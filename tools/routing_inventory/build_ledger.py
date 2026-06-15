"""Phase 2 ledger builder + validator.

Reads:
  - tools/routing_inventory/ledger_classification.yaml   (human-curated)
  - audits/_routing_inventory_<ts>/concepts.csv          (machine-extracted)

Validates that every TRIGGER-overlap concept (hub_count >= 2 and source_fields
contains 'triggers') has exactly one ledger entry, and that primary_owner +
drop_from references are consistent with claiming_hubs.

Emits:
  - audits/_routing_inventory_<ts>/ledger.csv
  - audits/_routing_inventory_<ts>/semantic_hierarchy.md

Exit code:
  0 = all checks pass
  1 = validation errors (missing entries, unknown concepts, owner outside claimants)
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path
from collections import defaultdict

import yaml


VALID_PATTERNS = {"primary_only", "qualified_wins", "context_dispatch"}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: build_ledger.py <inventory-folder>")
        return 2
    inventory = Path(sys.argv[1])
    if not inventory.is_dir():
        print(f"not a folder: {inventory}")
        return 2

    yaml_path = Path(__file__).parent / "ledger_classification.yaml"
    if not yaml_path.is_file():
        print(f"missing classification: {yaml_path}")
        return 2

    doc = yaml.safe_load(yaml_path.read_text(encoding="utf-8"))
    super_concepts = doc.get("super_concepts", {})

    # Collect ledger entries from yaml
    ledger: dict[str, dict] = {}
    duplicate_concepts: list[str] = []
    for sc_name, sc in super_concepts.items():
        for e in sc.get("entries", []) or []:
            c = e["concept"]
            if c in ledger:
                duplicate_concepts.append(c)
                continue
            ledger[c] = {
                "super_concept": sc_name,
                "concept": c,
                "primary_owner": e["primary_owner"],
                "pattern": e["pattern"],
                "drop_from": e.get("drop_from") or [],
                "notes": e.get("notes", ""),
            }

    # Read trigger overlaps from concepts.csv
    trigger_overlaps: dict[str, dict] = {}
    with (inventory / "concepts.csv").open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            fields = set(r["source_fields"].split("; "))
            if "triggers" not in fields:
                continue
            if int(r["hub_count"]) < 2:
                continue
            trigger_overlaps[r["normalized_concept"]] = {
                "claiming_hubs": set(r["claiming_hubs"].split("; ")),
                "variants": r["variants"],
            }

    errors: list[str] = []
    warnings: list[str] = []

    for c in duplicate_concepts:
        errors.append(f"duplicate ledger entry: '{c}'")

    missing_in_ledger = sorted(set(trigger_overlaps) - set(ledger))
    for c in missing_in_ledger:
        errors.append(
            f"NOT classified: '{c}' (claimed by {sorted(trigger_overlaps[c]['claiming_hubs'])})"
        )

    # Historical ledger entries (overlap resolved by Phase 4 cleanup) are
    # expected and not warned. Only flag entries whose `drop_from` is empty
    # AND the concept doesn't overlap (that's a true typo / dead entry).
    extra_in_ledger = sorted(set(ledger) - set(trigger_overlaps))
    historical_resolved: list[str] = []
    for c in extra_in_ledger:
        entry = ledger[c]
        if entry["drop_from"]:
            historical_resolved.append(c)
        else:
            warnings.append(
                f"ledger entry for non-overlap concept with empty drop_from: '{c}' "
                f"(likely a typo or dead entry)"
            )

    for c, entry in ledger.items():
        if c not in trigger_overlaps:
            continue
        if entry["pattern"] not in VALID_PATTERNS:
            errors.append(f"'{c}': invalid pattern '{entry['pattern']}'")
            continue
        claiming = trigger_overlaps[c]["claiming_hubs"]
        primary = entry["primary_owner"]
        drops = set(entry["drop_from"])

        # primary owner must currently claim the concept OR be a known hub we're adding it to.
        # Phase-5 additions (e.g., 'funded accounts' onto customer-and-identity) are flagged.
        if primary not in claiming:
            warnings.append(
                f"'{c}': primary_owner '{primary}' is NOT a current claimant; needs PHASE 5 ADD"
            )

        # drop_from must be a subset of current claimants
        non_claimant_drops = drops - claiming
        if non_claimant_drops:
            errors.append(
                f"'{c}': drop_from has non-claimant(s): {sorted(non_claimant_drops)} "
                f"(claimants: {sorted(claiming)})"
            )

        # primary should not be in drop_from
        if primary in drops:
            errors.append(f"'{c}': primary_owner '{primary}' appears in drop_from")

        # For primary_only and qualified_wins, drop_from should cover all non-primary
        # claimants (we can verify in Phase 4 cleanup; warning here)
        if entry["pattern"] in {"primary_only", "qualified_wins"} and primary in claiming:
            should_drop = claiming - {primary}
            missing_drops = should_drop - drops
            if missing_drops:
                warnings.append(
                    f"'{c}' ({entry['pattern']}): drop_from missing claimants: "
                    f"{sorted(missing_drops)}"
                )

    print("=" * 60)
    print(f"Ledger entries:                       {len(ledger)}")
    print(f"Trigger overlaps in corpus:           {len(trigger_overlaps)}")
    print(f"Historical (resolved by Phase 4):     {len(historical_resolved)}")
    print(f"Errors:                               {len(errors)}")
    print(f"Warnings:                             {len(warnings)}")
    print("=" * 60)

    if errors:
        print("\nERRORS (fix before emitting outputs):\n")
        for e in errors:
            print(f"  {e}")

    if warnings:
        print("\nWARNINGS:\n")
        for w in warnings:
            print(f"  {w}")

    if errors:
        return 1

    # Canonical (stable path) + snapshot (in audit folder)
    canonical_csv = Path(__file__).parent / "ledger.csv"
    snapshot_csv = inventory / "ledger.csv"

    def _write_csv(p: Path) -> None:
        with p.open("w", encoding="utf-8", newline="") as f:
            w = csv.writer(f)
            w.writerow([
                "super_concept",
                "concept",
                "primary_owner",
                "pattern",
                "drop_from",
                "claiming_hubs",
                "variants",
                "notes",
            ])
            for c in sorted(ledger.keys()):
                entry = ledger[c]
                overlap = trigger_overlaps.get(c, {"claiming_hubs": set(), "variants": ""})
                w.writerow([
                    entry["super_concept"],
                    entry["concept"],
                    entry["primary_owner"],
                    entry["pattern"],
                    "; ".join(entry["drop_from"]),
                    "; ".join(sorted(overlap["claiming_hubs"])),
                    overlap["variants"],
                    entry["notes"],
                ])

    _write_csv(canonical_csv)
    _write_csv(snapshot_csv)
    print(f"\nWrote ledger.csv ({len(ledger)} rows):")
    print(f"  canonical: {canonical_csv}")
    print(f"  snapshot:  {snapshot_csv}")

    # semantic_hierarchy.md
    by_super: dict[str, list[dict]] = defaultdict(list)
    for c, entry in ledger.items():
        by_super[entry["super_concept"]].append(entry)
    for k in by_super:
        by_super[k].sort(key=lambda e: e["concept"])

    pattern_totals: dict[str, int] = defaultdict(int)
    for entry in ledger.values():
        pattern_totals[entry["pattern"]] += 1

    canonical_md = Path(__file__).parent / "semantic_hierarchy.md"
    snapshot_md = inventory / "semantic_hierarchy.md"
    out_md = canonical_md
    with out_md.open("w", encoding="utf-8") as f:
        f.write("# Semantic Concept Hierarchy + Ownership Ledger\n\n")
        f.write(
            "Phase 2 deliverable. Organizes the 184 trigger-overlap concepts into\n"
            "super-concept families and assigns each one a primary owner + a\n"
            "disambiguation pattern. Phase 3 (codify-contract) embeds this into\n"
            "cross-cutting/routing-disambiguation-contract.md. Phase 4 executes\n"
            "the trigger edits implied by `drop_from`.\n\n"
        )
        f.write("## Pattern legend\n\n")
        f.write(
            "- **primary_only** - bare form belongs to one hub; secondaries drop the trigger entirely.\n"
            "- **qualified_wins** - bare form goes to primary; secondaries keep ONLY qualified forms (e.g., `spaceship X`, `options X`).\n"
            "- **context_dispatch** - bare form has multiple legitimate owners; contract codifies intent-based routing.\n\n"
        )
        f.write("## Distribution\n\n")
        f.write(f"- Total ledger entries: **{len(ledger)}**\n")
        for p in sorted(pattern_totals):
            f.write(f"- `{p}`: {pattern_totals[p]}\n")
        f.write("\n")

        f.write("## Concept families\n\n")
        for sc_name in sorted(by_super.keys()):
            sc_doc = super_concepts.get(sc_name, {})
            desc = (sc_doc.get("description") or "").strip()
            f.write(f"### `{sc_name}` ({len(by_super[sc_name])} concepts)\n\n")
            if desc:
                f.write(desc + "\n\n")
            f.write("| Concept | Primary owner | Pattern | Drop from | Notes |\n")
            f.write("|---|---|---|---|---|\n")
            for entry in by_super[sc_name]:
                drops = ", ".join(entry["drop_from"]) if entry["drop_from"] else "-"
                notes = entry["notes"].replace("|", "\\|") if entry["notes"] else ""
                f.write(
                    f"| `{entry['concept']}` | `{entry['primary_owner']}` | "
                    f"{entry['pattern']} | {drops} | {notes} |\n"
                )
            f.write("\n")

    snapshot_md.write_text(canonical_md.read_text(encoding="utf-8"), encoding="utf-8")
    print(f"Wrote semantic_hierarchy.md:")
    print(f"  canonical: {canonical_md}")
    print(f"  snapshot:  {snapshot_md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
