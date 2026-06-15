"""Try harder against the langgraph-advanced-mcp-agent.

The first probe came back with just {id, served-model-name}. That suggests:
  (a) async response — need to fetch by id, OR
  (b) the SDK client truncated the response.

Direct REST call and inspect the full body.
"""
from __future__ import annotations

import json
import os

import httpx
from databricks.sdk import WorkspaceClient

EP = "agents_main-bi_output_stg-langgraph-advanced-mcp-agent"
QUESTION = (
    "What was eToro's Total Revenue (per the DDR, IncludedInTotalRevenue=1) "
    "for valid customers on 2026-06-08?"
)


def main() -> None:
    w = WorkspaceClient()
    host = w.config.host.rstrip("/")
    # Use the SDK's authenticate() to get the right auth header for whichever
    # method (pat / oauth-m2m / external-browser) is configured.
    auth_headers = w.config.authenticate() or {}
    headers = {"Content-Type": "application/json", **auth_headers}

    url = f"{host}/serving-endpoints/{EP}/invocations"
    body = {"input": [{"role": "user", "content": QUESTION}]}

    print(f"POST {url}")
    print(f"Auth header set: {'yes' if 'Authorization' in headers else 'NO'}")
    r = httpx.post(url, headers=headers, json=body, timeout=600.0)
    print(f"Status: {r.status_code}")
    print(f"Response headers: {dict(r.headers)}")
    print()
    print("=== body ===")
    try:
        print(json.dumps(r.json(), indent=2)[:8000])
    except Exception:
        print(r.text[:4000])


if __name__ == "__main__":
    main()
