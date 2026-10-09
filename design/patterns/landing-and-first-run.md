# Pattern: landing, sign-in and first run

**Source:** ADR-049 §1 and §5 · ADR-007 (Google sign-in via Clerk) · ADR-035 (display names) ·
ADR-046 (instruments come from enrolments) · MOT-59 (Figma "Landing & first run", rows 1–5 and the
dark · pt-BR copies; decisions D1–D9) · absorbs MOT-13 (landing, Direction C chosen 2026-09-12) and
MOT-15 (onboarding bridges)

## When

Use it for everything a visitor sees before they have something to practise: the signed-out landing
(`/`), the bridges while the account is set up (`/welcome`, `/welcome/error`), the name screen when
Google gives no full name, and the first run on Home for a student who has never started a course or
a path. A signed-in, registered visitor at `/` goes straight to Home.

## Why

A new student should reach their first practice in as few taps as possible, with nothing that looks
like someone else's product. Google is the only way in, so a sign-in form adds a tap and a foreign
look. A student's instruments come only from what they have started (ADR-046), so a new student has
nothing to practise until a course or path is started; the first run has to lead there, not to an
empty session.

## How

### Landing (S0) — D1–D4

- **Who can come in (D2):** any Google account (open alpha).
- **Layout (D4, Direction C):** no App Shell before sign-in (`navigation.md`). Top: the small mark
  and "MotifPath". Middle: `Brand/Mark` at 96 px, the headline, one line, the actions. Bottom: the
  language link.
- **Copy (D3):** headline "Practise a little every day. See your skills grow." — line "Short
  sessions on your instrument, picked for what you need next — and lessons when you want to learn
  something new." pt-BR: "Pratique um pouco todo dia. Acompanhe sua evolução." (not a literal
  "crescerem"). Never promise a feature the app doesn't have (an earlier "Hear yourself get
  better" implied listening back to recordings).
- **One action (D1):** `GoogleButton` "Continue with Google" starts Google sign-in through Clerk
  directly (no Clerk sign-in card). The G sits on a white disc, as Google's branding rules require.
  `/sign-in` stays as a route and redirects to the landing.
- **Caption:** "Free during the alpha. We use your Google name and email, nothing else."
- **Language:** from the browser; the link at the bottom switches en ↔ pt-BR before sign-in ("Português
  (Brasil)" / "English") and the choice carries into the app.
- **Signed out:** the landing shows the sign-out toast from `navigation.md` ("You're signed out.
  Your practice and progress are saved.").

### Bridges — D5

All of them keep the landing's layout, so the visitor never sees a blank page or a different screen.

- **Back from Google (`/welcome`):** the same screen; `GoogleButton` turns Busy "Setting up your
  account…", only after 300 ms (`states.md`), so a fast registration is never seen.
- **Name missing (`/welcome`, D1):** "What should we call you?" with First name and Last name
  (`TextField`), what Google gave prefilled, the missing one focused; **Continue**, and **Sign out**
  as the quiet way back. ADR-035 keeps both names required and the name still reaches core only
  through the token's `name` claim:
  - at sign-up, Clerk stops as "missing requirements"; Continue completes it (`signUp.update`);
  - for an existing account whose registration fails as name-required, Continue updates the Clerk
    user (`user.update`), refreshes the session token and retries the registration.
  This replaces today's "Add your name" button, which opens Clerk's profile form.
- **Setup failed (`/welcome/error`):** an `InlineNotice` (Error) "We couldn't set up your account.
  Your Google sign-in worked — try again in a moment.", **Try again**, and **Sign out**.
- **Google didn't finish** (cancelled, denied): back on the landing with an `InlineNotice` "Google
  sign-in didn't finish. Nothing was saved — try again when you're ready." and the Google button.

### First run on Home — D6–D9

- **Where (D6):** on Home, for a student who has never enrolled in a course or path. No route, no
  "seen" flag, no API change: it comes back until something is started. It replaces the whole home
  (a brand-new student's This week would be all zeros). The bottom bar shows Home.
- **Two questions (D7):** "Welcome, <first name>", "Two quick questions and we'll show you where to
  start.", then one card:
  - "What do you play?" — a `ChoiceChip` for every catalog instrument (acoustic guitar, electric
    guitar, electric bass today); none preselected, and the button waits for one.
  - "How much do you play?" — New to it · I can play a bit · I play well (= Beginner · Intermediate
    · Advanced); New to it preselected.
  - **Show me where to start** (Primary).
  - The answers are filters only and are never stored; the catalog language is the app's language.
- **Where to start (D8):** "Where to start", the answers with **Change**, a count ("1 path · 2
  courses"), then `CatalogCard` rows: paths first (a guided order), then courses, at most 5, from
  the catalog endpoints with level, instrument and language filters. The eyebrow names the kind
  ("Path · Beginner · English"). Tap opens the Discover detail, whose back arrow says "Where to
  start"; Start follows Discover D11 (current, My path on lesson 1, toast with Undo), and the first
  lesson ends in practice. About 7 taps from the landing to the first lesson.
  - **No match at that level:** "Nothing for beginners on electric bass yet. These are the
    closest:" and the instrument's other levels.
  - **Nothing for the instrument:** `StateBlock` (Empty) "No electric bass courses yet" with **Ask
    us on WhatsApp**; Change stays.
  - **Loading / failed:** skeleton rows after 300 ms; an `InlineNotice` with **Try again**
    (Secondary) in place (`states.md`).
- **Concierge (D9):** "Not sure? Ask us on WhatsApp" as a quiet link under the card and the results
  (PB-78's number), with "Browse everything in Discover". With nothing started, the Practice tab's
  nothing-to-practise action (`session.md`) is **Find where to start**, which opens this first run.

### Size classes

| Size class | Landing and bridges | First run |
|---|---|---|
| Compact | The centred screen above. | Bottom bar; one column. |
| Medium | The same, in a centred 420 px column; no shell. | Rail; one 560 px column. |
| Expanded | Direction C: a full-height brand panel (deep indigo gradient, `Brand/Mark` at 220 px with a soft glow; the same in both themes) beside a 420 px column that holds the Compact content. Every bridge keeps the split. | Sidebar; the questions in a centred 560 px column; results as `CatalogCard` tiles, 3 across (as Discover). |

## Do not

- Show Clerk's sign-in card, sign-up form or profile form; ask for what we need on our own screens.
- Store the first-run answers or add an onboarding flag; the student's enrolments are the state.
- Start a session for a student with nothing started, or show them an empty Today's practice.
- Show the App Shell before sign-in, or a full-page spinner on a bridge.
- Promise features the app doesn't have in landing copy.

## Spec changes this needs

- **`features/web/home.feature`:** "A student with no instruments sees This week and no Your skills"
  becomes two scenarios — a student who has never started anything sees the first run (no This
  week); a student who has left everything keeps today's rule. Add scenarios for the two questions,
  Where to start (order, fallbacks, Change) and the Practice tab's "Find where to start".
- **Web auth (`registering`, `registration-error`):** a name step (screen 1c) replacing
  `openUserProfile()`; the landing's Google button replacing Clerk's `<SignIn />`.
- No core or OpenAPI change: the catalog filters, enrolments and the name claim exist.
