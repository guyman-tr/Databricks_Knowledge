"""Build Dealing_dbo/_deploy-index.md from Tables/*.alter.sql (Generated rows)."""
from __future__ import annotations

from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / "knowledge/synapse/Wiki/Dealing_dbo/Tables"
OUT = ROOT / "knowledge/synapse/Wiki/Dealing_dbo/_deploy-index.md"


def main() -> None:
    alters = sorted(WIKI.glob("*.alter.sql"))
    names = [p.name[: -len(".alter.sql")] for p in alters]
    n = len(names)
    ts = date.today().isoformat()
    lines: list[str] = [
        "---",
        "",
        "## schema: Dealing_dbo",
        "database: Synapse DWH",
        f"total_deployable: {n}",
        f"generated: {n}",
        "deployed: 0",
        "failed: 0",
        "last_generate_batch: 0",
        "last_deploy_batch: 0",
        f'last_updated: "{ts}"',
        "",
        "## Schema ALTER + Deployment Progress",
        "",
        "| Metric                             | Value      |",
        "| ---------------------------------- | ---------- |",
        "| **Schema**                         | Dealing_dbo |",
        f"| **Total deployable**               | {n}        |",
        "| **Pending (no .alter.sql)**        | 0        |",
        f"| **Generated (awaiting UC deploy)** | {n}        |",
        "| **Deployed (UC)**                  | 0         |",
        "| **Stub-only (no UC)**              | 0          |",
        "| **Failed**                         | 0         |",
        "| **Stale**                          | 0          |",
        "| **Last generate batch**            | 0          |",
        "| **Last deploy batch**              | 0          |",
        f"| **Last updated**                   | {ts} |",
        "",
        "> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present, UC not deployed in this index pass. `Deployed` = UC ALTERs executed.",
        "",
        f"## Tables ({n})",
        "",
        "| Object                                                                                                                       | Deploy status                                                                                                                                      |",
        "| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |",
    ]
    for name in names:
        link = f"[Dealing_dbo.{name}](Tables/{name}.md)"
        lines.append(f"| {link:<124} | Generated |")
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}; {n} objects")


if __name__ == "__main__":
    main()
