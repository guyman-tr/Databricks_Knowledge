"""List all migration parallel jobs."""
import sys, os
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client

w = make_workspace_client()
print("Profile / host:", w.config.host)
print()
for j in w.jobs.list():
    if j.settings and j.settings.name and "migration" in j.settings.name.lower():
        print(j.job_id, "|", j.settings.name)
