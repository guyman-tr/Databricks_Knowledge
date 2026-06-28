#!/usr/bin/env python3
"""One-command daily auto_kb run (including Confluence MCP bridge).

Flow:
1) Fetch Confluence snapshot via agent-mediated MCP (SSO path)
2) Run the 5 watchers once (staging by default)
3) Build implications report
4) Run integrator
5) Emit a single run summary JSON/MD with per-step pass/fail
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.agent_runner import run_cursor_agent_prompt

OUT_ROOT = Path("Data_Skills_Automation/Auto_KB_Integrator/out")


def _run_cmd(name: str, cmd: list[str], timeout_sec: int) -> dict[str, Any]:
    started = dt.datetime.now(dt.timezone.utc)
    try:
        p = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout_sec,
        )
        ok = p.returncode == 0
        out = (p.stdout or "").strip()
        err = (p.stderr or "").strip()
        return {
            "name": name,
            "ok": ok,
            "returncode": p.returncode,
            "stdout_tail": out[-4000:],
            "stderr_tail": err[-2000:],
            "started_at": started.isoformat(timespec="seconds"),
            "ended_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        }
    except subprocess.TimeoutExpired as exc:
        out = (exc.stdout or "").strip()
        err = (exc.stderr or "").strip()
        return {
            "name": name,
            "ok": False,
            "returncode": None,
            "stdout_tail": out[-4000:],
            "stderr_tail": (err + "\nTIMEOUT").strip()[-2000:],
            "started_at": started.isoformat(timespec="seconds"),
            "ended_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        }


def _fetch_confluence_snapshot(snapshot_path: Path, lookback_days: int, workspace_cwd: Path) -> dict[str, Any]:
    prompt = (
        "You are running the Confluence MCP bridge for auto_kb.\n"
        "Use Atlassian MCP tools to build a JSON snapshot at the target path.\n"
        "Required flow:\n"
        "1) getAccessibleAtlassianResources\n"
        "2) searchConfluenceUsingCql with type=page and lastmodified >= now(\""
        f"-{lookback_days}d"
        "\") order by lastmodified desc, limit 25\n"
        "3) For the first 8 results, call getConfluencePage(contentFormat=markdown)\n"
        "4) Write JSON file shape: {\"pages\":[{page_id,space_key,title,version,last_modified,url,body}]}\n"
        f"5) Write to: {snapshot_path.as_posix()}\n"
        "6) Return exactly:\n"
        'RESULT_JSON:{"status":"done|error","pr_url":null,"notes":"short reason"}\n'
    )
    try:
        result = run_cursor_agent_prompt(
            prompt=prompt,
            workspace_cwd=workspace_cwd,
            model_id=None,
            timeout_seconds=240,
        )
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "notes": f"bridge exception: {exc}"}
    ok = result.final_status in {"done", "pushed"}
    return {"ok": ok, "notes": result.notes, "raw": result.raw_output[-2000:]}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--workspace-cwd", default=".", help="Workspace root")
    ap.add_argument("--staging", action="store_true", help="Run watchers in staging mode")
    ap.add_argument("--no-notify", action="store_true", help="Disable watcher notifications")
    ap.add_argument("--limit", type=int, default=1, help="Max items per watcher")
    ap.add_argument("--watcher-timeout-sec", type=int, default=420, help="Timeout per watcher process")
    ap.add_argument("--lookback-days", type=int, default=7, help="Confluence search lookback")
    ap.add_argument("--skip-confluence", action="store_true", help="Skip Confluence bridge + watcher entirely")
    ap.add_argument("--skip-confluence-bridge", action="store_true", help="Use existing snapshot instead of MCP bridge")
    ap.add_argument("--uc-detect-only", action="store_true", help="Run UC watcher in detect-only mode (no agent processing)")
    ap.add_argument("--questions-detect-only", action="store_true", help="Run Questions watcher in detect-only mode (no agent processing)")
    args = ap.parse_args()

    workspace = Path(args.workspace_cwd).resolve()
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    ts = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    conf_snapshot = Path("Data_Skills_Automation/Confluence_Watcher/runtime") / f"daily_bridge_snapshot_{ts}.json"
    bridge = {"ok": True, "notes": "confluence enabled"}
    if args.skip_confluence:
        bridge = {"ok": True, "notes": "confluence skipped by flag"}
    elif not args.skip_confluence_bridge:
        bridge = _fetch_confluence_snapshot(conf_snapshot, args.lookback_days, workspace)

    common_flags: list[str] = []
    if args.staging:
        common_flags.append("--staging")
    if args.no_notify:
        common_flags.append("--no-notify")

    steps: list[dict[str, Any]] = []
    steps.append(
        _run_cmd(
            "watcher_genie",
            [
                "python",
                "Data_Skills_Automation/Genie_Watcher/watch.py",
                *common_flags,
                "--workspace-cwd",
                str(workspace),
                "--limit",
                str(args.limit),
                "--snapshot",
                "Data_Skills_Automation/Genie_Watcher/runtime/daily_snapshot.json",
                "--manifest-out",
                "Data_Skills_Automation/Genie_Watcher/out/daily_manifest.json",
            ],
            args.watcher_timeout_sec,
        )
    )
    steps.append(
        _run_cmd(
            "watcher_uc_object",
            [
                "python",
                "Data_Skills_Automation/UC_Object_Watcher/watch.py",
                *common_flags,
                *(["--detect-only"] if args.uc_detect_only else []),
                "--workspace-cwd",
                str(workspace),
                "--limit",
                str(args.limit),
                "--snapshot",
                "Data_Skills_Automation/UC_Object_Watcher/runtime/daily_snapshot.json",
                "--manifest-out",
                "Data_Skills_Automation/UC_Object_Watcher/out/daily_manifest.json",
            ],
            args.watcher_timeout_sec,
        )
    )
    steps.append(
        _run_cmd(
            "watcher_dbschema",
            [
                "python",
                "Data_Skills_Automation/DBSchema_Lake_Watcher/watch.py",
                *common_flags,
                "--workspace-cwd",
                str(workspace),
                "--limit",
                str(args.limit),
                "--snapshot",
                "Data_Skills_Automation/DBSchema_Lake_Watcher/runtime/daily_snapshot.json",
                "--manifest-out",
                "Data_Skills_Automation/DBSchema_Lake_Watcher/out/daily_manifest.json",
            ],
            args.watcher_timeout_sec,
        )
    )
    steps.append(
        _run_cmd(
            "watcher_questions",
            [
                "python",
                "Data_Skills_Automation/Questions_Watcher/watch.py",
                *common_flags,
                *(["--detect-only"] if args.questions_detect_only else []),
                "--workspace-cwd",
                str(workspace),
                "--limit",
                str(args.limit),
                "--snapshot",
                "Data_Skills_Automation/Questions_Watcher/runtime/daily_snapshot.json",
                "--manifest-out",
                "Data_Skills_Automation/Questions_Watcher/out/daily_manifest.json",
            ],
            args.watcher_timeout_sec,
        )
    )

    if args.skip_confluence:
        steps.append(
            {
                "name": "watcher_confluence",
                "ok": True,
                "returncode": 0,
                "stdout_tail": "skipped by --skip-confluence",
                "stderr_tail": "",
                "started_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
                "ended_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
            }
        )
    else:
        confluence_cmd = [
            "python",
            "Data_Skills_Automation/Confluence_Watcher/watch.py",
            *common_flags,
            "--workspace-cwd",
            str(workspace),
            "--limit",
            str(args.limit),
            "--snapshot",
            "Data_Skills_Automation/Confluence_Watcher/runtime/daily_snapshot.json",
            "--manifest-out",
            "Data_Skills_Automation/Confluence_Watcher/out/daily_manifest.json",
        ]
        if bridge.get("ok"):
            confluence_cmd.extend(["--current", str(conf_snapshot).replace("\\", "/")])
        steps.append(_run_cmd("watcher_confluence", confluence_cmd, args.watcher_timeout_sec))

    steps.append(
        _run_cmd(
            "implications_report",
            ["python", "tools/auto_kb/implications_report.py", "--since-hours", "24"],
            180,
        )
    )
    steps.append(
        _run_cmd(
            "integrator",
            ["python", "tools/auto_kb/integrator_agent.py", "--agentic", "--workspace-cwd", str(workspace)],
            180,
        )
    )

    core_step_names = {"watcher_genie", "watcher_uc_object", "watcher_dbschema", "watcher_questions", "implications_report", "integrator"}
    core_ok = all(s["ok"] for s in steps if s["name"] in core_step_names)
    confluence_ok = True if args.skip_confluence else bridge.get("ok", False)
    overall_ok = core_ok and confluence_ok
    summary = {
        "run_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "staging": args.staging,
        "confluence_bridge": bridge,
        "steps": steps,
        "overall_ok": overall_ok,
    }

    out_json = OUT_ROOT / "daily_once_latest.json"
    out_md = OUT_ROOT / "daily_once_latest.md"
    out_json.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")

    lines = []
    lines.append("# Auto KB Daily Once Run")
    lines.append("")
    lines.append(f"- overall_ok: **{overall_ok}**")
    lines.append(f"- staging: `{args.staging}`")
    lines.append(f"- confluence_bridge_ok: `{bridge.get('ok', False)}`")
    lines.append(f"- confluence_bridge_notes: {bridge.get('notes', '')}")
    lines.append("")
    lines.append("## Step Results")
    for s in steps:
        lines.append(f"- `{s['name']}`: ok={s['ok']} returncode={s['returncode']}")
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"summary_json={out_json}")
    print(f"summary_md={out_md}")
    print(f"overall_ok={overall_ok}")
    return 0 if overall_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())

