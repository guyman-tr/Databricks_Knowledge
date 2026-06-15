"""Dump pinned eval cases for human review.

Outputs:
  audits/eval_suite/cases_overview.csv  - one row per case (Excel-friendly)
  audits/eval_suite/cases_by_source.md  - readable markdown grouped by stream
"""
from __future__ import annotations

import csv
import json
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
CASES_DIR = REPO_ROOT / "tools" / "eval_suite" / "cases"
OUT_DIR = REPO_ROOT / "audits" / "eval_suite"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def _summary(ev: dict | None) -> str:
    if not ev:
        return ""
    t = ev.get("type", "")
    if t == "PENDING":
        return "PENDING"
    v = ev.get("value")
    if v is None:
        return f"{t}=NULL"
    if t == "numeric":
        try:
            return f"{float(v):,.4f}"
        except (TypeError, ValueError):
            return str(v)
    if t == "numeric_series":
        if isinstance(v, list):
            head = v[:3]
            return f"series[{len(v)}]: {head}"
    if t == "tabular":
        if isinstance(v, list):
            cols = ev.get("columns") or []
            return f"tabular[{len(v)}r x {len(cols)}c]: cols={cols} head={v[:1]}"
    return str(v)[:120]


def main() -> None:
    cases = sorted(CASES_DIR.glob("*.yaml"))

    csv_path = OUT_DIR / "cases_overview.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "id", "source", "skill_coverage_status", "expected_skill_hub",
            "asof", "ev_type", "ev_value_summary",
            "canonical_tables", "tags", "question", "ground_truth_sql", "notes",
        ])
        for case in cases:
            d = yaml.safe_load(case.read_text(encoding="utf-8"))
            ev = d.get("expected_value") or {}
            w.writerow([
                d.get("id"),
                d.get("source"),
                d.get("skill_coverage_status"),
                d.get("expected_skill_hub"),
                d.get("asof"),
                ev.get("type"),
                _summary(ev),
                ", ".join(d.get("canonical_tables") or []),
                ", ".join(d.get("tags") or []),
                d.get("question"),
                d.get("ground_truth_sql"),
                d.get("notes") or "",
            ])

    md_path = OUT_DIR / "cases_by_source.md"
    by_src: dict[str, list[dict]] = {}
    for case in cases:
        d = yaml.safe_load(case.read_text(encoding="utf-8"))
        src = (d.get("source") or "?").split(":")[0]
        by_src.setdefault(src, []).append(d)

    lines: list[str] = ["# Eval-Suite Cases — Question → SQL\n"]
    lines.append(f"_Total: {len(cases)} cases across {len(by_src)} sources._\n")

    for src in sorted(by_src):
        cs = by_src[src]
        lines.append(f"\n---\n## `{src}` — {len(cs)} cases\n")
        for d in cs:
            ev = d.get("expected_value") or {}
            lines.append(f"\n### `{d.get('id')}`")
            lines.append("")
            lines.append(f"- **NL question:** {d.get('question')}")
            lines.append(f"- **Skill hub:** `{d.get('expected_skill_hub')}` "
                         f"(coverage: `{d.get('skill_coverage_status')}`)")
            lines.append(f"- **Tables:** {', '.join(f'`{t}`' for t in (d.get('canonical_tables') or []))}")
            lines.append(f"- **asof:** {d.get('asof')}")
            lines.append(f"- **Expected:** `{ev.get('type')}` = `{_summary(ev)}`")
            if ev.get("type") == "tabular" and ev.get("columns"):
                cols = ev.get("columns") or []
                rows = ev.get("value") or []
                if rows:
                    lines.append("")
                    lines.append("  | " + " | ".join(str(c) for c in cols) + " |")
                    lines.append("  | " + " | ".join("---" for _ in cols) + " |")
                    for r in rows[:5]:
                        lines.append("  | " + " | ".join(
                            "" if c is None else str(c).replace("\n", " ")[:60] for c in r
                        ) + " |")
                    if len(rows) > 5:
                        lines.append(f"  _...{len(rows)-5} more rows_")
            if d.get("notes"):
                lines.append(f"- **Notes:** {d['notes']}")
            sql = (d.get("ground_truth_sql") or "").strip()
            lines.append("")
            lines.append("```sql")
            lines.append(sql)
            lines.append("```")

    md_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {csv_path.relative_to(REPO_ROOT)}")
    print(f"wrote {md_path.relative_to(REPO_ROOT)}")
    print(f"  {len(cases)} cases, {len(by_src)} sources")


if __name__ == "__main__":
    main()
