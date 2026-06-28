#!/usr/bin/env python3
"""Set the DWH_Parallel_Migration__Orchestrator job schedule to 07:30 UTC daily."""
import os, sys
sys.path.append(r"C:\Users\guyman\Documents\github\Databricks_Knowledge")
os.environ["DATABRICKS_CONFIG_PROFILE"] = "DEFAULT"

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import jobs

w = WorkspaceClient(profile="DEFAULT")

PARENT_JOB_ID = 239804415469841

# Get current settings
job = w.jobs.get(job_id=PARENT_JOB_ID)
settings = job.settings

# Add schedule: 07:30 UTC daily = 10:30 Asia/Jerusalem (UTC+3 summer)
# Quartz cron: 0 30 7 * * ?  (sec min hour day month weekday)
new_settings = jobs.JobSettings(
    name=settings.name,
    max_concurrent_runs=settings.max_concurrent_runs,
    format=settings.format,
    tasks=settings.tasks,
    job_clusters=settings.job_clusters,
    timeout_seconds=settings.timeout_seconds,
    schedule=jobs.CronSchedule(
        quartz_cron_expression="0 30 7 * * ?",
        timezone_id="UTC",
        pause_status=jobs.PauseStatus.PAUSED,  # start paused — enable manually when ready
    ),
)

w.jobs.reset(job_id=PARENT_JOB_ID, new_settings=new_settings)
print(f"Schedule set: 0 30 7 * * ? UTC (paused). Enable in Databricks UI when ready to go live.")
print(f"Job URL: https://adb-5142916747090026.6.azuredatabricks.net/#job/{PARENT_JOB_ID}")
