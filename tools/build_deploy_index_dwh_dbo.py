"""One-off / reusable: build DWH_dbo/_deploy-index.md from _index.md + .alter.sql on disk."""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[1] / "knowledge" / "synapse" / "Wiki" / "DWH_dbo"
INDEX = BASE / "_index.md"
OUT = BASE / "_deploy-index.md"


def section(md: str, heading: str, next_heading: str) -> str:
    m = re.search(
        rf"## {re.escape(heading)} \(\d+\)\s*\n(.*?)(?=\n## {re.escape(next_heading)})",
        md,
        re.DOTALL,
    )
    return m.group(1) if m else ""


def parse_rows(sec: str, folder: str) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in sec.splitlines():
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---"):
            continue
        parts = [p.strip() for p in line.split("|")]
        parts = [p for p in parts if p]
        if len(parts) < 3 or parts[0].lower() == "object":
            continue
        status = parts[-1]
        if "Done" not in status:
            continue
        obj_cell = parts[0]
        mm = re.search(r"DWH_dbo\.([\w]+)", obj_cell)
        if not mm:
            continue
        rows.append((mm.group(1), folder))
    return rows


def row_status(name: str, folder: str) -> str:
    if name == "Dim_AccountStatus":
        return "Deployed (Batch 1) — 2026-03-30"
    alter = BASE / folder / f"{name}.alter.sql"
    if alter.is_file():
        return "Generated"
    return "Pending"


def link(name: str, folder: str) -> str:
    return f"[DWH_dbo.{name}]({folder}/{name}.md)"


def main() -> None:
    md = INDEX.read_text(encoding="utf-8")
    tables = parse_rows(section(md, "Tables", "Views"), "Tables")
    views = parse_rows(section(md, "Views", "Skipped"), "Views")
    all_rows = tables + views
    total = len(all_rows)

    deployed = sum(1 for n, _ in all_rows if n == "Dim_AccountStatus")
    generated = sum(
        1 for n, f in all_rows
        if n != "Dim_AccountStatus" and (BASE / f / f"{n}.alter.sql").is_file()
    )
    pending = total - deployed - generated

    lines: list[str] = [
        "---",
        "schema: DWH_dbo",
        "database: Synapse DWH",
        f"total_deployable: {total}",
        f"generated: {generated}",
        f"deployed: {deployed}",
        "failed: 0",
        "last_generate_batch: 0",
        "last_deploy_batch: 1",
        'last_updated: "2026-03-30"',
        "---",
        "",
        "## Schema ALTER + Deployment Progress",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        "| **Schema** | DWH_dbo |",
        f"| **Total deployable** | {total} |",
        f"| **Pending (no .alter.sql)** | {pending} |",
        f"| **Generated (awaiting UC deploy)** | {generated} |",
        f"| **Deployed (UC)** | {deployed} |",
        "| **Stub-only (no UC)** | 0 |",
        "| **Failed** | 0 |",
        "| **Stale** | 0 |",
        "| **Last generate batch** | 0 |",
        "| **Last deploy batch** | 1 |",
        "| **Last updated** | 2026-03-30 |",
        "",
        "> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present, UC not deployed in this index pass. `Deployed` = UC ALTERs executed.",
        "",
        f"## Tables ({len(tables)})",
        "",
        "| Object | Deploy status |",
        "|--------|---------------|",
    ]
    for name, folder in sorted(tables, key=lambda x: x[0].lower()):
        lines.append(f"| {link(name, folder)} | {row_status(name, folder)} |")

    lines.extend(
        [
            "",
            f"## Views ({len(views)})",
            "",
            "| Object | Deploy status |",
            "|--------|---------------|",
        ]
    )
    for name, folder in sorted(views, key=lambda x: x[0].lower()):
        lines.append(f"| {link(name, folder)} | {row_status(name, folder)} |")

    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({total} objects, pending={pending}, generated={generated}, deployed={deployed})")


if __name__ == "__main__":
    main()
