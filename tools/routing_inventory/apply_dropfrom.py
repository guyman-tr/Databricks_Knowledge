"""Phase 4 - apply ledger drop_from to the skill corpus.

For each row in tools/routing_inventory/ledger.csv with a non-empty `drop_from`:
    For each hub listed in drop_from:
        For each .md file in knowledge/skills/<hub>/:
            Remove every trigger line in the YAML frontmatter that normalizes
            to the concept value.

Edits are line-based on the frontmatter `triggers:` block to preserve all
other YAML formatting and comments. The script supports two modes:

    --dry-run     Default. Reports proposed edits without modifying files.
    --apply       Performs the edits in-place.

Outputs in audits/_phase4_trigger_cleanup_<ts>/:
    edits.csv               One row per (file, trigger removed, normalized concept).
    summary.md              Aggregate report: per-hub / per-super_concept stats.
    file_diffs.md           Per-file before/after trigger lists.
    warnings.md             Drop_from entries that didn't find a match;
                            files whose triggers list became empty.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

import yaml


REPO = Path(__file__).resolve().parents[2]
LEDGER_CSV = Path(__file__).parent / "ledger.csv"
SKILLS_DIR = REPO / "knowledge" / "skills"
PUNCT_RE = re.compile(r"[^\w\s\-]")
WS_RE = re.compile(r"\s+")


def normalize(s: str) -> str:
    s = str(s).lower().strip()
    s = PUNCT_RE.sub(" ", s)
    s = WS_RE.sub(" ", s).strip()
    return s


def parse_frontmatter_bounds(text: str) -> tuple[int, int] | None:
    """Return (start_line_idx_after_first_dashes, end_line_idx_of_closing_dashes)
    indices in the line array; or None if no frontmatter.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            return 1, i
    return None


def find_triggers_block(lines: list[str], fm_start: int, fm_end: int) -> tuple[int, int, str] | None:
    """Return (first_line_idx, last_line_idx_exclusive, style) covering the
    `triggers:` block. `style` is 'block' for `- item` form or 'flow' for
    `[a, b]` form. Returns None if absent or empty.
    """
    for i in range(fm_start, fm_end):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("triggers:"):
            after_colon = stripped[len("triggers:"):].strip()
            if after_colon.startswith("["):
                # flow style; consume until matching ]
                bracket_depth = 0
                for j in range(i, fm_end):
                    bracket_depth += lines[j].count("[")
                    bracket_depth -= lines[j].count("]")
                    if bracket_depth == 0:
                        return i, j + 1, "flow"
                return i, fm_end, "flow"
            if after_colon == "[]":
                return None
            if after_colon and after_colon != "":
                # `triggers: foo` - single scalar; not a list. Skip.
                return None
            # block style; consume `- item` lines below
            block_start = i
            block_end = i + 1
            for j in range(i + 1, fm_end):
                line_j = lines[j]
                stripped_j = line_j.strip()
                if line_j.startswith("  - ") or line_j.startswith("- "):
                    block_end = j + 1
                    continue
                if not stripped_j:
                    block_end = j + 1
                    continue
                break
            return block_start, block_end, "block"
    return None


def extract_trigger_value(line: str) -> str | None:
    """Extract the trigger value from a `  - <value>` line. Returns None for
    non-item lines (key line, blank).
    """
    stripped = line.lstrip()
    if not stripped.startswith("- "):
        return None
    value = stripped[2:].strip()
    if value.startswith(("'", '"')) and value.endswith(value[0]):
        value = value[1:-1]
    return value


def _edit_block(
    lines: list[str], tb_start: int, tb_end: int, concepts_to_drop: set[str]
) -> tuple[list[str], list[dict], int]:
    edits: list[dict] = []
    kept: list[str] = []
    triggers_before = 0
    for i in range(tb_start, tb_end):
        line = lines[i]
        val = extract_trigger_value(line)
        if val is None:
            kept.append(line)
            continue
        triggers_before += 1
        if normalize(val) in concepts_to_drop:
            edits.append({"trigger_raw": val, "normalized": normalize(val)})
            continue
        kept.append(line)
    return kept, edits, triggers_before


def _edit_flow(
    lines: list[str], tb_start: int, tb_end: int, concepts_to_drop: set[str]
) -> tuple[list[str], list[dict], int]:
    """Edit a flow-style `triggers: [a, b, c]` (possibly multi-line). We parse
    the YAML, filter, and re-emit as flow-style on a single line (the
    multi-line wrapping is whitespace-only and not preserved)."""
    block_text = "\n".join(lines[tb_start:tb_end])
    # safe_load of "triggers: [a, b]" returns {"triggers": ["a", "b"]}
    try:
        parsed = yaml.safe_load(block_text)
    except yaml.YAMLError:
        return lines[tb_start:tb_end], [], 0
    if not isinstance(parsed, dict) or "triggers" not in parsed:
        return lines[tb_start:tb_end], [], 0
    triggers = parsed["triggers"] or []
    if not isinstance(triggers, list):
        return lines[tb_start:tb_end], [], 0

    edits: list[dict] = []
    kept_triggers: list[str] = []
    triggers_before = len(triggers)
    for t in triggers:
        if normalize(str(t)) in concepts_to_drop:
            edits.append({"trigger_raw": str(t), "normalized": normalize(str(t))})
            continue
        kept_triggers.append(str(t))

    # Re-emit as flow style on a single line. Quote items that need it.
    def _quote(s: str) -> str:
        needs_quote = any(c in s for c in [",", "[", "]", "{", "}", "#", ":", "'", '"'])
        if needs_quote or s != s.strip():
            return '"' + s.replace('"', '\\"') + '"'
        return s

    if kept_triggers:
        new_line = "triggers: [" + ", ".join(_quote(t) for t in kept_triggers) + "]"
    else:
        new_line = "triggers: []"
    return [new_line], edits, triggers_before


def edit_file(
    file_path: Path,
    concepts_to_drop: set[str],
    apply: bool,
) -> tuple[list[dict], int, int]:
    """Returns (edits, triggers_before, triggers_after). Edits is a list of
    {"trigger_raw": str, "normalized": str} dicts."""
    text = file_path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=False)
    bounds = parse_frontmatter_bounds(text)
    if bounds is None:
        return [], 0, 0
    fm_start, fm_end = bounds
    tb = find_triggers_block(lines, fm_start, fm_end)
    if tb is None:
        return [], 0, 0
    tb_start, tb_end, style = tb

    if style == "flow":
        kept_block, edits, triggers_before = _edit_flow(lines, tb_start, tb_end, concepts_to_drop)
    else:
        kept_block, edits, triggers_before = _edit_block(lines, tb_start, tb_end, concepts_to_drop)

    if not edits:
        return [], triggers_before, triggers_before

    new_lines = lines[:tb_start] + kept_block + lines[tb_end:]

    if apply:
        new_text = "\n".join(new_lines)
        if text.endswith("\n"):
            new_text += "\n"
        file_path.write_text(new_text, encoding="utf-8")
    triggers_after = triggers_before - len(edits)
    return edits, triggers_before, triggers_after


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true", help="Modify files in place (default: dry-run)")
    args = p.parse_args(argv)

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"Mode: {mode}")

    # Build {hub: {normalized_concept_to_drop -> (super_concept, primary_owner)}}
    hub_drops: dict[str, dict[str, tuple[str, str]]] = defaultdict(dict)
    ledger_rows: list[dict] = []
    with LEDGER_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            ledger_rows.append(r)
            drop_from = (r.get("drop_from") or "").strip()
            if not drop_from:
                continue
            for hub in drop_from.split("; "):
                hub = hub.strip()
                if not hub:
                    continue
                hub_drops[hub][r["concept"]] = (r["super_concept"], r["primary_owner"])

    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_dir = REPO / "audits" / f"_phase4_trigger_cleanup_{ts}"
    out_dir.mkdir(parents=True, exist_ok=True)

    all_edits: list[dict] = []
    files_emptied: list[str] = []
    matched_concepts_per_hub: dict[str, set[str]] = defaultdict(set)
    per_file_before: dict[str, int] = {}
    per_file_after: dict[str, int] = {}

    for hub in sorted(hub_drops):
        concepts = set(hub_drops[hub].keys())
        hub_dir = SKILLS_DIR / hub
        if not hub_dir.is_dir():
            print(f"WARN: hub directory missing: {hub_dir}")
            continue
        for md in sorted(hub_dir.rglob("*.md")):
            edits, before, after = edit_file(md, concepts, apply=args.apply)
            rel = str(md.relative_to(REPO)).replace("\\", "/")
            if before > 0:
                per_file_before[rel] = before
                per_file_after[rel] = after
            for e in edits:
                sc, primary = hub_drops[hub][e["normalized"]]
                all_edits.append({
                    "file": rel,
                    "hub": hub,
                    "trigger_raw": e["trigger_raw"],
                    "normalized": e["normalized"],
                    "super_concept": sc,
                    "primary_owner": primary,
                })
                matched_concepts_per_hub[hub].add(e["normalized"])
            if before > 0 and after == 0 and edits:
                files_emptied.append(rel)

    # warnings: drop_from entries that didn't match anything in any file of that hub
    unmatched_warnings: list[tuple[str, str]] = []
    for hub, concepts in hub_drops.items():
        matched = matched_concepts_per_hub.get(hub, set())
        for c in concepts:
            if c not in matched:
                unmatched_warnings.append((hub, c))

    # write edits.csv
    edits_csv = out_dir / "edits.csv"
    with edits_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["super_concept", "primary_owner", "hub", "file", "trigger_raw", "normalized"])
        w.writeheader()
        for e in sorted(all_edits, key=lambda r: (r["super_concept"], r["hub"], r["file"], r["normalized"])):
            w.writerow(e)

    # summary.md
    super_concept_counts: dict[str, int] = defaultdict(int)
    hub_counts: dict[str, int] = defaultdict(int)
    for e in all_edits:
        super_concept_counts[e["super_concept"]] += 1
        hub_counts[e["hub"]] += 1

    summary_md = out_dir / "summary.md"
    with summary_md.open("w", encoding="utf-8") as f:
        f.write(f"# Phase 4 trigger cleanup - {mode}\n\n")
        f.write(f"Generated: {datetime.utcnow().isoformat()}Z\n\n")
        f.write(f"- Total trigger removals: **{len(all_edits)}**\n")
        f.write(f"- Files touched: **{len({e['file'] for e in all_edits})}**\n")
        f.write(f"- Hubs touched: **{len({e['hub'] for e in all_edits})}**\n")
        f.write(f"- Files emptied (triggers became []): **{len(files_emptied)}**\n")
        f.write(f"- Unmatched drop_from entries: **{len(unmatched_warnings)}**\n\n")

        f.write("## Removals per super-concept family\n\n")
        f.write("| Super-concept | Removals |\n|---|---:|\n")
        for sc in sorted(super_concept_counts, key=lambda k: -super_concept_counts[k]):
            f.write(f"| `{sc}` | {super_concept_counts[sc]} |\n")
        f.write("\n")

        f.write("## Removals per hub\n\n")
        f.write("| Hub | Removals |\n|---|---:|\n")
        for h in sorted(hub_counts, key=lambda k: -hub_counts[k]):
            f.write(f"| `{h}` | {hub_counts[h]} |\n")

    # file_diffs.md
    diffs_md = out_dir / "file_diffs.md"
    with diffs_md.open("w", encoding="utf-8") as f:
        f.write(f"# Phase 4 per-file trigger removals - {mode}\n\n")
        by_file: dict[str, list[dict]] = defaultdict(list)
        for e in all_edits:
            by_file[e["file"]].append(e)
        for file_rel in sorted(by_file):
            f.write(f"### `{file_rel}`\n\n")
            before = per_file_before.get(file_rel, 0)
            after = per_file_after.get(file_rel, 0)
            f.write(f"Triggers: {before} -> {after}  (removed {before-after})\n\n")
            f.write("Removed:\n")
            for e in sorted(by_file[file_rel], key=lambda r: r["normalized"]):
                f.write(f"- `{e['trigger_raw']}`  ({e['super_concept']}, primary: `{e['primary_owner']}`)\n")
            f.write("\n")

    # warnings.md
    warn_md = out_dir / "warnings.md"
    with warn_md.open("w", encoding="utf-8") as f:
        f.write(f"# Phase 4 warnings - {mode}\n\n")
        f.write(f"## Files emptied ({len(files_emptied)})\n\n")
        f.write("Files where the triggers list dropped to size 0 after removals.\n")
        f.write("These hubs will be unroutable until someone adds replacement triggers.\n\n")
        for fr in sorted(files_emptied):
            f.write(f"- `{fr}`\n")
        f.write("\n")

        f.write(f"## Unmatched drop_from entries ({len(unmatched_warnings)})\n\n")
        f.write(
            "Ledger entries where drop_from listed a hub but no file in that hub\n"
            "had the concept as a literal trigger. Most likely cause: the concept\n"
            "appeared in required_tables or sample_questions in that hub (NOT in\n"
            "triggers), and the inventory flagged it because we scanned all three\n"
            "fields. No edit needed.\n\n"
        )
        f.write("| Hub | Concept |\n|---|---|\n")
        for hub, concept in sorted(unmatched_warnings):
            f.write(f"| `{hub}` | `{concept}` |\n")

    print(f"\nWrote outputs to: {out_dir}")
    print(f"  Total trigger removals: {len(all_edits)}")
    print(f"  Files touched:          {len({e['file'] for e in all_edits})}")
    print(f"  Hubs touched:           {len({e['hub'] for e in all_edits})}")
    print(f"  Files emptied:          {len(files_emptied)}")
    print(f"  Unmatched drops:        {len(unmatched_warnings)}")
    if args.apply:
        print("\nFiles modified in place. Re-run scan.py to verify overlap delta.")
    else:
        print("\nDry-run. Re-run with --apply to perform edits.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
