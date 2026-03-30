"""
Normalize text embedded in Unity Catalog SQL string literals (COMMENT, TBLPROPERTIES).

Fixes common mojibake when UTF-8 punctuation was mis-decoded as Windows-1255 (Hebrew),
and maps Unicode punctuation to ASCII so tooling on Windows cannot re-corrupt files.

Wiki markdown may keep typographic dashes; all generators MUST pass descriptions
through sanitize_uc_sql_comment_text (or escape_sql_comment_value) before writing SQL.
"""

from __future__ import annotations

import re

# UTF-8 bytes for U+2014 / U+2194 / U+2192 / U+2264 misread as Windows-1255:
#   E2 80 94 -> Gimel (E2) + Euro (80) + U+201D
#   E2 86 94 -> Gimel + dagger (86) + U+201D  (left-right arrow)
#   E2 86 92 -> Gimel + dagger + U+2019  (right arrow)
#   E2 89 A4 -> Gimel + per mille + shekel (<=)
# Double-mangled section sign in "See §2.4":
#   U+05B2 (Hebrew) + U+00A7 (section)
# U+2212 MINUS SIGN: E2 88 92 -> Gimel + modifier circumflex + U+2019 (CP1255-style)
# U+2260 NOT EQUAL TO: E2 89 A0 -> Gimel + per mille + NBSP (vs U+2264 which ends with shekel)

_MOJIBAKE_TUPLES: tuple[tuple[str, str], ...] = (
    ("\u05d2\u20ac\u201d", " - "),  # em dash (tier tag delimiter)
    ("\u05d2\u2020\u201d", " <-> "),  # U+2194
    ("\u05d2\u2020\u2019", " -> "),  # U+2192
    ("\u05d2\u2030\u20aa", " <= "),  # U+2264
    ("\u05d2\u2030\u00a0", " != "),  # U+2260
    ("\u05d2\u02c6\u2019", " - "),  # U+2212 minus sign (arithmetic "minus")
    ("\u05b2\u00a7", "section "),  # § after "See "
)

_UNICODE_TO_ASCII: tuple[tuple[str, str], ...] = (
    ("\u2014", " - "),  # em dash
    ("\u2013", " - "),  # en dash
    ("\u2212", " - "),  # minus sign
    ("\u2194", " <-> "),
    ("\u2192", " -> "),
    ("\u2260", " != "),
    ("\u2264", " <= "),
    ("\u2265", " >= "),
    ("\u00a7", "section "),  # section sign
)


def sanitize_uc_sql_comment_text(text: str) -> str:
    if not text:
        return text
    for bad, good in _MOJIBAKE_TUPLES:
        text = text.replace(bad, good)
    for u, asc in _UNICODE_TO_ASCII:
        text = text.replace(u, asc)
    # Normalize tier tag spacing after mojibake repair: "(Tier 2  -  SP" -> "(Tier 2 - SP"
    text = re.sub(r"\(Tier\s+(\d+)\s+-\s+", r"(Tier \1 - ", text)
    # Collapse double-spacing around ASCII operators introduced by " - " / " -> " repairs
    for _ in range(40):
        n = (
            text.replace("  -  ", " - ")
            .replace("  ->  ", " -> ")
            .replace("  <=  ", " <= ")
            .replace("  <->  ", " <-> ")
            .replace("  !=  ", " != ")
        )
        if n == text:
            break
        text = n
    return text


def escape_sql_comment_value(text: str) -> str:
    """sanitize + SQL single-quote doubling for string literals."""
    return sanitize_uc_sql_comment_text(text).replace("'", "''")
