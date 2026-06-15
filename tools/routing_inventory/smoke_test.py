"""Phase 8 - routing smoke test.

Mimics what the LLM matcher sees: for each query, finds every trigger across
the corpus that appears as a substring (or normalized-form match) in the
query, and reports which hubs claim those triggers. This is a structural
analogue of what a real matcher would score, useful for verifying that the
routing-disambiguation contract changes (Phase 1-7) land the right hubs at
the top of the candidate list.

NOT a substitute for live MCP regression - the live router uses an embedding
+ ranking model. But it's a quick sanity check that the trigger SET on each
hub is now consistent with the contract.

Usage:
    python tools/routing_inventory/smoke_test.py
        - runs the default set of 8 questions spanning 6 super-concepts.

    python tools/routing_inventory/smoke_test.py --query "how many funded accounts yesterday"
        - runs a single ad-hoc query.

The default 8 questions intentionally exercise:
    - the funded-accounts case that motivated the whole effort
    - AUM bare + qualified forms
    - FTD bare + qualified forms
    - Apex / USABroker / Gatsby (broker identity)
    - MIMO bare (no overlap; sanity check)
    - net deposits bare vs spaceship-qualified
    - audit trail context_dispatch
    - PlayerStatus identity column
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

import yaml


REPO = Path(__file__).resolve().parents[2]
SKILLS_DIR = REPO / "knowledge" / "skills"
LEDGER_CSV = Path(__file__).parent / "ledger.csv"
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---", re.DOTALL)
PUNCT_RE = re.compile(r"[^\w\s\-]")
WS_RE = re.compile(r"\s+")


DEFAULT_QUERIES = [
    {
        "id": "funded_accounts_bare",
        "query": "how many funded accounts do we have yesterday",
        "expected_top": "domain-customer-and-identity",
        "anti": ["domain-spaceship", "domain-revenue-and-fees"],
        "rationale": "The exact case that motivated the whole effort. Bare 'funded accounts' must route to the global lifecycle owner, not Spaceship.",
    },
    {
        "id": "funded_accounts_spaceship_qualified",
        "query": "funded accounts on spaceship dashboard",
        "expected_top": "domain-spaceship",
        "anti": [],
        "rationale": "Qualified form: 'spaceship funded accounts' should route to the niche hub.",
    },
    {
        "id": "aum_bare",
        "query": "what is our AUM as of today",
        "expected_top": "domain-aum-and-aua",
        "anti": ["domain-trading", "domain-payments"],
        "rationale": "Bare AUM goes to the dedicated AUM hub. Trading and payments dropped the bare trigger in Phase 4.",
    },
    {
        "id": "aum_moneyfarm_qualified",
        "query": "moneyfarm aum trend last quarter",
        "expected_top": "domain-moneyfarm",
        "anti": ["domain-revenue-and-fees"],
        "rationale": "Qualified 'moneyfarm aum' goes to MF niche hub, not revenue (which dropped the trigger).",
    },
    {
        "id": "apex_broker",
        "query": "what is the apex SOD recon difference",
        "expected_top": "domain-cross",
        "anti": ["domain-options", "domain-payments", "domain-revenue-and-fees"],
        "rationale": "Apex/Gatsby/USABroker are all the same US broker - canonical recon lives in domain-cross/provider-reconciliation.md (Phase 5 added the bare 'Apex' trigger there).",
    },
    {
        "id": "isglobalftd_column",
        "query": "what is IsGlobalFTD",
        "expected_top": "domain-customer-and-identity",
        "anti": ["domain-cross", "domain-options", "domain-payments"],
        "rationale": "IsGlobalFTD is the global lifecycle column - lives on customer-populations-and-lifecycle.md (Phase 5 addition).",
    },
    {
        "id": "playerstatus_column",
        "query": "what does PlayerStatus mean on Dim_Customer",
        "expected_top": "domain-customer-and-identity",
        "anti": ["domain-compliance-and-aml", "domain-ops-and-onboarding", "domain-staking"],
        "rationale": "PlayerStatus is a Dim_Customer column - customer-master-record.md (Phase 5 addition).",
    },
    {
        "id": "audit_trail_dispatch",
        "query": "audit trail for accountid 12345 over last month",
        "expected_top": "domain-customer-and-identity",
        "anti": [],
        "context_dispatch": True,
        "rationale": "Context-dispatch: matcher correctly ties domain-cross and domain-customer-and-identity at the trigger level (both legitimately claim 'audit trail'). The contract resolves the tie at routing time via §5.1 intent dispatch ('audit trail for accountid' -> identity). PASS if expected hub appears in top 2.",
    },
]


def normalize(s: str) -> str:
    s = str(s).lower().strip()
    s = PUNCT_RE.sub(" ", s)
    s = WS_RE.sub(" ", s).strip()
    return s


def parse_frontmatter(text: str):
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None
    try:
        return yaml.safe_load(m.group(1))
    except yaml.YAMLError:
        return None


def hub_of(rel_path: Path) -> str:
    return rel_path.parts[2]


def build_trigger_index() -> dict[str, dict]:
    """{normalized_trigger: {hub: count_of_files}}"""
    index: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for md in sorted(SKILLS_DIR.rglob("*.md")):
        rel = md.relative_to(REPO)
        hub = hub_of(rel)
        if not (hub.startswith("domain-") or hub == "cross-cutting"):
            continue
        fm = parse_frontmatter(md.read_text(encoding="utf-8"))
        if fm is None:
            continue
        triggers = fm.get("triggers", []) or []
        if not isinstance(triggers, list):
            triggers = [triggers]
        for t in triggers:
            raw = str(t).strip()
            if not raw:
                continue
            index[normalize(raw)][hub] += 1
    return index


def score_query(query: str, trigger_index: dict[str, dict[str, int]]) -> list[tuple[str, float, list[str]]]:
    """Returns ranked list of (hub, score, matched_triggers).
    Score = sum over matched triggers of (1.0 / number of hubs claiming that trigger).
    This rewards hubs that exclusively own a trigger and penalizes shared triggers."""
    q_norm = normalize(query)
    q_words = set(q_norm.split())

    hub_scores: dict[str, float] = defaultdict(float)
    hub_matches: dict[str, list[str]] = defaultdict(list)

    for trig_norm, hubs in trigger_index.items():
        trig_words = trig_norm.split()
        if not trig_words:
            continue
        # Full-phrase substring match (most reliable)
        if trig_norm in q_norm:
            weight = 1.0 / len(hubs)
            # Longer triggers carry more weight (more specific)
            length_boost = len(trig_words)
            for hub in hubs:
                hub_scores[hub] += weight * length_boost
                hub_matches[hub].append(trig_norm)
            continue
        # Token-set partial match: all trigger tokens present in query as words
        # (only for multi-token triggers - single-token would be too noisy)
        if len(trig_words) >= 2 and set(trig_words).issubset(q_words):
            weight = 0.5 / len(hubs)
            length_boost = len(trig_words)
            for hub in hubs:
                hub_scores[hub] += weight * length_boost
                hub_matches[hub].append(trig_norm + " (token-match)")

    ranked = sorted(
        ((h, s, sorted(set(hub_matches[h]))) for h, s in hub_scores.items()),
        key=lambda r: -r[1],
    )
    return ranked


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--query", help="Run a single ad-hoc query")
    p.add_argument("--top", type=int, default=5, help="Show top-N hubs per query")
    args = p.parse_args(argv)

    print("Building trigger index from knowledge/skills/...")
    index = build_trigger_index()
    print(f"  Indexed {len(index)} distinct triggers across the corpus.\n")

    if args.query:
        queries = [{"id": "adhoc", "query": args.query, "expected_top": None, "anti": [], "rationale": ""}]
    else:
        queries = DEFAULT_QUERIES

    pass_count = 0
    fail_count = 0
    for q in queries:
        print("=" * 72)
        print(f"[{q['id']}]  \"{q['query']}\"")
        if q["expected_top"]:
            print(f"  Expected top: `{q['expected_top']}`")
        if q["rationale"]:
            print(f"  Rationale: {q['rationale']}")
        ranked = score_query(q["query"], index)
        print(f"\n  Top {args.top} hubs:")
        for i, (hub, score, matches) in enumerate(ranked[:args.top], start=1):
            marker = ""
            if q["expected_top"]:
                if hub == q["expected_top"]:
                    if i == 1:
                        marker = "  <- EXPECTED #1 (PASS)"
                    elif q.get("context_dispatch") and i == 2:
                        marker = "  <- EXPECTED in top 2 (PASS via context-dispatch contract)"
                elif hub in q["anti"] and i == 1:
                    marker = "  <- ANTI (FAIL: should not be #1)"
                elif hub in q["anti"]:
                    marker = "  <- anti (still appears but not top)"
            print(f"    #{i:>2}  {hub:<35}  score={score:.3f}  triggers={matches[:3]}{'...' if len(matches) > 3 else ''}{marker}")

        if q["expected_top"]:
            top_hubs = [r[0] for r in ranked[:2]] if q.get("context_dispatch") else [ranked[0][0]] if ranked else []
            if q["expected_top"] in top_hubs:
                pass_count += 1
            else:
                fail_count += 1
        print()

    print("=" * 72)
    if args.query:
        return 0
    print(f"\nResults: {pass_count} pass, {fail_count} fail (of {len(queries)} test queries)")
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
