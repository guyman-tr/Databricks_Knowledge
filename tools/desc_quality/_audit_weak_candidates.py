"""Scan the wiki corpus for WEAK description candidates.

Definition of weak (tentative — to be tightened with user input):
  - Passes the TRIVIAL pattern catalog (so the trivial pass left it alone)
  - But is still low-information: short, no formula, no FK target, no business term

Buckets reported:
  - LEN_LT_30           : description shorter than 30 chars
  - JUST_TYPE_WORDS     : only matches words like "integer", "date", "string", "timestamp", "boolean"
  - JUST_ID_OR_KEY      : "id column", "primary key", "fk column", "key field" with no further info
  - JUST_DATE_DESC      : "Date", "Date in YYYYMMDD", "Timestamp" with no other text
  - JUST_REFERENCES     : description is one fk target like "FK to dim_x.col_y" with no business meaning
  - PROVENANCE_ONLY     : sentence ends in "Source: X" or "via Y" with no leading sentence
  - LOW_SEMANTIC_DENSITY: total length / unique-word count is high (lots of filler)
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

# Strip markdown for analysis (does NOT mutate the wiki)
def clean_md(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()

# Patterns suggesting weakness
TYPE_WORDS = re.compile(
    r"^(integer|int|bigint|smallint|tinyint|date|datetime|datetime2|datetimeoffset|"
    r"time|timestamp|string|nvarchar|varchar|char|bit|boolean|bool|decimal|float|"
    r"real|numeric|money|uniqueidentifier|guid|binary|varbinary|n?text|xml)$",
    re.IGNORECASE,
)

ID_KEY_ONLY = re.compile(
    r"^(?:fk(?:\s+to)?|primary\s+key|pk|surrogate\s+key|business\s+key|natural\s+key|"
    r"id\s+column|key|reference|reference\s+to|references?|join\s+key|lookup\s+key)\b",
    re.IGNORECASE,
)

DATE_LIKE = re.compile(
    r"^(?:date(?:\s+(?:column|field|key|in|encoded|as|of))?|timestamp|datetime|"
    r"datekey|dateid|yyyymmdd)[\s.,]*$",
    re.IGNORECASE,
)

# Just a Schema.Table.Column or Table.Column reference, optionally with a leading word
JUST_FK = re.compile(
    r"^(?:fk(?:\s+to)?\s+)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*){1,2}\.?\s*$",
)

PROVENANCE_ONLY = re.compile(
    r"^(?:Source\s*:\s*|via\s+|from\s+|passthrough\s+(?:from|of)\s+|direct\s+from\s+)",
    re.IGNORECASE,
)


def assess(cell: str) -> list[str]:
    """Return list of weakness tags. Empty list => OK."""
    txt = clean_md(cell)
    if not txt:
        return ["EMPTY"]
    tags: list[str] = []
    if len(txt) < 30:
        tags.append("LEN_LT_30")
    if TYPE_WORDS.match(txt):
        tags.append("JUST_TYPE_WORDS")
    if ID_KEY_ONLY.match(txt) and len(txt) < 50:
        tags.append("JUST_ID_OR_KEY")
    if DATE_LIKE.match(txt):
        tags.append("JUST_DATE_DESC")
    if JUST_FK.match(txt):
        tags.append("JUST_REFERENCES")
    if PROVENANCE_ONLY.match(txt) and len(txt) < 80:
        tags.append("PROVENANCE_ONLY")
    return tags


def main() -> int:
    wikis = sorted(ROOT.glob("knowledge/synapse/Wiki/**/*.md"))
    print(f"Scanning {len(wikis)} wikis...")

    bucket_counts: Counter[str] = Counter()
    by_wiki_weak: dict[str, int] = defaultdict(int)
    by_wiki_total: dict[str, int] = defaultdict(int)
    examples: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    total_rows = 0
    weak_rows = 0
    trivial_rows = 0
    ok_rows = 0

    for wp in wikis:
        try:
            tbl = parse_wiki(wp)
        except Exception:
            continue
        if not tbl.rows or tbl.semantic_header_used is None:
            continue
        rel = str(wp.relative_to(ROOT)).replace("\\", "/")
        for row in tbl.rows:
            total_rows += 1
            verdict, _ = classify(row.semantic_cell)
            if verdict == Verdict.TRIVIAL:
                trivial_rows += 1
                continue
            tags = assess(row.semantic_cell)
            by_wiki_total[rel] += 1
            if tags:
                weak_rows += 1
                by_wiki_weak[rel] += 1
                for t in tags:
                    bucket_counts[t] += 1
                    if len(examples[t]) < 5:
                        examples[t].append((rel.rsplit("/", 1)[-1], row.column, row.semantic_cell[:160]))
            else:
                ok_rows += 1

    print()
    print(f"=== Population summary ===")
    print(f"  total §4 rows scanned:      {total_rows:,}")
    print(f"  TRIVIAL (already addressed): {trivial_rows:,}")
    print(f"  WEAK candidates:             {weak_rows:,}  ({100.0*weak_rows/max(total_rows-trivial_rows,1):.1f}% of non-trivial)")
    print(f"  OK (no weakness flags):      {ok_rows:,}")
    print()
    print("=== Bucket counts (a row can hit multiple tags) ===")
    for tag, cnt in bucket_counts.most_common():
        print(f"  {tag:25s}: {cnt:,}")
    print()
    print("=== Top wikis by weak-row count ===")
    for rel, n in sorted(by_wiki_weak.items(), key=lambda x: -x[1])[:20]:
        print(f"  {n:4d}  {rel}")
    print()
    print("=== Sample rows per bucket ===")
    for tag, items in examples.items():
        print(f"\n[{tag}]  (showing {len(items)} of {bucket_counts[tag]})")
        for wiki, col, cell in items:
            print(f"  {wiki}  ::  {col!r}  ->  {cell!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
