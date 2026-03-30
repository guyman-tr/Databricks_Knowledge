"""
Reset deploy status in _deploy-index.md for ANY schema.

Replaces reset_deploy_index_dwh_dbo.py and reset_deploy_pending_to_generated_dwh_dbo.py.

Modes:
  --mode pending-to-generated   Convert Pending rows to Generated (useful after
                                batch ALTER generation when index was pre-existing)
  --mode reset-deployed         Reset Deployed/Failed rows back to Generated
                                (for full redeploy)

Usage:
  python tools/reset_deploy_status.py --schema DWH_dbo --mode pending-to-generated
  python tools/reset_deploy_status.py --schema eMoney_dbo --mode reset-deployed --dry-run
"""
from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"


def recount(md: str, schema: str) -> dict[str, int]:
    prefix = f"[{schema}."
    counts = {"generated": 0, "deployed": 0, "failed": 0, "pending": 0, "stub": 0}
    for line in md.splitlines():
        if prefix not in line or not line.strip().startswith("|"):
            continue
        segs = line.split("|")
        if len(segs) < 4:
            continue
        st = segs[2].strip()
        if st == "Generated":
            counts["generated"] += 1
        elif st.startswith("Deployed"):
            counts["deployed"] += 1
        elif st.startswith("Failed"):
            counts["failed"] += 1
        elif st == "Pending":
            counts["pending"] += 1
        elif st.startswith("Stub"):
            counts["stub"] += 1
    return counts


def update_metrics(text: str, counts: dict[str, int]) -> str:
    text = re.sub(r"^generated: \d+", f"generated: {counts['generated']}", text, count=1, flags=re.MULTILINE)
    text = re.sub(r"^deployed: \d+", f"deployed: {counts['deployed']}", text, count=1, flags=re.MULTILINE)
    text = re.sub(r"^failed: \d+", f"failed: {counts['failed']}", text, count=1, flags=re.MULTILINE)
    text = re.sub(
        r'^last_updated:.*$',
        f'last_updated: "{date.today().isoformat()}"',
        text,
        flags=re.M,
    )
    metric_updates = {
        r"\*\*Pending \(no \.alter\.sql\)\*\*": counts["pending"],
        r"\*\*Generated \(awaiting UC deploy\)\*\*": counts["generated"],
        r"\*\*Deployed \(UC\)\*\*": counts["deployed"],
        r"\*\*Stub-only \(no UC\)\*\*": counts["stub"],
        r"\*\*Failed\*\*": counts["failed"],
    }
    for pattern, value in metric_updates.items():
        text = re.sub(
            rf"(\|\s+{pattern}\s+\|)\s*[^|]+(\|)",
            rf"\1 {value} \2",
            text,
            count=1,
        )
    return text


def main() -> None:
    ap = argparse.ArgumentParser(description="Reset deploy statuses in _deploy-index.md")
    ap.add_argument("--schema", required=True, help="Schema folder name (e.g. DWH_dbo)")
    ap.add_argument(
        "--mode", required=True,
        choices=["pending-to-generated", "reset-deployed"],
        help="pending-to-generated: Pending→Generated | reset-deployed: Deployed/Failed→Generated",
    )
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    schema = args.schema
    path = WIKI_ROOT / schema / "_deploy-index.md"
    if not path.is_file():
        print(f"ERROR: {path} not found")
        raise SystemExit(1)

    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    out: list[str] = []
    converted = 0

    row_re = re.compile(
        rf"^(\|\s*\[{re.escape(schema)}\.[^\]]+\]\([^)]+\)\s*)(\|)(.+)(\|)\s*$",
    )

    for line in lines:
        m = row_re.match(line)
        if m:
            pre, sep, status_cell, tail = m.group(1), m.group(2), m.group(3), m.group(4)
            st = status_cell.strip()
            should_convert = False

            if args.mode == "pending-to-generated" and st == "Pending":
                should_convert = True
            elif args.mode == "reset-deployed" and (st.startswith("Deployed") or st.startswith("Failed")):
                should_convert = True

            if should_convert:
                out.append(f"{pre}{sep} Generated {tail}")
                converted += 1
                continue

        if args.mode == "reset-deployed":
            if line.startswith("last_deploy_batch: "):
                out.append("last_deploy_batch: 0")
                continue
            if "| **Last deploy batch**" in line:
                out.append(re.sub(r"(\|\s*\*\*Last deploy batch\*\*\s*\|\s*)[^|]+", r"\g<1>0 ", line))
                continue

        out.append(line)

    text2 = "\n".join(out)
    counts = recount(text2, schema)
    text2 = update_metrics(text2, counts)

    if args.dry_run:
        print(f"[dry-run] Would convert {converted} rows in {path}")
        print(f"  Counts: {counts}")
        return

    path.write_text(text2, encoding="utf-8")
    print(f"Wrote {path}; converted {converted} rows.")
    print(f"  Counts: {counts}")


if __name__ == "__main__":
    main()
