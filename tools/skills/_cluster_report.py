"""
One-off — cluster the per-token Class A gaps from a report.csv into concept families.

Goal: instead of 4,867 token-level rows, surface ~50 concept clusters that each
suggest a single short trigger (the 'root') that would substring-match all members.

Heuristic clustering:
1. Drop trailing/leading throwaway parts: _v, _stg, _id, gold_, bronze_, silver_,
   sql_dp_prod_we_, bi_db_dbo_, _masked, _new, etc.
2. Split on underscores -> 'tokens-of-the-token'.
3. Group tokens that share a meaningful root word (>= 3 chars, not a stop word).
4. The cluster's proposed trigger is the SHORTEST meaningful subtoken common to all.

Usage:
  python tools/skills/_cluster_report.py audits/_usage_trigger_xref_<ts>/report.csv
"""
from __future__ import annotations
import csv
import re
import sys
from collections import defaultdict

STRIP_PREFIXES = (
    "gold_sql_dp_prod_we_", "bronze_sql_dp_prod_we_", "silver_sql_dp_prod_we_",
    "bi_db_dbo_", "dwh_dbo_", "bi_output_", "de_output_",
    "gold_", "bronze_", "silver_",
)
STRIP_SUFFIXES = (
    "_masked", "_new", "_v", "_history", "_datafactory", "_forgenie",
)
CONCEPT_STOPWORDS = frozenset("""
date dates time times id key num count amount value status flag type code
total sum avg min max desc asc name names num nums numb numbs the and or not
record records row rows table tables item items data start end first last
new old current default test prod stage staging dev
fact dim vg vw view views bi db dbo dwh main system info schema
gold bronze silver dp sql prod we ext extras external ex
all any some only just other others same different similar diff
masked daily weekly monthly hourly minute hour day week month year quarter
""".split())


def normalize(tok: str) -> list[str]:
    """Return the meaningful subtokens of a (possibly compound) identifier."""
    t = tok.lower().strip()
    for p in STRIP_PREFIXES:
        if t.startswith(p):
            t = t[len(p):]
    for s in STRIP_SUFFIXES:
        if t.endswith(s):
            t = t[:-len(s)]
    parts = [p for p in re.split(r"[_]+", t) if p]
    return [p for p in parts if len(p) >= 3 and p not in CONCEPT_STOPWORDS]


def main():
    if len(sys.argv) < 2:
        print("usage: _cluster_report.py <report.csv>", file=sys.stderr)
        sys.exit(2)
    path = sys.argv[1]

    # Cluster key: SET of normalized subtokens (frozen)
    # cluster_key -> {hub: {token: max_queries}}
    clusters: dict[frozenset, dict[str, dict[str, int]]] = defaultdict(lambda: defaultdict(dict))
    # Also track tokens that have NO meaningful subtoken — keep as their own cluster
    singletons: dict[str, dict[str, int]] = defaultdict(dict)

    with open(path, encoding="utf-8") as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            if row["class"] != "A":
                continue
            tok = row["phrase"]
            hub = row["hub_skill_id"]
            qc = int(row["query_count"] or 0)
            parts = normalize(tok)
            if not parts:
                singletons[tok][hub] = max(singletons[tok].get(hub, 0), qc)
                continue
            key = frozenset(parts)
            # Merge if another existing cluster's key OVERLAPS by >= 1 part
            merged_into = None
            for existing_key in list(clusters.keys()):
                if existing_key & key:
                    merged_into = existing_key | key
                    break
            if merged_into and merged_into != existing_key:
                old = clusters.pop(existing_key)
                clusters[merged_into] = old
                key = merged_into
            elif merged_into:
                key = merged_into
            if hub not in clusters[key]:
                clusters[key][hub] = {}
            clusters[key][hub][tok] = max(clusters[key][hub].get(tok, 0), qc)

    # Score clusters by total queries across hubs (max-per-token, summed)
    def cluster_score(c: dict[str, dict[str, int]]) -> int:
        return sum(sum(toks.values()) for toks in c.values())

    rows = []
    for key, hubs in clusters.items():
        score = cluster_score(hubs)
        if score < 100:
            continue
        # Choose proposed trigger: the SHORTEST normalized token that appears in
        # >= half the member tokens (so it substring-matches them)
        all_member_tokens = sorted({t for hub in hubs.values() for t in hub.keys()})
        proposed = ""
        candidates = sorted(key, key=len)
        for c in candidates:
            hits = sum(1 for m in all_member_tokens if c in m.lower())
            if hits >= max(1, len(all_member_tokens) // 2):
                proposed = c
                break
        if not proposed:
            proposed = min(key, key=len)
        rows.append((score, proposed, sorted(key), hubs, all_member_tokens))

    rows.sort(key=lambda r: -r[0])

    print(f"# Concept clusters from {path}")
    print(f"# Total clusters: {len(rows)} (scoring >= 100 queries)\n")
    print(f"{'Score':>6}  {'Proposed':28}  {'#tokens':>7}  {'Hubs (top usage)':40}  Member tokens")
    print(f"{'-'*6}  {'-'*28}  {'-'*7}  {'-'*40}  {'-'*40}")
    for score, proposed, key_parts, hubs, members in rows[:40]:
        hubs_sorted = sorted(
            hubs.items(),
            key=lambda kv: -sum(kv[1].values()),
        )
        hubs_str = "; ".join(f"{h}={sum(t.values())}" for h, t in hubs_sorted[:3])
        members_str = ", ".join(members[:6]) + (" …" if len(members) > 6 else "")
        print(f"{score:6d}  {proposed:28}  {len(members):7d}  {hubs_str[:40]:40}  {members_str}")


if __name__ == "__main__":
    main()
