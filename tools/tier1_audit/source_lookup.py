"""source_lookup.py — given a candidate source wiki and a column name claimed
by a downstream DWH wiki, return whatever the source actually says about
that column (description + tier classification + is-OLTP flag).

Column-name matching is fuzzy: DWH often renames `CID` to `RealCID`,
or pluralises with `s`, or splits on underscores. We try a small set of
normalisation rules; if none match we return a `not-found` result.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

from .parser import ColumnRow, parse_wiki_columns
from .resolver import Resolution, is_oltp_path


@dataclass
class SourceColumn:
    source_wiki: Path
    matched_column: str
    description: str               # tier-tag stripped
    raw_description: str           # original
    source_tier: str | None        # "1" / "2" / "3" / etc., or None if no tag
    source_confidence: str | None  # OLTP-style: VERIFIED / CODE-BACKED / etc.
    is_oltp_truth: bool            # True if the source wiki is under ProdSchemas
    match_method: str              # how the fuzzy match succeeded


@dataclass
class LookupResult:
    """Result of trying to find the column across all candidate wikis."""
    resolution: Resolution
    matches: list[SourceColumn] = field(default_factory=list)
    miss_notes: list[str] = field(default_factory=list)

    @property
    def best_match(self) -> SourceColumn | None:
        """Pick the strongest match — OLTP truth wins over Synapse mid-tier."""
        if not self.matches:
            return None
        oltp = [m for m in self.matches if m.is_oltp_truth]
        if oltp:
            return oltp[0]
        # Otherwise prefer Tier 1 over Tier 2+
        ranked = sorted(self.matches,
                        key=lambda m: (
                            int(m.source_tier) if (m.source_tier and m.source_tier.isdigit())
                            else 9
                        ))
        return ranked[0]


@lru_cache(maxsize=512)
def _wiki_columns(path: Path) -> tuple[ColumnRow, ...]:
    """Cache parsed rows per wiki path."""
    return tuple(parse_wiki_columns(path))


def _normalise(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


def _name_variants(name: str) -> list[str]:
    """Generate a small set of plausible variants for the claimed column."""
    out: list[str] = [name]
    nl = name.lower()
    # Strip common DWH "Real" / "DWH_" prefixes
    if nl.startswith("real"):
        out.append(name[4:])
    if nl.startswith("dwh_"):
        out.append(name[4:])
    # Strip trailing "ID"
    if nl.endswith("id") and len(name) > 2:
        out.append(name[:-2])
    # Singular/plural swap
    if nl.endswith("s"):
        out.append(name[:-1])
    else:
        out.append(name + "s")
    # Replace underscores
    if "_" in name:
        out.append(name.replace("_", ""))
    seen = set()
    deduped: list[str] = []
    for v in out:
        if v and v.lower() not in seen:
            seen.add(v.lower())
            deduped.append(v)
    return deduped


def _find_column(rows: tuple[ColumnRow, ...], claimed_name: str) -> tuple[ColumnRow | None, str]:
    """Return (row, match_method) or (None, '')."""
    by_norm: dict[str, ColumnRow] = {}
    by_lower: dict[str, ColumnRow] = {}
    for r in rows:
        by_lower[r.column_name.lower()] = r
        by_norm[_normalise(r.column_name)] = r
    # 1. exact (case-insensitive)
    if claimed_name.lower() in by_lower:
        return by_lower[claimed_name.lower()], "exact (case-insensitive)"
    # 2. normalised
    norm = _normalise(claimed_name)
    if norm in by_norm:
        return by_norm[norm], "normalised (alphanumeric only)"
    # 3. variant fan-out
    for v in _name_variants(claimed_name):
        if v.lower() in by_lower:
            return by_lower[v.lower()], f"variant {v!r}"
        vnorm = _normalise(v)
        if vnorm in by_norm:
            return by_norm[vnorm], f"variant-normalised {v!r}"
    return None, ""


def lookup_source_column(resolution: Resolution, claimed_column: str) -> LookupResult:
    """Walk every candidate path in `resolution`, find the matching column,
    return all matches plus miss notes."""
    result = LookupResult(resolution=resolution)
    if not resolution.candidate_paths:
        return result
    for path in resolution.candidate_paths:
        rows = _wiki_columns(path)
        row, method = _find_column(rows, claimed_column)
        if row is None:
            result.miss_notes.append(
                f"{path.name}: no column matching {claimed_column!r} (checked {len(rows)} rows)"
            )
            continue
        # Decode tier classification
        primary = row.primary_tier_tag
        result.matches.append(
            SourceColumn(
                source_wiki=path,
                matched_column=row.column_name,
                description=row.description,
                raw_description=row.raw_description,
                source_tier=primary.tier if primary else None,
                source_confidence=row.confidence,
                is_oltp_truth=is_oltp_path(path),
                match_method=method,
            )
        )
    return result
