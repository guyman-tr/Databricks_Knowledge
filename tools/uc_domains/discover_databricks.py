#!/usr/bin/env python3
"""
Phase 4 — Databricks-native discovery for an acquired-company UC domain.

Scans:
  1. Genie spaces — list all spaces, fetch the serialized config of each, and
     keep the ones whose data_sources.tables[].identifier matches an object in
     our UC inventory. Cache the parsed JSON locally.
  2. Notebooks — best-effort listing of notebooks under predictable paths
     (Workspace/Repos/.../DataPlatform/databricks/de/{Domain}). Records paths
     and last_modified only.

Skips by default:
  - Query history (optional, can be added with --query-history N).

Output: knowledge/uc_domains/{domain}/_discovery/databricks_assets.json
        knowledge/uc_domains/{domain}/_discovery/genie_spaces/<space_id>__<slug>.json

Usage:
  python tools/uc_domains/discover_databricks.py \
      --domain spaceship \
      --inventory knowledge/uc_domains/spaceship/_discovery/uc_inventory.json \
      --notebook-paths /Workspace/Repos \
                       /Repos \
      --domain-folder Spaceship \
      --out knowledge/uc_domains/spaceship/_discovery/databricks_assets.json
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

try:
    from databricks.sdk import WorkspaceClient
    from databricks.sdk.errors import NotFound, PermissionDenied
except ImportError:
    print("Install: pip install databricks-sdk", file=sys.stderr)
    sys.exit(1)


SLUG_RE = re.compile(r"[^a-z0-9]+")


def slug(s: str) -> str:
    return SLUG_RE.sub("-", (s or "").lower()).strip("-") or "untitled"


def load_inventory(path: Path) -> tuple[set[str], dict[str, str]]:
    """Return (set of full_names, full_name -> bare table name)."""
    inv = json.loads(path.read_text(encoding="utf-8"))
    full_names: set[str] = set()
    bare: dict[str, str] = {}
    for sd in inv["schemas"].values():
        for o in sd["objects"]:
            full_names.add(o["full_name"].lower())
            bare[o["full_name"].lower()] = o["name"]
    return full_names, bare


def list_genie_spaces(w: WorkspaceClient) -> list[dict]:
    """Page through every Genie space. Returns space dicts including
    `serialized_space` (raw JSON string) when the API populates it on list."""
    out: list[dict] = []
    page_token: str | None = None
    while True:
        kwargs: dict = {}
        if page_token:
            kwargs["page_token"] = page_token
        resp = w.genie.list_spaces(**kwargs)
        spaces = resp.spaces or []
        for sp in spaces:
            out.append({
                "space_id": sp.space_id,
                "title": sp.title,
                "warehouse_id": getattr(sp, "warehouse_id", None),
                "description": getattr(sp, "description", None),
                "serialized_space": getattr(sp, "serialized_space", None),
            })
        page_token = resp.next_page_token
        if not page_token:
            break
    return out


def hydrate_space(w: WorkspaceClient, space_meta: dict) -> dict:
    """Fetch the serialized config for a Genie space.

    The SDK's `genie.list_spaces()` and `genie.get_space()` both return
    `serialized_space=None` because neither sets `include_serialized_space=true`.
    We call the raw REST endpoint to force inclusion."""
    sid = space_meta["space_id"]
    try:
        resp = w.api_client.do(
            "GET",
            f"/api/2.0/genie/spaces/{sid}",
            query={"include_serialized_space": "true"},
        )
    except (NotFound, PermissionDenied) as e:
        return {**space_meta, "_error": str(e)}
    except Exception as e:
        return {**space_meta, "_error": f"{type(e).__name__}: {e}"}
    if not isinstance(resp, dict):
        return {**space_meta, "_error": f"unexpected resp type {type(resp).__name__}"}
    data = dict(space_meta)
    data.update({k: v for k, v in resp.items() if k not in {"serialized_space"}})
    ser = resp.get("serialized_space")
    if isinstance(ser, str) and ser:
        try:
            data["space_config"] = json.loads(ser)
        except Exception as e:
            data["space_config_parse_error"] = str(e)
    elif isinstance(ser, dict):
        data["space_config"] = ser
    return data


def extract_space_tables(space_data: dict) -> set[str]:
    """Pull data_sources.tables[].identifier from a Genie space config (lowercased)."""
    out: set[str] = set()
    cfg = space_data.get("space_config") or {}
    for t in (cfg.get("data_sources") or {}).get("tables", []) or []:
        ident = (t.get("identifier") or "").lower()
        if ident:
            out.add(ident)
    return out


def count_space_overlap_features(space_data: dict, our_tables: set[str]) -> dict:
    """Count text instructions / join specs / SQL snippets touching our tables."""
    cfg = space_data.get("space_config") or {}
    inst = cfg.get("instructions") or {}
    text = inst.get("text_instructions") or []
    joins = inst.get("join_specs") or []
    snippets = inst.get("sql_snippets") or {}
    our_lower = our_tables  # already lowercased

    def _hits(items, attrs):
        c = 0
        for it in items or []:
            blob = " ".join(str(it.get(a, "") or "") for a in attrs).lower()
            if any(t in blob for t in our_lower):
                c += 1
        return c

    join_hit = 0
    for js in joins:
        l = (js.get("left") or {}).get("identifier", "").lower()
        r = (js.get("right") or {}).get("identifier", "").lower()
        if l in our_lower or r in our_lower:
            join_hit += 1
    return {
        "text_instruction_hits": _hits(text, ["title", "content", "value"]),
        "join_spec_hits": join_hit,
        "snippet_filter_hits": _hits((snippets or {}).get("filters", []), ["name", "sql", "title"]),
        "snippet_measure_hits": _hits((snippets or {}).get("measures", []), ["name", "sql", "title"]),
    }


def list_local_notebooks(local_repo: Path, domain_folder: str,
                         our_full_names: set[str]) -> list[dict]:
    """Find notebooks in a local DataPlatform repo under databricks/de/{domain_folder}/.
    Cheaper and more deterministic than Workspace API; the repo is the source-of-truth
    for ingest pipelines anyway."""
    folder = local_repo / "databricks" / "de" / domain_folder
    if not folder.exists():
        return []
    out: list[dict] = []
    candidates = sorted(list(folder.rglob("*.py")) + list(folder.rglob("*.ipynb")))
    for p in candidates:
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            text = ""
        # Find every UC table mention (catalog.schema.table) that's in our inventory.
        text_lower = text.lower()
        hits = sorted(t for t in our_full_names if t in text_lower)
        # Treat each two-part schema.table as a less specific mention for fallback,
        # since notebooks often write via abfss path, not UC name.
        bare_hits = sorted({
            t.split(".", 1)[1]  # schema.table
            for t in our_full_names
            if t.split(".", 1)[1] in text_lower
        }) if not hits else []
        out.append({
            "path": str(p.relative_to(local_repo)).replace("\\", "/"),
            "language": "PYTHON" if p.suffix == ".py" else "JUPYTER",
            "size_bytes": p.stat().st_size,
            "modified_at": dt.datetime.fromtimestamp(p.stat().st_mtime).isoformat(),
            "uc_table_mentions": hits,
            "bare_schema_table_mentions": bare_hits,
        })
    return out


def list_notebooks(w: WorkspaceClient, base_paths: list[str], domain_folder: str,
                   max_walk: int = 5000) -> list[dict]:
    """Walk Workspace under base_paths to find */DataPlatform/databricks/de/{domain_folder}/*."""
    found: list[dict] = []
    seen = 0
    target_re = re.compile(rf"/DataPlatform/databricks/de/{re.escape(domain_folder)}(/|$)", re.I)
    stack = list(base_paths)
    while stack and seen < max_walk:
        path = stack.pop()
        try:
            for entry in w.workspace.list(path, recursive=False):
                seen += 1
                p = entry.path or ""
                otype = (entry.object_type.value if hasattr(entry.object_type, "value")
                         else str(entry.object_type))
                if target_re.search(p):
                    if otype == "NOTEBOOK":
                        found.append({
                            "path": p,
                            "language": (entry.language.value if entry.language else None),
                            "modified_at": (entry.modified_at if hasattr(entry, "modified_at") else None),
                            "object_id": entry.object_id,
                        })
                    elif otype == "DIRECTORY":
                        stack.append(p)
                    continue
                # Drill into directories that look like they could contain DataPlatform
                if otype == "DIRECTORY":
                    if (
                        "/DataPlatform" in p
                        or "/Repos" in p
                        or "/Workspace/Repos" in p
                        or p.count("/") < 4
                    ):
                        stack.append(p)
        except (NotFound, PermissionDenied):
            continue
        except Exception as e:
            print(f"[notebooks] skip {path}: {type(e).__name__}: {e}",
                  file=sys.stderr)
            continue
    return found


def main() -> int:
    ap = argparse.ArgumentParser(description="Databricks-native discovery for a UC domain")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--inventory", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--profile", default=None,
                    help="Databricks SDK profile (default: env DATABRICKS_MCP_PROFILE or 'DEFAULT')")
    ap.add_argument("--notebook-paths", nargs="*", default=["/Workspace/Repos", "/Repos"])
    ap.add_argument("--local-de-repo", default=None,
                    help="Path to a local clone of DataPlatform. If set, crawl "
                         "<local-de-repo>/databricks/de/{domain-folder} instead of "
                         "the workspace API (more deterministic).")
    ap.add_argument("--domain-folder", default=None,
                    help="Capitalised domain folder under databricks/de/, e.g. 'Spaceship'")
    ap.add_argument("--skip-genie", action="store_true",
                    help="Skip the Genie space scan (slow if many spaces)")
    ap.add_argument("--skip-notebooks", action="store_true",
                    help="Skip the notebook crawl")
    args = ap.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    spaces_dir = out_path.parent / "genie_spaces"
    spaces_dir.mkdir(parents=True, exist_ok=True)

    profile = args.profile or (
        __import__("os").environ.get("DATABRICKS_MCP_PROFILE")
        or __import__("os").environ.get("DATABRICKS_CONFIG_PROFILE")
        or "DEFAULT"
    )
    print(f"[dbx] profile={profile}", file=sys.stderr)
    w = WorkspaceClient(profile=profile)

    inv = json.loads(Path(args.inventory).read_text(encoding="utf-8"))
    full_names, bare_map = load_inventory(Path(args.inventory))

    # ---- Genie scan -------------------------------------------------------
    matching_spaces: list[dict] = []
    per_object_genie: dict[str, list[dict]] = {fn: [] for fn in full_names}
    if not args.skip_genie:
        all_spaces = list_genie_spaces(w)
        print(f"[genie] {len(all_spaces)} spaces total", file=sys.stderr)
        for i, sp in enumerate(all_spaces, 1):
            sid = sp.get("space_id")
            if not sid:
                continue
            data = hydrate_space(w, sp)
            tables = extract_space_tables(data)
            overlap = full_names & tables
            if not overlap:
                continue
            counts = count_space_overlap_features(data, full_names)
            slug_t = slug(sp.get("title") or "untitled")
            cache_path = spaces_dir / f"{sid}__{slug_t}.json"
            try:
                cache_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
            except Exception as e:
                print(f"[genie] cache write failed for {sid}: {e}", file=sys.stderr)
            matching_spaces.append({
                "space_id": sid,
                "title": sp.get("title"),
                "warehouse_id": sp.get("warehouse_id"),
                "description": sp.get("description"),
                "table_count": len(tables),
                "domain_table_overlap": len(overlap),
                "overlap_tables": sorted(overlap),
                **counts,
                "exported_path": str(cache_path.relative_to(out_path.parent.parent)),
            })
            for tbl in overlap:
                per_object_genie[tbl].append({
                    "space_id": sid,
                    "title": sp.get("title"),
                    "join_spec_hits": counts["join_spec_hits"],
                    "text_instruction_hits": counts["text_instruction_hits"],
                    "snippet_filter_hits": counts["snippet_filter_hits"],
                    "snippet_measure_hits": counts["snippet_measure_hits"],
                })
            print(f"  [{i}/{len(all_spaces)}] HIT: {sp.get('title')} — overlap={len(overlap)}",
                  file=sys.stderr)
    else:
        print("[genie] skipped", file=sys.stderr)

    # ---- Notebook crawl ---------------------------------------------------
    notebooks: list[dict] = []
    if not args.skip_notebooks:
        domain_folder = args.domain_folder or args.domain.capitalize()
        if args.local_de_repo:
            local = Path(args.local_de_repo)
            print(f"[notebooks] scanning local repo {local}/databricks/de/{domain_folder}/",
                  file=sys.stderr)
            notebooks = list_local_notebooks(local, domain_folder, full_names)
        else:
            print(f"[notebooks] walking workspace {args.notebook_paths} for "
                  f"/DataPlatform/databricks/de/{domain_folder}/", file=sys.stderr)
            notebooks = list_notebooks(w, args.notebook_paths, domain_folder)
        print(f"[notebooks] found {len(notebooks)}", file=sys.stderr)

    # ---- Per-object index --------------------------------------------------
    per_object: dict[str, dict] = {}
    notebook_by_table: dict[str, list[str]] = {}
    for nb in notebooks:
        for tbl in nb.get("uc_table_mentions", []) or []:
            notebook_by_table.setdefault(tbl, []).append(nb["path"])
    for fn in full_names:
        per_object[fn] = {
            "genie_spaces": per_object_genie.get(fn, []),
            "notebook_paths": notebook_by_table.get(fn, []),
        }

    payload = {
        "domain": args.domain,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "genie_spaces": matching_spaces,
        "notebooks": notebooks,
        "per_object_index": per_object,
        "stats": {
            "domain_objects": len(full_names),
            "genie_spaces_matching": len(matching_spaces),
            "notebooks_found": len(notebooks),
        },
    }
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[dbx] wrote {out_path} (genie_matches={len(matching_spaces)}, "
          f"notebooks={len(notebooks)})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)
