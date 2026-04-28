"""
build_writer_prompt.py

Composes the writer prompt for ONE object in the regen harness.

Inputs:
  --schema       e.g. BI_DB_dbo
  --object       e.g. BI_DB_AdvancedDeposit_Ext
  --attempt      attempt number (1 or 2). Default 1.
  --judge-feedback (optional) path to attempt_(N-1)/judge_verdict.json — when
                   provided, its `regeneration_feedback` field is appended as
                   an explicit list of fixes for attempt 2.

Composition order:
  1. Writer preamble        (tools/regen-harness/prompts/writer_preamble.md)
  2. Reused batch template  (.claude/prompts/build-wiki-{bidb|dwh}-batch.md)
     -- with the ⛔ MCP block kept (we want the writer to verify MCP) and the
        "Plan batch / _index.md" section stripped (we are doing one object,
        not a batch).
  3. Object header          (Schema, Object, attempt number, output paths)
  4. Pre-resolved upstream bundle  (audits/regen-sample/.../regen/_upstream_bundle.md)
  5. (attempt 2 only) Judge feedback block

Output:
  audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/writer_prompt.md
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
HARNESS_ROOT = Path(__file__).resolve().parent
PREAMBLE = HARNESS_ROOT / "prompts" / "writer_preamble.md"
TARGET_ROOT = REPO_ROOT / "audits" / "regen-sample"

BIDB_TEMPLATE = REPO_ROOT / ".claude" / "prompts" / "build-wiki-bidb-batch.md"
DWH_TEMPLATE = REPO_ROOT / ".claude" / "prompts" / "build-wiki-dwh-batch.md"


def pick_template(schema: str) -> Path:
    if schema.lower() == "bi_db_dbo":
        return BIDB_TEMPLATE
    return DWH_TEMPLATE


def strip_batch_specific(template: str, schema: str) -> str:
    """Remove the batch-loop-specific instructions from the reused template.

    We keep:
      - The MCP pre-flight block.
      - The "Load rules" list (still useful for the writer).
      - The "Key resources" list.

    We strip:
      - Anything talking about reading `_index.md`, the blacklist, batch
        sizing, weighted exceptions, or "ONE BATCH PER SESSION".
      - The Phase 16 reference (judge runs separately now).
      - The schema argument footer (we add our own object header).
    """
    text = template

    # Replace the "Plan batch" and "Execute pipeline" sections with a
    # single-object equivalent. The two batch templates use the same
    # "## Instructions ... ## Key resources" boundary.
    instructions_pattern = re.compile(
        r"## Instructions.*?(?=## Key resources)",
        re.DOTALL,
    )
    new_instructions = (
        "## Instructions (regen-harness, single object)\n\n"
        "1. **Load rules** — read these in order before anything else:\n"
        "   - `.cursor/rules/semantic-layer-core/repo-first-access.mdc`\n"
        "   - `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc`\n"
        "   - `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`\n"
        "   - `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`\n"
        "   - `.cursor/rules/dwh-semantic-doc/10.5b-tier1-enforcement.mdc`\n\n"
        "2. **Skip batch planning** — do NOT read `_index.md`, do NOT touch\n"
        "   `_batch_context.json`, do NOT scan the blacklist. The harness\n"
        "   already chose this object.\n\n"
        "3. **Run the pipeline for THIS object only**: phases 1 through 11\n"
        "   inclusive. Use the pre-resolved upstream bundle (provided below)\n"
        "   as your authoritative Tier 1 source. Generate three files in\n"
        "   `audits/regen-sample/{schema}/{object}/regen/attempt_{N}/`:\n"
        "   `.lineage.md`, `.md`, `.review-needed.md`. Do NOT generate\n"
        "   `.alter.sql`. Do NOT modify any file under `knowledge/synapse/Wiki/`.\n\n"
        "4. **Skip Phase 16** — the adversarial judge runs in a separate,\n"
        "   fresh claude process after you exit. Self-evaluation here wastes\n"
        "   tokens and pollutes the comparison.\n\n"
        "5. **Exit cleanly** after printing the OUTPUT CHECK block defined in\n"
        "   the Regen Harness preamble.\n\n"
    )
    text = instructions_pattern.sub(new_instructions, text, count=1)

    # Remove the trailing "Schema argument" footer if present.
    text = re.sub(
        r"## Schema argument.*\Z",
        "",
        text,
        flags=re.DOTALL,
    ).rstrip() + "\n"

    return text


def find_ddl_path(schema: str, obj: str) -> Optional[Path]:
    base = Path(r"c:\Users\guyman\Documents\github\DataPlatform") / "SynapseSQLPool1" / "sql_dp_prod_we" / schema
    for sub in ("Tables", "Views", "Functions"):
        cand = base / sub / f"{schema}.{obj}.sql"
        if cand.exists():
            return cand
    return None


def compose(schema: str, obj: str, attempt: int, judge_feedback_path: Optional[Path]) -> str:
    if not PREAMBLE.exists():
        raise SystemExit(f"Writer preamble missing: {PREAMBLE}")
    preamble = PREAMBLE.read_text(encoding="utf-8")
    template = pick_template(schema)
    if not template.exists():
        raise SystemExit(f"Batch template missing: {template}")
    base = template.read_text(encoding="utf-8")
    base = strip_batch_specific(base, schema)

    target_dir = TARGET_ROOT / schema / obj
    regen_dir = target_dir / "regen"
    bundle = regen_dir / "_upstream_bundle.md"
    no_upstream_marker = regen_dir / "_no_upstream_found.txt"
    attempt_dir = regen_dir / f"attempt_{attempt}"

    if not bundle.exists():
        raise SystemExit(
            f"Pre-resolved upstream bundle missing: {bundle}\n"
            "Run preload_upstream.py before build_writer_prompt.py."
        )

    bundle_text = bundle.read_text(encoding="utf-8")

    # Resolve DDL path for the object header (judge wants this too)
    ddl_path = find_ddl_path(schema, obj)

    out = []
    out.append("# Regen Harness — Writer Prompt")
    out.append("")
    out.append(preamble)
    out.append("")
    out.append("---")
    out.append("")
    out.append("# Object Header")
    out.append("")
    out.append(f"- **Schema**: `{schema}`")
    out.append(f"- **Object**: `{obj}`")
    out.append(f"- **Attempt**: `{attempt}`")
    out.append(f"- **Output directory** (relative to repo root): `audits/regen-sample/{schema}/{obj}/regen/attempt_{attempt}/`")
    out.append(f"- **Absolute output directory**: `{attempt_dir}`")
    out.append(f"- **Bundle path**: `{bundle}`")
    if ddl_path:
        out.append(f"- **DDL path**: `{ddl_path}`")
    if no_upstream_marker.exists():
        out.append(
            f"- **No-upstream marker present**: `{no_upstream_marker}` — "
            "object is dormant or has no resolvable upstream wiki. Footer may "
            "say `Production Source: Unknown (dormant)`. Tier 4 inferred is "
            "STILL banned — ground every column description in DDL + SP code."
        )
    out.append("")
    out.append("---")
    out.append("")
    out.append(base.rstrip())
    out.append("")
    out.append("---")
    out.append("")
    out.append("# PRE-RESOLVED UPSTREAM BUNDLE")
    out.append("")
    out.append("Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.")
    out.append("")
    out.append(bundle_text)
    out.append("")

    if attempt > 1 and judge_feedback_path and judge_feedback_path.exists():
        try:
            verdict = json.loads(judge_feedback_path.read_text(encoding="utf-8"))
        except Exception as exc:
            out.append("---\n")
            out.append("# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT")
            out.append(f"\n*[Failed to parse {judge_feedback_path}: {exc}]*\n")
        else:
            out.append("---\n")
            out.append("# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT — apply ALL of these")
            v = verdict.get("verdict") or {}
            score = v.get("weighted_score")
            verdict_str = v.get("verdict", "FAIL")
            out.append("")
            out.append(
                f"Previous attempt scored **{score}** ({verdict_str}). The "
                "adversarial judge required regeneration with the following "
                "specific fixes:"
            )
            out.append("")
            feedback = v.get("regeneration_feedback") or "(no feedback string in verdict.json)"
            out.append("> " + feedback.replace("\n", "\n> "))
            out.append("")
            issues = v.get("issues") or []
            if issues:
                out.append("Top issues from the judge:")
                for i, issue in enumerate(issues[:10], 1):
                    sev = issue.get("severity", "?")
                    where = issue.get("column_or_section", "")
                    prob = issue.get("problem", "")
                    out.append(f"{i}. [{sev}] `{where}` — {prob}")
                out.append("")
            t1 = v.get("t1_fidelity_table") or []
            mismatches = [r for r in t1 if r.get("match") == "NO"]
            if mismatches:
                out.append("Tier 1 paraphrasing failures (must be fixed verbatim):")
                out.append("")
                for r in mismatches[:10]:
                    out.append(f"- **{r.get('column','?')}**:")
                    out.append(f"  - Upstream: `{r.get('upstream_quote','')[:200]}`")
                    out.append(f"  - You wrote: `{r.get('wiki_quote','')[:200]}`")
                    out.append(f"  - Loss: {r.get('loss','?')}")
                out.append("")
            out.append(
                "Address every issue above. Do NOT regenerate the whole wiki "
                "from scratch — keep what was correct, only fix what the "
                "judge flagged."
            )
            out.append("")

    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", required=True)
    ap.add_argument("--object", dest="obj", required=True)
    ap.add_argument("--attempt", type=int, default=1)
    ap.add_argument("--judge-feedback", default=None,
                    help="Path to attempt_(N-1)/judge_verdict.json (for attempt 2)")
    ap.add_argument("--output", default=None,
                    help="Override output path. Default: regen/attempt_N/writer_prompt.md")
    args = ap.parse_args()

    target_dir = TARGET_ROOT / args.schema / args.obj
    regen_dir = target_dir / "regen"
    attempt_dir = regen_dir / f"attempt_{args.attempt}"
    attempt_dir.mkdir(parents=True, exist_ok=True)

    judge_path = Path(args.judge_feedback) if args.judge_feedback else None
    if args.attempt > 1 and judge_path is None:
        prev_attempt = regen_dir / f"attempt_{args.attempt - 1}" / "judge_verdict.json"
        if prev_attempt.exists():
            judge_path = prev_attempt

    prompt = compose(args.schema, args.obj, args.attempt, judge_path)

    out_path = Path(args.output) if args.output else (attempt_dir / "writer_prompt.md")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(prompt, encoding="utf-8")
    size = out_path.stat().st_size
    print(f"Wrote writer prompt: {out_path}  ({size:,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
