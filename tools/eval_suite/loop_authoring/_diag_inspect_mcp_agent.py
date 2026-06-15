"""Inspect the langgraph-advanced-mcp-agent endpoint.

If this endpoint already wires the user-databricks-stg MCP to a Claude/GPT
loop, it's a turnkey driver for our eval.
"""
from __future__ import annotations
import json
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()
ep_name = "agents_main-bi_output_stg-langgraph-advanced-mcp-agent"
ep = w.serving_endpoints.get(ep_name)

print(f"Name:            {ep.name}")
print(f"State:           {ep.state.ready.value if ep.state and ep.state.ready else 'n/a'}")
print(f"Task:            {ep.task}")
print(f"Creation time:   {ep.creation_timestamp}")
print(f"Last updated:    {ep.last_updated_timestamp}")
print(f"Creator:         {ep.creator}")
if ep.config and ep.config.served_entities:
    print(f"\nServed entities:")
    for se in ep.config.served_entities:
        print(f"  - name={se.name}")
        print(f"    entity={se.entity_name}  v{se.entity_version}")
        print(f"    workload_size={se.workload_size}  scale_to_zero={se.scale_to_zero_enabled}")
        if se.environment_vars:
            print(f"    env vars: {list(se.environment_vars.keys())}")
print(f"\n--- raw config (first 2000 chars) ---")
print(json.dumps(ep.as_dict(), default=str, indent=2)[:2000])
