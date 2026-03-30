"""
Build or rebuild _deploy-index.md for ANY schema from .alter.sql files on disk.

Replaces the per-schema scripts (build_deploy_index_dwh_dbo.py, _dealing_dbo.py, _bi_db_dbo.py).
Scans Tables/, Views/, and Functions/ automatically.

Usage:
  python tools/build_deploy_index.py --schema DWH_dbo
  python tools/build_deploy_index.py --schema eMoney_dbo
  python tools/build_deploy_index.py --schema Dealing_dbo --dry-run
"""
from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"

OBJECT_DIRS = ("Tables", "Views", "Functions")


def is_stub(path: Path) -> bool:
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        if s.upper().startswith("ALTER TABLE") or s.upper().startswith("ALTER VIEW"):
            return False
    return True


def collect(schema_dir: Path, folder: str) -> list[tuple[str, str, bool]]:
    d = schema_dir / folder
    if not d.is_dir():
        return []
    out: list[tuple[str, str, bool]] = []
    for p in sorted(d.glob("*.alter.sql")):
        if ".downstream." in p.name:
            continue
        name = p.name.removesuffix(".alter.sql")
        out.append((name, folder, is_stub(p)))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description="Build _deploy-index.md for a schema")
    ap.add_argument(
        "--schema", required=True,
        help="Schema folder name under knowledge/synapse/Wiki/ (e.g. DWH_dbo, eMoney_dbo)"
    )
    ap.add_argument("--dry-run", action="store_true", help="Print summary without writing")
    args = ap.parse_args()

    schema = args.schema
    schema_dir = WIKI_ROOT / schema
    if not schema_dir.is_dir():
        print(f"ERROR: Schema directory not found: {schema_dir}")
        raise SystemExit(1)

    out_path = schema_dir / "_deploy-index.md"

    by_folder: dict[str, list[tuple[str, str, bool]]] = {}
    for folder in OBJECT_DIRS:
        items = collect(schema_dir, folder)
        if items:
            by_folder[folder] = items

    all_items = [item for items in by_folder.values() for item in items]
    n_total = len(all_items)
    n_stub = sum(1 for _, _, s in all_items if s)
    n_gen = n_total - n_stub
    ts = date.today().isoformat()

    if n_total == 0:
        print(f"No .alter.sql files found under {schema_dir} in {', '.join(OBJECT_DIRS)}")
        raise SystemExit(1)

    lines: list[str] = [
        "---",
        f"schema: {schema}",
        "database: Synapse DWH",
        f"total_deployable: {n_total}",
        f"generated: {n_gen}",
        "deployed: 0",
        "failed: 0",
        f"stub_only: {n_stub}",
        "last_generate_batch: 0",
        "last_deploy_batch: 0",
        f'last_updated: "{ts}"',
        "---",
        "",
        "## Schema ALTER + Deployment Progress",
        "",
        "| Metric                             | Value      |",
        "| ---------------------------------- | ---------- |",
        f"| **Schema**                         | {schema}   |",
        f"| **Total deployable**               | {n_total}  |",
        "| **Pending (no .alter.sql)**        | 0          |",
        f"| **Generated (awaiting UC deploy)** | {n_gen}    |",
        "| **Deployed (UC)**                  | 0          |",
        f"| **Stub-only (no UC)**              | {n_stub}   |",
        "| **Failed**                         | 0          |",
        "| **Stale**                          | 0          |",
        "| **Last generate batch**            | 0          |",
        "| **Last deploy batch**              | 0          |",
        f"| **Last updated**                   | {ts}       |",
        "",
        "> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).",
        "",
    ]

    for folder, items in by_folder.items():
        lines.append(f"## {folder} ({len(items)})")
        lines.append("")
        lines.append("| Object | Deploy status |")
        lines.append("|--------|---------------|")
        for name, fld, stub in sorted(items, key=lambda x: x[0].lower()):
            link = f"[{schema}.{name}]({fld}/{name}.md)"
            status = "Stub only" if stub else "Generated"
            lines.append(f"| {link} | {status} |")
        lines.append("")

    if args.dry_run:
        print(f"[dry-run] Would write {out_path}")
        for folder, items in by_folder.items():
            stubs = sum(1 for _, _, s in items if s)
            exe = len(items) - stubs
            print(f"  {folder}: {len(items)} ({exe} executable, {stubs} stubs)")
        print(f"  Total Generated (deployable): {n_gen}")
        return

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path}")
    for folder, items in by_folder.items():
        stubs = sum(1 for _, _, s in items if s)
        exe = len(items) - stubs
        print(f"  {folder}: {len(items)} ({exe} executable, {stubs} stubs)")
    print(f"  Total Generated (deployable): {n_gen}")


if __name__ == "__main__":
    main()
