"""
Classify a §4 row's semantic cell as one of:
    TRIVIAL              - provenance-only; carries no semantic content
    HAS_TRANSFORMATION   - contains math / CASE / COALESCE / aggregation
    HAS_SEMANTIC         - non-trivial prose, no math; describes the field

The TRIVIAL pattern catalog is the source of truth — defined in the spec at
`.cursor/rules/uc-pipeline-doc/description-quality.mdc`. Any change here must
also update the spec.
"""
from __future__ import annotations

import re
from enum import Enum


class Verdict(str, Enum):
    TRIVIAL = "TRIVIAL"
    HAS_TRANSFORMATION = "HAS_TRANSFORMATION"
    HAS_SEMANTIC = "HAS_SEMANTIC"


# --- TRIVIAL pattern catalog (mirrors description-quality.mdc) ---
_TRIVIAL_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"^\s*Direct\s*$", re.IGNORECASE),
    re.compile(r"^\s*Direct\s*\(\s*alias[^)]*\)\s*$", re.IGNORECASE),
    re.compile(r"^\s*Direct\s*\(\s*legacy[^)]*\)\s*$", re.IGNORECASE),
    re.compile(r"^\s*Direct\s+from\s+[\w\.\[\]\"`]+\s*$", re.IGNORECASE),
    re.compile(r"^\s*Same\s+as\s+upstream\s*$", re.IGNORECASE),
    re.compile(r"^\s*Same\s+lineage\s+as\s+[\w\.\[\]\"`]+\s*$", re.IGNORECASE),
    re.compile(r"^\s*Passthrough\s*$", re.IGNORECASE),
    re.compile(r"^\s*$"),
    # "Tier 2 — via Foo" alone, no body, also trivial
    re.compile(r"^\s*\(Tier\s*\d[^\)]*\)\s*$", re.IGNORECASE),
]


# --- Transformation signal regexes ---
# Any one of these in the cell text marks it as HAS_TRANSFORMATION.
# Order matters only for explainability (we record the FIRST hit). The tests
# in test_classify.py lock the expected verdict for known cells.
_TRANSFORM_SIGNALS: list[tuple[str, re.Pattern[str]]] = [
    ("case_when", re.compile(r"\bCASE\s+WHEN\b", re.IGNORECASE)),
    ("coalesce", re.compile(r"\b(COALESCE|ISNULL|NULLIF|IIF)\s*\(", re.IGNORECASE)),
    ("agg", re.compile(r"\b(SUM|AVG|MIN|MAX|COUNT|STDEV|VAR)\s*\(", re.IGNORECASE)),
    ("cast", re.compile(r"\b(CAST|CONVERT|TRY_CAST|TRY_CONVERT)\s*\(", re.IGNORECASE)),
    # Arithmetic operator with REQUIRED whitespace on both sides. This rejects
    # hyphens in prose ("Human-readable", "real-time") while still matching the
    # formulas we care about (e.g. `Liabilities + ActualNWA`,
    # `TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount`).
    (
        "arithmetic",
        re.compile(r"\b\w+\s+[+\-*/]\s+\w+\b"),
    ),
    ("formula_eq", re.compile(r"\bFormula\s*:\s*\S", re.IGNORECASE)),
    # "X = Y + Z" style explicit equation — requires both = and an operator
    # with whitespace on each side.
    ("equation", re.compile(r"\b\w+\s*=\s*\w+\s+[+\-*/]\s+\w+", re.IGNORECASE)),
]


def is_trivial(cell: str) -> bool:
    for pat in _TRIVIAL_PATTERNS:
        if pat.match(cell):
            return True
    return False


def has_transformation(cell: str) -> tuple[bool, str | None]:
    for name, pat in _TRANSFORM_SIGNALS:
        if pat.search(cell):
            return True, name
    return False, None


# Approximate "non-trivial prose" detection. We use this only as a positive
# signal — if it's not trivial and not transformation, the verdict is HAS_SEMANTIC
# regardless. This helper is here for diagnostics / explainability.
_PROSE_WORD_COUNT_THRESHOLD = 4


def looks_like_prose(cell: str) -> bool:
    # Strip "(Tier N — ...)" tag at the end for length measurement
    stripped = re.sub(r"\(\s*Tier[^)]*\)\s*$", "", cell, flags=re.IGNORECASE).strip()
    words = [w for w in re.split(r"\s+", stripped) if w]
    return len(words) >= _PROSE_WORD_COUNT_THRESHOLD


def classify(cell: str) -> tuple[Verdict, str | None]:
    """Return (verdict, signal_name_if_applicable)."""
    if is_trivial(cell):
        return Verdict.TRIVIAL, None
    hit, signal = has_transformation(cell)
    if hit:
        return Verdict.HAS_TRANSFORMATION, signal
    # Otherwise treat as semantic prose. We do not gatekeep prose quality here;
    # the visible failure for "polished but empty" prose is left to human review.
    return Verdict.HAS_SEMANTIC, "prose"
