"""One-shot reshaper: convert BI_DB_KYC_Panel.md Elements table from the
historical 7-cell shape (with separate Confidence and Tier columns) to the
canonical 5-cell shape used everywhere else in the wiki (Dim_Country
template), with the tier marker embedded inline at the end of the
description.

7-cell input:
  | # | Column | Type | Nullable | Confidence | Tier | Description |
5-cell output:
  | # | Element | Type | Nullable | Description |

Each row's Description is rewritten as:
  "<original_description> (Tier <N> - <Confidence>)"

Also drops the now-redundant "## 7. Tier Legend" trailing section (replaced
by a one-line inline note above the Elements table). Idempotent: running
twice is a no-op.
"""
from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Tables" / "BI_DB_KYC_Panel.md"

OLD_HEADER = "| # | Column | Type | Nullable | Confidence | Tier | Description |"
OLD_SEP_RE = re.compile(r"^\|---\|--------\|------\|----------\|------------\|------\|-------------\|\s*$")
NEW_HEADER = "| # | Element | Type | Nullable | Description |"
NEW_SEP = "|---|---------|------|----------|-------------|"

# Mapping from short tier code to the canonical legend phrasing already in
# the wiki's "Tier Legend" trailing section.
TIER_LABEL = {
    "T1": "Tier 1 - Upstream wiki verbatim",
    "T2": "Tier 2 - SP/DDL code",
    "T3": "Tier 3 - Live data sampling",
    "T4": "Tier 4-Inferred [UNVERIFIED] - Naming heuristic",
}


def confidence_phrase(conf: str) -> str:
    c = conf.strip().upper()
    if c in ("CODE-BACKED", "CODE BACKED"):
        return "CODE-BACKED"
    if c == "INFERRED":
        return "INFERRED"
    if c == "VERBATIM":
        return "VERBATIM"
    return c or "UNKNOWN"


def reshape_row(line: str) -> tuple[bool, str]:
    """Reshape one row. Returns (changed, new_line)."""
    if not line.startswith("|"):
        return False, line
    cells = [c.strip() for c in line.split("|")][1:-1]
    # Need exactly 7 cells for the old shape: # | Column | Type | Nullable | Confidence | Tier | Description
    if len(cells) != 7:
        return False, line
    n, col, typ, nullable, conf, tier, desc = cells
    if not n.isdigit():
        return False, line
    tier_token = tier.upper()
    if tier_token not in TIER_LABEL:
        return False, line
    conf_norm = confidence_phrase(conf)
    tier_phrase = TIER_LABEL[tier_token]
    suffix = f" ({tier_phrase}; {conf_norm})"
    if desc.endswith(suffix):
        return False, line  # already reshaped, idempotent
    new_desc = f"{desc}{suffix}"
    new_line = f"| {n} | {col} | {typ} | {nullable} | {new_desc} |"
    return True, new_line


def main() -> None:
    text = WIKI.read_text(encoding="utf-8")
    if NEW_HEADER in text and OLD_HEADER not in text:
        print("Already reshaped (idempotent no-op). Nothing to do.")
        return

    lines = text.splitlines()
    out: list[str] = []
    n_rows_reshaped = 0
    in_elements_table = False

    for line in lines:
        if line.strip() == OLD_HEADER.strip():
            out.append(NEW_HEADER)
            in_elements_table = True
            continue
        if in_elements_table and OLD_SEP_RE.match(line):
            out.append(NEW_SEP)
            continue
        if in_elements_table and line.startswith("|"):
            changed, new = reshape_row(line)
            out.append(new)
            if changed:
                n_rows_reshaped += 1
            continue
        if in_elements_table and not line.startswith("|"):
            in_elements_table = False
        out.append(line)

    new_text = "\n".join(out)
    if text.endswith("\n"):
        new_text += "\n"

    # Drop the trailing "## 7. Tier Legend" sub-section (now embedded inline).
    # Conservatively: locate "## 7. Tier Legend" through next top-level "## "
    # or end-of-file, and remove that span. The "## 8. ..." footer (italic
    # *Documented...*) is preserved if present.
    legend_re = re.compile(
        r"\n+---\n+## 7\. Tier Legend\n(?:.*?\n)*?(?=---\n+\*Documented|\Z)",
        re.MULTILINE,
    )
    new_text2 = legend_re.sub("\n", new_text)
    if new_text2 != new_text:
        print("Removed legacy '## 7. Tier Legend' section (tier now inline in descriptions).")
        new_text = new_text2

    WIKI.write_text(new_text, encoding="utf-8")
    print(f"Reshaped {n_rows_reshaped} Element rows in {WIKI.relative_to(REPO).as_posix()}")


if __name__ == "__main__":
    main()
