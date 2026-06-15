"""
Reusable Synapse connection utility.

Usage by agents:
    from synapse_connect import connect, run_query, run_queries, print_table

    conn = connect()
    cols, rows = run_query(conn, "SELECT TOP 5 * FROM DWH_dbo.Dim_Country")
    print_table(cols, rows)
    conn.close()

    results = run_queries(["SELECT ...", "SELECT ..."])

SQL authentication (no Azure AD / MFA):
    Set environment variables (PowerShell):
        $env:SYNAPSE_SQL_USER = "your_sql_login"
        $env:SYNAPSE_SQL_PASSWORD = "..."
    Optional overrides:
        SYNAPSE_SERVER   (default: see SERVER below)
        SYNAPSE_DATABASE (default: see DATABASE below)
    When SYNAPSE_SQL_USER and SYNAPSE_SQL_PASSWORD are both set, connect() uses
    SQL Server authentication only — no interactive or device-code flows.

Azure AD (only if SQL env vars are not set):
    1. ActiveDirectoryIntegrated (Windows SSO via the logged-in user) —
       silent, no popup. Works whenever the machine is signed into the
       AD tenant that owns the Synapse pool. This is the preferred path.
    2. ActiveDirectoryInteractive (cached WAM token) — fallback for
       environments where Integrated can't be used.
    3. If both hang, device code to warm cache, then retry Interactive.
"""
import os
import sys
import signal
import pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"
CONNECT_TIMEOUT = 30
QUERY_TIMEOUT = 300

# Env-based SQL auth (see module docstring)
_ENV_SQL_USER = "SYNAPSE_SQL_USER"
_ENV_SQL_PASSWORD = "SYNAPSE_SQL_PASSWORD"
_ENV_SERVER = "SYNAPSE_SERVER"
_ENV_DATABASE = "SYNAPSE_DATABASE"


def _sql_auth_from_env():
    """Return (user, password) if both SQL auth env vars are set, else (None, None)."""
    user = os.environ.get(_ENV_SQL_USER, "").strip()
    pwd = os.environ.get(_ENV_SQL_PASSWORD, "")
    if user and pwd:
        return user, pwd
    return None, None


def _effective_server_database():
    return (
        os.environ.get(_ENV_SERVER, SERVER).strip() or SERVER,
        os.environ.get(_ENV_DATABASE, DATABASE).strip() or DATABASE,
    )


def _escape_odbc_brace_value(s: str) -> str:
    """Brace-wrap ODBC values; double any closing braces inside the value."""
    return s.replace("}", "}}")


def _conn_str_sql(user: str, password: str):
    """SQL Server authentication — no Azure AD."""
    srv, db = _effective_server_database()
    pwd_esc = _escape_odbc_brace_value(password)
    return (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={srv};"
        f"Database={db};"
        f"UID={user};"
        f"PWD={{{pwd_esc}}};"
        "Encrypt=yes;TrustServerCertificate=no;"
        f"Connection Timeout={CONNECT_TIMEOUT};"
    )


def _ensure_line_buffering():
    """Cursor terminals don't show output without line buffering."""
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass


def _conn_str_integrated():
    """ActiveDirectoryIntegrated — Windows SSO, silent, no popup."""
    srv, db = _effective_server_database()
    return (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={srv};"
        f"Database={db};"
        "Authentication=ActiveDirectoryIntegrated;"
        "Encrypt=yes;TrustServerCertificate=no;"
        f"Connection Timeout={CONNECT_TIMEOUT};"
    )


def _conn_str():
    """ActiveDirectoryInteractive (WAM) — popup on first call, cached after."""
    srv, db = _effective_server_database()
    return (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={srv};"
        f"Database={db};"
        f"UID={UID};"
        "Authentication=ActiveDirectoryInteractive;"
        "Encrypt=yes;TrustServerCertificate=no;"
        f"Connection Timeout={CONNECT_TIMEOUT};"
    )


class _Timeout(Exception):
    pass


def _timeout_handler(signum, frame):
    raise _Timeout()


def _try_integrated(timeout_sec=CONNECT_TIMEOUT):
    """Try ActiveDirectoryIntegrated (Windows SSO). Returns conn or raises on
    timeout/error. Silent — no popup. Works whenever the machine is signed
    into the AD tenant that owns the Synapse pool."""
    if sys.platform != "win32":
        old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
        signal.alarm(timeout_sec)
    try:
        conn = pyodbc.connect(_conn_str_integrated(), timeout=timeout_sec)
        return conn
    except _Timeout:
        raise _Timeout("ActiveDirectoryIntegrated timed out")
    finally:
        if sys.platform != "win32":
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)


def _try_interactive(timeout_sec=CONNECT_TIMEOUT):
    """Try ActiveDirectoryInteractive. Returns conn or raises on timeout/error."""
    if sys.platform != "win32":
        old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
        signal.alarm(timeout_sec)
    try:
        conn = pyodbc.connect(_conn_str(), timeout=timeout_sec)
        return conn
    except _Timeout:
        raise _Timeout("ActiveDirectoryInteractive timed out — WAM cache is cold")
    finally:
        if sys.platform != "win32":
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)


def _warm_cache_via_device_code():
    """
    Authenticate via device code to warm the MSAL/WAM cache.
    The token itself can't be used with Synapse (wrong client ID),
    but the act of authenticating refreshes the cache that
    ActiveDirectoryInteractive reads from.
    """
    try:
        from azure.identity import DeviceCodeCredential
    except ImportError:
        print("ERROR: azure-identity not installed. Run: pip install azure-identity", flush=True)
        raise

    print("\n--- Device Code Authentication ---", flush=True)
    print("This warms the Windows auth cache so Synapse can connect silently.", flush=True)

    credential = DeviceCodeCredential(
        prompt_callback=lambda url, code, _: print(
            f"\n  1. Open: {url}\n  2. Enter code: {code}\n  3. Sign in as {UID}\n",
            flush=True,
        )
    )
    try:
        credential.get_token("https://database.windows.net/.default")
        print("Cache warmed successfully.\n", flush=True)
    except Exception as e:
        print(f"Device code auth failed: {e}", flush=True)
        print("You may need to authenticate manually in a browser.", flush=True)
        raise


def connect(verbose=True):
    """
    Connect to Synapse.

    If SYNAPSE_SQL_USER and SYNAPSE_SQL_PASSWORD are set, uses SQL authentication
    (no browser/MFA). Otherwise uses ActiveDirectoryInteractive + device-code fallback.
    """
    _ensure_line_buffering()

    sql_user, sql_pwd = _sql_auth_from_env()
    if sql_user is not None:
        srv, db = _effective_server_database()
        if verbose:
            print(
                f"Connecting to Synapse ({srv} / {db}) using SQL login {_ENV_SQL_USER}...",
                flush=True,
            )
        conn = pyodbc.connect(_conn_str_sql(sql_user, sql_pwd), timeout=CONNECT_TIMEOUT)
        conn.timeout = QUERY_TIMEOUT
        if verbose:
            print("Connected (SQL authentication).\n", flush=True)
        return conn

    srv, _ = _effective_server_database()
    if verbose:
        print(f"Connecting to Synapse ({srv})...", flush=True)

    # Attempt 1: ActiveDirectoryIntegrated (Windows SSO — silent, no popup)
    try:
        conn = _try_integrated()
        conn.timeout = QUERY_TIMEOUT
        if verbose:
            print("Connected (ActiveDirectoryIntegrated / Windows SSO).\n", flush=True)
        return conn
    except _Timeout:
        if verbose:
            print("Integrated auth timed out — trying Interactive.", flush=True)
    except pyodbc.Error as e:
        if verbose:
            print(f"Integrated auth failed: {e} — trying Interactive.", flush=True)

    # Attempt 2: ActiveDirectoryInteractive with cached WAM token
    try:
        conn = _try_interactive()
        conn.timeout = QUERY_TIMEOUT
        if verbose:
            print("Connected (ActiveDirectoryInteractive, cached credentials).\n", flush=True)
        return conn
    except _Timeout:
        if verbose:
            print("Cached credentials not available — need interactive auth.", flush=True)
    except pyodbc.Error as e:
        if verbose:
            print(f"Connection attempt failed: {e}", flush=True)
            print("Trying device code fallback...", flush=True)

    # Attempt 3: warm cache via device code, then retry Interactive
    _warm_cache_via_device_code()

    if verbose:
        print("Retrying Synapse connection with warmed cache...", flush=True)

    conn = pyodbc.connect(_conn_str(), timeout=120)
    conn.timeout = QUERY_TIMEOUT
    if verbose:
        print("Connected.\n", flush=True)
    return conn


def run_query(conn, query, params=None):
    """Execute a query. Returns (column_names, rows)."""
    cursor = conn.cursor()
    cursor.execute(query, params or [])
    if cursor.description is None:
        return [], []
    cols = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    return cols, rows


def run_queries(queries, params_list=None):
    """
    Execute multiple queries in one connection session.
    Returns list of (cols, rows) tuples.
    """
    conn = connect()
    results = []
    try:
        for i, q in enumerate(queries):
            p = (params_list[i] if params_list else None)
            results.append(run_query(conn, q, p))
    finally:
        conn.close()
    return results


def print_table(cols, rows, max_col_width=60):
    """Print results as a markdown table."""
    if not cols:
        print("(no results)\n")
        return
    print("| " + " | ".join(cols) + " |")
    print("| " + " | ".join("---" for _ in cols) + " |")
    for r in rows:
        cells = []
        for v in r:
            s = str(v) if v is not None else ""
            if len(s) > max_col_width:
                s = s[:max_col_width - 3] + "..."
            cells.append(s)
        print("| " + " | ".join(cells) + " |")
    print()


if __name__ == "__main__":
    print("Testing Synapse connection...\n")
    conn = connect()
    cols, rows = run_query(conn, "SELECT TOP 3 TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME")
    print_table(cols, rows)
    print(f"Success — {len(rows)} rows returned.")
    conn.close()
