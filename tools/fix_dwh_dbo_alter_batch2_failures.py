"""
Fix known-bad patterns in DWH_dbo *.alter.sql from batch-2 deploy failures:
- Remove documentation-tier junk columns (ALTER COLUMN Tier 1 .. Tier 5) — not real UC columns.
- Quote Dim_Channel.Organic/Paid with backticks for Databricks SQL.
- Replace invalid 'ALTER TABLE Not in Generic Pipeline...' scripts with comment-only stubs.

Run from repo root: python tools/fix_dwh_dbo_alter_batch2_failures.py
"""
from __future__ import annotations

import re
from pathlib import Path

WIKI = Path(__file__).resolve().parents[1] / "knowledge/synapse/Wiki/DWH_dbo/Tables"

FOOTER_RE = re.compile(
    r"\n*-- == LAST EXECUTION ==.*?-- ====================",
    re.DOTALL,
)

TIER_LINE = re.compile(
    r"^\s*ALTER TABLE\s+.+\s+ALTER COLUMN\s+Tier\s+\d+\s",
    re.IGNORECASE,
)


def strip_footer(raw: str) -> str:
    return FOOTER_RE.sub("", raw).rstrip()


def fix_tier_and_channel(text: str) -> str:
    lines = text.splitlines()
    out: list[str] = []
    for line in lines:
        if TIER_LINE.match(line):
            continue
        line = line.replace(
            "ALTER COLUMN Organic/Paid",
            "ALTER COLUMN `Organic/Paid`",
        )
        out.append(line)
    return "\n".join(out)


STUB_TEMPLATE = """-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.{name}
-- UC Target: _Not_Migrated — not in Generic Pipeline mapping; not exported to Gold/UC
-- No executable ALTER statements until a UC Gold table exists (semantic wiki only).
-- =============================================================================
"""


def stub_no_uc(name: str) -> str:
    return STUB_TEMPLATE.format(name=name)


def main() -> None:
    n_tier = 0
    n_channel = 0
    n_stub = 0

    for path in sorted(WIKI.glob("*.alter.sql")):
        raw = path.read_text(encoding="utf-8")
        base = strip_footer(raw)

        if "ALTER TABLE Not in Generic Pipeline mapping" in raw:
            name = path.stem.replace(".alter", "")
            path.write_text(stub_no_uc(name) + "\n", encoding="utf-8")
            n_stub += 1
            continue

        if "ALTER COLUMN Tier " in raw or "ALTER COLUMN Organic/Paid" in raw:
            new = fix_tier_and_channel(base)
            if "ALTER COLUMN Tier " in raw:
                n_tier += 1
            if "ALTER COLUMN Organic/Paid" in raw:
                n_channel += 1
            path.write_text(new + "\n", encoding="utf-8")

    print(f"Done: stubs={n_stub}, files with Tier lines fixed={n_tier}, Dim_Channel backticks applied (counted if file had Organic/Paid)")


if __name__ == "__main__":
    main()
