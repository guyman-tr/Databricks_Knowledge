#!/usr/bin/env python3
"""
compact_audits.py - shrink audits/regen-sample/ by dropping redundant artifacts
                    from objects that have a PASS verdict.

Premise: by the time a wiki is promoted to the live tree, the regen audit
trail contains massive redundancy:
  - regen/final/ is a verbatim copy of the best regen/attempt_N/
  - regen/final/writer_raw_stream.jsonl can be 50-300 KB of raw LLM tokens
  - regen/final/judge_raw_stream.jsonl adds another 15-65 KB of LLM tokens
  - regen/_upstream_bundle.md (often 50-100 KB) is reproducible from preload
  - the attempt_N/ dirs themselves are obsolete once their winner lives in final/

Real measurement on the BI_DB_dbo sample (75 completed objects, 98.6 MB total):
  writer_raw_stream.jsonl   45.2 MB across 171 files
  writer_prompt.md          19.8 MB across 171 files
  judge_raw_stream.jsonl    14.6 MB across 226 files
  _upstream_bundle.md        7.5 MB across  75 files

Compaction strategy (per object, applied only when there's a PASS verdict):

  KEEP (proves the wiki was generated correctly):
    - regen/regen_summary.json
    - regen/_upstream_resolution.json
    - regen/final/{Object}.md  + .lineage.md  + .review-needed.md
    - regen/final/judge_verdict.json
    - regen/final/judge_log.md
    - regen/final/writer_log.md
    - regen/auto_promote_log.json (when present)
    - regen/auto_verify_log.md    (when present)
    - compare.md
    - current/      (baseline -- needed to regenerate compare)
    - current_judge/

  DROP (redundant or reproducible):
    - regen/attempt_*/  (entire subtree -- final/ has the best copy)
    - regen/_upstream_bundle.md
    - regen/final/writer_raw_stream.jsonl
    - regen/final/judge_raw_stream.jsonl
    - regen/final/writer_prompt.md
    - regen/final/writer_summary.json
    - regen/final/writer_stderr.tmp

Safety rails:
  - DRY-RUN BY DEFAULT. --apply is required to actually delete anything.
  - --policy completed-only (default) ONLY touches objects with PASS verdict.
    --policy any-final compacts even FAIL objects (keeps the final/ contents
    for the score-based forensics; drops attempts and raw streams everywhere).
  - --keep-attempts forces retention of attempt_*/ dirs (useful for objects
    that hit MaxAttempts because the per-attempt diagnostics matter).
  - A _compaction_log.json is written per object (next to regen_summary.json)
    listing every file deleted + its size, so reductions are auditable.
  - Never touches current/ or current_judge/ (baseline data).

Usage:
  # See what WOULD be deleted (default dry-run):
  python tools/regen-harness/compact_audits.py --schema BI_DB_dbo

  # Actually delete:
  python tools/regen-harness/compact_audits.py --schema BI_DB_dbo --apply

  # Single-object compaction:
  python tools/regen-harness/compact_audits.py --schema BI_DB_dbo --object BI_DB_AB_Test --apply
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional

REPO_ROOT = Path(__file__).resolve().parents[2]
AUDIT_ROOT = REPO_ROOT / "audits" / "regen-sample"

# Files to delete inside regen/final/ when compacting (the heavy redundancies)
FINAL_FILES_TO_DROP = (
    "writer_raw_stream.jsonl",
    "judge_raw_stream.jsonl",
    "writer_prompt.md",
    "writer_summary.json",
    "writer_stderr.tmp",
)

# Files at regen/ level to drop
REGEN_FILES_TO_DROP = (
    "_upstream_bundle.md",
)


@dataclass
class CompactionResult:
    schema: str
    object: str
    skipped: bool = False
    skip_reason: str = ""
    bytes_before: int = 0
    bytes_after: int = 0
    files_before: int = 0
    files_after: int = 0
    deleted: List[dict] = field(default_factory=list)
    kept: List[str] = field(default_factory=list)

    @property
    def bytes_freed(self) -> int:
        return self.bytes_before - self.bytes_after


def _dir_size(d: Path) -> tuple[int, int]:
    """Return (total_bytes, file_count) for a directory tree."""
    total_b = 0
    total_f = 0
    if not d.exists():
        return 0, 0
    for p in d.rglob("*"):
        if p.is_file():
            try:
                total_b += p.stat().st_size
                total_f += 1
            except OSError:
                pass
    return total_b, total_f


def _read_verdict(verdict_path: Path) -> tuple[Optional[str], Optional[float]]:
    """Return (verdict_str, score) from a judge_verdict.json, or (None, None)."""
    if not verdict_path.exists():
        return None, None
    try:
        j = json.loads(verdict_path.read_text(encoding="utf-8"))
    except Exception:
        return None, None
    v = j.get("verdict")
    if isinstance(v, dict):
        return v.get("verdict"), v.get("weighted_score")
    return None, None


def _enqueue_deletes(obj_dir: Path, policy: str, keep_attempts: bool) -> List[Path]:
    """Return the list of paths that compaction would delete for this object."""
    targets: List[Path] = []
    regen = obj_dir / "regen"
    if not regen.exists():
        return targets

    # Drop attempt_*/ subtrees (the winner already lives in final/)
    if not keep_attempts:
        for d in regen.iterdir():
            if d.is_dir() and d.name.startswith("attempt_"):
                targets.append(d)

    # Drop reproducible files at regen/ level
    for n in REGEN_FILES_TO_DROP:
        p = regen / n
        if p.exists() and p.is_file():
            targets.append(p)

    # Drop heavy files inside regen/final/
    final = regen / "final"
    if final.exists():
        for n in FINAL_FILES_TO_DROP:
            p = final / n
            if p.exists() and p.is_file():
                targets.append(p)

    return targets


def _files_under(targets: List[Path]) -> List[tuple[Path, int]]:
    """Expand a list of files-and-dirs into (file_path, size_bytes) leaves."""
    out: List[tuple[Path, int]] = []
    for t in targets:
        if t.is_file():
            try:
                out.append((t, t.stat().st_size))
            except OSError:
                out.append((t, 0))
        elif t.is_dir():
            for p in t.rglob("*"):
                if p.is_file():
                    try:
                        out.append((p, p.stat().st_size))
                    except OSError:
                        out.append((p, 0))
    return out


def compact_one(obj_dir: Path, *, apply: bool, policy: str,
                keep_attempts: bool) -> CompactionResult:
    schema = obj_dir.parent.name
    obj = obj_dir.name
    res = CompactionResult(schema=schema, object=obj)

    res.bytes_before, res.files_before = _dir_size(obj_dir)

    # ---------- gating: was this object successfully completed? ----------
    final_verdict = obj_dir / "regen" / "final" / "judge_verdict.json"
    verdict_str, score = _read_verdict(final_verdict)

    if policy == "completed-only":
        if verdict_str != "PASS":
            res.skipped = True
            res.skip_reason = (f"verdict={verdict_str!r} score={score} "
                               f"(policy=completed-only requires PASS)")
            res.bytes_after = res.bytes_before
            res.files_after = res.files_before
            return res
    elif policy == "any-final":
        if not final_verdict.exists():
            res.skipped = True
            res.skip_reason = "no regen/final/judge_verdict.json (object not finished)"
            res.bytes_after = res.bytes_before
            res.files_after = res.files_before
            return res

    # ---------- collect what we'd delete ----------
    targets = _enqueue_deletes(obj_dir, policy, keep_attempts)
    leaves = _files_under(targets)

    deletion_log = [{
        "path": str(p.relative_to(obj_dir)).replace("\\", "/"),
        "bytes": sz,
    } for p, sz in leaves]
    res.deleted = deletion_log

    if not apply:
        res.bytes_after = res.bytes_before - sum(sz for _, sz in leaves)
        res.files_after = res.files_before - len(leaves)
        return res

    # ---------- actually delete ----------
    deleted_count = 0
    deleted_bytes = 0
    for t in targets:
        if not t.exists():
            continue
        try:
            if t.is_file():
                deleted_bytes += t.stat().st_size
                t.unlink()
                deleted_count += 1
            elif t.is_dir():
                for p in t.rglob("*"):
                    if p.is_file():
                        try:
                            deleted_bytes += p.stat().st_size
                            deleted_count += 1
                        except OSError:
                            pass
                shutil.rmtree(t, ignore_errors=True)
        except OSError as e:
            print(f"  WARN: could not delete {t}: {e}", file=sys.stderr)

    # Write a per-object compaction log into regen/
    log = {
        "schema": schema,
        "object": obj,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "policy": policy,
        "keep_attempts": keep_attempts,
        "verdict": verdict_str,
        "score": score,
        "bytes_before": res.bytes_before,
        "files_before": res.files_before,
        "bytes_freed": deleted_bytes,
        "files_deleted": deleted_count,
        "deleted_paths": deletion_log[:200],
    }
    log_path = obj_dir / "regen" / "_compaction_log.json"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(json.dumps(log, indent=2), encoding="utf-8")

    res.bytes_after, res.files_after = _dir_size(obj_dir)
    return res


def _list_objects(audit_root: Path, schema: Optional[str], obj: Optional[str]) -> List[Path]:
    if not audit_root.exists():
        return []
    out: List[Path] = []
    if schema and obj:
        d = audit_root / schema / obj
        if d.is_dir():
            out.append(d)
        return out
    schema_dirs = [audit_root / schema] if schema else [d for d in audit_root.iterdir() if d.is_dir()]
    for sd in schema_dirs:
        if not sd.is_dir():
            continue
        for od in sorted(sd.iterdir()):
            if od.is_dir():
                out.append(od)
    return out


def _human(n: int) -> str:
    for u in ("B", "KB", "MB", "GB"):
        if abs(n) < 1024:
            return f"{n:7.1f} {u}"
        n /= 1024
    return f"{n:7.1f} TB"


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--schema", help="schema name (e.g. BI_DB_dbo); omit to walk all schemas")
    ap.add_argument("--object", help="single object (requires --schema)")
    ap.add_argument("--apply", action="store_true",
                    help="actually delete files (default is DRY-RUN)")
    ap.add_argument("--policy", choices=("completed-only", "any-final"),
                    default="completed-only",
                    help="completed-only: only compact objects with PASS verdict (safest); "
                         "any-final: compact every object that has regen/final/judge_verdict.json")
    ap.add_argument("--keep-attempts", action="store_true",
                    help="retain regen/attempt_*/ dirs (default drops them; final/ has the winner)")
    ap.add_argument("--audit-root", default=str(AUDIT_ROOT),
                    help=f"override audit root (default {AUDIT_ROOT})")
    args = ap.parse_args(argv)

    if args.object and not args.schema:
        ap.error("--object requires --schema")

    audit_root = Path(args.audit_root)
    objects = _list_objects(audit_root, args.schema, args.object)
    if not objects:
        print(f"No objects found under {audit_root}"
              + (f"/{args.schema}" if args.schema else "")
              + (f"/{args.object}" if args.object else ""))
        return 1

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"compact_audits  mode={mode}  policy={args.policy}  keep_attempts={args.keep_attempts}")
    print(f"  audit_root: {audit_root}")
    print(f"  objects:    {len(objects)}")
    print()

    results: List[CompactionResult] = []
    for od in objects:
        r = compact_one(od, apply=args.apply, policy=args.policy,
                        keep_attempts=args.keep_attempts)
        results.append(r)
        if r.skipped:
            print(f"  SKIP  {r.schema}/{r.object:50s}  {r.skip_reason}")
        else:
            tag = "WOULD-FREE" if not args.apply else "FREED"
            n_targets = len(r.deleted)
            print(f"  OK    {r.schema}/{r.object:50s}  {tag} {_human(r.bytes_freed)}  "
                  f"({n_targets} files; {_human(r.bytes_before)} -> {_human(r.bytes_after)})")

    total_before = sum(r.bytes_before for r in results)
    total_after  = sum(r.bytes_after  for r in results)
    total_freed  = total_before - total_after
    n_compacted  = sum(1 for r in results if not r.skipped)
    n_skipped    = sum(1 for r in results if r.skipped)
    pct = (100.0 * total_freed / total_before) if total_before else 0.0

    print()
    print(f"Summary: {n_compacted} compacted, {n_skipped} skipped")
    print(f"  Before: {_human(total_before)}  After: {_human(total_after)}  Freed: {_human(total_freed)}  ({pct:.1f}%)")
    if not args.apply:
        print(f"  (dry-run -- no files written. Re-run with --apply to actually delete.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
