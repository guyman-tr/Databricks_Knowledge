"""Shared Databricks-SQL connection helper for the UC-Pipeline pack.

Same auth resolution as tools/uc_domains/discover_uc.py and tools/dbx_query.py:
  1. DATABRICKS_TOKEN env (PAT) — headless/CI.
  2. ~/.databrickscfg profile via SDK Config — DATABRICKS_MCP_PROFILE → DATABRICKS_CONFIG_PROFILE → 'guyman' → 'DEFAULT'.
  3. databricks-sql-connector built-in U2M OAuth (browser pop-up) — last resort.
"""
from __future__ import annotations

import os
import sys

try:
    from databricks import sql as dbsql
except ImportError:
    print("Install: pip install databricks-sql-connector databricks-sdk", file=sys.stderr)
    raise

DEFAULT_HOSTNAME = "adb-5142916747090026.6.azuredatabricks.net"
DEFAULT_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"


def connect():
    hostname = os.environ.get("DATABRICKS_SERVER_HOSTNAME") or DEFAULT_HOSTNAME
    http_path = os.environ.get("DATABRICKS_HTTP_PATH") or DEFAULT_HTTP_PATH

    token = os.environ.get("DATABRICKS_TOKEN")
    if token:
        print(f"[connect] host={hostname} http_path={http_path} auth=PAT",
              file=sys.stderr, flush=True)
        return dbsql.connect(server_hostname=hostname, http_path=http_path, access_token=token)

    profile = (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "guyman"
    )
    try:
        from databricks.sdk.core import Config
        cfg = Config(profile=profile)
        print(f"[connect] host={hostname} http_path={http_path} auth=SDK profile={profile}",
              file=sys.stderr, flush=True)
        return dbsql.connect(
            server_hostname=hostname,
            http_path=http_path,
            credentials_provider=lambda: cfg.authenticate,
        )
    except Exception as e:
        print(f"[connect] SDK profile auth failed ({e}); falling back to U2M OAuth",
              file=sys.stderr, flush=True)

    return dbsql.connect(server_hostname=hostname, http_path=http_path, auth_type="databricks-oauth")


def workspace_client():
    """Return a Databricks SDK WorkspaceClient using the same auth path as connect().

    Used for Workspace API notebook export, jobs.get(), pipelines.get(), etc.
    """
    from databricks.sdk import WorkspaceClient
    from databricks.sdk.core import Config

    token = os.environ.get("DATABRICKS_TOKEN")
    if token:
        return WorkspaceClient(host=f"https://{os.environ.get('DATABRICKS_SERVER_HOSTNAME') or DEFAULT_HOSTNAME}",
                               token=token)

    profile = (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "guyman"
    )
    cfg = Config(profile=profile)
    return WorkspaceClient(config=cfg)
