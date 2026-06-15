"""CLI driver for the eval-suite harness — used in Cursor/local dev.

The Databricks notebook does NOT use this file; it imports from
tools.eval_suite.harness directly. Keep this file thin.

Usage:
    python tools/eval_suite/run_harness.py --backend mock
    python tools/eval_suite/run_harness.py --backend mock --perturb-pct 0.3
    python tools/eval_suite/run_harness.py --backend direct_sql
    python tools/eval_suite/run_harness.py --backend mock --tags ddr,revenue
    python tools/eval_suite/run_harness.py --backend mock --case-id ddr_revenue_totals_yesterday
"""
from __future__ import annotations

import argparse
import datetime as dt
import os
import sys

REPO_ROOT = os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from tools.eval_suite.harness import load_cases, run_case, write_telemetry  # noqa: E402
from tools.eval_suite.harness.runner import run_cases  # noqa: E402
from tools.eval_suite.harness.suts import get_sut  # noqa: E402


def main() -> int:
    p = argparse.ArgumentParser(description="Run the DDR eval suite once.")
    p.add_argument("--cases-root", default=os.path.join(REPO_ROOT, "tools", "eval_suite", "cases"))
    p.add_argument("--backend", default="mock",
                   choices=["mock", "direct_sql", "direct_mcp",
                            "databricks_mcp", "genie_code", "cursor_agent"])
    p.add_argument("--cursor-model", default="sonnet-4-5",
                   help="(cursor_agent only) Cursor model slug; e.g. sonnet-4-5, gpt-5-5.")
    p.add_argument("--cursor-timeout-s", type=int, default=600,
                   help="(cursor_agent only) hard wall-clock cap per case in seconds.")
    p.add_argument("--mcp-server-id", default="databricks-stg",
                   help="(direct_mcp only) Cursor MCP config key for the server to spawn.")
    p.add_argument("--llm-backend", default="databricks", choices=["databricks", "cursor"],
                   help="(direct_mcp only) LLM backend used to author SQL from skill bodies.")
    p.add_argument("--llm-model", default=None,
                   help="(direct_mcp only) override the LLM driver's default endpoint name "
                        "(e.g. databricks-claude-sonnet-4-6 or databricks-gpt-5-5).")
    p.add_argument("--baseline", default="none", choices=["none", "direct_sql"],
                   help="If a SUT case fails, also run this control-group SUT to "
                        "classify the failure as SKILL_GAP vs DATA_DRIFT.")
    p.add_argument("--rebaseline", action="store_true",
                   help="Run baseline (--baseline) FIRST on every case and use its "
                        "live value as the ground truth, instead of the YAML pin. "
                        "Requires --baseline. Use this when you want the SUT scored "
                        "against TODAY's UC data.")
    p.add_argument("--perturb-pct", type=float, default=0.0,
                   help="(mock only) perturb the returned value by this percent")
    p.add_argument("--tags", default="",
                   help="comma-separated tag list; keep cases matching ANY")
    p.add_argument("--case-id", action="append", default=[],
                   help="repeatable; restrict to specific case ids")
    p.add_argument("--out-csv", default=os.path.join(
        REPO_ROOT, "audits", "eval_suite", "runs",
        f"run-{dt.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}.csv",
    ))
    p.add_argument("--include-drafts", action="store_true")
    p.add_argument("--no-progress", action="store_true")
    p.add_argument("--judge", action="store_true",
                   help="Enable LLM-judge secondary scoring (requires ANTHROPIC_API_KEY).")
    args = p.parse_args()

    tags_any = [t.strip() for t in args.tags.split(",") if t.strip()] or None
    cases = load_cases(
        args.cases_root,
        include_drafts=args.include_drafts,
        tags_any=tags_any,
        case_ids=args.case_id or None,
    )
    if not cases:
        print("No cases matched the filter; nothing to do.")
        return 1

    print(f"Loaded {len(cases)} cases.")
    print(f"Backend: {args.backend}    Baseline: {args.baseline}    Judge: {args.judge}")
    if args.backend == "mock":
        sut = get_sut("mock", perturb_pct=args.perturb_pct)
    elif args.backend == "direct_sql":
        sut = get_sut("direct_sql")
    elif args.backend == "databricks_mcp":
        sut = get_sut("databricks_mcp")
    elif args.backend == "genie_code":
        sut = get_sut("genie_code")
    elif args.backend == "cursor_agent":
        sut = get_sut(
            "cursor_agent",
            model=args.cursor_model,
            workspace=REPO_ROOT,
            timeout_s=args.cursor_timeout_s,
        )
    elif args.backend == "direct_mcp":
        sut = get_sut(
            "direct_mcp",
            mcp_server_id=args.mcp_server_id,
            llm_backend=args.llm_backend,
            llm_model=args.llm_model,
        )
    else:  # pragma: no cover (argparse already constrained this)
        raise SystemExit(f"unknown backend: {args.backend}")

    baseline_sut = None
    if args.baseline == "direct_sql":
        baseline_sut = get_sut("direct_sql")

    if args.rebaseline and baseline_sut is None:
        raise SystemExit("--rebaseline requires --baseline (e.g. --baseline direct_sql).")

    print()
    try:
        results = run_cases(
            cases, sut,
            progress=not args.no_progress,
            baseline_sut=baseline_sut,
            rebaseline=args.rebaseline,
        )
    finally:
        # cursor_agent SUT installs `.cursor/rules/eval-mcp-only.mdc` at init;
        # remove it now so a Cursor session opened next has the normal corpus.
        close = getattr(sut, "close", None)
        if callable(close):
            try:
                close()
            except Exception:  # noqa: BLE001
                pass

    if args.judge:
        from tools.eval_suite.harness.scorer import judge_textual_inplace
        case_by_id = {c.case_id: c for c in cases}
        print()
        print("Running LLM judge over results...")
        judge_textual_inplace(results, case_by_id)

    n_pass = sum(1 for r in results if r.passed)
    n_fail = len(results) - n_pass
    print()
    print(f"Summary: {n_pass}/{len(results)} passed, {n_fail} failed.")

    if baseline_sut is not None:
        from collections import Counter
        verdicts = Counter(r.drift_verdict for r in results)
        print(f"Drift verdicts: {dict(verdicts)}")
    if args.judge:
        n_judge = sum(1 for r in results if r.judge_score is not None)
        n_correct = sum(1 for r in results if r.judge_label == "correct")
        print(f"Judge: {n_correct}/{n_judge} graded correct (model={results[0].judge_model if n_judge else 'n/a'})")

    out = write_telemetry(results, target="csv", out_path=args.out_csv)
    print(f"Telemetry: {out}")
    return 0 if n_fail == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
