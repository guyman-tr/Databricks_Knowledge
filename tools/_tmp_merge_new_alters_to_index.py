"""Merge newly created .alter.sql files into existing _deploy-index.md without
clobbering Deployed/Failed status of existing rows.

Logic:
1. Read existing index, capture the set of objects already tracked.
2. For each .alter.sql on disk, decide if it's new (not in index).
3. If new and not stub-only, insert as `Generated` row in the appropriate
   ## section (Tables / Views / Functions).
4. Recount frontmatter counters from the new row set.
5. Write back.
"""
from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"

ROW_RE = re.compile(
    r"^\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|\s*([^|]+?)\s*\|\s*$"
)
SECTION_RE = re.compile(r"^##\s+(Tables|Views|Functions)\s+\((\d+)\)\s*$")
HEADER_RE = re.compile(r"^\|\s*Object\s*\|\s*Deploy status\s*\|", re.IGNORECASE)


def is_stub(path: Path) -> bool:
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        u = s.upper()
        if u.startswith("ALTER TABLE") or u.startswith("ALTER VIEW") or u.startswith("COMMENT ON"):
            return False
    return True


def collect_new_alter_stems(schema_dir: Path) -> dict[str, list[tuple[str, bool]]]:
    """Return {folder: [(stem, stub)]}. Only includes alter files."""
    out: dict[str, list[tuple[str, bool]]] = {}
    for folder in ("Tables", "Views", "Functions"):
        d = schema_dir / folder
        if not d.is_dir():
            continue
        items: list[tuple[str, bool]] = []
        for p in sorted(d.glob("*.alter.sql")):
            if ".downstream." in p.name:
                continue
            items.append((p.name.removesuffix(".alter.sql"), is_stub(p)))
        if items:
            out[folder] = items
    return out


def parse_existing_index(text: str, schema: str) -> dict[str, dict[str, str]]:
    """Return {folder: {stem: status}}."""
    out: dict[str, dict[str, str]] = {"Tables": {}, "Views": {}, "Functions": {}}
    current_folder: str | None = None
    for line in text.splitlines():
        sm = SECTION_RE.match(line.strip())
        if sm:
            current_folder = sm.group(1)
            continue
        if not current_folder:
            continue
        m = ROW_RE.match(line)
        if not m:
            continue
        link_text, link_target, status = m.group(1), m.group(2), m.group(3).strip()
        if not link_text.startswith(f"{schema}."):
            continue
        stem = link_text[len(schema) + 1 :]
        out[current_folder][stem] = status
    return out


def merge_one(schema: str, *, dry_run: bool = False) -> dict:
    schema_dir = WIKI_ROOT / schema
    idx = schema_dir / "_deploy-index.md"
    if not idx.exists():
        return {"schema": schema, "skipped": "no _deploy-index.md", "added": 0, "flipped": 0}

    text = idx.read_text(encoding="utf-8")
    existing = parse_existing_index(text, schema)
    new_alters = collect_new_alter_stems(schema_dir)

    # Build update plan:
    #   additions: rows to insert (not in index yet)
    #   flips: rows to relabel (Pending or Stub-only when a deployable alter exists now)
    additions: dict[str, list[tuple[str, str]]] = {}
    flips: dict[tuple[str, str], str] = {}  # (folder, stem) -> new_status

    for folder, items in new_alters.items():
        for stem, stub in items:
            cur = existing.get(folder, {}).get(stem)
            new_status = "Stub only" if stub else "Generated"
            if cur is None:
                additions.setdefault(folder, []).append((stem, new_status))
            else:
                cur_lc = cur.lower()
                # Don't disturb Deployed / Failed rows.
                if cur_lc.startswith("deployed") or cur_lc.startswith("failed"):
                    continue
                # Flip Pending / Stub-only / etc. to Generated when a real alter exists.
                if not stub and not cur_lc.startswith("generated"):
                    flips[(folder, stem)] = "Generated"

    n_added = sum(len(v) for v in additions.values())
    n_flipped = len(flips)
    if n_added == 0 and n_flipped == 0:
        return {"schema": schema, "added": 0, "flipped": 0}

    # Splice rows into each folder's section + apply flips on existing rows.
    lines = text.splitlines()
    out_lines: list[str] = []
    i = 0
    current_folder: str | None = None
    section_header_emitted = False
    while i < len(lines):
        line = lines[i]
        sm = SECTION_RE.match(line.strip())
        if sm:
            current_folder = sm.group(1)
            section_header_emitted = False
            existing_n = sum(1 for _ in existing.get(current_folder, {})) if current_folder else 0
            new_n = existing_n + len(additions.get(current_folder, []))
            out_lines.append(f"## {current_folder} ({new_n})")
            i += 1
            continue
        if current_folder and HEADER_RE.match(line.strip()):
            out_lines.append(line)
            i += 1
            if i < len(lines) and lines[i].strip().startswith("|---"):
                out_lines.append(lines[i])
                i += 1
            section_header_emitted = True
            continue

        # Apply flips on existing rows in the current folder.
        if current_folder and section_header_emitted:
            row_m = ROW_RE.match(line)
            if row_m:
                link_text = row_m.group(1)
                if link_text.startswith(f"{schema}."):
                    stem = link_text[len(schema) + 1 :]
                    if (current_folder, stem) in flips:
                        new_status = flips[(current_folder, stem)]
                        link_target = row_m.group(2)
                        out_lines.append(
                            f"| [{link_text}]({link_target}) | {new_status} |"
                        )
                        i += 1
                        continue

        # End of a section (next ## or EOF)
        is_blank_or_section = (
            line.strip() == "" or line.strip().startswith("## ")
        ) and current_folder is not None
        # If we're transitioning out of the current section, append additions first.
        if is_blank_or_section and section_header_emitted and additions.get(current_folder):
            for stem, status in sorted(additions[current_folder], key=lambda x: x[0].lower()):
                out_lines.append(
                    f"| [{schema}.{stem}]({current_folder}/{stem}.md) | {status} |"
                )
            section_header_emitted = False
            additions[current_folder] = []  # consumed
        out_lines.append(line)
        i += 1

    # Append any folders that had additions but no existing section yet.
    for folder, adds in additions.items():
        if not adds:
            continue
        out_lines.append("")
        out_lines.append(f"## {folder} ({len(adds)})")
        out_lines.append("")
        out_lines.append("| Object | Deploy status |")
        out_lines.append("|--------|---------------|")
        for stem, status in sorted(adds, key=lambda x: x[0].lower()):
            out_lines.append(f"| [{schema}.{stem}]({folder}/{stem}.md) | {status} |")
        out_lines.append("")

    new_text = "\n".join(out_lines)

    # Recount frontmatter from the merged content.
    g = d = f = stub = 0
    for ln in out_lines:
        m = ROW_RE.match(ln)
        if not m:
            continue
        if not m.group(1).startswith(f"{schema}."):
            continue
        s = m.group(3).strip()
        if s.startswith("Deployed"):
            d += 1
        elif s.startswith("Failed"):
            f += 1
        elif s.startswith("Stub"):
            stub += 1
        else:
            g += 1
    total = g + d + f + stub
    ts = date.today().isoformat()

    new_text = re.sub(r"^total_deployable:\s*\d+", f"total_deployable: {total}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r"^generated:\s*\d+", f"generated: {g}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r"^deployed:\s*\d+", f"deployed: {d}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r"^failed:\s*\d+", f"failed: {f}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r"^stub_only:\s*\d+", f"stub_only: {stub}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r'^last_updated:\s*"[^"]*"', f'last_updated: "{ts}"', new_text, count=1, flags=re.MULTILINE)

    if not dry_run:
        idx.write_text(new_text, encoding="utf-8")
    return {
        "schema": schema,
        "added": n_added,
        "flipped": n_flipped,
        "totals": {"deployed": d, "generated": g, "failed": f, "stub_only": stub, "total": total},
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schemas", nargs="+", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    for s in args.schemas:
        r = merge_one(s, dry_run=args.dry_run)
        print(r)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
