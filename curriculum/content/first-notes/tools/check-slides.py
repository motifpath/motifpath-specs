"""Fail when a learner deck carries exercise material.

Usage (from the repository root):
    python3 curriculum/content/first-notes/tools/check-slides.py [deck.pptx ...]

Without arguments it checks every deck in curriculum/content/first-notes/slides/.
Exercise prompts, hints, rationales and per-option feedback from activities.json
must not appear on any slide, hidden slide or speaker note. Practice is authored
in MotifPath (content-production: exclude exercise material from the final deck).
Requires python-pptx.
"""
import json
import re
import sys
from pathlib import Path

from pptx import Presentation

UNIT_DIR = Path(__file__).resolve().parent.parent
REVIEW_STATE_LABELS = ("Pratique de novo", "Conferir resposta", "Uma dica", "Resposta:")
MIN_FRAGMENT = 12  # shorter strings ("Um semitom", "Casa 3") are legitimate lesson copy


def normalize(value):
    return re.sub(r"\s+", " ", value).strip().casefold()


def exercise_fragments(activities):
    fragments = set()
    for activity in activities:
        for item in (activity, activity.get("retry") or {}):
            for field in ("prompt", "hint", "rationale"):
                if item.get(field):
                    fragments.add(item[field])
            for option in item.get("options", []):
                if option.get("reason"):
                    fragments.add(option["reason"])
    return {normalize(f) for f in fragments if len(f) >= MIN_FRAGMENT}


def deck_texts(path):
    """Yield (location, text) for every slide, including hidden ones, and every note."""
    for number, slide in enumerate(Presentation(path).slides, 1):
        if slide._element.get("show") == "0":
            yield f"slide {number}", "HIDDEN SLIDE"
        for shape in slide.shapes:
            if shape.has_text_frame:
                yield f"slide {number}", shape.text_frame.text
            if shape.has_table:
                for cell in (c for row in shape.table.rows for c in row.cells):
                    yield f"slide {number}", cell.text
        if slide.has_notes_slide:
            yield f"notes {number}", slide.notes_slide.notes_text_frame.text


def problems_in(path, fragments):
    found = []
    for location, raw in deck_texts(path):
        text = normalize(raw)
        if raw == "HIDDEN SLIDE":
            found.append(f"{location}: hidden slide")
        found += [f"{location}: label “{label}”" for label in REVIEW_STATE_LABELS
                  if normalize(label) in text]
        found += [f"{location}: exercise text “{f[:60]}”" for f in fragments if f in text]
    return found


def main(argv):
    activities = json.loads((UNIT_DIR / "activities.json").read_text(encoding="utf-8"))
    fragments = exercise_fragments(activities)
    decks = [Path(a) for a in argv] or sorted(
        p for p in (UNIT_DIR / "slides").glob("*.pptx")
        if not p.name.startswith("~$"))  # PowerPoint lock files while a deck is open
    failed = False
    for deck in decks:
        problems = problems_in(deck, fragments)
        status = "FAIL" if problems else "ok"
        print(f"{status}  {deck.name}  ({len(fragments)} exercise fragments checked)")
        for problem in problems:
            print(f"      {problem}")
        failed |= bool(problems)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
