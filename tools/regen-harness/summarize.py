"""
summarize.py

Aggregates per-object compare.md + judge_verdict.json files into a single
report at `audits/regen-sample/_summary.md`. Also emits `_summary.csv` for
easy spreadsheet pasting.

The summary contains:
  - One row per object: schema | object | bucket | current Q (self) |
    current Q (judge) | regen Q (judge) | slop before | slop after | verdict
  - Aggregate stats per bucket: how many BETTER / WORSE / EQUIVALENT.
  - Aggregate stats per schema (same axes).
  - Cost / token totals if writer_summary.json + judge_verdict.json have them.
  - Headline: "X / 25 came back BETTER. Y / 25 are EQUIVALENT. Z / 25 are
    WORSE. Decide accordingly."
"""
from __future__ import annotations

import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
TARGET_ROOT = REPO_ROOT / "audits" / "regen-sample"
MANIFEST = TARGET_ROOT / "manifest.csv"

T4_INFERRED_RE = re.compile(r"\(Tier\s*4[^)]*inferred", re.IGNORECASE)


def safe_load(path: Path) -> Optional[Dict]:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def slop_count(text: str) -> int:
    if not text:
        return 0
    return len(T4_INFERRED_RE.findall(text))


def get_score(verdict_obj: Optional[Dict]) -> Optional[float]:
    if not verdict_obj:
        return None
    v = verdict_obj.get("verdict")
    if not isinstance(v, dict):
        return None
    s = v.get("weighted_score")
    try:
        return float(s) if s is not None else None
    except Exception:
        return None


def parse_compare(path: Path) -> Tuple[Optional[str], Optional[float]]:
    """Read compare.md and return (verdict_label, score_delta)."""
    if not path.exists():
        return None, None
    text = path.read_text(encoding="utf-8")
    m = re.search(r"\*\*Verdict\*\*:\s*\*\*(\w+)\*\*", text)
    label = m.group(1) if m else None
    m2 = re.search(r"score delta\s*([+-]?\d+\.?\d*)", text)
    delta = float(m2.group(1)) if m2 else None
    return label, delta


def load_writer_cost(obj_dir: Path) -> Tuple[float, int, int]:
    """Sum cost/tokens across all attempts."""
    cost = 0.0
    in_tok = 0
    out_tok = 0
    regen_dir = obj_dir / "regen"
    for ws in regen_dir.glob("attempt_*/writer_summary.json"):
        d = safe_load(ws) or {}
        try: cost += float(d.get("cost_usd") or 0)
        except: pass
        try: in_tok += int(d.get("input_tokens") or 0)
        except: pass
        try: out_tok += int(d.get("output_tokens") or 0)
        except: pass
    return cost, in_tok, out_tok


def load_judge_cost(obj_dir: Path) -> Tuple[float, int, int]:
    cost = 0.0
    in_tok = 0
    out_tok = 0
    for jv in (obj_dir / "regen").glob("attempt_*/judge_verdict.json"):
        d = safe_load(jv) or {}
        try: cost += float(d.get("cost_usd") or 0)
        except: pass
        try: in_tok += int(d.get("input_tokens") or 0)
        except: pass
        try: out_tok += int(d.get("output_tokens") or 0)
        except: pass
    cj = obj_dir / "current_judge" / "judge_verdict.json"
    if cj.exists():
        d = safe_load(cj) or {}
        try: cost += float(d.get("cost_usd") or 0)
        except: pass
        try: in_tok += int(d.get("input_tokens") or 0)
        except: pass
        try: out_tok += int(d.get("output_tokens") or 0)
        except: pass
    return cost, in_tok, out_tok


def main() -> int:
    if not MANIFEST.exists():
        print(f"ERROR: manifest missing: {MANIFEST}")
        return 1

    rows = list(csv.DictReader(MANIFEST.open("r", encoding="utf-8-sig")))

    table: List[Dict[str, Any]] = []
    total_cost = 0.0
    total_in = 0
    total_out = 0

    for row in rows:
        schema = row["Schema"]; obj = row["Object"]; bucket = row.get("Bucket","")
        cur_q_self = row.get("CurrentQuality") or ""
        obj_dir = TARGET_ROOT / schema / obj
        if not obj_dir.exists():
            table.append({
                "schema": schema, "object": obj, "bucket": bucket,
                "current_q_self": cur_q_self, "current_q_judge": None,
                "regen_q_judge": None, "slop_before": None, "slop_after": None,
                "verdict": "MISSING_FOLDER", "score_delta": None,
            })
            continue

        # Slop counts from raw wiki text
        cur_md = obj_dir / "current" / f"{obj}.md"
        new_md = obj_dir / "regen" / "final" / f"{obj}.md"
        slop_before = slop_count(cur_md.read_text(encoding="utf-8", errors="replace")) if cur_md.exists() else None
        slop_after  = slop_count(new_md.read_text(encoding="utf-8", errors="replace")) if new_md.exists() else None

        cur_judge = safe_load(obj_dir / "current_judge" / "judge_verdict.json")

        # Find regen judge verdict (best attempt or final)
        regen_summary = safe_load(obj_dir / "regen" / "regen_summary.json")
        regen_judge: Optional[Dict] = None
        if regen_summary:
            ba = regen_summary.get("best_attempt")
            if ba:
                regen_judge = safe_load(obj_dir / "regen" / f"attempt_{ba}" / "judge_verdict.json")
        if regen_judge is None:
            for jv in sorted((obj_dir / "regen").glob("attempt_*/judge_verdict.json")):
                regen_judge = safe_load(jv)
                if regen_judge:
                    break

        verdict_label, score_delta = parse_compare(obj_dir / "compare.md")

        table.append({
            "schema": schema,
            "object": obj,
            "bucket": bucket,
            "current_q_self": cur_q_self,
            "current_q_judge": get_score(cur_judge),
            "regen_q_judge":   get_score(regen_judge),
            "slop_before": slop_before,
            "slop_after":  slop_after,
            "verdict": verdict_label or "INCONCLUSIVE",
            "score_delta": score_delta,
        })

        c1, i1, o1 = load_writer_cost(obj_dir)
        c2, i2, o2 = load_judge_cost(obj_dir)
        total_cost += c1 + c2
        total_in += i1 + i2
        total_out += o1 + o2

    # ---- Render markdown ----
    out: List[str] = []
    out.append("# Regen Harness Summary")
    out.append("")
    out.append(f"_Generated from `{MANIFEST.name}` -- {len(table)} objects._")
    out.append("")

    # Headline counts
    counts = Counter(r["verdict"] for r in table)
    n_better = counts.get("BETTER", 0)
    n_eq = counts.get("EQUIVALENT", 0)
    n_worse = counts.get("WORSE", 0)
    n_other = sum(v for k, v in counts.items() if k not in {"BETTER","EQUIVALENT","WORSE"})

    out.append(f"## Headline")
    out.append("")
    out.append(f"- **BETTER**: {n_better} / {len(table)}")
    out.append(f"- **EQUIVALENT**: {n_eq} / {len(table)}")
    out.append(f"- **WORSE**: {n_worse} / {len(table)}")
    if n_other:
        out.append(f"- **Other / inconclusive**: {n_other}")
    out.append("")
    out.append(f"- **Total claude cost (all attempts + judges + current-judges)**: ${total_cost:.2f} USD")
    out.append(f"- **Total tokens**: in={total_in:,}  out={total_out:,}")
    out.append("")

    # Per-bucket breakdown
    bucket_breakdown: Dict[str, Counter] = defaultdict(Counter)
    for r in table:
        bucket_breakdown[r["bucket"]][r["verdict"]] += 1
    out.append("## Per-bucket breakdown")
    out.append("")
    out.append("| Bucket | Total | BETTER | EQUIVALENT | WORSE | Other |")
    out.append("|---|---|---|---|---|---|")
    for bucket, c in sorted(bucket_breakdown.items()):
        tot = sum(c.values())
        other = sum(v for k, v in c.items() if k not in {"BETTER","EQUIVALENT","WORSE"})
        out.append(f"| {bucket} | {tot} | {c['BETTER']} | {c['EQUIVALENT']} | {c['WORSE']} | {other} |")
    out.append("")

    # Per-schema breakdown
    schema_breakdown: Dict[str, Counter] = defaultdict(Counter)
    for r in table:
        schema_breakdown[r["schema"]][r["verdict"]] += 1
    out.append("## Per-schema breakdown")
    out.append("")
    out.append("| Schema | Total | BETTER | EQUIVALENT | WORSE | Other |")
    out.append("|---|---|---|---|---|---|")
    for schema, c in sorted(schema_breakdown.items()):
        tot = sum(c.values())
        other = sum(v for k, v in c.items() if k not in {"BETTER","EQUIVALENT","WORSE"})
        out.append(f"| {schema} | {tot} | {c['BETTER']} | {c['EQUIVALENT']} | {c['WORSE']} | {other} |")
    out.append("")

    # Per-object table
    out.append("## Per-object detail")
    out.append("")
    out.append("| Schema | Object | Bucket | Q (self) | Q (judge cur) | Q (judge regen) | Slop before | Slop after | Verdict | Score delta |")
    out.append("|---|---|---|---|---|---|---|---|---|---|")
    for r in table:
        out.append(
            "| {schema} | {object} | {bucket} | {q_self} | {q_cur} | {q_new} | {slop_b} | {slop_a} | {verdict} | {delta} |".format(
                schema=r["schema"],
                object=r["object"],
                bucket=r["bucket"],
                q_self=r["current_q_self"] or "-",
                q_cur=r["current_q_judge"] if r["current_q_judge"] is not None else "-",
                q_new=r["regen_q_judge"]   if r["regen_q_judge"]   is not None else "-",
                slop_b=r["slop_before"] if r["slop_before"] is not None else "-",
                slop_a=r["slop_after"]  if r["slop_after"]  is not None else "-",
                verdict=r["verdict"],
                delta=(f"{r['score_delta']:+}" if r["score_delta"] is not None else "-"),
            )
        )
    out.append("")

    # Decision guidance
    out.append("## Decision guidance")
    out.append("")
    if len(table) > 0 and n_better >= 0.85 * len(table):
        out.append(
            f"- **Strong signal to roll out**: {n_better} / {len(table)} BETTER. "
            "Consider running the full pipeline (or at least the slop list) "
            "with the new architecture."
        )
    elif n_better > n_worse and n_better >= 0.5 * len(table):
        out.append(
            f"- **Mixed signal**: {n_better} BETTER vs {n_worse} WORSE. "
            "Recommend running the slop-only subset (47 known-slop objects) "
            "before committing to a full re-run."
        )
    elif n_worse > n_better:
        out.append(
            f"- **Regression risk**: {n_worse} WORSE vs {n_better} BETTER. "
            "Diagnose the WORSE rows in the per-object compare.md files "
            "before any rollout."
        )
    else:
        out.append("- **No clear signal**. Inspect individual compare.md files.")
    out.append("")

    summary_md = TARGET_ROOT / "_summary.md"
    summary_md.write_text("\n".join(out), encoding="utf-8")
    print(f"Wrote {summary_md}")

    # ---- CSV ----
    csv_path = TARGET_ROOT / "_summary.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Schema","Object","Bucket","Q_self","Q_judge_current","Q_judge_regen","Slop_before","Slop_after","Verdict","Score_delta"])
        for r in table:
            w.writerow([
                r["schema"], r["object"], r["bucket"],
                r["current_q_self"], r["current_q_judge"], r["regen_q_judge"],
                r["slop_before"], r["slop_after"], r["verdict"], r["score_delta"],
            ])
    print(f"Wrote {csv_path}")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
