"""Probe the custom Databricks MCP gateway directly.

Goal: confirm we can
  1. Connect using the cached mcp-remote OAuth bearer (no LLM, no anthropic).
  2. List the available tools (sanity).
  3. List Genie spaces via databricks_ops_manage_genie(action='list').
  4. Ask one of our DDR eval questions via databricks_ops_ask_genie.

This is a one-off authoring probe; it lives under loop_authoring/ on purpose.
The harness SUT will be rebuilt around the result.
"""
from __future__ import annotations

import asyncio
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
sys.path.insert(0, ROOT)

from tools.eval_suite.harness.suts.databricks_mcp import (
    _DEFAULT_GATEWAY_URL,
    _ensure_fresh_token,
)


async def _probe(question: str) -> None:
    from mcp import ClientSession
    from mcp.client.streamable_http import streamablehttp_client

    bearer = _ensure_fresh_token()
    if not bearer:
        print("FATAL: no MCP bearer; run mcp-remote in Cursor first to seed cache.")
        return
    print(f"bearer ok (len={len(bearer)})")

    headers = {"Authorization": f"Bearer {bearer}"}
    async with streamablehttp_client(_DEFAULT_GATEWAY_URL, headers=headers) as (read, write, _meta):
        async with ClientSession(read, write) as session:
            await session.initialize()
            print("session initialized")

            # 1. List tools
            t = await session.list_tools()
            print(f"\n{len(t.tools)} tools available:")
            for tool in t.tools:
                print(f"  - {tool.name}")

            # 2. List Genie spaces
            print("\n--- listing Genie spaces ---")
            r = await session.call_tool(
                "databricks_ops_manage_genie",
                {"action": "list"},
            )
            text = "".join(getattr(b, "text", "") or "" for b in (r.content or []))
            print(text[:6000])

            # 3. If we found any DDR/revenue-flavoured space, try asking it.
            try:
                payload = json.loads(text)
                spaces = payload.get("spaces") or []
            except Exception:
                spaces = []
            ddr_candidates = [
                s for s in spaces
                if any(
                    k in (s.get("title") or s.get("display_name") or "").lower()
                    for k in ("ddr", "revenue", "kpi", "mimo", "daily")
                )
            ]
            print(f"\nDDR-like candidates: {len(ddr_candidates)}")
            for s in ddr_candidates[:8]:
                print(f"  {s.get('space_id')}  {s.get('title') or s.get('display_name')}")

            if not ddr_candidates and spaces:
                ddr_candidates = spaces[:2]
                print("(falling back to first 2 spaces)")

            for s in ddr_candidates[:1]:
                sid = s.get("space_id")
                title = s.get("title") or s.get("display_name")
                print(f"\n--- asking '{title}' ({sid}) ---")
                ask = await session.call_tool(
                    "databricks_ops_ask_genie",
                    {"space_id": sid, "question": question, "timeout_seconds": 180},
                )
                ask_text = "".join(getattr(b, "text", "") or "" for b in (ask.content or []))
                print(ask_text[:6000])


if __name__ == "__main__":
    q = (
        "What was the total revenue for valid customers on 2026-06-08? "
        "(BI_DB_DDR_Fact_Revenue_Generating_Actions, IncludedInTotalRevenue=1)"
    )
    asyncio.run(_probe(q))
