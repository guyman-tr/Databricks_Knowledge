"""Convergence pass v1 — produces proposed comment replacements without touching UC.

Three rules applied in order:

  Rule 1 (UPSTREAM_RICHER)
      If the wiki name appearing inside the Source cell points at another
      wiki whose §4 cell for the same column is RICHER (more literals,
      more table.col refs, more predicate ops) than ours, swap.

  Rule 2 (SEMANTIC_ANCHOR)
      Scan every wiki's section headings for ones that contain the column
      name. Extract CapitalizedNoun phrases (>= 6 chars) absent from
      the deployed comment. Prepend the strongest as "Flag for <Noun>."
      (only for boolean flags whose column name starts with Is/Has/Are).

  Rule 3 (SIBLING_RICHER)
      Among all wikis whose §4 has the same column name (excluding our
      target), pick the highest-richness transform. If it beats Rule 1's
      candidate, use that. Provenance is recorded.

Inputs are hard-coded for this run: 14 rows (IsSQF × 6, IsCreditReportValidCB × 8).

Output: audits/_convergence_gap/proposed_converged.csv with columns:
  uc_fqn, column, deployed, converged, rules_fired, source_wiki,
  upstream_richness, sibling_richness, deployed_richness, semantic_anchor
"""
from __future__ import annotations
import csv
import re
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo"
OUT = ROOT / "audits" / "_convergence_gap" / "proposed_converged.csv"

# Targets — same 14 rows the audit surfaced
TARGETS = [
    # (target_wiki_name,                       column,                  uc_fqn)
    ("Function_Trading_Volume",                "IsSQF",                  "main.etoro_kpi_prep.v_trading_volume_and_amount"),
    ("Function_Trading_Volume_PositionLevel",  "IsSQF",                  "main.etoro_kpi_prep.v_trading_volume_positionlevel"),
    ("Function_Revenue_AdminFee",              "IsSQF",                  "main.etoro_kpi_prep.v_revenue_adminfee"),
    ("Function_Revenue_Commissions",           "IsSQF",                  "main.etoro_kpi_prep.v_revenue_commission"),
    ("Function_Revenue_FullCommissions",       "IsSQF",                  "main.etoro_kpi_prep.v_revenue_fullcommission"),
    ("Function_Revenue_RolloverFee",           "IsSQF",                  "main.etoro_kpi_prep.v_revenue_rollover"),
    ("Function_Revenue_OptionsPlatform",       "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_optionsplatform"),
    ("Function_Revenue_AdminFee",              "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_adminfee"),
    ("Function_Revenue_Commissions",           "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_commission"),
    ("Function_Revenue_FullCommissions",       "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_fullcommission"),
    ("Function_Revenue_RolloverFee",           "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_rollover"),
    ("Function_Revenue_Dividend",              "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_dividend"),
    ("Function_Revenue_StakingFee",            "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_stakingfee"),
    ("Function_Revenue_TransferCoinFee",       "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_revenue_transfercoinfee"),
    # Discovered during pilot deploy via information_schema scan — same
    # Tier 5 correction propagates here too.
    ("Function_Instrument_Snapshot_Enriched",  "IsSQF",                  "main.etoro_kpi_prep.v_dim_instrument_enriched"),
    ("Function_MIMO_Options_Platform",         "IsCreditReportValidCB",  "main.etoro_kpi_prep.v_mimo_options_platform"),
]

# Broadened literal-detector — counts every "specific thing the author committed to"
LITERAL_PATTERNS = [
    # named ID = N / IN (N,N,...)
    re.compile(r"\b[A-Z][A-Za-z_]*ID\s*(?:=|IN|<>|≠|!=)\s*'?\(?\s*\d+", re.IGNORECASE),
    # named field <op> value
    re.compile(r"\b[A-Z][A-Za-z_]+\s*(?:=|<>|!=|≠|>=|<=|>|<)\s*'[^']*'"),
    # table.column refs (3+ chars each side)
    re.compile(r"\b[A-Za-z_][A-Za-z0-9_]{2,}\.[A-Z][A-Za-z0-9_]{2,}\b"),
    # @date variables
    re.compile(r"@[A-Za-z][A-Za-z0-9_]+"),
    # explicit integer in predicate context like = 59, IN (4,10), = 250
    re.compile(r"(?:=|IN|>=|<=)\s*\(?\s*\d+"),
    # CASE WHEN exprs
    re.compile(r"\bCASE\s+WHEN\b", re.IGNORECASE),
    # group / regulation / country mentions with a value next to them
    re.compile(r"\b(?:Group|Regulation|Country|Account|KYC|InstrumentType|Player)[A-Za-z_]*\s*[=<>]+\s*\d+", re.IGNORECASE),
]

# Trivial-ish penalty patterns — we DON'T want to converge toward these
TRIVIAL_PATTERNS = [
    re.compile(r"^Direct\.?\s*$", re.IGNORECASE),
    re.compile(r"^Passthrough\.?\s*$", re.IGNORECASE),
    re.compile(r"^From\s+customer\s+snapshot\.?\s*$", re.IGNORECASE),
    re.compile(r"^From\s+[A-Z][A-Za-z_]+\.?\s*$"),
]

# CapitalizedNoun phrase detector
NOUN_PHRASE_RX = re.compile(r"\b([A-Z][a-z]+(?:[A-Z][a-z]+){1,3})\b")

# Words we should never propose as a "business name" — too generic / not a noun
NOUN_BLACKLIST = {
    "DateID", "GroupID", "InstrumentID", "AccountID", "CustomerID", "RegulationID",
    "RealCID", "ActionID", "PositionID", "CountryID", "AccountTypeID",
    "Function", "Source", "Direct", "True", "False", "Tier", "Passthrough",
    "Fact", "Dim", "Trade", "Snapshot", "Customer", "Instrument", "Position",
    "Action", "Aggregate", "ETLcomputed", "DateKey", "MonthEndDateID",
}


@dataclass
class S4Row:
    wiki_path: Path
    wiki_name: str
    column: str
    source_cell: str
    transform_cell: str
    tier: str

    @property
    def richness(self) -> int:
        text = self.transform_cell
        if any(p.match(text) for p in TRIVIAL_PATTERNS):
            return 0
        score = 0
        for pat in LITERAL_PATTERNS:
            score += len(pat.findall(text))
        # length bonus capped
        score += min(len(text) // 40, 5)
        return score


def clean_md(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def parse_section4(path: Path) -> dict[str, S4Row]:
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return {}
    m = re.search(r"## 4\.\s+(?:Output Columns|Elements)\s*\n(.*?)(?=\n## |\Z)", text, re.DOTALL)
    if not m:
        return {}
    wiki_name = path.stem
    out: dict[str, S4Row] = {}
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---") or "# |" in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6:
            continue
        col = parts[2].strip().strip("*").strip("`")
        if not col or col.lower() in ("column", "element"):
            continue
        out[col.lower()] = S4Row(
            wiki_path=path,
            wiki_name=wiki_name,
            column=col,
            source_cell=clean_md(parts[3]),
            transform_cell=clean_md(parts[4]),
            tier=parts[5].strip() if len(parts) > 5 else "",
        )
    return out


# Corpus index: column_name_lower → list[S4Row]
_INDEX: dict[str, list[S4Row]] = defaultdict(list)
# Wiki name → §4
_BY_WIKI: dict[str, dict[str, S4Row]] = {}
# Heading index: column_name_lower → list[(wiki_name, heading_text)]
_HEADINGS: dict[str, list[tuple[str, str]]] = defaultdict(list)


def build_corpus() -> None:
    heading_rx = re.compile(r"^#+\s+(.*)$")
    for p in WIKI_ROOT.rglob("*.md"):
        if "lineage" in p.name or "review" in p.name:
            continue
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            continue
        s4 = parse_section4(p)
        if s4:
            _BY_WIKI[p.stem] = s4
            for col_lower, row in s4.items():
                _INDEX[col_lower].append(row)
        # Headings
        for line in text.splitlines():
            mh = heading_rx.match(line)
            if not mh:
                continue
            heading = clean_md(mh.group(1))[:200]
            # Drop heading numbering prefix
            heading_no_num = re.sub(r"^\d+(\.\d+)*\.?\s*", "", heading)
            for word in re.findall(r"\b[A-Za-z][A-Za-z0-9_]+\b", heading_no_num):
                _HEADINGS[word.lower()].append((p.stem, heading_no_num))
    print(f"Corpus indexed: {len(_BY_WIKI)} wikis, "
          f"{sum(len(v) for v in _INDEX.values())} §4 rows", flush=True)


def deployed_comment(row: S4Row) -> str:
    """Replicate the exact format from tools/apply_tvf_col_comments.py."""
    t = row.transform_cell
    if t.lower() in ("direct", "direct pass-through",
                     "direct from union branches", "direct from union row"):
        comment = f"Direct pass-through from {row.source_cell}. ({row.tier} — {row.wiki_name})"
    else:
        comment = f"{t}. Source: {row.source_cell}. ({row.tier} — {row.wiki_name})"
    return comment


_TRAILING_TIER_RX = re.compile(r"\s*\(\s*Tier\s*\d+\b[^)]*\)\s*$", re.IGNORECASE)
_TRAILING_VIA_RX = re.compile(r"\s*\(\s*via\s+[^)]+\)\s*$", re.IGNORECASE)


def strip_trailing_provenance(text: str) -> str:
    """Strip any trailing '(Tier N - ...)' / '(via X)' parentheticals so we can
    re-stitch our own provenance suffix without doubling up."""
    prev = None
    cur = text.strip()
    while cur != prev:
        prev = cur
        cur = _TRAILING_TIER_RX.sub("", cur)
        cur = _TRAILING_VIA_RX.sub("", cur)
        cur = cur.strip()
        if cur.endswith("."):
            cur = cur[:-1].rstrip()
    return cur


def find_upstream_wiki_name(row: S4Row) -> str | None:
    """Pull Function_* / V_* wiki name out of the Source cell."""
    m = re.search(r"\b(Function_[A-Za-z0-9_]+|V_[A-Za-z0-9_]+)\b", row.source_cell)
    return m.group(1) if m else None


def find_semantic_anchor(column: str, deployed: str) -> str | None:
    """Headings that contain column-name tail, surface a noun phrase absent from deployed."""
    col_tail = column
    # For Is{X} flags, the interesting noun is {X}
    m = re.match(r"^(Is|Has|Are|Was)([A-Z][A-Za-z0-9_]+)$", column)
    search_keys = [column.lower()]
    if m:
        search_keys.append(m.group(2).lower())
    # also try short tail like 'SQF' for IsSQF (3-letter acronyms)
    if len(column) > 2 and column[:2] == "Is" and column[2:].isupper():
        search_keys.append(column[2:].lower())

    headings_seen: set[str] = set()
    for key in search_keys:
        for _wiki, heading in _HEADINGS.get(key, []):
            if heading in headings_seen:
                continue
            headings_seen.add(heading)
            for noun in NOUN_PHRASE_RX.findall(heading):
                if noun in NOUN_BLACKLIST:
                    continue
                if len(noun) < 6:
                    continue
                if noun.lower() in deployed.lower():
                    continue
                # Prefer one that appears in headings of MULTIPLE wikis
                count = sum(1 for w, _ in _HEADINGS.get(key, [])
                            if noun in _)
                # Actually just return the first plausible
                return noun
    return None


def converge(target_wiki: str, column: str) -> dict:
    s4_target = _BY_WIKI.get(target_wiki, {})
    target_row = s4_target.get(column.lower())
    if not target_row:
        return {"error": f"target {target_wiki}.{column} not found"}

    deployed = deployed_comment(target_row)
    deployed_rich = target_row.richness

    # Rule 1 candidate: direct upstream from Source cell
    upstream_name = find_upstream_wiki_name(target_row)
    upstream_row = None
    if upstream_name and upstream_name != target_wiki:
        upstream_row = _BY_WIKI.get(upstream_name, {}).get(column.lower())

    # Rule 3 candidate: richest sibling (excluding self)
    siblings = [r for r in _INDEX.get(column.lower(), [])
                if r.wiki_name != target_wiki]
    siblings.sort(key=lambda r: -r.richness)
    richest_sibling = siblings[0] if siblings else None

    # Choose best alternative
    candidates: list[tuple[str, S4Row | None]] = []
    if upstream_row and upstream_row.richness > deployed_rich:
        candidates.append(("UPSTREAM_RICHER", upstream_row))
    if richest_sibling and richest_sibling.richness > deployed_rich:
        if not upstream_row or richest_sibling.richness >= upstream_row.richness:
            candidates.append(("SIBLING_RICHER", richest_sibling))

    rules_fired: list[str] = []
    chosen: S4Row | None = None
    if candidates:
        # Prefer UPSTREAM if available, else SIBLING
        candidates.sort(key=lambda c: (0 if c[0] == "UPSTREAM_RICHER" else 1, -c[1].richness))
        rules_fired.append(candidates[0][0])
        chosen = candidates[0][1]

    # Build merged transform text — strip trailing tier/via parentheticals
    # from sibling-borrowed cells so we don't double-stamp provenance.
    if chosen:
        merged_transform = strip_trailing_provenance(chosen.transform_cell)
        merged_source = f"{chosen.source_cell} (via {chosen.wiki_name})"
    else:
        merged_transform = target_row.transform_cell
        merged_source = target_row.source_cell

    # Rule 2: semantic anchor
    anchor = find_semantic_anchor(column, deployed + " " + merged_transform)
    col_l = column.lower()

    # Per-column template registry — keeps the converger from emitting
    # awkward "{Noun} flag." prefixes that don't fit specific concepts.
    SEMANTIC_TEMPLATES = {
        "issqf": ("Flag for {anchor} instruments. ", True),
        "iscreditreportvalidcb": (
            "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ",
            False,  # ignore anchor; semantic is column-intrinsic
        ),
    }
    template, uses_anchor = SEMANTIC_TEMPLATES.get(col_l, ("{anchor} flag. ", True))

    # Skip the template entirely if the chosen text already carries the
    # same semantic. Heuristic: look for any non-stopword token from the
    # template that's >= 6 chars; if all such tokens appear in the
    # merged_transform, the semantic is already in place.
    def _template_already_present(tmpl: str, body: str) -> bool:
        tokens = [t for t in re.findall(r"[A-Za-z_]{6,}", tmpl)
                  if t.lower() not in ("financial", "client", "balance", "for", "flag", "reports")]
        if not tokens:
            tokens = re.findall(r"[A-Za-z_]{6,}", tmpl)[:3]
        body_low = body.lower()
        # Require ALL specific tokens present to declare "already there"
        return all(t.lower() in body_low for t in tokens) if tokens else False

    if uses_anchor:
        if anchor and col_l.startswith(("is", "has", "are")):
            if anchor.lower() in merged_transform.lower():
                # Already mentions the anchor; no prefix
                merged_transform_final = merged_transform
            else:
                rules_fired.append("SEMANTIC_ANCHOR")
                prefix = template.format(anchor=anchor)
                merged_transform_final = prefix + merged_transform
        else:
            merged_transform_final = merged_transform
    else:
        # Column-intrinsic semantic (e.g. ICRVCB)
        if _template_already_present(template, merged_transform):
            merged_transform_final = merged_transform
        else:
            rules_fired.append("SEMANTIC_TEMPLATE")
            merged_transform_final = template + merged_transform

    converged = f"{merged_transform_final}. Source: {merged_source}. ({target_row.tier} — {target_wiki})"
    # Compress whitespace and dedup ".."
    converged = re.sub(r"\s+", " ", converged).replace("..", ".").strip()

    return {
        "deployed": deployed,
        "converged": converged,
        "rules_fired": ",".join(rules_fired) if rules_fired else "NONE",
        "source_wiki": chosen.wiki_name if chosen else target_wiki,
        "upstream_richness": upstream_row.richness if upstream_row else "",
        "sibling_richness": richest_sibling.richness if richest_sibling else "",
        "deployed_richness": deployed_rich,
        "semantic_anchor": anchor or "",
    }


def main() -> int:
    build_corpus()

    rows: list[dict] = []
    for wiki, col, uc in TARGETS:
        result = converge(wiki, col)
        rows.append({
            "uc_fqn": uc,
            "wiki": wiki,
            "column": col,
            **result,
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=[
            "uc_fqn", "wiki", "column",
            "deployed", "converged",
            "rules_fired", "source_wiki",
            "deployed_richness", "upstream_richness", "sibling_richness",
            "semantic_anchor",
        ])
        w.writeheader()
        w.writerows(rows)

    print(f"\nWrote {OUT.relative_to(ROOT)}")
    print()
    for r in rows:
        print("=" * 110)
        print(f"{r['uc_fqn']}.{r['column']}")
        print(f"  rules : {r['rules_fired']}  (deployed_rich={r['deployed_richness']}  "
              f"upstream_rich={r['upstream_richness']}  sibling_rich={r['sibling_richness']})")
        print(f"  anchor: {r['semantic_anchor']!r}    source_wiki={r['source_wiki']}")
        print(f"  BEFORE: {r['deployed']}")
        print(f"  AFTER : {r['converged']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
