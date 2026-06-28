from __future__ import annotations

from dataclasses import dataclass

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import jobs, workspace


@dataclass(frozen=True)
class RunJobTaskSpec:
    """Task that triggers an existing Databricks job by ID (Run-Job task type)."""

    task_key: str
    job_id: int
    depends_on: tuple[str, ...] = ()
    timeout_seconds: int = 0


@dataclass(frozen=True)
class SqlTaskSpec:
    task_key: str
    sql_filename: str
    sql_text: str
    depends_on: tuple[str, ...] = ()
    timeout_seconds: int = 0


@dataclass(frozen=True)
class NotebookTaskSpec:
    """Task that runs a workspace notebook on a job cluster."""
    task_key: str
    notebook_path: str
    job_cluster_key: str
    depends_on: tuple[str, ...] = ()
    timeout_seconds: int = 0


def create_or_update_multitask_job(
    *,
    profile: str,
    job_name: str,
    warehouse_id: str,
    workspace_sql_dir: str,
    sql_tasks: list[SqlTaskSpec] | None = None,
    run_job_tasks: list[RunJobTaskSpec] | None = None,
    notebook_tasks: list[NotebookTaskSpec] | None = None,
    job_clusters: list | None = None,
    max_concurrent_runs: int = 1,
    job_timeout_seconds: int = 0,
    preserve_schedule: bool = True,
) -> dict[str, object]:
    """Create or update a multi-task job that mixes SQL tasks and Run-Job tasks.

    SQL tasks are uploaded to ``workspace_sql_dir`` and executed against ``warehouse_id``.
    Run-Job tasks trigger an existing job by ``job_id`` — used for the parent orchestrator
    to fan out to per-block child jobs.
    """
    w = WorkspaceClient(profile=profile)
    w.workspace.mkdirs(workspace_sql_dir)

    uploaded: dict[str, str] = {}
    tasks: list[jobs.Task] = []

    for spec in (sql_tasks or []):
        sql_path = f"{workspace_sql_dir}/{spec.sql_filename}"
        w.workspace.upload(
            sql_path,
            spec.sql_text.encode("utf-8"),
            format=workspace.ImportFormat.AUTO,
            overwrite=True,
        )
        uploaded[spec.sql_filename] = sql_path
        deps = [jobs.TaskDependency(task_key=d) for d in spec.depends_on] if spec.depends_on else None
        tasks.append(
            jobs.Task(
                task_key=spec.task_key,
                depends_on=deps,
                timeout_seconds=spec.timeout_seconds,
                sql_task=jobs.SqlTask(
                    warehouse_id=warehouse_id,
                    file=jobs.SqlTaskFile(path=sql_path, source=jobs.Source.WORKSPACE),
                ),
            )
        )

    for spec in (run_job_tasks or []):
        deps = [jobs.TaskDependency(task_key=d) for d in spec.depends_on] if spec.depends_on else None
        tasks.append(
            jobs.Task(
                task_key=spec.task_key,
                depends_on=deps,
                timeout_seconds=spec.timeout_seconds,
                run_job_task=jobs.RunJobTask(job_id=spec.job_id),
            )
        )

    for spec in (notebook_tasks or []):
        deps = [jobs.TaskDependency(task_key=d) for d in spec.depends_on] if spec.depends_on else None
        tasks.append(
            jobs.Task(
                task_key=spec.task_key,
                depends_on=deps,
                timeout_seconds=spec.timeout_seconds,
                job_cluster_key=spec.job_cluster_key,
                notebook_task=jobs.NotebookTask(
                    notebook_path=spec.notebook_path,
                    source=jobs.Source.WORKSPACE,
                ),
            )
        )

    existing = _find_job_id(w, job_name)
    if existing is None:
        created = w.jobs.create(
            name=job_name,
            max_concurrent_runs=max_concurrent_runs,
            format=jobs.Format.MULTI_TASK,
            tasks=tasks,
            job_clusters=job_clusters or [],
            timeout_seconds=job_timeout_seconds,
        )
        return {
            "action": "created",
            "job_id": int(created.job_id),
            "job_name": job_name,
            "sql_files": uploaded,
            "task_count": len(tasks),
        }

    # Preserve the existing schedule so callers that only update tasks/clusters
    # don't accidentally wipe the cron schedule set by set_orchestrator_schedule.py.
    existing_schedule = None
    if preserve_schedule:
        try:
            existing_job = w.jobs.get(job_id=existing)
            existing_schedule = existing_job.settings.schedule if existing_job.settings else None
        except Exception:
            pass

    w.jobs.reset(
        job_id=existing,
        new_settings=jobs.JobSettings(
            name=job_name,
            max_concurrent_runs=max_concurrent_runs,
            format=jobs.Format.MULTI_TASK,
            tasks=tasks,
            job_clusters=job_clusters or [],
            timeout_seconds=job_timeout_seconds,
            schedule=existing_schedule,
        ),
    )
    return {
        "action": "updated",
        "job_id": existing,
        "job_name": job_name,
        "sql_files": uploaded,
        "task_count": len(tasks),
        "schedule_preserved": existing_schedule.quartz_cron_expression if existing_schedule else None,
    }


def _find_job_id(w: WorkspaceClient, name: str) -> int | None:
    for j in w.jobs.list(name=name):
        if j.settings and j.settings.name == name and j.job_id is not None:
            return int(j.job_id)
    return None


def create_or_update_sql_job(
    *,
    profile: str,
    job_name: str,
    warehouse_id: str,
    workspace_sql_dir: str,
    task_specs: list[SqlTaskSpec],
    max_concurrent_runs: int = 1,
    job_timeout_seconds: int = 0,
) -> dict[str, object]:
    w = WorkspaceClient(profile=profile)
    w.workspace.mkdirs(workspace_sql_dir)

    uploaded: dict[str, str] = {}
    tasks: list[jobs.Task] = []
    for spec in task_specs:
        sql_path = f"{workspace_sql_dir}/{spec.sql_filename}"
        w.workspace.upload(
            sql_path,
            spec.sql_text.encode("utf-8"),
            format=workspace.ImportFormat.AUTO,
            overwrite=True,
        )
        uploaded[spec.sql_filename] = sql_path
        deps = [jobs.TaskDependency(task_key=d) for d in spec.depends_on] if spec.depends_on else None
        tasks.append(
            jobs.Task(
                task_key=spec.task_key,
                depends_on=deps,
                timeout_seconds=spec.timeout_seconds,
                sql_task=jobs.SqlTask(
                    warehouse_id=warehouse_id,
                    file=jobs.SqlTaskFile(path=sql_path, source=jobs.Source.WORKSPACE),
                ),
            )
        )

    existing = _find_job_id(w, job_name)
    if existing is None:
        created = w.jobs.create(
            name=job_name,
            max_concurrent_runs=max_concurrent_runs,
            format=jobs.Format.MULTI_TASK,
            tasks=tasks,
            timeout_seconds=job_timeout_seconds,
        )
        return {
            "action": "created",
            "job_id": int(created.job_id),
            "job_name": job_name,
            "sql_files": uploaded,
        }

    w.jobs.reset(
        job_id=existing,
        new_settings=jobs.JobSettings(
            name=job_name,
            max_concurrent_runs=max_concurrent_runs,
            format=jobs.Format.MULTI_TASK,
            tasks=tasks,
            timeout_seconds=job_timeout_seconds,
        ),
    )
    return {
        "action": "updated",
        "job_id": existing,
        "job_name": job_name,
        "sql_files": uploaded,
    }
