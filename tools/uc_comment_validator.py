"""Shared validator: reject ALTER COLUMN COMMENT values that are obviously
wrong — tier tokens or wiki Elements header labels — so the historic drift
(BI_DB_KYC_Panel, eMoneyClientBalance, 2026-05-03) cannot recur.

Background
----------
An older version of `parse_wiki_column_catalog` picked the wrong cell in
wiki Elements tables when the Tier column was placed before the Description
column (KYC_Panel shape) or when the section had no Description column at
all (eMoneyClientBalance §4.8 RepCur shape). The result was 150 column
comments deployed to Unity Catalog as literal `'T1'`/`'T2'`/`'T3'` strings
and 7 deploy errors from header-row pollution (`ALTER COLUMN \`Column\`
COMMENT 'Description'`).

The current parser is fixed, but this validator is the regression guard so
no future scaffold path can re-introduce the same drift unnoticed.

Use at TWO chokepoints:
  1. Generation time: scaffold_missing_uc_alter_files.py +
     merge_wiki_column_comments_into_alter.py call `assert_comment_safe()`
     for each comment before writing it.
  2. Deploy time: dwh_dbo_deploy_resume_batch.py (and other deploy
     scripts) call `validate_alter_sql()` on the alter file BEFORE
     executing any statement.
"""
from __future__ import annotations

import re
from typing import Iterable

TIER_TOKENS = frozenset({"T0", "T1", "T2", "T3", "T4"})

HEADER_TOKENS = frozenset({
    "description", "tier", "confidence", "column", "element", "type",
    "nullable", "null", "not null", "source", "rule", "notes",
    "code-backed", "code backed", "inferred", "verbatim",
    "sentinel", "category", "yes", "no",
    "etl_metadata", "etl-metadata", "etl metadata",
    "name-inferred", "name inferred",
    "unverified", "unknown",
})

_LONG_TIER_RE = re.compile(r"^\s*tier\s*[0-4]\.?\s*$", re.IGNORECASE)

_COMMENT_LINE_RE = re.compile(
    r"ALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN\s+([^\s]+)\s+COMMENT\s+'((?:[^']|'')*)'",
    re.IGNORECASE,
)

_FORBIDDEN_COLUMN_NAMES = frozenset({"column", "element"})


class BadCommentError(ValueError):
    """Raised when a column comment value is a known drift artifact
    (tier-only token or wiki section-header label)."""


def is_bad_comment(comment: str) -> tuple[bool, str]:
    """Return (is_bad, reason). Pure function — safe to call anywhere."""
    if comment is None:
        return False, ""
    c = comment.strip()
    if not c:
        return False, ""
    if c in TIER_TOKENS:
        return True, f"tier-only token '{c}' — wiki Tier cell was captured instead of Description"
    if _LONG_TIER_RE.match(c):
        return True, (
            f"long-form tier-only label '{c}' — wiki Tier cell was captured "
            "instead of Description (BI_DB_First5Actions / IFRS15 class of leak)"
        )
    if c.lower() in HEADER_TOKENS:
        return True, f"wiki-header label '{c}' — section-header row was parsed as a data row"
    return False, ""


def is_bad_column_name(col: str) -> tuple[bool, str]:
    c = (col or "").strip().strip("`").strip()
    if c.lower() in _FORBIDDEN_COLUMN_NAMES:
        return True, f"placeholder column name '{c}' — wiki section-header was parsed as a data row"
    return False, ""


def assert_comment_safe(column: str, comment: str, *, context: str = "") -> None:
    """Raise BadCommentError if the comment is a known drift artifact.
    Call from generation code (scaffold/merge) per (column, comment) pair."""
    bad_col, why_col = is_bad_column_name(column)
    if bad_col:
        raise BadCommentError(
            f"refusing comment for placeholder column {column!r}: {why_col}"
            + (f" [{context}]" if context else "")
        )
    bad, why = is_bad_comment(comment)
    if bad:
        raise BadCommentError(
            f"refusing comment {comment!r} on column {column!r}: {why}"
            + (f" [{context}]" if context else "")
        )


def validate_alter_sql(content: str, *, source: str = "") -> list[str]:
    """Scan an entire .alter.sql body. Return list of human-readable error
    strings (empty if clean). Call from deploy code BEFORE executing.

    Use:
        problems = validate_alter_sql(text, source=str(path))
        if problems:
            raise SystemExit("\\n".join(problems))
    """
    problems: list[str] = []
    for m in _COMMENT_LINE_RE.finditer(content):
        col = m.group(2)
        comment = m.group(3)
        try:
            assert_comment_safe(col, comment, context=source)
        except BadCommentError as e:
            problems.append(str(e))
    return problems


def filter_safe_pairs(
    pairs: Iterable[tuple[str, str]], *, source: str = "", verbose: bool = False
) -> list[tuple[str, str]]:
    """Return only (col, comment) pairs that pass the validator. Bad pairs
    are skipped (and printed if verbose). Generation code that wants to
    soft-skip rather than abort can use this instead of `assert_comment_safe`.
    """
    out: list[tuple[str, str]] = []
    for col, comment in pairs:
        try:
            assert_comment_safe(col, comment, context=source)
        except BadCommentError as e:
            if verbose:
                print(f"SKIP bad pair: {e}")
            continue
        out.append((col, comment))
    return out
