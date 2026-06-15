#!/usr/bin/env python3
"""Convert tools/_staging_vs_snapshot_findings.md to a PDF for sharing."""
from pathlib import Path
from datetime import datetime
from markdown_pdf import MarkdownPdf, Section

REPO = Path(__file__).resolve().parents[1]
SRC = REPO / "tools" / "_staging_vs_snapshot_findings.md"
OUT = REPO / "tools" / "DWH_staging_vs_DBX_snapshot_audit_2026-05-24.pdf"

css = """
body { font-family: 'Segoe UI', Arial, sans-serif; font-size: 10.5pt; color: #1a1a1a; line-height: 1.45; }
h1 { color: #0b3d91; border-bottom: 2px solid #0b3d91; padding-bottom: 6px; margin-top: 0; }
h2 { color: #0b3d91; margin-top: 22px; border-bottom: 1px solid #ccd; padding-bottom: 3px; }
h3 { color: #b00020; margin-top: 16px; }
table { border-collapse: collapse; margin: 8px 0 14px 0; width: 100%; }
th, td { border: 1px solid #bbb; padding: 4px 8px; font-size: 9.5pt; text-align: left; vertical-align: top; }
th { background: #eef2f7; }
code { background: #f4f4f4; padding: 1px 4px; border-radius: 3px; font-size: 9.5pt; font-family: 'Consolas','Courier New', monospace; }
pre { background: #f4f4f4; padding: 8px 10px; border-radius: 4px; font-size: 9pt; overflow-x: auto; line-height: 1.35; }
pre code { background: transparent; padding: 0; }
hr { border: 0; border-top: 1px solid #ccc; margin: 18px 0; }
.footer { color: #888; font-size: 8.5pt; text-align: center; margin-top: 24px; }
"""

md_text = SRC.read_text(encoding="utf-8")
header = (
    "# DWH_staging (Synapse) vs daily_snapshot (DBX) — full audit\n\n"
    f"_Generated {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')} • "
    "source: `tools/_compare_staging_vs_snapshot.py` • "
    "detail: `tools/_staging_vs_snapshot_diff.csv` (139 rows)_\n\n---\n\n"
)
# strip the existing H1+intro paragraph from the source (we replaced it with the header above)
lines = md_text.splitlines()
start = 0
for i, line in enumerate(lines):
    if line.startswith("## Scoreboard"):
        start = i
        break
body = "\n".join(lines[start:])
final_md = header + body

pdf = MarkdownPdf(toc_level=2, optimize=True)
pdf.add_section(Section(final_md, toc=False), user_css=css)
pdf.meta["title"] = "DWH_staging vs DBX daily_snapshot audit"
pdf.meta["author"] = "Guy / Data Platform"
pdf.meta["subject"] = "Snapshot-layer audit for Dim_Customer migration"
pdf.save(str(OUT))
print(f"wrote {OUT}")
print(f"size: {OUT.stat().st_size / 1024:.1f} KB")
