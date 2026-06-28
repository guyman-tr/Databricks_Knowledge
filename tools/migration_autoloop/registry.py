"""CSV-backed pipeline registry + manifest helpers."""
from __future__ import annotations

import csv
import datetime as dt
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

REGISTRY_FIELDS = [
    "pipeline_name",
    "source",
    "status",
    "retry_count",
    "last_run_id",
    "last_checked_at",
    "last_error",
    "last_qa_compared_count",
    "last_qa_mismatch_count",
    "last_qa_error_count",
    "evidence_path",
    "notes",
]

VALID_STATUS = {"pending", "processing", "blocked", "qa_failed", "done"}


@dataclass
class RegistryRow:
    pipeline_name: str
    source: str
    status: str
    retry_count: int = 0
    last_run_id: str = ""
    last_checked_at: str = ""
    last_error: str = ""
    last_qa_compared_count: int = 0
    last_qa_mismatch_count: int = 0
    last_qa_error_count: int = 0
    evidence_path: str = ""
    notes: str = ""

    @classmethod
    def from_dict(cls, row: dict[str, str]) -> "RegistryRow":
        status = (row.get("status") or "pending").strip().lower()
        if status not in VALID_STATUS:
            status = "pending"
        return cls(
            pipeline_name=(row.get("pipeline_name") or "").strip(),
            source=(row.get("source") or "").strip(),
            status=status,
            retry_count=_to_int(row.get("retry_count")),
            last_run_id=(row.get("last_run_id") or "").strip(),
            last_checked_at=(row.get("last_checked_at") or "").strip(),
            last_error=(row.get("last_error") or "").strip(),
            last_qa_compared_count=_to_int(row.get("last_qa_compared_count")),
            last_qa_mismatch_count=_to_int(row.get("last_qa_mismatch_count")),
            last_qa_error_count=_to_int(row.get("last_qa_error_count")),
            evidence_path=(row.get("evidence_path") or "").strip(),
            notes=(row.get("notes") or "").strip(),
        )

    def to_dict(self) -> dict[str, str]:
        return {
            "pipeline_name": self.pipeline_name,
            "source": self.source,
            "status": self.status,
            "retry_count": str(self.retry_count),
            "last_run_id": self.last_run_id,
            "last_checked_at": self.last_checked_at,
            "last_error": self.last_error,
            "last_qa_compared_count": str(self.last_qa_compared_count),
            "last_qa_mismatch_count": str(self.last_qa_mismatch_count),
            "last_qa_error_count": str(self.last_qa_error_count),
            "evidence_path": self.evidence_path,
            "notes": self.notes,
        }


def _to_int(raw: str | None) -> int:
    if not raw:
        return 0
    try:
        return int(raw)
    except ValueError:
        return 0


def now_utc_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def load_registry(path: Path) -> dict[str, RegistryRow]:
    if not path.exists():
        return {}
    rows: dict[str, RegistryRow] = {}
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        for item in reader:
            row = RegistryRow.from_dict(item)
            if row.pipeline_name:
                rows[row.pipeline_name] = row
    return rows


def save_registry(path: Path, rows: Iterable[RegistryRow]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    ordered = sorted(rows, key=lambda r: r.pipeline_name.lower())
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=REGISTRY_FIELDS)
        writer.writeheader()
        for row in ordered:
            writer.writerow(row.to_dict())


def write_manifest(path: Path, rows: list[RegistryRow]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=REGISTRY_FIELDS)
        writer.writeheader()
        for row in rows:
            writer.writerow(row.to_dict())


def load_manifest(path: Path) -> list[RegistryRow]:
    if not path.exists():
        return []
    out: list[RegistryRow] = []
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        for item in reader:
            row = RegistryRow.from_dict(item)
            if row.pipeline_name:
                out.append(row)
    return out

