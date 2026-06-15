#!/usr/bin/env python3
"""render_audit_compare.py — render a side-by-side compare view of a Tier 1
audit run.

Reads `report.csv` from an audit directory and writes `compare.md` (and
optionally `compare.html`) in the same directory. Each DWH wiki gets a
section with a 5-column table:

    | line | column | verdict | current description | source description |

Rows are in source order (file line number), so you can walk a single wiki
top-to-bottom and spot-check the judge's PASS verdicts in context.

Usage:
  python tools/render_audit_compare.py audits/_tier1_audit_dwh_dbo_<ts>
  python tools/render_audit_compare.py audits/_tier1_audit_dwh_dbo_<ts> --html
  python tools/render_audit_compare.py audits/_tier1_audit_dwh_dbo_<ts> --filter-wiki "Dim_Customer*"
  python tools/render_audit_compare.py audits/_tier1_audit_dwh_dbo_<ts> --only PASS
"""
from __future__ import annotations

import argparse
import csv
import sys
from collections import defaultdict
from fnmatch import fnmatch
from html import escape
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _trim(text: str, n: int = 500) -> str:
    text = (text or "").replace("\n", " ").strip()
    if len(text) <= n:
        return text
    return text[: n - 1].rstrip() + "…"


def _md_cell(text: str) -> str:
    """Escape pipe characters and collapse newlines so the cell is one MD row."""
    return (text or "").replace("|", "\\|").replace("\n", " ").strip()


def _verdict_badge_md(verdict: str, severity: str, layer: str) -> str:
    if verdict == "PASS":
        return "✓ PASS"
    sev = severity or "?"
    short_layer = layer.replace("L1-structural", "L1") \
                       .replace("L2-semantic", "L2") \
                       .replace("L0-unresolved", "L0")
    return f"✗ FAIL / {sev} / {short_layer}"


def _verdict_badge_html(verdict: str, severity: str, layer: str) -> str:
    if verdict == "PASS":
        return '<span style="color:green;font-weight:bold">PASS</span>'
    color = {"HIGH": "#c00", "MEDIUM": "#d80", "LOW": "#888"}.get(severity, "#444")
    sev = severity or "?"
    short_layer = layer.replace("L1-structural", "L1") \
                       .replace("L2-semantic", "L2") \
                       .replace("L0-unresolved", "L0")
    return (f'<span style="color:{color};font-weight:bold">FAIL</span> '
            f'<span style="color:#666">{sev}/{short_layer}</span>')


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------
def render_md(
    rows_by_wiki: dict[str, list[dict]],
    *,
    summary_line: str,
    cell_max_chars: int,
) -> str:
    out: list[str] = []
    out.append("# Tier 1 Audit — Side-by-Side Compare")
    out.append("")
    out.append(summary_line)
    out.append("")
    out.append("## Index")
    out.append("")
    for wiki, rows in sorted(rows_by_wiki.items()):
        fails = sum(1 for r in rows if r["verdict"] == "FAIL")
        passes = len(rows) - fails
        anchor = wiki.replace("/", "-").replace(".", "-").lower()
        out.append(f"- [`{wiki}`](#{anchor}) — {len(rows)} claims "
                   f"({passes} PASS, {fails} FAIL)")
    out.append("")
    for wiki, rows in sorted(rows_by_wiki.items()):
        anchor = wiki.replace("/", "-").replace(".", "-").lower()
        fails = sum(1 for r in rows if r["verdict"] == "FAIL")
        passes = len(rows) - fails
        out.append("---")
        out.append("")
        out.append(f"## `{wiki}` <a id=\"{anchor}\"></a>")
        out.append(f"_{len(rows)} claims — {passes} PASS, {fails} FAIL_")
        out.append("")
        # Sort by source-file line number so columns appear in document order
        rows_sorted = sorted(rows, key=lambda r: int(r.get("line_no") or 0))
        out.append("| line | column | verdict | current (DWH wiki) | source-of-truth |")
        out.append("|---:|---|---|---|---|")
        for r in rows_sorted:
            verdict_badge = _verdict_badge_md(r["verdict"], r["severity"], r["layer"])
            source_label = r["source_wiki"].split("/")[-1] if r["source_wiki"] else "—"
            src_desc = r["source_desc"] or "_(source-unresolved; no description)_"
            current = _md_cell(_trim(r["current_desc"], cell_max_chars))
            source = _md_cell(_trim(src_desc, cell_max_chars))
            # Append source filename in italics for context
            if r["source_wiki"]:
                source = f"_{source_label}_<br/>{source}"
            col_label = f"`{r['column_name']}`"
            # If FAIL with proposed fix, add a sub-line
            cells = [r["line_no"], col_label, verdict_badge, current, source]
            out.append("| " + " | ".join(str(c) for c in cells) + " |")
            if r["verdict"] == "FAIL" and r.get("judge_reason"):
                out.append(
                    f"| | | _reason_ | _{_md_cell(_trim(r['judge_reason'], 350))}_ | "
                    + (f"**fix:** {_md_cell(_trim(r['proposed_fix'], cell_max_chars))}"
                       if r.get("proposed_fix") else "")
                    + " |"
                )
        out.append("")
    return "\n".join(out)


def render_html(
    rows_by_wiki: dict[str, list[dict]],
    *,
    summary_line: str,
    cell_max_chars: int,
) -> str:
    parts: list[str] = []
    parts.append("<!doctype html><html><head><meta charset='utf-8'>")
    parts.append("<title>Tier 1 audit — side-by-side</title>")
    parts.append("<style>")
    parts.append(
        "body{font-family:-apple-system,Segoe UI,Helvetica,sans-serif;"
        "max-width:1500px;margin:1em auto;padding:0 1em;color:#222;}"
        "table{border-collapse:collapse;width:100%;table-layout:fixed;}"
        "th,td{border:1px solid #ddd;padding:6px 8px;vertical-align:top;"
        "font-size:13px;line-height:1.4;}"
        "th{background:#f4f4f4;text-align:left;font-weight:600;}"
        "tr.pass td.verdict{background:#e8f5e8;}"
        "tr.fail td.verdict{background:#fde7e7;}"
        "tr.reason td{background:#fffbe6;color:#665;font-size:12px;}"
        ".col-line{width:50px;text-align:right;color:#666;}"
        ".col-name{width:170px;font-family:Menlo,Consolas,monospace;color:#0a4;}"
        ".col-verdict{width:120px;text-align:center;}"
        ".src-label{font-style:italic;color:#888;font-size:11px;}"
        "h2{margin-top:2em;border-bottom:1px solid #ccc;padding-bottom:4px;}"
        ".summary{background:#eef;padding:8px 12px;border-left:4px solid #88a;}"
    )
    parts.append("</style></head><body>")
    parts.append("<h1>Tier 1 Audit — Side-by-Side Compare</h1>")
    parts.append(f"<p class='summary'>{escape(summary_line)}</p>")
    parts.append("<h2>Index</h2><ul>")
    for wiki, rows in sorted(rows_by_wiki.items()):
        fails = sum(1 for r in rows if r["verdict"] == "FAIL")
        passes = len(rows) - fails
        anchor = wiki.replace("/", "-").replace(".", "-").lower()
        parts.append(f"<li><a href='#{escape(anchor)}'><code>{escape(wiki)}</code></a> "
                     f"— {len(rows)} ({passes} PASS, {fails} FAIL)</li>")
    parts.append("</ul>")
    for wiki, rows in sorted(rows_by_wiki.items()):
        anchor = wiki.replace("/", "-").replace(".", "-").lower()
        fails = sum(1 for r in rows if r["verdict"] == "FAIL")
        passes = len(rows) - fails
        parts.append(f"<h2 id='{escape(anchor)}'><code>{escape(wiki)}</code> "
                     f"<span class='src-label'>({len(rows)} — {passes} PASS, {fails} FAIL)</span></h2>")
        parts.append("<table><thead><tr>"
                     "<th class='col-line'>line</th>"
                     "<th class='col-name'>column</th>"
                     "<th class='col-verdict'>verdict</th>"
                     "<th>current (DWH wiki)</th>"
                     "<th>source-of-truth</th>"
                     "</tr></thead><tbody>")
        rows_sorted = sorted(rows, key=lambda r: int(r.get("line_no") or 0))
        for r in rows_sorted:
            klass = "pass" if r["verdict"] == "PASS" else "fail"
            verdict_html = _verdict_badge_html(r["verdict"], r["severity"], r["layer"])
            src_label = r["source_wiki"].split("/")[-1] if r["source_wiki"] else "—"
            src_desc = r["source_desc"] or "<em>(source-unresolved; no description)</em>"
            parts.append(
                f"<tr class='{klass}'>"
                f"<td class='col-line'>{escape(str(r['line_no']))}</td>"
                f"<td class='col-name'>{escape(r['column_name'])}</td>"
                f"<td class='col-verdict verdict'>{verdict_html}</td>"
                f"<td>{escape(_trim(r['current_desc'], cell_max_chars))}</td>"
                f"<td><span class='src-label'>{escape(src_label)}</span><br/>"
                f"{escape(_trim(src_desc, cell_max_chars))}</td>"
                f"</tr>"
            )
            if r["verdict"] == "FAIL" and r.get("judge_reason"):
                reason = escape(_trim(r["judge_reason"], 600))
                fix = escape(_trim(r["proposed_fix"] or "", cell_max_chars))
                fix_html = f"<br/><b>fix:</b> {fix}" if fix else ""
                parts.append(
                    f"<tr class='reason'><td colspan='5'><b>reason:</b> {reason}{fix_html}</td></tr>"
                )
        parts.append("</tbody></table>")
    parts.append("</body></html>")
    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("audit_dir", type=Path,
                   help="Audit directory containing report.csv")
    p.add_argument("--html", action="store_true",
                   help="Also write compare.html (often easier to scan than MD)")
    p.add_argument("--filter-wiki", type=str, default=None,
                   help="Only include rows whose dwh_wiki matches this glob "
                        "(applied to the basename, e.g. 'Dim_Customer*')")
    p.add_argument("--only", choices=("PASS", "FAIL"), default=None,
                   help="Restrict to verdict")
    p.add_argument("--severity", choices=("HIGH", "MEDIUM", "LOW"), default=None,
                   help="Restrict to severity (FAILs only)")
    p.add_argument("--layer", choices=("L0-unresolved", "L1-structural",
                                       "L2-semantic", "L2-skipped"), default=None,
                   help="Restrict to layer")
    p.add_argument("--max-chars", type=int, default=600,
                   help="Per-cell truncation length")
    p.add_argument("--out-prefix", type=str, default="compare",
                   help="Output filename prefix (default: 'compare')")
    args = p.parse_args()

    audit_dir = args.audit_dir.resolve()
    csv_path = audit_dir / "report.csv"
    if not csv_path.exists():
        print(f"ERROR: {csv_path} not found", file=sys.stderr)
        return 2

    with csv_path.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    # Filtering
    if args.filter_wiki:
        rows = [r for r in rows if fnmatch(Path(r["dwh_wiki"]).name, args.filter_wiki)]
    if args.only:
        rows = [r for r in rows if r["verdict"] == args.only]
    if args.severity:
        rows = [r for r in rows if r["severity"] == args.severity]
    if args.layer:
        rows = [r for r in rows if r["layer"] == args.layer]

    grouped: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        grouped[r["dwh_wiki"]].append(r)

    total = len(rows)
    pass_n = sum(1 for r in rows if r["verdict"] == "PASS")
    fail_n = total - pass_n
    summary = (f"{total} claims across {len(grouped)} wikis "
               f"({pass_n} PASS, {fail_n} FAIL)")
    filter_bits = []
    if args.filter_wiki: filter_bits.append(f"wiki={args.filter_wiki}")
    if args.only:        filter_bits.append(f"verdict={args.only}")
    if args.severity:    filter_bits.append(f"severity={args.severity}")
    if args.layer:       filter_bits.append(f"layer={args.layer}")
    if filter_bits:
        summary += "  ·  filter: " + " ".join(filter_bits)

    md_out = audit_dir / f"{args.out_prefix}.md"
    md_out.write_text(render_md(grouped, summary_line=summary,
                                 cell_max_chars=args.max_chars),
                       encoding="utf-8")
    print(f"wrote {md_out.relative_to(REPO).as_posix()}")
    if args.html:
        html_out = audit_dir / f"{args.out_prefix}.html"
        html_out.write_text(render_html(grouped, summary_line=summary,
                                         cell_max_chars=args.max_chars),
                             encoding="utf-8")
        print(f"wrote {html_out.relative_to(REPO).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
