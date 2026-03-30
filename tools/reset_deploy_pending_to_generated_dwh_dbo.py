"""
Set every _deploy-index.md object row with status Pending -> Generated.

Leaves Deployed, Failed, Stub, and existing Generated unchanged. Recomputes YAML
and metrics table counts from the object rows.

Usage:
  python tools/reset_deploy_pending_to_generated_dwh_dbo.py
  python tools/reset_deploy_pending_to_generated_dwh_dbo.py --dry-run
"""
from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "knowledge/synapse/Wiki/DWH_dbo/_deploy-index.md"


def recount(md: str) -> tuple[int, int, int, int, int]:
    """generated, deployed, failed, pending, stub."""
    gen = dep = fail = pend = stub = 0
    for line in md.splitlines():
        if "[DWH_dbo." not in line or not line.strip().startswith("|"):
            continue
        segs = line.split("|")
        if len(segs) < 4:
            continue
        st = segs[2].strip()
        if st == "Generated":
            gen += 1
        elif st.startswith("Deployed"):
            dep += 1
        elif st.startswith("Failed"):
            fail += 1
        elif st == "Pending":
            pend += 1
        elif st.startswith("Stub"):
            stub += 1
    return gen, dep, fail, pend, stub


def main() -> None:
    ap = argparse.ArgumentParser(description="Pending -> Generated in DWH_dbo _deploy-index.md only.")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    text = PATH.read_text(encoding="utf-8")
    lines = text.splitlines()
    out: list[str] = []
    converted = 0

    row_re = re.compile(
        r"^(\|\s*\[DWH_dbo\.[^\]]+\]\([^)]+\)\s*)(\|)(.+)(\|)\s*$",
    )

    for line in lines:
        m = row_re.match(line)
        if m:
            pre, sep, status_cell, tail = m.group(1), m.group(2), m.group(3), m.group(4)
            st = status_cell.strip()
            if st == "Pending":
                out.append(
                    f"{pre}{sep} Generated                                                                                                                                    {tail}"
                )
                converted += 1
                continue
        out.append(line)

    text2 = "\n".join(out)
    gen, dep, fail, pend, stub = recount(text2)

    text2 = re.sub(r"^generated: \d+", f"generated: {gen}", text2, count=1, flags=re.MULTILINE)
    text2 = re.sub(r"^deployed: \d+", f"deployed: {dep}", text2, count=1, flags=re.MULTILINE)
    text2 = re.sub(r"^failed: \d+", f"failed: {fail}", text2, count=1, flags=re.MULTILINE)
    text2 = re.sub(
        r'^last_updated:.*$',
        f'last_updated: "{date.today().isoformat()}"',
        text2,
        flags=re.M,
    )

    text2 = re.sub(
        r"(\|\s+\*\*Pending \(no \.alter\.sql\)\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {pend}        \2",
        text2,
        count=1,
    )
    text2 = re.sub(
        r"(\|\s+\*\*Generated \(awaiting UC deploy\)\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {gen}        \2",
        text2,
        count=1,
    )
    text2 = re.sub(
        r"(\|\s+\*\*Deployed \(UC\)\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {dep}         \2",
        text2,
        count=1,
    )
    text2 = re.sub(
        r"(\|\s+\*\*Stub-only \(no UC\)\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {stub}          \2",
        text2,
        count=1,
    )
    text2 = re.sub(
        r"(\|\s+\*\*Failed\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {fail}         \2",
        text2,
        count=1,
    )

    if args.dry_run:
        print(f"[dry-run] Would convert {converted} Pending -> Generated")
        print(f"  Counts: generated={gen}, deployed={dep}, failed={fail}, pending={pend}, stub={stub}")
        return

    PATH.write_text(text2, encoding="utf-8")
    print(
        f"Wrote {PATH}; Pending -> Generated: {converted}. "
        f"Counts: generated={gen}, deployed={dep}, failed={fail}, pending={pend}, stub={stub}"
    )


if __name__ == "__main__":
    main()
