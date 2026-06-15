"""Phase 1 - Corpus-wide concept inventory scanner.

Walks `knowledge/skills/{cross-cutting,domain-*}/` and extracts every trigger /
required_tables / sample_questions entry into a normalized concept catalog.
Outputs:
  audits/_routing_inventory_<ts>/raw_triggers.csv
  audits/_routing_inventory_<ts>/concepts.csv
  audits/_routing_inventory_<ts>/substring_overlaps.csv
  audits/_routing_inventory_<ts>/inventory_report.md

No classification in this phase. Pure discovery. Phase 2 builds the semantic
hierarchy and assigns ownership patterns on top of these outputs.
"""
from __future__ import annotations

import csv
import re
from collections import defaultdict
from datetime import datetime
from pathlib import Path

import yaml


REPO = Path(__file__).resolve().parents[2]
SKILLS_DIR = REPO / "knowledge" / "skills"
TS = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
OUT = REPO / "audits" / f"_routing_inventory_{TS}"

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---", re.DOTALL)
PUNCT_RE = re.compile(r"[^\w\s\-]")
WS_RE = re.compile(r"\s+")

SCANNED_FIELDS = ("triggers", "required_tables", "sample_questions")


def parse_frontmatter(text: str):
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None
    try:
        return yaml.safe_load(m.group(1))
    except yaml.YAMLError:
        return None


def normalize(s: str) -> str:
    """Lowercase, strip non-word punct (keep hyphens), collapse whitespace."""
    s = str(s).lower().strip()
    s = PUNCT_RE.sub(" ", s)
    s = WS_RE.sub(" ", s).strip()
    return s


def hub_of(rel_path: Path) -> str:
    """domain-foo / cross-cutting (rel path looks like knowledge/skills/<hub>/...)."""
    return rel_path.parts[2]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    raw_rows: list[dict] = []
    concept_to_hubs: dict[str, set[str]] = defaultdict(set)
    concept_to_files: dict[str, set[str]] = defaultdict(set)
    concept_variants: dict[str, set[str]] = defaultdict(set)
    concept_to_fields: dict[str, set[str]] = defaultdict(set)
    hub_stats: dict[str, dict[str, int]] = defaultdict(
        lambda: {"files": 0, "triggers": 0, "required_tables": 0, "sample_questions": 0}
    )
    files_scanned = 0
    files_no_frontmatter = 0

    for md in sorted(SKILLS_DIR.rglob("*.md")):
        rel = md.relative_to(REPO)
        if any(p.startswith("_") or p == ".local_workspace_backup" for p in rel.parts):
            continue
        hub = hub_of(rel)
        if not (hub.startswith("domain-") or hub == "cross-cutting"):
            continue

        text = md.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        files_scanned += 1
        if fm is None:
            files_no_frontmatter += 1
            continue

        hub_stats[hub]["files"] += 1
        file_str = str(rel).replace("\\", "/")

        for field in SCANNED_FIELDS:
            values = fm.get(field, []) or []
            if not isinstance(values, list):
                values = [values]
            for v in values:
                raw = str(v).strip()
                if not raw:
                    continue
                raw_rows.append(
                    {
                        "hub_id": hub,
                        "file": file_str,
                        "source_field": field,
                        "trigger_raw": raw,
                        "trigger_normalized": normalize(raw),
                    }
                )
                hub_stats[hub][field] += 1
                norm = normalize(raw)
                concept_to_hubs[norm].add(hub)
                concept_to_files[norm].add(file_str)
                concept_variants[norm].add(raw)
                concept_to_fields[norm].add(field)

    # raw_triggers.csv
    with (OUT / "raw_triggers.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["hub_id", "file", "source_field", "trigger_raw", "trigger_normalized"],
        )
        w.writeheader()
        for r in raw_rows:
            w.writerow(r)

    # concepts.csv
    with (OUT / "concepts.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(
            [
                "normalized_concept",
                "hub_count",
                "claiming_hubs",
                "variant_count",
                "variants",
                "file_count",
                "source_fields",
            ]
        )
        for concept in sorted(
            concept_to_hubs.keys(), key=lambda c: (-len(concept_to_hubs[c]), c)
        ):
            hubs = sorted(concept_to_hubs[concept])
            variants = sorted(concept_variants[concept])
            files = concept_to_files[concept]
            fields = sorted(concept_to_fields[concept])
            w.writerow(
                [
                    concept,
                    len(hubs),
                    "; ".join(hubs),
                    len(variants),
                    "; ".join(variants),
                    len(files),
                    "; ".join(fields),
                ]
            )

    # substring overlap detection: long concept on hub A contains sub-concept
    # claimed by hub B (not A) -> matcher-false-positive vector.
    multi_word_concepts = {c: hubs for c, hubs in concept_to_hubs.items() if len(c.split()) >= 2}
    sub_overlap_rows: list[dict] = []
    for long_c, long_hubs in multi_word_concepts.items():
        toks = long_c.split()
        for n in range(2, len(toks)):
            for i in range(len(toks) - n + 1):
                sub = " ".join(toks[i : i + n])
                if sub == long_c:
                    continue
                sub_hubs = multi_word_concepts.get(sub) or concept_to_hubs.get(sub)
                if not sub_hubs:
                    continue
                foreign = sub_hubs - long_hubs
                if not foreign:
                    continue
                sub_overlap_rows.append(
                    {
                        "long_concept": long_c,
                        "long_hubs": "; ".join(sorted(long_hubs)),
                        "sub_concept": sub,
                        "sub_hubs": "; ".join(sorted(sub_hubs)),
                        "foreign_hubs": "; ".join(sorted(foreign)),
                    }
                )

    with (OUT / "substring_overlaps.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "long_concept",
                "long_hubs",
                "sub_concept",
                "sub_hubs",
                "foreign_hubs",
            ],
        )
        w.writeheader()
        for r in sub_overlap_rows:
            w.writerow(r)

    # inventory_report.md
    total_triggers = sum(1 for r in raw_rows if r["source_field"] == "triggers")
    total_concepts = len(concept_to_hubs)
    overlapping_concepts = sum(1 for h in concept_to_hubs.values() if len(h) >= 2)
    overlap_pct = (overlapping_concepts * 100.0 / total_concepts) if total_concepts else 0.0

    top_overlap = sorted(
        ((c, h) for c, h in concept_to_hubs.items() if len(h) >= 2),
        key=lambda kv: (-len(kv[1]), kv[0]),
    )

    with (OUT / "inventory_report.md").open("w", encoding="utf-8") as f:
        f.write("# Routing Inventory - Corpus-Wide Scan\n\n")
        f.write(f"Generated: {datetime.utcnow().isoformat()}Z\n\n")

        f.write("## Corpus stats\n\n")
        f.write(f"- Hubs in scope: **{len(hub_stats)}**\n")
        f.write(f"- Files scanned (with frontmatter): **{sum(s['files'] for s in hub_stats.values())}**\n")
        f.write(f"- Files scanned total: {files_scanned}\n")
        f.write(f"- Files without frontmatter (skipped): {files_no_frontmatter}\n")
        f.write(f"- Total trigger entries (raw): **{total_triggers}**\n")
        f.write(
            f"- Distinct normalized concepts (triggers + required_tables + sample_questions): "
            f"**{total_concepts}**\n"
        )
        f.write(
            f"- Concepts claimed by >=2 hubs (unmanaged overlap candidates): "
            f"**{overlapping_concepts}** ({overlap_pct:.1f}% of all concepts)\n"
        )
        f.write(
            f"- Substring overlap rows (matcher-false-positive candidates): "
            f"**{len(sub_overlap_rows)}**\n\n"
        )

        f.write("## Per-hub stats\n\n")
        f.write("| Hub | Files | Triggers | Required tables | Sample questions |\n")
        f.write("|---|---:|---:|---:|---:|\n")
        for hub in sorted(hub_stats.keys()):
            s = hub_stats[hub]
            f.write(
                f"| `{hub}` | {s['files']} | {s['triggers']} | "
                f"{s['required_tables']} | {s['sample_questions']} |\n"
            )

        f.write("\n## Top overlap candidates - concepts claimed by >=2 hubs\n\n")
        f.write("Sorted by hub-count desc, then alphabetic. Top 60 shown; full list in concepts.csv.\n\n")
        f.write("| Concept (normalized) | Hubs | Claiming hubs | Source fields | Variants |\n")
        f.write("|---|---:|---|---|---|\n")
        for concept, hubs in top_overlap[:60]:
            variants = sorted(concept_variants[concept])
            fields = sorted(concept_to_fields[concept])
            v_str = "; ".join(variants[:4]) + (" ..." if len(variants) > 4 else "")
            f.write(
                f"| `{concept}` | {len(hubs)} | {', '.join(sorted(hubs))} | "
                f"{', '.join(fields)} | {v_str} |\n"
            )

        f.write("\n## Substring overlap - top 40\n\n")
        f.write(
            "Multi-word concepts that contain another claimed concept as a "
            "sub-span, where the sub-concept is claimed by a hub the long "
            "concept is NOT on. These are the false-positive vectors when a "
            "matcher does substring / n-gram matching.\n\n"
        )
        f.write("| Long concept | Long hub(s) | Sub-concept (exposed) | Sub hub(s) | Foreign hub(s) |\n")
        f.write("|---|---|---|---|---|\n")
        for r in sub_overlap_rows[:40]:
            f.write(
                f"| `{r['long_concept']}` | {r['long_hubs']} | "
                f"`{r['sub_concept']}` | {r['sub_hubs']} | {r['foreign_hubs']} |\n"
            )

    print(f"Wrote inventory to: {OUT}")
    print(f"  raw_triggers.csv:        {len(raw_rows)} rows")
    print(f"  concepts.csv:            {total_concepts} normalized concepts")
    print(f"  substring_overlaps.csv:  {len(sub_overlap_rows)} rows")
    print(f"  inventory_report.md")
    print()
    print(f"Hubs scanned:           {len(hub_stats)}")
    print(f"Files scanned:          {sum(s['files'] for s in hub_stats.values())}")
    print(f"Total trigger entries:  {total_triggers}")
    print(f"Distinct concepts:      {total_concepts}")
    print(f"Overlapping concepts:   {overlapping_concepts} ({overlap_pct:.1f}%)")


if __name__ == "__main__":
    main()
