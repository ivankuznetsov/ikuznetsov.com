#!/usr/bin/env python3
"""Generate uniform, minimal SVG charts for the code-reviewer eval post.

Site aesthetic: white background, Georgia serif, restrained greyscale + one
navy accent. No external deps — raw SVG so the output is crisp and identical
everywhere. Run: python3 script/gen_reviewer_charts.py
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..",
                   "assets", "images", "posts", "code-reviewer-eval")
OUT = os.path.abspath(OUT)
os.makedirs(OUT, exist_ok=True)

# palette
INK = "#2b2b2b"; SUB = "#6b6b6b"; GRID = "#ededed"; AXIS = "#cfcfcf"
NAVY = "#27496d"; MID = "#5d83a8"; LIGHT = "#b7c4d4"
GREY = "#c4cad2"; DARK = "#16304b"; BLUE = "#2f7ab0"
TFONT = "Georgia, 'Times New Roman', serif"
LFONT = "ui-sans-serif, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif"

W = 760


def esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def num(v):
    return f"{v:.0f}" if abs(v - round(v)) < 1e-9 else f"{v:.1f}"


def header(parts, title, subtitle=None, h=430):
    parts.append(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {h}" '
        f'width="100%" role="img" style="max-width:760px">')
    parts.append(f'<rect width="{W}" height="{h}" fill="#ffffff"/>')
    parts.append(
        f'<text x="40" y="40" font-family="{TFONT}" font-size="22" '
        f'fill="{INK}">{esc(title)}</text>')
    if subtitle:
        parts.append(
            f'<text x="40" y="62" font-family="{LFONT}" font-size="13.5" '
            f'fill="{SUB}">{esc(subtitle)}</text>')


def yaxis(parts, top, plotH, ymax, ticks, left):
    for t in ticks:
        py = top + plotH * (1 - t / ymax)
        parts.append(f'<line x1="{left}" y1="{py:.1f}" x2="{W-24}" y2="{py:.1f}" '
                     f'stroke="{GRID}" stroke-width="1"/>')
        parts.append(f'<text x="{left-10}" y="{py+4:.1f}" text-anchor="end" '
                     f'font-family="{LFONT}" font-size="12.5" fill="{SUB}">{t}</text>')


def grouped(fn, title, categories, series, ymax, ticks, fmt="{:.0f}",
            subtitle=None, h=430, ylabel="recall %"):
    left, right, top, bottom = 56, 24, 78, 62
    plotW = W - left - right
    plotH = h - top - bottom
    parts = []
    header(parts, title, subtitle, h)
    yaxis(parts, top, plotH, ymax, ticks, left)
    parts.append(f'<text x="16" y="{top+plotH/2:.0f}" font-family="{LFONT}" '
                 f'font-size="12.5" fill="{SUB}" transform="rotate(-90 16 {top+plotH/2:.0f})" '
                 f'text-anchor="middle">{ylabel}</text>')
    n = len(categories)
    gslot = plotW / n
    ns = len(series)
    gpad = gslot * 0.18
    bw = (gslot - 2 * gpad) / ns
    for gi, cat in enumerate(categories):
        gx = left + gi * gslot + gpad
        for si, (sname, color, vals) in enumerate(series):
            v = vals[gi]
            bx = gx + si * bw
            by = top + plotH * (1 - v / ymax)
            bh = plotH * (v / ymax)
            parts.append(f'<rect x="{bx:.1f}" y="{by:.1f}" width="{bw-4:.1f}" '
                         f'height="{bh:.1f}" rx="2" fill="{color}"/>')
            parts.append(f'<text x="{bx+(bw-4)/2:.1f}" y="{by-7:.1f}" '
                         f'text-anchor="middle" font-family="{LFONT}" font-size="13" '
                         f'fill="{INK}">{num(v)}</text>')
        parts.append(f'<text x="{left+gi*gslot+gslot/2:.1f}" y="{top+plotH+22:.0f}" '
                     f'text-anchor="middle" font-family="{LFONT}" font-size="13.5" '
                     f'fill="{INK}">{esc(cat)}</text>')
    # legend — top-right, on the title baseline (avoids subtitle collision)
    items = []
    total = 0.0
    for sname, color, _ in series:
        w_item = 13 + 6 + 7.2 * len(sname) + 22
        items.append((sname, color, w_item))
        total += w_item
    lx = W - 24 - total
    ly = 40
    for sname, color, w_item in items:
        parts.append(f'<rect x="{lx:.1f}" y="{ly-11}" width="13" height="13" rx="2" fill="{color}"/>')
        parts.append(f'<text x="{lx+19:.1f}" y="{ly}" font-family="{LFONT}" font-size="13" '
                     f'fill="{SUB}">{esc(sname)}</text>')
        lx += w_item
    parts.append('</svg>')
    write(fn, parts)


def single(fn, title, bars, ymax, ticks, fmt="{:.0f}", subtitle=None, h=430,
           ylabel="recall %", brackets=None):
    # bars: list of (label, value, color)
    if brackets:
        top = 118 if subtitle else 104
    elif subtitle:
        top = 92
    else:
        top = 78
    left, right, bottom = 56, 24, 72
    plotW = W - left - right
    plotH = h - top - bottom
    parts = []
    header(parts, title, subtitle, h)
    yaxis(parts, top, plotH, ymax, ticks, left)
    parts.append(f'<text x="16" y="{top+plotH/2:.0f}" font-family="{LFONT}" '
                 f'font-size="12.5" fill="{SUB}" transform="rotate(-90 16 {top+plotH/2:.0f})" '
                 f'text-anchor="middle">{ylabel}</text>')
    n = len(bars)
    slot = plotW / n
    bw = slot * 0.56
    centers = []
    for i, (label, v, color) in enumerate(bars):
        cx = left + i * slot + slot / 2
        centers.append(cx)
        bx = cx - bw / 2
        by = top + plotH * (1 - v / ymax)
        bh = plotH * (v / ymax)
        parts.append(f'<rect x="{bx:.1f}" y="{by:.1f}" width="{bw:.1f}" '
                     f'height="{bh:.1f}" rx="2" fill="{color}"/>')
        parts.append(f'<text x="{cx:.1f}" y="{by-7:.1f}" text-anchor="middle" '
                     f'font-family="{LFONT}" font-size="13" fill="{INK}">{num(v)}</text>')
        # wrap label on " "
        words = label.split(" ")
        lines, cur = [], ""
        for wd in words:
            if len(cur + " " + wd) > 14 and cur:
                lines.append(cur); cur = wd
            else:
                cur = (cur + " " + wd).strip()
        if cur:
            lines.append(cur)
        for li, ln in enumerate(lines):
            parts.append(f'<text x="{cx:.1f}" y="{top+plotH+20+li*14:.0f}" '
                         f'text-anchor="middle" font-family="{LFONT}" font-size="12.5" '
                         f'fill="{INK}">{esc(ln)}</text>')
    if brackets:
        hb = top - 18  # bracket line, in its own clear band above the plot
        for (i0, i1, txt) in brackets:
            x0 = centers[i0] - bw / 2 - 2
            x1 = centers[i1] + bw / 2 + 2
            parts.append(f'<path d="M{x0:.1f} {hb+6:.1f} L{x0:.1f} {hb:.1f} '
                         f'L{x1:.1f} {hb:.1f} L{x1:.1f} {hb+6:.1f}" fill="none" '
                         f'stroke="{AXIS}" stroke-width="1"/>')
            parts.append(f'<text x="{(x0+x1)/2:.1f}" y="{hb-7:.0f}" text-anchor="middle" '
                         f'font-family="{LFONT}" font-size="12.5" fill="{SUB}">{esc(txt)}</text>')
    parts.append('</svg>')
    write(fn, parts)


def diverging(fn, title, subtitle, rows, xmin, xmax, xticks, h=430):
    # rows: list of (label, value, color, endnote)
    left, right, top, bottom = 40, 24, 92, 56
    plotW = W - left - right
    plotH = h - top - bottom
    parts = []
    header(parts, title, subtitle, h)
    zx = left + plotW * (0 - xmin) / (xmax - xmin)
    # x ticks
    for t in xticks:
        tx = left + plotW * (t - xmin) / (xmax - xmin)
        parts.append(f'<text x="{tx:.1f}" y="{top+plotH+22:.0f}" text-anchor="middle" '
                     f'font-family="{LFONT}" font-size="11.5" fill="{SUB}">{"+" if t>0 else ""}{t}</text>')
    n = len(rows)
    rh = plotH / n
    bh = rh * 0.52
    for i, (label, v, color, note) in enumerate(rows):
        cy = top + i * rh + rh / 2
        vx = left + plotW * (v - xmin) / (xmax - xmin)
        x0 = min(zx, vx); bw = abs(vx - zx)
        if bw < 1.2:
            parts.append(f'<circle cx="{zx:.1f}" cy="{cy:.1f}" r="4" fill="{color}"/>')
        else:
            parts.append(f'<rect x="{x0:.1f}" y="{cy-bh/2:.1f}" width="{bw:.1f}" '
                         f'height="{bh:.1f}" rx="2" fill="{color}"/>')
        # row label to the left of plot baseline (right-anchored at left margin)
        parts.append(f'<text x="{left-2:.1f}" y="{cy-bh/2-8:.1f}" '
                     f'font-family="{LFONT}" font-size="13" fill="{INK}">{esc(label)}</text>')
        # value at bar end
        vlab = ("+" if v > 0 else "") + str(v)
        if v >= 0:
            parts.append(f'<text x="{vx+7:.1f}" y="{cy+4.5:.1f}" font-family="{LFONT}" '
                         f'font-size="13" font-weight="600" fill="{INK}">{vlab}</text>')
        else:
            parts.append(f'<text x="{vx-7:.1f}" y="{cy+4.5:.1f}" text-anchor="end" '
                         f'font-family="{LFONT}" font-size="13" font-weight="600" fill="{INK}">{vlab}</text>')
    # zero line
    parts.append(f'<line x1="{zx:.1f}" y1="{top-4}" x2="{zx:.1f}" y2="{top+plotH}" '
                 f'stroke="{SUB}" stroke-width="1" stroke-dasharray="3 3"/>')
    parts.append(f'<text x="{left}" y="{top+plotH+40:.0f}" font-family="{LFONT}" '
                 f'font-size="11.5" fill="{SUB}">gap widened</text>')
    parts.append(f'<text x="{W-24}" y="{top+plotH+40:.0f}" text-anchor="end" '
                 f'font-family="{LFONT}" font-size="11.5" fill="{SUB}">gap closed (points)</text>')
    parts.append('</svg>')
    write(fn, parts)


def write(fn, parts):
    path = os.path.join(OUT, fn)
    with open(path, "w") as f:
        f.write("\n".join(parts) + "\n")
    print("wrote", path)


# 1. evolution — 8 bars, two groups
single("evolution.svg",
       "Recall through the autoresearch loop",
       [("baseline", 6.9, MID), ("+ prompt", 10.7, MID), ("+ Opus", 13.9, MID),
        ("+ 2-pass union", 16.3, MID), ("+ per-hunk depth", 22.9, MID),
        ("+ depth & union", 29.1, MID), ("+ repository", 35.9, NAVY),
        ("+ grounded persona", 43.7, DARK)],
       50, [0, 10, 20, 30, 40, 50], fmt="{:.1f}",
       subtitle="private Go reviewer", h=460,
       brackets=[(0, 5, "diff-only"), (6, 7, "+ repository")])

# 2. matrix — v1 vs v2, Sonnet
grouped("matrix.svg",
        "v1 catalog vs v2 persona — diff-only (Sonnet)",
        ["DHH", "Rafael", "José", "Hockin"],
        [("v1 catalog", NAVY, [55, 61, 67, 26]),
         ("v2 persona", LIGHT, [41, 53, 36, 18])],
        80, [0, 20, 40, 60, 80])

# 3. control — private diff-only
single("control.svg",
       "Private Go reviewer — diff-only (the control)",
       [("Sonnet v1", 8.9, MID), ("Sonnet v2", 9.9, MID),
        ("Opus v1", 12.5, NAVY), ("Opus v2", 10.7, NAVY)],
       50, [0, 10, 20, 30, 40, 50], fmt="{:.1f}")

# 4. gap — diverging
diverging("gap.svg",
          "How much the stronger model closes the v1–v2 gap",
          "Sonnet → Opus  ·  blue = the model already knows the reviewer",
          [("José Valim  (31→13)", 18, BLUE, ""),
           ("DHH  (14→−2)", 16, BLUE, ""),
           ("Tim Hockin  (8→8)", 0, GREY, ""),
           ("Rafael França  (8→11)", -3, GREY, ""),
           ("private Go reviewer  (−1→2)", -3, GREY, "")],
          -6, 20, [-6, -3, 0, 3, 6, 10, 14, 18])

# 5. cross-tool
grouped("crosstool.svg",
        "Recall: diff-only vs full recipe",
        ["our clone", "pr-review-toolkit", "ce-code-review"],
        [("diff-only", GREY, [17.5, 7.7, 3.9]),
         ("full recipe", NAVY, [44, 34, 31])],
        50, [0, 10, 20, 30, 40, 50], fmt="{:.1f}",
        subtitle="private Go reviewer")

# 6. combined
single("combined.svg",
       "Combined review — private Go reviewer (full recipe)",
       [("ce-code-review", 31, GREY), ("our clone", 44, NAVY),
        ("clone + ce", 52, DARK)],
       60, [0, 20, 40, 60], fmt="{:.0f}")

print("done")
