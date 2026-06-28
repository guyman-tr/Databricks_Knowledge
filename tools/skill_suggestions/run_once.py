#!/usr/bin/env python3
"""Execute one autonomous processing cycle for skill suggestions."""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.update_status import ALLOWED_STATUS
from tools.skill_suggestions.agent_runner import run_cursor_agent_prompt


DEFAULT_MANIFEST = Path("tools/skill_suggestions/work_manifest.json")
DEFAULT_RUNTIME_ROOT = Path("tools/skill_suggestions/runtime")


@dataclass
class ItemResult:
    row_id: str
    final_status: str
    pr_url: str | None
    notes: str
    ok: bool


def _safe_slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def _run(cmd: list[str], cwd: str | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd,
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return proc.returncode, proc.stdout, proc.stderr


def _resolve_dataplatform_repo(workspace_cwd: Path) -> Path | None:
    """
    Resolve DataPlatform repo path from workspace root conventions:
    - <workspace>/DataPlatform
    - sibling of Databricks_Knowledge
    """
    candidate = workspace_cwd / "DataPlatform"
    if candidate.exists():
        return candidate
    if workspace_cwd.name.lower() == "databricks_knowledge":
        sibling = workspace_cwd.parent / "DataPlatform"
        if sibling.exists():
            return sibling
    return None


def _require_clean_dev_dataplatform(workspace_cwd: Path) -> None:
    """
    Hard preflight for live runs:
    - DataPlatform repo must exist
    - working tree must be clean
    - switch to dev branch
    - fast-forward pull origin/dev
    """
    dp_repo = _resolve_dataplatform_repo(workspace_cwd)
    if dp_repo is None:
        raise RuntimeError(
            "DataPlatform repo not found from workspace-cwd; expected <cwd>/DataPlatform "
            "or sibling of Databricks_Knowledge."
        )

    rc, out, err = _run(["git", "-C", str(dp_repo), "status", "--porcelain"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform git status failed: {err or out}")
    if out.strip():
        raise RuntimeError(
            "DataPlatform repo is not clean. Commit/stash/revert local changes before live run."
        )

    rc, out, err = _run(["git", "-C", str(dp_repo), "checkout", "dev"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform checkout dev failed: {err or out}")

    rc, out, err = _run(["git", "-C", str(dp_repo), "pull", "--ff-only", "origin", "dev"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform pull --ff-only origin dev failed: {err or out}")

    rc, out, err = _run(["git", "-C", str(dp_repo), "rev-parse", "--abbrev-ref", "HEAD"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform branch verify failed: {err or out}")
    if out.strip() != "dev":
        raise RuntimeError(f"DataPlatform branch is {out.strip()}, expected dev")


def _prepare_dataplatform_clean_dev(
    workspace_cwd: Path,
    auto_stash: bool,
) -> tuple[Path, str | None]:
    """
    Ensure DataPlatform is on clean dev and optionally stash pre-existing changes.
    Returns (dp_repo_path, stash_ref_name_or_none).
    """
    dp_repo = _resolve_dataplatform_repo(workspace_cwd)
    if dp_repo is None:
        raise RuntimeError(
            "DataPlatform repo not found from workspace-cwd; expected <cwd>/DataPlatform "
            "or sibling of Databricks_Knowledge."
        )

    stash_ref: str | None = None
    rc, out, err = _run(["git", "-C", str(dp_repo), "status", "--porcelain"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform git status failed: {err or out}")
    dirty = bool(out.strip())
    if dirty and not auto_stash:
        raise RuntimeError(
            "DataPlatform repo is not clean. Commit/stash/revert local changes before live run."
        )
    if dirty and auto_stash:
        marker = "user_submission_agent_auto_stash"
        rc, out, err = _run(
            [
                "git",
                "-C",
                str(dp_repo),
                "stash",
                "push",
                "-u",
                "-m",
                marker,
            ]
        )
        if rc != 0:
            raise RuntimeError(f"DataPlatform auto-stash failed: {err or out}")
        # Resolve newest stash ref; expected format stash@{0}
        rc, out, err = _run(
            ["git", "-C", str(dp_repo), "stash", "list", "-n", "1", "--format=%gd"]
        )
        if rc != 0:
            raise RuntimeError(f"DataPlatform stash ref resolve failed: {err or out}")
        stash_ref = out.strip() or None

    rc, out, err = _run(["git", "-C", str(dp_repo), "checkout", "dev"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform checkout dev failed: {err or out}")

    rc, out, err = _run(["git", "-C", str(dp_repo), "pull", "--ff-only", "origin", "dev"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform pull --ff-only origin dev failed: {err or out}")

    rc, out, err = _run(["git", "-C", str(dp_repo), "rev-parse", "--abbrev-ref", "HEAD"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform branch verify failed: {err or out}")
    if out.strip() != "dev":
        raise RuntimeError(f"DataPlatform branch is {out.strip()}, expected dev")

    rc, out, err = _run(["git", "-C", str(dp_repo), "status", "--porcelain"])
    if rc != 0:
        raise RuntimeError(f"DataPlatform post-check status failed: {err or out}")
    if out.strip():
        raise RuntimeError("DataPlatform is still dirty after clean-dev preparation.")

    return dp_repo, stash_ref


def _restore_dataplatform_stash(dp_repo: Path, stash_ref: str | None) -> str | None:
    """
    Restore stashed changes if auto-stash was used.
    Returns warning string on conflict/failure, otherwise None.
    """
    if not stash_ref:
        return None
    rc, out, err = _run(["git", "-C", str(dp_repo), "stash", "pop", stash_ref])
    if rc == 0:
        return None
    return (
        "DataPlatform auto-stash restore had conflicts. "
        f"stash_ref={stash_ref}. Resolve manually. Details: {(err or out).strip()}"
    )


def _notify(subject: str, body: str, status: str, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] notify status={status} subject={subject}")
        return
    cmd = [
        sys.executable,
        "tools/notify/notify.py",
        "--subject",
        subject,
        "--status",
        status,
        "--body",
        body,
        "--channel",
        "teams",
    ]
    rc, out, err = _run(cmd)
    if rc != 0:
        print(f"[warn] notify failed: {err or out}", file=sys.stderr)


def _update_row(
    *,
    row_id: str,
    status: str,
    notes: str,
    pr_url: str | None,
    dry_run: bool,
    skip_status_update: bool,
) -> None:
    if status not in ALLOWED_STATUS:
        raise ValueError(f"invalid status: {status}")
    if dry_run:
        print(f"[dry-run] update id={row_id} status={status} pr={pr_url} notes={notes[:120]}")
        return
    if skip_status_update:
        print(f"[no-status-update] id={row_id} status={status} pr={pr_url} notes={notes[:120]}")
        return
    cmd = [
        sys.executable,
        "tools/skill_suggestions/update_status.py",
        "--id",
        row_id,
        "--status",
        status,
        "--agent-notes",
        notes,
        "--set-processed-now",
    ]
    if pr_url:
        cmd.extend(["--pr-url", pr_url])
    rc, out, err = _run(cmd)
    if rc != 0:
        raise RuntimeError(f"update_status failed: {err or out}")


def _simulate_push_url(item: dict[str, Any]) -> str:
    title = str(item.get("title") or "skill-change")
    slug = _safe_slug(title) or "skill-change"
    return f"https://github.com/eToro/DataPlatform/pull/DRYRUN-{slug}"


def _materialize_new_skill_source(
    *,
    item: dict[str, Any],
    runtime_root: Path,
) -> Path:
    row_id = str(item.get("id") or "unknown")
    local_payload_path = str(item.get("local_payload_path") or "").strip()
    body_text = str(item.get("body_text") or "").strip()
    runtime_root.mkdir(parents=True, exist_ok=True)
    target_dir = runtime_root / row_id
    target_dir.mkdir(parents=True, exist_ok=True)

    if local_payload_path and Path(local_payload_path).exists():
        return Path(local_payload_path)

    if body_text:
        draft_path = target_dir / "submission.md"
        draft_path.write_text(body_text, encoding="utf-8")
        return draft_path

    raise RuntimeError("new_skill has no usable payload path and empty body_text")


def _model_for(role: str) -> str | None:
    """
    Resolve model by role with environment overrides:
    - CURSOR_AGENT_MODEL_<ROLE> (e.g. CURSOR_AGENT_MODEL_INGEST)
    - CURSOR_AGENT_MODEL
    - None (SDK default)
    """
    role_key = f"CURSOR_AGENT_MODEL_{role.upper()}"
    return os.environ.get(role_key) or os.environ.get("CURSOR_AGENT_MODEL")


def _build_agent_prompt_for_new_skill(
    source_path: Path,
    item: dict[str, Any],
    execution_mode: str,
) -> str:
    title = str(item.get("title") or "new skill submission")
    if execution_mode == "ingest_only":
        return (
            "You are executing an autonomous skill submission request.\n"
            "Process this NEW SKILL submission in the current workspace:\n"
            f"- title: {title}\n"
            f"- source_path: {source_path}\n\n"
            "Required flow:\n"
            "1) Run /skills-ingest for the source path.\n"
            "2) Do NOT run /skills-push in this mode.\n"
            "3) Return one line exactly in this format:\n"
            "RESULT_JSON:{\"status\":\"pushed|skipped_overlap|error\",\"pr_url\":null,\"notes\":\"short reason\"}\n"
            "Use status=pushed when ingest passes in ingest_only mode.\n"
        )
    return (
        "You are executing an autonomous skill submission request.\n"
        "Process this NEW SKILL submission end-to-end in the current workspace:\n"
        f"- title: {title}\n"
        f"- source_path: {source_path}\n\n"
        "Required flow:\n"
        "1) Run /skills-ingest for the source path.\n"
        "2) If overlap-prevention says STOP (same-tables-same-purpose), do NOT push; return skipped_overlap.\n"
        "3) If ingest succeeds, run /skills-push.\n"
        "4) Return one line exactly in this format:\n"
        "RESULT_JSON:{\"status\":\"pushed|skipped_overlap|error\",\"pr_url\":\"<url or null>\",\"notes\":\"short reason\"}\n"
        "If pushed, include actual DataPlatform PR URL.\n"
    )


def _build_agent_prompt_for_push_only(item: dict[str, Any]) -> str:
    title = str(item.get("title") or "new skill submission")
    return (
        "You are executing an autonomous skill submission request.\n"
        "INGEST is already complete. Run only push phase in the current workspace:\n"
        f"- title: {title}\n\n"
        "Required flow:\n"
        "1) Run /skills-push.\n"
        "2) Return one line exactly in this format:\n"
        "RESULT_JSON:{\"status\":\"pushed|error\",\"pr_url\":\"<url or null>\",\"notes\":\"short reason\"}\n"
        "If pushed, include actual DataPlatform PR URL.\n"
    )


def _build_agent_prompt_for_correction(item: dict[str, Any]) -> str:
    target_skill = str(item.get("target_skill") or "")
    details = str(item.get("body_text") or "")
    title = str(item.get("title") or "skill correction")
    return (
        "You are executing an autonomous skill correction request.\n"
        "Process this CORRECTION end-to-end in the current workspace:\n"
        f"- title: {title}\n"
        f"- target_skill: {target_skill}\n"
        f"- correction_request: {details}\n\n"
        "Required flow:\n"
        "1) Apply a surgical edit only for the requested correction in the target skill.\n"
        "2) Bump version/validation metadata as required by skill rules.\n"
        "3) Validate using the canonical skills validators.\n"
        "4) Run /skills-push.\n"
        "5) Return one line exactly in this format:\n"
        "RESULT_JSON:{\"status\":\"pushed|error\",\"pr_url\":\"<url or null>\",\"notes\":\"short reason\"}\n"
        "If pushed, include actual DataPlatform PR URL.\n"
    )


def _process_new_skill(
    item: dict[str, Any],
    dry_run: bool,
    workspace_cwd: Path,
    runtime_root: Path,
    execution_mode: str,
) -> ItemResult:
    row_id = str(item.get("id") or "")
    body_text = str(item.get("body_text") or "").strip()
    local_payload = str(item.get("local_payload_path") or "").strip()

    if not row_id:
        return ItemResult("", "error", None, "missing row id", False)

    # Minimal gating for now: at least one source (text or payload path).
    if not body_text and not local_payload:
        return ItemResult(row_id, "error", None, "new_skill missing body_text and payload path", False)

    if dry_run:
        pr_url = _simulate_push_url(item)
        notes = "new_skill processed via dry-run simulation."
        return ItemResult(row_id, "pushed", pr_url, notes, True)

    source_path = _materialize_new_skill_source(item=item, runtime_root=runtime_root)
    if execution_mode == "ingest_only":
        prompt = _build_agent_prompt_for_new_skill(source_path, item, execution_mode)
        result = run_cursor_agent_prompt(
            prompt=prompt,
            workspace_cwd=workspace_cwd,
            model_id=_model_for("ingest"),
        )
        ok = result.final_status in {"pushed", "skipped_overlap"}
        status = result.final_status if result.final_status in ALLOWED_STATUS else "error"
        return ItemResult(row_id, status, result.pr_url, result.notes, ok)

    # Full mode: split semantic-heavy ingest from lower-complexity push.
    ingest_prompt = _build_agent_prompt_for_new_skill(source_path, item, execution_mode="ingest_only")
    ingest_result = run_cursor_agent_prompt(
        prompt=ingest_prompt,
        workspace_cwd=workspace_cwd,
        model_id=_model_for("ingest"),
    )
    ingest_status = ingest_result.final_status if ingest_result.final_status in ALLOWED_STATUS else "error"
    if ingest_status == "skipped_overlap":
        return ItemResult(
            row_id,
            "skipped_overlap",
            None,
            f"ingest skipped overlap: {ingest_result.notes}",
            True,
        )
    if ingest_status != "pushed":
        return ItemResult(
            row_id,
            "error",
            None,
            f"ingest failed: {ingest_result.notes}",
            False,
        )

    push_prompt = _build_agent_prompt_for_push_only(item)
    push_result = run_cursor_agent_prompt(
        prompt=push_prompt,
        workspace_cwd=workspace_cwd,
        model_id=_model_for("push"),
    )
    push_status = push_result.final_status if push_result.final_status in ALLOWED_STATUS else "error"
    ok = push_status == "pushed"
    notes = f"ingest ok; push result: {push_result.notes}"
    return ItemResult(row_id, push_status, push_result.pr_url, notes, ok)


def _process_correction(item: dict[str, Any], dry_run: bool, workspace_cwd: Path) -> ItemResult:
    row_id = str(item.get("id") or "")
    target_skill = str(item.get("target_skill") or "").strip()
    body_text = str(item.get("body_text") or "").strip()
    if not row_id:
        return ItemResult("", "error", None, "missing row id", False)
    if not target_skill:
        return ItemResult(row_id, "error", None, "correction missing target_skill", False)
    if not body_text:
        return ItemResult(row_id, "error", None, "correction missing body_text", False)

    if dry_run:
        pr_url = _simulate_push_url(item)
        notes = f"correction for {target_skill} processed via dry-run simulation."
        return ItemResult(row_id, "pushed", pr_url, notes, True)

    prompt = _build_agent_prompt_for_correction(item)
    result = run_cursor_agent_prompt(
        prompt=prompt,
        workspace_cwd=workspace_cwd,
        model_id=_model_for("correction"),
    )
    ok = result.final_status in {"pushed"}
    status = result.final_status if result.final_status in ALLOWED_STATUS else "error"
    return ItemResult(row_id, status, result.pr_url, result.notes, ok)


def _process_item(
    item: dict[str, Any],
    dry_run: bool,
    workspace_cwd: Path,
    runtime_root: Path,
    execution_mode: str,
) -> ItemResult:
    req_type = str(item.get("request_type") or "").strip().lower()
    if req_type == "new_skill":
        return _process_new_skill(item, dry_run, workspace_cwd, runtime_root, execution_mode)
    if req_type == "correction":
        return _process_correction(item, dry_run, workspace_cwd)
    row_id = str(item.get("id") or "")
    return ItemResult(row_id, "error", None, f"unsupported request_type={req_type!r}", False)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="Manifest path from scan.py")
    ap.add_argument("--dry-run", action="store_true", help="Do not update DB or send external notifications")
    ap.add_argument("--stop-on-error", action="store_true", help="Stop processing after first error")
    ap.add_argument(
        "--no-status-update",
        action="store_true",
        help="Skip update_status.py calls (useful for local live smoke tests).",
    )
    ap.add_argument(
        "--no-notify",
        action="store_true",
        help="Skip Teams notifications (useful for local live smoke tests).",
    )
    ap.add_argument(
        "--workspace-cwd",
        default=".",
        help="Workspace root for live Cursor SDK execution",
    )
    ap.add_argument(
        "--runtime-root",
        default=str(DEFAULT_RUNTIME_ROOT),
        help="Runtime temp root for materialized submission payloads",
    )
    ap.add_argument(
        "--execution-mode",
        choices=["full", "ingest_only"],
        default="full",
        help="full=ingest+push, ingest_only=run ingest gate only",
    )
    ap.add_argument(
        "--auto-stash-dataplatform",
        action="store_true",
        help="If DataPlatform is dirty, stash it temporarily, run on clean dev, then restore stash.",
    )
    args = ap.parse_args()

    manifest_path = Path(args.manifest)
    workspace_cwd = Path(args.workspace_cwd).resolve()
    runtime_root = Path(args.runtime_root)
    if not args.dry_run and not os.environ.get("CURSOR_API_KEY"):
        raise SystemExit(
            "live mode requires CURSOR_API_KEY for cursor_sdk Agent.prompt. "
            "Set CURSOR_API_KEY or run with --dry-run."
        )
    dp_repo: Path | None = None
    dp_stash_ref: str | None = None
    if not args.dry_run and args.execution_mode == "full":
        dp_repo, dp_stash_ref = _prepare_dataplatform_clean_dev(
            workspace_cwd,
            args.auto_stash_dataplatform,
        )
    if not manifest_path.exists():
        raise SystemExit(f"manifest not found: {manifest_path}")

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    items = data.get("items") or []
    if not isinstance(items, list):
        raise SystemExit("manifest.items must be a list")

    print(f"processing {len(items)} item(s) from {manifest_path}")
    failures = 0
    results: list[dict[str, Any]] = []
    for item in items:
        row_id = str(item.get("id") or "")
        try:
            result = _process_item(
                item,
                args.dry_run,
                workspace_cwd,
                runtime_root,
                args.execution_mode,
            )
            _update_row(
                row_id=result.row_id,
                status=result.final_status,
                notes=result.notes,
                pr_url=result.pr_url,
                dry_run=args.dry_run,
                skip_status_update=args.no_status_update,
            )
            n_status = "ok" if result.ok else "fail"
            if not args.no_notify:
                _notify(
                    subject=f"User Submission Agent: {result.final_status} ({row_id})",
                    body=f"row_id={row_id}\nstatus={result.final_status}\npr_url={result.pr_url}\nnotes={result.notes}",
                    status=n_status,
                    dry_run=args.dry_run,
                )
            if not result.ok:
                failures += 1
            results.append(
                {
                    "id": row_id,
                    "status": result.final_status,
                    "pr_url": result.pr_url,
                    "ok": result.ok,
                    "notes": result.notes,
                }
            )
            if failures and args.stop_on_error:
                break
        except Exception as exc:  # noqa: BLE001
            failures += 1
            err_note = f"exception: {exc}"
            if row_id:
                try:
                    _update_row(
                        row_id=row_id,
                        status="error",
                        notes=err_note,
                        pr_url=None,
                        dry_run=args.dry_run,
                        skip_status_update=args.no_status_update,
                    )
                    if not args.no_notify:
                        _notify(
                            subject=f"User Submission Agent: error ({row_id})",
                            body=err_note,
                            status="fail",
                            dry_run=args.dry_run,
                        )
                except Exception as nested:  # noqa: BLE001
                    print(f"[warn] failed to record error for {row_id}: {nested}", file=sys.stderr)
            results.append({"id": row_id, "status": "error", "ok": False, "notes": err_note})
            if args.stop_on_error:
                break

    summary = {
        "total": len(items),
        "failures": failures,
        "dry_run": args.dry_run,
        "results": results,
    }
    restore_warning = None
    if not args.dry_run and dp_repo is not None:
        restore_warning = _restore_dataplatform_stash(dp_repo, dp_stash_ref)
        if restore_warning:
            summary["restore_warning"] = restore_warning
            failures += 1

    print(json.dumps(summary, indent=2))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
