#!/usr/bin/env python3
"""6th end-of-run integrator for auto_kb watcher outputs.

Consumes six artifacts:
1) genie manifest
2) uc_object manifest
3) dbschema manifest
4) confluence manifest
5) questions manifest
6) implications_rows.csv

Produces integrated summary artifacts for the daily handoff. Supports:
- deterministic mode (always on)
- agentic augmentation (optional) via cursor_sdk bridge
"""
from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path
import sys
import re

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.agent_runner import run_cursor_agent_prompt

DEFAULT_OUT_DIR = Path("Data_Skills_Automation/Auto_KB_Integrator/out")


def _pick_manifest(app_dir: Path) -> Path | None:
    out = app_dir / "out"
    if not out.exists():
        return None
    candidates = sorted(out.glob("*manifest*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    return candidates[0] if candidates else None


def load_manifest(path: Path | None) -> dict:
    if path is None or not path.exists():
        return {"app": "", "new": [], "changed": [], "removed": [], "items": []}
    return json.loads(path.read_text(encoding="utf-8"))


def load_implications_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def build_deterministic_summary(manifests: dict[str, dict], implications_rows: list[dict[str, str]]) -> dict:
    app_stats = {}
    for app, m in manifests.items():
        app_stats[app] = {
            "new": len(m.get("new", [])),
            "changed": len(m.get("changed", [])),
            "removed": len(m.get("removed", [])),
            "processed_items": len(m.get("items", [])),
        }

    implication_counts = Counter((r.get("implication") or "OTHER") for r in implications_rows)
    recent_errors = [
        {
            "app": r.get("app", ""),
            "item_id": r.get("item_id", ""),
            "notes": r.get("notes", ""),
            "processed_at": r.get("processed_at", ""),
        }
        for r in implications_rows
        if (r.get("implication") or "") == "BLOCKER"
    ][:10]

    return {
        "app_stats": app_stats,
        "implication_counts": dict(implication_counts),
        "recent_blockers": recent_errors,
        "overall_health": "blocked" if recent_errors else "healthy",
    }


def write_summary_csv(path: Path, summary: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["section", "key", "subkey", "value"])
        for app, stats in summary["app_stats"].items():
            for k, v in stats.items():
                w.writerow(["app_stats", app, k, v])
        for k, v in summary["implication_counts"].items():
            w.writerow(["implication_counts", k, "", v])
        for b in summary["recent_blockers"]:
            w.writerow(["recent_blockers", b["app"], b["item_id"], b["notes"]])
        w.writerow(["overall", "overall_health", "", summary["overall_health"]])


def write_summary_md(path: Path, summary: dict, manifests_used: dict[str, str], rows_path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    lines.append("# Auto KB Integrated Daily Summary")
    lines.append("")
    lines.append(f"- Overall health: **{summary['overall_health']}**")
    lines.append(f"- Implication rows source: `{rows_path}`")
    lines.append("")
    lines.append("## Inputs (5 outputs)")
    for app, p in manifests_used.items():
        lines.append(f"- `{app}` manifest: `{p}`")
    lines.append(f"- implications rows: `{rows_path}`")
    lines.append("")
    lines.append("## App Stats")
    for app, stats in summary["app_stats"].items():
        lines.append(
            f"- `{app}`: new={stats['new']}, changed={stats['changed']}, removed={stats['removed']}, processed_items={stats['processed_items']}"
        )
    lines.append("")
    lines.append("## Implication Counts")
    for k, v in sorted(summary["implication_counts"].items()):
        lines.append(f"- `{k}`: {v}")
    lines.append("")
    lines.append("## Blockers")
    if not summary["recent_blockers"]:
        lines.append("- none")
    else:
        for b in summary["recent_blockers"]:
            lines.append(f"- `{b['app']}` `{b['item_id']}`: {b['notes']}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_agentic_appendix(summary: dict, out_path: Path, workspace_cwd: Path, timeout_seconds: int) -> str:
    prompt = (
        "You are the Auto KB 6th integrator agent. "
        "Given this deterministic daily summary JSON, write a concise operational appendix with: "
        "1) Top 3 implications for skill/domain maintenance; "
        "2) Promotion decision (Go/No-Go) with reason; "
        "3) Immediate next actions for the watcher owners. "
        "Return RESULT_JSON with status done|error and notes containing markdown only.\n\n"
        f"SUMMARY_JSON:\n{json.dumps(summary, ensure_ascii=False)}"
    )
    try:
        result = run_cursor_agent_prompt(
            prompt=prompt,
            workspace_cwd=workspace_cwd,
            model_id=None,
            timeout_seconds=timeout_seconds,
        )
    except Exception as exc:  # noqa: BLE001
        out_path.write_text(f"Agentic appendix unavailable: {exc}\n", encoding="utf-8")
        return f"error: {exc}"

    if result.notes.startswith("live run completed (RESULT_JSON not found; parsed fallback)"):
        raw = (result.raw_output or "").strip()
        # Accept common fallback shape: fenced JSON with {"status":"done","notes":"..."}.
        m = re.search(r"\{[\s\S]*\"status\"[\s\S]*\"notes\"[\s\S]*\}", raw)
        if m:
            try:
                parsed = json.loads(m.group(0))
                notes = str(parsed.get("notes", "")).strip()
                status = str(parsed.get("status", "error")).strip().lower() or "error"
                if notes:
                    out_path.write_text(notes + "\n", encoding="utf-8")
                    return status
            except Exception:
                pass

        snippet = raw
        if len(snippet) > 2000:
            snippet = snippet[:2000] + "\n...<truncated>"
        out_path.write_text(
            "Agentic appendix unavailable: integrator agent did not return RESULT_JSON.\n\n"
            "Raw output snippet:\n"
            f"{snippet}\n",
            encoding="utf-8",
        )
        return "error"

    text = (result.notes or "").strip()
    out_path.write_text((text + "\n") if text else "Agentic appendix empty.\n", encoding="utf-8")
    return result.final_status


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out-dir", default=str(DEFAULT_OUT_DIR), help="Output directory")
    ap.add_argument("--implications-rows", default="", help="Override implications_rows.csv path")
    ap.add_argument("--agentic", action="store_true", help="Run agentic appendix generation")
    ap.add_argument("--workspace-cwd", default=".", help="Workspace root for agentic mode")
    ap.add_argument("--agent-timeout-seconds", type=int, default=120, help="Agent timeout in seconds")
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    implications_rows_path = (
        Path(args.implications_rows)
        if args.implications_rows
        else (out_dir / "implications_rows_latest_run.csv")
    )
    if not implications_rows_path.exists() and not args.implications_rows:
        implications_rows_path = out_dir / "implications_rows.csv"

    apps = {
        "genie": Path("Data_Skills_Automation/Genie_Watcher"),
        "uc_object": Path("Data_Skills_Automation/UC_Object_Watcher"),
        "dbschema": Path("Data_Skills_Automation/DBSchema_Lake_Watcher"),
        "confluence": Path("Data_Skills_Automation/Confluence_Watcher"),
        "questions": Path("Data_Skills_Automation/Questions_Watcher"),
    }

    manifests: dict[str, dict] = {}
    manifests_used: dict[str, str] = {}
    for app, root in apps.items():
        p = _pick_manifest(root)
        manifests[app] = load_manifest(p)
        manifests_used[app] = str(p) if p else "(missing)"

    implications_rows = load_implications_rows(implications_rows_path)
    summary = build_deterministic_summary(manifests, implications_rows)

    summary_json = out_dir / "integrated_summary.json"
    summary_csv = out_dir / "integrated_summary.csv"
    summary_md = out_dir / "integrated_summary.md"
    appendix_md = out_dir / "integrated_agentic_appendix.md"

    out_dir.mkdir(parents=True, exist_ok=True)
    summary_json.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    write_summary_csv(summary_csv, summary)
    write_summary_md(summary_md, summary, manifests_used, implications_rows_path)

    agentic_status = "not_run"
    if args.agentic:
        agentic_status = run_agentic_appendix(
            summary=summary,
            out_path=appendix_md,
            workspace_cwd=Path(args.workspace_cwd).resolve(),
            timeout_seconds=args.agent_timeout_seconds,
        )

    print(f"summary_json={summary_json}")
    print(f"summary_csv={summary_csv}")
    print(f"summary_md={summary_md}")
    print(f"agentic_status={agentic_status}")
    if args.agentic:
        print(f"agentic_appendix={appendix_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
