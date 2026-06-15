"""Ask the langgraph-advanced-mcp-agent endpoint a real DDR question.

Two attempts:
  - via the OpenAI-compatible /serving-endpoints/{name}/invocations
  - via WorkspaceClient.serving_endpoints.query (whichever shape it accepts)

Goal: find the request format the endpoint expects and confirm it returns a
usable answer for our eval cases.
"""
from __future__ import annotations

import json
import os
import sys

from databricks.sdk import WorkspaceClient

EP = "agents_main-bi_output_stg-langgraph-advanced-mcp-agent"
QUESTION = (
    "What was eToro's Total Revenue (per the DDR, IncludedInTotalRevenue=1) "
    "for valid customers on 2026-06-08?"
)


def main() -> None:
    w = WorkspaceClient()

    # Try the agent/v1/responses shape first (Anthropic-Responses style).
    payloads = [
        {
            "label": "v1/responses (input as user msg)",
            "body": {"input": [{"role": "user", "content": QUESTION}]},
        },
        {
            "label": "OpenAI chat (messages)",
            "body": {"messages": [{"role": "user", "content": QUESTION}]},
        },
        {
            "label": "plain input string",
            "body": {"input": QUESTION},
        },
    ]

    for p in payloads:
        print(f"\n=== trying: {p['label']} ===")
        try:
            resp = w.serving_endpoints.query(name=EP, **p["body"])
            d = resp.as_dict() if hasattr(resp, "as_dict") else dict(resp.__dict__)
            print(json.dumps(d, default=str, indent=2)[:4000])
            return
        except Exception as e:
            print(f"  -> {type(e).__name__}: {str(e)[:300]}")


if __name__ == "__main__":
    main()
