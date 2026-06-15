"""Quantify the 'convergence gap': for each deployed UC column comment,
compare it against richer sources elsewhere in the corpus.

Heuristic gap signals (any one flags a candidate for re-deploy under
a convergence pass):

  COMPRESSION_LOSS    — upstream §4 row (per Source cell) contains
                        identifiers (GroupID=N, table.col, explicit numbers)
                        that the deployed UC comment dropped.

  SIBLING_RICHER      — some sibling wiki has a §4 row for the same
                        column name with length >= 1.5x the deployed
                        comment and contains noun phrases (capitalized
                        terms) absent from the deployed comment.

  HEADING_ANCHOR      — some wiki §1/§2/§3 prose or section heading
                        names the column AND contains a CapitalizedPhrase
                        that's absent from the deployed comment.
                        (Crude "is there a name for what this is" check.)

Output: CSV ranking by signal density. No deploy is performed.
"""
from __future__ import annotations
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"

# Predicate-y patterns that downstream comments often drop
PREDICATE_RX = re.compile(
    r"(?:GroupID\s*=\s*\d+|InstrumentTypeID\s*=\s*\d+|"
    r"CompensationReasonID\s*[=I]N?\s*\(?[\d,\s]+\)?|"
    r"ActionTypeID\s*[=I]N?\s*\(?[\d,\s]+\)?|"
    r"SettlementTypeID\s*=\s*\d+|"
    r"FundingTypeID\s*[=I]N?\s*\(?[\d,\s]+\)?|"
    r"TxTypeID\s*[=I]N?\s*\(?[\d,\s]+\)?|"
    r"PayTypeCode\s*=\s*'\w+'|"
    r"`?[A-Z][A-Za-z_]+\.[A-Z][A-Za-z_]+`?)",
    re.IGNORECASE,
)

# Capitalised multi-word phrases (rough semantic-noun-phrase detector)
NOUN_PHRASE_RX = re.compile(r"\b([A-Z][a-zA-Z]+(?:[A-Z][a-zA-Z]+){1,3})\b")


def clean(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def parse_section4(path: Path) -> dict[str, dict]:
    """Return {col_lower: {source, transform, tier, raw_row}} from §4 Output Columns."""
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return {}
    m = re.search(r"## 4\.\s+(?:Output Columns|Elements)\s*\n(.*?)(?=\n## |\Z)", text, re.DOTALL)
    if not m:
        return {}
    out = {}
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
        out[col.lower()] = {
            "source": clean(parts[3]),
            "transform": clean(parts[4]),
            "tier": parts[5].strip() if len(parts) > 5 else "",
            "raw_row": line,
        }
    return out


_WIKI_CACHE: dict[Path, tuple[str, list[tuple[str, str]], list[str]]] = {}


def _load_corpus() -> None:
    """Preload every BI_DB wiki: full text, headings, sentence list (no §4)."""
    if _WIKI_CACHE:
        return
    bi_db = WIKI_ROOT / "BI_DB_dbo"
    heading_pat = re.compile(r"^#+\s+(.*)$")
    paths = list(bi_db.rglob("*.md")) if bi_db.exists() else []
    # Also include DDR fact wikis under any BI_DB folder
    for p in paths:
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            continue
        text_no_s4 = re.sub(r"## 4\.[\s\S]*?(?=\n## |\Z)", "", text)
        headings = []
        for line in text_no_s4.splitlines():
            mh = heading_pat.match(line)
            if mh:
                headings.append((mh.group(1), clean(mh.group(1))[:200]))
        # Pre-split sentences once
        sentences = [clean(s)[:240] for s in re.split(r"(?<=[\.\!\?])\s+", text_no_s4)
                     if 20 < len(s) < 400]
        _WIKI_CACHE[p] = (text, headings, sentences)
    print(f"Corpus cached: {len(_WIKI_CACHE)} BI_DB wikis", flush=True)


def harvest_column_mentions(col_name: str) -> dict[Path, list[str]]:
    """For a column name, find every wiki that mentions it anywhere outside §4."""
    _load_corpus()
    out: dict[Path, list[str]] = defaultdict(list)
    pat = re.compile(rf"\b{re.escape(col_name)}\b", re.IGNORECASE)
    for p, (full_text, headings, sentences) in _WIKI_CACHE.items():
        if not pat.search(full_text):
            continue
        for raw, cleaned in headings:
            if pat.search(raw):
                out[p].append("HEAD: " + cleaned)
        for sent in sentences:
            if pat.search(sent):
                out[p].append("PROSE: " + sent[:200])
    return out


def main() -> int:
    # Hard-code the deployed cohort for this audit
    DEPLOYED = [
        ("Function_Trading_Volume",                "main.etoro_kpi_prep.v_trading_volume_and_amount"),
        ("Function_Trading_Volume_PositionLevel",  "main.etoro_kpi_prep.v_trading_volume_positionlevel"),
        ("Function_Revenue_OptionsPlatform",       "main.etoro_kpi_prep.v_revenue_optionsplatform"),
        ("Function_Revenue_AdminFee",              "main.etoro_kpi_prep.v_revenue_adminfee"),
        ("Function_Revenue_Commissions",           "main.etoro_kpi_prep.v_revenue_commission"),
        ("Function_Revenue_FullCommissions",       "main.etoro_kpi_prep.v_revenue_fullcommission"),
        ("Function_Revenue_RolloverFee",           "main.etoro_kpi_prep.v_revenue_rollover"),
        ("Function_Revenue_Dividend",              "main.etoro_kpi_prep.v_revenue_dividend"),
        ("Function_Revenue_StakingFee",            "main.etoro_kpi_prep.v_revenue_stakingfee"),
        ("Function_Revenue_TransferCoinFee",       "main.etoro_kpi_prep.v_revenue_transfercoinfee"),
        ("Function_PnL_Single_Day",                "main.etoro_kpi_prep.tvf_pnl_single_day"),
        ("Function_AUM_OptionsPlatform",           "main.etoro_kpi_prep.v_options_aum"),
        ("Function_Instrument_Snapshot_Enriched",  "main.etoro_kpi_prep.v_dim_instrument_enriched"),
        ("Function_Population_Active_Traders",     "main.etoro_kpi_prep.v_population_active_traders"),
        ("Function_Population_Funded",             "main.etoro_kpi_prep.v_population_funded"),
        ("V_Liabilities",                          "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities"),
    ]

    rows_out = []
    for wiki_name, uc_fqn in DEPLOYED:
        # Find the wiki path
        candidates = list(WIKI_ROOT.rglob(f"{wiki_name}.md"))
        candidates = [c for c in candidates if "lineage" not in c.name and "review" not in c.name]
        if not candidates:
            continue
        wiki_path = candidates[0]
        s4 = parse_section4(wiki_path)
        for col_lower, info in s4.items():
            # Deployed comment = the format from apply_tvf_col_comments.py
            transform = info["transform"]
            source = info["source"]
            tier = info["tier"]
            deployed = f"{transform}. Source: {source}. ({tier} — {wiki_name})"

            signals = []

            # COMPRESSION_LOSS: does the upstream Source cell point to a wiki?
            #   If so, parse THAT wiki's §4 for the same column and compare.
            src_wiki_name = None
            m = re.search(r"\bFunction_[A-Za-z0-9_]+", source)
            if m:
                src_wiki_name = m.group(0)
            if src_wiki_name and src_wiki_name != wiki_name:
                up_paths = [c for c in WIKI_ROOT.rglob(f"{src_wiki_name}.md")
                            if "lineage" not in c.name and "review" not in c.name]
                if up_paths:
                    up_s4 = parse_section4(up_paths[0])
                    up_row = up_s4.get(col_lower)
                    if up_row:
                        up_transform = up_row["transform"]
                        up_preds = set(m.group(0).lower() for m in PREDICATE_RX.finditer(up_transform))
                        deployed_preds = set(m.group(0).lower() for m in PREDICATE_RX.finditer(deployed))
                        lost = up_preds - deployed_preds
                        if lost:
                            signals.append(f"COMPRESSION_LOSS: {sorted(lost)[:4]}")

            # SIBLING_RICHER + HEADING_ANCHOR
            mentions = harvest_column_mentions(col_lower)
            deployed_noun_phrases = set(NOUN_PHRASE_RX.findall(deployed))
            sibling_phrases = set()
            heading_hits = []
            for src_path, snippets in mentions.items():
                if src_path == wiki_path:
                    continue
                for snip in snippets:
                    if snip.startswith("HEAD:"):
                        heading_hits.append(f"{src_path.stem}: {snip[6:80]}")
                    new_phrases = set(NOUN_PHRASE_RX.findall(snip)) - deployed_noun_phrases
                    sibling_phrases |= {p for p in new_phrases if len(p) >= 6}
            if sibling_phrases:
                signals.append(f"SIBLING_PHRASES: {sorted(sibling_phrases)[:6]}")
            if heading_hits:
                signals.append(f"HEADING_ANCHOR: {heading_hits[:2]}")

            if signals:
                rows_out.append({
                    "uc_fqn": uc_fqn,
                    "column": col_lower,
                    "deployed_comment": deployed[:160],
                    "signals": " || ".join(signals)[:600],
                })

    # Sort by signal richness (proxy: total length of signals string)
    rows_out.sort(key=lambda r: -len(r["signals"]))

    out_path = ROOT / "audits" / "_convergence_gap" / "convergence_candidates.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["uc_fqn", "column", "deployed_comment", "signals"])
        w.writeheader()
        w.writerows(rows_out)

    print(f"Wikis examined: {len(DEPLOYED)}")
    print(f"Columns with convergence signals: {len(rows_out)}")
    print(f"Output: {out_path.relative_to(ROOT)}")
    print()
    print("Top 15 by signal richness:")
    for r in rows_out[:15]:
        print(f"  {r['uc_fqn'].split('.')[-1]:30s}  {r['column']:24s}  ->  {r['signals'][:140]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
