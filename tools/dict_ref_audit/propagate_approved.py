"""Post-approval pipeline: from edited wikis to UC.

Reads `_dict_ref_audit_apply_report.csv` to find which .md files were edited,
then runs in order:

  1) `python tools/regen_alter_from_wiki.py <md_paths>`
       Refreshes the `-- ---- Column Comments ----` section of each
       corresponding `.alter.sql`.

  2) `python tools/redeploy_schema.py --files <alter_sql_paths> --apply
       --label dict_ref_audit_<YYYYMMDD>`
       Pushes the new ALTER statements to UC for TABLE targets.

  3) For .alter.sql files whose wiki lives under a `Views/` folder, route
     through `tools/_tmp_deploy_view_comments.py` instead (because UC views
     require `COMMENT ON COLUMN`, not `ALTER TABLE`).

DRY-RUN by default (no Databricks call). Pass `--apply` to actually deploy.
Pre-deploy, this script always runs `regen_alter_from_wiki.py` so the
.alter.sql files reflect the latest wiki .md.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"


def _alter_path_for_md(md_rel: str) -> Path:
    md_path = REPO / md_rel
    return md_path.with_suffix(".alter.sql")


def _is_view_target(md_rel: str) -> bool:
    parts = Path(md_rel).parts
    return "Views" in parts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true",
                         help="Actually run regen + deploy (default: dry-run).")
    parser.add_argument("--apply-report",
                         default="knowledge/_dict_ref_audit_apply_report.csv")
    parser.add_argument("--label",
                         default=f"dict_ref_audit_{dt.date.today():%Y%m%d}")
    parser.add_argument("--skip-regen", action="store_true",
                         help="Skip the regen step (use if .alter.sql files were "
                              "manually regenerated already).")
    args = parser.parse_args()

    report = REPO / args.apply_report
    if not report.exists():
        print(f"[error] apply report not found: {report}", file=sys.stderr)
        print("Did you run apply_approved.py with --apply first?", file=sys.stderr)
        return 1

    rows = list(csv.DictReader(report.open(encoding="utf-8")))
    ok_rows = [r for r in rows if r.get("status") == "OK"]
    affected_mds = sorted({r["wiki_md"] for r in ok_rows})
    print(f"Apply report had {len(ok_rows)} OK edits across {len(affected_mds)} wiki files.")

    table_alters: list[Path] = []
    view_alters: list[Path] = []
    missing_alters: list[str] = []
    for md_rel in affected_mds:
        alter = _alter_path_for_md(md_rel)
        if not alter.exists():
            missing_alters.append(md_rel)
            continue
        if _is_view_target(md_rel):
            view_alters.append(alter)
        else:
            table_alters.append(alter)

    print(f"  Table .alter.sql files: {len(table_alters)}")
    print(f"  View  .alter.sql files: {len(view_alters)}")
    if missing_alters:
        print(f"  No matching .alter.sql for {len(missing_alters)} wikis:")
        for m in missing_alters[:5]:
            print(f"     {m}")
        if len(missing_alters) > 5:
            print(f"     ... +{len(missing_alters) - 5} more")
        print("  (These need scaffolding before they can be deployed.)")

    mode = "APPLY" if args.apply else "DRY-RUN"

    # ---- Step 1: regen .alter.sql from wiki ----
    if not args.skip_regen:
        md_paths = [str((REPO / m).resolve()) for m in affected_mds]
        cmd = [sys.executable, "tools/regen_alter_from_wiki.py", *md_paths]
        print(f"\n[{mode}] Step 1: regen .alter.sql")
        if args.apply:
            print(f"  exec: regen_alter_from_wiki.py on {len(md_paths)} .md files")
            res = subprocess.run(cmd, cwd=str(REPO))
            if res.returncode != 0:
                print(f"[error] regen failed (exit {res.returncode})", file=sys.stderr)
                return res.returncode
        else:
            print(f"  would-exec: regen_alter_from_wiki.py on {len(md_paths)} .md files")

    # ---- Step 2: deploy TABLE targets ----
    if table_alters:
        files_args = [str(p.resolve()) for p in table_alters]
        cmd = [
            sys.executable, "tools/redeploy_schema.py",
            "--files", *files_args,
            "--label", args.label,
        ]
        if args.apply:
            cmd.append("--apply")
        print(f"\n[{mode}] Step 2: redeploy_schema.py for {len(table_alters)} tables  (label={args.label})")
        if args.apply:
            res = subprocess.run(cmd, cwd=str(REPO))
            if res.returncode != 0:
                print(f"[warn] redeploy_schema exit {res.returncode}", file=sys.stderr)
        else:
            print(f"  would-exec: redeploy_schema.py --files <{len(table_alters)} paths> --label {args.label} --apply")

    # ---- Step 3: deploy VIEW targets via COMMENT ON COLUMN ----
    if view_alters:
        files_args = [str(p.resolve()) for p in view_alters]
        cmd = [sys.executable, "tools/_tmp_deploy_view_comments.py", *files_args]
        if args.apply:
            cmd.append("--apply")
        print(f"\n[{mode}] Step 3: _tmp_deploy_view_comments.py for {len(view_alters)} views")
        if args.apply:
            res = subprocess.run(cmd, cwd=str(REPO))
            if res.returncode != 0:
                print(f"[warn] view-deploy exit {res.returncode}", file=sys.stderr)
        else:
            print(f"  would-exec: _tmp_deploy_view_comments.py <{len(view_alters)} paths> --apply")

    print(f"\n[{mode}] Done.")
    if not args.apply:
        print("Rerun with --apply to actually regen + deploy.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
