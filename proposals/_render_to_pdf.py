"""Render a markdown report to a nicely-formatted PDF via Edge headless.

Usage:
    python _render_to_pdf.py <input.md> <output.pdf>

Pipeline:
    md -> HTML (via python-markdown with extensions) -> PDF (via msedge --headless --print-to-pdf)
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import markdown


CSS = r"""
@page {
    size: A4;
    margin: 22mm 18mm 22mm 18mm;
    @bottom-center {
        content: counter(page) " / " counter(pages);
        font-family: 'Inter', 'Segoe UI', sans-serif;
        font-size: 9pt;
        color: #888;
    }
}

* { box-sizing: border-box; }

html, body {
    font-family: 'Inter', 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
    font-size: 10.5pt;
    line-height: 1.55;
    color: #1f2328;
    background: #ffffff;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
}

.page {
    max-width: 175mm;
    margin: 0 auto;
}

h1, h2, h3, h4 {
    font-family: 'Inter', 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
    color: #0d1117;
    line-height: 1.25;
    page-break-after: avoid;
}

h1 {
    font-size: 24pt;
    font-weight: 700;
    margin: 0 0 6pt 0;
    letter-spacing: -0.5px;
}

h1 + p {
    font-size: 13pt;
    color: #57606a;
    font-weight: 500;
    margin: 0 0 4pt 0;
}

h1 + p + p em, h1 + p + p {
    font-size: 9.5pt;
    color: #6e7781;
    font-style: italic;
    margin: 0 0 18pt 0;
}

h2 {
    font-size: 16pt;
    font-weight: 700;
    margin: 22pt 0 8pt 0;
    padding-bottom: 4pt;
    border-bottom: 1.5px solid #d0d7de;
}

h3 {
    font-size: 12.5pt;
    font-weight: 600;
    margin: 18pt 0 6pt 0;
    color: #1f2328;
}

h4 {
    font-size: 11pt;
    font-weight: 600;
    margin: 14pt 0 4pt 0;
    color: #424a53;
}

p {
    margin: 0 0 8pt 0;
    text-align: justify;
    hyphens: auto;
}

strong {
    font-weight: 600;
    color: #0d1117;
}

em {
    font-style: italic;
}

ul, ol {
    margin: 4pt 0 10pt 0;
    padding-left: 22pt;
}

li {
    margin: 0 0 4pt 0;
}

li > p {
    margin: 0 0 4pt 0;
}

blockquote {
    margin: 8pt 0;
    padding: 8pt 14pt;
    border-left: 3px solid #1f6feb;
    background: #f6f8fa;
    color: #424a53;
    font-style: normal;
}

blockquote p {
    margin: 0;
    text-align: left;
}

blockquote p + p {
    margin-top: 6pt;
}

code {
    font-family: 'Cascadia Code', 'Consolas', 'Monaco', 'Menlo', monospace;
    font-size: 9.2pt;
    background: #f6f8fa;
    color: #cf222e;
    padding: 1pt 4pt;
    border-radius: 3px;
    border: 0.5px solid #d0d7de;
}

pre {
    background: #f6f8fa;
    border: 0.5px solid #d0d7de;
    border-radius: 5px;
    padding: 10pt 12pt;
    overflow-x: auto;
    margin: 8pt 0 12pt 0;
    page-break-inside: avoid;
    font-size: 9.2pt;
    line-height: 1.45;
}

pre code {
    background: transparent;
    border: none;
    padding: 0;
    color: #1f2328;
    font-size: 9.2pt;
}

.codehilite {
    background: #f6f8fa;
    border: 0.5px solid #d0d7de;
    border-radius: 5px;
    margin: 8pt 0 12pt 0;
    page-break-inside: avoid;
}

.codehilite pre {
    background: transparent;
    border: none;
    margin: 0;
    padding: 10pt 12pt;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin: 10pt 0 14pt 0;
    font-size: 9.5pt;
    page-break-inside: avoid;
}

thead {
    background: #1f2328;
    color: #ffffff;
}

th, td {
    border: 0.5px solid #d0d7de;
    padding: 6pt 9pt;
    text-align: left;
    vertical-align: top;
}

th {
    font-weight: 600;
    color: #ffffff;
}

tr:nth-child(even) td {
    background: #f6f8fa;
}

td:first-child {
    font-weight: 600;
    text-align: center;
    width: 24pt;
}

hr {
    border: none;
    border-top: 0.5px solid #d0d7de;
    margin: 18pt 0;
}

a {
    color: #0969da;
    text-decoration: none;
}

/* Pygments syntax highlighting tokens */
.codehilite .k, .codehilite .kd, .codehilite .kn { color: #cf222e; font-weight: 600; }
.codehilite .s, .codehilite .s1, .codehilite .s2 { color: #0a3069; }
.codehilite .nb, .codehilite .nf { color: #8250df; }
.codehilite .c, .codehilite .c1 { color: #6e7781; font-style: italic; }
.codehilite .mi, .codehilite .mf { color: #0550ae; }
.codehilite .p { color: #1f2328; }
.codehilite .nt { color: #116329; }
.codehilite .na { color: #0550ae; }

/* Title block — first heading prominent, no top margin */
h1:first-child { margin-top: 0; }

/* Avoid orphans / widows in important spots */
h2 + p, h3 + p { page-break-before: avoid; }
"""


HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
{css}
</style>
</head>
<body>
<div class="page">
{body}
</div>
</body>
</html>
"""


def md_to_html(md_path: Path) -> str:
    text = md_path.read_text(encoding="utf-8")
    md = markdown.Markdown(
        extensions=[
            "extra",       # tables, fenced code, footnotes, attr_list
            "codehilite",  # pygments-based code block highlighting
            "sane_lists",
            "smarty",      # smart quotes, em-dashes
        ],
        extension_configs={
            "codehilite": {
                "guess_lang": True,
                "noclasses": False,
                "css_class": "codehilite",
            },
        },
    )
    body = md.convert(text)
    return HTML_TEMPLATE.format(title=md_path.stem, css=CSS, body=body)


def find_edge() -> str:
    candidates = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    raise RuntimeError("Neither Edge nor Chrome found on this system.")


def render(md_path: Path, pdf_path: Path) -> None:
    html = md_to_html(md_path)
    edge = find_edge()

    with tempfile.TemporaryDirectory() as tmpdir:
        html_path = Path(tmpdir) / "report.html"
        html_path.write_text(html, encoding="utf-8")
        intermediate_pdf = Path(tmpdir) / "report.pdf"

        cmd = [
            edge,
            "--headless=new",
            "--disable-gpu",
            "--no-pdf-header-footer",
            "--no-margins",
            f"--print-to-pdf={intermediate_pdf}",
            html_path.as_uri(),
        ]
        print(f"  rendering with: {Path(edge).name}")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if result.returncode != 0:
            print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
            raise RuntimeError(f"Edge headless failed (exit {result.returncode})")

        if not intermediate_pdf.exists():
            raise RuntimeError("Edge did not produce a PDF.")

        shutil.copy(intermediate_pdf, pdf_path)
        size_kb = pdf_path.stat().st_size / 1024
        print(f"  wrote: {pdf_path}  ({size_kb:.1f} KB)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: python _render_to_pdf.py <input.md> <output.pdf>")
        sys.exit(2)
    render(Path(sys.argv[1]), Path(sys.argv[2]))
