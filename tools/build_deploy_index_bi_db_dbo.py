"""Build BI_DB_dbo/_deploy-index.md from Tables/*.alter.sql + Functions/*.alter.sql."""
from __future__ import annotations

from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / "knowledge/synapse/Wiki/BI_DB_dbo"
OUT = WIKI / "_deploy-index.md"


def is_stub(path: Path) -> bool:
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        if s.startswith("ALTER TABLE") or s.startswith("ALTER VIEW"):
            return False
    return True


def collect(folder: str) -> list[tuple[str, str, bool]]:
    d = WIKI / folder
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
    tables = collect("Tables")
    functions = collect("Functions")
    all_items = tables + functions

    n_total = len(all_items)
    n_stub = sum(1 for _, _, s in all_items if s)
    n_gen = n_total - n_stub
    ts = date.today().isoformat()

    lines: list[str] = [
        "---",
        "",
        "## schema: BI_DB_dbo",
        "database: Synapse DWH",
        f"total_deployable: {n_total}",
        f"generated: {n_gen}",
        "deployed: 0",
        "failed: 0",
        f"stub_only: {n_stub}",
        "last_generate_batch: 0",
        "last_deploy_batch: 0",
        f'last_updated: "{ts}"',
        "",
        "## Schema ALTER + Deployment Progress",
        "",
        "| Metric                             | Value      |",
        "| ---------------------------------- | ---------- |",
        "| **Schema**                         | BI_DB_dbo  |",
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
        "> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed in this index pass. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).",
        "",
    ]

    if tables:
        lines.append(f"## Tables ({len(tables)})")
        lines.append("")
        lines.append(
            "| Object                                                                                                                       "
            "| Deploy status                                                                                                                                      |"
        )
        lines.append(
            "| ---------------------------------------------------------------------------------------------------------------------------- "
            "| -------------------------------------------------------------------------------------------------------------------------------------------------- |"
        )
        for name, folder, stub in tables:
            link = f"[BI_DB_dbo.{name}]({folder}/{name}.md)"
            status = "Stub only" if stub else "Generated"
            lines.append(f"| {link:<124} | {status} |")
        lines.append("")

    if functions:
        lines.append(f"## Functions ({len(functions)})")
        lines.append("")
        lines.append(
            "| Object                                                                                                                       "
            "| Deploy status                                                                                                                                      |"
        )
        lines.append(
            "| ---------------------------------------------------------------------------------------------------------------------------- "
            "| -------------------------------------------------------------------------------------------------------------------------------------------------- |"
        )
        for name, folder, stub in functions:
            link = f"[BI_DB_dbo.{name}]({folder}/{name}.md)"
            status = "Stub only" if stub else "Generated"
            lines.append(f"| {link:<124} | {status} |")
        lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"  Tables: {len(tables)} ({sum(1 for _,_,s in tables if not s)} executable, {sum(1 for _,_,s in tables if s)} stubs)")
    print(f"  Functions: {len(functions)} ({sum(1 for _,_,s in functions if not s)} executable, {sum(1 for _,_,s in functions if s)} stubs)")
    print(f"  Total Generated (deployable): {n_gen}")


if __name__ == "__main__":
    main()
