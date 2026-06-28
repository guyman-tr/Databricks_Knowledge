from __future__ import annotations

import os
import re
import time
import uuid
from pathlib import Path
from typing import Iterable

import streamlit as st
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState


TABLE_FQN = "main.de_output.de_output_skills_automation_user_suggestions_agent"
DEFAULT_WAREHOUSE_ID = "208214768b0e0308"
VOLUME_ROOT = Path("/Volumes/main/de_output/skills_automation_user_suggestions_agent_files")
APP_BUILD = "2026-06-18 12:54 UTC"
SKILL_WORKSPACE_ROOTS = [
    "/Workspace/Users/guyman@etoro.com/Databricks_Knowledge/knowledge/skills",
    "/Workspace/Users/guyman@etoro.com/Databricks_Knowledge/.cursor/skills",
]


def _safe_name(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9._-]+", "_", name)


def _sql_quote(value: str) -> str:
    return value.replace("'", "''")


def _get_warehouse_id() -> str:
    return os.environ.get("DATABRICKS_WAREHOUSE_ID", DEFAULT_WAREHOUSE_ID).strip()


def _run_sql(statement: str) -> None:
    w = WorkspaceClient()
    resp = w.statement_execution.execute_statement(
        warehouse_id=_get_warehouse_id(),
        statement=statement,
        wait_timeout="50s",
    )
    sid = resp.statement_id
    state = resp.status.state
    while state in (StatementState.PENDING, StatementState.RUNNING):
        time.sleep(2.0)
        resp = w.statement_execution.get_statement(sid)
        state = resp.status.state
    if state != StatementState.SUCCEEDED:
        err = getattr(resp.status, "error", None)
        msg = err.message if err else f"state={state}"
        raise RuntimeError(msg)


def _run_sql_query(statement: str) -> list[list[str]]:
    w = WorkspaceClient()
    resp = w.statement_execution.execute_statement(
        warehouse_id=_get_warehouse_id(),
        statement=statement,
        wait_timeout="50s",
    )
    sid = resp.statement_id
    state = resp.status.state
    while state in (StatementState.PENDING, StatementState.RUNNING):
        time.sleep(2.0)
        resp = w.statement_execution.get_statement(sid)
        state = resp.status.state
    if state != StatementState.SUCCEEDED:
        err = getattr(resp.status, "error", None)
        msg = err.message if err else f"state={state}"
        raise RuntimeError(msg)
    if not resp.result or not resp.result.data_array:
        return []
    return resp.result.data_array


def _skill_name_from_workspace_path(path: str) -> str | None:
    norm = path.replace("\\", "/")
    if not norm.endswith("/SKILL.md"):
        return None
    parts = [p for p in norm.split("/") if p]
    if len(parts) < 2:
        return None
    return parts[-2].strip()


def _collect_workspace_skills(client: WorkspaceClient, root: str, depth: int = 0) -> set[str]:
    if depth > 5:
        return set()
    out: set[str] = set()
    try:
        items = list(client.workspace.list(root))
    except Exception:
        return out
    for item in items:
        item_path = item.path or ""
        item_type = str(item.object_type or "").upper()
        skill_name = _skill_name_from_workspace_path(item_path)
        if skill_name:
            out.add(skill_name)
            continue
        if item_type.endswith("DIRECTORY"):
            out.update(_collect_workspace_skills(client, item_path, depth + 1))
    return out


def _load_seed_skills() -> set[str]:
    seed_path = Path(__file__).with_name("skill_options_seed.txt")
    if not seed_path.exists():
        return set()
    out: set[str] = set()
    for raw in seed_path.read_text(encoding="utf-8").splitlines():
        value = raw.strip()
        if not value or value.startswith("#"):
            continue
        out.add(value)
    return out


def _group_for_skill(skill_name: str) -> str:
    name = (skill_name or "").strip().lower()
    if name.startswith("domain-"):
        return "domain"
    if name.startswith("subdomain-"):
        return "subdomain"
    if name.startswith("cross-") or name.startswith("cross_"):
        return "cross"
    return "other"


def _build_grouped_skill_labels(skill_names: list[str]) -> tuple[list[str], dict[str, str]]:
    group_rank = {"domain": 0, "subdomain": 1, "cross": 2, "other": 3}
    sorted_skills = sorted(
        skill_names,
        key=lambda s: (group_rank.get(_group_for_skill(s), 99), s.lower()),
    )
    labels: list[str] = []
    label_to_skill: dict[str, str] = {}
    for skill in sorted_skills:
        label = f"[{_group_for_skill(skill)}] {skill}"
        labels.append(label)
        label_to_skill[label] = skill
    return labels, label_to_skill


@st.cache_data(ttl=300)
def _load_skill_options() -> list[str]:
    out: set[str] = _load_seed_skills()

    # Existing correction targets from queue history.
    try:
        rows = _run_sql_query(
            f"""
SELECT DISTINCT target_skill
FROM {TABLE_FQN}
WHERE target_skill IS NOT NULL AND TRIM(target_skill) <> ''
ORDER BY target_skill
""".strip()
        )
        for row in rows:
            if not row:
                continue
            val = str(row[0] or "").strip()
            if val:
                out.add(val)
    except Exception:
        pass

    # Skill files from workspace repo snapshots (best-effort, may be empty under app service principal).
    try:
        w = WorkspaceClient()
        for root in SKILL_WORKSPACE_ROOTS:
            out.update(_collect_workspace_skills(w, root))
    except Exception:
        pass

    return sorted(out)


def _write_files(submission_id: str, files: Iterable) -> str | None:
    files = list(files)
    if not files:
        return None
    target = VOLUME_ROOT / submission_id
    target.mkdir(parents=True, exist_ok=True)
    for f in files:
        filename = _safe_name(f.name)
        (target / filename).write_bytes(f.read())
    return str(target)


def _insert_submission(
    *,
    submission_id: str,
    submitter: str,
    request_type: str,
    target_skill: str,
    title: str,
    body_text: str,
    volume_path: str | None,
) -> None:
    sql = f"""
INSERT INTO {TABLE_FQN} (
  id, submitted_at, submitter, request_type, target_skill,
  title, body_text, volume_path, status, pr_url, processed_at, agent_notes
) VALUES (
  '{_sql_quote(submission_id)}',
  current_timestamp(),
  '{_sql_quote(submitter)}',
  '{_sql_quote(request_type)}',
  {f"'{_sql_quote(target_skill)}'" if target_skill else "NULL"},
  '{_sql_quote(title)}',
  {f"'{_sql_quote(body_text)}'" if body_text else "NULL"},
  {f"'{_sql_quote(volume_path)}'" if volume_path else "NULL"},
  'new',
  NULL,
  NULL,
  NULL
)
""".strip()
    _run_sql(sql)


st.set_page_config(page_title="Skill Suggestions", layout="centered")
st.title("Skill Suggestions")
st.caption("Submit new skill bundles or targeted fixes for existing skills.")
st.caption(f"Build: {APP_BUILD}")
st.info(
    "This app queues your request for the autonomous skills agent: it stores your submission in Unity Catalog, "
    "then the daily worker picks it up and runs ingest/push with status updates."
)

skill_options = _load_skill_options()
skill_option_labels, label_to_skill = _build_grouped_skill_labels(skill_options)
skill_options_for_ui = skill_option_labels if skill_option_labels else [""]

with st.form("skill_suggestion_form", clear_on_submit=True):
    submitter = st.text_input("Submitter", placeholder="name or email")
    request_type = st.selectbox(
        "Request type",
        options=["new_skill", "correction"],
        help="new_skill: one or more markdown files. correction: specific fix request for an existing skill.",
    )
    st.selectbox(
        "Target skill (searchable)",
        options=["Coming soon"],
        index=0,
        disabled=True,
        help="Coming soon: searchable skill picker requires additional workspace-read permissions for the app principal.",
    )
    target_skill = st.text_input(
        "Target skill name",
        placeholder="e.g. Trading & Markets",
        help="Use the business name of the skill; the agent will map it to the canonical skill id.",
    ).strip()
    title = st.text_input("Title", placeholder="Short summary")
    body_text = st.text_area(
        "Details",
        placeholder="For corrections: 'skill domain-xxx is wrong on yyy'. For new skills: optional context.",
        height=180,
    )
    files = st.file_uploader(
        "Upload markdown files (.md) for new skill requests",
        type=["md"],
        accept_multiple_files=True,
    )
    submit = st.form_submit_button("Submit")

if submit:
    if not submitter.strip():
        st.error("Submitter is required.")
        st.stop()
    if not title.strip():
        st.error("Title is required.")
        st.stop()
    if request_type == "correction" and not target_skill.strip():
        st.error("Target skill is required for correction requests.")
        st.stop()
    if request_type == "new_skill" and not body_text.strip() and not files:
        st.error("Provide either markdown files or detail text for new_skill requests.")
        st.stop()

    submission_id = str(uuid.uuid4())
    try:
        volume_path = _write_files(submission_id, files)
        _insert_submission(
            submission_id=submission_id,
            submitter=submitter.strip(),
            request_type=request_type,
            target_skill=target_skill.strip(),
            title=title.strip(),
            body_text=body_text.strip(),
            volume_path=volume_path,
        )
        st.success(f"Submitted. ID: {submission_id}")
        if volume_path:
            st.info(f"Uploaded files: {volume_path}")
    except Exception as exc:  # noqa: BLE001
        st.error(f"Submission failed: {exc}")
