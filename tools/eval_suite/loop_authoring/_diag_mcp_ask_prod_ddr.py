"""Ask the PROD - DDR Genie Space one of our DDR eval questions, via the MCP.

Verifies that:
  1. databricks_ops_ask_genie returns a structured payload with sql + data.
  2. The data field carries the scalar we can grade against ground truth.
  3. The full response shape so we can build a clean SUT around it.
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


PROD_DDR_SPACE_ID = "01f13712cf8516878dbc9663f5f73eb7"

# Use the natural-language question from one of our pinned cases verbatim.
QUESTION = (
    "What was the total revenue (sum of Amount, including only IncludedInTotalRevenue=1, "
    "from BI_DB_DDR_Fact_Revenue_Generating_Actions) for valid customers on 2026-06-08?"
)


async def main() -> None:
    from mcp import ClientSession
    from mcp.client.streamable_http import streamablehttp_client

    bearer = _ensure_fresh_token()
    if not bearer:
        print("FATAL: no MCP bearer.")
        return
    headers = {"Authorization": f"Bearer {bearer}"}

    async with streamablehttp_client(_DEFAULT_GATEWAY_URL, headers=headers) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            r = await session.call_tool(
                "databricks_ops_ask_genie",
                {
                    "space_id": PROD_DDR_SPACE_ID,
                    "question": QUESTION,
                    "timeout_seconds": 240,
                },
            )
            text = "".join(getattr(b, "text", "") or "" for b in (r.content or []))
            print("=== raw response ===")
            print(text[:8000])
            print()
            print("=== parsed structure ===")
            try:
                payload = json.loads(text)
            except Exception as e:
                print(f"could not parse JSON: {e}")
                return
            for k in ("status", "conversation_id", "message_id", "row_count"):
                print(f"  {k}: {payload.get(k)}")
            print(f"  text_response (first 400): {(payload.get('text_response') or '')[:400]}")
            print(f"  sql: {(payload.get('sql') or '')[:400]}")
            print(f"  description (first 400): {(payload.get('description') or '')[:400]}")
            print(f"  columns: {payload.get('columns')}")
            data = payload.get("data")
            if data:
                print(f"  data (first row): {data[0] if isinstance(data, list) and data else data}")
                print(f"  data row count: {len(data) if isinstance(data, list) else 'n/a'}")


if __name__ == "__main__":
    asyncio.run(main())
