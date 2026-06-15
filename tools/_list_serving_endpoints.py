#!/usr/bin/env python3
"""List Databricks Model Serving endpoints + try a smoke-test call."""
from databricks.sdk import WorkspaceClient

w = WorkspaceClient(profile="DEFAULT")
eps = list(w.serving_endpoints.list())
print(f"Total endpoints: {len(eps)}\n")

rows = []
for e in eps:
    state = e.state.ready.value if e.state and e.state.ready else "?"
    task = getattr(e, "task", None) or "?"
    cfg = e.config
    served = []
    if cfg and cfg.served_entities:
        for se in cfg.served_entities:
            ext = se.external_model
            if ext:
                served.append(f"{ext.provider}:{ext.name}")
            else:
                served.append(se.entity_name or se.name or "?")
    elif cfg and cfg.served_models:
        served = [sm.model_name for sm in cfg.served_models]
    rows.append((e.name, state, task, ", ".join(served)))

rows.sort(key=lambda r: r[0])
print(f"{'NAME':70s} {'STATE':12s} {'TASK':25s} SERVED")
print("-" * 150)
for name, state, task, served in rows:
    print(f"{name:70s} {state:12s} {task:25s} {served}")
