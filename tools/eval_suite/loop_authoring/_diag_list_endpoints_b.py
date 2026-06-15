from databricks.sdk import WorkspaceClient

w = WorkspaceClient(profile="guyman")
endpoints = list(w.serving_endpoints.list())
print(f"Total serving endpoints: {len(endpoints)}\n")

interesting = []
for e in endpoints:
    name = (e.name or "").lower()
    if any(k in name for k in ("claude", "gpt", "llama", "meta", "sonnet", "opus", "haiku", "mistral", "dbrx")):
        interesting.append(e)

print(f"Foundation/LLM-looking endpoints ({len(interesting)}):")
for e in interesting:
    state = e.state.ready if e.state else "?"
    task = e.task or "?"
    print(f"  {e.name:65s}  state={state}  task={task}")

print("\nAll endpoint names (first 60):")
for e in endpoints[:60]:
    print(f"  {e.name}")
