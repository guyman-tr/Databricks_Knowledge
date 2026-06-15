"""Verify the Databricks foundation-model endpoint supports OpenAI-style
tool calling via raw HTTP to /serving-endpoints/{name}/invocations.

If this works, we can give the LLM a `describe_table` tool inside the eval
loop and have it call describe before emitting the final SQL.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request
import urllib.error

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from databricks.sdk import WorkspaceClient


SCHEMA = {
    "type": "function",
    "function": {
        "name": "describe_table",
        "description": "Return columns + types for a Databricks UC table.",
        "parameters": {
            "type": "object",
            "properties": {
                "fqn": {
                    "type": "string",
                    "description": "Three-part fully-qualified name, e.g. main.bi_db.gold_x",
                },
            },
            "required": ["fqn"],
        },
    },
}


def main() -> int:
    print("[1/2] Construct WorkspaceClient (profile=guyman)…")
    w = WorkspaceClient(profile="guyman")
    host = w.config.host.rstrip("/")
    headers = w.config.authenticate()
    headers["Content-Type"] = "application/json"
    print(f"  host={host}")

    endpoint = "databricks-claude-sonnet-4-6"
    url = f"{host}/serving-endpoints/{endpoint}/invocations"
    body = {
        "messages": [
            {"role": "system",
             "content": "You answer about Databricks UC. Use the describe_table "
                        "tool when you need column information for a table. "
                        "Do not guess column names; always describe first."},
            {"role": "user",
             "content": "What columns does "
                        "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum have?"},
        ],
        "tools": [SCHEMA],
        "tool_choice": "auto",
        "max_tokens": 400,
        "temperature": 0.0,
    }
    print(f"\n[2/2] POST {url}")
    req = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"),
                                 method="POST", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            text = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        err_body = ""
        try:
            err_body = e.read().decode("utf-8", errors="replace")
        except Exception:  # noqa: BLE001
            pass
        print(f"  FAIL HTTP {e.code} {e.reason}")
        print(f"  body: {err_body[:1500]}")
        return 1

    payload = json.loads(text)
    print("  raw response (truncated 3 KB):")
    print(json.dumps(payload, indent=2, default=str)[:3000])

    choices = payload.get("choices") or []
    tool_calls = []
    for c in choices:
        msg = c.get("message") or {}
        for tc in (msg.get("tool_calls") or []):
            tool_calls.append(tc)
    print(f"\n  tool_calls found: {len(tool_calls)}")
    for tc in tool_calls:
        fn = (tc.get("function") or {})
        print(f"    -> name={fn.get('name')!r} args={fn.get('arguments')!r}")

    if not tool_calls:
        print("\nWARN: model did not emit a tool_call.")
        return 2

    print("\nGreen — Databricks endpoint supports OpenAI tool-calling over HTTP.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
