"""
Rewrite the front-matter `primary_objects:` block in every skill that
references Synapse-named objects, replacing each entry with its
Unity-Catalog-qualified equivalent (or moving it to `synapse_only_objects:`
when the object is not queryable in UC).

Inputs:
  knowledge/skills/_uc_object_map.json  (produced by build_uc_object_map.py)

Per skill we:
  1. Locate the `primary_objects:` YAML block in front-matter.
  2. For each `- ref` line, replace `ref` with the UC FQN where one exists,
     prefixing the original comment (if any) with `<TYPE> | Synapse: <ref>`.
  3. Move any ref whose status is `not_migrated`, `synapse_only_no_uc`, or
     `unknown` (live-validation needed) to a new `synapse_only_objects:`
     block, marked with the reason.
  4. Drop refs whose status is `non_existent` or `deprecated_old_ddr` (with
     a `# REMOVED:` audit comment so the human reviewer can spot it).
  5. If `qa_only_objects:` already exists with such refs, also rewrite it.

Backups (`<file>.uc-rewrite.bak`) are written before the in-place edit.
"""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SKILLS_DIR = REPO / "knowledge" / "skills"
MAP_PATH = SKILLS_DIR / "_uc_object_map.json"


# Strip leading `main.` for compactness in some places? No — keep `main.` so
# Genie can use the FQN literally.
def fmt_uc(uc: str) -> str:
    return uc


REF_LINE_RE = re.compile(
    r'^(?P<lead>\s*-\s+)["\']?'
    r'(?P<ref>[A-Za-z_][\w]*\.[A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)?)'
    r'["\']?(?P<rest>.*)$'
)


def split_comment(rest: str) -> tuple[str, str]:
    """Return (pre_comment, comment_text). Strip trailing quote if present."""
    rest = rest.rstrip()
    # Anything after `#` is a comment, preserve as-is.
    m = re.match(r'^(?P<pre>[^#]*)#\s*(?P<c>.*)$', rest)
    if not m:
        return rest, ""
    return m.group("pre"), m.group("c").strip()


def rewrite_block(lines: list[str], start_idx: int, end_idx: int,
                  resolutions: dict, kind: str) -> tuple[list[str], list[str], list[str]]:
    """Process `primary_objects:` body lines (between but excluding the key
    line and the next non-block line). Returns (new_primary_lines,
    synapse_only_lines, removed_audit_lines).
    """
    new_primary: list[str] = []
    synapse_only: list[str] = []
    removed_audit: list[str] = []

    for i in range(start_idx, end_idx):
        line = lines[i]
        m = REF_LINE_RE.match(line)
        if not m:
            # Pass-through (blank line, comment-only line, etc.)
            new_primary.append(line)
            continue
        ref = m.group("ref")
        lead = m.group("lead")
        rest = m.group("rest")
        pre, original_comment = split_comment(rest)
        rec = resolutions.get(ref)
        if rec is None:
            # Couldn't resolve — preserve as-is (shouldn't happen).
            new_primary.append(line)
            continue
        status = rec.get("uc_status", "unknown")
        uc_target = rec.get("uc_target")
        uc_type = rec.get("uc_object_type") or ""
        # Prefer the explicit type; fall back to heuristics.
        if not uc_type and status == "deployed_prod":
            uc_type = "TABLE"
        if not uc_type and status == "deployed_view_alias":
            uc_type = "VIEW"

        if status in ("non_existent", "deprecated_old_ddr"):
            # Drop, but record an audit comment.
            removed_audit.append(f"# REMOVED on UC validation: `{ref}` ({status}). {rec.get('note','')}")
            continue

        if status in ("deployed", "deployed_prod", "deployed_view_alias",
                      "uc_native", "uc_native_inferred"):
            target = fmt_uc(uc_target or ref)
            comment_parts = []
            if uc_type:
                comment_parts.append(uc_type)
            comment_parts.append(f"Synapse: {ref}")
            if original_comment:
                comment_parts.append(original_comment)
            new_comment = "  # " + " | ".join(comment_parts)
            new_line = f"{lead}{target}{new_comment}"
            new_primary.append(new_line)
            continue

        # not_migrated / synapse_only_no_uc / unknown -> move to synapse_only
        reason = {
            "not_migrated": "alter.sql says _Not_Migrated",
            "synapse_only_no_uc": "wiki only; never ingested",
            "unknown": "live UC validation needed",
        }.get(status, status)
        view_alias = rec.get("uc_view_alias")
        if view_alias:
            # If a view alias exists, prefer the view in primary instead.
            comment_parts = ["VIEW", f"Synapse: {ref}", f"alias for {ref}"]
            if original_comment:
                comment_parts.append(original_comment)
            new_primary.append(f"{lead}{view_alias}  # " + " | ".join(comment_parts))
        else:
            extra = f" ({reason})"
            if original_comment:
                extra = f" ({reason}; {original_comment})"
            synapse_only.append(f"  - \"{ref}{extra}\"")

    return new_primary, synapse_only, removed_audit


def find_block(lines: list[str], key: str) -> tuple[int, int] | None:
    """Find a top-level YAML block named `<key>:` inside the front-matter.

    Returns (body_start, body_end) where body_start is the first body line
    and body_end is the index of the next non-block line (exclusive).
    """
    in_fm = False
    fm_start = -1
    fm_end = -1
    for i, l in enumerate(lines):
        if l.strip() == "---":
            if not in_fm:
                in_fm = True
                fm_start = i
            else:
                fm_end = i
                break
    if fm_end < 0:
        return None
    # Within (fm_start+1, fm_end-1)
    key_line = -1
    for i in range(fm_start + 1, fm_end):
        if lines[i].rstrip() == f"{key}:" or lines[i].rstrip().startswith(f"{key}:"):
            # Only top-level (no leading whitespace).
            if not lines[i][:1].isspace():
                key_line = i
                break
    if key_line < 0:
        return None
    body_start = key_line + 1
    body_end = body_start
    for j in range(body_start, fm_end):
        ln = lines[j]
        if not ln.strip():
            body_end = j + 1
            continue
        if ln[0].isspace():
            body_end = j + 1
        else:
            break
    return (body_start, body_end)


def find_fm_end(lines: list[str]) -> int:
    """Return index of closing `---` of the front-matter, or -1."""
    seen_open = False
    for i, l in enumerate(lines):
        if l.strip() == "---":
            if not seen_open:
                seen_open = True
                continue
            return i
    return -1


def upsert_block(lines: list[str], key: str, body_lines: list[str], audit_lines: list[str]) -> list[str]:
    """Replace or insert `key:` block in front-matter. Audit lines are
    appended after the closing `---` so the diff is visible."""
    blk = find_block(lines, key)
    new_block = [f"{key}:\n"] + [bl + "\n" if not bl.endswith("\n") else bl for bl in body_lines]
    if blk:
        body_start, body_end = blk
        # Replace from key line (body_start - 1) through body_end-1
        return lines[:body_start - 1] + new_block + lines[body_end:]
    else:
        # Insert before closing ---
        end = find_fm_end(lines)
        if end < 0:
            return lines
        return lines[:end] + new_block + lines[end:]


def main() -> None:
    if not MAP_PATH.exists():
        raise SystemExit("Run tools/skills/build_uc_object_map.py first.")
    data = json.loads(MAP_PATH.read_text(encoding="utf-8"))
    resolutions: dict[str, dict] = data["objects"]
    by_skill: dict[str, list[dict]] = data["by_skill"]

    edits = 0
    for skill_path_str, items in sorted(by_skill.items()):
        skill_path = REPO / skill_path_str
        if not skill_path.exists():
            continue
        text = skill_path.read_text(encoding="utf-8")
        lines = text.splitlines(keepends=True)

        any_change = False
        all_new_primary: list[str] = []
        all_synapse_only: list[str] = []
        all_removed: list[str] = []

        for key in ("primary_objects", "qa_only_objects"):
            blk = find_block(lines, key)
            if not blk:
                continue
            body_start, body_end = blk
            new_primary, synapse_only, removed = rewrite_block(
                lines, body_start, body_end, resolutions, key
            )
            # Compare original block content
            original_block = "".join(lines[body_start:body_end])
            new_block = "".join(l if l.endswith("\n") else l + "\n" for l in new_primary)
            if new_block.strip() == original_block.strip() and not synapse_only and not removed:
                continue
            any_change = True
            # Replace this block in lines
            lines = (
                lines[:body_start]
                + [l if l.endswith("\n") else l + "\n" for l in new_primary]
                + lines[body_end:]
            )
            all_synapse_only.extend(synapse_only)
            all_removed.extend(removed)

        if all_synapse_only:
            # Merge with any existing synapse_only_objects block
            existing = find_block(lines, "synapse_only_objects")
            existing_lines: list[str] = []
            if existing:
                bs, be = existing
                existing_lines = [l.rstrip("\n") for l in lines[bs:be] if l.strip()]
            merged = existing_lines + all_synapse_only
            # de-dupe while preserving order
            seen: set[str] = set()
            deduped = []
            for ml in merged:
                key = ml.strip()
                if key in seen:
                    continue
                seen.add(key)
                deduped.append(ml)
            lines = upsert_block(lines, "synapse_only_objects", deduped, [])
            any_change = True

        if all_removed:
            # Append audit lines after closing front-matter ---
            end = find_fm_end(lines)
            if end >= 0:
                audit_text = "\n<!--\nUC validation audit (auto-generated by tools/skills/apply_uc_object_map.py):\n"
                audit_text += "\n".join(all_removed) + "\n-->\n\n"
                lines = lines[: end + 1] + [audit_text] + lines[end + 1:]
                any_change = True

        if any_change:
            backup = skill_path.with_suffix(skill_path.suffix + ".uc-rewrite.bak")
            if not backup.exists():
                shutil.copyfile(skill_path, backup)
            skill_path.write_text("".join(lines), encoding="utf-8")
            print(f"  edited {skill_path.relative_to(REPO)} "
                  f"(synapse_only={len(all_synapse_only)} removed={len(all_removed)})")
            edits += 1

    print(f"\nDone. {edits} skill files edited.")


if __name__ == "__main__":
    main()
