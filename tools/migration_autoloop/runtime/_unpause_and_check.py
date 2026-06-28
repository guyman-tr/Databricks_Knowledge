#!/usr/bin/env python3
"""Find snapshot prereq job + unpause orchestrator schedule."""
import os, sys
sys.path.insert(0, r"C:\Users\guyman\Documents\github\Databricks_Knowledge")
os.environ["DATABRICKS_CONFIG_PROFILE"] = "DEFAULT"

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import jobs

w = WorkspaceClient()

# Find snapshot prereq job by name pattern
print("=== Snapshot prereq jobs ===")
for j in w.jobs.list():
    if j.settings and "snapshot" in (j.settings.name or "").lower():
        s = j.settings
        sched = s.schedule
        cron = sched.quartz_cron_expression if sched else "NO SCHEDULE"
        tz   = sched.timezone_id if sched else ""
        paused = sched.pause_status if sched else ""
        print(f"  [{j.job_id}] {s.name}")
        print(f"    {cron} {tz}  paused={paused}")

# Unpause the orchestrator
PARENT_JOB_ID = 239804415469841
print()
print("=== Unpausing orchestrator ===")
job = w.jobs.get(job_id=PARENT_JOB_ID)
s = job.settings
cron_expr = s.schedule.quartz_cron_expression
tz_id     = s.schedule.timezone_id

new_settings = jobs.JobSettings(
    name=s.name,
    max_concurrent_runs=s.max_concurrent_runs,
    format=s.format,
    tasks=s.tasks,
    job_clusters=s.job_clusters,
    timeout_seconds=s.timeout_seconds,
    schedule=jobs.CronSchedule(
        quartz_cron_expression=cron_expr,
        timezone_id=tz_id,
        pause_status=jobs.PauseStatus.UNPAUSED,
    ),
)
w.jobs.reset(job_id=PARENT_JOB_ID, new_settings=new_settings)
print(f"  UNPAUSED — next fire: {cron_expr} {tz_id}")
print(f"  URL: https://adb-5142916747090026.6.azuredatabricks.net/#job/{PARENT_JOB_ID}")
