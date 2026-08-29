"""Generate print-ready monochrome diagrams for EverCare documentation.

The figures use a page-shaped 11 x 7 inch canvas at 300 DPI so labels remain
legible when placed on a US Letter landscape page.  They intentionally avoid
decorative color and reflect the current Flutter and Supabase implementation.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Polygon


ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "docs" / "week 6"

INK = "#111111"
MID = "#666666"
LIGHT = "#F2F2F2"
LIGHTER = "#FAFAFA"
WHITE = "#FFFFFF"


def canvas(title: str, subtitle: str):
    fig, ax = plt.subplots(figsize=(11, 7), dpi=300)
    fig.patch.set_facecolor(WHITE)
    ax.set_facecolor(WHITE)
    ax.set_xlim(0, 110)
    ax.set_ylim(0, 70)
    ax.axis("off")
    ax.text(
        55,
        67.7,
        title,
        ha="center",
        va="center",
        fontsize=18,
        fontweight="bold",
        color=INK,
    )
    ax.text(
        55,
        64.7,
        subtitle,
        ha="center",
        va="center",
        fontsize=10.5,
        color=MID,
    )
    return fig, ax


def box(
    ax,
    x: float,
    y: float,
    w: float,
    h: float,
    title: str,
    lines: str = "",
    *,
    fill: str = WHITE,
    linewidth: float = 1.4,
    dashed: bool = False,
    title_size: float = 10.5,
    body_size: float = 8.8,
    roundness: float = 0.8,
):
    patch = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle=f"round,pad=0.25,rounding_size={roundness}",
        facecolor=fill,
        edgecolor=INK,
        linewidth=linewidth,
        linestyle=(0, (4, 3)) if dashed else "solid",
        zorder=2,
    )
    ax.add_patch(patch)
    if lines:
        ax.text(
            x + w / 2,
            y + h * 0.67,
            title,
            ha="center",
            va="center",
            fontsize=title_size,
            fontweight="bold",
            color=INK,
            zorder=3,
        )
        ax.text(
            x + w / 2,
            y + h * 0.32,
            lines,
            ha="center",
            va="center",
            fontsize=body_size,
            color=INK,
            linespacing=1.25,
            zorder=3,
        )
    else:
        ax.text(
            x + w / 2,
            y + h / 2,
            title,
            ha="center",
            va="center",
            fontsize=title_size,
            fontweight="bold",
            color=INK,
            linespacing=1.2,
            zorder=3,
        )
    return patch


def container(ax, x, y, w, h, title, subtitle="", *, dashed=False):
    header_height = 5.2 if subtitle else 4.2
    patch = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.3,rounding_size=0.9",
        facecolor=LIGHTER,
        edgecolor=INK,
        linewidth=1.4,
        linestyle=(0, (5, 3)) if dashed else "solid",
        zorder=0,
    )
    ax.add_patch(patch)
    ax.add_patch(
        FancyBboxPatch(
            (x, y + h - header_height),
            w,
            header_height,
            boxstyle="round,pad=0.3,rounding_size=0.9",
            facecolor="#E4E4E4",
            edgecolor=INK,
            linewidth=1.0,
            zorder=1,
        )
    )
    ax.text(
        x + w / 2,
        y + h - (1.55 if subtitle else 2.05),
        title,
        ha="center",
        va="center",
        fontsize=10.7,
        fontweight="bold",
        color=INK,
        zorder=3,
    )
    if subtitle:
        ax.text(
            x + w / 2,
            y + h - 3.65,
            subtitle,
            ha="center",
            va="center",
            fontsize=7.4,
            color=MID,
            zorder=3,
        )
    return patch


def arrow(
    ax,
    start,
    end,
    label: str = "",
    *,
    rad: float = 0.0,
    dashed: bool = False,
    label_offset=(0.0, 0.0),
    linewidth: float = 1.25,
):
    patch = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=10,
        linewidth=linewidth,
        color=INK,
        linestyle=(0, (4, 3)) if dashed else "solid",
        connectionstyle=f"arc3,rad={rad}",
        shrinkA=2,
        shrinkB=2,
        zorder=4,
    )
    ax.add_patch(patch)
    if label:
        mx = (start[0] + end[0]) / 2 + label_offset[0]
        my = (start[1] + end[1]) / 2 + label_offset[1]
        ax.text(
            mx,
            my,
            label,
            ha="center",
            va="center",
            fontsize=7.8,
            color=INK,
            bbox=dict(facecolor=WHITE, edgecolor="none", pad=0.7),
            zorder=6,
        )
    return patch


def save(fig, filename: str):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    target = OUTPUT_DIR / filename
    fig.savefig(
        target,
        dpi=300,
        facecolor=WHITE,
        edgecolor=WHITE,
        bbox_inches=None,
        pad_inches=0,
    )
    plt.close(fig)
    return target


def generate_architecture():
    fig, ax = canvas(
        "EverCare System Architecture",
        "Implemented Flutter client, Supabase backend, device services, and external integrations",
    )

    box(
        ax,
        4,
        54.0,
        27,
        7.5,
        "People",
        "Senior • Caregiver • Family member",
        fill=LIGHT,
        body_size=9.0,
    )
    box(
        ax,
        79,
        54.0,
        27,
        7.5,
        "YK-IBPA1 BP Monitor",
        "Bluetooth Low Energy notifications",
        fill=LIGHT,
        body_size=9.0,
    )

    container(
        ax,
        3,
        31.0,
        104,
        19.0,
        "Flutter Mobile Client",
        "Portrait UI • Android BLE capture • authenticated Supabase client",
    )
    client_boxes = [
        (6, "Presentation\n& Navigation", "Screens • widgets\nNamed routes • eight-tab MainShell"),
        (31.5, "UI State\n& Shared Scopes", "StatefulWidget • futures • timers\nBLE and accessibility ChangeNotifiers"),
        (57, "Models\n& Business Rules", "Typed Dart records • validation\nSchedules • BP assessment"),
        (82.5, "Repositories\n& Services", "Owner-filtered CRUD • database RPCs\nAuth • BLE • AI • maps • photos"),
    ]
    for x, title, lines in client_boxes:
        box(
            ax,
            x,
            34.0,
            21.5,
            9.5,
            title,
            lines,
            fill=WHITE,
            title_size=8.6,
            body_size=7.25,
        )

    arrow(ax, (31, 57.7), (16.8, 50.0), "touch / view", rad=0.04)
    arrow(ax, (92.5, 54), (93.2, 43.5), "BLE packets")
    arrow(ax, (27.5, 38.7), (31.5, 38.7))
    arrow(ax, (53, 38.7), (57, 38.7))
    arrow(ax, (78.5, 38.7), (82.5, 38.7))

    container(
        ax,
        3,
        4.2,
        67,
        22.8,
        "Supabase Backend",
        "PostgreSQL 17 • authenticated requests • server-clock rules",
    )
    box(ax, 6, 14.8, 12, 6.3, "Auth", "Email/password\nSession identity", body_size=7.3)
    box(ax, 20.5, 14.8, 14.5, 6.3, "PostgREST + RPC", "CRUD endpoints\nServer functions", title_size=7.7, body_size=6.8)
    box(ax, 37.5, 14.8, 11.5, 6.3, "RLS", "Owner policies\nauth.uid() checks", body_size=7.3)
    box(ax, 51.5, 14.8, 15.5, 6.3, "PostgreSQL 17", "11 public tables\ntriggers • indexes", body_size=7.3)
    box(ax, 14.5, 6.5, 19, 5.4, "Private Storage", "journal-photos objects", body_size=7.3)
    box(ax, 39.0, 6.5, 20, 5.4, "Edge Functions", "BP insight/chat • Care Book AI", body_size=7.3)

    arrow(ax, (92.8, 34), (34, 27.0), "authenticated Supabase APIs", rad=0.04, label_offset=(0, 1.0))
    arrow(ax, (35, 18.0), (37.5, 18.0))
    arrow(ax, (49, 18.0), (51.5, 18.0))

    container(
        ax,
        73,
        4.2,
        34,
        22.8,
        "External and Device Services",
        "No embedded Google Maps SDK",
        dashed=True,
    )
    box(
        ax,
        76,
        14.6,
        13.0,
        6.5,
        "OpenStreetMap",
        "Tiles • Overpass\nNominatim • Photon",
        body_size=7.5,
        dashed=True,
    )
    box(
        ax,
        91.5,
        12.3,
        12.5,
        8.8,
        "Groq API",
        "GPT-OSS model\nserver-side only",
        body_size=7.5,
        dashed=True,
    )
    box(
        ax,
        76,
        6.5,
        13.0,
        5.3,
        "Device APIs",
        "Location • camera\nclipboard • files",
        body_size=7.4,
        dashed=True,
    )
    box(
        ax,
        91.5,
        6.5,
        12.5,
        4.2,
        "External Links",
        "Google Maps • NIA",
        body_size=7.4,
        dashed=True,
    )
    arrow(ax, (97, 34), (90, 27.0), "device / public services", rad=-0.02, label_offset=(0, 0.9))

    ax.text(
        55,
        1.5,
        "Persistent health and care data is protected by Supabase authentication and Row Level Security; local preferences store only accessibility and BLE setup choices.",
        ha="center",
        va="center",
        fontsize=8.3,
        color=MID,
    )
    return save(fig, "system_architecture.png")


def generate_schema_overview():
    fig, ax = canvas(
        "EverCare Database Schema Overview",
        "Physical ownership references, core table groups, and principal one-to-many relationships",
    )

    box(
        ax,
        42,
        55.5,
        26,
        6.5,
        "auth.users",
        "Supabase-managed account identity",
        fill=LIGHT,
        body_size=8.8,
    )

    group_specs = [
        (3, "Identity and Trusted Care", "profile keys reference auth.users"),
        (39, "Health and Scheduling", "each table has user_id → auth.users.id"),
        (75, "Journal and Safety", "each table has user_id → auth.users.id"),
    ]
    for x, title, subtitle in group_specs:
        container(ax, x, 8.0, 32, 41.5, title, subtitle)

    # Group 1: profile tables sit side by side so their relationship arrow
    # does not pass through another table.
    box(ax, 5.2, 31.5, 13.3, 9.0, "profiles", "PK/FK: id\n→ auth.users.id\nrole + identity", title_size=9.0, body_size=7.1)
    box(ax, 19.5, 31.5, 13.3, 9.0, "medical_profiles", "PK/FK: user_id\n→ auth.users.id\nmedical details", title_size=7.4, body_size=7.1)
    box(ax, 6.5, 15.0, 25, 10.0, "caregiver_\nrelationships", "older_adult_id → profiles.id\ncaregiver_id → profiles.id\nunique pair • status workflow", title_size=8.3, body_size=7.2)
    arrow(ax, (11.8, 31.5), (16.5, 25.0), "1 : N", rad=-0.05, label_offset=(-1.0, 0.6))

    # Group 2
    box(ax, 42, 36.0, 26, 6.0, "medications", "schedule and course state", body_size=7.5)
    box(ax, 42, 28.2, 26, 6.0, "medication_dose_events", "FK: medication_id → medications.id", title_size=9.0, body_size=7.4)
    box(ax, 42, 20.4, 26, 6.0, "appointments", "visit schedule and attendance state", body_size=7.5)
    box(ax, 42, 12.6, 26, 6.0, "blood_pressure_readings", "manual or BLE measurement capture", title_size=9.0, body_size=7.4)
    arrow(ax, (55, 36.0), (55, 34.2), "1 : N", label_offset=(3.0, 0.0))

    # Group 3
    box(ax, 78, 36.0, 26, 6.0, "journal_entries", "journal text and wellbeing tags", body_size=7.5)
    box(ax, 78, 28.2, 26, 6.0, "journal_entry_photos", "FK: journal_entry_id → journal_entries.id", title_size=9.0, body_size=7.3)
    box(ax, 78, 20.4, 26, 6.0, "emergency_contacts", "one optional primary contact per user", title_size=9.0, body_size=7.3)
    box(ax, 78, 12.6, 26, 6.0, "notifications", "read-only feed; client updates is_read", body_size=7.4)
    arrow(ax, (91, 36.0), (91, 34.2), "1 : N", label_offset=(3.0, 0.0))

    # Ownership arrows enter the group headers instead of crossing every table.
    arrow(ax, (49, 55.5), (19, 49.6), "identity FKs", rad=0.06, label_offset=(0, 0.8))
    arrow(ax, (55, 55.5), (55, 49.6), "owner FKs")
    arrow(ax, (61, 55.5), (91, 49.6), "owner FKs", rad=-0.06, label_offset=(0, 0.8))

    box(
        ax,
        4,
        1.8,
        102,
        4.0,
        "Security boundary",
        "RLS enabled on all 11 public tables • private photo files live in storage.objects and are linked by storage_path (not a database foreign key)",
        fill=LIGHT,
        title_size=9.2,
        body_size=7.6,
        roundness=0.5,
    )
    return save(fig, "database_schema_overview.png")


def diamond(ax, cx, cy, w, h, text, *, fontsize=9.2):
    points = [(cx, cy + h / 2), (cx + w / 2, cy), (cx, cy - h / 2), (cx - w / 2, cy)]
    patch = Polygon(points, closed=True, facecolor=LIGHT, edgecolor=INK, linewidth=1.4, zorder=2)
    ax.add_patch(patch)
    ax.text(
        cx,
        cy,
        text,
        ha="center",
        va="center",
        fontsize=fontsize,
        fontweight="bold",
        color=INK,
        linespacing=1.15,
        zorder=3,
    )
    return patch


def generate_system_flowchart():
    fig, ax = canvas(
        "EverCare Core System Flowchart",
        "Actual startup, authentication, feature selection, and authenticated data/integration flow",
    )

    box(ax, 44, 58.0, 22, 4.5, "Launch EverCare", fill=LIGHT, title_size=10.5)
    box(
        ax,
        34,
        50.2,
        42,
        5.7,
        "Initialize application",
        "Flutter bindings • Supabase • BLE scope • accessibility preferences",
        body_size=8.0,
    )
    arrow(ax, (55, 58), (55, 55.9))
    diamond(ax, 55, 43.5, 24, 8.5, "Active Supabase\nsession?")
    arrow(ax, (55, 50.2), (55, 47.8))

    box(
        ax,
        4,
        38.5,
        29,
        8.0,
        "Welcome and Authentication",
        "Onboarding • login • registration\npassword reset through Supabase Auth",
        body_size=7.8,
    )
    arrow(ax, (43, 43.5), (33, 43.0), "No")
    box(
        ax,
        42,
        31.7,
        26,
        6.0,
        "Authenticated MainShell",
        "Dashboard and eight feature tabs",
        fill=LIGHT,
        body_size=8.3,
    )
    arrow(ax, (55, 39.25), (55, 37.7), "Yes", label_offset=(2.8, 0.0))
    arrow(ax, (33, 39.5), (42, 34.7), "successful session", rad=-0.06, label_offset=(0, 0.7))
    diamond(ax, 55, 25.7, 22, 6.6, "Select a task")
    arrow(ax, (55, 31.7), (55, 29.0))

    # Three feature lanes.
    container(ax, 2, 6.4, 33, 15.0, "Health Capture", "explicit save required")
    box(ax, 5, 11.6, 27, 4.2, "BLE monitor or manual entry", "decode / validate / assess", title_size=8.6, body_size=7.2)
    box(ax, 5, 7.2, 27, 3.2, "Save and review", "history • trends • optional AI", title_size=8.7, body_size=7.1)

    container(ax, 38.5, 6.4, 33, 15.0, "Daily Care Records", "in-app reconciliation")
    box(ax, 41.5, 11.6, 27, 4.2, "Medicines • visits • journals", "create / read / update / delete", title_size=8.6, body_size=7.2)
    box(ax, 41.5, 7.2, 27, 3.2, "Server-validated outcomes", "dose/attendance RPCs • private photos", title_size=8.3, body_size=6.9)

    container(ax, 75, 6.4, 33, 15.0, "Safety and Reference", "no automatic emergency dispatch")
    box(ax, 78, 11.6, 27, 4.2, "Emergency • profile • Care Book", "contacts • medical info • handbook", title_size=8.4, body_size=7.1)
    box(ax, 78, 7.2, 27, 3.2, "Hospital and external help", "OSM search • copied phone • map links", title_size=8.2, body_size=6.9)

    arrow(ax, (49.5, 25.7), (18.5, 21.4), "Health", rad=0.06, label_offset=(0, 0.4))
    arrow(ax, (55, 22.4), (55, 21.4), "Care records", label_offset=(5.0, 0.0))
    arrow(ax, (60.5, 25.7), (91.5, 21.4), "Safety / reference", rad=-0.06, label_offset=(0, 0.4))
    arrow(ax, (18.5, 11.6), (18.5, 10.4))
    arrow(ax, (55, 11.6), (55, 10.4))
    arrow(ax, (91.5, 11.6), (91.5, 10.4))

    box(
        ax,
        12,
        0.7,
        86,
        4.4,
        "Repository and service boundary",
        "Authenticated Supabase APIs → Row Level Security → PostgreSQL / private Storage / Edge Functions; direct services handle BLE and public map/reference requests",
        fill=LIGHT,
        title_size=9.3,
        body_size=7.5,
        roundness=0.5,
    )
    arrow(ax, (18.5, 7.2), (31, 5.1), rad=-0.04)
    arrow(ax, (55, 7.2), (55, 5.1))
    arrow(ax, (91.5, 7.2), (79, 5.1), rad=0.04)

    ax.text(
        5,
        34.3,
        "Registration trigger\ncreates profiles row",
        ha="left",
        va="center",
        fontsize=7.7,
        color=MID,
    )
    ax.text(
        104.5,
        34.0,
        "Return to the dashboard\nor choose another tab",
        ha="right",
        va="center",
        fontsize=7.7,
        color=MID,
    )
    return save(fig, "system_flowchart.png")


def main():
    targets = [
        generate_architecture(),
        generate_schema_overview(),
        generate_system_flowchart(),
    ]
    for target in targets:
        print(target)


if __name__ == "__main__":
    main()
