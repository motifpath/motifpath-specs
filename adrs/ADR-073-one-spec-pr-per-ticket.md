# ADR-073: One spec PR per ticket; core switches scenarios on; skills and content move out

**Status:** Accepted
**Date:** 2026-11-09
**Deciders:** Gilson (Product Owner)
**Input:** MOT-192. PO decisions, 2026-11-09 (approved by Gilson on 2026-11-09):
- move skills and content to two new repositories;
- core switches a ticket's scenarios on from a list it keeps, keyed by ticket tags;
- contract fixes found during TDD land in one batched follow-up PR per ticket.

---

## Context

motifpath-specs opened 200 pull requests between 2026-10-09 and 2026-11-08, about 6–7 a day.
Half of them changed two files or fewer. Most of the volume came from the process, not from the
amount of contract work. An analysis of those 200 PRs found these drivers:

- **Un-tag PRs (~42).** A scenario specified ahead of core is tagged `@wip`, so core's strict godog
  runs skip it (the convention from 2026-09-21). Once core implements it, a separate specs PR
  removes the tag. Every implemented ticket cost at least one PR whose only content was deleting
  a tag line.
- **Several PRs per ticket.** MOT-185 alone had 9: the spec, its fixes, golden cases, un-tags and
  a skill tweak. An ADR often went in a PR of its own (13 one- or two-file ADR PRs).
- **Skills (~20)** and **lesson content (~16)**. `plugins/` (the `motifpath-skills` marketplace)
  and `curriculum/content/` lived here, so every skill tweak and every lesson revision went through
  the contract repository's PR flow, although neither is a contract.
- **Contract fixes found during core TDD (8+)**, each merged as its own PR (#453, #458).

Each PR costs review, CI runs, a merge and branch cleanup, and it hides contract changes among
housekeeping in the history.

## Decision

**1. Ticket tags replace `@wip`; core switches scenarios on.** A scenario that a ticket will
implement carries that ticket's tag, `@MOT-NNN`, at feature or scenario level, for good. It is
never removed, and it doubles as traceability. motifpath-core keeps `bdd/implemented-tickets.txt`.
`make test:bdd` builds the godog tag expression with `scripts/bdd_tags`, which skips every ticket
tag found in the specs but not listed there. The core PR that implements a ticket adds it to the
list, and that switches its scenarios on with no specs PR. CI prints the tickets still pending.
`@wip` stays, but only for *parked* scenarios: specified, with no ticket scheduled. A ticket that
picks a parked scenario up retags it `@MOT-NNN` in its own spec PR. `@web` is unchanged.

**2. One spec PR per ticket.** A ticket's ADR, OpenAPI change, Gherkin and golden cases go in one
PR. Fixes found in review are pushed to that PR. Contract fixes found later, during core or web
TDD, are collected and land in **one** follow-up spec PR per ticket. Core CI keeps running against
specs `main`.
An ADR is pushed only after the PO has approved it in the working session, and it lands with
`Status: Accepted`. No PR carries a `Proposed` ADR, so no later PR only changes its status.

**3. Skills move to `motifpath/motifpath-skills`.** It holds the same `plugins/<name>/` layout,
marketplace manifest and history (`git subtree split`). The marketplace and plugin names are
unchanged. A skill change is not a contract change: it is committed to that repo's `main` with a
version bump and CHANGELOG entry, and gets a PR only when someone wants a review.

**4. Lesson content moves to `motifpath/motifpath-content`.** It holds one folder per unit,
starting with `first-notes/`, with history. Its tools read this repository's knowledge map and
motifpath-skills' fonts from sibling checkouts. The curriculum plan, principles and pilot
records stay here: they are what content is checked against.

**5. Epic branches only for multi-milestone efforts** (such as MOT-107 monetization). A regular
ticket's spec PR targets `main` directly.

## Rationale

- **Core owning the switch** puts the change where the knowledge is. Core is the repo that knows
  when a scenario is implemented, and its implementing PR is already open. Rejected:
  - *Keep `@wip` and remove it in the next spec PR of the same area.* No core change, but it
    still needs a specs change after every implementation, and it saves the least.
  - *Pin core's specs checkout to a commit.* This removes the strict-mode breakage, but bumping
    the pin pulls in every other ticket's unimplemented scenarios, so a skip list is needed anyway.
  - *An allow-list of scenario names in core.* This breaks on every rename. Ticket tags are
    stable and say why a scenario exists.
- **Skipping unknown ticket tags by default** keeps spec-first intact: a merged spec never turns
  unrelated core PRs red. The cost is the same as today's leftover-`@wip` risk, a scenario that
  stays skipped after implementation. That risk is now visible, because CI prints the pending
  tickets on every run.
- **One batched fix-up PR instead of keeping the spec PR open until core is green.** Keeping it
  open would need core CI to check out a specs branch, plus a guard that `main` is restored
  before merge. Batching gets most of the saving without that machinery.
- **Separate repositories instead of path-scoped rules here.** Path filters could exempt
  `plugins/` and `curriculum/content/` from review, but they would still share this repo's CI,
  history and PR numbering. Separate repos also let skills and content set their own lighter
  flow.

## Consequences

### Positive
- About half of the recent PR volume disappears structurally: un-tag, skill, content and
  per-finding fix-up PRs.
- A scenario's tag now names the ticket that owns it.
- The specs history shows contract changes only.

### Negative / Trade-offs
- Merge order matters once: core's runner change must reach core `dev` before a specs PR adds
  ticket tags. Otherwise core CI runs those scenarios and fails on undefined steps.
- `make test:bdd` is now the only way to run the BDD suites: a bare `go test` refuses to run
  without `BDD_TAGS`.
- Forgetting to list a ticket in core leaves its scenarios skipped. CI's pending list is the
  guard, but a person still has to read it.
- Team members re-point the marketplace once:
  `claude plugin marketplace add git@github.com:motifpath/motifpath-skills.git`.
- Content tools need three sibling checkouts (content, specs, skills) or the
  `MOTIFPATH_SPECS_DIR` / `MOTIFPATH_SKILLS_DIR` overrides.
- The new repositories start private. Making them public, as motifpath-specs is, is a separate
  choice.

- The PO approves an ADR before it is pushed, outside GitHub. The approval is recorded in the
  ADR's `Input` line (who approved it and when) rather than in a PR review.

### Neutral
- Existing parked `@wip` scenarios keep their tag until a ticket picks them up. The monetization
  features stay `@wip` until their runtime tickets retag them.
- Older ADRs and PRs that link `plugins/` or `curriculum/content/` keep their links into this
  repo's history.

## Related ADRs

- ADR-022: Drop Notion project tracking — skills were then distributed from this repo's
  `plugins/`; this ADR moves them.
- ADR-071: Two commercial products — the monetization epic, the model for when an epic branch
  is warranted.

---

*To revise, create a new ADR with Status: Supersedes ADR-073.*
