"""
Pull portfolio_only CIDs for DateID=20260518 from both UC and Synapse using
inlined queries (NOT the view, to push date predicate down). Then diff and
trace one CID from each side.
"""
import os
import sys
import time

sys.stdout.reconfigure(line_buffering=True)

CREDS_FILE = r"C:\Users\guyman\.cursor\synapse-credentials.env"
if os.path.exists(CREDS_FILE):
    with open(CREDS_FILE) as _f:
        for _line in _f:
            _line = _line.strip()
            if not _line or _line.startswith("#") or "=" not in _line:
                continue
            _k, _, _v = _line.partition("=")
            _k, _v = _k.strip(), _v.strip()
            if _k == "SYNAPSE_SQL_USER" and _v:
                os.environ["SYNAPSE_SQL_USER"] = _v
            elif _k in ("SYNAPSE_SQL_PASS", "SYNAPSE_SQL_PASSWORD") and _v:
                os.environ["SYNAPSE_SQL_PASSWORD"] = _v

os.environ["SYNAPSE_SERVER"] = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
os.environ["SYNAPSE_DATABASE"] = "sql_dp_prod_we"

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import synapse_connect
synapse_connect.QUERY_TIMEOUT = 1200
from synapse_connect import connect as syn_connect, run_query as syn_run

from databricks import sql as dbx_sql


DATE_ID = 20260518
DBX_HOST = "adb-5142916747090026.6.azuredatabricks.net"
DBX_HTTP = "/sql/1.0/warehouses/208214768b0e0308"

UC_INLINE = f"""
WITH holders AS (
    SELECT dp.CID AS RealCID
    FROM main.dwh.dim_position dp
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    WHERE COALESCE(dp.IsAirDrop, 0) = 0
        AND dp.OpenDateID <= {DATE_ID}
        AND (dp.CloseDateID >= {DATE_ID} OR dp.CloseDateID = 0)
), options_aum AS (
    SELECT dc.RealCID
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
    INNER JOIN main.general.bronze_usabroker_apex_options op
        ON bps.AccountNumber = op.OptionsApexID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON op.GCID = dc.GCID
    WHERE bps.OfficeCode IN ('4GS', '5GU')
        AND bps.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
        AND CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT) = {DATE_ID}
    GROUP BY dc.RealCID
    HAVING MAX(bps.PositionMarketValue) > 0
), candidates AS (
    SELECT RealCID FROM holders
    UNION
    SELECT RealCID FROM options_aum
), actives AS (
    SELECT DISTINCT RealCID
    FROM main.etoro_kpi_prep.v_population_active_traders
    WHERE DateID = {DATE_ID}
)
SELECT DISTINCT c.RealCID
FROM candidates c
WHERE c.RealCID IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM actives a WHERE a.RealCID = c.RealCID)
"""


def get_uc_cids() -> set[int]:
    print("[UC] connecting...", flush=True)
    t0 = time.time()
    conn = dbx_sql.connect(
        server_hostname=DBX_HOST,
        http_path=DBX_HTTP,
        auth_type="databricks-oauth",
    )
    cur = conn.cursor()
    print("[UC] running inlined portfolio_only query...", flush=True)
    cur.execute(UC_INLINE)
    rows = cur.fetchall()
    cids = {int(r[0]) for r in rows if r[0] is not None}
    cur.close()
    conn.close()
    print(f"[UC] got {len(cids):,} CIDs in {time.time()-t0:,.1f}s", flush=True)
    return cids


def get_synapse_cids() -> set[int]:
    print("[SYN] connecting...", flush=True)
    t0 = time.time()
    conn = syn_connect()
    print(f"[SYN] running portfolio_only TVF for {DATE_ID}...", flush=True)
    cols, rows = syn_run(
        conn,
        f"SELECT DISTINCT RealCID FROM BI_DB_dbo.Function_Population_Portfolio_Only({DATE_ID}, {DATE_ID})",
    )
    cids = {int(r[0]) for r in rows if r[0] is not None}
    conn.close()
    print(f"[SYN] got {len(cids):,} CIDs in {time.time()-t0:,.1f}s", flush=True)
    return cids


def main():
    uc_cids = get_uc_cids()
    syn_cids = get_synapse_cids()

    only_uc = uc_cids - syn_cids
    only_syn = syn_cids - uc_cids
    both = uc_cids & syn_cids

    print()
    print("=" * 70)
    print(f"UC count:      {len(uc_cids):,}")
    print(f"Synapse count: {len(syn_cids):,}")
    print(f"In both:       {len(both):,}")
    print(f"Only in UC:    {len(only_uc):,}")
    print(f"Only in Syn:   {len(only_syn):,}")
    print("=" * 70)

    sample_only_uc = sorted(only_uc)[:20]
    sample_only_syn = sorted(only_syn)[:20]
    print(f"First 20 only-in-UC CIDs:  {sample_only_uc}")
    print(f"First 20 only-in-Syn CIDs: {sample_only_syn}")

    out_dir = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(out_dir, "_diff_portfolio_only_uc.txt"), "w") as f:
        f.write("\n".join(str(c) for c in sorted(only_uc)))
    with open(os.path.join(out_dir, "_diff_portfolio_only_syn.txt"), "w") as f:
        f.write("\n".join(str(c) for c in sorted(only_syn)))
    print(f"Saved full diff lists to tools/_diff_portfolio_only_{{uc,syn}}.txt")


if __name__ == "__main__":
    main()
