"""One-off: reset DWH_dbo _deploy-index.md for full redeploy (Deployed/Failed -> Generated)."""
from __future__ import annotations

import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "knowledge/synapse/Wiki/DWH_dbo/_deploy-index.md"


def _count_generated_rows(md: str) -> int:
    n = 0
    for line in md.splitlines():
        if "[DWH_dbo." not in line or not line.strip().startswith("|"):
            continue
        parts = line.split("|")
        if len(parts) >= 4 and parts[2].strip() == "Generated":
            n += 1
    return n


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    lines = text.splitlines()
    out: list[str] = []
    converted = 0
    for line in lines:
        if line.startswith("deployed: "):
            out.append("deployed: 0")
            continue
        if line.startswith("failed: "):
            out.append("failed: 0")
            continue
        if line.startswith("last_deploy_batch: "):
            out.append("last_deploy_batch: 0")
            continue
        if re.match(r"^generated: \d+$", line):
            out.append("__GENERATED_PLACEHOLDER__")
            continue
        if "| **Deployed (UC)**" in line:
            out.append(re.sub(r"(\|\s*\*\*Deployed \(UC\)\*\*\s*\|\s*)\d+", r"\g<1>0", line))
            continue
        if "| **Generated (awaiting UC deploy)**" in line:
            out.append(re.sub(r"(\|\s*\*\*Generated \(awaiting UC deploy\)\*\*\s*\|\s*)\d+", r"\g<1>0", line))
            continue
        if "| **Failed**" in line and "**Failed**" in line:
            out.append(re.sub(r"(\|\s*\*\*Failed\*\*\s*\|\s*)\d+", r"\g<1>0", line))
            continue
        if "| **Last deploy batch**" in line:
            out.append(re.sub(r"(\|\s*\*\*Last deploy batch\*\*\s*\|\s*)\d+", r"\g<1>0", line))
            continue

        m = re.match(
            r"^(\|\s*\[DWH_dbo\.[^\]]+\]\([^)]+\)\s*)(\|)(.+)(\|)\s*$",
            line,
        )
        if m:
            pre, sep, status_cell, tail = m.group(1), m.group(2), m.group(3), m.group(4)
            st = status_cell.strip()
            if st.startswith("Pending"):
                out.append(line)
            elif st.startswith("Stub"):
                out.append(line)
            elif st.startswith("Deployed") or st.startswith("Failed (deploy"):
                out.append(
                    f"{pre}{sep} Generated                                                                                                                                    {tail}"
                )
                converted += 1
            else:
                out.append(line)
        else:
            out.append(line)

    text2 = "\n".join(out)
    gen_total = _count_generated_rows(text2)
    text2 = text2.replace("__GENERATED_PLACEHOLDER__", f"generated: {gen_total}")
    text2 = re.sub(
        r'^last_updated:.*$',
        f'last_updated: "{date.today().isoformat()}"',
        text2,
        flags=re.M,
    )
    text2 = re.sub(
        r"(\|\s*\*\*Generated \(awaiting UC deploy\)\*\*\s*\|\s*)\d+",
        rf"\g<1>{gen_total}",
        text2,
    )
    PATH.write_text(text2, encoding="utf-8")
    print(f"Wrote {PATH}; Generated rows: {gen_total} (converted from Deployed/Failed: {converted})")


if __name__ == "__main__":
    main()
