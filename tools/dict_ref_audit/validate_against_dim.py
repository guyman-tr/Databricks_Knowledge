"""Cross-check candidate enum claims against the canonical Dim_X wiki content.

For each candidate row (one per (wiki_md, column_name, line_no)):
  1. Extract canonical (id, label) pairs from the target Dim_X.md.
  2. Compare the claimed enum entries to canonical.
  3. Classify: clean | partial | mismatched_labels | delusional | unverifiable | no_target

Canonical extraction strategy (in order):
  a. Look for "value-mapping" tables under sections like "2.3 Lookup Table",
     "Values", "Codepoint", "Reference Data", or any table whose header contains
     "ID" and "Name"/"Description"/"Meaning"/"Label".
  b. Fall back to enum entries embedded in the Dim's ID-column Elements
     description.
  c. Fall back to enum entries anywhere in the Dim .md.

Caches extracted canonicals to `knowledge/_dict_ref_live_dim_cache.json`.
This script is deliberately offline (no DB calls). A future enhancement can
swap the wiki-derived source for a live Synapse MCP pull, keyed on the same
cache file.
"""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

sys.path.insert(0, str(REPO / "tools"))
from merge_wiki_column_comments_into_alter import (  # type: ignore
    _ELEMENTS_HEADER_RE,
    _NEXT_TOP_SECTION_RE,
)

# Same enum regex as the scanner.
ENUM_ENTRY_RE = re.compile(
    r"(?<![A-Za-z0-9_])(?P<n>-?\d+)\s*=\s*"
    r"(?P<label>[A-Za-z\[][A-Za-z0-9 &/+'_\-\(\)\]]{0,40}?)"
    r"(?=\s*(?:[,;\|\)]|\.\s|\.$|$|\bor\b|\band\b|\belse\b))",
)

def _label_norm(s: str) -> str:
    """Normalise a label for fuzzy comparison."""
    return re.sub(r"[\s\W_]+", "", s.lower())


def _labels_similar(a: str, b: str) -> bool:
    """Return True if labels match modulo whitespace/case/punctuation."""
    na, nb = _label_norm(a), _label_norm(b)
    if not na or not nb:
        return False
    return na == nb or na.startswith(nb) or nb.startswith(na)


def extract_canonical_from_md(md_path: Path) -> dict[int, str]:
    """Best-effort extraction of {id: label} from a Dim_X.md.

    Strategy: every `N=Label` pattern found anywhere in the markdown becomes
    a canonical entry (first occurrence wins). This deliberately ignores
    markdown table cells (`| 1 | ID | int | ...`) because those are the
    Dim's own column-catalog positions, not value-mapping data.
    """
    try:
        text = md_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return {}

    canonical: dict[int, str] = {}
    for m in ENUM_ENTRY_RE.finditer(text):
        try:
            n = int(m.group("n"))
        except ValueError:
            continue
        if n in canonical:
            continue
        label = m.group("label").strip().strip(",.")
        if not label:
            continue
        canonical[n] = label
    return canonical


def classify(claimed_pairs: list[tuple[int, str]],
             canonical: dict[int, str]) -> tuple[str, dict]:
    """Compare claimed -> canonical. Return (status, details)."""
    if not canonical:
        return "unverifiable", {
            "delusional_ids": [],
            "mismatched_labels": [],
            "missing_ids": [],
        }
    delusional = []
    mismatched = []
    claimed_ids = set()
    for n, label in claimed_pairs:
        claimed_ids.add(n)
        if n not in canonical:
            delusional.append(n)
        else:
            if not _labels_similar(label, canonical[n]):
                mismatched.append({"id": n, "claimed": label,
                                    "canonical": canonical[n]})
    missing = sorted(set(canonical) - claimed_ids)
    if delusional:
        status = "delusional"
    elif mismatched:
        status = "mismatched_labels"
    elif missing:
        status = "partial"
    else:
        status = "clean"
    return status, {
        "delusional_ids": delusional,
        "mismatched_labels": mismatched,
        "missing_ids": missing,
    }


def parse_claimed_pairs(claimed_pairs_str: str) -> list[tuple[int, str]]:
    """Reverse the scanner's serialised `N=Label; N=Label; ...` form."""
    out = []
    for token in claimed_pairs_str.split(";"):
        token = token.strip()
        if not token:
            continue
        m = re.match(r"^(-?\d+)\s*=\s*(.*)$", token)
        if not m:
            continue
        try:
            out.append((int(m.group(1)), m.group(2).strip()))
        except ValueError:
            continue
    return out


def main() -> int:
    src = REPO / "knowledge" / "_dict_ref_resolved.csv"
    out = REPO / "knowledge" / "_dict_ref_validated.csv"
    cache_path = REPO / "knowledge" / "_dict_ref_live_dim_cache.json"
    rows_in = list(csv.DictReader(src.open(encoding="utf-8")))

    # Build the canonical cache once per unique target_dim_md
    cache: dict[str, dict] = {}
    unique_mds = sorted(set(r["target_dim_md"] for r in rows_in if r["target_dim_md"]))
    print(f"Extracting canonical from {len(unique_mds)} Dim_X wikis...")
    for md_rel in unique_mds:
        md_path = REPO / md_rel
        canonical = extract_canonical_from_md(md_path)
        cache[md_rel] = {
            "source": "wiki",
            "n_entries": len(canonical),
            "entries": {str(k): v for k, v in sorted(canonical.items())},
        }

    cache_path.write_text(json.dumps(cache, indent=2, ensure_ascii=False),
                          encoding="utf-8")
    print(f"Wrote canonical cache: {cache_path.relative_to(REPO).as_posix()}")

    rows_out = []
    status_counts: dict[str, int] = {}
    for r in rows_in:
        target_md = r["target_dim_md"]
        target_dim = r["target_dim"]
        claimed = parse_claimed_pairs(r["claimed_pairs"])
        if not target_dim:
            status = "no_target"
            details = {"delusional_ids": [], "mismatched_labels": [], "missing_ids": []}
        elif target_md and target_md in cache:
            canonical_str_keys = cache[target_md]["entries"]
            canonical = {int(k): v for k, v in canonical_str_keys.items()}
            status, details = classify(claimed, canonical)
        else:
            # Dictionary.X with no wiki - cannot validate offline
            status = "unverifiable"
            details = {"delusional_ids": [], "mismatched_labels": [], "missing_ids": []}
        status_counts[status] = status_counts.get(status, 0) + 1
        rows_out.append({
            **r,
            "validation_status": status,
            "delusional_ids": json.dumps(details["delusional_ids"]),
            "mismatched_labels": json.dumps(details["mismatched_labels"], ensure_ascii=False),
            "missing_ids": json.dumps(details["missing_ids"]),
        })

    fnames = list(rows_in[0].keys()) + ["validation_status", "delusional_ids",
                                          "mismatched_labels", "missing_ids"]
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fnames)
        w.writeheader()
        for r in rows_out:
            w.writerow(r)

    print(f"\nWrote {out.relative_to(REPO).as_posix()}: {len(rows_out)} rows")
    print(f"\nValidation status breakdown:")
    for status, n in sorted(status_counts.items(), key=lambda kv: -kv[1]):
        print(f"  {n:>4}  {status}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
