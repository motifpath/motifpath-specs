"""Build the two first-notes learner decks from the MotifPath presentation library.

Usage: python3 build_slides.py <template.pptx> <out_dir>

Learner delivery only: no exercise prompts, options, answers, feedback or retries
appear on slides, hidden slides or speaker notes. Practice lives in MotifPath.
Diagrams are native editable shapes; text alternatives are in the speaker notes.
"""
import copy
import sys
from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_CONNECTOR, MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.oxml.ns import qn
from pptx.util import Emu, Pt

# Brand tokens (motifpath-brand/tokens.json via the presentation guide).
INDIGO, VIOLET, LILAC = "05072C", "6D28E0", "C97CFF"
CREAM, INK, MUTED = "FBFAFF", "1A1633", "5B5470"
RULE, TINT, DARK, WHITE = "E4DEF3", "EFE8FF", "0B0D2E", "FFFFFF"
STRING_GRAY, FRET_GRAY = "B9B2CC", "8E86A6"

# Template library slide numbers used as frames (1-based).
FRAME_COVER, FRAME_LIGHT, FRAME_DARK, FRAME_CLOSING = 6, 11, 12, 35
FRAME_KEEP_TEXT = {"MotifPath"}


def px(value):
    return Emu(int(round(value * 9525)))


def rgb(hex_color):
    return RGBColor.from_string(hex_color)


# ---------------------------------------------------------------- slide frames

def clone_slide(prs, src):
    """Append a copy of src (shapes, background, image relationships)."""
    new = prs.slides.add_slide(src.slide_layout)
    for shape in list(new.shapes):
        shape._element.getparent().remove(shape._element)
    rid_map = {}
    for rid, rel in src.part.rels.items():
        if rel.reltype.endswith("/image"):
            rid_map[rid] = new.part.relate_to(rel._target, rel.reltype)
    src_bg = src._element.cSld.find(qn("p:bg"))
    if src_bg is not None:
        new._element.cSld.insert(0, copy.deepcopy(src_bg))
    for el in src.shapes._spTree.iterchildren():
        if el.tag in (qn("p:nvGrpSpPr"), qn("p:grpSpPr")):
            continue
        clone = copy.deepcopy(el)
        for node in clone.iter():
            for attr in (qn("r:embed"), qn("r:link")):
                if node.get(attr) in rid_map:
                    node.set(attr, rid_map[node.get(attr)])
        new.shapes._spTree.append(clone)
    return new


def strip_to_frame(slide):
    """Keep pictures, the brand name and the page number; drop example copy."""
    for shape in list(slide.shapes):
        if shape.shape_type == 13:
            continue
        text = shape.text_frame.text.strip() if shape.has_text_frame else ""
        if text in FRAME_KEEP_TEXT or (text.isdigit() and len(text) <= 2):
            continue
        shape._element.getparent().remove(shape._element)


def set_page_number(slide, number):
    for shape in slide.shapes:
        if shape.has_text_frame and shape.text_frame.text.strip().isdigit():
            shape.text_frame.paragraphs[0].runs[0].text = f"{number:02d}"


def replace_runs(shape, lines):
    """Replace text of a template text shape, keeping each paragraph's first-run style."""
    tf = shape.text_frame
    paras = tf.paragraphs
    styles = [copy.deepcopy(p.runs[0]._r.find(qn("a:rPr"))) if p.runs else None for p in paras]
    template_p = paras[-1]._p
    for p in paras[1:]:
        p._p.getparent().remove(p._p)
    first = tf.paragraphs[0]
    for r in list(first.runs)[1:]:
        r._r.getparent().remove(r._r)
    for i, line in enumerate(lines):
        if i == 0:
            p = first
        else:
            p_el = copy.deepcopy(template_p)
            tf._txBody.append(p_el)
            p = tf.paragraphs[-1]
            for r in list(p.runs)[1:]:
                r._r.getparent().remove(r._r)
        style = styles[min(i, len(styles) - 1)]
        if p.runs:
            p.runs[0].text = line
            if style is not None:
                old = p.runs[0]._r.find(qn("a:rPr"))
                if old is not None:
                    p.runs[0]._r.replace(old, copy.deepcopy(style))
        else:
            p.add_run().text = line


def find_shape(slide, startswith):
    for shape in slide.shapes:
        if shape.has_text_frame and shape.text_frame.text.startswith(startswith):
            return shape
    raise KeyError(startswith)


# ---------------------------------------------------------------- primitives

def text(slide, x, y, w, h, paras, size=20, color=INK, bold=False, align="l",
         anchor="t", spacing=4, name=None):
    """paras: list of str or list of (text, {opts}) runs. Opts: b, c, sz, i."""
    box = slide.shapes.add_textbox(px(x), px(y), px(w), px(h))
    if name:
        box.name = name
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = {"t": MSO_ANCHOR.TOP, "m": MSO_ANCHOR.MIDDLE, "b": MSO_ANCHOR.BOTTOM}[anchor]
    if isinstance(paras, str):
        paras = [paras]
    for i, para in enumerate(paras):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = {"l": PP_ALIGN.LEFT, "c": PP_ALIGN.CENTER, "r": PP_ALIGN.RIGHT}[align]
        if i:
            p.space_before = Pt(spacing)
        runs = [(para, {})] if isinstance(para, str) else para
        for run_text, opts in runs:
            r = p.add_run()
            r.text = run_text
            f = r.font
            f.size = Pt(opts.get("sz", size))
            f.bold = opts.get("b", bold)
            f.italic = opts.get("i", False)
            f.color.rgb = rgb(opts.get("c", color))
    return box


def rect(slide, x, y, w, h, fill=None, line=None, line_w=1.0, shape=MSO_SHAPE.RECTANGLE,
         name=None, radius=None):
    s = slide.shapes.add_shape(shape, px(x), px(y), px(w), px(h))
    if name:
        s.name = name
    if fill:
        s.fill.solid()
        s.fill.fore_color.rgb = rgb(fill)
    else:
        s.fill.background()
    if line:
        s.line.color.rgb = rgb(line)
        s.line.width = Pt(line_w)
    else:
        s.line.fill.background()
    if radius is not None and shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        s.adjustments[0] = radius
    s.shadow.inherit = False
    return s


def label_shape(s, value, size=16, color=INK, bold=True):
    tf = s.text_frame
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    lines = value.split("\n")
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = PP_ALIGN.CENTER
        r = p.add_run()
        r.text = line
        r.font.size = Pt(size)
        r.font.bold = bold
        r.font.color.rgb = rgb(color)


def line(slide, x1, y1, x2, y2, color=INK, width=1.0, name=None):
    c = slide.shapes.add_connector(MSO_CONNECTOR.STRAIGHT, px(x1), px(y1), px(x2), px(y2))
    c.line.color.rgb = rgb(color)
    c.line.width = Pt(width)
    if name:
        c.name = name
    return c


def chip(slide, x, y, w, h, value, fill=VIOLET, color=WHITE, size=20, line_color=None, bold=True):
    s = rect(slide, x, y, w, h, fill=fill, line=line_color, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.18)
    label_shape(s, value, size=size, color=color, bold=bold)
    return s


# ---------------------------------------------------------------- diagrams

WHITE_KEYS = [("Dó", "C4"), ("Ré", "D4"), ("Mi", "E4"), ("Fá", "F4"), ("Sol", "G4"),
              ("Lá", "A4"), ("Si", "B4"), ("Dó", "C5")]
BLACK_AFTER = {0: "C♯4", 1: "D♯4", 3: "F♯4", 4: "G♯4", 5: "A♯4"}


def keyboard(slide, x, y, key_w, key_h, highlight=None, badges=None, black_labels=None):
    """C4–C5 with every intermediate black key. highlight: {key_id: fill}; key ids are
    'C4'… for white keys and 'C♯4'… for black keys. badges: {key_id: str} count badges."""
    highlight = highlight or {}
    badges = badges or {}
    black_labels = black_labels or {}
    centers = {}
    for i, (name, letter) in enumerate(WHITE_KEYS):
        kx = x + i * key_w
        fill = highlight.get(letter, WHITE)
        rect(slide, kx, y, key_w, key_h, fill=fill, line=FRET_GRAY, line_w=1.0,
             name=f"Tecla {letter}")
        txt_color = WHITE if fill == VIOLET else INK
        text(slide, kx, y + key_h - 74, key_w, 30, [[(name, {"b": True})]], size=17,
             color=txt_color, align="c")
        text(slide, kx, y + key_h - 44, key_w, 26, letter, size=14, color=txt_color, align="c")
        centers[letter] = (kx + key_w / 2, y + key_h - 100)
    bw, bh = key_w * 0.6, key_h * 0.58
    for i, letter in BLACK_AFTER.items():
        bx = x + (i + 1) * key_w - bw / 2
        fill = highlight.get(letter, INK)
        rect(slide, bx, y, bw, bh, fill=fill, line=INK, line_w=0.75, name=f"Tecla {letter}")
        if letter in black_labels:
            text(slide, bx - 30, y - 34, bw + 60, 28, black_labels[letter], size=14,
                 color=VIOLET, bold=True, align="c")
        centers[letter] = (bx + bw / 2, y + bh - 34)
    for key, value in badges.items():
        cx, cy = centers[key]
        b = rect(slide, cx - 17, cy - 17, 34, 34, fill=WHITE, line=VIOLET, line_w=2,
                 shape=MSO_SHAPE.OVAL, name=f"Contagem {key}")
        label_shape(b, value, size=15, color=VIOLET)


def fretboard(slide, x, y, title, strings, marks, frets=4, width=500, gap=26):
    """Front view, nut on the left, lowest string at the bottom.
    strings: names top→bottom; the last one is highlighted (low E).
    marks: list of (fret, pitch_name, register) on the highlighted string; fret 0 = open."""
    text(slide, x, y, width, 30, [[(title, {"b": True})]], size=17, color=VIOLET)
    top = y + 74
    name_w = 54
    open_w = 52
    nut_x = x + name_w + open_w
    fret_w = (width - name_w - open_w) / frets
    bottom = top + gap * (len(strings) - 1)
    rect(slide, nut_x, top - 10, frets * fret_w, bottom - top + 20, fill=TINT, name="Braço")
    rect(slide, nut_x - 6, top - 12, 8, bottom - top + 24, fill=INK, name="Pestana")
    for f in range(1, frets + 1):
        fx = nut_x + f * fret_w
        line(slide, fx, top - 10, fx, bottom + 10, color=FRET_GRAY, width=2, name=f"Traste {f}")
    for i, s_name in enumerate(strings):
        sy = top + i * gap
        low = i == len(strings) - 1
        line(slide, x + name_w, sy, nut_x + frets * fret_w, sy,
             color=VIOLET if low else STRING_GRAY, width=4.5 if low else 1.25,
             name=f"Corda {s_name}" + (" grave" if low else ""))
        text(slide, x, sy - 12, name_w - 8, 24, [[(s_name, {"b": low})]], size=13,
             color=VIOLET if low else MUTED, align="r")
    row_y = bottom + 22
    for fret, pitch, register in marks:
        cx = x + name_w + open_w / 2 if fret == 0 else nut_x + (fret - 0.5) * fret_w
        r = 13
        if fret == 0:
            rect(slide, cx - r, bottom - r, 2 * r, 2 * r, fill=WHITE, line=VIOLET, line_w=2.5,
                 shape=MSO_SHAPE.OVAL, name=f"Corda solta {register}")
        else:
            rect(slide, cx - r, bottom - r, 2 * r, 2 * r, fill=VIOLET, shape=MSO_SHAPE.OVAL,
                 name=f"Posição {register}")
        text(slide, cx - 45, row_y, 90, 24, [[(pitch, {"b": True})]], size=15, color=INK, align="c")
        text(slide, cx - 45, row_y + 22, 90, 22, register, size=13, color=MUTED, align="c")
    num_y = row_y + 52
    labels = ["solta"] + [f"casa {f}" for f in range(1, frets + 1)]
    for f, lab in enumerate(labels):
        cx = x + name_w + open_w / 2 if f == 0 else nut_x + (f - 0.5) * fret_w
        text(slide, cx - 45, num_y, 90, 22, lab, size=12, color=MUTED, align="c")
    text(slide, nut_x - 50, top - 36, 100, 20, "pestana", size=12, color=MUTED, align="c")
    return num_y + 24


CHROMATIC = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B", "C"]
NATURALS = {0: "Dó", 2: "Ré", 4: "Mi", 5: "Fá", 7: "Sol", 9: "Lá", 11: "Si", 12: "Dó"}


def c_major_ruler(slide, x, y, step):
    """Chromatic ruler C4–C5; naturals at 0,2,4,5,7,9,11,12; distances below."""
    line(slide, x, y + 60, x + 12 * step, y + 60, color=RULE, width=3, name="Régua cromática")
    for pos in range(13):
        cx = x + pos * step
        natural = pos in NATURALS
        text(slide, cx - 30, y, 60, 22, str(pos), size=12, color=MUTED, align="c")
        if natural:
            c = rect(slide, cx - 30, y + 30, 60, 60, fill=VIOLET, shape=MSO_SHAPE.OVAL,
                     name=f"Nota natural {pos}")
            label_shape(c, CHROMATIC[pos], size=18, color=WHITE)
            text(slide, cx - 40, y + 98, 80, 26, [[(NATURALS[pos], {"b": True})]], size=17,
                 align="c")
        else:
            c = rect(slide, cx - 13, y + 47, 26, 26, fill=WHITE, line=FRET_GRAY, line_w=1.25,
                     shape=MSO_SHAPE.OVAL, name=f"Posição intermediária {pos}")
            text(slide, cx - 30, y + 98, 60, 22, CHROMATIC[pos], size=13, color=MUTED, align="c")
    nat = sorted(NATURALS)
    for a, b in zip(nat, nat[1:]):
        d = b - a
        xa, xb = x + a * step + 8, x + b * step - 8
        by = y + 150
        line(slide, xa, by, xb, by, color=VIOLET if d == 1 else INK, width=2)
        line(slide, xa, by - 8, xa, by, color=VIOLET if d == 1 else INK, width=2)
        line(slide, xb, by - 8, xb, by, color=VIOLET if d == 1 else INK, width=2)
        # One unit per label: 2 semitones read as 1T (one tone), never "2 T".
        label = "1S" if d == 1 else "1T"
        text(slide, xa, by + 8, xb - xa, 26,
             [[(label, {"b": True, "c": VIOLET if d == 1 else INK})]], size=17, align="c")


FINGERS = ("index", "middle", "ring", "pinky")


def hand_sign(slide, x, y, w, raised, name):
    """Original stylized hand (palm facing the viewer): raised fingers are tall, the
    others are folded stubs. raised: subset of {'thumb', 'index', 'middle', 'ring', 'pinky'}."""
    u = w / 5
    palm_x, palm_w = x + 1.1 * u, 3.8 * u
    palm_y, palm_h = y + 2.4 * u, 1.9 * u
    for i, finger in enumerate(FINGERS):
        fx = palm_x + 0.1 * u + i * 0.92 * u
        up = finger in raised
        fy = y if up else palm_y - 0.55 * u
        fh = (palm_y - y) + 0.5 * u if up else 1.0 * u
        rect(slide, fx, fy, 0.78 * u, fh, fill=VIOLET, shape=MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.5, name=f"{name}: dedo {finger}{' levantado' if up else ''}")
    rect(slide, palm_x, palm_y, palm_w, palm_h, fill=VIOLET,
         shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.3, name=f"{name}: palma")
    if "thumb" in raised:
        t = rect(slide, x + 0.45 * u, palm_y - 0.7 * u, 0.78 * u, 2.0 * u, fill=VIOLET,
                 shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.5, name=f"{name}: polegar levantado")
        t.rotation = -35


PIANO_LOW, PIANO_HIGH = 21, 108  # A0–C8 (MIDI)
WHITE_PCS = {0, 2, 4, 5, 7, 9, 11}


def note_label(midi):
    names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    return f"{names[midi % 12]}{midi // 12 - 1}"


def range_chart(slide, x, y, w, bars):
    """88-key keyboard A0–C8 with sounding-range bars above it. bars: (label, low, high, fill)."""
    whites = [m for m in range(PIANO_LOW, PIANO_HIGH + 1) if m % 12 in WHITE_PCS]
    kw = w / len(whites)
    index = {m: i for i, m in enumerate(whites)}

    def center(m):
        return x + (index[m] + 0.5) * kw if m in index else x + (index[m - 1] + 1) * kw

    for row, (label, low, high, fill) in enumerate(bars):
        by = y + row * 46
        b = rect(slide, center(low) - kw / 2, by, center(high) - center(low) + kw, 36, fill=fill,
                 shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.3, name=f"Extensão {label}")
        label_shape(b, f"{label}  {note_label(low)}–{note_label(high)}", size=15, color=WHITE)
    ky, kh = y + len(bars) * 46 + 14, 120
    for m in whites:
        rect(slide, center(m) - kw / 2, ky, kw, kh, fill=LILAC if m == 60 else WHITE,
             line=FRET_GRAY, line_w=0.5, name=f"Tecla {note_label(m)}")
    for m in range(PIANO_LOW, PIANO_HIGH + 1):
        if m % 12 not in WHITE_PCS:
            rect(slide, center(m) - kw * 0.3, ky, kw * 0.6, kh * 0.6, fill=INK,
                 name=f"Tecla {note_label(m)}")
    for m in whites:
        if m % 12 == 0:
            text(slide, center(m) - 40, ky + kh + 8, 80, 22, [[(note_label(m), {"b": m == 60})]],
                 size=13, color=VIOLET if m == 60 else MUTED, align="c")
    return ky + kh + 34


def tone_split(slide, x, y, w):
    """One tone drawn as a bar split into two equal semitones (dark slide)."""
    top = rect(slide, x, y, w, 64, fill=LILAC, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.2,
               name="1 tom")
    label_shape(top, "1 tom", size=24, color=INDIGO)
    half = (w - 12) / 2
    for i in range(2):
        h = rect(slide, x + i * (half + 12), y + 80, half, 64, fill="1C1F4A", line=LILAC,
                 line_w=1.5, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.2, name=f"Semitom {i + 1}")
        label_shape(h, "1 semitom", size=20, color=WHITE)


# ---------------------------------------------------------------- deck assembly

class Deck:
    def __init__(self, template_path):
        self.prs = Presentation(template_path)
        self.frames = list(self.prs.slides)
        self.count = 0

    def _new(self, frame_no, notes):
        slide = clone_slide(self.prs, self.frames[frame_no - 1])
        for shape in slide.shapes:
            if shape.shape_type == 13:
                full_bleed = shape.width > px(1000)
                shape._element.nvPicPr.cNvPr.set(
                    "descr", "Arte decorativa: fita violeta" if full_bleed else "Logotipo MotifPath")
        self.count += 1
        set_page_number(slide, self.count)
        slide.notes_slide.notes_text_frame.text = notes
        return slide

    def light(self, title, notes):
        s = self._new(FRAME_LIGHT, notes)
        strip_to_frame(s)
        text(s, 64, 112, 1150, 60, [[(title, {"b": True})]], size=34, name="Título")
        return s

    def dark(self, title, notes):
        s = self._new(FRAME_DARK, notes)
        strip_to_frame(s)
        text(s, 64, 112, 1150, 60, [[(title, {"b": True})]], size=34, color=WHITE, name="Título")
        return s

    def cover(self, title_lines, promise, notes):
        """Title and promise only: level and instrument metadata stay off the cover."""
        s = self._new(FRAME_COVER, notes)
        replace_runs(find_shape(s, "[Lesson title]"), title_lines)
        replace_runs(find_shape(s, "[A concrete musical result]"), [promise])
        return s

    def closing(self, heading_lines, detail, notes):
        s = self._new(FRAME_CLOSING, notes)
        replace_runs(find_shape(s, "[A useful next"), heading_lines)
        body = find_shape(s, "[Reference, linked practice")
        replace_runs(body, [detail])
        body.width = px(560)  # keep the copy clear of the ribbon artwork
        for shape in list(s.shapes):  # template title hidden behind the background art
            if shape.has_text_frame and shape.text_frame.text == "Your next practice":
                shape._element.getparent().remove(shape._element)
        return s

    def save(self, path, title):
        sld_ids = self.prs.slides._sldIdLst
        for sld_id in list(sld_ids)[: len(self.frames)]:
            self.prs.part.drop_rel(sld_id.rId)
            sld_ids.remove(sld_id)
        props = self.prs.core_properties
        props.title = title
        props.subject = "MotifPath · Primeiras notas · pt_BR"
        props.author = "MotifPath"
        props.keywords = "MOT-160; first-notes; pt_BR"
        self.prs.save(path)


def two_cards(s, left_head, left_body, right_head, right_body, y=200, h=300, size=22):
    for i, (head, body) in enumerate(((left_head, left_body), (right_head, right_body))):
        cx = 64 + i * 586
        rect(s, cx, y, 564, h, fill=WHITE, line=RULE, shape=MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.05, name=f"Cartão {head}")
        text(s, cx + 32, y + 28, 500, 34, [[(head, {"b": True})]], size=22, color=VIOLET)
        text(s, cx + 32, y + 80, 500, h - 100, body, size=size, spacing=12)


def practice_banner(s, body, y=540):
    rect(s, 64, y, 1152, 78, fill=VIOLET, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.12,
         name="Prática no MotifPath")
    text(s, 92, y, 1100, 78, [[("Prática no MotifPath  ", {"b": True}), (body, {})]],
         size=20, color=WHITE, anchor="m")


def steps_row(s, steps, y=210):
    for i, (num, head, body) in enumerate(steps):
        cx = 64 + i * 292
        text(s, cx, y, 272, 40, [[(num, {"b": True, "c": LILAC, "sz": 30})]], size=30)
        text(s, cx, y + 48, 272, 36, [[(head, {"b": True})]], size=22, color=VIOLET)
        text(s, cx, y + 92, 262, 90, body, size=20)


def callout(s, y, h, paras, size=20):
    rect(s, 64, y, 1152, h, fill=TINT, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.1,
         name="Destaque")
    text(s, 96, y, 1100, h, paras, size=size, anchor="m", spacing=6)


NAMES = ["Dó", "Ré", "Mi", "Fá", "Sol", "Lá", "Si"]
LETTERS = ["C", "D", "E", "F", "G", "A", "B"]

# Speaker notes keep text alternatives and presenter detail; slides keep only the essentials.
NO_EXERCISES = ("Entrega ao estudante: as atividades desta lição são feitas na prática do "
                "MotifPath; não há perguntas, respostas ou feedback neste arquivo.")


def build_lesson_a(template, out):
    d = Deck(template)
    d.cover(["C, D, E…"], "O código que todo músico usa",
            "Lição A, pt_BR, versão 2 do artigo (PR #436). " + NO_EXERCISES)

    s = d.light("Para que você vai usar isso?",
                "Abertura de aplicação. Desejo da pessoa: tocar suas músicas com outras pessoas e "
                "seguir cifras e tutoriais sem travar. O primeiro passo é o código de nomes: quando "
                "alguém diz “a música está em G”, você sabe que é Sol; C, D, E deixam de ser letras "
                "soltas. Numa cifra, C indica o acorde de Dó maior; tocar a nota Dó e tocar o acorde "
                "são ações diferentes, estudadas depois. A lição não exige reconhecer notas de ouvido "
                "nem decorar o braço. Instrumento é opcional.")
    two_cards(s, "Seu objetivo",
              ["Tocar com outras pessoas", "Seguir cifras e tutoriais sem travar"],
              "O primeiro passo",
              ["“Está em G”: você sabe que é Sol", "C, D, E deixam de ser letras soltas"],
              y=210, h=260, size=24)

    s = d.light("As sete notas",
                "Construção em três slides. Primeiro, os sete nomes em português, na ordem: Dó, Ré, "
                "Mi, Fá, Sol, Lá, Si.")
    names_and_letters(s, 206, letters=False)  # same positions as the next two slides

    s = d.light("Cada nota tem uma letra",
                "Alternativa textual: Dó=C, Ré=D, Mi=E, Fá=F, Sol=G, Lá=A, Si=B. Leia nos dois "
                "sentidos: A é Lá.")
    names_and_letters(s, 206)

    s = d.light("Um nome, duas escritas",
                "Resumo da construção. Exemplo resolvido: Mi–Fá–Sol corresponde a E–F–G; as notas "
                "são as mesmas, muda só a escrita.")
    names_and_letters(s, 206)
    callout(s, 430, 130, [[("Mi–Fá–Sol  =  E–F–G", {"b": True, "c": VIOLET, "sz": 32})],
                          "Mesmas notas, outra escrita."])

    s = d.light("O código também nas mãos",
                "Outra forma do mesmo código: no palco, músicos combinam o tom da música com sinais "
                "de mão, com a palma voltada para a banda. Desenhos originais e simplificados: Dó, "
                "indicador levantado; Ré, indicador e médio; Mi, três dedos; Fá, quatro dedos; Sol, "
                "mão aberta; Lá, polegar e mínimo; Si, polegar e indicador. Em geral, a palma para a "
                "frente indica maior e o dorso da mão indica menor; maior e menor são assunto de "
                "outra lição. As convenções variam entre grupos: combine os sinais antes de tocar. "
                "PENDENTE: confirmar o sinal de Si com a revisão musical antes da publicação.")
    signs = [("Dó", {"index"}), ("Ré", {"index", "middle"}), ("Mi", {"index", "middle", "ring"}),
             ("Fá", set(FINGERS)), ("Sol", {"thumb", *FINGERS}), ("Lá", {"thumb", "pinky"}),
             ("Si", {"thumb", "index"})]
    for i, (n, raised) in enumerate(signs):
        cx = 72 + i * 164
        hand_sign(s, cx + 12, 220, 120, raised, f"Sinal de {n}")
        text(s, cx, 360, 140, 40, [[(n, {"b": True})]], size=26, align="c")
    text(s, 64, 470, 1152, 50, "No palco, a banda combina o tom com as mãos.", size=24)

    s = d.light("Os nomes no teclado",
                "Alternativa textual: teclas brancas da esquerda para a direita C4, D4, E4, F4, "
                "G4, A4, B4, C5. Duas teclas pretas entre C4 e E4 e três entre F4 e B4. O Dó é a "
                "tecla branca imediatamente à esquerda do grupo de duas teclas pretas; depois "
                "seguem Ré, Mi, Fá, Sol, Lá e Si. Exemplo resolvido: F4 → Fá, tecla destacada. "
                "As teclas pretas também são notas; seus nomes aparecem na próxima lição.")
    keyboard(s, 64, 210, 88, 320, highlight={"F4": LILAC})
    text(s, 790, 250, 426, 260,
         [[("Dó", {"b": True, "c": VIOLET}), (": à esquerda das duas teclas pretas.", {})],
          [("F4 = Fá", {"b": True, "c": VIOLET, "sz": 30})]],
         size=24, spacing=28)

    s = d.dark("O nome se repete; a altura muda",
               "Depois do Si, os nomes recomeçam em Dó numa outra oitava. C4 e C5 são dois Dós; "
               "C5 está uma oitava acima, mais aguda. O número indica a oitava no sistema de "
               "referência, não casa, corda ou dedo. O nome Dó, sozinho, não diz a oitava.")
    row = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
    for i, lab in enumerate(row):
        hl = lab in ("C4", "C5")
        chip(s, 64 + i * 144, 220, 128, 70, lab, fill=LILAC if hl else "1C1F4A",
             color=INDIGO if hl else "E4D6FF", size=24)
    text(s, 64, 340, 1152, 140,
         ["C4 e C5 são dois Dós.", "C5 está uma oitava acima."],
         size=40, color=WHITE, bold=True, spacing=6)
    text(s, 64, 520, 1152, 50, "O número indica a oitava, não casa, corda ou dedo.",
         size=22, color=LILAC)

    s = d.light("Conhecendo o braço",
                "Vocabulário: corda solta (tocar sem pressionar uma casa), pestana (peça junto ao "
                "começo do braço), traste (divisão de metal) e casa (espaço entre dois trastes, "
                "ou entre a pestana e o primeiro traste). Nos desenhos, o braço está de frente, "
                "com a pestana à esquerda e a corda Mi mais grave embaixo, mais grossa.")
    terms = [("Corda solta", "Sem pressionar casa."),
             ("Pestana", "Início do braço."),
             ("Traste", "Divisão de metal."),
             ("Casa", "Espaço entre trastes.")]
    for i, (term, desc) in enumerate(terms):
        cx = 64 + i * 292
        rect(s, cx, 220, 272, 200, fill=WHITE, line=RULE, shape=MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.06, name=f"Termo {term}")
        text(s, cx + 24, 252, 230, 36, [[(term, {"b": True})]], size=24, color=VIOLET)
        text(s, cx + 24, 306, 226, 100, desc, size=22)

    s = d.light("Para localizar uma nota",
                "Método em quatro passos, demonstrado com Sol no slide seguinte: G, rótulo G, casa 3 "
                "na corda Mi grave (G2 na guitarra, G1 no baixo). A casa 3 é uma posição no braço, "
                "não uma instrução para usar o terceiro dedo. Tocar é opcional e exige afinação "
                "padrão: pressione dentro da casa, perto do traste à direita, sem apertar sobre o "
                "metal.")
    steps_row(s, [("01", "Nome", "Sol"),
                  ("02", "Letra", "G"),
                  ("03", "Rótulo", "Ache G no desenho."),
                  ("04", "Corda e casa", "Corda Mi, casa 3.")])
    callout(s, 450, 110, [[("Casa 3 ", {"b": True, "c": VIOLET}),
                           ("é uma posição, não o terceiro dedo.", {})]], size=24)

    s = d.light("Guitarra e baixo: corda Mi",
                "Alternativa textual. Guitarra, sexta corda em afinação padrão: solta Mi E2, "
                "casa 1 Fá F2, casa 3 Sol G2. Baixo, quarta corda em afinação padrão: solta Mi E1, "
                "casa 1 Fá F1, casa 3 Sol G1. A casa 2 fica sem nome nesta etapa, o que não "
                "significa que ela não tenha nota. Círculo vazio: corda solta. Cada ponto é uma "
                "posição alternativa na mesma corda, não notas tocadas juntas. O Mi solto do baixo "
                "(E1) fica uma oitava abaixo do E2 da guitarra. Cordas da guitarra de cima para "
                "baixo: Mi, Si, Sol, Ré, Lá, Mi. Cordas do baixo: Sol, Ré, Lá, Mi.")
    marks_a = lambda o: [(0, "Mi", f"E{o}"), (1, "Fá", f"F{o}"), (3, "Sol", f"G{o}")]
    fretboard(s, 64, 200, "Guitarra · 6ª corda",
              ["Mi", "Si", "Sol", "Ré", "Lá", "Mi"], marks_a(2), width=540, gap=24)
    fretboard(s, 676, 200, "Baixo · 4ª corda",
              ["Sol", "Ré", "Lá", "Mi"], marks_a(1), width=540, gap=24)
    text(s, 64, 570, 1152, 40, "○ corda solta    ● posição na mesma corda",
         size=18, color=MUTED)

    s = d.light("Onde cada instrumento toca",
                "Alternativa textual: teclado de 88 teclas, de A0 a C8, com o Dó central (C4) "
                "destacado. Faixas de altura real (som que soa): teclado A0–C8; guitarra E2–D6, com "
                "22 casas; baixo E1–D sustenido 4, com 20 casas. A extensão muda com o número de "
                "casas. Numa banda, o baixo sustenta o grave, a guitarra ocupa o meio e o teclado "
                "alcança toda a extensão; as faixas se sobrepõem, por isso os músicos dividem as "
                "regiões ao tocar juntos.")
    end = range_chart(s, 64, 196, 1152, [("Teclado", 21, 108, "1C1F4A"),
                                          ("Guitarra", 40, 86, VIOLET),
                                          ("Baixo", 28, 63, "4C1D95")])
    text(s, 64, end + 14, 1152, 40,
         [[("Baixo", {"b": True}), (" no grave, ", {}), ("guitarra", {"b": True}),
           (" no meio, ", {}), ("teclado", {"b": True}), (" em toda a extensão.", {})]], size=22)

    s = d.light("Aplicação: uma frase",
                "Frase de estudo original: Mi–Fá–Sol–Fá–Mi, ou E–F–G–F–E. Na corda Mi grave da "
                "guitarra ou do baixo: solta, casa 1, casa 3, casa 1, solta. A frase começa em "
                "Mi, sobe até Sol e volta a Mi. Aponte cada nome na ordem; tocar ou cantar é "
                "opcional. Na guitarra e no baixo as alturas exatas mudam; a ordem dos nomes "
                "continua a mesma.")
    rows = [("Nomes", ["Mi", "Fá", "Sol", "Fá", "Mi"], WHITE, INK, RULE),
            ("Letras", ["E", "F", "G", "F", "E"], VIOLET, WHITE, None),
            ("Corda Mi", ["solta", "casa 1", "casa 3", "casa 1", "solta"], TINT, VIOLET, None)]
    for r_i, (lab, vals, fill, col, ln) in enumerate(rows):
        ry = 230 + r_i * 104
        text(s, 64, ry, 220, 80, [[(lab, {"b": True})]], size=20, color=MUTED, anchor="m")
        for c_i, v in enumerate(vals):
            chip(s, 290 + c_i * 186, ry, 168, 80, v, fill=fill, color=col,
                 size=28 if r_i < 2 else 22, line_color=ln)

    s = d.light("Você já fala o código",
                "Fechamento ligado à abertura. Conquista: ler C, D, E como Dó, Ré, Mi e achar a nota "
                "no teclado, na guitarra e no baixo com uma referência. Isso aproxima o objetivo da "
                "abertura: entender o que a banda pede e seguir cifras e tutoriais. Não mede "
                "reconhecimento auditivo nem fluência ao tocar. " + NO_EXERCISES)
    two_cards(s, "Você já consegue", ["Ler C, D, E… como Dó, Ré, Mi…", "Achar a nota no instrumento"],
              "Seu objetivo ficou mais perto", ["Entender o que a banda pede", "Seguir cifras e tutoriais"],
              y=210, h=260, size=24)
    practice_banner(s, "Atividades desta lição.")

    d.closing(["Nem todo passo", "é igual"],
              "Próxima lição: o padrão da escala maior.",
              "Próxima lição: “Nem todo passo é igual: o padrão da escala maior”. Os nomes dizem "
              "quais notas procurar; a próxima lição conta a distância entre elas e mostra por "
              "que alguns nomes vizinhos ficam mais perto que outros.")
    d.save(out, "C, D, E…: o código que todo músico usa")


def names_and_letters(s, y, letters=True):
    """Progressive build: identical positions on every slide that reveals the table."""
    text(s, 64, y + 18, 120, 30, "Nome", size=15, color=MUTED)
    if letters:
        text(s, 64, y + 104, 120, 30, "Letra", size=15, color=MUTED)
    for i, (n, l) in enumerate(zip(NAMES, LETTERS)):
        cx = 184 + i * 147
        chip(s, cx, y, 131, 66, n, fill=WHITE, color=INK, size=24, line_color=RULE)
        if letters:
            chip(s, cx, y + 82, 131, 72, l, fill=VIOLET, color=WHITE, size=30)


def build_lesson_b(template, out):
    d = Deck(template)
    d.cover(["Nem todo passo", "é igual"], "O padrão da escala maior",
            "Lição B, pt_BR, versão 2 do artigo (PR #436). " + NO_EXERCISES)

    s = d.light("Para que você vai usar isso?",
                "Abertura de aplicação. Desejo da pessoa: improvisar, criar os próprios solos e tocar "
                "uma música no tom de quem canta. O primeiro passo é saber quais notas cabem na "
                "música: a escala maior é o primeiro mapa, e ela nasce de passos de tom e semitom. "
                "Hoje: contar um ou dois semitons e aplicar em Dó maior, sem instrumento se preferir. "
                "Fora do escopo: improvisar, construir acordes, transpor uma escala inteira e "
                "reconhecer intervalos de ouvido.")
    two_cards(s, "Seu objetivo",
              ["Improvisar e criar seus solos", "Tocar no tom de quem canta"],
              "O primeiro passo",
              ["A escala maior é o primeiro mapa", "Ela nasce de tons e semitons"],
              y=210, h=260, size=24)

    s = d.light("Referência rápida",
                "Ponte com a lição “C, D, E…: o código que todo músico usa”: seções “Um mesmo nome "
                "pode aparecer de duas formas” (tabela de nomes e letras) e “O nome se repete; a "
                "altura muda” (números de oitava). Depois do Si, a sequência recomeça em Dó. Esta "
                "lição funciona sem abrir a anterior.")
    for i, (n, l) in enumerate(zip(NAMES, LETTERS)):
        chip(s, 64 + i * 166, 230, 150, 84, f"{n} = {l}", fill=WHITE, color=INK, size=24,
             line_color=RULE)
    callout(s, 380, 110, [[("C4 e C5: ", {"b": True, "c": VIOLET}),
                           ("mesmo nome, outra oitava.", {})]], size=24)

    s = d.dark("A menor contagem",
               "Alternativa textual do desenho: uma barra de um tom dividida em duas metades iguais, "
               "cada uma um semitom. Um semitom é meio tom: a próxima tecla, branca ou preta, ou a "
               "próxima casa na mesma corda. Um tom são dois semitons. Nos exemplos, a oitava tem "
               "12 semitons iguais. Contamos mudanças; o ponto de partida não é um passo.")
    tone_split(s, 64, 220, 560)
    text(s, 680, 220, 536, 150,
         [[("1 semitom = ½ tom", {"b": True, "c": LILAC, "sz": 40})],
          "a próxima tecla ou casa"], size=26, color=WHITE, spacing=10)
    text(s, 64, 520, 1152, 50, "Conte mudanças, não posições.", size=24, color="E4D6FF")

    s = d.light("Mi–Fá e Dó–Ré",
                "Alternativa textual: teclado C4 a C5 com todas as teclas pretas. Mi4 e Fá4 são "
                "vizinhas: contagem 0 em Mi4 e 1 em Fá4, um semitom. Dó4, Dó sustenido 4 e Ré4: "
                "contagem 0, 1 e 2, dois semitons ou um tom. A contagem começa em 0 na nota "
                "inicial.")
    keyboard(s, 64, 224, 84, 320,
             highlight={"C4": VIOLET, "C♯4": "4C1D95", "D4": VIOLET, "E4": LILAC, "F4": LILAC},
             badges={"C4": "0", "C♯4": "1", "D4": "2", "E4": "0", "F4": "1"},
             black_labels={"C♯4": "C♯/D♭"})
    text(s, 770, 250, 446, 280,
         [[("Mi → Fá", {"b": True, "sz": 28})],
          "1 semitom",
          [("Dó → Dó♯ → Ré", {"b": True, "c": VIOLET, "sz": 28})],
          "1 tom"],
         size=22, spacing=10)

    s = d.light("Sustenido e bemol",
                "Neste sistema de afinação, a tecla entre Dó e Ré pode ser chamada de Dó sustenido "
                "(C♯) ou Ré bemol (D♭). O sustenido sobe um semitom; o bemol desce um semitom. "
                "Não é preciso escolher a grafia agora: basta incluir a altura intermediária na "
                "contagem. Sustenidos e bemóis também podem nomear teclas brancas em outros "
                "contextos; a cor não define o símbolo.")
    two_cards(s, "♯  sobe 1 semitom", [[("Dó♯ (C♯)", {"b": True, "sz": 30})]],
              "♭  desce 1 semitom", [[("Ré♭ (D♭)", {"b": True, "sz": 30})]], y=210, h=200)
    callout(s, 450, 110, [[("Dó♯ e Ré♭: ", {"b": True, "c": VIOLET}),
                           ("a mesma tecla.", {})]], size=24)

    s = d.light("Como contar",
                "Método em quatro passos: identificar início e chegada; ver todas as teclas ou "
                "casas entre elas, inclusive as intermediárias; começar em zero e contar cada "
                "mudança; um passo é semitom, dois são um tom. Exemplo resolvido: Dó recebe 0, "
                "Dó sustenido 1, Ré 2; dois semitons. Erro comum: contar as três posições em vez "
                "das duas mudanças.")
    steps_row(s, [("01", "Início e chegada", "Marque as duas notas."),
                  ("02", "Caminho", "Inclua as intermediárias."),
                  ("03", "Conte", "Comece em 0."),
                  ("04", "Compare", ["1 = semitom", "2 = tom"])])
    callout(s, 450, 110, [[("Dó 0  ·  Dó♯ 1  ·  Ré 2  →  1 tom",
                            {"b": True, "c": VIOLET, "sz": 28})]])

    s = d.light("Na corda Mi",
                "Alternativa textual. Guitarra, sexta corda solta E2; casa 1 F2; casa 2 F sustenido "
                "2; casa 3 G2. Baixo, quarta corda solta E1; casa 1 F1; casa 2 F sustenido 1; casa 3 "
                "G1. Mi a Fá: solta para casa 1, um semitom. Fá a Sol: casa 1, 2 e 3, dois "
                "semitons; “suba um tom a partir de Fá” chega a Sol. Contar casas vale só na mesma "
                "corda; o número da casa indica a posição, não o dedo.")
    marks_b = lambda o: [(0, "Mi", f"E{o}"), (1, "Fá", f"F{o}"), (2, "Fá♯", f"F♯{o}"),
                         (3, "Sol", f"G{o}")]
    fretboard(s, 64, 200, "Guitarra · 6ª corda",
              ["Mi", "Si", "Sol", "Ré", "Lá", "Mi"], marks_b(2), width=540, gap=22)
    fretboard(s, 676, 200, "Baixo · 4ª corda",
              ["Sol", "Ré", "Lá", "Mi"], marks_b(1), width=540, gap=22)
    text(s, 64, 560, 1152, 40,
         [[("Mi → Fá: ", {"b": True}), ("1 semitom      ", {}),
           ("Fá → Sol: ", {"b": True}), ("1 tom      ", {}),
           ("Só na mesma corda.", {"c": MUTED})]], size=20)

    s = d.dark("Dois pares mais curtos",
               "Entre as notas naturais consecutivas, Mi–Fá e Si–Dó têm um semitom; os outros "
               "pares têm um tom. “Passar para o próximo nome” nem sempre percorre a mesma "
               "distância. Entre Sol e Lá há Sol sustenido/Lá bemol. De Si3 ao Dó4 seguinte, a "
               "oitava muda, mas as teclas são vizinhas.")
    text(s, 64, 240, 1152, 200,
         [[("Mi–Fá ", {"b": True, "c": LILAC}), ("e ", {"b": True}),
           ("Si–Dó", {"b": True, "c": LILAC}), (": 1 semitom.", {"b": True})],
          [("Os outros vizinhos: 1 tom.", {"b": True})]],
         size=44, color=WHITE, spacing=12)

    s = d.light("Dó maior",
                "Alternativa textual da régua: de C4 a C5, posições 0 a 12, uma por semitom. Notas "
                "naturais em 0 Dó, 2 Ré, 4 Mi, 5 Fá, 7 Sol, 9 Lá, 11 Si, 12 Dó. Distâncias "
                "consecutivas: Dó–Ré 1 tom, Ré–Mi 1 tom, Mi–Fá 1 semitom, Fá–Sol 1 tom, Sol–Lá "
                "1 tom, Lá–Si 1 tom, Si–Dó 1 semitom. Padrão T–T–S–T–T–T–S; soma 12 semitons, "
                "chegando ao Dó uma oitava acima.")
    c_major_ruler(s, 112, 200, 88)
    callout(s, 450, 120, [[("T–T–S–T–T–T–S", {"b": True, "c": VIOLET, "sz": 32})],
                          [("T = tom    S = semitom    total: 12 semitons", {"c": MUTED})]])

    s = d.light("Dó–Ré–Mi–Fá",
                "Dó–Ré–Mi–Fá: um tom, um tom e um semitom. Todos os movimentos avançam para o "
                "próximo nome, mas o último é menor. Aponte cada nota e explique a distância até "
                "a seguinte, incluindo a tecla ou casa intermediária quando houver.")
    moves = [("tom", "2"), ("tom", "2"), ("semitom", "1")]
    for i, n in enumerate(["Dó", "Ré", "Mi", "Fá"]):
        chip(s, 64 + i * 300, 250, 190, 110, n, fill=VIOLET, color=WHITE, size=36)
    for i, (m, v) in enumerate(moves):
        mx = 254 + i * 300
        line(s, mx + 14, 305, mx + 96, 305, color=INK, width=2.5)
        text(s, mx, 250, 110, 30, [[(m, {"b": True})]], size=18,
             color=VIOLET if v == "1" else INK, align="c")
    callout(s, 450, 110, [[("O último passo é menor.", {"b": True, "c": VIOLET})]], size=26)

    s = d.light("Você já vê o padrão",
                "Fechamento ligado à abertura. Conquista: contar tons e semitons e montar Dó maior "
                "pelo padrão T–T–S–T–T–T–S. Esse padrão é a base para improvisar com a escala e "
                "tocar em outros tons, que são os objetivos da abertura; improvisar e transpor ainda "
                "são próximos passos. Não mede velocidade, execução nem reconhecimento das "
                "distâncias pelo som. Recursos externos opcionais ficam no artigo e no plano do "
                "professor. " + NO_EXERCISES)
    two_cards(s, "Você já consegue", ["Contar tons e semitons", "Montar a escala de Dó maior"],
              "Seu objetivo ficou mais perto", ["Base para improvisar", "e tocar em outros tons"],
              y=210, h=260, size=24)
    practice_banner(s, "Atividades desta lição.")

    d.closing(["Escolha outro par", "e refaça a contagem"],
              "Depois: escalas em outros tons e improviso.",
              "Próxima ação de prática: escolher outro par na régua e recontar. Depois, usar o "
              "mesmo padrão para montar escalas em outros tons, improvisar com elas e entender os "
              "intervalos que formam os acordes.")
    d.save(out, "Nem todo passo é igual: o padrão da escala maior")


if __name__ == "__main__":
    template, out_dir = sys.argv[1], Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    build_lesson_a(template, out_dir / "lesson-a.pt-BR.pptx")
    build_lesson_b(template, out_dir / "lesson-b.pt-BR.pptx")
    print("built", *sorted(p.name for p in out_dir.glob("*.pptx")))
