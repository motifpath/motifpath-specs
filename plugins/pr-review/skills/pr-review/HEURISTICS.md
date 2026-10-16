# Systemic checklist

Questions, not rules: a question crosses languages and repos; a rule dies with the framework. Each
item states a **principle** (what must stay true), the **questions** that test it on a change, and
the **smell** that signals it is broken.

Items are written as concepts, never as cases. A review meets code nobody has seen before, so an
item has to be recognisable from the shape of the problem, not from a past incident's names. Where
an item came from is recorded in `CHANGELOG.md`, not here.

**Mindset:** step out of the changed line and hold the change against three axes the diff itself
doesn't show — **the system** (who calls in, where the output lands), **real data** (volume,
cardinality, how hostile the content actually is), and **the lifecycle** (rollout, migration,
reprocessing — not just steady-state).

## Activation

24 items is too many for every review. Classify the change and walk only the activated subset —
plus the five always-on items.

| If the change… | activates |
|---|---|
| alters behavior that already exists | 10, 11, 12, 13, 4 |
| creates a new entry point or a new output | 1, 15, 7, 14 |
| touches ordering, filtering, scoring, or aggregation | 10, 5, 6, 23, 18 |
| touches an identifier, key, name, unit, or path | 8, 9 |
| reuses an existing routine in a new context | 3, 5, 6 |
| adds an extension point, or a new kind through one | 2, 4 |
| adds validation or a constraint | 11, 12, 13 |
| carries external content into render/query/exec | 15, 16, 2 |
| touches configuration, migration, reference data, or rollout | 7, 14, 2, 4 |
| adds a test, or a CI step that reads another repo or shared data | 18, 7 |
| is user-facing | 12, 18, 14, 23, 5 |
| runs on a tick (animation frame, timer, poller, scheduled job) | 24, 7 |
| **always** | **17, 19, 20, 21, 22** |

---

## Axis A — The system around it

1. **Call chain (source → destination).** A change is only as correct as what feeds it and what
   consumes it. Who builds the input, and where does the output get written, rendered, or
   persisted? — *Smell:* a function reviewed in isolation, without opening its caller or where its
   output lands.

2. **Symmetry and precedent.** A rule that matters in one path matters in its siblings, and the
   codebase usually already has an answer. Did every sibling path (read and write, producer and
   consumer, each entry point to the same data) get the same guard? Does the project already solve
   this somewhere? When the change adds an extension point so new kinds need no change, do the
   rules that still branch on the concrete kinds read through it too, or would a new kind silently
   skip them? — *Smell:* a guard present on one side of a pair and absent on the other; a twin
   module's solution ignored; an extension point proven only by a fake plugging in, never by the
   fake going through every rule the existing kinds go through.

3. **Reuse fit.** A routine carries the assumptions of the caller it was built for. Does it return
   what this caller needs, or carry weight (fields, ordering, no limit) it doesn't use? Was it built
   for this scale? — *Smell:* reusing something built for a handful of items on a path that sees
   thousands.

4. **Second-order effects on shared invariants.** Code elsewhere relies on guarantees this change
   may move, and this change may rely on guarantees code elsewhere breaks. Who else reads what this
   writes, and through how broad a filter (by type, owner, classification), so that new rows or a
   new kind are picked up by readers that never expected them? Does new code assume something
   ("one current row per key," "rows here are live") that another flow (update, archive,
   re-versioning) quietly breaks? Does it create a dependency across a boundary the architecture
   keeps separate? — *Smell:* "just optimized," "just swapped a parameter," "just added more
   reference data," with no map of who depends on it; a new discriminator only the new code path
   filters on; a read by parent id with no filter for children a lifecycle elsewhere superseded.

23. **A pointer into a collection someone else can change.** State that refers to an item must
    survive the collection changing under it. Does a selection, cursor, focus, "current" item, or
    offset hold a *position* while other code can reorder, insert into, or remove from the
    collection? The pointer then lands on another item, and the next action on "the selected one"
    silently acts on the wrong thing. — *Smell:* an index kept beside a list mutated in more than one
    place, adjusted only for the mutation its owner performs.

## Axis B — Real data

5. **Distribution, not example.** Production data and real environments are wider than the example
   that drove the design. What are the real volume, shape, and extremes (values repeated in nearly
   every row, the largest collection, the maximum allowed limit, the narrowest screen a layout
   appears on after fixed surroundings take their share)? — *Smell:* reasoning anchored to the
   spec's clean example; a layout sized against the design's single frame.

6. **Amplification and cost.** Work multiplies along fan-out and frequency. One event or request
   turns into how many operations, times how often it fires? — *Smell:* a serial loop of round
   trips with no limit.

7. **Absence, transition, and interruption.** Every state has to be right when inputs are missing,
   when the system is half-migrated, and when a process ends any way other than success. Is empty
   "not set yet" or a deliberate value ("every", "no limit"), and does a default tell them apart?
   What holds during rollout (unmigrated rows, unreprocessed events, older clients in flight)? Does
   an in-progress state (playing, loading, connected) clear on every way it can end — failure,
   outside interruption, the owner moving on — or only on success? Does a test pin the exact
   contents of a source that grows on its own schedule (another repo, a shared catalog, an external
   API), so its next addition breaks unrelated changes? — *Smell:* only the happy path covered; a
   default applied to a value someone set on purpose; a "started" flag cleared by one success
   event; an exact count asserted on data someone else keeps growing.

8. **Normalization changes identity.** Transforming a value (shortening, hashing, converting a unit
   or scale) changes what counts as equal. What guaranteed uniqueness before, and what guarantees it
   now? Does the destination accept a duplicate silently? When two forms now compare equal, which
   form does a kept "best" or "current" value hold, and is it the one the user just chose? What does
   an operator lose for debugging? — *Smell:* truncation or hashing with no dedup at the
   destination; a strict "better than" that keeps the old form on a tie.

9. **Sentinel inside the real value space.** A fallback must not be mistakable for a real value.
   Does an "unknown" placeholder share the key space of real values? — *Smell:* a sentinel that
   produces a stable key and so never invalidates.

24. **Missed ticks.** A loop driven by ticks cannot assume they arrive on time. After a long gap
    (a suspended tab or device, a stalled worker), does it schedule work into the past, or replay
    every missed tick at once? — *Smell:* the next run computed from the previous run's end
    instead of from now, with no catch-up rule.

## Axis C — The nature of the change

10. **Additive or mutating?** Changing existing behavior needs proof the old behavior moved only
    where intended. Does the change add a capability, or alter order, filtering, scoring, format, or
    precedence? Is there a test that locks the behavior before and after, not only one for the new
    case? — *Smell:* a criterion change with no before/after test.

11. **New constraint on an existing door.** A constraint applies to everything that passes through
    the door, not just the edit that motivated it. Do all callers send the newly validated field?
    Do payloads that resend whole state now get rejected for fields the user never touched, or
    blocked by legacy data? Would validating only on change suffice? — *Smell:* validation added
    without enumerating callers and payload shapes.

12. **Every door, with a reason.** A rule protects data only if it holds at every point the data
    can be changed, and a block helps only if it explains itself. Does the rule apply at every
    entry point, and is its error shown, actionably, at every caller? — *Smell:* protection at
    some entry points but not all; a control silently disabled where an explained refusal belongs;
    half a rule extracted into a helper while the other half stays duplicated.

13. **One rule, one answer.** Wherever a rule is computed more than once, the copies drift. Is the
    same rule evaluated in two places (client and server, cache and origin, a list that offers
    choices and the action that carries one out)? Do both get the same inputs, defaults, and
    limits, and do they find items the same way? — *Smell:* two defaults for one rule in different
    files; a check on unsaved form state guarding a request validated against the saved record; an
    offer built from one source while the action queries another.

14. **Surface beyond the code.** Behavior that changes for users or operators needs a trace outside
    the code. Do docs, runbooks, migrations, configuration, or operator communication belong to
    this change? — *Smell:* new behavior with no trace outside the code.

## Axis D — Untrusted input

15. **Trail from input to a sensitive destination.** Content others can edit must be neutralized
    before anything interprets it. Does user-editable content reach a destination that interprets
    it raw (render, query, exec, template, file path, header)? Where exactly is it neutralized? Who
    writes that input, and at what scale? Once one vector is found, do the other producers of the
    same destination share it? — *Smell:*
    external content interpolated with no explicit neutralization step on the path.

16. **Tool semantics before copying the fix.** A fix is only as safe as what the tool actually
    does. Does an option or setting that fixes this case apply to a whole scope and break a
    legitimate neighbor? — *Smell:* a fix copied without reading what the option does.

## Axis E — Reviewer method

17. **Verify, don't presume.** A conclusion about code is only as good as the reading behind it.
    Did you claim a guarantee ("sanitized," "populated," "ordered") without opening the code? Does
    each worked example in a spec or test actually satisfy the rule it illustrates? Recompute it.
    — *Smell:* a conclusion about unread code; an example's numbers never re-derived from the rule.

18. **Test the real path.** A test proves a guarantee only if it exercises what could break it. Does
    it go through the path a real caller takes, firing the whole real gesture or event rather than
    injecting state? Does it fake away the very nondeterminism the guarantee has to survive — a
    shuffle replaced by a no-op, a fixed seed, a frozen clock, a fake that never fails? A rule that
    must hold *whatever* the order, timing, or failure needs at least one test where those vary.
    — *Smell:* a suite that only manipulates internal state and never fires the real event, or
    fires one part of a multi-part gesture; a guarantee about order or timing tested only with the
    order or clock pinned.

19. **Existing discussion is context.** Prior discussion holds decisions a fresh review can't see.
    Have you listed all discussion (bot and human, resolved and open), fully paginated, and deduped
    against it? The criterion is "thread without a reply," never "recent comment." — *Smell:* a
    draft proposing something a thread on this PR already settled.

20. **Concurrent, mutually exclusive changes.** Two changes pulling one decision opposite ways cost
    a revert. Is another open change taking the same design decision in another direction? Decide
    the direction first and look for a synthesis. — *Smell:* "known conflict, we'll sort it out
    later."

21. **Does the description describe the current state?** The description is what reviewers trust
    first. Does it still match the diff after mid-review changes? Are instructions for reviewers
    where they will look? — *Smell:* a description contradicting the diff.

## Axis F — Comment hygiene

22. **Does a comment explain the code, or point away from it?** The reason belongs next to the code
    it explains; a pointer to a document goes stale and costs every reader a lookup. Does a code
    comment name an ADR, backlog item, ticket, or spec file instead of stating the invariant,
    constraint, or reason in its own words? Document references belong in commit messages and PR
    descriptions, which are allowed to age. — *Smell:* "per ADR-NNN," "see ticket X," or a bare
    document name standing in for an explanation.

---

## Budget

**Cap: 24 items.** Adding at the cap requires merging two neighboring items or cutting the weakest
one first (`LEARNING.md` §2) — a judgment call made by re-reading the checklist, not by usage data.
The restriction is intentional: a 40-item checklist doesn't get reviewed, it gets skimmed.

A new item here **only** enters after passing the filter in `LEARNING.md` §1: it has to survive
without this repo's stack, phrase as a question, be falsifiable, and be stated as a principle with
no trace of the case that prompted it. Never add a rule that's really a fix specific to one PR.
