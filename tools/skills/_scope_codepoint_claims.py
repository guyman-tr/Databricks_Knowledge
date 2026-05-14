"""Quick scope scan for codepoint-name claims across wiki .alter.sql files.
Not a real tool — just a one-shot survey to size the judge work."""
from __future__ import annotations
import re
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

# Anything that looks like a codepoint-to-label assertion inside a comment body.
# Examples it catches:
#   "1=Standard (94%); 4=Internal; 7=Diamond"
#   "26=ILQ, 30=Dealing"
#   "PlayerLevelID = 4 = Internal"
#   "(1) Standard, (2) Active"
#   "ID 4 means Internal"
ENUM_PATTERNS = [
    # N = Word
    re.compile(r"\b(\d{1,4})\s*=\s*([A-Z][\w./+&'\- ]{1,40})"),
    # (N) Word
    re.compile(r"\((\d{1,4})\)\s+([A-Z][\w./+&'\- ]{1,40})"),
]

# Match any column-COMMENT statement
COMMENT_STMT = re.compile(
    r"(ALTER (?:TABLE|VIEW)\s+[\w.]+\s+ALTER COLUMN\s+`?\w+`?\s+COMMENT\s+'((?:[^']|'')*)')"
    r"|"
    r"(COMMENT\s+ON\s+COLUMN\s+[\w.`]+\s+IS\s+'((?:[^']|'')*)')",
    re.IGNORECASE,
)

COL_RE = re.compile(
    r"ALTER COLUMN\s+`?(?P<col>\w+)`?\s+COMMENT|"
    r"COMMENT ON COLUMN\s+[\w.]+\.`?(?P<col2>\w+)`?\s+IS",
    re.IGNORECASE,
)


def main() -> None:
    files = sorted(WIKI.rglob("*.alter.sql"))
    print(f"Total .alter.sql files: {len(files)}")
    files_with_hits = 0
    total_stmts_with_claim = 0
    claims_by_column: Counter[str] = Counter()
    distinct_claims: Counter[tuple[str, str, str]] = Counter()
    claim_examples: dict[tuple[str, str, str], str] = {}
    files_by_schema: defaultdict[str, int] = defaultdict(int)
    stmts_by_schema: defaultdict[str, int] = defaultdict(int)

    for f in files:
        try:
            txt = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        schema = f.relative_to(WIKI).parts[0]
        file_has = False
        for m in COMMENT_STMT.finditer(txt):
            body = m.group(2) or m.group(4) or ""
            # Find column
            head = m.group(1) or m.group(3) or ""
            cm = COL_RE.search(head)
            col = (cm.group("col") or cm.group("col2")) if cm else "?"
            had_claim = False
            for pat in ENUM_PATTERNS:
                for em in pat.finditer(body):
                    digit, label = em.group(1), em.group(2).strip()
                    # Filter obvious noise: years (e.g. "2025"), percentages noise ("94" before "%"), version numbers
                    if label.lower() in {"year", "default"}:
                        continue
                    key = (col, digit, label.lower())
                    distinct_claims[key] += 1
                    claim_examples.setdefault(key, body[:200])
                    had_claim = True
                    claims_by_column[col] += 1
            if had_claim:
                file_has = True
                total_stmts_with_claim += 1
                stmts_by_schema[schema] += 1
        if file_has:
            files_with_hits += 1
            files_by_schema[schema] += 1

    print(f"Files with codepoint-claim COMMENT(s): {files_with_hits}")
    print(f"Total COMMENT statements containing a codepoint claim: {total_stmts_with_claim}")
    print(f"Distinct (column, codepoint, name) tuples: {len(distinct_claims)}")
    print()
    print("By schema (folder under Wiki/):")
    for s, n in sorted(files_by_schema.items(), key=lambda kv: -kv[1]):
        print(f"  {s:<20} files={n:<4} stmts={stmts_by_schema[s]}")
    print()
    print("Top 30 columns by # of codepoint claims:")
    for col, n in claims_by_column.most_common(30):
        print(f"  {col:<32} {n}")
    print()
    print("Top 30 distinct (col, codepoint, label) — most-repeated assertions:")
    for (col, dig, lbl), n in distinct_claims.most_common(30):
        print(f"  {n:<5} {col:<28} {dig:<5} {lbl}")


if __name__ == "__main__":
    main()
