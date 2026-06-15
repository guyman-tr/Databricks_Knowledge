"""Direct Synapse runner for the eval-suite loop authoring agent.

Same auth path as the Synapse MCP server (SQL auth from
~/.cursor/synapse-credentials.env, with ActiveDirectoryIntegrated fallback).

Why not call the MCP? Because the loop runs many queries in series and
the SSE round-trip is slow. Direct pyodbc is 10x faster and uses the
exact same credential.
"""
from __future__ import annotations

import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import pyodbc
except ImportError as e:  # pragma: no cover
    raise SystemExit("ERROR: pip install pyodbc") from e


SYNAPSE_CRED_FILE = Path.home() / ".cursor" / "synapse-credentials.env"
PROD_SERVER = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
PROD_DATABASE = "sql_dp_prod_we"


@dataclass
class SynapseResult:
    columns: list[str]
    rows: list[list[Any]]
    elapsed_s: float


def _load_creds() -> tuple[str | None, str | None]:
    user = os.getenv("SYNAPSE_SQL_USER")
    pwd = os.getenv("SYNAPSE_SQL_PASS")
    if user and pwd:
        return user, pwd
    if SYNAPSE_CRED_FILE.exists():
        for line in SYNAPSE_CRED_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip()
            if k == "SYNAPSE_SQL_USER":
                user = v
            elif k == "SYNAPSE_SQL_PASS":
                pwd = v
    return user, pwd


def _connect(server: str = PROD_SERVER, database: str = PROD_DATABASE) -> pyodbc.Connection:
    user, pwd = _load_creds()
    base = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};"
        f"DATABASE={database};Encrypt=yes;TrustServerCertificate=no;"
        f"Connection Timeout=60;"
    )
    if user and pwd:
        return pyodbc.connect(base + f"UID={user};PWD={pwd}")
    return pyodbc.connect(base + "Authentication=ActiveDirectoryIntegrated;")


_conn: pyodbc.Connection | None = None


def run(sql: str, *, server: str = PROD_SERVER, database: str = PROD_DATABASE,
        timeout_s: int = 600) -> SynapseResult:
    global _conn
    if _conn is None:
        _conn = _connect(server, database)
    _conn.timeout = timeout_s
    t0 = time.time()
    cur = _conn.cursor()
    try:
        cur.execute(sql)
        cols = [c[0] for c in cur.description] if cur.description else []
        rows = [list(r) for r in cur.fetchall()] if cur.description else []
    except pyodbc.Error:
        try:
            _conn.close()
        except Exception:
            pass
        _conn = _connect(server, database)
        _conn.timeout = timeout_s
        cur = _conn.cursor()
        cur.execute(sql)
        cols = [c[0] for c in cur.description] if cur.description else []
        rows = [list(r) for r in cur.fetchall()] if cur.description else []
    return SynapseResult(columns=cols, rows=rows, elapsed_s=time.time() - t0)
