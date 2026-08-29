"""Build the EverCare system documentation as a structured Word document.

The source uses the standard_business_brief preset with a named
``monochrome_academic_report`` override requested for this deliverable:

* US Letter portrait, 1 inch margins, 0.45 inch header/footer distance.
* Times New Roman 11 pt body, black text, 1.15 line spacing, 6 pt after.
* Black 15/12.5/11.5 pt heading ladder.
* Fixed-width DXA tables with 120 DXA indent and restrained gray headers.
* Dedicated Letter landscape diagram pages with 0.55/0.65 inch margins.

Microsoft Word is used separately to update fields and export the final PDF.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING, WD_TAB_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[2]
WEEK6 = ROOT / "docs" / "week 6"
DEFAULT_OUTPUT = ROOT / ".tmp_docx_review" / "final" / "EverCare_System_Documentation.docx"

BLACK = RGBColor(0, 0, 0)
GRAY = RGBColor(80, 80, 80)
LIGHT_GRAY_HEX = "E7E7E7"
WHITE_HEX = "FFFFFF"

FONT = "Times New Roman"
MONO_FONT = "Consolas"


def set_run_font(run, *, name=FONT, size=None, bold=None, italic=None, color=BLACK):
    run.font.name = name
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.rFonts
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    rfonts.set(qn("w:ascii"), name)
    rfonts.set(qn("w:hAnsi"), name)
    rfonts.set(qn("w:eastAsia"), name)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic
    run.font.color.rgb = color
    return run


def style_font(style, *, name=FONT, size=11, bold=False, italic=False, color=BLACK):
    style.font.name = name
    style.font.size = Pt(size)
    style.font.bold = bold
    style.font.italic = italic
    style.font.color.rgb = color
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.rFonts
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    rfonts.set(qn("w:ascii"), name)
    rfonts.set(qn("w:hAnsi"), name)
    rfonts.set(qn("w:eastAsia"), name)


def set_paragraph_tokens(
    style,
    *,
    before=0,
    after=6,
    line_spacing=1.15,
    keep_with_next=False,
    keep_together=False,
):
    fmt = style.paragraph_format
    fmt.space_before = Pt(before)
    fmt.space_after = Pt(after)
    fmt.line_spacing = line_spacing
    fmt.keep_with_next = keep_with_next
    fmt.keep_together = keep_together


def remove_style_paragraph_borders(style):
    """Remove decorative borders inherited from a built-in Word style."""
    ppr = style.element.get_or_add_pPr()
    borders = ppr.find(qn("w:pBdr"))
    if borders is not None:
        ppr.remove(borders)


def configure_styles(doc: Document):
    styles = doc.styles

    normal = styles["Normal"]
    style_font(normal, size=11)
    set_paragraph_tokens(normal, after=6, line_spacing=1.15)

    title = styles["Title"]
    style_font(title, size=24, bold=True)
    title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_paragraph_tokens(title, before=0, after=8, line_spacing=1.0, keep_with_next=True)
    remove_style_paragraph_borders(title)

    subtitle = styles["Subtitle"]
    style_font(subtitle, size=13, color=GRAY)
    subtitle.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_paragraph_tokens(subtitle, after=20, line_spacing=1.05, keep_with_next=True)
    remove_style_paragraph_borders(subtitle)

    heading_specs = {
        "Heading 1": (15, 14, 6),
        "Heading 2": (12.5, 10, 5),
        "Heading 3": (11.5, 8, 3),
    }
    for name, (size, before, after) in heading_specs.items():
        style = styles[name]
        style_font(style, size=size, bold=True)
        set_paragraph_tokens(
            style,
            before=before,
            after=after,
            line_spacing=1.05,
            keep_with_next=True,
            keep_together=True,
        )

    caption = styles["Caption"]
    style_font(caption, size=9.5, italic=True, color=GRAY)
    caption.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_paragraph_tokens(caption, before=4, after=6, line_spacing=1.0, keep_together=True)

    for name in ("List Bullet", "List Number"):
        style = styles[name]
        style_font(style, size=11)
        set_paragraph_tokens(style, after=4, line_spacing=1.15)
        style.paragraph_format.left_indent = Inches(0.5)
        style.paragraph_format.first_line_indent = Inches(-0.25)
        style.paragraph_format.tab_stops.add_tab_stop(Inches(0.5))

    schema = styles.add_style("Schema Detail", WD_STYLE_TYPE.PARAGRAPH)
    style_font(schema, size=9.5)
    set_paragraph_tokens(schema, after=3, line_spacing=1.05, keep_together=True)

    small = styles.add_style("Small Note", WD_STYLE_TYPE.PARAGRAPH)
    style_font(small, size=9, color=GRAY)
    set_paragraph_tokens(small, after=4, line_spacing=1.05)

    metadata = styles.add_style("Cover Metadata", WD_STYLE_TYPE.PARAGRAPH)
    style_font(metadata, size=11.5)
    set_paragraph_tokens(metadata, after=4, line_spacing=1.1)


def remove_all_children(element):
    for child in list(element):
        element.remove(child)


def add_field(paragraph, instruction: str, display: str = ""):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = display
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, instr, separate, text, end])
    set_run_font(run, size=9)
    return run


def set_page_number_start(section, value: int | None):
    sect_pr = section._sectPr
    for child in list(sect_pr):
        if child.tag == qn("w:pgNumType"):
            sect_pr.remove(child)
    if value is not None:
        pg_num = OxmlElement("w:pgNumType")
        pg_num.set(qn("w:start"), str(value))
        sect_pr.append(pg_num)


def configure_page(section, *, landscape=False, start_number=None, cover=False):
    if landscape:
        section.orientation = WD_ORIENT.LANDSCAPE
        section.page_width = Inches(11)
        section.page_height = Inches(8.5)
        section.top_margin = Inches(0.55)
        section.bottom_margin = Inches(0.55)
        section.left_margin = Inches(0.65)
        section.right_margin = Inches(0.65)
    else:
        section.orientation = WD_ORIENT.PORTRAIT
        section.page_width = Inches(8.5)
        section.page_height = Inches(11)
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)

    section.header_distance = Inches(0.45 if not landscape else 0.3)
    section.footer_distance = Inches(0.45 if not landscape else 0.3)
    set_page_number_start(section, start_number)

    section.header.is_linked_to_previous = False
    section.footer.is_linked_to_previous = False
    header = section.header
    footer = section.footer
    for p in list(header.paragraphs):
        remove_all_children(p._p)
    for p in list(footer.paragraphs):
        remove_all_children(p._p)

    if cover:
        return

    usable = 9.7 if landscape else 6.5
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.LEFT
    hp.paragraph_format.space_after = Pt(0)
    hp.paragraph_format.tab_stops.add_tab_stop(Inches(usable), WD_TAB_ALIGNMENT.RIGHT)
    set_run_font(hp.add_run("EverCare System Documentation"), size=8.5, bold=True, color=GRAY)
    set_run_font(hp.add_run("\tBrent Lawrence C. Bernardo"), size=8.5, color=GRAY)

    fp = footer.paragraphs[0]
    fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    fp.paragraph_format.space_before = Pt(0)
    fp.paragraph_format.space_after = Pt(0)
    set_run_font(fp.add_run("Page "), size=9, color=GRAY)
    add_field(fp, " PAGE ", "1")


def set_document_settings(doc: Document):
    settings = doc.settings._element
    for tag in ("w:updateFields", "w:doNotCompressPictures"):
        if settings.find(qn(tag)) is None:
            node = OxmlElement(tag)
            if tag == "w:updateFields":
                node.set(qn("w:val"), "true")
            settings.append(node)

    try:
        dpi = settings.find(qn("w14:defaultImageDpi"))
        if dpi is None:
            dpi = OxmlElement("w14:defaultImageDpi")
            settings.append(dpi)
        dpi.set(qn("w14:val"), "300")
    except KeyError:
        # Older python-docx namespace maps may omit w14. The explicit
        # doNotCompressPictures setting still preserves the embedded PNGs.
        pass


def add_body(doc, text: str, *, bold_label: str | None = None, style=None, align=None):
    p = doc.add_paragraph(style=style)
    if align is not None:
        p.alignment = align
    if bold_label and text.startswith(bold_label):
        set_run_font(p.add_run(bold_label), bold=True)
        set_run_font(p.add_run(text[len(bold_label) :]))
    else:
        set_run_font(p.add_run(text), size=9.5 if style == "Schema Detail" else 11)
    return p


def add_labeled_paragraph(doc, label: str, text: str, *, style=None):
    p = doc.add_paragraph(style=style)
    size = 9.5 if style == "Schema Detail" else 11
    set_run_font(p.add_run(f"{label}: "), size=size, bold=True)
    set_run_font(p.add_run(text), size=size)
    return p


def add_bullet(doc, text: str):
    p = doc.add_paragraph(style="List Bullet")
    set_run_font(p.add_run(text), size=11)
    return p


def add_numbered(doc, text: str):
    p = doc.add_paragraph(style="List Number")
    set_run_font(p.add_run(text), size=11)
    return p


def add_cover_metadata(doc, label: str, value: str):
    p = doc.add_paragraph(style="Cover Metadata")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(p.add_run(f"{label}: "), size=11.5, bold=True)
    set_run_font(p.add_run(value), size=11.5)
    return p


def shade_cell(cell, fill: str):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{margin}"))
        if node is None:
            node = OxmlElement(f"w:{margin}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_cell_width(cell, width_dxa: int):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_w = tc_pr.find(qn("w:tcW"))
    if tc_w is None:
        tc_w = OxmlElement("w:tcW")
        tc_pr.append(tc_w)
    tc_w.set(qn("w:w"), str(width_dxa))
    tc_w.set(qn("w:type"), "dxa")


def set_table_borders(table):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = qn(f"w:{edge}")
        node = borders.find(tag)
        if node is None:
            node = OxmlElement(f"w:{edge}")
            borders.append(node)
        node.set(qn("w:val"), "single")
        node.set(qn("w:sz"), "4")
        node.set(qn("w:space"), "0")
        node.set(qn("w:color"), "666666")


def set_table_geometry(table, widths_dxa: list[int], *, total=9360, indent=120):
    if sum(widths_dxa) != total:
        raise ValueError(f"Table widths must total {total} DXA: {widths_dxa}")
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    tbl = table._tbl
    tbl_pr = tbl.tblPr

    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(total))
    tbl_w.set(qn("w:type"), "dxa")

    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent))
    tbl_ind.set(qn("w:type"), "dxa")

    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")

    grid = tbl.tblGrid
    remove_all_children(grid)
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)

    for row in table.rows:
        for index, cell in enumerate(row.cells):
            set_cell_width(cell, widths_dxa[index])
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def repeat_header_row(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = tr_pr.find(qn("w:tblHeader"))
    if tbl_header is None:
        tbl_header = OxmlElement("w:tblHeader")
        tr_pr.append(tbl_header)
    tbl_header.set(qn("w:val"), "true")


def set_cell_text(cell, text: str, *, bold=False, size=9, align=WD_ALIGN_PARAGRAPH.LEFT):
    cell.text = ""
    p = cell.paragraphs[0]
    p.alignment = align
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.05
    set_run_font(p.add_run(text), size=size, bold=bold)


def add_table(doc, headers: list[str], rows: list[list[str]], widths_dxa: list[int], *, font_size=9):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    hdr = table.rows[0]
    for index, text in enumerate(headers):
        set_cell_text(hdr.cells[index], text, bold=True, size=font_size)
        shade_cell(hdr.cells[index], LIGHT_GRAY_HEX)
    repeat_header_row(hdr)

    for values in rows:
        row = table.add_row()
        for index, text in enumerate(values):
            set_cell_text(row.cells[index], text, size=font_size)

    set_table_geometry(table, widths_dxa)
    set_table_borders(table)
    before = table._tbl.getprevious()
    if before is not None and before.tag == qn("w:p"):
        p = before
        p_pr = p.get_or_add_pPr()
        spacing = p_pr.find(qn("w:spacing"))
        if spacing is None:
            spacing = OxmlElement("w:spacing")
            p_pr.append(spacing)
        spacing.set(qn("w:after"), "80")
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return table


def add_picture(doc, path: Path, *, width_inches: float, alt_text: str, caption: str, note: str | None = None):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(2)
    shape = p.add_run().add_picture(str(path), width=Inches(width_inches))
    shape._inline.docPr.set("descr", alt_text)
    shape._inline.docPr.set("title", caption)
    cp = doc.add_paragraph(caption, style="Caption")
    cp.paragraph_format.keep_with_next = note is not None
    if note:
        np = doc.add_paragraph(note, style="Small Note")
        np.alignment = WD_ALIGN_PARAGRAPH.CENTER
        np.paragraph_format.keep_together = True
    return shape


def add_toc(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(8)
    add_field(p, ' TOC \\o "1-2" \\h \\z \\u ', "Right-click and update the table of contents.")


def add_landscape_section(doc: Document, image: Path, alt: str, caption: str, note: str | None = None):
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    configure_page(section, landscape=True)
    add_picture(doc, image, width_inches=9.55, alt_text=alt, caption=caption, note=note)
    return section


def add_portrait_section(doc: Document):
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    configure_page(section, landscape=False)
    return section


def add_schema_entry(
    doc,
    table: str,
    keys: str,
    columns: str,
    rules: str,
    *,
    page_break_before: bool = False,
):
    heading = doc.add_heading(table, level=3)
    heading.paragraph_format.page_break_before = page_break_before
    add_labeled_paragraph(doc, "Keys and relationships", keys, style="Schema Detail")
    add_labeled_paragraph(doc, "Columns", columns, style="Schema Detail")
    add_labeled_paragraph(doc, "Rules and indexes", rules, style="Schema Detail")


def build_document(output_path: Path):
    required_images = {
        "architecture": WEEK6 / "system_architecture.png",
        "flowchart": WEEK6 / "system_flowchart.png",
        "schema": WEEK6 / "database_schema_overview.png",
        "erd": WEEK6 / "database_erd.png",
    }
    missing = [str(path) for path in required_images.values() if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing diagram assets: " + ", ".join(missing))

    doc = Document()
    configure_styles(doc)
    set_document_settings(doc)
    props = doc.core_properties
    props.title = "EverCare System Documentation"
    props.subject = "Database ERD, database schema overview, system flowchart, and architecture"
    props.author = "Brent Lawrence C. Bernardo"
    props.keywords = "EverCare, Flutter, Supabase, PostgreSQL, ERD, system architecture"
    props.comments = "Generated from the EverCare repository snapshot dated August 28, 2026."

    cover = doc.sections[0]
    configure_page(cover, cover=True)

    # Plain editorial-cover structure with the requested monochrome override.
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(92)
    p.paragraph_format.space_after = Pt(0)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(p.add_run("EVERCARE"), size=17, bold=True)

    p = doc.add_paragraph(style="Title")
    set_run_font(p.add_run("System Documentation"), size=24, bold=True)
    p = doc.add_paragraph(style="Subtitle")
    set_run_font(
        p.add_run("Database Design, Schema Overview, System Flow, and Architecture"),
        size=13,
        color=GRAY,
    )

    spacer = doc.add_paragraph()
    spacer.paragraph_format.space_before = Pt(82)
    spacer.paragraph_format.space_after = Pt(0)
    add_cover_metadata(doc, "Prepared by", "Brent Lawrence C. Bernardo")
    add_cover_metadata(doc, "Section", "ITE231")
    add_cover_metadata(doc, "Professor", "Paul John Cabance")
    add_cover_metadata(doc, "Document date", "August 28, 2026")
    add_cover_metadata(doc, "System", "EverCare Flutter Mobile Application")

    # Front matter starts its own numbered section.
    front = doc.add_section(WD_SECTION.NEW_PAGE)
    configure_page(front, start_number=1)
    doc.add_heading("Table of Contents", level=1)
    add_toc(doc)
    doc.add_page_break()

    doc.add_heading("Document Purpose and Scope", level=1)
    add_body(
        doc,
        "This document describes the current EverCare mobile application as implemented in the repository snapshot dated August 28, 2026. It explains the system architecture, core application flow, PostgreSQL data model, Supabase security boundary, principal business rules, and the source-code structure that supports the application.",
    )
    add_body(
        doc,
        "The Supabase migration files are treated as the authoritative database definition. Flutter source files are treated as the authoritative description of implemented user flows. The diagrams are intentionally rendered at print resolution on dedicated landscape pages so labels remain readable in the PDF and on paper.",
    )
    add_labeled_paragraph(
        doc,
        "Diagram convention",
        "Solid boxes are implemented EverCare or Supabase components. Dashed boxes represent external or device-provided services. Arrows show the direction of a request, event, or persisted relationship.",
    )
    add_labeled_paragraph(
        doc,
        "Database convention",
        "PK means primary key, FK means foreign key, RLS means Row Level Security, RPC means a PostgreSQL function called through Supabase, and a question mark after a type denotes a nullable column in the compact schema listing.",
    )

    doc.add_heading("Executive Summary", level=1)
    add_body(
        doc,
        "EverCare is a Flutter care companion for Filipino seniors, caregivers, and family members. It brings blood-pressure records, medication schedules, medical appointments, journals with private photos, emergency details, caregiver relationship records, notifications, and caregiving references into one accessible mobile interface.",
    )
    add_body(
        doc,
        "The mobile client connects to Supabase for email/password authentication, PostgreSQL persistence, PostgREST data access, server-validated RPCs, private object storage, and authenticated Edge Functions. It also integrates with a YK-IBPA1 Bluetooth Low Energy blood-pressure monitor, OpenStreetMap-based hospital services, external Google Maps links, the bundled NIA Caregiver's Handbook, and a Groq-hosted language model reached only through server-side Edge Functions.",
    )
    add_labeled_paragraph(
        doc,
        "Safety boundary",
        "EverCare is not a diagnostic device, medical verification service, emergency-dispatch system, or substitute for professional care. Saved blood-pressure records are constrained to remain medically unverified. Emergency numbers are copied for the user; the app does not automatically call, text, send an SOS, or alert another person.",
    )

    doc.add_heading("System Overview", level=1)
    add_table(
        doc,
        ["Area", "Implemented technology and responsibility"],
        [
            ["Mobile client", "Flutter / Dart application with named routes, reusable widgets, an eight-tab MainShell, and elderly-friendly accessibility controls."],
            ["State", "Screen-local StatefulWidget/FutureBuilder state plus app-owned ChangeNotifier scopes for BLE monitoring and accessibility settings."],
            ["Backend", "Supabase Auth, PostgREST, PostgreSQL RPCs, Row Level Security, private Storage, and authenticated Edge Functions."],
            ["Database", "PostgreSQL 17 with 11 public application tables plus Supabase-managed auth.users and storage objects."],
            ["Hardware", "YK-IBPA1 BLE monitor; the app decodes progress and final packets and applies the implemented local systolic calibration."],
            ["External services", "OpenStreetMap tiles, Overpass, Nominatim, Photon, external Google Maps URLs, Groq API, and NIA reference resources."],
            ["Local device storage", "SharedPreferences for text-size/reduced-motion settings and saved BLE monitor setup; camera/gallery, location, clipboard, files, and browser are used only when the related feature is invoked."],
        ],
        [1900, 7460],
        font_size=9,
    )

    doc.add_heading("Users and Navigation", level=2)
    add_body(
        doc,
        "Registration accepts three profile values: senior, caregiver, and family member. These are descriptive profile metadata in the current release, not separate authorization roles. Every authenticated account receives the same main shell, and no administrator or clinician module exists.",
    )
    add_bullet(doc, "Home — dashboard summary, next medication, next appointment, and quick actions.")
    add_bullet(doc, "My Health — BLE/manual blood-pressure capture, history, trend, and optional AI explanation or chat.")
    add_bullet(doc, "Medications — weekday schedule, due/taken/missed state, course completion, edit, and delete.")
    add_bullet(doc, "Appointments — create, edit, hospital selection, attendance state, directions, completion, cancellation, and delete.")
    add_bullet(doc, "Journals — create, read, edit, bookmark, delete, and attach private photos.")
    add_bullet(doc, "Care Book — bundled caregiving chapters, handbook download, references, and memory-only AI chat.")
    add_bullet(doc, "Emergency — hotline/contacts, medical information links, safety guidance, and hospital finder.")
    add_bullet(doc, "Profile — personal details, trusted people, accessibility, settings, notifications, and logout.")

    architecture_heading = doc.add_heading("System Architecture", level=1)
    architecture_heading.paragraph_format.page_break_before = True
    add_body(
        doc,
        "EverCare is layered, but it is not a strict Clean Architecture implementation. Screens commonly instantiate feature repositories directly. Shared dependencies are injected through Flutter inherited scopes, while repositories translate Supabase responses into typed Dart models.",
    )
    add_table(
        doc,
        ["Layer", "Current implementation"],
        [
            ["Bootstrap and composition", "Initializes Flutter, locks portrait orientation, initializes Supabase, creates BLE/accessibility controllers, and injects application scopes."],
            ["Presentation and navigation", "Feature screens, widgets, named routes, route observers, headers, and the eight-tab MainShell."],
            ["State and application behavior", "Screen-local state, futures, timers, lifecycle observers, and ChangeNotifier scopes for shared BLE and accessibility state."],
            ["Domain models and rules", "Typed medication, dose, appointment, journal, BP, emergency, caregiver, hospital, profile, and notification records plus validation/schedule logic."],
            ["Repositories and integration services", "Owner-filtered CRUD, RPC calls, Storage operations, Auth, BLE, AI, hospital lookup, photo picking, downloads, and local preferences."],
            ["Backend and external services", "Supabase authentication/data/security/storage/functions; Groq, OpenStreetMap services, Google Maps URLs, and NIA references."],
        ],
        [2300, 7060],
        font_size=9,
    )
    add_body(
        doc,
        "All direct database operations use the authenticated Supabase client and are still checked by server-side RLS. Client-side owner filters improve clarity and query efficiency but are not the security boundary.",
    )

    add_landscape_section(
        doc,
        required_images["architecture"],
        "EverCare architecture from people and BLE device through the Flutter client to Supabase and external services.",
        "Figure 1. EverCare system architecture and component interaction.",
    )

    add_portrait_section(doc)
    doc.add_heading("Core System Flow", level=1)
    add_body(
        doc,
        "EverCare begins by initializing Supabase and the shared device/accessibility controllers. The splash screen checks the current Supabase session. A signed-in user enters the MainShell; otherwise, the app presents welcome, onboarding, login, registration, and password-reset paths.",
    )
    add_numbered(doc, "Initialize Flutter bindings, system UI, Supabase, BLE monitoring state, and accessibility preferences.")
    add_numbered(doc, "Check the Supabase Auth session after the splash delay.")
    add_numbered(doc, "When no session exists, complete onboarding and authenticate or register. Registration metadata is copied into a new profiles row by a database trigger.")
    add_numbered(doc, "Enter the authenticated MainShell and choose one of the eight feature tabs or a detail route.")
    add_numbered(doc, "The selected screen applies local validation and calls a repository or integration service.")
    add_numbered(doc, "Supabase requests pass through authentication, grants, RLS, database constraints, triggers, and RPC rules before a response returns to the UI.")
    add_numbered(doc, "The screen refreshes, returns to the dashboard, or continues to another feature. In-app medication and appointment reconciliation runs again on the relevant load/resume paths.")
    add_labeled_paragraph(
        doc,
        "Important distinction",
        "Direct device or public-service actions—BLE, location, camera/gallery, clipboard, files, map tiles, and public hospital lookup—do not use the PostgreSQL path. AI calls do use an authenticated Edge Function so provider credentials remain off the mobile client.",
    )

    add_landscape_section(
        doc,
        required_images["flowchart"],
        "EverCare flowchart showing startup, authentication, task selection, feature lanes, and repository/service boundary.",
        "Figure 2. EverCare core system flowchart.",
    )

    add_portrait_section(doc)
    doc.add_heading("Major Feature Workflows", level=1)
    doc.add_heading("Blood-Pressure Capture", level=2)
    add_body(
        doc,
        "Health → request Bluetooth permission → scan and save/connect the YK-IBPA1 monitor → discover the custom BLE service and notification characteristic → decode 0x80 progress and 0x81 final packets → apply the implemented −10 mmHg systolic calibration → show the result and assessment → optionally request an AI explanation → explicitly save through BloodPressureRepository. Manual entry bypasses BLE and calibration but uses the same owner-scoped table.",
    )
    doc.add_heading("Medication Adherence", level=2)
    add_body(
        doc,
        "Medication screen → load active medicines and recent dose events → calculate Philippine-time occurrences → display upcoming, due, taken, or missed state → call a server-clock RPC for taken/missed → optionally edit, complete, or delete. Missed state is reconciled while the app is active or resumed; there is no background operating-system reminder service.",
    )
    doc.add_heading("Appointment Attendance", level=2)
    add_body(
        doc,
        "Appointments → add/edit a visit and optionally select a hospital → persist through AppointmentRepository → open the detail page → use external directions/details or call server RPCs to complete/cancel. Unresolved upcoming visits become missed 24 hours after the start time when reconciliation runs in the app.",
    )
    doc.add_heading("Journals and Private Photos", level=2)
    add_body(
        doc,
        "Journal list → create/read/edit/bookmark/delete journal_entries. Camera/gallery photos are resized or compressed, uploaded to the private journal-photos bucket, described by journal_entry_photos metadata, and displayed through temporary signed URLs. Deleting an entry removes its photo objects and metadata through coordinated repository operations.",
    )
    doc.add_heading("Emergency and Hospital Finder", level=2)
    add_body(
        doc,
        "Emergency → load the signed-in user's contacts → add/edit/delete and select at most one primary contact → copy a selected number when needed. Hospital Finder requests foreground location, uses OpenStreetMap tiles and public Overpass/Nominatim/Photon services, and can open external Google Maps directions or details. It does not place a call or dispatch emergency assistance.",
    )
    doc.add_heading("Care Book, AI, Notifications, and Trusted People", level=2)
    add_body(
        doc,
        "Care Book content and the NIA handbook PDF are bundled with the app. Care Book and blood-pressure AI features invoke authenticated Edge Functions that call Groq; the mobile app does not contain the provider secret. The Notifications screen reads database-backed records and can update is_read, but current code does not generate rows or provide push delivery. Trusted People currently lists recipient-side stored relationships and allows removal; invitation/acceptance UI and access to another user's health records are not implemented.",
    )

    doc.add_heading("Database Design Overview", level=1)
    add_body(
        doc,
        "EverCare uses Supabase-hosted PostgreSQL 17. Five versioned migrations define 11 public application tables. Supabase-managed auth.users provides account identity, while storage.objects holds private journal-photo files. Most owner foreign keys point directly to auth.users.id; profiles is not the physical parent of the health and care tables.",
    )
    add_bullet(doc, "Identity and trusted care: profiles, medical_profiles, and caregiver_relationships.")
    add_bullet(doc, "Health and scheduling: medications, medication_dose_events, appointments, and blood_pressure_readings.")
    add_bullet(doc, "Journal and safety: journal_entries, journal_entry_photos, emergency_contacts, and notifications.")
    add_bullet(doc, "Principal child relationships: medications 1:N dose events; journal entries 1:N photo metadata; profiles participate in caregiver relationships in two roles.")
    add_bullet(doc, "All 11 public tables have RLS enabled. Storage policies also restrict private photo paths and access to the signed-in journal owner.")

    add_landscape_section(
        doc,
        required_images["schema"],
        "Complete database schema overview grouped into identity, health and scheduling, and journal and safety domains.",
        "Figure 3. Database schema overview with physical ownership references.",
    )

    add_landscape_section(
        doc,
        required_images["erd"],
        "High-resolution EverCare database entity relationship diagram showing core entities, selected fields, and principal links.",
        "Figure 4. EverCare core entity relationship diagram (ERD).",
        note=(
            "Scope note: this existing high-resolution ERD emphasizes the core relational feature tables. "
            "Figure 3 and the schema dictionary are authoritative for the complete 11-table model, including "
            "notifications and the separate auth.users ownership FK on journal photo metadata."
        ),
    )

    add_portrait_section(doc)
    doc.add_heading("Database Schema Dictionary", level=1)
    add_body(
        doc,
        "The following compact dictionary reflects the final state after all five migrations. A question mark denotes a nullable field; unmarked fields are NOT NULL unless the rule text states otherwise. Supabase-managed auth.users and storage.objects are referenced but are not recreated by the local application migrations.",
    )

    doc.add_heading("Identity and Trusted-Care Tables", level=2)
    add_schema_entry(
        doc,
        "profiles",
        "id uuid is both the PK and an FK to auth.users.id with cascade delete.",
        "id uuid; full_name text; phone_number text?; birth_date date?; user_type text; address text?; avatar_path text?; created_at timestamptz; updated_at timestamptz.",
        "user_type is senior, caregiver, or family_member. A signup trigger inserts the row; updated_at is maintained automatically. Owner can select/update/insert but has no client delete policy.",
    )
    add_schema_entry(
        doc,
        "medical_profiles",
        "user_id uuid is both the PK and an FK to auth.users.id with cascade delete and auth.uid() default.",
        "user_id uuid; blood_type text?; allergies text[]; conditions text[]; preferred_hospital text?; medical_notes text?; created_at timestamptz; updated_at timestamptz.",
        "Arrays default to empty. Owner-scoped CRUD is enforced by RLS; updated_at is automatic.",
    )
    add_schema_entry(
        doc,
        "caregiver_relationships",
        "id uuid PK; older_adult_id and caregiver_id are FKs to profiles.id with cascade delete.",
        "id uuid; older_adult_id uuid; caregiver_id uuid; relationship_label text?; status text; created_at timestamptz; updated_at timestamptz.",
        "Parties must differ and the pair is unique. Status is pending, accepted, declined, or revoked. A trigger prevents changing parties/label; RLS provides party-specific read/create/update/delete rules.",
    )

    doc.add_heading("Health and Scheduling Tables", level=2)
    add_schema_entry(
        doc,
        "medications",
        "id uuid PK; user_id uuid FK to auth.users.id with cascade delete and auth.uid() default.",
        "id uuid; user_id uuid; name text; dosage text; purpose text?; frequency text?; instructions text?; schedule_time time?; start_date date?; end_date date?; is_active boolean; schedule_days smallint[]; completed_at timestamptz?; created_at timestamptz; updated_at timestamptz.",
        "Name/dosage are nonblank; end date cannot precede start date; ISO weekdays are unique values 1–7; completed_at requires inactive state. Indexed by owner, active flag, and time.",
    )
    add_schema_entry(
        doc,
        "medication_dose_events",
        "id uuid PK; user_id uuid FK to auth.users.id; medication_id uuid FK to medications.id; both cascade on delete.",
        "id uuid; user_id uuid; medication_id uuid; scheduled_for timestamptz; taken_at timestamptz?; status text; created_at timestamptz; updated_at timestamptz.",
        "Status is scheduled, taken, missed, or skipped. taken requires taken_at; other states require null. medication_id + scheduled_for is unique. Owner/parent consistency is enforced by RLS and RPC checks.",
    )
    add_schema_entry(
        doc,
        "appointments",
        "id uuid PK; user_id uuid FK to auth.users.id with cascade delete and auth.uid() default.",
        "id uuid; user_id uuid; title text; doctor_name text?; specialty text?; starts_at timestamptz; clinic text?; address text?; notes text?; status text; completed_at timestamptz?; created_at timestamptz; updated_at timestamptz.",
        "Status is upcoming, completed, missed, or cancelled. completed_at is valid only for completed state. Server-clock trigger and RPCs restrict rescheduling and attendance transitions; start-time indexes support owner queries.",
        page_break_before=True,
    )
    add_schema_entry(
        doc,
        "blood_pressure_readings",
        "id uuid PK; user_id uuid FK to auth.users.id with cascade delete and auth.uid() default.",
        "id uuid; user_id uuid; systolic integer; diastolic integer; pulse integer; measured_at timestamptz; source text; monitor_name text?; decoder_name text?; raw_packet_hex text?; capture_metadata jsonb; notes text?; is_medically_verified boolean; created_at timestamptz; updated_at timestamptz.",
        "Ranges are systolic 1–350, diastolic 1–250, and pulse 1–300; source is ble or manual; verification is constrained to false. A trigger makes capture fields immutable. Indexed by owner/time; BLE packet identity is deduplicated when non-null.",
    )

    doc.add_heading("Journal and Safety Tables", level=2)
    add_schema_entry(
        doc,
        "journal_entries",
        "id uuid PK; user_id uuid FK to auth.users.id with cascade delete and auth.uid() default.",
        "id uuid; user_id uuid; entry_at timestamptz; title text; body text; mood text?; symptoms text[]; activities text[]; tags text[]; bookmarked boolean; created_at timestamptz; updated_at timestamptz.",
        "At least title or body must be nonblank. Arrays default to empty; bookmark defaults false. Owner-scoped CRUD and owner/time index apply.",
    )
    add_schema_entry(
        doc,
        "journal_entry_photos",
        "id uuid PK; user_id uuid FK to auth.users.id; journal_entry_id uuid FK to journal_entries.id; both cascade on delete.",
        "id uuid; user_id uuid; journal_entry_id uuid; storage_path text; display_order integer; created_at timestamptz.",
        "storage_path is unique and must begin user_id/journal_entry_id/. Display order is nonnegative. RLS confirms both owner and parent; indexes support ordered entry photos and owner history.",
    )
    add_schema_entry(
        doc,
        "emergency_contacts",
        "id uuid PK; user_id uuid FK to auth.users.id with cascade delete and auth.uid() default.",
        "id uuid; user_id uuid; name text; relationship text?; phone_number text; is_primary boolean; created_at timestamptz; updated_at timestamptz.",
        "Name/phone are nonblank. A partial unique index allows at most one primary contact per user; owner-scoped CRUD applies.",
    )
    add_schema_entry(
        doc,
        "notifications",
        "id uuid PK; user_id uuid FK to auth.users.id with cascade delete and auth.uid() default.",
        "id uuid; user_id uuid; title text; body text?; kind text; is_read boolean; created_at timestamptz.",
        "Title is nonblank. Authenticated clients can select owner records and update only is_read; there is no client insert/delete grant or current in-repository notification producer.",
    )

    database_security_heading = doc.add_heading("Database Security and Integrity", level=1)
    database_security_heading.paragraph_format.page_break_before = True
    doc.add_heading("Row Level Security and Grants", level=2)
    add_table(
        doc,
        ["Data area", "Effective authenticated-client access"],
        [
            ["profiles", "Owner select, update, and insert; no client delete policy."],
            ["medical_profiles, medications, appointments, journal_entries, emergency_contacts, blood_pressure_readings", "Owner-scoped select, insert, update, and delete using auth.uid()."],
            ["medication_dose_events", "Owner-scoped CRUD plus a parent-medication ownership check."],
            ["journal_entry_photos", "Owner-scoped CRUD plus a parent-journal ownership check."],
            ["caregiver_relationships", "Either party can read/delete; recipient creates pending/revokes; caregiver accepts or declines pending relationships."],
            ["notifications", "Owner select and update; grants restrict update to is_read. No client insert/delete."],
            ["journal-photos Storage", "Owner upload/read/delete under a user/journal path; bucket is private and no object update policy exists."],
        ],
        [2900, 6460],
        font_size=8.7,
    )

    doc.add_heading("Private Photo Storage", level=2)
    add_body(
        doc,
        "The private journal-photos bucket permits JPEG, PNG, WebP, HEIC, and HEIF objects up to 8 MiB. A journal owner uploads under user_id/journal_entry_id/..., and database metadata stores the object path and display order. Reads use a short-lived signed URL. The storage path is a logical link, not a PostgreSQL foreign key.",
    )

    doc.add_heading("Server-Side Functions and Triggers", level=2)
    add_table(
        doc,
        ["Function or trigger", "Purpose"],
        [
            ["handle_new_user / on_auth_user_created", "Creates a profiles row from validated Supabase Auth registration metadata."],
            ["get_my_caregiver_relationships", "Returns recipient-side relationships and reveals caregiver details only when accepted."],
            ["record_medication_dose_taken / missed", "Uses the server clock, validates ownership and occurrence age, and writes idempotent dose outcomes."],
            ["complete_medication", "Marks the owner's course inactive and records a server completion time."],
            ["reconcile_missed_appointments", "Marks the owner's unresolved visits missed after the 24-hour threshold."],
            ["complete_appointment / cancel_appointment", "Applies server-validated attendance transitions."],
            ["set_updated_at triggers", "Refresh updated_at on the nine mutable tables that contain it."],
            ["care-party immutability trigger", "Prevents changing relationship participants or label after creation."],
            ["BP capture immutability trigger", "Prevents edits to the stored device/manual measurement capture fields; notes may still be updated."],
            ["appointment transition trigger", "Rejects invalid schedule/status combinations and assigns trusted completion timestamps."],
        ],
        [3400, 5960],
        font_size=8.6,
    )

    doc.add_heading("Implementation Reference", level=1)
    add_table(
        doc,
        ["Repository path", "Responsibility"],
        [
            ["lib/main.dart, lib/app.dart", "Application initialization, system UI, Supabase initialization, global scopes, lifecycle handling, and MaterialApp."],
            ["lib/routes/", "Named route constants, route generation, and navigation observation."],
            ["lib/screens/", "Feature-specific user interfaces and screen-local state."],
            ["lib/widgets/", "Reusable UI elements plus backend, BLE, and accessibility scopes."],
            ["lib/models/", "Typed Dart domain and transport records."],
            ["lib/repositories/", "Owner-filtered data queries, CRUD operations, Storage coordination, and PostgreSQL RPC calls."],
            ["lib/services/", "Authentication, BLE, hospital lookup, AI, accessibility preferences, and Care Book/download integrations."],
            ["lib/decoders/", "YK-IBPA1 packet decoding and separation of progress versus completed-result packets."],
            ["supabase/migrations/", "Authoritative PostgreSQL tables, constraints, indexes, triggers, functions, grants, and RLS policies."],
            ["supabase/functions/", "Authenticated BP and Care Book Edge Functions and shared Groq integration."],
            ["test/", "Widget, model, repository, decoder, and service-level automated tests."],
        ],
        [2850, 6510],
        font_size=8.7,
    )

    doc.add_heading("Current Scope and Limitations", level=1)
    add_bullet(doc, "Account user_type does not change authorization, navigation, or the feature set; all authenticated roles use the same shell.")
    add_bullet(doc, "Trusted People is a recipient-side foundation. Invitation/acceptance UI and cross-user health-record sharing are not implemented.")
    add_bullet(doc, "Medication and appointment reminders are reconciled in-app; no background operating-system notification scheduler or push-notification service is present.")
    add_bullet(doc, "The notifications table is a read/mark-read feed. Current application and migration code do not produce notification rows.")
    add_bullet(doc, "Emergency actions copy numbers and open guidance/maps. There is no automatic dial, SMS, SOS, caregiver alert, or emergency-dispatch integration.")
    add_bullet(doc, "Hospital lookup uses public OpenStreetMap infrastructure intended for low-volume development/classroom demonstration; results and service availability must be verified.")
    add_bullet(doc, "Saved BP readings are not medically verified. The YK-IBPA1 decoder/calibration is provisional and requires explicit user confirmation before persistence.")
    add_bullet(doc, "AI output is educational/supportive, not clinical advice. Groq is called only from authenticated Edge Functions, and provider credentials are not stored in the mobile app.")
    add_bullet(doc, "There is no administrator or clinician portal in the current repository.")

    source_heading = doc.add_heading("Source of Truth", level=1)
    source_heading.paragraph_format.page_break_before = True
    add_body(
        doc,
        "This documentation was prepared from the checked-in EverCare source. The following files and folders should be consulted first when the application changes:",
    )
    add_bullet(doc, "supabase/migrations/ — database schema, RLS, functions, triggers, grants, indexes, and private photo policies.")
    add_bullet(doc, "lib/main.dart, lib/app.dart, lib/routes/, lib/screens/home/main_shell.dart — startup, dependency composition, routing, and main navigation.")
    add_bullet(doc, "lib/repositories/ and lib/services/ — implemented data flows and external integrations.")
    add_bullet(doc, "README.md and docs/AI_SETUP.md — current setup, operational behavior, and integration limits.")
    add_bullet(doc, "docs/week 6/ — editable Mermaid summaries, high-resolution figures, migration verification notes, and demo material.")

    doc.add_heading("Conclusion", level=1)
    add_body(
        doc,
        "EverCare combines an accessible Flutter client with an owner-scoped Supabase data layer, private journal media, server-validated care rules, BLE blood-pressure capture, and carefully bounded external integrations. The database schema, RLS policies, triggers, RPCs, and explicit implementation limits documented here define the current system boundary and provide a dependable reference for future development and evaluation.",
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(output_path)
    print(output_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    build_document(args.output.resolve())


if __name__ == "__main__":
    main()
