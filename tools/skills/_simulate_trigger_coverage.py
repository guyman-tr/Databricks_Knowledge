"""
Simulate: 'if I added <trigger> to the hub, how much actual usage would it
substring-match, and which tokens would it cover?'

This is the inverse view of report.csv: instead of asking 'what gaps are
there', ask 'what's the coverage payoff of each candidate root trigger?'.

The candidate set is hand-curated — concepts we already know are conceptually
real (ftd, crm, mixpanel, kyc, aml, breach, fee, club, snapshot, mimo, etc.)
— and the script tells us which actually clear a meaningful coverage bar.

Usage:
  python tools/skills/_simulate_trigger_coverage.py audits/_usage_trigger_xref_<ts>/report.csv
"""
from __future__ import annotations
import csv
import sys
from collections import defaultdict

CANDIDATE_TRIGGERS = [
    # Concept                         (substring,    expected_hub)
    ("ftd",                            "domain-customer-and-identity"),
    ("firsttimedeposit",               "domain-customer-and-identity"),
    ("registration",                   "domain-customer-and-identity"),
    ("crm",                            "domain-customer-and-identity"),
    ("case",                           "domain-customer-and-identity"),
    ("mixpanel",                       "domain-customer-and-identity"),
    ("mp_event",                       "domain-customer-and-identity"),
    ("clubtier",                       "domain-customer-and-identity"),
    ("club",                           "domain-customer-and-identity"),
    ("snapshot",                       "domain-customer-and-identity"),
    ("kyc",                            "domain-customer-and-identity"),
    ("appropriate",                    "domain-customer-and-identity"),
    ("negative_market",                "domain-customer-and-identity"),
    ("breach",                         "domain-customer-and-identity"),
    ("alert",                          "domain-customer-and-identity"),
    ("block",                          "domain-customer-and-identity"),
    ("cfd_status",                     "domain-customer-and-identity"),
    ("ddr_revenue",                    "domain-customer-and-identity"),
    ("ddr_mimo",                       "domain-customer-and-identity"),
    ("ddr_aum",                        "domain-customer-and-identity"),
    ("ddr_customer",                   "domain-customer-and-identity"),
    ("mimo",                           "domain-payments"),
    ("rolloverfee",                    "domain-revenue-and-fees"),
    ("rollover",                       "domain-revenue-and-fees"),
    ("netprofit",                      "domain-revenue-and-fees"),
    ("revenue",                        "domain-revenue-and-fees"),
    ("aum",                            "domain-revenue-and-fees"),
    ("trading_volume",                 "domain-trading"),
    ("payment",                        "domain-payments"),
    ("funding",                        "domain-payments"),
    ("emoney",                         "domain-payments"),
    ("cashback",                       "domain-payments"),
    ("aml",                            "domain-compliance-and-aml"),
    ("risk_classification",            "domain-compliance-and-aml"),
    ("compliance",                     "domain-compliance-and-aml"),
    ("regtech",                        "domain-compliance-and-aml"),
    ("illegal_trade",                  "domain-compliance-and-aml"),
    ("undertaking",                    "domain-compliance-and-aml"),
    ("instrument",                     "domain-trading"),
    ("dealing",                        "domain-trading"),
    ("position",                       "domain-trading"),
    ("affiliate",                      "domain-revenue-and-fees"),
    ("fiktivo",                        "domain-revenue-and-fees"),
    ("marketing",                      "domain-revenue-and-fees"),
    ("campaign",                       "domain-revenue-and-fees"),
    ("raf",                            "domain-revenue-and-fees"),
    ("voice_of_the_customer",          "domain-customer-and-identity"),
    ("data_rooms",                     "domain-customer-and-identity"),
]


def main():
    if len(sys.argv) < 2:
        print("usage: _simulate_trigger_coverage.py <report.csv>", file=sys.stderr)
        sys.exit(2)
    path = sys.argv[1]

    # Load every token + count + best hub from Class A rows
    # token -> max_query_count
    token_qc: dict[str, int] = {}
    # token -> set(hubs already routed there in the report)
    token_hubs: dict[str, set] = defaultdict(set)

    with open(path, encoding="utf-8") as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            if row["class"] != "A":
                continue
            tok = (row["phrase"] or "").lower()
            qc = int(row["query_count"] or 0)
            hub = row["hub_skill_id"]
            token_qc[tok] = max(token_qc.get(tok, 0), qc)
            token_hubs[tok].add(hub)

    print(f"# Candidate trigger coverage simulation")
    print(f"# Source: {path}")
    print(f"# Total Class-A tokens: {len(token_qc)}\n")
    print(f"{'Trigger':22} {'Hub':32} {'Matches':>7} {'Queries':>8}  Top members")
    print(f"{'-'*22} {'-'*32} {'-'*7} {'-'*8}  {'-'*60}")

    used_tokens: set[str] = set()
    summary = []
    for trig, hub in CANDIDATE_TRIGGERS:
        matches = [(t, c) for t, c in token_qc.items() if trig in t]
        if not matches:
            continue
        matches.sort(key=lambda x: -x[1])
        total = sum(c for _, c in matches)
        used_tokens.update(t for t, _ in matches)
        top = ", ".join(f"{t}({c})" for t, c in matches[:4])
        if len(matches) > 4:
            top += f" + {len(matches) - 4} more"
        summary.append((total, trig, hub, len(matches), top))

    summary.sort(key=lambda r: -r[0])
    for total, trig, hub, nmatches, top in summary:
        print(f"{trig:22} {hub:32} {nmatches:>7} {total:>8}  {top}")

    unique = len(used_tokens)
    print(f"\n# Coverage: {unique} of {len(token_qc)} Class-A tokens ({unique*100//max(1,len(token_qc))}%) matched by candidate triggers")
    print(f"# Uncovered: {len(token_qc) - unique} tokens still need direct triggers or different concepts")


if __name__ == "__main__":
    main()
