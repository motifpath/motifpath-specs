---
name: project-index-maintenance
version: 1.3.0
description: >
  Use this skill when Gilson explicitly asks to update the MotifPath Project Index
  page in Notion. Trigger on phrases like "update the project index", "log this
  session", "run the index check", "wrap up the session", "close out the session",
  or similar invocations referring to the Project Index, the session log, or
  end-of-session bookkeeping. This skill reconciles the Project Index page
  (Notion ID 3679ccc1-102f-8184-83a7-e328e0d8cbfc) against what actually happened
  in the session — updating the Current Focus section, Decided ADRs table, and
  Last-updated timestamp — while keeping the page short (trimming stale
  narrative, not just appending to it). Backlog Snapshot on the index is a live
  linked view of the real Product Backlog database (Notion ID
  93826617-2504-4976-9769-d3841dffcafd), so this skill instead reconciles
  backlog *item* pages directly — normalizing every item's status to the
  five-value vocabulary (Ready, In Progress, Blocked, Done, Archived) and
  creating a database item when session work has none. Do NOT auto-trigger from
  conversation cues alone — wait for an explicit user invocation.
---

# Project Index Maintenance

## Purpose

The MotifPath Project Index page is the canonical pointer to current focus, decided ADRs, and backlog state. Without active maintenance it drifts two ways: it grows a chronological narrative nobody trims, and backlog statuses accumulate ad hoc values that stop meaning anything consistent. Both make the next session's bootstrap slow and error-prone — a bloated page is expensive to read, and a confused status is worse than no status. This skill performs the reconciliation: read the index page and the real Product Backlog database, compare them against what happened this session, reconcile the differences (including normalizing statuses and trimming stale bulk), write them, and report.

As of 2026-09-15, the Backlog Snapshot section of the index is a **live linked view** of the Product Backlog database, not a manually copied table — it cannot drift out of sync with itself the way the old markdown table could. But the two things it used to hide — a real item's status going stale, and a real item never getting created at all — can still happen at the database level, so reconciliation now targets the database directly instead of index-page table rows.

## When to Trigger

This skill runs on explicit user invocation only. Listen for phrases like:

- "update the project index"
- "log this session" / "log the session"
- "run the index check" / "run the index update"
- "wrap up the session" / "close out the session"
- "session close" / "end of session bookkeeping"

Do NOT trigger from implicit conversation cues (a session winding down, work seemingly finishing). Gilson controls when this runs.

If nothing has changed this session, still acknowledge the invocation — but report cleanly that no updates are needed rather than skipping silently.

---

## Backlog Status Vocabulary

Every item in the Product Backlog database (`collection://93826617-2504-4976-9769-d3841dffcafd`) carries exactly one of five `Status` values. No other value is ever written, and no item is ever left without one of these five:

| Status | Meaning |
|---|---|
| **Ready** | Todo. Not started, and nothing is blocking it from starting. |
| **In Progress** | Active work this session or the most recent one — independent of PBI type (Feature, Epic, ADR, Research Task, Discovery spike, all use the same value). |
| **Blocked** | Cannot proceed — waiting on another PBI, a decision, or an external dependency. Name the blocker in the row's description. |
| **Done** | Finished and merged/accepted. There is no separate "Validated" status — validation is part of what "Done" means, not a further stage after it. |
| **Archived** | Superseded, split into child items, or otherwise no longer tracked as live work (e.g. a parent epic replaced by its own child PBIs). |

There is no "Discovery" status. A discovery/spike item is either **Ready** (not started yet) or **In Progress** (the spike is actively happening) like any other PBI — the fact that the work is exploratory is a property of the PBI's type/description, not a distinct lifecycle stage.

### Normalizing legacy values

The database's `Status` select property only offers these five options (the legacy `Discovery`, `Validated`, and `Ready to Build` options were removed 2026-09-15 via `notion-update-data-source`, so they can't be picked again). But an item's *actual* status can still drift stale — e.g. an item sits at `Ready` for months after the work that finished it, because nobody went back and flipped it. Whenever the reconciliation in Step 3 touches an item (or, opportunistically, whenever you notice a mismatch while reading), correct it using this mapping — this is a self-healing cleanup, not a one-time migration to schedule separately:

| What you find | Normalize to |
|---|---|
| Status says `Ready` or `In Progress`, but the session/index history shows the work is actually merged/accepted | `Done` |
| Status says anything, but the item is superseded or split into child items | `Archived` |
| An item discussed this session has no corresponding database row at all | Create one (see Edge Cases) with the correct `Status` |
| Genuinely unclear which of the five an item should be | Ask Gilson; don't guess-write it |

A normalization write counts as a real update for Step 5's report even if nothing else about that item changed.

---

## Workflow

The workflow is six steps. Do not skip any of them.

Invoking this skill is the go-ahead to write. Gilson has already decided the index should be updated; the skill's job is to reconcile accurately and write directly — no separate "present the plan and wait for approval" gate. State the writes as you make them (Step 6 reports them), and if Gilson wants something different they will say so.

### Step 1: Fetch the current state

Use `notion-fetch` against page ID `3679ccc1-102f-8184-83a7-e328e0d8cbfc` to retrieve the current state of the index page. Read it carefully. Note especially:

- The current "Latest session note" link and date
- The current "Active item" and its status
- The current "Last updated" timestamp
- The rows currently in the Decided ADRs table

Then use `notion-query-data-sources` (SQL mode) against `collection://93826617-2504-4976-9769-d3841dffcafd` to pull every backlog item touched by this session's inventory (Step 2) — `Name`, `Status`, `Priority`, `ID`, `url`. The index page's Backlog Snapshot section is a live linked view now; it needs no fetch of its own, but the database behind it does.

Without this step, you are operating blind. The entire reconciliation depends on knowing what the page and the database actually say right now.

### Step 2: Inventory what changed this session

Look back over the conversation history of the current session. Build a concrete inventory of:

- **Session note**: Was a new session note page created in Notion (typically as a subpage under a backlog item like PB-8)? If so, capture its URL.
- **Active backlog item**: Did work focus shift from one backlog item to another? Did the active item's status change (e.g., "Ready" → "In Progress")?
- **ADRs**: Were any ADRs decided or finalized? Capture the ADR number and topic.
- **Backlog changes**: Did any backlog item change status or priority, get created, or get renamed/rescoped?

Reference specific PB-X IDs and ADR-X numbers from the conversation. Do not infer changes that weren't explicitly discussed.

### Step 3: Reconcile against the six checks

Run these six lenses against `(inventory ∩ current page state)` to determine what actually needs to change. The check is **divergence**, not **event** — if a session note was created but the page already points to it, no update is needed.

1. **Session note check**: Does "Latest session note" on the page point to the most recent session note from the inventory?
2. **Active item check**: Does "Active item" on the page match the focus of this session? Does its status match?
3. **ADR check**: Are all newly-decided ADRs from the inventory present as rows in the Decided ADRs table?
4. **Backlog database check**: Does every backlog item the inventory touched exist in the Product Backlog database with the right `Status` and `Priority`? An item mentioned this session (by a PB-X id or by description) that has no matching database row at all is a divergence too — see Edge Cases for creating it.
5. **Status vocabulary check**: For the items Step 4 touched, does `Status` reflect where the work actually is (not just whichever of the five values it happens to hold)? Normalize per the mapping table under "Backlog Status Vocabulary" above. This check is scoped to items the inventory surfaced — it is not a full audit of all ~50 backlog items every run.
6. **Timestamp check**: If any of checks 1–5 will result in a write, the "Last updated" date should be updated to today.

If all six checks pass (page and database already match reality), there's nothing to write — skip to Step 6 and report "Project Index unchanged".

If Step 2 surfaced an ambiguity a write depends on (see Edge Cases — e.g. two backlog items became active), resolve it with Gilson before writing that specific change. Everything unambiguous still gets written.

### Step 4: Trim the page

The index is a pointer, not an archive — the full narrative already lives in git history, PR descriptions, and linked session-note pages. Every run, check the page for bulk that shouldn't be there and cut it:

- **Current Focus**: This section must read as a short present-tense status, not a session-by-session chronicle. Keep only: the active item and its (normalized) status, one short line of "why/what's next", and the "Latest session note" link. If Current Focus has accumulated dated paragraphs from past sessions (e.g. "**2026-09-13 session...**", "**2026-09-14 session (continued)...**"), delete them — that detail belongs in the session note pages and git/PR history, not inline on the index. Keep at most the current state; do not summarize the deleted history into a longer paragraph as a substitute.
- **Backlog database `Notes` field**: If an item's `Notes` property (not the index page — see Purpose) has grown a multi-sentence merge-by-merge history, compress it to one short clause with a pointer (e.g. "see ADR-019" or "see PB-49") if another item/ADR already carries the detail. This is the database-item equivalent of the old Backlog Snapshot row-trimming and follows the same rule: compress, don't delete the item or lose its `Status`/`Priority`.
- Leave the Decided ADRs table, Key Product & Architecture Context, Key Notion IDs, Active English Patterns, Repo Structure, Methodology sections, and the Backlog Snapshot's live-view pointer paragraph alone — they are not chronological and are not the source of the bloat (see "What NOT to Update").

Trimming is part of the same write batch as Step 5 — it is not a separate ask-first pass. If a trim would delete information that isn't preserved anywhere else (no linked session note, no PR, no ADR), keep it rather than lose it, and flag that gap in Step 6's report instead of silently dropping it.

### Step 5: Execute writes

Two different targets get writes now — keep them straight:

**Index page** (`notion-update-page` with `page_id: 3679ccc1-102f-8184-83a7-e328e0d8cbfc`), for:
- "Update the 'Latest session note' line to point to the new URL"
- "Add a new row to the Decided ADRs table with ADR-006"
- "Update the 'Last updated' value to today's date"
- "Replace the Current Focus section with the trimmed version"

**Backlog database items** (`notion-update-page` with `command: update_properties`, targeting the individual item's own page ID from Step 1's query — never the index page ID), for:
- "Set PB-41's `Status` to `Ready`"
- "Compress PB-49's `Notes` field to one clause"

If an item from Step 3 check 4 has no database row at all, create one with `notion-create-pages` (`parent: {type: data_source_id, data_source_id: 93826617-2504-4976-9769-d3841dffcafd}`), setting `Name`, `Status`, `Priority`, and `Type` — see Edge Cases.

Use the block IDs and structures observed in Step 1 to construct correct index-page update calls. If a particular write fails, do not abort the whole sequence — continue with the rest, then report failures in Step 6.

### Step 6: Report results

After all writes are attempted, report concisely.

Successful run:

```
✅ Project Index updated:
- Latest session note → [new link]
- Active item → PB-9 (In Progress)
- Decided ADRs: +ADR-006
- Status normalized (Product Backlog database): PB-41 Ready → Done
- Current Focus trimmed: removed 4 dated session paragraphs (detail preserved in linked session notes / git history)
- Last updated → 2026-05-21
```

Partial failure:

```
⚠️ Partial update:
- ✅ Latest session note updated
- ✅ Last updated timestamp set
- ❌ Failed to add ADR-006 row to Decided ADRs table (reason: ...)
```

Nothing changed:

```
ℹ️ Project Index unchanged — no backlog, ADR, session note, or status-vocabulary updates needed this session.
```

---

## What NOT to Update

Even if it looks tempting, leave these alone:

- **Active English Patterns** — owned by the `english-fluency-coach` skill. Touch nothing here.
- **Repo Structure** — only changes for genuine architectural moves; not a routine maintenance target.
- **Methodology** — same.
- **Key Product & Architecture Context / Key Notion IDs** — reference material, not a session log; leave as-is unless it's factually wrong.
- **Historical session notes as separate Notion pages** — only the "Latest session note" pointer on the index moves; the note pages themselves, and older note links inside them, are untouched.
- **Speculative future ADRs** — only Decided ADRs go into the table. Drafts and proposals do not.
- **Priority values on backlog items** (P0–P3) — this skill normalizes *status*, not priority; only touch priority if the inventory explicitly says it changed.
- **Backlog items this session's inventory never touched** — Step 3 check 5 is scoped to items the inventory surfaced. Do not run a full audit of every backlog item's status on every invocation; that's a different, heavier task, not this skill's job.
- **The Active Backlog linked view itself** (filter/sort/columns) — it's configuration on the view block, not content this skill reconciles. Leave its filter (`Status IN (Ready, In Progress, Blocked)`) alone unless Gilson asks for a different scope.

Note the one deliberate exception to "leave it alone": Step 4 trims dated narrative out of **Current Focus** and compresses an over-grown `Notes` field on a backlog item, on every run, as a normal part of this skill's job — that is not scope creep, it is the second half of what "maintenance" means here. The scope creep to avoid is going further than Step 4 describes: rewriting an item's meaning, reordering anything, or restyling sections it doesn't cover.

---

## Coordination with english-fluency-coach

Both this skill and `english-fluency-coach` are part of the session-close ritual. Gilson invokes them separately and controls the order. There is no shared state and no required sequencing — but if Gilson asks to run both, do them sequentially (one fully completes, including its write-and-report cycle, before the next starts). Do not interleave.

---

## Edge Cases

**Two backlog items became active in one session.** Ask Gilson which one should be the "Active item" going forward. Don't guess. Write every other unambiguous change in the meantime.

**An ADR was discussed but Gilson said "let me think about it more."** It's not decided. Do not add it to the Decided ADRs table.

**The Notion fetch returns an unexpected page structure** (sections missing, table headers renamed) or the database query returns an unexpected schema (the `Status` property has options beyond the five, or is missing). Stop. Report the discrepancy rather than trying to autocorrect. The skill assumes a stable page structure and a stable five-option `Status` property; if either is broken, a human needs to look.

**A backlog item discussed this session has no corresponding row in the Product Backlog database at all.** This happened for real on 2026-09-15: PB-40 (exercise-authoring builder) had months of session-note history and multiple merged PRs but no database row — the work had only ever been tracked in the index page's old markdown table, never in the actual database. Create the missing row with `notion-create-pages` (`Name`, `Status`, `Priority`, `Type`, and a short `Notes` summary with PR/ADR pointers), then report it as a creation, not a normalization. If an existing row's *name* looks like it might be the same effort under different wording rather than truly missing, ask Gilson which it is — don't guess and silently rename or merge.

**Gilson invokes the skill mid-session, not at session close.** That's fine — the workflow is the same. Reconcile against whatever has happened so far. Nothing about the workflow actually requires "end of session" to be true.

**The session was entirely discussion, no concrete changes.** If, while reading, you notice an item's `Status` clearly doesn't match reality (e.g. still `Ready` though the index history shows it shipped), normalize it anyway even though nothing happened this session, report the normalization, and otherwise report "Project Index unchanged".

**A write turns out larger or more sweeping than the inventory justifies.** Don't force it through just because the skill is running. Pause, say what looks off, and let Gilson steer. This includes Step 4 trims: if trimming Current Focus would mean judgment calls about what counts as "still needed" beyond the rule stated there, pause and check rather than guessing.

**An item's true status doesn't map cleanly** (e.g. it's genuinely unclear whether an item stuck at `Ready` should become `In Progress` or is actually already `Done`). Don't guess-write it. Ask Gilson which of the five it should become, resolve everything else, and report the one pending call.

**A backlog item's whole point was that it's exploratory** (a research task, a spike). Resist the urge to invent a sixth status for it. It's still just Ready, In Progress, Blocked, Done, or Archived — the item's title/type already says it's a spike; the status only tracks where it is in that lifecycle.

---

## Page Reference

- **Project Index page ID**: `3679ccc1-102f-8184-83a7-e328e0d8cbfc` — this skill writes to Current Focus, Decided ADRs, and Last-updated on this page.
- **Product Backlog data source**: `collection://93826617-2504-4976-9769-d3841dffcafd` — this skill writes to individual backlog item pages' `Status`/`Priority`/`Notes` properties, and creates new item pages when Step 3 check 4 finds a gap. It never edits the data source's schema (the five-option `Status` property, its colors, or other properties) — that's a one-time setup, not a per-session maintenance task.
- These are the only two places this skill writes to. Any other Notion writes are out of scope.
