"""One-off debug: inspect what attributes are populated on a ViewItem after
populate_views(workbook, usage=True). We need to find a freshness signal."""

from __future__ import annotations

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


def make_jwt(client_id, secret_id, secret_value, username):
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "iss": client_id, "exp": now + datetime.timedelta(minutes=10),
        "jti": str(uuid.uuid4()), "aud": "tableau", "sub": username,
        "scp": ["tableau:content:*"],
    }
    return jwt.encode(payload, secret_value, algorithm="HS256",
                      headers={"kid": secret_id, "iss": client_id})


def main() -> int:
    server_url = os.getenv("TABLEAU_SERVER", "").rstrip("/")
    token = make_jwt(os.environ["TABLEAU_CLIENT_ID"], os.environ["TABLEAU_SECRET_ID"],
                     os.environ["TABLEAU_SECRET_VALUE"], os.environ["TABLEAU_USERNAME"])
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    server.auth.sign_in(tsc.JWTAuth(token, site_id=os.getenv("TABLEAU_SITE_NAME", "")))
    print(f"REST API version: {server.version}")
    try:
        import importlib.metadata as md
        print(f"TSC version: {md.version('tableauserverclient')}")
    except Exception as e:  # noqa: BLE001
        print(f"TSC version unknown: {e}")

    luid = "31f8b29f-136d-401a-9c5e-0280c1f0ab41"  # known active workbook
    wb = server.workbooks.get_by_id(luid)
    print(f"\nWorkbook attributes:")
    for k in sorted(vars(wb)):
        v = getattr(wb, k, None)
        if k.startswith("_") or callable(v):
            continue
        if isinstance(v, (str, int, float, bool, datetime.datetime, type(None))):
            print(f"  {k:30s} = {v!r}")

    server.workbooks.populate_views(wb, usage=True)
    if wb.views:
        v = wb.views[0]
        print(f"\nFirst view attributes (after populate_views(usage=True)):")
        for k in sorted(vars(v)):
            val = getattr(v, k, None)
            if k.startswith("_") or callable(val):
                continue
            if isinstance(val, (str, int, float, bool, datetime.datetime, type(None))):
                print(f"  {k:30s} = {val!r}")
        # Also try public properties
        print(f"\n  v.total_views property: {getattr(v, 'total_views', '<missing>')!r}")
        print(f"  v.last_viewed_at property: {getattr(v, 'last_viewed_at', '<missing>')!r}")
        print(f"  dir(v): {[a for a in dir(v) if not a.startswith('_')]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
