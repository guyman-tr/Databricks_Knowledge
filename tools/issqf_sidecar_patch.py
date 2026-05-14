"""IsSQF inventory + sidecar Tier 5 patcher.

Scans all wiki .md files for `IsSQF` references and classifies each into:
  A. Already corrected (the 3 DDR facts regenerated 2026-05-14)
  B. Has WRONG narrative in main wiki (e.g. "Sustainable & Quality-Focused" or "Small Quantity Fee") — needs fix in main .md AND Tier 5 sidecar
  C. Has only lineage / technical references — needs Tier 5 awareness note in .review-needed.md sidecar
  D. Skill / config files — skip (defer per prior user instruction)

For category B and C: appends a Tier 5 row to the corresponding .review-needed.md
under the "Tier 5 Re-Review Needed" table (creates sidecar if missing).

For Function_Instrument_Snapshot_Enriched (the CANONICAL source for IsSQF),
patches the wiki body to add the SpotQuotedFuture business narrative.

USAGE:
  python tools/issqf_sidecar_patch.py --scan        # inventory only
  python tools/issqf_sidecar_patch.py --apply       # apply patches
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

# The 3 DDR facts that were just regenerated with Tier 5 IsSQF text — skip.
ALREADY_FIXED = {
    "BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md",
    "BI_DB_DDR_Fact_Revenue_Generating_Actions.md",
    "BI_DB_DDR_Fact_PnL.md",
}

# Wrong-narrative patterns (case-insensitive)
WRONG_PATTERNS = [
    r"Sustainable\s*&?\s*Quality.?Focused",
    r"Sustainable\s*and\s*Quality.?Focused",
    r"Small\s*Quantity\s*Fee",
    r"SQF\s*\(\s*Small\s*Quantity",
]
WRONG_RE = re.compile("|".join(WRONG_PATTERNS), re.IGNORECASE)

# The canonical Tier 5 narrative
TIER5_NARRATIVE = (
    "**`IsSQF` (SpotQuotedFuture flag)** — 1 = instrument is a SpotQuotedFuture "
    "(smaller-contract variant of eToro RealFutures, traded on the CME / Chicago "
    "Mercantile Exchange). 0 = not an SQF instrument. Source: "
    "`Function_Instrument_Snapshot_Enriched(@dateInt)` via membership in "
    "`Trade.InstrumentGroups` with `GroupID = 59`. (Tier 5 — user expert "
    "correction 2026-05-14; previously mis-described as \"Sustainable & "
    "Quality-Focused\" or \"Small Quantity Fee\")"
)

# Sidecar Tier 5 table row
TIER5_ROW_TEMPLATE = (
    "| IsSQF | SpotQuotedFuture flag — smaller-contract RealFutures on CME; "
    "`Trade.InstrumentGroups.GroupID = 59` via "
    "`Function_Instrument_Snapshot_Enriched`. | {old_tier} — \"{old_text}\" | "
    "Tier 5 (user expert 2026-05-14) | Replaced fabricated business narrative "
    "with grounded product semantic (SpotQuotedFuture, CME). |"
)

TIER5_TABLE_HEADER = (
    "| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | "
    "New Tier 1-3 | Change Summary |\n"
    "|--------|-------------------|----------------------------|"
    "--------------|----------------|"
)


def find_issqf_files() -> list[Path]:
    """Find every .md file under the Wiki tree that mentions IsSQF
    (excluding .review-needed.md and .lineage.md sidecars)."""
    files = []
    for p in WIKI.rglob("*.md"):
        if p.name.endswith(".review-needed.md"):
            continue
        if p.name.endswith(".lineage.md"):
            continue
        if p.name.endswith(".alter.sql"):
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        if "IsSQF" in text:
            files.append(p)
    return sorted(files)


def classify(p: Path) -> dict:
    """Classify an IsSQF-bearing file."""
    text = p.read_text(encoding="utf-8", errors="replace")
    wrong_match = WRONG_RE.search(text)
    # If the file is already in our ALREADY_FIXED list, skip.
    is_already_fixed = p.name in ALREADY_FIXED

    # Extract any IsSQF lines for context
    lines = text.splitlines()
    issqf_lines = [(i + 1, ln) for i, ln in enumerate(lines) if "IsSQF" in ln]

    sidecar = p.parent / (p.stem + ".review-needed.md")

    if is_already_fixed:
        cat = "A"
    elif wrong_match:
        cat = "B"
    else:
        cat = "C"

    return {
        "path": p,
        "sidecar": sidecar,
        "category": cat,
        "wrong_match": wrong_match.group(0) if wrong_match else None,
        "issqf_lines": issqf_lines,
    }


def append_tier5_to_sidecar(sidecar: Path, old_tier: str, old_text: str) -> bool:
    """Append a Tier 5 row to the sidecar's Tier 5 table. If the sidecar doesn't
    have a Tier 5 table yet, append the whole table. Returns True if changed."""
    if sidecar.exists():
        text = sidecar.read_text(encoding="utf-8", errors="replace")
    else:
        # Create minimal sidecar
        text = (
            f"# {sidecar.stem.replace('.review-needed', '')} — Review Needed\n\n"
            f"> Tier 5 expert corrections accumulated by tooling.\n\n"
        )

    # Check if a Tier 5 entry for IsSQF already exists
    if re.search(r"\|\s*IsSQF\s*\|.*SpotQuotedFuture", text, re.IGNORECASE):
        return False  # already patched

    row = TIER5_ROW_TEMPLATE.format(old_tier=old_tier, old_text=old_text)

    # Find existing Tier 5 table header
    t5_header_idx = text.find("## Tier 5 Re-Review Needed")
    if t5_header_idx < 0:
        # No Tier 5 section — append a fresh one
        addition = (
            "\n\n## Tier 5 Re-Review Needed\n\n"
            + TIER5_TABLE_HEADER + "\n"
            + row + "\n"
        )
        new_text = text.rstrip() + addition
    else:
        # Find the end of the existing Tier 5 table (last "|...|" line under it)
        section = text[t5_header_idx:]
        # Find line containing TIER5 table; insert row before any blank line
        lines = section.splitlines()
        insert_at = None
        in_table = False
        for i, line in enumerate(lines):
            if line.startswith("|") and "Column" in line and "Correction" in line:
                in_table = True
                continue
            if in_table:
                # Look for placeholder rows like "| _(none)_ |"
                if "_(none)_" in line or line.strip() == "":
                    insert_at = i
                    break
        if insert_at is None:
            # Append at end of section
            new_section = section.rstrip() + "\n" + row + "\n"
        else:
            # Replace the placeholder line with our row
            if "_(none)_" in lines[insert_at]:
                lines[insert_at] = row
            else:
                lines.insert(insert_at, row)
            new_section = "\n".join(lines) + "\n"
        new_text = text[:t5_header_idx] + new_section

    sidecar.write_text(new_text, encoding="utf-8")
    return True


def patch_canonical_function_wiki() -> bool:
    """Update Function_Instrument_Snapshot_Enriched.md to add SpotQuotedFuture
    business narrative to the IsSQF Element row (currently only technical
    derivation, no narrative)."""
    p = WIKI / "BI_DB_dbo" / "Functions" / "Function_Instrument_Snapshot_Enriched.md"
    if not p.exists():
        return False
    text = p.read_text(encoding="utf-8", errors="replace")

    # Look for the IsSQF row in the Elements table
    # Current: | 7 | IsSQF | DWH_staging.etoro_Trade_InstrumentGroups | `CASE ...` | T2 |
    old_row_re = re.compile(
        r"^\| \d+ \| IsSQF \| .*?WHERE.*?GroupID\s*=\s*59.*?\| T\d \|$",
        re.MULTILINE,
    )
    m = old_row_re.search(text)
    if not m:
        return False
    if "SpotQuotedFuture" in text:
        return False  # already patched

    # Add a business-meaning narrative above the lineage row using a Notes
    # section, or replace the row with a richer description.
    # Simplest: insert a fenced callout above the Elements heading.
    callout = (
        "\n> **IsSQF business semantic (Tier 5 user expert 2026-05-14):** "
        "`IsSQF = 1` flags instruments that are **SpotQuotedFutures** — "
        "smaller-contract-size variants of eToro RealFutures, traded on the "
        "**CME (Chicago Mercantile Exchange)**. The technical predicate "
        "(`Trade.InstrumentGroups.GroupID = 59`) is correct; the business "
        "meaning is the product classification, NOT \"Sustainable & "
        "Quality-Focused\" (legacy fabricated narrative across DDR wikis "
        "until 2026-05-14) and NOT \"Small Quantity Fee pricing model\" "
        "(another fabricated narrative seen in Client_Balance_* wikis).\n"
    )
    # Insert callout before the Elements table heading or after Section 1
    insert_pat = re.compile(
        r"(^## (?:4\. )?Elements|^## Elements|^## Columns)",
        re.MULTILINE,
    )
    m_ins = insert_pat.search(text)
    if not m_ins:
        # Append to end
        new_text = text.rstrip() + callout
    else:
        new_text = text[:m_ins.start()] + callout + "\n" + text[m_ins.start():]

    p.write_text(new_text, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scan", action="store_true",
                        help="Inventory only (no writes)")
    parser.add_argument("--apply", action="store_true",
                        help="Apply patches to sidecars + canonical wiki")
    args = parser.parse_args()

    if not args.scan and not args.apply:
        parser.error("Must specify --scan or --apply")

    files = find_issqf_files()
    by_cat: dict[str, list[dict]] = {"A": [], "B": [], "C": [], "D": []}

    for p in files:
        # Skip the Tableau-derived markdowns under knowledge/tableau (not wiki)
        info = classify(p)
        by_cat[info["category"]].append(info)

    print(f"\n=== IsSQF inventory ({len(files)} files) ===\n")
    print(f"  A (already fixed, skip): {len(by_cat['A'])}")
    print(f"  B (WRONG narrative in main wiki — needs main+sidecar fix): "
          f"{len(by_cat['B'])}")
    print(f"  C (lineage/technical only — sidecar Tier 5 awareness): "
          f"{len(by_cat['C'])}")

    print("\n=== Category B (wrong narrative) ===")
    for info in by_cat["B"]:
        rel = info["path"].relative_to(REPO)
        print(f"  {rel}")
        print(f"    matched: {info['wrong_match']!r}")

    print("\n=== Category C (technical only — sidecar Tier 5 only) ===")
    for info in by_cat["C"]:
        rel = info["path"].relative_to(REPO)
        print(f"  {rel}")

    if args.scan:
        return 0

    # APPLY
    print("\n=== Applying patches ===")
    patched = 0
    for info in by_cat["B"] + by_cat["C"]:
        sidecar = info["sidecar"]
        cat = info["category"]
        if cat == "B":
            old_tier = "Tier 2"
            old_text = info["wrong_match"]
        else:
            old_tier = "Tier 2 (lineage only)"
            old_text = "Technical lineage row, no business narrative"
        changed = append_tier5_to_sidecar(sidecar, old_tier, old_text)
        if changed:
            print(f"  PATCHED {sidecar.relative_to(REPO)}")
            patched += 1
        else:
            print(f"  SKIP    {sidecar.relative_to(REPO)} (already has IsSQF Tier 5 row)")

    print()
    if patch_canonical_function_wiki():
        print("  CANONICAL: Function_Instrument_Snapshot_Enriched.md "
              "(added SpotQuotedFuture business callout)")
        patched += 1
    else:
        print("  CANONICAL: Function_Instrument_Snapshot_Enriched.md unchanged "
              "(already patched or no IsSQF row found)")

    print(f"\nTotal patches applied: {patched}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
