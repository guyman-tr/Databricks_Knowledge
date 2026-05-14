"""Apply approved DWH judge fixes to wiki source files.

Reads the user-curated ``knowledge/_dwh_judge_review.csv`` and processes only
rows whose ``approve_y_n`` cell is ``Y`` (case-insensitive). For each approved
row:

1. Load the target wiki file (``.md`` or ``.alter.sql``).
2. Locate ``wiki_value`` in the line at ``wiki_line`` (with a small +/- 2 line
   window for resilience to extraction line-number drift).
3. Replace with ``suggested_fix`` (literal substring substitution, never
   regex).
4. Write the patched file back.

After every approved row is applied, the script:

5. Re-runs the deterministic verifier (in-memory) over the patched output and
   refuses to commit any file changes if NEW WRONG verdicts appear.
6. Emits ``knowledge/_dwh_judge_remediation.alter.sql`` containing the
   ALTER statements needed to push the column-comment changes to UC.

If you re-run the script later, set ``approve_y_n`` back to empty on rows
you have already applied -- the script does not track its own history.

Safety rules carried over from the codepoint corruption postmortem:
- Literal substring matching only; never regex.
- If ``wiki_value`` is NOT exactly present in the located line window, the
  row is rejected and logged. The user fixes the CSV and re-runs.
- After all approved patches are tentatively applied, the deterministic
  verifier re-runs on the patched output. If it finds any NEW WRONG row
  (object/column not in the prior violations set), the entire batch is
  discarded.

Usage:
    python tools/dwh_judge/apply_approved.py             # dry-run (default)
    python tools/dwh_judge/apply_approved.py --apply     # actually write
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import subprocess
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
REVIEW_CSV = REPO / "knowledge" / "_dwh_judge_review.csv"
DET_BEFORE_CSV = REPO / "knowledge" / "_dwh_deterministic_violations.csv"
DET_AFTER_TMP_CSV = REPO / "knowledge" / "_dwh_deterministic_violations.after_apply.csv"
REMEDIATION_SQL = REPO / "knowledge" / "_dwh_judge_remediation.alter.sql"
MANUAL_EDITS_MD = REPO / "knowledge" / "_dwh_judge_manual_edits.md"


def _approved(row: dict) -> bool:
    return (row.get("approve_y_n") or "").strip().upper() == "Y"


def _patch_line(text: str, line_no: int, old: str, new: str) -> tuple[str | None, str]:
    """Return (patched_text, note). ``patched_text`` is None when the row
    cannot be applied safely."""
    if not old:
        return None, "empty wiki_value"
    if old == new:
        return None, "wiki_value == suggested_fix; nothing to do"
    lines = text.splitlines(keepends=True)
    # Try the exact line first, then expand to +/- 2 lines.
    candidate_indices = []
    if 1 <= line_no <= len(lines):
        candidate_indices.append(line_no - 1)
    for d in (1, 2):
        for i in (line_no - 1 - d, line_no - 1 + d):
            if 0 <= i < len(lines) and i not in candidate_indices:
                candidate_indices.append(i)
    hits: list[int] = []
    for idx in candidate_indices:
        if old in lines[idx]:
            hits.append(idx)
    if not hits:
        return None, f"wiki_value not found near line {line_no}"
    if len(hits) > 1:
        return None, f"wiki_value ambiguous; matches {len(hits)} lines near {line_no}"
    idx = hits[0]
    line = lines[idx]
    # Literal substring replacement -- one occurrence only.
    new_line = line.replace(old, new, 1)
    if new_line == line:
        return None, "replace produced no change"
    lines[idx] = new_line
    return "".join(lines), f"patched line {idx + 1}: '{old}' -> '{new}'"


def _parse_lines_field(value: str) -> list[int]:
    out: list[int] = []
    for tok in re.split(r"[,\s]+", value or ""):
        tok = tok.strip()
        if not tok:
            continue
        try:
            out.append(int(tok))
        except ValueError:
            pass
    return out


def _apply_substitutions(
    text: str, line_nos: list[int], subs: list[dict],
) -> tuple[str | None, list[str]]:
    """Apply each substitution pair to EVERY listed line (dual-target
    .alter.sql files repeat the same comment at two line numbers; both must
    be patched). Returns (patched_text, notes).

    If a pair cannot be found on ANY of the listed lines, the call fails
    (returns None) so the user can fix the row and re-run.
    """
    notes: list[str] = []
    if not line_nos:
        notes.append("FAIL: no wiki_line(s) provided")
        return None, notes
    for sub in subs:
        old = sub.get("old", "")
        new = sub.get("new", "")
        if not old or old == new:
            notes.append(f"skip '{old}' -> '{new}' (empty or noop)")
            continue
        applied_on_any = False
        per_line_errs: list[str] = []
        for ln in line_nos:
            patched, note = _patch_line(text, ln, old, new)
            if patched is None:
                per_line_errs.append(f"L{ln}: {note}")
                continue
            text = patched
            notes.append(f"L{ln}: '{old}' -> '{new}'")
            applied_on_any = True
        if not applied_on_any:
            notes.append(f"FAIL '{old}' -> '{new}': {'; '.join(per_line_errs)}")
            return None, notes
    return text, notes


def _uc_target_for_alter(text: str) -> str | None:
    m = re.search(r"^--\s*UC Target:\s*(\S+)", text, re.MULTILINE)
    if m:
        return m.group(1).strip().rstrip("`").strip("`")
    m = re.search(r"\bALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN", text, re.IGNORECASE)
    if m:
        return m.group(1).strip("`")
    return None


def _build_remediation_sql(approved_rows: list[dict], file_changes: dict[Path, str]) -> str:
    """Emit ALTER COLUMN COMMENT statements for every approved column-level
    fix in ``.alter.sql`` files. Table-level / md-only fixes are skipped here
    (they are handled by the .md / .alter.sql file edits themselves)."""
    out_lines = [
        "-- =============================================================================",
        "-- DWH Judge remediation script",
        "-- Generated by tools/dwh_judge/apply_approved.py",
        "-- Source: knowledge/_dwh_judge_review.csv  (approve_y_n = Y rows only)",
        "-- This script ONLY contains ALTER COLUMN COMMENT statements derived from",
        "-- patched .alter.sql files. The .md sources have been patched in place by",
        "-- the applier.",
        "-- =============================================================================",
        "",
    ]
    by_file: dict[Path, list[dict]] = defaultdict(list)
    for r in approved_rows:
        wiki_file = (r.get("wiki_file") or "").strip()
        if not wiki_file.endswith(".alter.sql"):
            continue
        if not r.get("column"):
            continue
        by_file[REPO / wiki_file].append(r)

    statements = 0
    for path, rows in by_file.items():
        patched_text = file_changes.get(path)
        if patched_text is None:
            try:
                patched_text = path.read_text(encoding="utf-8")
            except OSError:
                continue
        uc = _uc_target_for_alter(patched_text)
        if uc is None:
            out_lines.append(f"-- WARN: no UC target found in {path.relative_to(REPO)}")
            continue
        seen_cols: set[str] = set()
        for r in rows:
            col = r["column"]
            if col in seen_cols:
                continue
            seen_cols.add(col)
            # Extract the column's CURRENT comment body from the patched text.
            pat = re.compile(
                r"ALTER\s+(?:TABLE|VIEW)\s+" + re.escape(uc) +
                r"\s+ALTER\s+COLUMN\s+`?" + re.escape(col) + r"`?"
                r"\s+COMMENT\s+'((?:[^']|'')*)'\s*;",
                re.IGNORECASE,
            )
            m = pat.search(patched_text)
            if not m:
                out_lines.append(
                    f"-- WARN: could not locate ALTER COLUMN body for {uc}.{col}; "
                    f"skipping remediation statement"
                )
                continue
            body = m.group(1)
            out_lines.append(
                f"ALTER TABLE {uc} ALTER COLUMN {col} COMMENT '{body}';"
            )
            statements += 1
        out_lines.append("")
    out_lines.append(f"-- {statements} ALTER COLUMN COMMENT statements emitted")
    return "\n".join(out_lines) + "\n"


def _re_run_verifier() -> int:
    """Run the deterministic verifier; return its exit code. The verifier
    rewrites the canonical violations CSV in place, so we copy that to a
    temporary location for comparison."""
    cmd = [sys.executable, str(REPO / "tools" / "dwh_judge" / "verify_deterministic.py")]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=120)
    except subprocess.TimeoutExpired:
        print("  [verify] timed out", flush=True)
        return 99
    if proc.returncode != 0:
        print(proc.stdout)
        print(proc.stderr)
    return proc.returncode


def _write_manual_edits_md(rows: list[dict]) -> None:
    """Write a Markdown summary of approved rows whose claim_type is not
    safely auto-patchable (type / nullable / default / fk_ref / lineage_tag).
    The user reviews this file and edits the wikis manually.
    """
    by_file: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        # The aggregated row may carry multiple files in `wiki_file` separated
        # by " | ". Expand so the summary groups by file.
        files = [f.strip() for f in (r.get("wiki_file") or "").split("|")
                 if f.strip()]
        if not files:
            files = [""]
        for wf in files:
            by_file[wf].append(r)

    lines = [
        "# DWH Judge -- manual edits required",
        "",
        "These rows were approved (`approve_y_n = Y`) but cannot be safely",
        "auto-patched (type / nullable / default / fk_ref / lineage_tag).",
        "Edit the listed files by hand using the `truth_value` as guidance.",
        "",
    ]
    for wf in sorted(by_file):
        lines.append(f"## {wf or '(unspecified file)'}")
        lines.append("")
        for r in by_file[wf]:
            lines.append(f"- **{r['object']}.{r['column']}** "
                         f"`{r['claim_type']}` lines={r.get('wiki_line', '')}")
            lines.append(f"  - wiki claims: `{r.get('wiki_value', '')}`")
            lines.append(f"  - truth:       `{r.get('truth_value', '')}`")
            ts = r.get("truth_source", "")
            if ts:
                lines.append(f"  - source: {ts}")
            lines.append("")
    MANUAL_EDITS_MD.write_text("\n".join(lines), encoding="utf-8")


def _violation_set(path: Path) -> set[tuple[str, str, str, str]]:
    if not path.exists():
        return set()
    out = set()
    with path.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            out.add((r.get("object", ""), r.get("column", ""),
                     r.get("claim_type", ""), r.get("wiki_value", "")))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true",
                    help="Actually write changes. Default is dry-run.")
    args = ap.parse_args()

    if not REVIEW_CSV.exists():
        print(f"ERROR: {REVIEW_CSV.relative_to(REPO)} not found. "
              f"Run build_review_csv.py first.")
        sys.exit(1)

    rows = list(csv.DictReader(REVIEW_CSV.open(encoding="utf-8")))
    approved = [r for r in rows if _approved(r)]
    print(f"Review rows total:   {len(rows)}")
    print(f"Approved (Y):        {len(approved)}")
    if not approved:
        print("Nothing to apply. Mark rows with approve_y_n=Y first.")
        return

    # Compute patches per-file in memory.
    file_changes: dict[Path, str] = {}
    skipped: list[tuple[dict, str]] = []
    manual_edits: list[dict] = []

    for r in approved:
        subs_raw = (r.get("substitutions_json") or "").strip()

        # Aggregated row with structured payload.
        if subs_raw:
            try:
                payload = json.loads(subs_raw)
            except json.JSONDecodeError as e:
                skipped.append((r, f"bad substitutions_json: {e}"))
                continue

            # Structural / informational rows: applier doesn't auto-patch.
            if isinstance(payload, dict) and payload.get("applier_strategy") == "manual-edit":
                manual_edits.append(r)
                continue

            wiki_file = (r.get("wiki_file") or "").strip()
            if not wiki_file or " | " in wiki_file:
                # Codepoint aggregation is single-file by design.
                skipped.append((r, f"unexpected multi-file codepoint row: {wiki_file}"))
                continue
            path = REPO / wiki_file
            if not path.exists():
                skipped.append((r, "file missing"))
                continue
            text = file_changes.get(path)
            if text is None:
                try:
                    text = path.read_text(encoding="utf-8")
                except OSError as e:
                    skipped.append((r, f"read error: {e}"))
                    continue
            subs = payload if isinstance(payload, list) else []
            line_nos = _parse_lines_field(r.get("wiki_line", ""))
            patched, notes = _apply_substitutions(text, line_nos, subs)
            if patched is None:
                skipped.append((r, " | ".join(notes)))
                continue
            file_changes[path] = patched
            continue

        # Single-substring row (LLM description).
        wiki_file = (r.get("wiki_file") or "").strip()
        if not wiki_file:
            skipped.append((r, "empty wiki_file"))
            continue
        path = REPO / wiki_file
        if not path.exists():
            skipped.append((r, "file missing"))
            continue
        text = file_changes.get(path)
        if text is None:
            try:
                text = path.read_text(encoding="utf-8")
            except OSError as e:
                skipped.append((r, f"read error: {e}"))
                continue
        try:
            line_no = int((r.get("wiki_line") or "0").split(",")[0])
        except ValueError:
            skipped.append((r, "non-integer wiki_line"))
            continue
        old = r.get("wiki_value", "")
        new = r.get("suggested_fix", "") or r.get("truth_value", "")
        patched, note = _patch_line(text, line_no, old, new)
        if patched is None:
            skipped.append((r, note))
            continue
        file_changes[path] = patched

    print(f"Files to patch:        {len(file_changes)}")
    print(f"Manual-edit rows:      {len(manual_edits)}")
    print(f"Rows skipped (errors): {len(skipped)}")
    if skipped:
        print("\n--- Skipped rows (errors) ---")
        for r, note in skipped[:25]:
            print(f"  {r['object']}.{r['column']} ({r['claim_type']}) "
                  f"in {r['wiki_file']}:{r['wiki_line']}: {note}")
        if len(skipped) > 25:
            print(f"  ... and {len(skipped) - 25} more")

    if manual_edits:
        _write_manual_edits_md(manual_edits)
        print(f"\nWrote {MANUAL_EDITS_MD.relative_to(REPO)} "
              f"({len(manual_edits)} rows needing manual editing)")

    if not args.apply:
        print("\nDRY-RUN: no files written. Re-run with --apply to commit.")
        return

    if not file_changes:
        print("No patches to apply.")
        return

    # Snapshot the pre-apply violation set.
    before = _violation_set(DET_BEFORE_CSV)

    for path, new_text in file_changes.items():
        path.write_text(new_text, encoding="utf-8")
        print(f"  Wrote {path.relative_to(REPO)}")

    # Re-extract claims and re-verify.
    extract_cmd = [sys.executable, str(REPO / "tools" / "dwh_judge" / "extract_wiki_claims.py")]
    print("\nRe-extracting claims...")
    proc = subprocess.run(extract_cmd, capture_output=True, text=True,
                          encoding="utf-8", errors="replace", timeout=120)
    if proc.returncode != 0:
        print(proc.stdout); print(proc.stderr)
        print("ERROR: extract_wiki_claims failed; manual inspection required.")
        sys.exit(2)

    print("Re-verifying deterministic claims...")
    rc = _re_run_verifier()
    if rc != 0:
        print("ERROR: verifier returned non-zero; manual inspection required.")
        sys.exit(3)

    after = _violation_set(DET_BEFORE_CSV)
    # New violations = after - before
    new_violations = after - before
    if new_violations:
        print("\nNEW deterministic violations detected after applying patches:")
        for v in sorted(new_violations)[:20]:
            print(f"  {v}")
        print("\nThe applier introduced regressions. Revert and inspect.")
        sys.exit(4)

    remediation = _build_remediation_sql(approved, file_changes)
    REMEDIATION_SQL.write_text(remediation, encoding="utf-8")
    print(f"\nWrote {REMEDIATION_SQL.relative_to(REPO)}")
    print("Next step: deploy with tools/redeploy_schema.py (--files <remediation_sql>)")


if __name__ == "__main__":
    main()
