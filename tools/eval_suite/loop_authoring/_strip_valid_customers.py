"""Strip 'valid customers' / 'yesterday (DATE)' phrasing from V1 case YAMLs.

Rationale:
  - 'valid customers' is supposed to be applied automatically by the
    valid-users-filter-contract skill (DEFAULT-ON). Asking for it tests the
    SQL writer; not asking tests whether the skill fires zero-shot.
  - 'yesterday' is ambiguous. Today is not the asof date; the explicit
    YYYY-MM-DD date is what we want.

Rewrites the natural_language_question block in-place; leaves all other
fields untouched.
"""
from __future__ import annotations

import re
from pathlib import Path

CASES_DIR = Path(__file__).resolve().parents[2] / "eval_suite" / "cases" / "ddr"

# Per-phrase substitutions, applied in order. Each is (pattern, replacement).
# All match case-insensitively and are minimally invasive — if a phrase isn't
# present, that case is left alone. The script is idempotent.
SUBS: list[tuple[str, str]] = [
    # "How many valid customers ... " → "How many customers ... "
    (r"\bHow many valid customers\b", "How many customers"),
    # "across all valid customers' positions/open positions" → "across all open positions"
    (r"\bacross all valid customers'\s*open positions\b", "across all open positions"),
    (r"\bacross all valid customers'\s*positions\b", "across all positions"),
    # "How many distinct valid customers" → "How many distinct customers"
    (r"\bHow many distinct valid customers\b", "How many distinct customers"),
    # "did valid customers make" → "were made"
    (r"\bdid valid customers make\b", "were made"),
    # Generic trailing phrasing: "for valid customers" / "across valid customers"
    (r"\s+for valid customers\b", ""),
    (r"\s+across valid customers\b", ""),
    # "valid customers" anywhere else (last resort cleanup)
    (r"\bvalid customers\b", "customers"),

    # "yesterday (DATE)" → "on DATE"   (parenthetical-form first)
    (r"\byesterday\s*\((\d{4}-\d{2}-\d{2})\)\?", r"on \1?"),
    (r"\byesterday\s*\((\d{4}-\d{2}-\d{2})\)\b", r"on \1"),
    # bare "yesterday" with date elsewhere → just drop "yesterday"
    (r"\byesterday\s+(?=\(?\d{4}-\d{2}-\d{2})", ""),
]


def rewrite_block(block: str) -> str:
    out = block
    for pat, repl in SUBS:
        out = re.sub(pat, repl, out, flags=re.IGNORECASE)
    # Collapse double spaces, leftover " ?" → "?", " ?" patterns introduced
    # by stripping prepositional phrases.
    out = re.sub(r"  +", " ", out)
    out = re.sub(r" \?", "?", out)
    out = re.sub(r" \.", ".", out)
    return out


def rewrite_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    # Match the YAML block-scalar literal `natural_language_question: |\n  ...`
    # up to the next non-indented line. Keep it conservative.
    pattern = re.compile(
        r"(natural_language_question:\s*\|\s*\n)((?:[ \t]+.*\n)+)",
        flags=re.MULTILINE,
    )
    m = pattern.search(text)
    if not m:
        return False
    header, block = m.group(1), m.group(2)
    new_block = rewrite_block(block)
    if new_block == block:
        return False
    new_text = text[:m.start()] + header + new_block + text[m.end():]
    path.write_text(new_text, encoding="utf-8")
    return True


def main() -> None:
    files = sorted(CASES_DIR.glob("*.yaml"))
    n_changed = 0
    for f in files:
        if rewrite_file(f):
            print(f"  rewrote: {f.name}")
            n_changed += 1
        else:
            print(f"  unchanged: {f.name}")
    print(f"\n{n_changed} of {len(files)} files rewritten.")


if __name__ == "__main__":
    main()
