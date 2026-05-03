"""
Extract edges from all Databricks Genie spaces.

For each space:
  - Treat the data_sources.tables[] set as a clique (all-pairs edges, low weight)
  - Treat each instructions.join_specs[] entry as an explicit edge (high weight,
    join SQL captured)

Output: knowledge/skills/_edges_genie.csv
Also writes:  knowledge/skills/_genie_spaces_index.json — list of spaces with
              their tables, useful as cluster annotation later.

Uses:  C:\\Users\\guyman\\databricks-cli-new\\databricks.exe genie list-spaces
       C:\\Users\\guyman\\databricks-cli-new\\databricks.exe genie get-space <id>
"""
from __future__ import annotations

import csv
import json
import subprocess
import sys
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_EDGES = ROOT / "knowledge" / "skills" / "_edges_genie.csv"
OUT_INDEX = ROOT / "knowledge" / "skills" / "_genie_spaces_index.json"
DBX = r"C:\Users\guyman\databricks-cli-new\databricks.exe"


def run_dbx(args: list[str]) -> dict:
    cp = subprocess.run(
        [DBX] + args,
        capture_output=True,
        timeout=180,
    )
    if cp.returncode != 0:
        err = (cp.stderr or b"").decode("utf-8", errors="replace")
        raise RuntimeError(f"dbx failed: {err}")
    out = (cp.stdout or b"").decode("utf-8", errors="replace").strip()
    return json.loads(out) if out else {}


def list_all_spaces() -> list[dict]:
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
        print(f"  ... {len(spaces)} spaces so far, paginating", flush=True)
    return spaces


def get_space_serialized(space_id: str) -> dict:
    data = run_dbx(["genie", "get-space", space_id, "--include-serialized-space", "-o", "json"])
    serialized = data.get("serialized_space")
    if not serialized:
        return {"_meta": data, "_serialized": None}
    return {"_meta": {k: v for k, v in data.items() if k != "serialized_space"}, "_serialized": json.loads(serialized)}


def normalize_identifier(idf: str) -> str:
    """Catalog.schema.table -> schema.table (last two segments)."""
    if not idf:
        return ""
    parts = [p.strip("`").strip("[]") for p in idf.split(".") if p]
    if len(parts) >= 2:
        return f"{parts[-2]}.{parts[-1]}"
    return idf


def extract_edges(spaces: list[dict]) -> tuple[list[dict], list[dict]]:
    edges: list[dict] = []
    index: list[dict] = []
    for s in spaces:
        sid = s["space_id"]
        title = s.get("title", "")
        try:
            payload = get_space_serialized(sid)
        except Exception as exc:
            print(f"  WARN: get-space {sid} ({title}): {exc}", flush=True)
            continue
        sp = payload.get("_serialized") or {}
        tables = sp.get("data_sources", {}).get("tables", [])
        join_specs = sp.get("instructions", {}).get("join_specs", [])
        identifiers = [normalize_identifier(t.get("identifier", "")) for t in tables if t.get("identifier")]
        identifiers = [i for i in identifiers if i]

        index.append({
            "space_id": sid,
            "title": title,
            "description": (s.get("description", "") or "")[:300],
            "warehouse_id": s.get("warehouse_id", ""),
            "tables": identifiers,
            "n_tables": len(identifiers),
            "n_join_specs": len(join_specs),
        })

        # All-pairs clique edges (low weight per pair when many tables)
        # Cap clique size to keep dense spaces from drowning the graph
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

        # Explicit join specs
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

        print(f"  {title}: {len(identifiers)} tables, {len(join_specs)} explicit joins", flush=True)
    return edges, index


def main() -> int:
    OUT_EDGES.parent.mkdir(parents=True, exist_ok=True)
    print("Listing Genie spaces...", flush=True)
    spaces = list_all_spaces()
    print(f"Found {len(spaces)} Genie spaces total", flush=True)

    edges, index = extract_edges(spaces)
    print(f"Total Genie edges: {len(edges)}", flush=True)

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
