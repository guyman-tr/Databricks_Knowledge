"""Smoke-test the Tableau Connected App credentials in tools/tableau/.env.

Tries each plausible site contentUrl ("", "default", "Default") so we can
diagnose the 'TABLEAU_SITE_NAME' question quickly. Prints how many workbooks
are visible to confirm the metadata API is reachable.

Run from anywhere; we explicitly load the .env next to this file.
"""
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

HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")

warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def _env(name: str) -> str:
    val = os.getenv(name, "")
    if not val:
        raise SystemExit(f"Missing env var: {name}")
    return val


def make_jwt(
    client_id: str,
    secret_id: str,
    secret_value: str,
    username: str,
    scopes: list[str] | None = None,
) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "iss": client_id,
        "exp": now + datetime.timedelta(minutes=5),
        "jti": str(uuid.uuid4()),
        "aud": "tableau",
        "sub": username,
        "scp": scopes if scopes is not None else ["tableau:content:*"],
    }
    headers = {"kid": secret_id, "iss": client_id}
    return jwt.encode(payload, secret_value, algorithm="HS256", headers=headers)


def try_signin(server_url: str, site: str, token: str) -> tuple[bool, str]:
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    try:
        server.auth.sign_in(tsc.JWTAuth(token, site_id=site))
    except Exception as exc:  # noqa: BLE001
        return False, f"sign_in failed: {type(exc).__name__}: {exc}"
    try:
        try:
            info = server.server_info.get()
            product = getattr(info, "product_version", "?")
            rest_api = getattr(info, "rest_api_version", "?")
        except Exception as exc:  # noqa: BLE001
            product = rest_api = f"<server_info err: {type(exc).__name__}>"

        try:
            _, pagination = server.workbooks.get()
            wb_count = pagination.total_available
        except Exception as exc:  # noqa: BLE001
            wb_count = f"<workbooks err: {type(exc).__name__}: {exc}>"

        try:
            meta_resp = server.metadata.query("query { databaseTablesConnection(first: 1) { totalCount } }")
            meta_total = meta_resp.get("data", {}).get("databaseTablesConnection", {}).get("totalCount")
            meta_errs = meta_resp.get("errors")
            meta_status = (
                f"databaseTables.totalCount={meta_total}"
                if not meta_errs
                else f"errors={[e.get('message') for e in meta_errs]}"
            )
        except Exception as exc:  # noqa: BLE001
            meta_status = f"<metadata err: {type(exc).__name__}: {exc}>"

        return True, (
            f"OK | product={product} restApi={rest_api} "
            f"site_id={server.site_id} workbooks_visible={wb_count} "
            f"metadata: {meta_status}"
        )
    finally:
        try:
            server.auth.sign_out()
        except Exception:  # noqa: BLE001
            pass


def main() -> int:
    raw_server = _env("TABLEAU_SERVER")
    server_url = raw_server.rstrip("/")
    if server_url != raw_server:
        print(f"NOTE: stripped trailing slash from TABLEAU_SERVER -> {server_url}")

    client_id = _env("TABLEAU_CLIENT_ID")
    secret_id = _env("TABLEAU_SECRET_ID")
    secret_value = _env("TABLEAU_SECRET_VALUE")
    username = _env("TABLEAU_USERNAME")
    declared_site = os.getenv("TABLEAU_SITE_NAME", "")

    print(f"Server      : {server_url}")
    print(f"Username    : {username}")
    print(f"Declared site: '{declared_site}'")
    print()

    site_candidates: list[str] = []
    for c in [declared_site, "", "default", "Default"]:
        if c not in site_candidates:
            site_candidates.append(c)

    sub_candidates: list[str] = []
    for c in [username, username.split("@")[0]]:
        if c not in sub_candidates:
            sub_candidates.append(c)

    scope_candidates: list[list[str]] = [
        ["tableau:content:*"],
        [
            "tableau:content:read",
            "tableau:views:download",
            "tableau:workbooks:download",
        ],
    ]

    success: tuple[str, str, list[str]] | None = None
    for sub in sub_candidates:
        for scopes in scope_candidates:
            token = make_jwt(client_id, secret_id, secret_value, sub, scopes)
            for site in site_candidates:
                tag = f"sub='{sub}' scope={scopes} site='{site}'"
                print(f"--- {tag} ---")
                ok, msg = try_signin(server_url, site, token)
                print(msg)
                print()
                if ok:
                    success = (sub, site, scopes)
                    break
            if success:
                break
        if success:
            break

    if success is None:
        print("All combinations failed. See errors above.")
        return 2

    sub, site, scopes = success
    print("SUCCESS")
    print(f"  sub      = {sub}")
    print(f"  site_id  = '{site}'")
    print(f"  scopes   = {scopes}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
