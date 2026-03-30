"""
Reset Dealing_dbo _index.md to a clean state: all objects Pending, counters zeroed,
no completed-batch history. Primary wiki files only (excludes .review-needed.md, .lineage.md).

Run from repo root:
  python tools/reset_wiki_index_dealing_dbo.py
"""
from __future__ import annotations

from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "knowledge" / "synapse" / "Wiki" / "Dealing_dbo"
OUT = BASE / "_index.md"


def _primary_md_files(folder: Path) -> list[str]:
    out: list[str] = []
    for p in sorted(folder.glob("*.md")):
        if p.name.endswith(".review-needed.md") or p.name.endswith(".lineage.md"):
            continue
        out.append(p.stem)
    return out


def main() -> None:
    tables = _primary_md_files(BASE / "Tables")
    views = _primary_md_files(BASE / "Views")
    n_tab, n_view = len(tables), len(views)
    total = n_tab + n_view
    ts = date.today().isoformat()

    lines: list[str] = [
        "---",
        "schema: Dealing_dbo",
        "database: Synapse DWH",
        f"total_objects: {total}",
        "documented: 0",
        "blacklisted: 0",
        "failed: 0",
        "last_batch: 0",
        "skipped: 0",
        f'last_updated: "{ts}"',
        "quality_avg: 0",
        "---",
        "",
        "# Dealing_dbo — Schema Documentation Index",
        "",
        "## Schema Documentation Progress",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        "| **Schema** | Dealing_dbo |",
        f"| **Total Objects** | {total} |",
        f"| **Tables** | {n_tab} |",
        f"| **Views** | {n_view} |",
        "| **Documented** | 0 (0%) |",
        "| **Blacklisted** | 0 |",
        "| **Failed** | 0 |",
        "| **Skipped** | 0 |",
        f"| **Last Updated** | {ts} |",
        "",
        "---",
        "",
        "## Next Batch",
        "",
        "**Index reset** — all objects are `Pending`. Run your `build-wiki` / semantic batch command to plan Batch 1 and resume documentation.",
        "",
        "---",
        "",
        f"## Tables ({n_tab})",
        "",
        "| # | Object | Type | Quality | Status |",
        "|---|--------|------|---------|--------|",
    ]
    for i, name in enumerate(tables, start=1):
        lines.append(
            f"| {i} | [{name}](Tables/{name}.md) | Table | - | Pending |"
        )
    lines.extend(
        [
            "",
            f"## Views ({n_view})",
            "",
            "| # | Object | Type | Quality | Status |",
            "|---|--------|------|---------|--------|",
        ]
    )
    for i, name in enumerate(views, start=1):
        lines.append(
            f"| {i} | [{name}](Views/{name}.md) | View | - | Pending |"
        )
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}: {total} objects ({n_tab} tables, {n_view} views), all Pending")


if __name__ == "__main__":
    main()
