"""Smoke-test the MCPStdioClient against `databricks-stg`.

Goals:
  1. Spawn `npx mcp-remote ...` from Python.
  2. Complete the JSON-RPC `initialize` handshake.
  3. List available tools.
  4. Call `skills_find_skills` with "how many funded users yesterday".
  5. Call `databricks_ops_execute_sql` with a trivial SELECT 1.

If any step fails, print stderr tail so we can diagnose.
"""
from __future__ import annotations

import json
import sys
import textwrap
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

from tools.eval_suite.harness.suts._mcp_client import (
    MCPStdioClient,
    MCPClientError,
    load_mcp_command_from_cursor_config,
)


def main() -> int:
    server_id = "databricks-stg"
    print(f"[1/5] Loading MCP command for {server_id!r} from ~/.cursor/mcp.json")
    cmd = load_mcp_command_from_cursor_config(server_id)
    print(f"      cmd[0]={cmd[0]}  args={cmd[1:3]}...  (total argv items: {len(cmd)})")

    print(f"\n[2/5] Spawning subprocess + initialize handshake")
    t0 = time.monotonic()
    with MCPStdioClient(cmd, request_timeout_s=60) as cli:
        try:
            info = cli.initialize()
        except Exception as e:
            print(f"  initialize FAILED: {type(e).__name__}: {e}")
            print(f"  stderr tail:\n{textwrap.indent(cli.stderr_tail(), '    ')}")
            return 1
        dt = time.monotonic() - t0
        srv = info.get("serverInfo") or {}
        print(f"      OK in {dt:.1f}s — server={srv.get('name')!r} "
              f"version={srv.get('version')!r}  protocol={info.get('protocolVersion')!r}")

        print(f"\n[3/5] tools/list")
        try:
            tools = cli.list_tools()
        except Exception as e:
            print(f"  tools/list FAILED: {e}")
            print(f"  stderr tail:\n{textwrap.indent(cli.stderr_tail(), '    ')}")
            return 1
        names = [t.get("name") for t in tools]
        print(f"      OK — {len(names)} tools advertised")
        for n in names:
            print(f"        - {n}")

        print(f"\n[4/5] skills_find_skills 'how many funded users yesterday'")
        try:
            r = cli.call_tool("skills_find_skills", {
                "question": "how many funded users yesterday",
                "k": 3,
            })
        except Exception as e:
            print(f"  call FAILED: {e}")
            print(f"  stderr tail:\n{textwrap.indent(cli.stderr_tail(), '    ')}")
            return 1
        # MCP returns {"content":[{"type":"text","text":"<json>"}], "isError":false}
        text = ""
        if isinstance(r, dict) and r.get("content"):
            for c in r["content"]:
                if c.get("type") == "text":
                    text = c.get("text", "")
                    break
        try:
            payload = json.loads(text) if text else {}
        except json.JSONDecodeError:
            payload = {"_raw_text": text[:500]}
        skills = payload.get("skills") or []
        print(f"      OK — top-{len(skills)} skill candidates:")
        for s in skills[:3]:
            print(f"        - id={s.get('id')!r}  score={s.get('score')}")

        print(f"\n[5/5] databricks_ops_execute_sql 'SELECT 1 AS probe'")
        try:
            r = cli.call_tool("databricks_ops_execute_sql", {
                "sql_query": "SELECT 1 AS probe",
                "output_format": "json",
            })
        except Exception as e:
            print(f"  call FAILED: {e}")
            print(f"  stderr tail:\n{textwrap.indent(cli.stderr_tail(), '    ')}")
            return 1
        is_err = bool(r.get("isError")) if isinstance(r, dict) else False
        text = ""
        if isinstance(r, dict) and r.get("content"):
            for c in r["content"]:
                if c.get("type") == "text":
                    text = c.get("text", "")
                    break
        print(f"      OK — isError={is_err}  result excerpt:")
        for line in (text or "").splitlines()[:6]:
            print(f"        {line}")

        print(f"\n=== call_records ({len(cli.call_records)}) ===")
        for r in cli.call_records:
            ok = "OK " if r.error is None else "ERR"
            print(f"  {ok} {r.method:30s}  {r.elapsed_ms:>6}ms")

    print(f"\nTotal smoke time: {time.monotonic() - t0:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
