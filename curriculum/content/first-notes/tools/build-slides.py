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
        label = "S" if d == 1 else "T"
        text(slide, xa, by + 8, xb - xa, 26,
             [[(f"{d}  ", {"b": True}), (label, {"b": True, "c": VIOLET if d == 1 else INK})]],
             size=17, align="c")


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

    def cover(self, title_lines, result, meta, notes):
        s = self._new(FRAME_COVER, notes)
        replace_runs(find_shape(s, "[Lesson title]"), title_lines)
        replace_runs(find_shape(s, "[A concrete musical result]"), [result, meta])
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


def two_cards(s, left_head, left_body, right_head, right_body, y=200, h=300):
    for i, (head, body) in enumerate(((left_head, left_body), (right_head, right_body))):
        cx = 64 + i * 586
        rect(s, cx, y, 564, h, fill=WHITE, line=RULE, shape=MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.05, name=f"Cartão {head}")
        text(s, cx + 28, y + 24, 508, 34, [[(head, {"b": True})]], size=22, color=VIOLET)
        text(s, cx + 28, y + 72, 508, h - 90, body, size=19, spacing=10)


def practice_banner(s, body, y=545):
    rect(s, 64, y, 1152, 78, fill=VIOLET, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.12,
         name="Prática no MotifPath")
    text(s, 92, y, 1100, 78, [[("Prática no MotifPath  ", {"b": True}), (body, {})]],
         size=19, color=WHITE, anchor="m")


NO_EXERCISES = ("Entrega ao estudante: as atividades desta lição são feitas na prática do "
                "MotifPath; não há perguntas, respostas ou feedback neste arquivo.")


def build_lesson_a(template, out):
    d = Deck(template)
    d.cover(["Conheça", "as notas"], "Nomes que você pode encontrar",
            "Iniciante  /  Instrumento opcional",
            "Lição A, pt_BR, versão 2 do artigo (PR #436). " + NO_EXERCISES)

    s = d.light("Para que você vai usar isso?",
                "Abertura de aplicação. Uso imediato: entender um pedido como “toque a nota F” "
                "e acompanhar E–F–G escrito como Mi–Fá–Sol. Próximos assuntos: melodias, escalas "
                "e cifras. A lição não exige reconhecer notas de ouvido.")
    two_cards(s, "Uso agora",
              ["Alguém pede “toque a nota F”: você reconhece Fá e procura essa nota numa "
               "referência do instrumento.",
               "Você acompanha E–F–G mesmo quando outra pessoa escreve Mi–Fá–Sol."],
              "Nos próximos assuntos",
              ["Melodias e escalas: os nomes indicam quais notas tocar.",
               "Cifras: C indica o acorde de Dó maior. Tocar a nota Dó e tocar o acorde "
               "são ações diferentes."], y=196, h=316)
    text(s, 64, 540, 1152, 80,
         [[("Ao terminar: ", {"b": True, "c": VIOLET}),
           ("você relaciona nomes e letras e localiza exemplos com uma referência, sem "
            "reconhecer notas de ouvido nem decorar o braço inteiro. Instrumento é opcional.", {})]],
         size=19)

    s = d.light("Um mesmo nome, duas formas de escrever",
                "Alternativa textual da tabela: Dó=C, Ré=D, Mi=E, Fá=F, Sol=G, Lá=A, Si=B. "
                "Exemplo resolvido: Mi–Fá–Sol corresponde a E–F–G.")
    names = ["Dó", "Ré", "Mi", "Fá", "Sol", "Lá", "Si"]
    letters = ["C", "D", "E", "F", "G", "A", "B"]
    text(s, 64, 214, 120, 30, "Nome", size=15, color=MUTED)
    text(s, 64, 300, 120, 30, "Letra", size=15, color=MUTED)
    for i, (n, l) in enumerate(zip(names, letters)):
        cx = 184 + i * 147
        chip(s, cx, 196, 131, 66, n, fill=WHITE, color=INK, size=24, line_color=RULE)
        chip(s, cx, 278, 131, 72, l, fill=VIOLET, color=WHITE, size=30)
    text(s, 64, 384, 1152, 70,
         ["Escolha o nome na primeira linha e leia a letra logo abaixo. No sentido "
          "contrário também funciona: A é Lá. Cada letra tem seu próprio par."], size=20)
    rect(s, 64, 482, 1152, 116, fill=TINT, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.1,
         name="Exemplo resolvido")
    text(s, 96, 482, 1100, 116,
         [[("Mi–Fá–Sol  =  E–F–G", {"b": True, "c": VIOLET, "sz": 28})],
          "As mesmas notas; muda apenas a maneira de escrever seus nomes."],
         size=19, anchor="m", spacing=6)

    s = d.light("Os nomes no teclado",
                "Alternativa textual: teclas brancas da esquerda para a direita C4, D4, E4, F4, "
                "G4, A4, B4, C5. Duas teclas pretas entre C4 e E4 e três entre F4 e B4. A tecla "
                "F4 está destacada como exemplo resolvido.")
    keyboard(s, 64, 200, 88, 300, highlight={"F4": LILAC})
    tx = 790
    text(s, tx, 200, 426, 330,
         [[("Encontre o Dó: ", {"b": True}),
           ("a tecla branca imediatamente à esquerda do grupo de duas teclas pretas.", {})],
          "Depois dele seguem Ré, Mi, Fá, Sol, Lá e Si.",
          [("Exemplo: ", {"b": True, "c": VIOLET}),
           ("F4 → F é Fá → procure a tecla com o rótulo F4.", {"c": VIOLET})]],
         size=20, spacing=16)
    text(s, 64, 540, 1152, 60,
         "As teclas pretas também são notas. Vamos usar seus nomes na próxima lição, "
         "quando contarmos distâncias.", size=17, color=MUTED)

    s = d.dark("O nome se repete; a altura muda",
               "Depois do Si, os nomes recomeçam em Dó numa outra oitava. C4 e C5 são dois Dós; "
               "C5 está uma oitava acima, mais aguda. O número indica a oitava no sistema de "
               "referência, não casa, corda ou dedo.")
    row = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
    for i, lab in enumerate(row):
        hl = lab in ("C4", "C5")
        chip(s, 64 + i * 144, 210, 128, 70, lab, fill=LILAC if hl else "1C1F4A",
             color=INDIGO if hl else "E4D6FF", size=24)
    text(s, 64, 316, 1152, 140,
         ["C4 e C5 são dois Dós.", "C5 está uma oitava acima, mais aguda."],
         size=38, color=WHITE, bold=True, spacing=6)
    text(s, 64, 486, 1152, 110,
         ["O número identifica a oitava. Ele não indica casa, corda nem dedo.",
          "O nome Dó, sozinho, não diz em qual oitava a nota está."],
         size=21, color=LILAC, spacing=8)

    s = d.light("Palavras do braço",
                "Vocabulário: corda solta, pestana, traste e casa. Os desenhos seguintes usam "
                "esses termos.")
    terms = [("Corda solta", "Tocar a corda sem pressionar uma casa."),
             ("Pestana", "A peça junto ao começo do braço."),
             ("Traste", "Cada divisão de metal ao longo do braço."),
             ("Casa", "O espaço entre dois trastes, ou entre a pestana e o primeiro traste.")]
    for i, (term, desc) in enumerate(terms):
        cx = 64 + i * 292
        rect(s, cx, 200, 272, 250, fill=WHITE, line=RULE, shape=MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.06, name=f"Termo {term}")
        text(s, cx + 24, 224, 230, 36, [[(term, {"b": True})]], size=23, color=VIOLET)
        text(s, cx + 24, 276, 226, 160, desc, size=19)
    text(s, 64, 488, 1152, 110,
         ["Nos desenhos, o braço está de frente para você, com a pestana à esquerda. "
          "A corda Mi mais grave fica embaixo, mais grossa e com o nome indicado."], size=20)

    s = d.light("O mesmo raciocínio na guitarra e no baixo",
                "Alternativa textual. Guitarra, sexta corda em afinação padrão: solta Mi E2, "
                "casa 1 Fá F2, casa 3 Sol G2. Baixo, quarta corda em afinação padrão: solta Mi E1, "
                "casa 1 Fá F1, casa 3 Sol G1. A casa 2 fica sem nome nesta etapa, o que não "
                "significa que ela não tenha nota. Cordas da guitarra de cima para baixo: Mi, Si, "
                "Sol, Ré, Lá, Mi. Cordas do baixo: Sol, Ré, Lá, Mi.")
    marks_a = lambda o: [(0, "Mi", f"E{o}"), (1, "Fá", f"F{o}"), (3, "Sol", f"G{o}")]
    fretboard(s, 64, 192, "Guitarra · 6ª corda, afinação padrão",
              ["Mi", "Si", "Sol", "Ré", "Lá", "Mi"], marks_a(2), width=540, gap=24)
    fretboard(s, 676, 192, "Baixo · 4ª corda, afinação padrão",
              ["Sol", "Ré", "Lá", "Mi"], marks_a(1), width=540, gap=24)
    text(s, 64, 548, 1152, 80,
         [[("Círculo vazio: corda solta. ", {"b": True}),
           ("Cada ponto é uma posição alternativa na mesma corda, não notas tocadas juntas. "
            "Mesmos nomes, registros diferentes: o Mi solto do baixo (E1) fica uma oitava "
            "abaixo do E2 da guitarra.", {})]], size=17, color=INK)

    s = d.light("Para localizar uma nota",
                "Método em quatro passos, demonstrado com Sol: G, rótulo G, casa 3 na corda Mi "
                "grave (G2 na guitarra, G1 no baixo). Tocar é opcional e exige afinação padrão.")
    steps = [("01", "Leia o nome", "Por exemplo, Sol."),
             ("02", "Encontre a letra", "Na tabela, Sol é G."),
             ("03", "Procure o rótulo", "Ache G no desenho do instrumento escolhido."),
             ("04", "Corda e casa", "Corda Mi grave, casa 3: G2 na guitarra, G1 no baixo.")]
    for i, (num, head, body) in enumerate(steps):
        cx = 64 + i * 292
        text(s, cx, 200, 272, 40, [[(num, {"b": True, "c": LILAC, "sz": 30})]], size=30)
        text(s, cx, 246, 272, 36, [[(head, {"b": True})]], size=22, color=VIOLET)
        text(s, cx, 290, 262, 130, body, size=19)
    rect(s, 64, 446, 1152, 2, fill=RULE)
    text(s, 64, 470, 1152, 150,
         [[("A casa 3 é uma posição no braço, ", {"b": True}),
           ("não uma instrução para usar o terceiro dedo.", {})],
          "Se você já afina e toca, experimente na corda indicada: pressione dentro da casa, "
          "perto do traste à direita, sem apertar sobre o metal. Se ainda não, faça tudo pela "
          "figura; tocar não é necessário nesta lição."], size=19, spacing=10)

    s = d.light("Aplicação: uma frase em dois jeitos de escrever",
                "Frase de estudo original: Mi–Fá–Sol–Fá–Mi, ou E–F–G–F–E. Na corda Mi grave da "
                "guitarra ou do baixo: solta, casa 1, casa 3, casa 1, solta.")
    rows = [("Nomes", ["Mi", "Fá", "Sol", "Fá", "Mi"], WHITE, INK, RULE),
            ("Letras", ["E", "F", "G", "F", "E"], VIOLET, WHITE, None),
            ("Corda Mi grave", ["solta", "casa 1", "casa 3", "casa 1", "solta"], TINT, VIOLET, None)]
    for r_i, (lab, vals, fill, col, ln) in enumerate(rows):
        ry = 200 + r_i * 92
        text(s, 64, ry, 220, 72, [[(lab, {"b": True})]], size=19, color=MUTED, anchor="m")
        for c_i, v in enumerate(vals):
            chip(s, 290 + c_i * 186, ry, 168, 72, v, fill=fill, color=col,
                 size=26 if r_i < 2 else 21, line_color=ln)
    text(s, 64, 488, 1152, 130,
         ["A frase começa em Mi, sobe até Sol e volta a Mi. Aponte cada nome na ordem; "
          "tocar ou cantar é opcional.",
          "Na guitarra e no baixo as alturas exatas mudam. A ordem dos nomes continua a mesma."],
         size=19, spacing=10)

    s = d.light("O que você já consegue conferir",
                "Verificação de sucesso com apoio da tabela e dos desenhos. Não mede "
                "reconhecimento auditivo nem fluência ao tocar. " + NO_EXERCISES)
    two_cards(s, "Com a tabela",
              ["Escolha uma letra e diga seu nome em português.",
               "Se houver um número junto à letra, diga que ele identifica a oitava."],
              "Com os desenhos",
              ["Encontre esse rótulo no teclado ou na corda Mi grave.",
               "Confira a corda e a casa. Volte à referência sempre que precisar."],
              y=196, h=250)
    text(s, 64, 466, 1152, 60,
         "Reconhecer uma nota apenas pelo som e tocar com fluência são outras habilidades.",
         size=17, color=MUTED)
    practice_banner(s, "Faça as atividades desta lição, com dica e nova tentativa.")

    d.closing(["Próximo passo:", "tons e semitons"],
              "Os nomes dizem quais notas procurar. Agora vamos contar a distância entre elas "
              "e entender por que alguns nomes vizinhos ficam mais perto que outros.",
              "Próxima lição: “Tons e semitons: encontre a próxima nota”.")
    d.save(out, "Conheça as notas: nomes que você pode encontrar")


def build_lesson_b(template, out):
    d = Deck(template)
    d.cover(["Tons e", "semitons"], "Encontre a próxima nota",
            "Iniciante  /  Instrumento opcional",
            "Lição B, pt_BR, versão 2 do artigo (PR #436). " + NO_EXERCISES)

    s = d.light("Para que você vai usar isso?",
                "Abertura de aplicação. Uso imediato: transformar “suba um tom a partir de Fá” em "
                "uma contagem de teclas ou casas. Próximos assuntos: escalas, transposição, "
                "intervalos para acordes e campo harmônico. Fora do escopo hoje: construir "
                "acordes, transpor uma escala inteira e reconhecer intervalos de ouvido.")
    two_cards(s, "Uso agora",
              ["“Suba um tom a partir de Fá” vira um movimento concreto: contar teclas ou "
               "casas até a próxima nota da melodia."],
              "Nos próximos assuntos",
              ["Escalas: cada uma organiza distâncias entre notas.",
               "Transposição: mudar a nota inicial e manter as distâncias.",
               "Acordes e campo harmônico: os intervalos dependem dessas distâncias."],
              y=196, h=316)
    text(s, 64, 540, 1152, 80,
         [[("Hoje: ", {"b": True, "c": VIOLET}),
           ("contar um ou dois semitons e usar essa contagem no exemplo de Dó maior. "
            "Todas as atividades podem ser feitas sem instrumento.", {})]], size=19)

    s = d.light("Uma referência rápida para começar",
                "Ponte com a lição “Conheça as notas”: seções “Um mesmo nome pode aparecer de duas "
                "formas” (tabela de nomes e letras) e “O nome se repete; a altura muda” (números "
                "de oitava). A referência essencial está repetida neste slide.")
    names = ["Dó", "Ré", "Mi", "Fá", "Sol", "Lá", "Si"]
    letters = ["C", "D", "E", "F", "G", "A", "B"]
    for i, (n, l) in enumerate(zip(names, letters)):
        chip(s, 64 + i * 166, 200, 150, 80, f"{n} = {l}", fill=WHITE, color=INK, size=24,
             line_color=RULE)
    text(s, 64, 310, 1152, 120,
         ["Depois do Si, a sequência de nomes recomeça em Dó.",
          [("C4 e C5: ", {"b": True}), ("a letra é a mesma; o número indica outra oitava.", {})]],
         size=21, spacing=10)
    rect(s, 64, 470, 1152, 120, fill=TINT, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.1)
    text(s, 96, 470, 1100, 120,
         [[("Quer revisar? ", {"b": True, "c": VIOLET}),
           ("Na lição “Conheça as notas”, veja “Um mesmo nome pode aparecer de duas formas” "
            "e “O nome se repete; a altura muda”. Esta lição funciona sem abrir a anterior.", {})]],
         size=19, anchor="m")

    s = d.dark("A menor contagem que vamos usar",
               "Nos exemplos, a oitava está dividida em 12 semitons iguais. Um semitom é um passo "
               "entre alturas vizinhas: a próxima tecla, branca ou preta, ou a próxima casa na "
               "mesma corda. Um tom são dois semitons. Contamos mudanças; o ponto de partida não "
               "é um passo.")
    for i, (big, small) in enumerate((("1 semitom", "um passo para a próxima tecla, branca ou "
                                      "preta, ou para a próxima casa na mesma corda"),
                                     ("1 tom", "dois semitons: dois passos seguidos"))):
        cy = 200 + i * 150
        text(s, 64, cy, 330, 70, [[(big, {"b": True})]], size=40, color=LILAC)
        text(s, 400, cy + 6, 800, 110, small, size=24, color=WHITE)
    text(s, 64, 512, 1152, 100,
         ["Nos exemplos, a oitava tem 12 semitons iguais.",
          "Contamos cada mudança de posição; o ponto de partida não é um passo."], size=20, color="E4D6FF", spacing=6)

    s = d.light("Por que Mi–Fá e Dó–Ré são diferentes?",
                "Alternativa textual: teclado C4 a C5 com todas as teclas pretas. Mi4 e Fá4 são "
                "vizinhas: contagem 0 em Mi4 e 1 em Fá4, um semitom. Dó4, Dó sustenido 4 e Ré4: "
                "contagem 0, 1 e 2, dois semitons ou um tom.")
    keyboard(s, 64, 214, 84, 300,
             highlight={"C4": VIOLET, "C♯4": "4C1D95", "D4": VIOLET, "E4": LILAC, "F4": LILAC},
             badges={"C4": "0", "C♯4": "1", "D4": "2", "E4": "0", "F4": "1"},
             black_labels={"C♯4": "C♯/D♭"})
    tx = 770
    text(s, tx, 214, 446, 320,
         [[("Mi4 → Fá4", {"b": True, "c": INK, "sz": 24})],
          "Teclas vizinhas: 1 semitom.",
          [("Dó4 → Dó♯4 → Ré4", {"b": True, "c": VIOLET, "sz": 24})],
          "Duas mudanças: 1 tom.",
          [("Um tom são dois semitons.", {"c": MUTED, "sz": 18})]],
         size=20, spacing=12)
    text(s, 64, 548, 1152, 60,
         "Os números nas teclas mostram a contagem: começa em 0 na nota inicial.",
         size=17, color=MUTED)

    s = d.light("Dó♯ ou Ré♭: a tecla entre Dó e Ré",
                "Neste sistema de afinação, a tecla entre Dó e Ré pode ser chamada de Dó sustenido "
                "(C♯) ou Ré bemol (D♭). O sustenido sobe um semitom; o bemol desce um semitom.")
    two_cards(s, "Sustenido  ♯",
              ["Sobe um semitom a partir da nota nomeada.",
               [("Dó + 1 semitom = Dó♯ (C♯)", {"b": True})]],
              "Bemol  ♭",
              ["Desce um semitom a partir da nota nomeada.",
               [("Ré − 1 semitom = Ré♭ (D♭)", {"b": True})]], y=196, h=230)
    text(s, 64, 452, 1152, 160,
         [[("Mesma tecla neste exemplo. ", {"b": True, "c": VIOLET}),
           ("Não é preciso escolher a grafia agora: basta perceber a altura intermediária e "
            "incluí-la na contagem.", {})],
          [("Sustenidos e bemóis também podem nomear teclas brancas em outros contextos; "
            "a cor não define o símbolo.", {"c": MUTED, "sz": 17})]], size=20, spacing=12)

    s = d.light("Um método que você pode repetir",
                "Método em quatro passos. Exemplo resolvido: Dó recebe 0, Dó sustenido 1, Ré 2; "
                "distância de dois semitons. Erro comum: contar as três posições em vez das duas "
                "mudanças.")
    steps = [("01", "Início e chegada", "Identifique a nota inicial e a nota de chegada."),
             ("02", "Tudo no caminho", "Veja todas as teclas ou casas entre elas, inclusive "
                                       "as intermediárias."),
             ("03", "Conte mudanças", "Comece em zero na nota inicial. Cada passagem para a "
                                      "posição seguinte vale um."),
             ("04", "Compare", "Um passo é um semitom. Dois passos são um tom.")]
    for i, (num, head, body) in enumerate(steps):
        cx = 64 + i * 292
        text(s, cx, 196, 272, 40, [[(num, {"b": True, "c": LILAC, "sz": 30})]], size=30)
        text(s, cx, 240, 272, 36, [[(head, {"b": True})]], size=22, color=VIOLET)
        text(s, cx, 284, 262, 150, body, size=19)
    rect(s, 64, 452, 1152, 150, fill=TINT, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.08,
         name="Exemplo resolvido")
    text(s, 96, 452, 1100, 150,
         [[("Dó = 0  ·  Dó♯ = 1  ·  Ré = 2  →  dois semitons", {"b": True, "c": VIOLET, "sz": 24})],
          [("Contou “três”? ", {"b": True}),
           ("Você provavelmente contou as três posições exibidas, em vez das duas mudanças "
            "entre elas.", {})]], size=19, anchor="m", spacing=10)

    s = d.light("A mesma contagem na corda Mi",
                "Alternativa textual. Guitarra, sexta corda solta E2; casa 1 F2; casa 2 F sustenido "
                "2; casa 3 G2. Baixo, quarta corda solta E1; casa 1 F1; casa 2 F sustenido 1; casa 3 "
                "G1. Mi a Fá: solta para casa 1, um semitom. Fá a Sol: casa 1, 2 e 3, dois "
                "semitons. Contar casas vale só na mesma corda.")
    marks_b = lambda o: [(0, "Mi", f"E{o}"), (1, "Fá", f"F{o}"), (2, "Fá♯", f"F♯{o}"),
                         (3, "Sol", f"G{o}")]
    fretboard(s, 64, 186, "Guitarra · 6ª corda (E2 solta)",
              ["Mi", "Si", "Sol", "Ré", "Lá", "Mi"], marks_b(2), width=540, gap=22)
    fretboard(s, 676, 186, "Baixo · 4ª corda (E1 solta)",
              ["Sol", "Ré", "Lá", "Mi"], marks_b(1), width=540, gap=22)
    text(s, 64, 520, 1152, 110,
         [[("Mi → Fá: ", {"b": True}), ("solta → casa 1, 1 semitom.   ", {}),
           ("Fá → Sol: ", {"b": True}), ("casa 1 → 2 → 3, 2 semitons. ", {}),
           ("“Suba um tom a partir de Fá” chega a Sol.", {"b": True, "c": VIOLET})],
          [("Conte casas só na mesma corda: trocar de corda muda a referência. O número da casa "
            "indica a posição, não o dedo.", {"c": MUTED, "sz": 16})]], size=18, spacing=8)

    s = d.dark("Dois pares sem tecla intermediária",
               "Entre as notas naturais consecutivas, Mi–Fá e Si–Dó têm um semitom; os outros "
               "pares têm um tom. Entre Sol e Lá há Sol sustenido/Lá bemol. De Si3 ao Dó4 "
               "seguinte, a oitava muda, mas as teclas são vizinhas.")
    text(s, 64, 206, 1152, 150,
         [[("Mi–Fá ", {"b": True, "c": LILAC}), ("e ", {"b": True}),
           ("Si–Dó", {"b": True, "c": LILAC}), (": um semitom.", {"b": True})],
          [("Os outros pares vizinhos: um tom.", {"b": True})]],
         size=40, color=WHITE, spacing=8)
    text(s, 64, 400, 1152, 190,
         ["“Passar para o próximo nome” nem sempre percorre a mesma distância.",
          "Entre Sol e Lá há Sol♯/Lá♭. Entre Si3 e o Dó4 seguinte não há tecla: o número "
          "da oitava muda, mas as teclas são vizinhas."],
         size=22, color="E4D6FF", spacing=12)

    s = d.light("Aplicação: as distâncias em Dó maior",
                "Alternativa textual da régua: de C4 a C5, posições 0 a 12. Notas naturais em "
                "0 Dó, 2 Ré, 4 Mi, 5 Fá, 7 Sol, 9 Lá, 11 Si, 12 Dó. Distâncias consecutivas: "
                "Dó–Ré 2, Ré–Mi 2, Mi–Fá 1, Fá–Sol 2, Sol–Lá 2, Lá–Si 2, Si–Dó 1. Padrão "
                "T–T–S–T–T–T–S; soma 12 semitons.")
    c_major_ruler(s, 112, 196, 88)
    text(s, 64, 410, 1152, 40,
         "Cada espaço da régua é um semitom. T = tom (2 semitons). S = semitom.",
         size=17, color=MUTED)
    rect(s, 64, 466, 1152, 132, fill=TINT, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.1)
    text(s, 96, 466, 1100, 132,
         [[("Escala de Dó maior:  T–T–S–T–T–T–S", {"b": True, "c": VIOLET, "sz": 26})],
          "2 + 2 + 1 + 2 + 2 + 2 + 1 = 12 semitons, chegando ao Dó uma oitava acima."],
         size=20, anchor="m", spacing=8)

    s = d.light("Conferindo o resultado em uma frase",
                "Dó–Ré–Mi–Fá: um tom, um tom e um semitom. O último deslocamento é menor, embora "
                "todos avancem para o próximo nome.")
    notes_row = ["Dó", "Ré", "Mi", "Fá"]
    moves = [("tom", "2"), ("tom", "2"), ("semitom", "1")]
    for i, n in enumerate(notes_row):
        chip(s, 64 + i * 300, 220, 190, 100, n, fill=VIOLET, color=WHITE, size=34)
    for i, (m, v) in enumerate(moves):
        mx = 254 + i * 300
        line(s, mx + 14, 270, mx + 96, 270, color=INK, width=2.5)
        text(s, mx, 216, 110, 30, [[(m, {"b": True})]], size=17,
             color=VIOLET if v == "1" else INK, align="c")
        text(s, mx - 10, 282, 130, 30, f"{v} semitom" + ("s" if v != "1" else ""), size=14,
             color=MUTED, align="c")
    text(s, 64, 372, 1152, 160,
         ["Todos os movimentos avançam para o próximo nome, mas o último é menor.",
          "Aponte cada nota e explique a distância até a seguinte, incluindo a tecla ou casa "
          "intermediária quando houver."], size=21, spacing=12)

    s = d.light("O que você já consegue conferir",
                "Verificação de sucesso com apoio da régua e dos desenhos. Não mede velocidade, "
                "execução nem reconhecimento das distâncias pelo som. " + NO_EXERCISES)
    two_cards(s, "Conte mudanças",
              ["Comece em zero na nota inicial.",
               "Inclua a tecla ou casa intermediária quando houver."],
              "Distinga um de dois",
              ["Um passo é semitom; dois passos são um tom.",
               "Mi–Fá e Si–Dó têm um semitom."], y=196, h=250)
    text(s, 64, 466, 1152, 60,
         "Isso ainda não mede velocidade, execução ou reconhecimento das distâncias pelo som.",
         size=17, color=MUTED)
    practice_banner(s, "Faça as atividades desta lição, com dica e nova tentativa.")

    s = d.light("Complementos opcionais",
                "Links verificados no texto publicado: musictheory.net em 2026-11-03 (inglês, exige "
                "JavaScript; controles não verificados) e Ableton Learning Music em português em "
                "2026-11-05 (controles e áudio não verificados). URLs: "
                "https://www.musictheory.net/lessons/20 e "
                "https://learningmusic.ableton.com/pt/advanced-topics/building-major-scales.html. "
                "Nenhum conteúdo externo é copiado.")
    text(s, 64, 176, 1152, 40, "A lição já contém o método completo. Use estes recursos para "
         "reforçar ou explorar a mesma ideia.", size=18, color=MUTED)
    refs = [("Steps and Accidentals", "musictheory.net · inglês · exige JavaScript",
             "https://www.musictheory.net/lessons/20",
             "Abertura: teclas vizinhas e dois passos. Use depois da comparação Mi–Fá e Dó–Ré."),
            ("Construindo escalas maiores", "Ableton Learning Music · português",
             "https://learningmusic.ableton.com/pt/advanced-topics/building-major-scales.html",
             "Seção inicial, até o padrão de tons e semitons. Use depois da prática.")]
    for i, (title, source, url, use) in enumerate(refs):
        cy = 236 + i * 186
        rect(s, 64, cy, 1152, 166, fill=WHITE, line=RULE, shape=MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.06, name=f"Referência {title}")
        tb = text(s, 96, cy + 22, 1090, 36, [[(title, {"b": True})]], size=23, color=VIOLET)
        tb.text_frame.paragraphs[0].runs[0].hyperlink.address = url
        text(s, 96, cy + 62, 1090, 28, source, size=16, color=MUTED)
        text(s, 96, cy + 98, 1090, 60, use, size=19)
    text(s, 64, 612, 1080, 30, "Se um recurso não abrir, a régua e os exemplos desta lição "
         "bastam.", size=15, color=MUTED)

    d.closing(["Escolha outro par", "e refaça a contagem"],
              "Depois, use o mesmo raciocínio para estudar outras escalas, transpor pequenas "
              "melodias e entender os intervalos que formam os acordes.",
              "Próxima ação de prática: escolher outro par na régua e recontar.")
    d.save(out, "Tons e semitons: encontre a próxima nota")


if __name__ == "__main__":
    template, out_dir = sys.argv[1], Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    build_lesson_a(template, out_dir / "lesson-a.pt-BR.pptx")
    build_lesson_b(template, out_dir / "lesson-b.pt-BR.pptx")
    print("built", *sorted(p.name for p in out_dir.glob("*.pptx")))
