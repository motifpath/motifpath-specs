# Pattern: primary action

**Source:** ADR-049 §4 and §5

## When

Use it on every screen that asks the student to do one thing next: start, check, continue or finish.

## Why

One obvious next step is fastest on a phone held in one hand, or held next to a guitar. Two
equal-looking buttons make the student stop and read.

## How

- **One primary action per screen,** styled with `PrimaryButton`. Secondary actions are outline
  buttons; tertiary ones are text links. A destructive action has its own variant.
- **Compact:** in a practice run, the primary action sits in the bottom action bar and spans its
  width. Elsewhere, it sits at the end of the content, never above the fold-only area.
- **Size:** at least 48 px tall, a touch target of at least 48 × 48 px.
- **Disabled:** a disabled primary action says why nearby (for example "Choose at least one
  option"), or isn't shown until it can be used.
- **Busy:** while the action runs, it shows the busy label ("Starting…") and ignores further taps.

## Do not

- Put two primary-styled buttons side by side.
- Hide the primary action behind a menu or a hover state.
- Ask for confirmation of a reversible action. Confirm only destructive, irreversible ones.
