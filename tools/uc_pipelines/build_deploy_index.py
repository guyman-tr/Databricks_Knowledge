#!/usr/bin/env python3
"""
Phase 6 — Build _deploy-index.md for a UC-Pipeline schema.

Per-schema deploy index. Output layout:
  knowledge/UC_generated/{schema}/_deploy-index.md

Markdown shape mirrors the synapse-Wiki / uc_domains convention so the existing
`tools/deploy_alter_batch.py --wiki-root` runner can consume it. Same status
flow as `dwh-semantic-doc/11w-write-objects` and `uc-domain-doc/06-deploy`.

Usage:
  python tools/uc_pipelines/build_deploy_index.py --schema etoro_kpi_prep
  python tools/uc_pipelines/build_deploy_index.py --schema de_output --dry-run
"""
from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PACK_ROOT = REPO / "knowledge" / "UC_generated"
OBJECT_DIRS = ("Tables", "Views")


def is_stub(path: Path) -> bool:
    """True if an .alter.sql has no executable ALTER/COMMENT statements."""
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            s = line.strip()
            if not s or s.startswith("--"):
                continue
            upper = s.upper()
            if (upper.startswith("ALTER TABLE") or upper.startswith("ALTER VIEW")
                    or upper.startswith("COMMENT ON")):
                return False
    except Exception:
        return True
    return True


def collect(schema_dir: Path) -> list[tuple[str, str, str, bool]]:
    """Return [(schema, folder, object_name, is_stub)] under <pack>/<schema>."""
    out: list[tuple[str, str, str, bool]] = []
    schema_name = schema_dir.name
    for folder in OBJECT_DIRS:
        d = schema_dir / folder
        if not d.is_dir():
            continue
        for p in sorted(d.glob("*.alter.sql")):
            if ".downstream." in p.name:
                continue
            name = p.name.removesuffix(".alter.sql")
            out.append((schema_name, folder, name, is_stub(p)))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Build _deploy-index.md for a UC-pipeline schema")
    ap.add_argument("--schema", required=True, help="Schema folder under knowledge/UC_generated/")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    schema_dir = PACK_ROOT / args.schema
    if not schema_dir.is_dir():
        print(f"ERROR: schema folder not found: {schema_dir}")
        return 1

    items = collect(schema_dir)
    n_total = len(items)
    n_stub = sum(1 for *_, s in items if s)
    n_gen = n_total - n_stub
    ts = date.today().isoformat()

    if n_total == 0:
        print(f"No .alter.sql files found under {schema_dir}")
        return 1

    out_path = schema_dir / "_deploy-index.md"

    rows = sorted(items, key=lambda x: (x[1], x[2].lower()))
    executable = sum(1 for *_, s in rows if not s)
    stubs = sum(1 for *_, s in rows if s)

    lines: list[str] = [
        "---",
        f"schema: {args.schema}",
        "framework: uc-pipeline-doc",
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
        f"# {args.schema} — UC-Pipeline ALTER Deployment Index",
        "",
        "| Metric                             | Value      |",
        "| ---------------------------------- | ---------- |",
        f"| **Schema**                         | `main.{args.schema}` |",
        f"| **Total deployable**               | {n_total}  |",
        "| **Pending (no .alter.sql)**        | 0          |",
        f"| **Generated (awaiting UC deploy)** | {n_gen}    |",
        "| **Deployed (UC)**                  | 0          |",
        f"| **Stub-only (no UC)**              | {n_stub}   |",
        "| **Failed**                         | 0          |",
        "| **Last deploy batch**              | 0          |",
        f"| **Last updated**                   | {ts}       |",
        "",
        "> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` "
        "present with executable ALTER/COMMENT, UC not deployed. `Deployed` = UC "
        "ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).",
        "",
        "## How to deploy",
        "",
        "```",
        f"python tools/deploy_alter_batch.py \\",
        f"    --wiki-root knowledge/UC_generated/{args.schema} \\",
        f"    --deploy-index knowledge/UC_generated/{args.schema}/_deploy-index.md \\",
        f"    --schema {args.schema} \\",
        f"    --batch-size 5 --deploy-batch 1",
        "```",
        "",
        "Authenticate via `DATABRICKS_TOKEN` (PAT) or `DATABRICKS_MCP_PROFILE=DEFAULT`.",
        "",
        f"## Schema: `{args.schema}` — {executable} deployable, {stubs} stubs",
        "",
        "| Object | Deploy status |",
        "|--------|---------------|",
    ]
    for s, folder, name, stub in rows:
        link = f"[{s}.{name}]({folder}/{name}.md)"
        status = "Stub only" if stub else "Generated"
        lines.append(f"| {link} | {status} |")
    lines.append("")

    if args.dry_run:
        print(f"[dry-run] Would write {out_path}")
    else:
        out_path.write_text("\n".join(lines), encoding="utf-8")
        print(f"[deploy-index] wrote {out_path} (total={n_total}, executable={n_gen}, stubs={n_stub})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
