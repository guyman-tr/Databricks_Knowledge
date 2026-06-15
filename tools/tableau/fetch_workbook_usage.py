"""Fetch view-usage stats (totalViewCount + lastViewedAt) for every workbook
referenced in `knowledge/tableau/_index/workbooks.csv`.

Aggregates per workbook by summing view counts and taking the max lastViewedAt
across all views in that workbook.

Output: knowledge/tableau/_index/usage.csv
        columns: workbook_luid, workbook_name, last_viewed_at, total_views,
                 views_count, age_days

Re-uses the JWT auth flow from extract_table_metadata.py.
"""

from __future__ import annotations

import csv
import datetime
import os
import sys
import uuid
import warnings
from pathlib import Path

import urllib3
import jwt
import tableauserverclient as tsc
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")

warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

WORKBOOKS_CSV = REPO_ROOT / "knowledge" / "tableau" / "_index" / "workbooks.csv"
OUT_CSV       = REPO_ROOT / "knowledge" / "tableau" / "_index" / "usage.csv"

sys.stdout.reconfigure(line_buffering=True)


def _env(name: str) -> str:
    val = os.getenv(name, "")
    if not val:
        raise SystemExit(f"Missing env var: {name}")
    return val


def make_jwt(client_id: str, secret_id: str, secret_value: str, username: str) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "iss": client_id,
        "exp": now + datetime.timedelta(minutes=10),
        "jti": str(uuid.uuid4()),
        "aud": "tableau",
        "sub": username,
        "scp": ["tableau:content:*"],
    }
    headers = {"kid": secret_id, "iss": client_id}
    return jwt.encode(payload, secret_value, algorithm="HS256", headers=headers)


def sign_in() -> tsc.Server:
    server_url = _env("TABLEAU_SERVER").rstrip("/")
    client_id = _env("TABLEAU_CLIENT_ID")
    secret_id = _env("TABLEAU_SECRET_ID")
    secret_value = _env("TABLEAU_SECRET_VALUE")
    username = _env("TABLEAU_USERNAME")
    site = os.getenv("TABLEAU_SITE_NAME", "")
    token = make_jwt(client_id, secret_id, secret_value, username)
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    server.auth.sign_in(tsc.JWTAuth(token, site_id=site))
    return server


def main() -> int:
    if not WORKBOOKS_CSV.exists():
        print(f"[usage] {WORKBOOKS_CSV} missing — run the bulk Tableau sweep first")
        return 2

    luids: dict[str, str] = {}
    with WORKBOOKS_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            luid = (row.get("workbook_luid") or "").strip()
            if not luid:
                continue
            if luid not in luids:
                luids[luid] = row.get("workbook_name", "")
    print(f"[usage] {len(luids)} unique workbook LUIDs to probe", flush=True)

    print("[usage] signing in to Tableau ...", flush=True)
    server = sign_in()
    print("[usage] signed in", flush=True)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    now = datetime.datetime.now(datetime.timezone.utc)
    written = 0
    errors  = 0
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "workbook_luid", "workbook_name",
            "last_viewed_at", "total_views", "views_count", "age_days",
        ])

        for i, (luid, name) in enumerate(sorted(luids.items()), 1):
            try:
                wb = server.workbooks.get_by_id(luid)
                server.workbooks.populate_views(wb, usage=True)
                views = wb.views or []
                total_views = 0
                last_viewed: datetime.datetime | None = None
                for v in views:
                    if getattr(v, "total_views", None):
                        try:
                            total_views += int(v.total_views)
                        except (TypeError, ValueError):
                            pass
                    last_str = getattr(v, "last_viewed_at", None)
                    if last_str:
                        # parse possible formats; tsc returns datetime usually
                        if isinstance(last_str, datetime.datetime):
                            dt = last_str
                        else:
                            dt = None
                            for fmt in (
                                "%Y-%m-%dT%H:%M:%SZ",
                                "%Y-%m-%dT%H:%M:%S.%fZ",
                                "%Y-%m-%dT%H:%M:%S",
                            ):
                                try:
                                    dt = datetime.datetime.strptime(str(last_str), fmt)
                                    dt = dt.replace(tzinfo=datetime.timezone.utc)
                                    break
                                except ValueError:
                                    pass
                        if dt and (last_viewed is None or dt > last_viewed):
                            last_viewed = dt

                age = ""
                last_str_out = ""
                if last_viewed is not None:
                    last_str_out = last_viewed.strftime("%Y-%m-%d %H:%M:%S")
                    age = f"{(now - last_viewed).total_seconds() / 86400.0:.1f}"

                w.writerow([luid, name, last_str_out, total_views, len(views), age])
                written += 1

                if i % 25 == 0 or i == len(luids):
                    print(f"[usage] [{i:4d}/{len(luids)}] OK {name[:60]} total_views={total_views} last={last_str_out or '(never)'}", flush=True)
            except Exception as e:  # noqa: BLE001
                msg = str(e).splitlines()[0][:160]
                errors += 1
                w.writerow([luid, name, "", "", "", ""])
                print(f"[usage] [{i:4d}/{len(luids)}] FAIL {name[:60]} -> {msg}", flush=True)

    print(f"\n[usage] wrote {written} rows ({errors} errors) -> {OUT_CSV}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
