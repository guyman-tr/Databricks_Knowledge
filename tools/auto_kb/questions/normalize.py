"""Denoise raw user questions and cluster them into intent signatures.

The contract (per the tracker spec):
  1. Remove noise: dates, quarters, years, month names, raw numbers, URLs,
     country/region literals, and conversational filler.
  2. Identify METRICS first, then CLASSIFIERS (dimensions / breakdowns).
  3. The intent SIGNATURE is `m:<metrics>|c:<classifiers>` -- two questions that
     ask for the same measure(s) sliced by the same dimension(s) collapse to one
     cluster regardless of which quarter, country, or threshold they mention.

Everything here is deterministic and offline. No DB, no agent, no network.
"""
from __future__ import annotations

import re
from collections import Counter
from dataclasses import dataclass, field
from typing import Any, Iterable

# ---------------------------------------------------------------------------
# Lexicon. Canonical concept -> list of surface synonyms (lowercase substrings).
# Ordered by priority so the signature is stable & reads metrics-first.
# ---------------------------------------------------------------------------

# Longest synonyms first within each concept so multi-word forms win.
METRIC_LEXICON: list[tuple[str, list[str]]] = [
    ("net_deposits", ["net deposits", "net deposit", "net mimo"]),
    ("ftd", ["first time depositor", "first-time depositor", "first time deposit",
             "first-time deposit", "ftda", "ftds", "ftd"]),
    ("deposits", ["deposits", "deposit", "deposited", "mimo"]),
    ("withdrawals", ["withdrawals", "withdrawal", "cashouts", "cashout", "cash out"]),
    ("revenue", ["gross revenue", "net revenue", "revenue", "turnover"]),
    ("trading_volume", ["trading volume", "notional", "invested amount", "volume"]),
    ("pnl", ["profit and loss", "profit/loss", "profit", "p&l", "pnl"]),
    ("aum", ["assets under management", "aum", "aua"]),
    ("cpa", ["cost per acquisition", "acquisition cost", "marketing cost", "cpa"]),
    ("registrations", ["registrations", "registration", "registered", "signups", "sign ups"]),
    ("active_traders", ["active traders", "active users", "active customers", "active accounts"]),
    ("fees", ["commission", "commissions", "fees", "fee"]),
    ("balance", ["balance", "equity"]),
    ("customers", ["number of customers", "customer count", "count of customers"]),
]

CLASSIFIER_LEXICON: list[tuple[str, list[str]]] = [
    ("country", ["by country", "per country", "country", "countries"]),
    ("region", ["marketingregion", "marketing region", "region", "cee", "emea", "apac", "area"]),
    ("platform", ["allplatforms", "all platforms", "by platform", "per platform", "platform"]),
    ("instrument", ["instruments", "instrument", "stocks", "stock", "commodities",
                    "commodity", "crypto", "ticker", "asset"]),
    ("asset_class", ["asset class", "asset type", "asset classes"]),
    ("month", ["monthly", "by month", "per month", "month over month", "mom", "month"]),
    ("day", ["daily", "by day", "per day", "day over day", "dod", "day"]),
    ("week", ["weekly", "by week", "per week", "week"]),
    ("quarter", ["quarterly", "quarter over quarter", "qoq", "by quarter", "quarter"]),
    ("year", ["yearly", "year over year", "yoy", "annual", "year"]),
    ("currency", ["currency", "ccy"]),
    ("age", ["age bucket", "age group", "age band", "age"]),
    ("gender", ["gender"]),
    ("customer", ["per customer", "by customer", "per user", "by user"]),
]

# Country / region literals to delete (so they never leak into 'other' tokens).
_GEO_LITERALS = [
    "poland", "romania", "czech republic", "czech", "hungary", "bulgaria", "slovakia",
    "croatia", "serbia", "ukraine", "greece", "france", "french", "germany", "german",
    "italy", "italian", "spain", "spanish", "portugal", "australia", "australian",
    "united kingdom", "uk", "usa", "united states", "us", "israel", "cyprus",
    "netherlands", "belgium", "austria", "switzerland", "sweden", "norway", "denmark",
    "finland", "ireland", "turkey", "brazil", "mexico", "argentina", "canada",
    "japan", "china", "india", "singapore", "thailand", "vietnam", "malaysia",
    "indonesia", "philippines", "south africa", "nigeria", "kenya", "egypt", "uae",
]

_MONTHS = [
    "january", "february", "march", "april", "may", "june", "july", "august",
    "september", "october", "november", "december",
    "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "sept", "oct", "nov", "dec",
]

# Conversational filler removed before extracting the 'other' fallback tokens.
_FILLER = {
    "show", "me", "give", "please", "can", "you", "what", "is", "was", "are", "the",
    "a", "an", "of", "for", "to", "from", "in", "on", "by", "with", "and", "or", "vs",
    "versus", "compare", "comparison", "breakdown", "broken", "down", "total", "totals",
    "top", "order", "ascending", "descending", "include", "also", "yes", "no", "i",
    "we", "our", "see", "want", "need", "get", "list", "over", "per", "this", "that",
    "last", "next", "between", "as", "their", "them", "it", "do", "does", "did",
    "how", "many", "much", "number", "count", "avg", "average", "sum", "ratio",
    "split", "each", "all", "where", "when", "why", "which", "value", "values",
}

_URL_RE = re.compile(r"https?://\S+")
_QUARTER_RE = re.compile(r"\bq[1-4]\b")
_YEAR_RE = re.compile(r"\b(?:19|20)\d{2}\b")
_NUM_RE = re.compile(r"\b\d[\d,\.]*\b")
_PUNCT_RE = re.compile(r"[^\w\s&/\-]")
_WS_RE = re.compile(r"\s+")
_MONTH_RE = re.compile(r"\b(?:" + "|".join(_MONTHS) + r")\b")
_GEO_RE = re.compile(r"\b(?:" + "|".join(re.escape(g) for g in sorted(_GEO_LITERALS, key=len, reverse=True)) + r")\b")


def denoise(prompt: str) -> str:
    """Strip dates, numbers, URLs, geo literals and punctuation. Lowercase."""
    s = (prompt or "").lower()
    s = _URL_RE.sub(" ", s)
    s = _QUARTER_RE.sub(" ", s)
    s = _YEAR_RE.sub(" ", s)
    s = _MONTH_RE.sub(" ", s)
    s = _GEO_RE.sub(" ", s)
    s = _NUM_RE.sub(" ", s)
    s = _PUNCT_RE.sub(" ", s)
    s = _WS_RE.sub(" ", s).strip()
    return s


def _match_concepts(clean: str, lexicon: list[tuple[str, list[str]]]) -> list[str]:
    found: list[str] = []
    for canonical, synonyms in lexicon:
        for syn in synonyms:
            if syn in clean:
                found.append(canonical)
                break
    return found


def _fallback_tokens(clean: str, limit: int = 3) -> list[str]:
    toks = [t for t in clean.split() if t not in _FILLER and len(t) > 2]
    # Preserve order, dedupe.
    seen: set[str] = set()
    out: list[str] = []
    for t in toks:
        if t not in seen:
            seen.add(t)
            out.append(t)
        if len(out) >= limit:
            break
    return out


@dataclass
class Signature:
    metrics: list[str] = field(default_factory=list)
    classifiers: list[str] = field(default_factory=list)
    other: list[str] = field(default_factory=list)

    @property
    def key(self) -> str:
        """Cluster key is METRIC-led (metrics first); classifiers are a secondary
        attribute aggregated per cluster, so 'FTD by country' and 'FTD by country
        per month' collapse to the same interest. Falls back to classifier-led,
        then to content tokens, when no metric is present."""
        if self.metrics:
            return "m:" + "+".join(self.metrics)
        if self.classifiers:
            return "c:" + "+".join(self.classifiers)
        return "o:" + "+".join(self.other or ["unknown"])


def extract_signature(prompt: str) -> Signature:
    clean = denoise(prompt)
    metrics = sorted(set(_match_concepts(clean, METRIC_LEXICON)))
    classifiers = sorted(set(_match_concepts(clean, CLASSIFIER_LEXICON)))
    other: list[str] = []
    if not metrics and not classifiers:
        other = _fallback_tokens(clean)
    return Signature(metrics=metrics, classifiers=classifiers, other=other)


# Common shape for one normalized question row (source-agnostic):
#   {source, prompt, skills_top_score, skills_match_quality_hint,
#    skills_all_below_floor, returned_skill_ids, status, thumb_down, user_hash}
@dataclass
class Cluster:
    signature: str
    metrics: list[str]
    other: list[str]
    count: int = 0
    classifier_counts: Counter = field(default_factory=Counter)
    user_hashes: set[str] = field(default_factory=set)
    sources: set[str] = field(default_factory=set)
    examples: Counter = field(default_factory=Counter)
    # coverage signal aggregation
    mcp_total: int = 0
    mcp_below_floor: int = 0
    mcp_above_floor: int = 0
    top_scores: list[float] = field(default_factory=list)
    returned_skill_ids: Counter = field(default_factory=Counter)
    genie_total: int = 0
    genie_fail: int = 0
    thumb_down: int = 0

    @property
    def distinct_users(self) -> int:
        return len(self.user_hashes)

    @property
    def classifiers(self) -> list[str]:
        """Top classifiers seen across the cluster (secondary attribute)."""
        return [c for c, _ in self.classifier_counts.most_common(4)]

    @property
    def label(self) -> str:
        if self.metrics:
            head = ", ".join(self.metrics)
        elif self.other:
            head = ", ".join(self.other)
        else:
            head = "general"
        tail = ", ".join(self.classifiers) if self.classifiers else "n/a"
        return f"{head} by {tail}"


_COMPLETED = {"completed", "success", "succeeded", "ok", "done"}


def _to_float(value: Any) -> float | None:
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _truthy(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() in {"true", "1", "yes", "t"}


def _normalize_skill_ids(value: Any) -> list[str]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return [str(v) for v in value]
    text = str(value).strip()
    # Databricks ARRAY casts often arrive as a JSON-ish string.
    text = text.strip("[]")
    parts = [p.strip().strip('"').strip("'") for p in text.split(",")]
    return [p for p in parts if p]


def cluster_questions(rows: Iterable[dict[str, Any]]) -> dict[str, Cluster]:
    """Group normalized question rows by intent signature."""
    clusters: dict[str, Cluster] = {}
    for r in rows:
        prompt = str(r.get("prompt") or "").strip()
        if not prompt:
            continue
        sig = extract_signature(prompt)
        key = sig.key
        cl = clusters.get(key)
        if cl is None:
            cl = Cluster(
                signature=key,
                metrics=sig.metrics,
                other=sig.other,
            )
            clusters[key] = cl

        cl.count += 1
        for c in sig.classifiers:
            cl.classifier_counts[c] += 1
        cl.examples[denoise(prompt)] += 1
        src = str(r.get("source") or "").lower()
        cl.sources.add(src or "unknown")
        uh = str(r.get("user_hash") or "").strip()
        if uh:
            cl.user_hashes.add(uh)

        if src == "mcp":
            cl.mcp_total += 1
            hint = str(r.get("skills_match_quality_hint") or "").strip().lower()
            below = _truthy(r.get("skills_all_below_floor")) or hint == "below_floor"
            if below:
                cl.mcp_below_floor += 1
            elif hint == "above_floor":
                cl.mcp_above_floor += 1
            score = _to_float(r.get("skills_top_score"))
            if score is not None:
                cl.top_scores.append(score)
            for sid in _normalize_skill_ids(r.get("returned_skill_ids")):
                cl.returned_skill_ids[sid] += 1
        elif src == "genie":
            cl.genie_total += 1
            status = str(r.get("status") or "").strip().lower()
            if status and status not in _COMPLETED:
                cl.genie_fail += 1
            if _truthy(r.get("thumb_down")):
                cl.thumb_down += 1

    return clusters
