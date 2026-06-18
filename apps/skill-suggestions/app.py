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


TABLE_FQN = "main.de_output.skill_suggestions"
DEFAULT_WAREHOUSE_ID = "208214768b0e0308"
VOLUME_ROOT = Path("/Volumes/main/de_output/skill_submissions")


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

with st.form("skill_suggestion_form", clear_on_submit=True):
    submitter = st.text_input("Submitter", placeholder="name or email")
    request_type = st.selectbox(
        "Request type",
        options=["new_skill", "correction"],
        help="new_skill: one or more markdown files. correction: specific fix request for an existing skill.",
    )
    target_skill = st.text_input(
        "Target skill (for correction only)",
        placeholder="domain-customer-and-identity",
    )
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
