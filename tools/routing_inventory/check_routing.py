"""ROUTING-001 - CI guard for the routing-disambiguation-contract.

Detects routing-contract violations introduced by recent edits to the skill
corpus. Re-runs the same inventory-scan logic used by Phase 1, then compares
the current trigger-overlap set against the ledger at
tools/routing_inventory/ledger.csv.

Reports four classes of finding:

1. UNCLASSIFIED NEW OVERLAP (warning by default, error with --strict)
   A trigger appears on >=2 hubs and is NOT in the ledger. Either someone added
   a duplicate trigger on a hub that already had a primary owner, or a brand-
   new concept needs a ledger entry. Fix: add to ledger OR remove the dup.

2. CONTRACT REGRESSION (always error)
   A hub listed in `drop_from` for a primary_only / qualified_wins concept
   re-introduced the bare trigger after Phase 4 cleanup. Fix: remove the
   trigger from that hub (it belongs only on the primary owner).

3. SUBSTRING LANDMINE (warning, surfaced for review)
   A new bare-prefix trigger (1-2 token, mostly schema-name-like) on one hub
   matches a long concept on another hub as a substring. Fix: remove the bare
   prefix OR qualify it.

4. CONTEXT_DISPATCH STILL OK (informational)
   The 4 known context_dispatch concepts (audit trail / is_ftd / is_funded /
   is_internal_transfer) continue to overlap by design. Not flagged.

Exit codes:
    0 = no findings
    1 = warnings only
    2 = errors (regression OR --strict warning)
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


def scan_triggers() -> dict[str, dict]:
    """Returns {normalized_concept: {"hubs": set, "files": set, "variants": set}}
    for every trigger entry."""
    concept_to_data: dict[str, dict] = defaultdict(
        lambda: {"hubs": set(), "files": set(), "variants": set()}
    )
    for md in sorted(SKILLS_DIR.rglob("*.md")):
        rel = md.relative_to(REPO)
        hub = hub_of(rel)
        if not (hub.startswith("domain-") or hub == "cross-cutting"):
            continue
        text = md.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        if fm is None:
            continue
        triggers = fm.get("triggers", []) or []
        if not isinstance(triggers, list):
            triggers = [triggers]
        file_str = str(rel).replace("\\", "/")
        for t in triggers:
            raw = str(t).strip()
            if not raw:
                continue
            norm = normalize(raw)
            d = concept_to_data[norm]
            d["hubs"].add(hub)
            d["files"].add(file_str)
            d["variants"].add(raw)
    return concept_to_data


def load_ledger() -> dict[str, dict]:
    if not LEDGER_CSV.is_file():
        return {}
    ledger: dict[str, dict] = {}
    with LEDGER_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            ledger[r["concept"]] = {
                "primary_owner": r["primary_owner"],
                "pattern": r["pattern"],
                "drop_from": set(r["drop_from"].split("; ")) if r["drop_from"] else set(),
                "super_concept": r["super_concept"],
                "notes": r["notes"],
            }
    return ledger


def detect_substring_landmines(concept_data: dict[str, dict]) -> list[dict]:
    """A bare-prefix landmine: a 1-2 token concept on hub A is a sub-span of a
    long concept on hub B (B != A). New only — already-known landmines are
    okay; we flag any that aren't in an allowlist."""
    short: dict[str, set[str]] = {}
    long_: dict[str, set[str]] = {}
    for c, data in concept_data.items():
        toks = c.split()
        if 1 <= len(toks) <= 2:
            short[c] = data["hubs"]
        if len(toks) >= 3:
            long_[c] = data["hubs"]
    landmines: list[dict] = []
    for long_c, long_hubs in long_.items():
        toks = long_c.split()
        for n in (1, 2):
            for i in range(len(toks) - n + 1):
                sub = " ".join(toks[i : i + n])
                if sub not in short:
                    continue
                sub_hubs = short[sub]
                foreign = sub_hubs - long_hubs
                if not foreign:
                    continue
                landmines.append({
                    "short": sub,
                    "long": long_c,
                    "short_hubs": sub_hubs,
                    "long_hubs": long_hubs,
                    "foreign_hubs": foreign,
                })
    return landmines


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--strict", action="store_true",
                   help="Treat warnings as errors (exit 2 instead of 1).")
    p.add_argument("--quiet", action="store_true", help="Only print summary.")
    args = p.parse_args(argv)

    concept_data = scan_triggers()
    ledger = load_ledger()
    if not ledger:
        print("ERROR: ledger not found at tools/routing_inventory/ledger.csv. "
              "Run tools/routing_inventory/build_ledger.py first.")
        return 2

    overlaps = {c: d for c, d in concept_data.items() if len(d["hubs"]) >= 2}

    unclassified: list[dict] = []
    regressions: list[dict] = []
    expected_dispatch: list[str] = []

    for concept, data in overlaps.items():
        if concept in ledger:
            entry = ledger[concept]
            if entry["pattern"] == "context_dispatch":
                expected_dispatch.append(concept)
                continue
            offending = data["hubs"] - {entry["primary_owner"]}
            offending &= entry["drop_from"]
            if offending:
                regressions.append({
                    "concept": concept,
                    "primary": entry["primary_owner"],
                    "pattern": entry["pattern"],
                    "offending_hubs": offending,
                    "files": data["files"],
                })
        else:
            unclassified.append({
                "concept": concept,
                "hubs": data["hubs"],
                "variants": data["variants"],
                "files": data["files"],
            })

    landmines = detect_substring_landmines(concept_data)
    # Landmines are informational (typically legitimate domain-bare-term
    # matches). They are reported but do not contribute to the exit code.
    # Only TRUE landmines (e.g., bare schema prefixes that fire on any FQN)
    # are flagged as warnings.
    schema_prefix_re = re.compile(r"^(main\s+\w+|\w+_prep|\w+_db|bi_db|dwh|bi_output|etoro_kpi)$")
    serious_landmines = [
        lm for lm in landmines
        if schema_prefix_re.match(lm["short"])
    ]

    err_count = len(regressions)
    warn_count = len(unclassified) + len(serious_landmines)

    if not args.quiet:
        print(f"\n=== ROUTING-001 routing compliance check ===\n")
        print(f"Hubs scanned:                       {len({h for d in concept_data.values() for h in d['hubs']})}")
        print(f"Distinct trigger concepts:          {len(concept_data)}")
        print(f"Overlapping concepts (>=2 hubs):    {len(overlaps)}")
        print(f"  Expected (context_dispatch):      {len(expected_dispatch)}")
        print(f"  Unclassified new overlap:         {len(unclassified)}   {'(warn)' if not args.strict else '(error)'}")
        print(f"  Contract regression:              {len(regressions)}   (error)")
        print(f"Substring landmines (informational): {len(landmines)}")
        print(f"  Serious (schema-prefix kind):       {len(serious_landmines)}   (warn)")
        print()

        if regressions:
            print("CONTRACT REGRESSIONS (must fix):")
            for r in regressions:
                print(f"  - '{r['concept']}' is back on {sorted(r['offending_hubs'])}; "
                      f"primary owner is `{r['primary']}` ({r['pattern']}).")
                for f in sorted(r["files"]):
                    print(f"      seen in: {f}")
            print()

        if unclassified:
            print("UNCLASSIFIED NEW OVERLAPS (add to ledger or dedupe):")
            for u in sorted(unclassified, key=lambda r: (-len(r["hubs"]), r["concept"])):
                print(f"  - '{u['concept']}' on {sorted(u['hubs'])}   variants={sorted(u['variants'])}")
            print()

        if serious_landmines:
            print(f"SERIOUS SUBSTRING LANDMINES (schema-prefix-like):")
            for lm in serious_landmines:
                print(f"  - bare '{lm['short']}' on {sorted(lm['short_hubs'])}; "
                      f"matches '{lm['long']}' on {sorted(lm['long_hubs'])}")
            print()
        elif landmines and not args.quiet:
            print(f"(Informational: {len(landmines)} non-serious substring matches not shown.)")
            print()

    if err_count > 0:
        print(f"FAIL: {err_count} contract regression(s)")
        return 2
    if warn_count > 0:
        print(f"WARN: {warn_count} unclassified overlap(s) / landmine(s)")
        return 2 if args.strict else 1
    print("PASS: no routing-contract violations.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
