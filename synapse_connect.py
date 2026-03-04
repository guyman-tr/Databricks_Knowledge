"""
Reusable Synapse connection utility.

Usage by agents:
    from synapse_connect import connect, run_query, run_queries, print_table

    conn = connect()           # handles auth with clear user prompts
    cols, rows = run_query(conn, "SELECT TOP 5 * FROM DWH_dbo.Dim_Country")
    print_table(cols, rows)
    conn.close()

    # Or run multiple queries in one session:
    results = run_queries(["SELECT ...", "SELECT ..."])

Auth strategy (in order):
    1. Try ActiveDirectoryInteractive with cached WAM token (silent, no popup)
    2. If that hangs >30s, it means WAM cache is cold — fall back to device code
    3. Device code warms the MSAL cache, then retry ActiveDirectoryInteractive

Why not use DeviceCodeCredential token directly?
    The device-code client ID isn't whitelisted on the Synapse server.
    But authenticating via device code warms the Windows WAM/MSAL cache,
    which ActiveDirectoryInteractive then picks up silently.
"""
import sys
import signal
import pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"
CONNECT_TIMEOUT = 30
QUERY_TIMEOUT = 300


def _ensure_line_buffering():
    """Cursor terminals don't show output without line buffering."""
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass


def _conn_str():
    return (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={SERVER};"
        f"Database={DATABASE};"
        f"UID={UID};"
        "Authentication=ActiveDirectoryInteractive;"
        "Encrypt=yes;TrustServerCertificate=no;"
        f"Connection Timeout={CONNECT_TIMEOUT};"
    )


class _Timeout(Exception):
    pass


def _timeout_handler(signum, frame):
    raise _Timeout()


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
    Connect to Synapse with automatic auth fallback.

    Returns a pyodbc.Connection.

    Flow:
        1. Try ActiveDirectoryInteractive (uses cached WAM token)
        2. If popup hangs, warm cache via device code, then retry
    """
    _ensure_line_buffering()

    if verbose:
        print(f"Connecting to Synapse ({SERVER})...", flush=True)

    # Attempt 1: try with cached credentials
    try:
        conn = _try_interactive()
        conn.timeout = QUERY_TIMEOUT
        if verbose:
            print("Connected (cached credentials).\n", flush=True)
        return conn
    except _Timeout:
        if verbose:
            print("Cached credentials not available — need interactive auth.", flush=True)
    except pyodbc.Error as e:
        if verbose:
            print(f"Connection attempt failed: {e}", flush=True)
            print("Trying device code fallback...", flush=True)

    # Attempt 2: warm cache via device code, then retry
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
