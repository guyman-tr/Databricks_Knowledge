#!/usr/bin/env python3
"""Get job config for Daily_Snapshot_UC_Tables from prod workspace."""
import os, sys
sys.path.append(r"C:\Users\guyman\Documents\github\Databricks_Knowledge")
os.environ["DATABRICKS_CONFIG_PROFILE"] = "prod"

from databricks.sdk import WorkspaceClient
w = WorkspaceClient(profile="prod")

for job_id in [974287842004660, 682301769456400]:
    try:
        job = w.jobs.get(job_id=job_id)
        print(f"\n=== Job {job_id}: {job.settings.name} ===")
        if job.settings.schedule:
            print(f"  Schedule: {job.settings.schedule.quartz_cron_expression} ({job.settings.schedule.timezone_id})")
        if job.settings.tasks:
            for task in job.settings.tasks:
                print(f"  Task: {task.task_key}")
                if task.notebook_task:
                    print(f"    Notebook: {task.notebook_task.notebook_path}")
                if task.python_wheel_task:
                    print(f"    Python wheel: {task.python_wheel_task}")
                if task.spark_python_task:
                    print(f"    Python file: {task.spark_python_task.python_file}")
                if task.run_job_task:
                    print(f"    Run job: {task.run_job_task.job_id}")
    except Exception as e:
        print(f"ERROR job {job_id}: {e}")
