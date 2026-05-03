"""
Parallel Genie space extractor with per-space caching.

Usage:
    python tools/skills/extract_genie_edges_parallel.py [--workers N]

Reads (or writes if missing): knowledge/skills/_genie_spaces_list.json
Caches per-space:              knowledge/skills/_genie_cache/<space_id>.json
Final outputs:                 knowledge/skills/_edges_genie.csv
                               knowledge/skills/_genie_spaces_index.json
"""
from __future__ import annotations

import csv
import json
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
CACHE_DIR = SKILLS / "_genie_cache"
LIST_PATH = SKILLS / "_genie_spaces_list.json"
OUT_EDGES = SKILLS / "_edges_genie.csv"
OUT_INDEX = SKILLS / "_genie_spaces_index.json"
DBX = r"C:\Users\guyman\databricks-cli-new\databricks.exe"


def run_dbx(args: list[str], timeout: int = 180) -> dict:
    cp = subprocess.run([DBX] + args, capture_output=True, timeout=timeout)
    if cp.returncode != 0:
        err = (cp.stderr or b"").decode("utf-8", errors="replace")
        raise RuntimeError(err)
    out = (cp.stdout or b"").decode("utf-8", errors="replace").strip()
    return json.loads(out) if out else {}


def list_all_spaces() -> list[dict]:
    if LIST_PATH.exists():
        return json.loads(LIST_PATH.read_text(encoding="utf-8"))
    spaces: list[dict] = []
    page_token: str | None = None
    while True:
        args = ["genie", "list-spaces", "-o", "json"]
        if page_token:
            args.extend(["--page-token", page_token])
        data = run_dbx(args)
        spaces.extend(data.get("spaces", []))
        page_token = data.get("next_page_token")
        if not page_token:
            break
        print(f"  ... {len(spaces)} so far", flush=True)
    LIST_PATH.write_text(json.dumps(spaces, indent=2), encoding="utf-8")
    return spaces


def cache_path(space_id: str) -> Path:
    return CACHE_DIR / f"{space_id}.json"


def fetch_one(space_meta: dict, retries: int = 2) -> tuple[str, str]:
    """Fetch one space, write to cache. Returns (space_id, status)."""
    sid = space_meta["space_id"]
    title = space_meta.get("title", "")
    cp = cache_path(sid)
    if cp.exists():
        return sid, "cached"
    last_err = None
    for attempt in range(retries + 1):
        try:
            data = run_dbx(["genie", "get-space", sid, "--include-serialized-space", "-o", "json"])
            cp.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            return sid, "ok"
        except Exception as exc:
            last_err = str(exc)[:120]
            time.sleep(2)
    cp.with_suffix(".err").write_text(last_err or "unknown", encoding="utf-8")
    return sid, f"error: {last_err}"


def normalize_identifier(idf: str) -> str:
    if not idf:
        return ""
    parts = [p.strip("`").strip("[]") for p in idf.split(".") if p]
    if len(parts) >= 2:
        return f"{parts[-2]}.{parts[-1]}"
    return idf


def aggregate(spaces: list[dict]) -> tuple[list[dict], list[dict]]:
    # Canonicalize via merge_graph normalizer if available
    canonicalize = None
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        from merge_graph import (  # type: ignore
            build_uc_canonical_index,
            build_wiki_canonical_index,
            normalize_node,
        )
        wiki_idx = build_wiki_canonical_index()
        uc_idx = build_uc_canonical_index()

        def canonicalize(name: str) -> str:  # type: ignore[misc]
            v = normalize_node(name, wiki_idx, uc_idx)
            return v or name
    except Exception as exc:
        print(f"  WARN: canonical normalizer unavailable: {exc}", flush=True)

    edges: list[dict] = []
    index: list[dict] = []
    for s in spaces:
        sid = s["space_id"]
        title = s.get("title", "")
        cp = cache_path(sid)
        if not cp.exists():
            print(f"  MISSING cache: {sid} ({title})", flush=True)
            continue
        try:
            data = json.loads(cp.read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"  bad cache {sid}: {exc}", flush=True)
            continue
        serialized_str = data.get("serialized_space")
        if not serialized_str:
            continue
        try:
            sp = json.loads(serialized_str)
        except Exception:
            continue
        tables = sp.get("data_sources", {}).get("tables", [])
        join_specs = sp.get("instructions", {}).get("join_specs", [])
        identifiers = [normalize_identifier(t.get("identifier", "")) for t in tables if t.get("identifier")]
        identifiers = [i for i in identifiers if i]
        if canonicalize:
            canonical_tables = [canonicalize(i) for i in identifiers]
        else:
            canonical_tables = list(identifiers)

        index.append({
            "space_id": sid,
            "title": title,
            "description": (s.get("description", "") or "")[:300],
            "warehouse_id": s.get("warehouse_id", ""),
            "tables": identifiers,
            "canonical_tables": canonical_tables,
            "n_tables": len(identifiers),
            "n_join_specs": len(join_specs),
        })

        if 2 <= len(identifiers) <= 60:
            for a, b in combinations(sorted(set(identifiers)), 2):
                edges.append({
                    "left": a,
                    "right": b,
                    "edge_kind": "genie_clique",
                    "join_keys": "",
                    "purpose": title[:80],
                    "source": sid,
                })

        for js in join_specs:
            left = normalize_identifier(js.get("left", {}).get("identifier", ""))
            right = normalize_identifier(js.get("right", {}).get("identifier", ""))
            sql = " ".join(js.get("sql", [])) if isinstance(js.get("sql"), list) else (js.get("sql") or "")
            if left and right and left != right:
                edges.append({
                    "left": left,
                    "right": right,
                    "edge_kind": "genie_join_spec",
                    "join_keys": sql[:200],
                    "purpose": title[:80],
                    "source": sid,
                })
    return edges, index


def main() -> int:
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=6)
    args = ap.parse_args()

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    SKILLS.mkdir(parents=True, exist_ok=True)

    print("Listing spaces (cached)...", flush=True)
    spaces = list_all_spaces()
    print(f"Total spaces: {len(spaces)}", flush=True)

    cached = sum(1 for s in spaces if cache_path(s["space_id"]).exists())
    todo = [s for s in spaces if not cache_path(s["space_id"]).exists()]
    print(f"Already cached: {cached}, to fetch: {len(todo)}", flush=True)

    if todo:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futures = {ex.submit(fetch_one, s): s for s in todo}
            done = 0
            for f in as_completed(futures):
                done += 1
                sid, status = f.result()
                print(f"  [{done}/{len(todo)}] {sid} -> {status}", flush=True)

    print("Aggregating cached spaces into edges...", flush=True)
    edges, index = aggregate(spaces)
    print(f"Total edges: {len(edges)}; spaces in index: {len(index)}", flush=True)

    OUT_INDEX.write_text(json.dumps(index, indent=2), encoding="utf-8")
    print(f"Wrote {OUT_INDEX.relative_to(ROOT)}", flush=True)

    fields = ["left", "right", "edge_kind", "join_keys", "purpose", "source"]
    with OUT_EDGES.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for e in edges:
            w.writerow(e)
    print(f"Wrote {OUT_EDGES.relative_to(ROOT)}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
