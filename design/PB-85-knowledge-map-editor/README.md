# PB-85 Phase 4 — Knowledge map editor (admin)

**Status:** Approved by the PO (2026-10-02)
**Repos:** `motifpath-specs` (this note, `features/web/knowledge-map-editor.feature`),
`motifpath-web`. No API change: the editor uses the knowledge-node and knowledge-edge calls
that Phase 1 specified and Phase 2 shipped (`listKnowledgeNodes`, `createKnowledgeNode`,
`updateKnowledgeNode`, `deleteKnowledgeNode`, `listKnowledgeEdges`, `createKnowledgeEdge`,
`updateKnowledgeEdge`, `deleteKnowledgeEdge`).
**Builds on:** ADR-043 (knowledge graph), ADR-036 (localized names), ADR-018 (UI
architecture), the Phase 3 two-pane picker (`SkillConceptTreePicker`), and the rule that
preview-then-confirm flows go in a modal.

## Problem

After Phase 3, nobody can create a skill or concept from the web app: the picker's inline
creation was removed for everyone, and the picker only says "Missing one? Ask the team."
The map (340 nodes, 335 applies, 136 requires) can change only through a data migration or
raw API calls. Admins need one screen to grow and correct it.

## Decisions (PO, 2026-10-02)

1. **Admin-only.** One route, `/admin/knowledge-map`, reachable from a "Knowledge map" nav
   section shown only to admins. Teachers and students never see it, and the router sends
   them away like any other role-gated route. (A read-only view for teachers is Open
   Question 1.)
2. **One screen, two panes.** The same tree as the picker sits on the left; the selected
   node's details and links sit on the right. On a phone the panes stack: the tree, then
   the node on its own view with a Back control.
3. **Concepts before Skills**, as everywhere else since Phase 3.
4. **Edges are edited from the node they leave.** A skill lists the concepts it *applies*
   and the nodes it *requires*, and those lists can be changed. A node also lists what
   *applies* or *requires* it, read-only, each linking to that node. That gives every edge
   exactly one place to edit it.
5. **Simple fields save directly; structural changes go through a modal.** Names,
   descriptions and instruments are a form with Save and Discard. Moving a node (new parent)
   and deleting one each open a confirmation modal that says what will happen.
6. **The UI prevents what it can and explains what it can't.** Choices the API would reject
   with 400 are disabled with a reason (a parent of the other kind, a node inside the moved
   subtree, instruments wider than the parent). Rejections only the server can know (409:
   content outside the new instruments, a node still in use, a cycle) show the server's
   message next to the control that caused them.
7. **Authoring pickers link here for admins.** For an admin, the picker's "Missing one? Ask
   the team." becomes "Missing one? Add it in the knowledge map", opening the editor in a
   new tab. The picker reloads both trees when its tab regains focus, so the new node
   appears without losing the form.

## Page and route

| Route | Name | Who | What |
|---|---|---|---|
| `/admin/knowledge-map` | `admin-knowledge-map` | admin | The editor. |

Query parameters keep the screen linkable and survive a reload:

- `node=<node_id>` — the selected node.
- `new=skill|concept` — the create form is open for that kind (no parent).
- `new=skill|concept&parent=<node_id>` — the create form is open under that parent.
- `tree=skill|concept` — the tab shown on the left (default `concept`).

An unknown `node` id shows the empty right pane with "This node no longer exists."

## Left pane — the tree

- Tabs **Concepts (n)** and **Skills (n)**.
- The picker's search (any-language name, key, ancestor names) and instrument filter. The
  filter defaults to **Any instrument**. Choosing an instrument greys out the nodes that
  aren't for it; they stay selectable, because an admin may need to edit them.
- Rows collapse and expand like the picker. Each row shows the name in the UI locale and,
  when the node isn't for every instrument, a compact instrument badge.
- The selected row is highlighted, and the path to it is expanded on load.
- **New concept** / **New skill** button (matching the tab) above the tree.

## Right pane — the selected node

Header: the name in the UI locale, the kind, the key (monospace, with a copy button), and the
breadcrumb of ancestors. Each ancestor links to that node.

### Details form

| Field | Create | Edit |
|---|---|---|
| Key | Suggested from the English name (lowercase kebab-case) until the admin edits it; validated against the pattern and uniqueness (client check against the loaded trees, server 409 as a backstop) | Read-only, with a note: "Keys never change." |
| Name — English, Português (Brasil) | Required, both | Required, both |
| Description — both languages | Optional; both or neither | Same; clearing both removes the description (sends `null`) |
| Parent | Picked in the create form (same-kind tree, or "No parent — a root") | Read-only here; **Move…** opens the move modal |
| Instruments | Defaults to the parent's; options outside the parent's scope are disabled, with the reason | Same limit. A 409 (content or a child outside the new scope) shows the server message under the field |

Save is disabled until something changed and every required field is valid. Leaving a
changed form (selecting another node, switching tabs, closing the page) asks "Discard your
changes?"

Under the form: **Add child** (opens the create form with this node as the parent),
**Move…** and **Delete…**.

### Links

For a **skill**:

- **Applies** — the concepts it uses. **Add** opens the picker in concept mode, with the
  concepts it already applies shown as picked. Each row has a remove ×.
- **Requires** — the nodes it needs, each with a level select (Accurate / Fluent /
  Retained). **Add** opens the picker over both trees. Each new link starts at **Accurate**,
  and the admin changes the level in the list. Changing the select saves at once
  (`PATCH /knowledge-edges/{id}`). Each row has a remove ×.
- **Required by** — read-only: the nodes that require this one, with their levels.

For a **concept**: **Requires** and **Required by** as above, plus **Applied by** —
read-only: the skills that apply it.

Each linked node is a link that selects it. An edge saves as soon as it's added or removed.
There is no form-level Save for links. A 409 on add (duplicate, or a requires link that
would close a cycle) shows inline under that list. For a cycle, the message names the chain
when the client can find it in the loaded edges: "Vibrato already requires Bends — this link
would close a loop." For a longer chain: "Vibrato already requires Bends (through Slides) —
this link would close a loop." Picking a node already in the list isn't possible: the picker
shows it as picked.

## Modals

**Move.** A same-kind tree in single-choice mode plus "No parent — make it a root". The node
itself and its descendants are disabled ("inside the node you're moving"), and so are
parents whose instruments are narrower than this node's ("narrower than this node"). The
confirm line says what moves: "Move **Bends** and its 4 descendants under **Lead
techniques**?" Buttons: Cancel / Move. A 409 keeps the modal open with the message.

**Delete.** When the node has children or links, which the client already knows, the modal
says what is blocking the delete, names those nodes and links, and offers only Close. When
it has neither, the modal asks "Delete **Bends**? This can't be undone." with Cancel /
Delete. A 409 (content, an exercise, a diagram or a challenge still uses it) shows the
server's message in the modal. After a delete, the parent (or nothing, for a root) becomes
the selection.

## States

- Loading: the tree's skeleton, as in the picker. The right pane shows "Pick a node, or
  create one."
- Load failed: the picker's "Couldn't load … Try again" state, per tree.
- Saving: the Save button shows progress; the form stays editable only after the response.
- A failed save (network or 5xx) shows a toast and keeps the form's values.

After any successful write, the editor refreshes its loaded nodes and edges, so names, the
tree and every link list stay consistent.

## Out of scope

- Teachers proposing new nodes (ADR-043 defers the proposal flow).
- Bulk import/export (the catalog YAML plus migration stays the bulk path).
- A graph visualisation of requires edges.
- Reordering siblings (the API has no order; the tree sorts by name).

## Open questions

Resolved with the spec's approval (2026-10-02): each recommendation below was accepted.

| # | Question | Decision |
|---|---|---|
| 1 | Let teachers open the map read-only? | Not now. They already browse it through the picker. Revisit with the proposal flow. |
| 2 | Edits made in the editor aren't written back to `catalogs/knowledge-map.yaml`, so a dev DB rebuilt from migrations loses them. Accept that until prod exists? | Yes. Until there's a prod DB, any edit worth keeping also goes into the YAML and a regenerated migration. The editor is for trying changes and for prod later. |
| 3 | Should the editor show how much content uses a node (counts per node)? | Not in PB-85. It needs a new endpoint, and the delete 409 already tells admins when a node is in use. |
