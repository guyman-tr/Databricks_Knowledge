"""Final audit: scan all wiki files for any 'CreditBureau' / 'credit bureau'
token that is NOT inside one of the documented protected anchors.

Should report ZERO lines after the sweep — every remaining occurrence must
be either (a) NOT CreditBureau disambiguation, (b) italicized *CreditBureau*
in a corrective callout, or (c) the quoted-fabrication narrative."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIKI = ROOT / "knowledge" / "synapse" / "Wiki"

PROTECTED_SUBSTRINGS = [
    "NOT CreditBureau",
    "NOT *CreditBureau*",
    "*CreditBureau*",
    '"CreditBureau"',
    "'CreditBureau'",
    "`CreditBureau`",
    '"CreditBureau credit report validation"',
    "'CreditBureau credit report validation'",
    "`CreditBureau credit report validation`",
    "CreditBureau credit report validation narrative",
    "fabricated CreditBureau",
    "fabrication: CreditBureau",
]

bad_lines = 0
for path in sorted(WIKI.rglob("*")):
    if not path.is_file() or path.suffix not in {".md", ".sql"}:
        continue
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    for i, line in enumerate(raw.splitlines(), 1):
        ll = line.lower()
        if "creditbureau" not in ll and "credit bureau" not in ll:
            continue
        scrubbed = line
        for anchor in PROTECTED_SUBSTRINGS:
            scrubbed = scrubbed.replace(anchor, "")
        if "creditbureau" in scrubbed.lower() or "credit bureau" in scrubbed.lower():
            bad_lines += 1
            print(f"  {path.relative_to(ROOT)}:{i}")
            print(f"    {line[:200]}")

print(f"\nUnprotected occurrences: {bad_lines}")
