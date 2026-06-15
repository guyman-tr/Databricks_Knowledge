"""Shared helpers for Tableau Metadata API scripts in this folder.

Loads creds from tools/tableau/.env, signs in via JWT, and exposes a paginated
GraphQL iterator. Mirrors the auth pattern proven in test_connection.py.
"""
from __future__ import annotations

import datetime
import os
import uuid
import warnings
from pathlib import Path
from typing import Any, Iterator

import jwt
import tableauserverclient as tsc
import urllib3
from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def _env(name: str, default: str | None = None) -> str:
    val = os.getenv(name, default if default is not None else "")
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


def signin() -> tsc.Server:
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


class GqlNodeLimitExceeded(Exception):
    """Raised when the API returns a NODE_LIMIT_EXCEEDED warning (partial data)."""


def gql(server: tsc.Server, query: str, variables: dict[str, Any] | None = None) -> dict[str, Any]:
    resp = server.metadata.query(query, variables=variables or {})
    errors = resp.get("errors") or []
    if errors:
        # Treat NODE_LIMIT_EXCEEDED specially: surface as a typed exception so the
        # iterator can shrink page_size and retry. All other errors are fatal.
        codes = {(e.get("extensions") or {}).get("code") for e in errors}
        severities = {(e.get("extensions") or {}).get("severity") for e in errors}
        if "NODE_LIMIT_EXCEEDED" in codes:
            raise GqlNodeLimitExceeded(str(errors))
        # Severity WARNING with no fatal code → log and continue with partial data.
        if severities and severities == {"WARNING"}:
            print(f"  [gql warning] {errors}", flush=True)
            return resp["data"]
        raise SystemExit(f"GraphQL errors: {errors}")
    return resp["data"]


def iter_paginated(
    server: tsc.Server,
    query: str,
    connection_path: str,
    page_size: int = 50,
    progress_every: int = 200,
    progress_label: str = "items",
    min_page_size: int = 1,
) -> Iterator[dict[str, Any]]:
    """Iterate a `*Connection` GraphQL query that uses (first, after) cursoring.

    `connection_path` is the dotted path to the connection object inside the
    response `data`, e.g. "customSQLTablesConnection".
    Yields each node. On NODE_LIMIT_EXCEEDED, halves page_size and retries the
    same cursor (cap at min_page_size; below that, raises).
    """
    after: str | None = None
    cur_page = page_size
    n = 0
    while True:
        try:
            data = gql(server, query, variables={"first": cur_page, "after": after})
        except GqlNodeLimitExceeded:
            new_page = max(min_page_size, cur_page // 2)
            if new_page == cur_page:
                raise SystemExit(
                    f"NODE_LIMIT_EXCEEDED at min page size {cur_page}. "
                    "Trim the GraphQL fragment further."
                )
            print(f"  [page shrink] node-limit hit; {cur_page} -> {new_page}", flush=True)
            cur_page = new_page
            continue
        node_path = connection_path
        cur: Any = data
        for part in node_path.split("."):
            cur = cur[part]
        for node in cur["nodes"]:
            n += 1
            if progress_every and n % progress_every == 0:
                print(f"  scanned {n} {progress_label} (page={cur_page}) ...", flush=True)
            yield node
        if not cur["pageInfo"]["hasNextPage"]:
            return
        after = cur["pageInfo"]["endCursor"]
        # gentle ramp back up after a shrink, but never above the original ask
        if cur_page < page_size:
            cur_page = min(page_size, cur_page * 2)


def introspect_type(server: tsc.Server, type_name: str) -> list[tuple[str, str]]:
    """Return [(field_name, type_str), ...] for a given GraphQL type."""
    q = """
    query t($n: String!) {
      __type(name: $n) {
        name
        fields { name type { name kind ofType { name kind ofType { name kind } } } }
      }
    }
    """
    data = gql(server, q, {"n": type_name})
    t = data["__type"]
    if not t:
        return []
    out: list[tuple[str, str]] = []
    for f in t["fields"]:
        out.append((f["name"], _flatten_type(f["type"])))
    return out


def _flatten_type(t: dict[str, Any]) -> str:
    if t is None:
        return "?"
    if t.get("name"):
        return t["name"]
    inner = t.get("ofType")
    kind = t.get("kind", "")
    inside = _flatten_type(inner) if inner else "?"
    if kind == "NON_NULL":
        return f"{inside}!"
    if kind == "LIST":
        return f"[{inside}]"
    return inside or "?"
