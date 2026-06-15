"""List Databricks Foundation Model / serving endpoints available in this workspace."""
from __future__ import annotations
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()
print(f"{'name':<60} {'state':<12} {'task':<30}")
print("-" * 105)
for ep in w.serving_endpoints.list():
    state = ep.state.ready.value if ep.state and ep.state.ready else "n/a"
    task = ep.task or "n/a"
    name = ep.name or ""
    print(f"{name:<60} {state:<12} {task:<30}")
