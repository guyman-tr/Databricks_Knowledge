"""Find rows that should have been classified TRIVIAL but slipped through.

These are descriptions that name an internal CTE / branch / row only, with no
semantic or formula. Candidates for the trivial pattern catalog v2.
"""
from __future__ import annotations
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tools.desc_quality.classify import Verdict, classify  # noqa: E402
from tools.desc_quality.wiki_parse import parse_wiki  # noqa: E402


def clean_md(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


# Candidate NEW trivial patterns (provenance-only, no semantic)
CANDIDATES = {
    "DIRECT_FROM_CTE": re.compile(
        r"^Direct\s+from\s+[A-Z][A-Za-z_]*(?:\s+[A-Z][A-Za-z_]*){0,2}\s+CTE\s*$",
        re.IGNORECASE,
    ),
    "DIRECT_FROM_BRANCH": re.compile(
        r"^Direct\s+from\s+(?:union\s+)?(?:branch(?:es)?|row|subquery|select)\s*$",
        re.IGNORECASE,
    ),
    "DIRECT_FROM_TWO_WORDS": re.compile(
        r"^Direct\s+from\s+[A-Z]\w+\s+[A-Z]\w+\s*$",
    ),
    "FROM_CTE_BARE": re.compile(
        r"^From\s+[A-Z][A-Za-z_]+\s+CTE\s*$",
        re.IGNORECASE,
    ),
    "VIA_BARE": re.compile(
        r"^(?:Via|Through)\s+[A-Za-z_][\w\.]*\s*$",
        re.IGNORECASE,
    ),
    "PASSTHROUGH_BARE": re.compile(
        r"^Passthrough(?:\s+from\s+[A-Za-z_][\w\.]*)?\s*$",
        re.IGNORECASE,
    ),
    "INHERITED": re.compile(
        r"^Inherited(?:\s+from\s+[A-Za-z_][\w\.]*)?\s*$",
        re.IGNORECASE,
    ),
}


def main() -> int:
    wikis = sorted(ROOT.glob("knowledge/synapse/Wiki/**/*.md"))
    print(f"Scanning {len(wikis)} wikis for trivial-equivalent patterns...")

    counts: Counter[str] = Counter()
    by_wiki: dict[str, int] = defaultdict(int)
    examples: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    total_non_trivial = 0

    for wp in wikis:
        try:
            tbl = parse_wiki(wp)
        except Exception:
            continue
        if not tbl.rows or tbl.semantic_header_used is None:
            continue
        rel = str(wp.relative_to(ROOT)).replace("\\", "/")
        for row in tbl.rows:
            verdict, _ = classify(row.semantic_cell)
            if verdict == Verdict.TRIVIAL:
                continue
            total_non_trivial += 1
            txt = clean_md(row.semantic_cell)
            for tag, pat in CANDIDATES.items():
                if pat.match(txt):
                    counts[tag] += 1
                    by_wiki[rel] += 1
                    if len(examples[tag]) < 6:
                        examples[tag].append((rel.rsplit("/", 1)[-1], row.column, txt))
                    break  # one tag per row

    print()
    print(f"Total non-trivial rows: {total_non_trivial:,}")
    print()
    print("=== Pattern counts ===")
    for tag, cnt in counts.most_common():
        print(f"  {tag:25s}: {cnt:,}")
    grand = sum(counts.values())
    print(f"  {'TOTAL_NEW_TRIVIAL':25s}: {grand:,}  ({100.0*grand/max(total_non_trivial,1):.1f}% of non-trivial)")
    print()
    print("=== Top wikis by new-trivial count ===")
    for rel, n in sorted(by_wiki.items(), key=lambda x: -x[1])[:20]:
        print(f"  {n:4d}  {rel}")
    print()
    print("=== Samples per pattern ===")
    for tag, items in examples.items():
        print(f"\n[{tag}]  ({counts[tag]} total)")
        for wiki, col, txt in items:
            print(f"  {wiki}  ::  {col!r}  ->  {txt!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
