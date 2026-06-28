#!/usr/bin/env python3
"""Re-apply the 07:30 UTC daily schedule to the orchestrator job (UNPAUSED)."""
import os, sys
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
os.environ["DATABRICKS_CONFIG_PROFILE"] = "DEFAULT"

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import jobs

w = WorkspaceClient()
PARENT_JOB_ID = 239804415469841

job = w.jobs.get(job_id=PARENT_JOB_ID)
s = job.settings

w.jobs.reset(job_id=PARENT_JOB_ID, new_settings=jobs.JobSettings(
    name=s.name,
    max_concurrent_runs=s.max_concurrent_runs,
    format=s.format,
    tasks=s.tasks,
    job_clusters=s.job_clusters,
    timeout_seconds=s.timeout_seconds,
    schedule=jobs.CronSchedule(
        quartz_cron_expression="0 30 7 * * ?",
        timezone_id="UTC",
        pause_status=jobs.PauseStatus.UNPAUSED,
    ),
))

print(f"Schedule restored: 0 30 7 * * ? UTC  UNPAUSED")
print(f"Next fire: 07:30 UTC today (Sunday Jun 28)")
print(f"URL: https://adb-5142916747090026.6.azuredatabricks.net/#job/{PARENT_JOB_ID}")
