"""Snapshot load/save + diff helpers for the auto_kb framework.

A snapshot file is JSON:
    {"version": 1, "app": "<app>", "saved_at": "<iso>", "items": {key: {"hash": "...", "meta": {...}}}}

Diff compares two key->hash maps and returns new / changed / removed keys.
"""
from __future__ import annotations

import datetime as _dt
import hashlib
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


SNAPSHOT_VERSION = 1


def canonical_hash(obj: Any) -> str:
    """Stable sha256 over a JSON-serializable object."""
    blob = json.dumps(obj, sort_keys=True, ensure_ascii=False, default=str)
    return hashlib.sha256(blob.encode("utf-8")).hexdigest()


def load_snapshot(path: str | Path) -> dict[str, Any]:
    p = Path(path)
    if not p.exists():
        return {"version": SNAPSHOT_VERSION, "items": {}}
    data = json.loads(p.read_text(encoding="utf-8"))
    if "items" not in data or not isinstance(data["items"], dict):
        data["items"] = {}
    return data


def save_snapshot(path: str | Path, app: str, items: dict[str, dict[str, Any]]) -> None:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": SNAPSHOT_VERSION,
        "app": app,
        "saved_at": _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds"),
        "items": items,
    }
    p.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


@dataclass
class Diff:
    new: list[str] = field(default_factory=list)
    changed: list[str] = field(default_factory=list)
    removed: list[str] = field(default_factory=list)

    @property
    def has_changes(self) -> bool:
        return bool(self.new or self.changed or self.removed)


def diff_hash_maps(
    prev_items: dict[str, dict[str, Any]],
    curr_items: dict[str, dict[str, Any]],
) -> Diff:
    """Compare {key: {"hash": ...}} maps."""
    prev_keys = set(prev_items)
    curr_keys = set(curr_items)
    new = sorted(curr_keys - prev_keys)
    removed = sorted(prev_keys - curr_keys)
    changed = sorted(
        k
        for k in (prev_keys & curr_keys)
        if prev_items[k].get("hash") != curr_items[k].get("hash")
    )
    return Diff(new=new, changed=changed, removed=removed)


def build_items_map(records: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Build a {key: {"hash": <hash>, "meta": <record>}} map from raw records."""
    out: dict[str, dict[str, Any]] = {}
    for key, record in records.items():
        out[str(key)] = {"hash": canonical_hash(record), "meta": record}
    return out
