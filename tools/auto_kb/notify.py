"""Thin wrapper over tools/notify/notify.py for the auto_kb framework."""
from __future__ import annotations

import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.notify.notify import notify as _notify


def send(
    *,
    subject: str,
    body: str,
    status: str,
    channels: tuple[str, ...],
    dry_run: bool,
    skip: bool,
) -> None:
    if dry_run or skip:
        print(f"[no-notify] status={status} subject={subject}")
        return
    try:
        _notify(subject=subject, body=body, status=status, channels=list(channels))
    except Exception as exc:  # noqa: BLE001
        print(f"[warn] notify failed: {exc}", file=sys.stderr)
