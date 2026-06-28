#!/usr/bin/env python3
"""Watch-only selector with cautious explicit ADF->job mapping."""
from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import make_workspace_client


def _norm(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", text.lower())


@dataclass
class SeedRow:
    pipeline_name: str
    source: str
    notes: str


@dataclass
class JobRow:
    job_id: str
    name: str


@dataclass
class JobMapRow:
    pipeline_name: str
    workspace_host: str
    job_id: str
    notes: str


def _read_seed(path: Path) -> list[SeedRow]:
    if not path.exists():
        raise FileNotFoundError(f"Seed file not found: {path}")
    out: list[SeedRow] = []
    with path.open("r", encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh):
            name = (row.get("pipeline_name") or "").strip()
            if not name:
                continue
            out.append(
                SeedRow(
                    pipeline_name=name,
                    source=(row.get("source") or "").strip(),
                    notes=(row.get("notes") or "").strip(),
                )
            )
    return out


def _read_job_map(path: Path) -> dict[str, JobMapRow]:
    if not path.exists():
        return {}
    out: dict[str, JobMapRow] = {}
    with path.open("r", encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh):
            pipeline = (row.get("pipeline_name") or "").strip()
            job_id = (row.get("job_id") or "").strip()
            if not pipeline or not job_id:
                continue
            out[pipeline] = JobMapRow(
                pipeline_name=pipeline,
                workspace_host=(row.get("workspace_host") or "").strip(),
                job_id=job_id,
                notes=(row.get("notes") or "").strip(),
            )
    return out


def _fetch_jobs(name_filter: str = "") -> tuple[str, list[JobRow]]:
    w = make_workspace_client()
    jobs = list(w.jobs.list(name=name_filter or None))
    out: list[JobRow] = []
    for job in jobs:
        out.append(
            JobRow(
                job_id=str(job.job_id or ""),
                name=(job.settings.name if job.settings and job.settings.name else ""),
            )
        )
    host = (w.config.host or "").replace("https://", "").replace("http://", "").strip("/")
    return host, out


def _match(seed_name: str, jobs: Iterable[JobRow]) -> tuple[bool, str, str, str]:
    """
    Returns:
      (matched, match_type, job_id, job_name)
    """
    seed_l = seed_name.lower()
    seed_n = _norm(seed_name)

    # 1) Exact case-insensitive
    for job in jobs:
        if job.name.lower() == seed_l:
            return True, "exact", job.job_id, job.name

    # 2) Normalized exact
    for job in jobs:
        if _norm(job.name) == seed_n and seed_n:
            return True, "normalized", job.job_id, job.name

    # 3) Substring (conservative: both normalized length>=8)
    if len(seed_n) >= 8:
        for job in jobs:
            jn = _norm(job.name)
            if len(jn) >= 8 and (seed_n in jn or jn in seed_n):
                return True, "substring", job.job_id, job.name

    return False, "", "", ""


def _write_csv(path: Path, rows: list[dict[str, str]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--seed-csv",
        default="tools/migration_autoloop/seeds/adf_pipelines.csv",
        help="ADF pipeline seed inventory",
    )
    ap.add_argument(
        "--out-all-csv",
        default="tools/migration_autoloop/runtime/pipeline_job_match.csv",
        help="Full matching result",
    )
    ap.add_argument(
        "--out-candidates-csv",
        default="tools/migration_autoloop/runtime/candidate_not_in_jobs.csv",
        help="Pipelines with no matched Databricks job",
    )
    ap.add_argument(
        "--name-filter",
        default="",
        help="Optional Databricks Jobs API name filter to reduce fetched set.",
    )
    ap.add_argument(
        "--job-map-csv",
        default="tools/migration_autoloop/seeds/pipeline_job_map.csv",
        help="Explicit ADF pipeline -> Databricks job mapping file.",
    )
    ap.add_argument(
        "--allow-heuristic",
        action="store_true",
        help="Allow fuzzy name matching when explicit map is missing.",
    )
    ap.add_argument(
        "--out-unresolved-csv",
        default="tools/migration_autoloop/runtime/pipeline_mapping_required.csv",
        help="Pipelines that require explicit mapping before validation.",
    )
    args = ap.parse_args()

    seed = _read_seed(Path(args.seed_csv))
    current_host, jobs = _fetch_jobs(args.name_filter)
    jobs_by_id = {j.job_id: j for j in jobs}
    explicit_map = _read_job_map(Path(args.job_map_csv))

    all_rows: list[dict[str, str]] = []
    candidates: list[dict[str, str]] = []
    unresolved: list[dict[str, str]] = []
    for row in seed:
        matched = False
        match_type = ""
        job_id = ""
        job_name = ""
        mapping_state = ""

        mapping = explicit_map.get(row.pipeline_name)
        if mapping is not None:
            mapped_host = mapping.workspace_host.replace("https://", "").replace("http://", "").strip("/")
            if mapped_host and mapped_host.lower() != current_host.lower():
                mapping_state = "workspace_mismatch"
                match_type = "explicit_workspace_mismatch"
                job_id = mapping.job_id
            else:
                mapped_job = jobs_by_id.get(mapping.job_id)
                if mapped_job is not None:
                    matched = True
                    match_type = "explicit_id"
                    job_id = mapped_job.job_id
                    job_name = mapped_job.name
                    mapping_state = "mapped_and_found"
                else:
                    mapping_state = "mapped_job_not_found"
                    match_type = "explicit_id_missing"
                    job_id = mapping.job_id
        else:
            mapping_state = "no_explicit_mapping"
            if args.allow_heuristic:
                matched, match_type, job_id, job_name = _match(row.pipeline_name, jobs)
                if matched:
                    mapping_state = "heuristic_match"
                else:
                    mapping_state = "heuristic_unmatched"

        rec = {
            "pipeline_name": row.pipeline_name,
            "source": row.source,
            "notes": row.notes,
            "matched_job": "1" if matched else "0",
            "mapping_state": mapping_state,
            "match_type": match_type,
            "job_id": job_id,
            "job_name": job_name,
            "current_workspace_host": current_host,
        }
        all_rows.append(rec)
        if mapping_state == "no_explicit_mapping":
            unresolved.append(rec)
        elif mapping_state == "workspace_mismatch":
            unresolved.append(rec)
        elif not matched:
            candidates.append(rec)

    fields = [
        "pipeline_name",
        "source",
        "notes",
        "matched_job",
        "mapping_state",
        "match_type",
        "job_id",
        "job_name",
        "current_workspace_host",
    ]
    _write_csv(Path(args.out_all_csv), all_rows, fields)
    _write_csv(Path(args.out_candidates_csv), candidates, fields)
    _write_csv(Path(args.out_unresolved_csv), unresolved, fields)

    print(f"seed_count={len(seed)} jobs_count={len(jobs)}")
    print(
        f"matched={sum(1 for r in all_rows if r['matched_job']=='1')} "
        f"missing_jobs={len(candidates)} unresolved_mapping={len(unresolved)}"
    )
    print(f"workspace_host={current_host}")
    print(f"all_results={args.out_all_csv}")
    print(f"candidates={args.out_candidates_csv}")
    print(f"mapping_required={args.out_unresolved_csv}")
    if candidates:
        print(f"next_candidate={candidates[0]['pipeline_name']}")
    else:
        print("next_candidate=")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

