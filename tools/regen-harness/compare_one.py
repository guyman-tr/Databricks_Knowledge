"""
compare_one.py

Compare current vs regenerated wiki for a single object. The comparison is
**judge-vs-judge**: we re-run the same adversarial judge against the CURRENT
wiki (using the bundle that was assembled from the current lineage) so that
both verdicts come from the same evaluator. Without this we'd be comparing
the writer's own self-grade ("Quality 9.4 -- I am amazing") to an external
judge — apples to oranges.

Inputs (assumed already populated by pick_sample / regen_one):
  audits/regen-sample/{Schema}/{Object}/current/*.md       (read-only snapshot)
  audits/regen-sample/{Schema}/{Object}/regen/final/*.md   (regen winner)
  audits/regen-sample/{Schema}/{Object}/regen/_upstream_bundle.md

Outputs:
  audits/regen-sample/{Schema}/{Object}/current_judge/judge_verdict.json
  audits/regen-sample/{Schema}/{Object}/current_judge/judge_log.md
  audits/regen-sample/{Schema}/{Object}/compare.md

Usage:
  python compare_one.py --schema BI_DB_dbo --object BI_DB_AdvancedDeposit_Ext
  python compare_one.py --all
  python compare_one.py --schema X --object Y --skip-current-judge
      (use only when current_judge/judge_verdict.json already exists, e.g.
       you re-ran compare after tweaking the diff logic and don't want to pay
       for the judge again)
"""
from __future__ import annotations

import argparse
import csv
import difflib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
HARNESS_ROOT = Path(__file__).resolve().parent
TARGET_ROOT = REPO_ROOT / "audits" / "regen-sample"
RUN_JUDGE = HARNESS_ROOT / "run_judge.ps1"
SSDT_ROOT = Path(r"c:\Users\guyman\Documents\github\DataPlatform") / "SynapseSQLPool1" / "sql_dp_prod_we"


def find_ddl(schema: str, obj: str) -> Optional[Path]:
    for sub in ("Tables", "Views", "Functions"):
        cand = SSDT_ROOT / schema / sub / f"{schema}.{obj}.sql"
        if cand.exists():
            return cand
    return None


def run_judge(
    schema: str,
    obj: str,
    wiki_path: Path,
    lineage_path: Path,
    review_path: Optional[Path],
    ddl_path: Optional[Path],
    upstream_bundle_path: Path,
    out_dir: Path,
    timeout_seconds: int = 900,
) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    args = [
        "powershell.exe",
        "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
        "-File", str(RUN_JUDGE),
        "-Schema", schema,
        "-ObjectName", obj,
        "-WikiPath", str(wiki_path),
        "-LineagePath", str(lineage_path),
        "-DdlPath", str(ddl_path) if ddl_path else "",
        "-UpstreamBundlePath", str(upstream_bundle_path),
        "-OutDir", str(out_dir),
        "-TimeoutSeconds", str(timeout_seconds),
    ]
    if review_path and review_path.exists():
        args += ["-ReviewPath", str(review_path)]
    print("  >", " ".join(args[:6]), "...", flush=True)
    proc = subprocess.run(args, cwd=str(REPO_ROOT))
    return proc.returncode


def load_verdict(path: Path) -> Optional[Dict]:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


# --- Wiki shape parsing ---------------------------------------------------

ELEMENTS_HEADER_RE = re.compile(r"^##\s*4\.\s+Element", re.IGNORECASE)
TIER_RE = re.compile(r"\(Tier\s+(\d)\b[^)]*\)", re.IGNORECASE)
T4_INFERRED_RE = re.compile(r"\(Tier\s*4[^)]*inferred", re.IGNORECASE)
SECTION_RE = re.compile(r"^##\s+(\d+)\.\s", re.MULTILINE)


def parse_elements_table(text: str) -> List[Tuple[str, str]]:
    """Return list of (column_name, description) from the elements table.

    Best-effort: looks for the section starting at "## 4. Elements" and
    parses pipe-delimited rows. Skips header / divider rows.
    """
    if not text:
        return []
    lines = text.splitlines()
    in_section = False
    rows: List[Tuple[str, str]] = []
    for line in lines:
        if ELEMENTS_HEADER_RE.match(line.strip()):
            in_section = True
            continue
        if in_section and re.match(r"^##\s+\d+\.\s", line.strip()):
            # next section reached
            break
        if in_section and line.strip().startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) < 5:
                continue
            if any("---" in c for c in cells):
                continue
            if cells[0].lower() in {"#", "no", "n", ""}:
                # try second cell as the column name
                col = cells[1] if len(cells) > 1 else ""
                desc = cells[-1] if len(cells) > 4 else ""
            else:
                # rare: no leading # column
                col = cells[0]
                desc = cells[-1]
            # Skip header
            if col.lower() in {"element", "column", "column name"}:
                continue
            if col and not col.lower().startswith("---"):
                rows.append((col, desc))
    return rows


def slop_count(text: str) -> int:
    if not text:
        return 0
    return len(T4_INFERRED_RE.findall(text))


def tier_breakdown(rows: List[Tuple[str, str]]) -> Dict[str, int]:
    bd = {"T1": 0, "T2": 0, "T3": 0, "T4": 0, "Untagged": 0}
    for _, desc in rows:
        m = TIER_RE.search(desc)
        if not m:
            bd["Untagged"] += 1
            continue
        key = f"T{m.group(1)}"
        bd[key] = bd.get(key, 0) + 1
    return bd


def diff_columns(
    cur_rows: List[Tuple[str, str]],
    new_rows: List[Tuple[str, str]],
    top_n: int = 10,
) -> List[Dict]:
    """Per-column diff sorted by edit distance descending."""
    cur_map = {c: d for c, d in cur_rows}
    new_map = {c: d for c, d in new_rows}
    seen = set()
    ordered_cols: List[str] = []
    for c, _ in cur_rows + new_rows:
        if c in seen:
            continue
        seen.add(c)
        ordered_cols.append(c)
    diffs: List[Dict] = []
    for c in ordered_cols:
        a = cur_map.get(c, "")
        b = new_map.get(c, "")
        if a == b:
            continue
        ratio = difflib.SequenceMatcher(None, a, b).ratio()
        diffs.append({
            "column": c,
            "current": a,
            "regen": b,
            "similarity": round(ratio, 3),
            "current_tier": (TIER_RE.search(a).group(1) if TIER_RE.search(a) else None) if a else None,
            "regen_tier": (TIER_RE.search(b).group(1) if TIER_RE.search(b) else None) if b else None,
        })
    diffs.sort(key=lambda d: d["similarity"])
    return diffs[:top_n]


def write_compare_md(
    schema: str,
    obj: str,
    out_path: Path,
    cur_text: str,
    new_text: str,
    cur_verdict: Optional[Dict],
    new_verdict: Optional[Dict],
    bucket: Optional[str],
) -> Tuple[str, float]:
    cur_rows = parse_elements_table(cur_text)
    new_rows = parse_elements_table(new_text)
    cur_slop = slop_count(cur_text)
    new_slop = slop_count(new_text)
    cur_breakdown = tier_breakdown(cur_rows)
    new_breakdown = tier_breakdown(new_rows)

    cur_score = None; new_score = None
    if cur_verdict and isinstance(cur_verdict, dict):
        v = cur_verdict.get("verdict") or {}
        cur_score = v.get("weighted_score")
    if new_verdict and isinstance(new_verdict, dict):
        v = new_verdict.get("verdict") or {}
        new_score = v.get("weighted_score")

    def num(x):
        try: return float(x)
        except: return None

    cur_n = num(cur_score); new_n = num(new_score)

    delta_score = None
    if cur_n is not None and new_n is not None:
        delta_score = round(new_n - cur_n, 2)

    # Verdict logic
    verdict = "EQUIVALENT"
    rationale_bits: List[str] = []
    if delta_score is None:
        verdict = "INCONCLUSIVE"
        rationale_bits.append("missing one or both judge scores")
    else:
        # Combine score delta + slop delta
        slop_delta = new_slop - cur_slop
        if delta_score >= 0.5 or (slop_delta <= -3 and delta_score >= 0):
            verdict = "BETTER"
        elif delta_score <= -0.5 or (slop_delta >= 3 and delta_score <= 0):
            verdict = "WORSE"
        else:
            verdict = "EQUIVALENT"
        rationale_bits.append(f"score delta {delta_score:+}")
        rationale_bits.append(f"slop {cur_slop} -> {new_slop} (delta {slop_delta:+})")

    diffs = diff_columns(cur_rows, new_rows, top_n=10)

    out: List[str] = []
    out.append(f"# Compare — `{schema}.{obj}`")
    out.append("")
    if bucket:
        out.append(f"**Bucket**: `{bucket}`")
    out.append("")
    out.append(f"**Verdict**: **{verdict}**  ({'; '.join(rationale_bits)})")
    out.append("")
    out.append("## Header")
    out.append("")
    out.append("| Metric | Current | Regen | Delta |")
    out.append("|---|---|---|---|")
    out.append(f"| Judge weighted score | {cur_score} | {new_score} | {delta_score} |")
    out.append(f"| Slop hits (`Tier 4 ... inferred`) | {cur_slop} | {new_slop} | {new_slop - cur_slop:+} |")
    out.append(f"| Element rows | {len(cur_rows)} | {len(new_rows)} | {len(new_rows) - len(cur_rows):+} |")
    all_tiers = sorted(set(list(cur_breakdown.keys()) + list(new_breakdown.keys())),
                       key=lambda k: (k != "Untagged", k))
    for tier in all_tiers:
        c = cur_breakdown.get(tier, 0)
        n = new_breakdown.get(tier, 0)
        out.append(f"| {tier} count | {c} | {n} | {n - c:+} |")
    out.append("")

    # Per-dimension comparison
    if cur_verdict and new_verdict:
        cur_v = cur_verdict.get("verdict") or {}
        new_v = new_verdict.get("verdict") or {}
        cur_dims = cur_v.get("dimension_scores") or {}
        new_dims = new_v.get("dimension_scores") or {}
        if cur_dims or new_dims:
            out.append("## Dimension scores")
            out.append("")
            out.append("| Dimension | Current | Regen |")
            out.append("|---|---|---|")
            keys = sorted(set(list(cur_dims.keys()) + list(new_dims.keys())))
            for k in keys:
                out.append(f"| {k} | {cur_dims.get(k)} | {new_dims.get(k)} |")
            out.append("")

    # Top column diffs
    out.append("## Top 10 column changes (by edit distance)")
    out.append("")
    if not diffs:
        out.append("_No element-row text changes detected._")
    else:
        out.append("| Column | Sim | Cur tier | Regen tier | Current | Regen |")
        out.append("|---|---|---|---|---|---|")
        for d in diffs:
            cur_short = (d["current"] or "")[:200].replace("|", "\\|").replace("\n", " ")
            new_short = (d["regen"]   or "")[:200].replace("|", "\\|").replace("\n", " ")
            out.append(
                f"| `{d['column']}` | {d['similarity']} | "
                f"{d['current_tier']} | {d['regen_tier']} | {cur_short} | {new_short} |"
            )
    out.append("")

    # Issues from new judge
    if new_verdict:
        v = new_verdict.get("verdict") or {}
        issues = v.get("issues") or []
        if issues:
            out.append("## Top issues — regen wiki (per judge)")
            out.append("")
            for i in issues[:8]:
                sev = i.get("severity", "?")
                where = i.get("column_or_section", "")
                prob = i.get("problem", "")
                out.append(f"- [{sev}] `{where}` — {prob}")
            out.append("")

    out_path.write_text("\n".join(out), encoding="utf-8")
    return verdict, (delta_score if delta_score is not None else 0.0)


def process_one(schema: str, obj: str, skip_current_judge: bool = False, bucket: Optional[str] = None) -> Dict:
    obj_dir = TARGET_ROOT / schema / obj
    if not obj_dir.exists():
        return {"schema": schema, "object": obj, "ok": False, "error": "no side folder"}

    current_dir = obj_dir / "current"
    regen_dir = obj_dir / "regen"
    final_dir = regen_dir / "final"
    bundle_path = regen_dir / "_upstream_bundle.md"

    cur_wiki     = current_dir / f"{obj}.md"
    cur_lineage  = current_dir / f"{obj}.lineage.md"
    cur_review   = current_dir / f"{obj}.review-needed.md"

    new_wiki     = final_dir / f"{obj}.md"
    new_lineage  = final_dir / f"{obj}.lineage.md"
    new_review   = final_dir / f"{obj}.review-needed.md"

    if not cur_wiki.exists():
        return {"schema": schema, "object": obj, "ok": False, "error": f"no current wiki at {cur_wiki}"}
    if not new_wiki.exists():
        return {"schema": schema, "object": obj, "ok": False, "error": f"no regen wiki at {new_wiki}"}
    if not bundle_path.exists():
        return {"schema": schema, "object": obj, "ok": False, "error": "no upstream bundle"}

    ddl = find_ddl(schema, obj)
    if ddl is None:
        # Mirror regen_one.ps1 behaviour: pass a placeholder so run_judge.ps1
        # accepts the parameter (it cannot bind an empty string) and the judge
        # can see explicitly that no DDL was located in the SSDT repo.
        placeholder = obj_dir / "_no_ddl.txt"
        if not placeholder.exists():
            placeholder.write_text(
                f"(DDL for {schema}.{obj} not found in DataPlatform SSDT repo)",
                encoding="utf-8",
            )
        ddl = placeholder

    # Run judge against current
    current_judge_dir = obj_dir / "current_judge"
    cur_verdict_path = current_judge_dir / "judge_verdict.json"
    if skip_current_judge and cur_verdict_path.exists():
        print(f"  [{schema}.{obj}] reusing existing current_judge verdict")
    else:
        print(f"  [{schema}.{obj}] running judge against CURRENT wiki...")
        rc = run_judge(schema, obj, cur_wiki, cur_lineage, cur_review, ddl, bundle_path, current_judge_dir)
        if rc != 0:
            print(f"    judge exit code {rc} — comparison may be partial")

    cur_verdict = load_verdict(cur_verdict_path)
    new_verdict_path = final_dir / "judge_verdict.json"
    if not new_verdict_path.exists():
        # final/ may not yet contain the judge verdict if regen_one didn't copy it
        # — fall back to whatever attempt directory was the best
        regen_summary = regen_dir / "regen_summary.json"
        if regen_summary.exists():
            try:
                rs = json.loads(regen_summary.read_text(encoding="utf-8"))
                ba = rs.get("best_attempt")
                if ba:
                    new_verdict_path = regen_dir / f"attempt_{ba}" / "judge_verdict.json"
            except Exception:
                pass
    new_verdict = load_verdict(new_verdict_path)

    cur_text = cur_wiki.read_text(encoding="utf-8", errors="replace")
    new_text = new_wiki.read_text(encoding="utf-8", errors="replace")

    out_path = obj_dir / "compare.md"
    verdict, delta = write_compare_md(
        schema, obj, out_path, cur_text, new_text, cur_verdict, new_verdict, bucket
    )
    print(f"  [{schema}.{obj}] -> {verdict}  delta={delta:+}  -> {out_path}")
    return {
        "schema": schema,
        "object": obj,
        "verdict": verdict,
        "delta": delta,
        "compare_path": str(out_path),
        "ok": True,
    }


def load_manifest_buckets() -> Dict[Tuple[str, str], str]:
    out: Dict[Tuple[str, str], str] = {}
    p = TARGET_ROOT / "manifest.csv"
    if not p.exists():
        return out
    for row in csv.DictReader(p.open("r", encoding="utf-8-sig")):
        out[(row["Schema"], row["Object"])] = row.get("Bucket", "")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema")
    ap.add_argument("--object", dest="obj")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--skip-current-judge", action="store_true",
                    help="Reuse existing current_judge/judge_verdict.json instead of re-running the judge.")
    args = ap.parse_args()

    buckets = load_manifest_buckets()

    if args.all:
        manifest = TARGET_ROOT / "manifest.csv"
        if not manifest.exists():
            print(f"manifest missing: {manifest}")
            return 1
        rows = list(csv.DictReader(manifest.open("r", encoding="utf-8-sig")))
        for r in rows:
            process_one(r["Schema"], r["Object"], args.skip_current_judge, r.get("Bucket"))
        return 0

    if not (args.schema and args.obj):
        ap.error("--schema and --object required (or use --all)")

    bucket = buckets.get((args.schema, args.obj))
    res = process_one(args.schema, args.obj, args.skip_current_judge, bucket)
    if not res.get("ok"):
        print("ERROR:", res.get("error"))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
