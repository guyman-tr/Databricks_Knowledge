#!/usr/bin/env python3
"""
Phase 6 — Build _deploy-index.md for a UC domain.

UC domains keep ONE _deploy-index.md per domain (rather than per schema, like
the synapse-Wiki framework does), because a domain naturally spans multiple
UC schemas (e.g. moneyfarm → money_farm + etoro_kpi_prep + bi_output).

Output layout:
  knowledge/uc_domains/{domain}/_deploy-index.md

Markdown shape mirrors the synapse-Wiki convention so the existing
`deploy_alter_batch.py --wiki-root` runner can consume it (after a tiny
patch to that runner).

Usage:
  python tools/uc_domains/build_deploy_index.py --domain spaceship
  python tools/uc_domains/build_deploy_index.py --domain moneyfarm --dry-run
"""
from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DOMAIN_ROOT = REPO / "knowledge" / "uc_domains"
OBJECT_DIRS = ("Tables", "Views", "Functions")


def is_stub(path: Path) -> bool:
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        upper = s.upper()
        if upper.startswith("ALTER TABLE") or upper.startswith("ALTER VIEW") \
                or upper.startswith("COMMENT ON"):
            return False
    return True


def collect(schema_dir: Path) -> list[tuple[str, str, str, bool]]:
    """Return [(schema, folder, object_name, is_stub)] under <domain>/schemas/<schema>."""
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
    ap = argparse.ArgumentParser(description="Build _deploy-index.md for a UC domain")
    ap.add_argument("--domain", required=True, help="Domain name (folder under knowledge/uc_domains/)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    domain_dir = DOMAIN_ROOT / args.domain
    if not domain_dir.is_dir():
        print(f"ERROR: domain folder not found: {domain_dir}")
        return 1
    schemas_root = domain_dir / "schemas"
    if not schemas_root.is_dir():
        print(f"ERROR: no schemas/ subfolder under {domain_dir}")
        return 1

    items: list[tuple[str, str, str, bool]] = []
    for schema_dir in sorted(p for p in schemas_root.iterdir() if p.is_dir()):
        items.extend(collect(schema_dir))

    n_total = len(items)
    n_stub = sum(1 for *_, s in items if s)
    n_gen = n_total - n_stub
    ts = date.today().isoformat()

    if n_total == 0:
        print(f"No .alter.sql files found under {schemas_root}")
        return 1

    out_path = domain_dir / "_deploy-index.md"

    by_schema: dict[str, list[tuple[str, str, str, bool]]] = {}
    for schema, folder, name, stub in items:
        by_schema.setdefault(schema, []).append((schema, folder, name, stub))

    lines: list[str] = [
        "---",
        f"domain: {args.domain}",
        "framework: uc-domain-doc",
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
        f"# {args.domain} — UC ALTER Deployment Index",
        "",
        "| Metric                             | Value      |",
        "| ---------------------------------- | ---------- |",
        f"| **Domain**                         | {args.domain} |",
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
        f"    --wiki-root knowledge/uc_domains/{args.domain}/schemas \\",
        f"    --deploy-index knowledge/uc_domains/{args.domain}/_deploy-index.md \\",
        f"    --schema <schema-name> \\",
        f"    --batch-size 5 --deploy-batch 1",
        "```",
        "",
        "Authenticate via `DATABRICKS_TOKEN` (PAT) or `DATABRICKS_MCP_PROFILE=DEFAULT`.",
        "",
    ]

    for schema in sorted(by_schema.keys()):
        rows = sorted(by_schema[schema], key=lambda x: (x[1], x[2].lower()))
        executable = sum(1 for *_, s in rows if not s)
        stubs = sum(1 for *_, s in rows if s)
        lines.append(f"## Schema: `{schema}` — {executable} deployable, {stubs} stubs")
        lines.append("")
        lines.append("| Object | Deploy status |")
        lines.append("|--------|---------------|")
        for s, folder, name, stub in rows:
            link = f"[{s}.{name}](schemas/{s}/{folder}/{name}.md)"
            status = "Stub only" if stub else "Generated"
            lines.append(f"| {link} | {status} |")
        lines.append("")

    if args.dry_run:
        print(f"[dry-run] Would write {out_path}")
    else:
        out_path.write_text("\n".join(lines), encoding="utf-8")
        print(f"[deploy-index] wrote {out_path} (total={n_total}, executable={n_gen}, stubs={n_stub})")

    for schema, rows in sorted(by_schema.items()):
        executable = sum(1 for *_, s in rows if not s)
        stubs = sum(1 for *_, s in rows if s)
        print(f"  {schema}: {len(rows)} ({executable} executable, {stubs} stubs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
