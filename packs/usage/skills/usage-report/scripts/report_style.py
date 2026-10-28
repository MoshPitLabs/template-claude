"""Shared look for the usage and context reports: self-contained HTML that uses the host's theme CSS
variables (--chart-1..5, --muted-foreground, --secondary, ...), so it fits a light or dark thread.

Layout, top to bottom: hero number, one stacked bar with a legend, a two-column grid of sections with
ranked bar rows, and a note. Every page element carries a hover tooltip (title attribute).
"""
import html

COLORS = ["--chart-1", "--chart-2", "--chart-3", "--chart-4", "--chart-5"]
OTHER = "--muted-foreground"

STYLE = """
body { margin:0; font-family:var(--font-sans); color:var(--foreground); }
.hero { display:flex; align-items:baseline; gap:12px; flex-wrap:wrap; }
.hero b { font:500 34px/1.1 var(--font-mono); }
.hero span { color:var(--muted-foreground); font-size:13px; }
.stack { display:flex; gap:2px; height:22px; margin:14px 0 8px; border-radius:4px; overflow:hidden; background:var(--secondary); }
.seg { display:block; height:100%; min-width:3px; }
.seg:hover { filter:brightness(1.15); }
.scale { display:flex; justify-content:space-between; font:11px var(--font-mono); color:var(--muted-foreground); }
.legend { display:flex; flex-wrap:wrap; gap:6px 16px; margin:14px 0 4px; font-size:12px; color:var(--muted-foreground); }
.lg b { color:var(--foreground); font-weight:500; font-family:var(--font-mono); margin-left:2px; }
i { display:inline-block; width:10px; height:10px; border-radius:3px; margin-right:6px; vertical-align:-1px; flex:none; }
.grid { display:grid; grid-template-columns:1fr 1fr; gap:22px 28px; margin-top:22px; padding-top:18px; border-top:1px solid var(--border); }
h4 { display:flex; align-items:center; margin:0; font-size:14px; font-weight:500; }
h4 span { margin-left:auto; font:12px var(--font-mono); color:var(--muted-foreground); }
.sub { margin:2px 0 8px; font-size:12px; color:var(--muted-foreground); }
.sub.ind { margin-left:16px; }
.row { display:grid; grid-template-columns:150px 1fr 52px; gap:10px; align-items:center; height:24px; cursor:default; }
.nm { font-size:12.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.tr { height:10px; background:var(--secondary); border-radius:3px; }
.br { display:block; height:100%; border-radius:3px; opacity:.85; }
.row:hover .br { opacity:1; }
.vl { text-align:right; font:12px var(--font-mono); }
.more { font-size:12px; color:var(--muted-foreground); margin-top:4px; }
.note { margin-top:22px; padding-top:14px; border-top:1px solid var(--border); font-size:12px; line-height:1.55; color:var(--muted-foreground); }
.note b { color:var(--foreground); font-weight:500; }
"""

ROW_H, SECTION_HEAD_H, GRID_GAP_H = 24, 46, 22


def esc(text):
    return html.escape(str(text), quote=True)


def swatch(color):
    return f'<i style="background:var({color})"></i>'


def hero(value, subtitle):
    return f'<div class="hero"><b>{esc(value)}</b><span>{esc(subtitle)}</span></div>'


def stack(segments, free=None, scale=None):
    """segments: [(label, value, color, tooltip)]; free: (value, tooltip) for unused capacity."""
    parts = [f'<span class="seg" style="flex:{v};background:var({c})" title="{esc(tip)}"></span>'
             for _, v, c, tip in segments if v > 0]
    if free:
        parts.append(f'<span class="seg" style="flex:{free[0]};background:transparent;min-width:0" title="{esc(free[1])}"></span>')
    out = f'<div class="stack">{"".join(parts)}</div>'
    if scale:
        out += '<div class="scale">' + "".join(f"<span>{esc(s)}</span>" for s in scale) + "</div>"
    return out


def legend(items):
    """items: [(label, value text, color)]."""
    return '<div class="legend">' + "".join(
        f'<span class="lg">{swatch(c)}{esc(label)} <b>{esc(val)}</b></span>' for label, val, c in items) + "</div>"


def section(title, rows, top, total_text="", sub="", color=None, more=""):
    """rows: [(label, value, value text, color, tooltip)], drawn relative to `top`."""
    head = f'<h4>{swatch(color) if color else ""}{esc(title)}<span>{esc(total_text)}</span></h4>'
    if sub:
        head += f'<p class="sub{" ind" if color else ""}">{esc(sub)}</p>'
    body = "".join(
        f'<div class="row" title="{esc(tip)}"><span class="nm">{esc(label)}</span>'
        f'<span class="tr"><span class="br" style="width:{max(v / top * 100 if top else 0, 0.6):.2f}%;background:var({c})"></span></span>'
        f'<span class="vl">{esc(vt)}</span></div>' for label, v, vt, c, tip in rows)
    if more:
        body += f'<div class="more">{esc(more)}</div>'
    return f"<section>{head}{body}</section>"


def section_height(n_rows, has_more=False):
    return SECTION_HEAD_H + n_rows * ROW_H + (20 if has_more else 0)


def grid(sections):
    return f'<div class="grid">{"".join(sections)}</div>'


def grid_height(heights):
    rows = [max(heights[i:i + 2]) for i in range(0, len(heights), 2)]
    return 40 + sum(rows) + GRID_GAP_H * (len(rows) - 1)


def note(inner_html):
    return f'<div class="note">{inner_html}</div>'


def page(body):
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{STYLE}</style></head><body>\n{body}\n</body></html>'


# Height of the parts above the grid: hero, stacked bar, scale, legend (one or two lines).
HEAD_H = 45 + 44 + 16 + 44
NOTE_H = 90


def tokens(x):
    return f"{x / 1e9:.1f}B" if x >= 1e9 else f"{x / 1e6:.1f}M" if x >= 1e6 else f"{x / 1e3:.1f}k" if x >= 1e3 else f"{x:.0f}"
