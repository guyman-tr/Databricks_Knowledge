"""Fire the orchestrator job and return the run_id."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.migration_autoloop.db import make_workspace_client

w = make_workspace_client()
run = w.jobs.run_now(job_id=239804415469841)
print("Orchestrator triggered, run_id =", run.run_id)
