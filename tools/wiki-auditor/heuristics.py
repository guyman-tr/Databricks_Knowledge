"""Heuristic rules for the wiki post-run auditor.

A column is a CANDIDATE if any rule triggers. Rules are:

    TIER_GAP        - downstream Tier 2/3 vs upstream Tier 1 / 4-Confluence
    MECH_ONLY       - downstream description is purely SP mechanics, no business meaning
    CONFLUENCE_GAP  - upstream wiki cites Confluence; downstream does not
    LENGTH_GAP      - upstream description is materially longer AND adds business nouns

Rules are deliberately cheap (regex + word counts). Token-spending judgement
happens later, in the LLM merger stage.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional

from wiki_parser import TierInfo, description_without_tier_suffix


# --- Wordlists ---------------------------------------------------------------

# Mechanical verbs / phrases. Any column whose stripped description consists
# almost entirely of these tokens (plus column-name fragments) is "business-blind".
MECHANICAL_TOKENS = {
    "abs",
    "isnull",
    "coalesce",
    "cast",
    "convert",
    "sum",
    "min",
    "max",
    "count",
    "avg",
    "passthrough",
    "pass-through",
    "rename",
    "renamed",
    "computed",
    "getdate",
    "null",
    "literal",
    "literals",
    "set to",
    "at insert",
    "at load",
    "during load",
    "etl-computed",
    "etl",
    "load",
    "loaded",
    "insert",
    "update",
    "delete",
    "merge",
    "join",
    "left join",
    "inner join",
    "outer join",
    "lookup",
    "filter",
    "where",
    "group by",
    "row",
    "rows",
    "value",
    "values",
    "field",
    "column",
    "id",
    "key",
    "alias",
    "from",
    "via",
    "into",
    "intentionally",
    "currently",
    "today",
    "post-load",
    "post-update",
    "direction",
    "directions",
    "rules",
    "sign",
    "signed",
    "unsigned",
    "absolute",
    "negate",
    "negation",
}

# Tokens that almost always appear and should not count toward "non-mechanical".
STOPWORDS = {
    "the",
    "a",
    "an",
    "is",
    "are",
    "was",
    "were",
    "be",
    "been",
    "being",
    "of",
    "in",
    "on",
    "to",
    "for",
    "with",
    "by",
    "from",
    "as",
    "at",
    "and",
    "or",
    "not",
    "no",
    "yes",
    "this",
    "that",
    "these",
    "those",
    "it",
    "its",
    "their",
    "his",
    "her",
    "our",
    "we",
    "you",
    "i",
    "they",
    "them",
    "us",
    "me",
    "if",
    "then",
    "else",
    "but",
    "so",
    "than",
    "into",
    "via",
    "per",
    "each",
    "any",
    "all",
    "some",
    "one",
    "two",
    "first",
    "last",
    "only",
    "also",
    "still",
    "yet",
    "again",
    "more",
    "less",
    "most",
    "least",
    "very",
    "much",
    "many",
    "few",
}

# Curated business nouns common to eToro DWH semantics. Used as a baseline
# even if a column is not in the glossary file. Glossary terms are merged in
# at runtime by the orchestrator.
BUSINESS_NOUN_BASELINE = {
    "fee",
    "fees",
    "commission",
    "spread",
    "markup",
    "revenue",
    "pip",
    "pips",
    "balance",
    "equity",
    "exposure",
    "deposit",
    "withdrawal",
    "withdraw",
    "cashout",
    "transaction",
    "trade",
    "trader",
    "trading",
    "position",
    "positions",
    "instrument",
    "asset",
    "currency",
    "exchange",
    "rate",
    "fx",
    "customer",
    "client",
    "investor",
    "merchant",
    "depot",
    "card",
    "payment",
    "regulation",
    "regulator",
    "kyc",
    "aml",
    "compliance",
    "country",
    "label",
    "campaign",
    "affiliate",
    "marketing",
    "leverage",
    "margin",
    "liability",
    "credit",
    "debit",
    "cash",
    "bonus",
    "fund",
    "funding",
    "portfolio",
    "copy",
    "popular",
    "guru",
    "stock",
    "stocks",
    "crypto",
    "etf",
    "option",
    "options",
    "future",
    "futures",
    "forex",
    "fiat",
    "loan",
    "rebate",
    "chargeback",
    "refund",
    "rollback",
    "reversal",
    "settlement",
    "settled",
    "approval",
    "approved",
    "decline",
    "declined",
    "verification",
    "verified",
    "snapshot",
    "snapshotted",
    "tier",
    "score",
    "level",
    "status",
    "regulator",
    "playbook",
    "policy",
    "club",
    "bafin",
    "asic",
    "fca",
    "cysec",
    "mifid",
    "iban",
    "ftd",
    "nop",
    "aum",
    "ltv",
    "p&l",
    "pnl",
    "ddr",
    "mid",
    "cid",
    "wpid",
    "uid",
    "ppi",
}


# --- Rule outputs ------------------------------------------------------------


@dataclass
class RuleHits:
    """Per-column outcome of all rules. Empty `triggered` means not a candidate."""

    triggered: list[str]
    severity: int
    detail: dict[str, str]

    @property
    def is_candidate(self) -> bool:
        return bool(self.triggered)


# --- Helpers -----------------------------------------------------------------


_WORD_RE = re.compile(r"[A-Za-z][A-Za-z0-9_'-]*")


def _normalise_tokens(text: str) -> list[str]:
    """Lowercase tokens, strip punctuation. Multi-word mechanical phrases
    (`'at insert'`, `'set to'`, etc.) are matched separately by substring."""
    return [t.lower() for t in _WORD_RE.findall(text)]


def _has_mechanical_phrase(text: str) -> bool:
    lowered = text.lower()
    return any(
        " " in tok and tok in lowered for tok in MECHANICAL_TOKENS
    )


def _business_noun_count(tokens: list[str], glossary_terms: set[str]) -> int:
    """How many distinct business nouns appear in the token stream."""
    found: set[str] = set()
    for t in tokens:
        if t in BUSINESS_NOUN_BASELINE or t in glossary_terms:
            found.add(t)
    return len(found)


def _content_token_count(tokens: list[str]) -> int:
    """Count tokens that aren't stopwords or pure mechanical verbs."""
    return sum(
        1
        for t in tokens
        if t not in STOPWORDS and t not in MECHANICAL_TOKENS and len(t) > 2
    )


# --- Rule implementations ----------------------------------------------------


def _tier_gap(downstream_tier: Optional[TierInfo], upstream_tier: Optional[TierInfo]) -> Optional[str]:
    """TIER_GAP: downstream is Tier 2/3 and upstream is Tier 1 or Tier 4-Confluence.

    Returns a short detail string when triggered, else None.
    """
    if not downstream_tier or not upstream_tier:
        return None
    d = downstream_tier.tier
    u = upstream_tier.tier
    if d in {"2", "2b", "3", "3b"} and (u == "1" or upstream_tier.is_confluence):
        suffix = "Confluence" if upstream_tier.is_confluence else "Tier 1"
        return f"downstream Tier {d} vs upstream {suffix}"
    return None


def _mech_only(description_no_tier: str, glossary_terms: set[str]) -> Optional[str]:
    """MECH_ONLY: description is dominated by SP mechanics with no business nouns.

    Triggers when ALL of:
      - >=1 mechanical token or phrase present
      - 0 business nouns (baseline + glossary) present
      - content tokens (post-stopword/mechanical filter) <= 4
    """
    tokens = _normalise_tokens(description_no_tier)
    has_mech = any(t in MECHANICAL_TOKENS for t in tokens) or _has_mechanical_phrase(description_no_tier)
    if not has_mech:
        return None
    biz = _business_noun_count(tokens, glossary_terms)
    if biz > 0:
        return None
    content_n = _content_token_count(tokens)
    if content_n > 4:
        return None
    return f"only mechanical verbs, no business nouns ({content_n} content tokens)"


def _confluence_gap(
    downstream_tier: Optional[TierInfo],
    upstream_tier: Optional[TierInfo],
) -> Optional[str]:
    """CONFLUENCE_GAP: upstream column itself is sourced from Confluence
    (Tier 4 - Confluence), but downstream column is not.

    Column-level only. Wiki-level Confluence presence (section 9 footers) is
    too noisy -- it would fire on every column whenever the upstream wiki
    cited any Confluence page anywhere.
    """
    if not upstream_tier or not upstream_tier.is_confluence:
        return None
    if downstream_tier and downstream_tier.is_confluence:
        return None
    return f"upstream column cites Confluence ({upstream_tier.tier}); downstream does not"


def _length_gap(
    downstream_desc_no_tier: str,
    upstream_desc_no_tier: Optional[str],
    glossary_terms: set[str],
) -> Optional[str]:
    """LENGTH_GAP: upstream is materially longer AND adds new business nouns."""
    if not upstream_desc_no_tier:
        return None
    d_tokens = _normalise_tokens(downstream_desc_no_tier)
    u_tokens = _normalise_tokens(upstream_desc_no_tier)
    if len(u_tokens) < 2 * max(len(d_tokens), 1):
        return None
    d_set = {t for t in d_tokens if t in BUSINESS_NOUN_BASELINE or t in glossary_terms}
    u_set = {t for t in u_tokens if t in BUSINESS_NOUN_BASELINE or t in glossary_terms}
    new_nouns = u_set - d_set
    if not new_nouns:
        return None
    sample = ", ".join(sorted(new_nouns)[:5])
    return f"upstream ~{len(u_tokens)}w vs downstream ~{len(d_tokens)}w; adds [{sample}]"


# --- Public entry point ------------------------------------------------------


def evaluate_column(
    *,
    downstream_description: str,
    downstream_tier: Optional[TierInfo],
    downstream_wiki_text: str,
    upstream_description: Optional[str],
    upstream_tier: Optional[TierInfo],
    upstream_wiki_text: Optional[str],
    glossary_terms: set[str],
) -> RuleHits:
    """Run all 4 rules. Returns a RuleHits with the triggered subset."""
    triggered: list[str] = []
    detail: dict[str, str] = {}

    d_no_tier = description_without_tier_suffix(downstream_description)
    u_no_tier = (
        description_without_tier_suffix(upstream_description) if upstream_description else None
    )

    if (msg := _tier_gap(downstream_tier, upstream_tier)):
        triggered.append("TIER_GAP")
        detail["TIER_GAP"] = msg

    # MECH_ONLY only fires when an upstream is available to inherit from.
    # Otherwise the candidate is unactionable noise.
    if upstream_description and (msg := _mech_only(d_no_tier, glossary_terms)):
        triggered.append("MECH_ONLY")
        detail["MECH_ONLY"] = msg

    if (msg := _confluence_gap(downstream_tier, upstream_tier)):
        triggered.append("CONFLUENCE_GAP")
        detail["CONFLUENCE_GAP"] = msg

    if (msg := _length_gap(d_no_tier, u_no_tier, glossary_terms)):
        triggered.append("LENGTH_GAP")
        detail["LENGTH_GAP"] = msg

    return RuleHits(triggered=triggered, severity=len(triggered), detail=detail)


# --- Glossary loader ---------------------------------------------------------


def load_glossary_terms(glossary_path) -> set[str]:
    """Load lower-cased single-word terms from the project glossary's acronyms table.

    The glossary file is small (<200 lines); we read it whole and parse the first
    column of the 'Acronyms & Terms' table. Multi-word entries are also lowered
    and split into tokens so phrase fragments still register as business nouns.
    """
    from pathlib import Path

    p = Path(glossary_path)
    terms: set[str] = set()
    if not p.exists():
        return terms
    text = p.read_text(encoding="utf-8", errors="ignore")
    in_table = False
    header_seen = False
    for line in text.splitlines():
        if not in_table:
            if line.lstrip().startswith("| Term"):
                in_table = True
                header_seen = False
            continue
        if not header_seen:
            if re.match(r"^\s*\|[\s\-:|]+\|", line):
                header_seen = True
            continue
        if not line.lstrip().startswith("|"):
            break
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if not cells:
            continue
        term = cells[0].strip("`* ")
        if not term:
            continue
        # Add the whole entry plus its lowercase tokens.
        for tok in re.findall(r"[A-Za-z][A-Za-z0-9_-]*", term.lower()):
            # Reject 1-2 char fragments and common English glue words --
            # otherwise tokens like "in" / "of" / "is" leak in via glossary
            # entries such as "PIP in USD" and trigger LENGTH_GAP falsely.
            if len(tok) > 2 and tok not in STOPWORDS:
                terms.add(tok)
    return terms
