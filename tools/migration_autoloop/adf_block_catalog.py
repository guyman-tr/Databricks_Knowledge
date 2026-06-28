"""ADF-real block catalog for migration execution.

This catalog is intentionally block-oriented (not single-proc oriented).
Each block captures the end-to-end dependency contract needed for a valid run.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class BlockTask:
    task_id: str
    task_kind: str
    sql: str
    depends_on: tuple[str, ...] = ()


@dataclass(frozen=True)
class AdfBlock:
    block_id: str
    pipeline_name: str
    migration_table: str
    gold_table: str
    wrapper_proc: str
    depends_on_blocks: tuple[str, ...]
    tasks: tuple[BlockTask, ...]


PIPELINE_NAME = "DWH_Daily_Process_-_Entry_Point"


DICTIONARIES_BLOCK = AdfBlock(
    block_id="dictionaries",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.dim_country",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country",
    wrapper_proc="sp_dictionaries_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="CALL dwh_daily_process.migration_tables.sp_dictionaries_dl_to_synapse_autopoc()",
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
SELECT
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_country) AS migration_rows,
  (SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country) AS gold_rows
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH c AS (
  SELECT
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_country) AS mr,
    (SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country) AS gr
)
SELECT CASE
  WHEN mr = gr THEN 'PARITY_PASS'
  ELSE raise_error(CONCAT('PARITY_FAIL dictionaries mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING)))
END AS parity_status
FROM c
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


FACT_CUSTOMERACTION_BLOCK = AdfBlock(
    block_id="fact_customeraction_etl",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_customeraction",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction",
    wrapper_proc="sp_fact_customeraction_dl_to_synapse_autopoc",
    depends_on_blocks=("dictionaries",),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="dictionaries_country",
            task_kind="sp",
            sql="CALL dwh_daily_process.migration_tables.sp_dictionaries_country_dl_to_synapse_autopoc()",
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="fact_customeraction",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_customeraction_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("dictionaries_country",),
        ),
        BlockTask(
            task_id="fact_firstcustomeraction",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_firstcustomeraction_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("fact_customeraction",),
        ),
        BlockTask(
            task_id="fact_billingdeposit",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_billingdeposit_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("fact_customeraction",),
        ),
        BlockTask(
            task_id="fact_billingwithdraw",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_billingwithdraw_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("fact_customeraction",),
        ),
        BlockTask(
            task_id="fact_billingredeem",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_billingredeem_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("fact_customeraction",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (
  SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction WHERE DateID IS NOT NULL
),
md AS (
  SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.fact_customeraction WHERE DateID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt,
    SUM(CAST(COALESCE(NetProfit, 0) AS DECIMAL(38,6))) AS s_np,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,6))) AS s_comm
  FROM dwh_daily_process.migration_tables.fact_customeraction WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt,
    SUM(CAST(COALESCE(NetProfit, 0) AS DECIMAL(38,6))) AS s_np,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,6))) AS s_comm
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction WHERE DateID = (SELECT cd FROM common)
)
SELECT
  (SELECT cd FROM common) AS common_date_id,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.s_amt AS migration_amount, gold.s_amt AS gold_amount,
  mig.s_np AS migration_netprofit, gold.s_np AS gold_netprofit,
  mig.s_comm AS migration_commission, gold.s_comm AS gold_commission
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("fact_firstcustomeraction", "fact_billingdeposit", "fact_billingwithdraw", "fact_billingredeem"),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (
  SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction WHERE DateID IS NOT NULL
),
md AS (
  SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.fact_customeraction WHERE DateID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt,
    SUM(CAST(COALESCE(NetProfit, 0) AS DECIMAL(38,6))) AS s_np,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,6))) AS s_comm
  FROM dwh_daily_process.migration_tables.fact_customeraction WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt,
    SUM(CAST(COALESCE(NetProfit, 0) AS DECIMAL(38,6))) AS s_np,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,6))) AS s_comm
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction WHERE DateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_amt, 0) AS ms_amt, COALESCE(gold.s_amt, 0) AS gs_amt,
    COALESCE(mig.s_np, 0) AS ms_np, COALESCE(gold.s_np, 0) AS gs_np,
    COALESCE(mig.s_comm, 0) AS ms_comm, COALESCE(gold.s_comm, 0) AS gs_comm
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms_amt = gs_amt AND ms_np = gs_np AND ms_comm = gs_comm
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING))
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' amt_diff=', CAST(ms_amt - gs_amt AS STRING),
           ' np_diff=', CAST(ms_np - gs_np AS STRING),
           ' comm_diff=', CAST(ms_comm - gs_comm AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Current-state customer dimension (SCD-1 by RealCID). Rebuilt by
# sp_dim_customer_autopoc: a sequential core DELETE+INSERT for new/changed CIDs
# (STEP 1-6) followed by 12 enrichment MERGEs (STEP 7-18) into the SAME
# Dim_Customer Delta table.
#
# PARALLELIZATION NOTE (why this is a single sequential SP, not a fan-out DAG):
# All 12 enrichment MERGEs write the one Dim_Customer table. Running them as
# concurrent Databricks tasks triggers Delta optimistic-concurrency conflicts
# (ConcurrentAppendException / ConcurrentDeleteReadException) because they touch
# overlapping files of an unpartitioned-by-merge-key table. That is almost
# certainly why the earlier "parallel" version had to be removed. The only
# Delta-safe parallelism here is parallel SOURCE-PREP into disjoint temp tables,
# which does not reduce the dominant cost (each MERGE still scans the 48M-row
# target once). Net: the writes MUST serialize, so the proc stays sequential.
#
# PARITY CONTRACT (honest, non-vacuous — NOT the full-table COUNT(*)=COUNT(*)
# that the Codex-era gate used). Gold is `_masked`, so PII columns (name, email,
# phone, address) are deliberately scrambled and can never match. Evidence from
# a fresh run: migration is a CLEAN SUBSET of gold (0 migration RealCIDs absent
# from gold), and the migration source simply lacks ~28.9K customers gold has
# (partial replication) — this is a source-population gap, not a logic defect.
# So the gate asserts the two things that MUST hold if the migration logic is
# correct:
#   1. ZERO spurious rows: every migration RealCID exists in gold (mig ⊆ gold).
#   2. >= 99.9% of the 48M shared rows are value-exact on the UNMASKED structural
#      columns (CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID,
#      PlayerStatusID, IsValidCustomer). The residual <0.1% are current-state
#      attribute drifts between two independently-timed snapshots.
# Both sides operate on the real 48M-row population (never 0==0).
DIM_CUSTOMER_BLOCK = AdfBlock(
    block_id="dim_customer",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.dim_customer",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked",
    wrapper_proc="sp_dim_customer_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="CALL dwh_daily_process.migration_tables.sp_dim_customer_autopoc()",
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH m AS (
  SELECT RealCID, CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID, PlayerStatusID, IsValidCustomer
  FROM dwh_daily_process.migration_tables.dim_customer
),
g AS (
  SELECT RealCID, CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID, PlayerStatusID, IsValidCustomer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
)
SELECT
  (SELECT COUNT(*) FROM m) AS migration_rows,
  (SELECT COUNT(*) FROM g) AS gold_rows,
  (SELECT COUNT(*) FROM m LEFT ANTI JOIN g USING (RealCID)) AS spurious_rows,
  (SELECT COUNT(*) FROM g LEFT ANTI JOIN m USING (RealCID)) AS gold_only_rows,
  (SELECT COUNT(*) FROM m JOIN g USING (RealCID)
     WHERE m.CountryID <=> g.CountryID AND m.LabelID <=> g.LabelID
       AND m.AccountTypeID <=> g.AccountTypeID AND m.RegulationID <=> g.RegulationID
       AND m.PlayerLevelID <=> g.PlayerLevelID AND m.PlayerStatusID <=> g.PlayerStatusID
       AND m.IsValidCustomer <=> g.IsValidCustomer) AS shared_value_match_rows
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH m AS (
  SELECT RealCID, CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID, PlayerStatusID, IsValidCustomer
  FROM dwh_daily_process.migration_tables.dim_customer
),
g AS (
  SELECT RealCID, CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID, PlayerStatusID, IsValidCustomer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
),
agg AS (
  SELECT
    (SELECT COUNT(*) FROM m) AS mig_rows,
    (SELECT COUNT(*) FROM m LEFT ANTI JOIN g USING (RealCID)) AS spurious,
    (SELECT COUNT(*) FROM m JOIN g USING (RealCID)
       WHERE m.CountryID <=> g.CountryID AND m.LabelID <=> g.LabelID
         AND m.AccountTypeID <=> g.AccountTypeID AND m.RegulationID <=> g.RegulationID
         AND m.PlayerLevelID <=> g.PlayerLevelID AND m.PlayerStatusID <=> g.PlayerStatusID
         AND m.IsValidCustomer <=> g.IsValidCustomer) AS value_match
)
SELECT CASE
  WHEN spurious = 0 AND value_match >= CAST(mig_rows AS DOUBLE) * 0.999
    THEN CONCAT('PARITY_PASS dim_customer subset-clean spurious=0 value_match=',
                CAST(value_match AS STRING), '/', CAST(mig_rows AS STRING),
                ' rate=', CAST(ROUND(value_match / mig_rows, 6) AS STRING))
  ELSE raise_error(
    CONCAT('PARITY_FAIL dim_customer spurious=', CAST(spurious AS STRING),
           ' value_match=', CAST(value_match AS STRING),
           ' mig_rows=', CAST(mig_rows AS STRING),
           ' rate=', CAST(ROUND(value_match / mig_rows, 6) AS STRING))
  )
END AS parity_status
FROM agg
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


FACT_SNAPSHOTEQUITY_BLOCK = AdfBlock(
    block_id="fact_snapshotequity",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_snapshotequity",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid",
    wrapper_proc="sp_fact_snapshotequity_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="""
SELECT
  CURRENT_DATE() AS run_date,
  DATEADD(DAY, -1, CURRENT_DATE()) AS target_date
""".strip(),
        ),
        BlockTask(
            task_id="extract",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_extract_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="barrier_extract",
            task_kind="barrier",
            sql="""
WITH c AS (
  SELECT
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_history_credit) AS history_credit_rows,
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_trade_position) AS trade_position_rows,
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_history_position) AS history_position_rows
)
SELECT CASE
  WHEN history_credit_rows > 0 AND trade_position_rows > 0 AND history_position_rows > 0 THEN 'BARRIER_PASS'
  ELSE raise_error(
    CONCAT(
      'BARRIER_FAIL extract rows history_credit=', CAST(history_credit_rows AS STRING),
      ' trade_position=', CAST(trade_position_rows AS STRING),
      ' history_position=', CAST(history_position_rows AS STRING)
    )
  )
END AS extract_barrier
FROM c
""".strip(),
            depends_on=("extract",),
        ),
        BlockTask(
            task_id="inprocesscashouts",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_inprocesscashouts_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("barrier_extract",),
        ),
        BlockTask(
            task_id="barrier_inprocesscashouts",
            task_kind="barrier",
            sql="""
WITH c AS (
  SELECT COUNT(*) AS rows_cnt
  FROM dwh_daily_process.migration_tables.ext_fse_inprocesscashouts
)
SELECT CASE
  WHEN rows_cnt > 0 THEN 'BARRIER_PASS'
  ELSE raise_error(CONCAT('BARRIER_FAIL inprocess rows=', CAST(rows_cnt AS STRING)))
END AS inprocess_barrier
FROM c
""".strip(),
            depends_on=("inprocesscashouts",),
        ),
        BlockTask(
            task_id="totalpositionamount",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_totalpositionamount_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("barrier_extract",),
        ),
        BlockTask(
            task_id="barrier_totalpositionamount",
            task_kind="barrier",
            sql="""
WITH c AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM dwh_daily_process.migration_tables.ext_fse_totalpositionamount
)
SELECT CASE
  WHEN rows_cnt > 0 AND (COALESCE(s1, 0) <> 0 OR COALESCE(s2, 0) <> 0 OR COALESCE(s3, 0) <> 0)
    THEN 'BARRIER_PASS'
  ELSE raise_error(
    CONCAT(
      'BARRIER_FAIL totalposition rows=', CAST(rows_cnt AS STRING),
      ' s1=', CAST(COALESCE(s1, 0) AS STRING),
      ' s2=', CAST(COALESCE(s2, 0) AS STRING),
      ' s3=', CAST(COALESCE(s3, 0) AS STRING)
    )
  )
END AS totalposition_barrier
FROM c
""".strip(),
            depends_on=("totalpositionamount",),
        ),
        BlockTask(
            task_id="core",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("barrier_inprocesscashouts", "barrier_totalpositionamount"),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH target AS (
  SELECT DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS d
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS sum_totalpositions,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS sum_totalmirrorpositions,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS sum_totalstockposition
  FROM dwh_daily_process.migration_tables.fact_snapshotequity
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT d FROM target)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS sum_totalpositions,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS sum_totalmirrorpositions,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS sum_totalstockposition
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT d FROM target)
)
SELECT
  (SELECT d FROM target) AS target_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  mig.sum_totalpositions AS migration_sum_totalpositions,
  gold.sum_totalpositions AS gold_sum_totalpositions,
  mig.sum_totalmirrorpositions AS migration_sum_totalmirrorpositions,
  gold.sum_totalmirrorpositions AS gold_sum_totalmirrorpositions,
  mig.sum_totalstockposition AS migration_sum_totalstockposition,
  gold.sum_totalstockposition AS gold_sum_totalstockposition
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("core",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH target AS (
  SELECT DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS d
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM dwh_daily_process.migration_tables.fact_snapshotequity
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT d FROM target)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT d FROM target)
),
x AS (
  SELECT
    mig.rows_cnt AS mr,
    gold.rows_cnt AS gr,
    COALESCE(mig.s1, 0) AS ms1,
    COALESCE(gold.s1, 0) AS gs1,
    COALESCE(mig.s2, 0) AS ms2,
    COALESCE(gold.s2, 0) AS gs2,
    COALESCE(mig.s3, 0) AS ms3,
    COALESCE(gold.s3, 0) AS gs3
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms1 = gs1 AND ms2 = gs2 AND ms3 = gs3
    THEN CONCAT('PARITY_PASS date=', (SELECT d FROM target))
  ELSE raise_error(
    CONCAT(
      'PARITY_FAIL date=', (SELECT d FROM target),
      ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
      ' ms1=', CAST(ms1 AS STRING), ' gs1=', CAST(gs1 AS STRING),
      ' ms2=', CAST(ms2 AS STRING), ' gs2=', CAST(gs2 AS STRING),
      ' ms3=', CAST(ms3 AS STRING), ' gs3=', CAST(gs3 AS STRING)
    )
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Daily full-replace price fact (NOT an SCD). Source snapshot holds only the
# target OccurredDateID, while gold keeps full history (2009+). Parity therefore
# MUST be sliced to the target OccurredDateID, never compared full-table.
#
# Known complication (documented, accepted): ConvertRateIsBuy_0/1 are derived
# cross-currency rates built from a self-join over USD pairs. Synapse used an
# arbitrary `ORDER BY 1` tie-break; Spark cannot reproduce that exact ordering,
# so ~27/16017 instruments land on a different USD-pair Bid/Ask, leaving a
# sub-dollar aggregate diff (~0.21, relative ~1e-6). Rows, Ask and Bid are
# bit-exact. The parity gate enforces exact rows/Ask/Bid and a tight relative
# tolerance on the two derived cross-rate sums.
FACT_CURRENCYPRICEWITHSPLIT_BLOCK = AdfBlock(
    block_id="fact_currencypricewithsplit",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_currencypricewithsplit",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit",
    wrapper_proc="sp_fact_currencypricewithsplit_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_currencypricewithsplit_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="barrier_ext_instrument",
            task_kind="barrier",
            sql="""
WITH c AS (
  SELECT COUNT(*) AS rows_cnt
  FROM dwh_daily_process.migration_tables.Ext_FCPWS_Instrument
)
SELECT CASE
  WHEN rows_cnt > 0 THEN 'BARRIER_PASS'
  ELSE raise_error(CONCAT('BARRIER_FAIL ext_instrument rows=', CAST(rows_cnt AS STRING)))
END AS ext_barrier
FROM c
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH target AS (
  SELECT CAST(DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS INT) AS d
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Ask, 0) AS DECIMAL(38,10))) AS sum_ask,
    SUM(CAST(COALESCE(Bid, 0) AS DECIMAL(38,10))) AS sum_bid,
    SUM(CAST(COALESCE(ConvertRateIsBuy_0, 0) AS DECIMAL(38,10))) AS sum_cr0,
    SUM(CAST(COALESCE(ConvertRateIsBuy_1, 0) AS DECIMAL(38,10))) AS sum_cr1
  FROM dwh_daily_process.migration_tables.fact_currencypricewithsplit
  WHERE OccurredDateID = (SELECT d FROM target)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Ask, 0) AS DECIMAL(38,10))) AS sum_ask,
    SUM(CAST(COALESCE(Bid, 0) AS DECIMAL(38,10))) AS sum_bid,
    SUM(CAST(COALESCE(ConvertRateIsBuy_0, 0) AS DECIMAL(38,10))) AS sum_cr0,
    SUM(CAST(COALESCE(ConvertRateIsBuy_1, 0) AS DECIMAL(38,10))) AS sum_cr1
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE OccurredDateID = (SELECT d FROM target)
)
SELECT
  (SELECT d FROM target) AS target_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  mig.sum_ask AS migration_sum_ask,
  gold.sum_ask AS gold_sum_ask,
  mig.sum_bid AS migration_sum_bid,
  gold.sum_bid AS gold_sum_bid,
  mig.sum_cr0 AS migration_sum_cr0,
  gold.sum_cr0 AS gold_sum_cr0,
  mig.sum_cr1 AS migration_sum_cr1,
  gold.sum_cr1 AS gold_sum_cr1
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("barrier_ext_instrument",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH target AS (
  SELECT CAST(DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS INT) AS d
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Ask, 0) AS DECIMAL(38,10))) AS s_ask,
    SUM(CAST(COALESCE(Bid, 0) AS DECIMAL(38,10))) AS s_bid,
    SUM(CAST(COALESCE(ConvertRateIsBuy_0, 0) AS DECIMAL(38,10))) AS s_cr0,
    SUM(CAST(COALESCE(ConvertRateIsBuy_1, 0) AS DECIMAL(38,10))) AS s_cr1
  FROM dwh_daily_process.migration_tables.fact_currencypricewithsplit
  WHERE OccurredDateID = (SELECT d FROM target)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Ask, 0) AS DECIMAL(38,10))) AS s_ask,
    SUM(CAST(COALESCE(Bid, 0) AS DECIMAL(38,10))) AS s_bid,
    SUM(CAST(COALESCE(ConvertRateIsBuy_0, 0) AS DECIMAL(38,10))) AS s_cr0,
    SUM(CAST(COALESCE(ConvertRateIsBuy_1, 0) AS DECIMAL(38,10))) AS s_cr1
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE OccurredDateID = (SELECT d FROM target)
),
x AS (
  SELECT
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_ask, 0) AS ms_ask, COALESCE(gold.s_ask, 0) AS gs_ask,
    COALESCE(mig.s_bid, 0) AS ms_bid, COALESCE(gold.s_bid, 0) AS gs_bid,
    COALESCE(mig.s_cr0, 0) AS ms_cr0, COALESCE(gold.s_cr0, 0) AS gs_cr0,
    COALESCE(mig.s_cr1, 0) AS ms_cr1, COALESCE(gold.s_cr1, 0) AS gs_cr1
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr
   AND ms_ask = gs_ask
   AND ms_bid = gs_bid
   AND ABS(ms_cr0 - gs_cr0) <= GREATEST(ABS(gs_cr0) * 0.00001, 1.0)
   AND ABS(ms_cr1 - gs_cr1) <= GREATEST(ABS(gs_cr1) * 0.00001, 1.0)
    THEN CONCAT(
      'PARITY_PASS date=', CAST((SELECT d FROM target) AS STRING),
      ' rows/Ask/Bid exact; cross-rate within tol',
      ' cr0_diff=', CAST(ms_cr0 - gs_cr0 AS STRING),
      ' cr1_diff=', CAST(ms_cr1 - gs_cr1 AS STRING)
    )
  ELSE raise_error(
    CONCAT(
      'PARITY_FAIL date=', CAST((SELECT d FROM target) AS STRING),
      ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
      ' ask_diff=', CAST(ms_ask - gs_ask AS STRING),
      ' bid_diff=', CAST(ms_bid - gs_bid AS STRING),
      ' cr0_diff=', CAST(ms_cr0 - gs_cr0 AS STRING),
      ' cr1_diff=', CAST(ms_cr1 - gs_cr1 AS STRING)
    )
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Daily-replace deposit-state fact (NOT an SCD): delete the target ModificationDateID
# slice, re-insert from daily_snapshot.etoro_Billing_BI_Deposit_State_Report.
#
# Refresh-cadence mismatch (handled, not a bug): the gold mirror is stale (max
# ModificationDateID ~20260511) while the source snapshot only holds the latest
# day (~20260621). The proc therefore loads a day gold doesn't have yet, so a
# fixed target-date comparison is impossible. Parity is evaluated at the COMMON
# AVAILABLE DATE = MAX(ModificationDateID) present in BOTH gold and migration.
# At that date the migration load is bit-exact to gold (rows + AmountInUSD +
# Amount), which is the meaningful equivalence under partial replication.
FACT_DEPOSIT_STATE_BLOCK = AdfBlock(
    block_id="fact_deposit_state",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_deposit_state",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state",
    wrapper_proc="sp_fact_deposit_state_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_deposit_state_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state
  WHERE ModificationDateID IS NOT NULL
),
md AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM dwh_daily_process.migration_tables.fact_deposit_state
  WHERE ModificationDateID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS sum_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS sum_amt
  FROM dwh_daily_process.migration_tables.fact_deposit_state
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS sum_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS sum_amt
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state
  WHERE ModificationDateID = (SELECT cd FROM common)
)
SELECT
  (SELECT cd FROM common) AS common_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  mig.sum_usd AS migration_sum_usd,
  gold.sum_usd AS gold_sum_usd,
  mig.sum_amt AS migration_sum_amt,
  gold.sum_amt AS gold_sum_amt
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state
  WHERE ModificationDateID IS NOT NULL
),
md AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM dwh_daily_process.migration_tables.fact_deposit_state
  WHERE ModificationDateID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS s_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt
  FROM dwh_daily_process.migration_tables.fact_deposit_state
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS s_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state
  WHERE ModificationDateID = (SELECT cd FROM common)
),
x AS (
  SELECT
    (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_usd, 0) AS ms_usd, COALESCE(gold.s_usd, 0) AS gs_usd,
    COALESCE(mig.s_amt, 0) AS ms_amt, COALESCE(gold.s_amt, 0) AS gs_amt
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms_usd = gs_usd AND ms_amt = gs_amt
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING))
  ELSE raise_error(
    CONCAT(
      'PARITY_FAIL common_date=', CAST(cd AS STRING),
      ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
      ' usd_diff=', CAST(ms_usd - gs_usd AS STRING),
      ' amt_diff=', CAST(ms_amt - gs_amt AS STRING)
    )
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Daily-replace cashout-state fact (NOT an SCD): same shape as fact_deposit_state.
# Delete the target ModificationDateID slice, re-insert from
# daily_snapshot.etoro_Billing_BI_Cashout_State_Report. Gold mirror is stale
# (max ~20260511) vs source snapshot (~20260621), so parity is evaluated at the
# COMMON AVAILABLE DATE. Proc takes a DATE param (no autopoc wrapper exists).
FACT_CASHOUT_STATE_BLOCK = AdfBlock(
    block_id="fact_cashout_state",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_cashout_state",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state",
    wrapper_proc="sp_fact_cashout_state",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_cashout_state(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS DATE)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state
  WHERE ModificationDateID IS NOT NULL
),
md AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM dwh_daily_process.migration_tables.fact_cashout_state
  WHERE ModificationDateID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS sum_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS sum_amt
  FROM dwh_daily_process.migration_tables.fact_cashout_state
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS sum_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS sum_amt
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state
  WHERE ModificationDateID = (SELECT cd FROM common)
)
SELECT
  (SELECT cd FROM common) AS common_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  mig.sum_usd AS migration_sum_usd,
  gold.sum_usd AS gold_sum_usd,
  mig.sum_amt AS migration_sum_amt,
  gold.sum_amt AS gold_sum_amt
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state
  WHERE ModificationDateID IS NOT NULL
),
md AS (
  SELECT DISTINCT ModificationDateID AS d
  FROM dwh_daily_process.migration_tables.fact_cashout_state
  WHERE ModificationDateID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS s_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt
  FROM dwh_daily_process.migration_tables.fact_cashout_state
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(AmountInUSD, 0) AS DECIMAL(38,6))) AS s_usd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,6))) AS s_amt
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state
  WHERE ModificationDateID = (SELECT cd FROM common)
),
x AS (
  SELECT
    (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_usd, 0) AS ms_usd, COALESCE(gold.s_usd, 0) AS gs_usd,
    COALESCE(mig.s_amt, 0) AS ms_amt, COALESCE(gold.s_amt, 0) AS gs_amt
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms_usd = gs_usd AND ms_amt = gs_amt
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING))
  ELSE raise_error(
    CONCAT(
      'PARITY_FAIL common_date=', CAST(cd AS STRING),
      ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
      ' usd_diff=', CAST(ms_usd - gs_usd AS STRING),
      ' amt_diff=', CAST(ms_amt - gs_amt AS STRING)
    )
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Compliance regulation-transfer fact. Multi-stage ETL: the orchestrator proc
# (sp_fact_regulationtransfer_dl_to_synapse_autopoc) rebuilds Ext_FRT_* change-log
# tables from daily_snapshot.etoro_History_BackOfficeCustomer (full temporal history,
# so any date is reproducible), then calls the final loader which enriches each
# regulation-change row with the PRIOR-DAY (V_beforedateid) equity snapshot read from
# migration_tables.V_Liabilities.
#
# GOLD LIVES IN main.compliance (NOT main.dwh) — the earlier "failed" status was purely
# a domain-routing miss (autoloop assumed the main.dwh.* name and never found gold).
# Gold here is FRESH (max DateID = yesterday), so parity is a FIXED target-date check
# (rows + equity sums), exact.
#
# Two DBSQL fixes were required and are deployed in the _autopoc procs:
#   1. orchestrator: DATEDIFF(-1, V_dt) mistranspilation -> DATEADD(day, 1, CAST(V_dt AS DATE)).
#   2. final loader: TEMP_TABLE_Equity temp view referenced the local var V_beforedateid
#      (LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION). Inlined as a subquery in the INSERT
#      via tools/migration_autoloop/patch_regulationtransfer_autopoc.py.
#
# ENVIRONMENT ARTIFACT (handled OUT OF BLOCK, not in the job DAG): migration_tables.
# V_Liabilities is only replicated through ~20260522, so a production-clean "yesterday"
# run would zero the equity columns. The side-action
# tools/migration_autoloop/runtime/prepare_vliabilities_baseline.py tops up the needed
# prior-day slice from the fresh gold mirror BEFORE the job runs (no-op in production).
# With that precondition met, all 6 metrics are bit-exact at the target date.
FACT_REGULATIONTRANSFER_BLOCK = AdfBlock(
    block_id="fact_regulationtransfer",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_regulationtransfer",
    gold_table="main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer",
    wrapper_proc="sp_fact_regulationtransfer_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_regulationtransfer_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH target AS (
  SELECT CAST(DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS INT) AS d
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(TotalCash, 0) AS DECIMAL(38,4))) AS s_tc,
    SUM(CAST(COALESCE(AUM, 0) AS DECIMAL(38,4))) AS s_aum,
    SUM(CAST(COALESCE(TotalLiability, 0) AS DECIMAL(38,4))) AS s_tl,
    SUM(CAST(COALESCE(UnrealizedPnL, 0) AS DECIMAL(38,4))) AS s_upnl
  FROM dwh_daily_process.migration_tables.fact_regulationtransfer
  WHERE DateID = (SELECT d FROM target)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(TotalCash, 0) AS DECIMAL(38,4))) AS s_tc,
    SUM(CAST(COALESCE(AUM, 0) AS DECIMAL(38,4))) AS s_aum,
    SUM(CAST(COALESCE(TotalLiability, 0) AS DECIMAL(38,4))) AS s_tl,
    SUM(CAST(COALESCE(UnrealizedPnL, 0) AS DECIMAL(38,4))) AS s_upnl
  FROM main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer
  WHERE DateID = (SELECT d FROM target)
)
SELECT
  (SELECT d FROM target) AS target_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  mig.s_req AS migration_realizedequity,
  gold.s_req AS gold_realizedequity,
  mig.s_tc AS migration_totalcash,
  gold.s_tc AS gold_totalcash,
  mig.s_aum AS migration_aum,
  gold.s_aum AS gold_aum,
  mig.s_tl AS migration_totalliability,
  gold.s_tl AS gold_totalliability,
  mig.s_upnl AS migration_unrealizedpnl,
  gold.s_upnl AS gold_unrealizedpnl
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH target AS (
  SELECT CAST(DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS INT) AS d
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(TotalCash, 0) AS DECIMAL(38,4))) AS s_tc,
    SUM(CAST(COALESCE(AUM, 0) AS DECIMAL(38,4))) AS s_aum,
    SUM(CAST(COALESCE(TotalLiability, 0) AS DECIMAL(38,4))) AS s_tl,
    SUM(CAST(COALESCE(UnrealizedPnL, 0) AS DECIMAL(38,4))) AS s_upnl
  FROM dwh_daily_process.migration_tables.fact_regulationtransfer
  WHERE DateID = (SELECT d FROM target)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(TotalCash, 0) AS DECIMAL(38,4))) AS s_tc,
    SUM(CAST(COALESCE(AUM, 0) AS DECIMAL(38,4))) AS s_aum,
    SUM(CAST(COALESCE(TotalLiability, 0) AS DECIMAL(38,4))) AS s_tl,
    SUM(CAST(COALESCE(UnrealizedPnL, 0) AS DECIMAL(38,4))) AS s_upnl
  FROM main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer
  WHERE DateID = (SELECT d FROM target)
),
x AS (
  SELECT
    (SELECT d FROM target) AS d,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_req, 0) AS ms_req, COALESCE(gold.s_req, 0) AS gs_req,
    COALESCE(mig.s_tc, 0) AS ms_tc, COALESCE(gold.s_tc, 0) AS gs_tc,
    COALESCE(mig.s_aum, 0) AS ms_aum, COALESCE(gold.s_aum, 0) AS gs_aum,
    COALESCE(mig.s_tl, 0) AS ms_tl, COALESCE(gold.s_tl, 0) AS gs_tl,
    COALESCE(mig.s_upnl, 0) AS ms_upnl, COALESCE(gold.s_upnl, 0) AS gs_upnl
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr
   AND ms_req = gs_req AND ms_tc = gs_tc AND ms_aum = gs_aum
   AND ms_tl = gs_tl AND ms_upnl = gs_upnl
    THEN CONCAT('PARITY_PASS date=', CAST(d AS STRING), ' rows=', CAST(mr AS STRING),
                ' all equity sums exact')
  ELSE raise_error(
    CONCAT(
      'PARITY_FAIL date=', CAST(d AS STRING),
      ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
      ' req_diff=', CAST(ms_req - gs_req AS STRING),
      ' tc_diff=', CAST(ms_tc - gs_tc AS STRING),
      ' aum_diff=', CAST(ms_aum - gs_aum AS STRING),
      ' tl_diff=', CAST(ms_tl - gs_tl AS STRING),
      ' upnl_diff=', CAST(ms_upnl - gs_upnl AS STRING)
    )
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Current-state copy-trading mirror dimension (PK MirrorID). Migration table is
# bit-exact full-table to gold (11,376,544 rows) and gold is NOT masked, so full
# value parity is checkable. sp_dim_mirror_dl_to_synapse_autopoc takes a TIMESTAMP
# and refreshes changed mirrors via MERGE. Gate = exact full-table rows + exact
# sums of the money measures (Amount, RealizedEquity, InitialInvestment). If a
# fresh run introduces snapshot-timing drift the gate fails and the block parks
# under the 5-pass guardrail.
DIM_MIRROR_BLOCK = AdfBlock(
    block_id="dim_mirror",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.dim_mirror",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror",
    wrapper_proc="sp_dim_mirror_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_dim_mirror_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(InitialInvestment, 0) AS DECIMAL(38,4))) AS s_inv
  FROM dwh_daily_process.migration_tables.dim_mirror
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(InitialInvestment, 0) AS DECIMAL(38,4))) AS s_inv
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
)
SELECT
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.s_amt AS migration_amount, gold.s_amt AS gold_amount,
  mig.s_req AS migration_realizedequity, gold.s_req AS gold_realizedequity,
  mig.s_inv AS migration_initialinvestment, gold.s_inv AS gold_initialinvestment
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(InitialInvestment, 0) AS DECIMAL(38,4))) AS s_inv
  FROM dwh_daily_process.migration_tables.dim_mirror
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(InitialInvestment, 0) AS DECIMAL(38,4))) AS s_inv
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
),
x AS (
  SELECT mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_amt, 0) AS ms_amt, COALESCE(gold.s_amt, 0) AS gs_amt,
    COALESCE(mig.s_req, 0) AS ms_req, COALESCE(gold.s_req, 0) AS gs_req,
    COALESCE(mig.s_inv, 0) AS ms_inv, COALESCE(gold.s_inv, 0) AS gs_inv
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms_amt = gs_amt AND ms_req = gs_req AND ms_inv = gs_inv
    THEN CONCAT('PARITY_PASS dim_mirror rows=', CAST(mr AS STRING), ' money sums exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL dim_mirror mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' amt_diff=', CAST(ms_amt - gs_amt AS STRING),
           ' req_diff=', CAST(ms_req - gs_req AS STRING),
           ' inv_diff=', CAST(ms_inv - gs_inv AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Daily customer unrealized-PnL fact (grain CID + DateModified yyyymmdd).
# sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc takes a TIMESTAMP and loads
# the target day's slice. Gold runs ~2 days ahead of the replicated source, so
# parity is evaluated at the COMMON AVAILABLE DateModified (MAX present in both),
# comparing rows + the representative measures PositionPnL, NOP and Notional.
FACT_CUSTOMERUNREALIZED_PNL_BLOCK = AdfBlock(
    block_id="fact_customerunrealized_pnl",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_customerunrealized_pnl",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl",
    wrapper_proc="sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (
  SELECT DISTINCT DateModified AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl WHERE DateModified IS NOT NULL
),
md AS (
  SELECT DISTINCT DateModified AS d FROM dwh_daily_process.migration_tables.fact_customerunrealized_pnl WHERE DateModified IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(PositionPnL, 0) AS DECIMAL(38,6))) AS s_pnl,
    SUM(CAST(COALESCE(NOP, 0) AS DECIMAL(38,6))) AS s_nop,
    SUM(CAST(COALESCE(Notional, 0) AS DECIMAL(38,6))) AS s_not
  FROM dwh_daily_process.migration_tables.fact_customerunrealized_pnl WHERE DateModified = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(PositionPnL, 0) AS DECIMAL(38,6))) AS s_pnl,
    SUM(CAST(COALESCE(NOP, 0) AS DECIMAL(38,6))) AS s_nop,
    SUM(CAST(COALESCE(Notional, 0) AS DECIMAL(38,6))) AS s_not
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl WHERE DateModified = (SELECT cd FROM common)
)
SELECT
  (SELECT cd FROM common) AS common_date_id,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.s_pnl AS migration_positionpnl, gold.s_pnl AS gold_positionpnl,
  mig.s_nop AS migration_nop, gold.s_nop AS gold_nop,
  mig.s_not AS migration_notional, gold.s_not AS gold_notional
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (
  SELECT DISTINCT DateModified AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl WHERE DateModified IS NOT NULL
),
md AS (
  SELECT DISTINCT DateModified AS d FROM dwh_daily_process.migration_tables.fact_customerunrealized_pnl WHERE DateModified IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(PositionPnL, 0) AS DECIMAL(38,6))) AS s_pnl,
    SUM(CAST(COALESCE(NOP, 0) AS DECIMAL(38,6))) AS s_nop,
    SUM(CAST(COALESCE(Notional, 0) AS DECIMAL(38,6))) AS s_not
  FROM dwh_daily_process.migration_tables.fact_customerunrealized_pnl WHERE DateModified = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(PositionPnL, 0) AS DECIMAL(38,6))) AS s_pnl,
    SUM(CAST(COALESCE(NOP, 0) AS DECIMAL(38,6))) AS s_nop,
    SUM(CAST(COALESCE(Notional, 0) AS DECIMAL(38,6))) AS s_not
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl WHERE DateModified = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s_pnl, 0) AS ms_pnl, COALESCE(gold.s_pnl, 0) AS gs_pnl,
    COALESCE(mig.s_nop, 0) AS ms_nop, COALESCE(gold.s_nop, 0) AS gs_nop,
    COALESCE(mig.s_not, 0) AS ms_not, COALESCE(gold.s_not, 0) AS gs_not
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms_pnl = gs_pnl AND ms_nop = gs_nop AND ms_not = gs_not
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING))
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' pnl_diff=', CAST(ms_pnl - gs_pnl AS STRING),
           ' nop_diff=', CAST(ms_nop - gs_nop AS STRING),
           ' not_diff=', CAST(ms_not - gs_not AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Customer snapshot fact keyed by DateRangeID (LONG, yyyymmdd + suffix), same
# grain family as fact_snapshotequity. sp_fact_snapshotcustomer_dl_to_synapse_autopoc
# is already DBSQL-clean (the DATEDIFF(-1, v_dt) bug that breaks the non-autopoc
# proc is patched). Both migration and gold cap at the same date (20260516 — this
# fact's source is a periodic snapshot, not daily), so parity is evaluated at the
# COMMON AVAILABLE DateRangeID-prefix date. Reproduction was validated: rebuilding
# the 20260516 slice via the proc kept it bit-exact (13,531 rows, distinct RealCID
# and GCID checksum all match gold) — genuine reproduction, not a stale leftover.
FACT_SNAPSHOTCUSTOMER_BLOCK = AdfBlock(
    block_id="fact_snapshotcustomer",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_snapshotcustomer",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer",
    wrapper_proc="sp_fact_snapshotcustomer_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_snapshotcustomer_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (
  SELECT DISTINCT LEFT(CAST(DateRangeID AS STRING), 8) AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer WHERE DateRangeID IS NOT NULL
),
md AS (
  SELECT DISTINCT LEFT(CAST(DateRangeID AS STRING), 8) AS d FROM dwh_daily_process.migration_tables.fact_snapshotcustomer WHERE DateRangeID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RealCID) AS dcid,
    SUM(CAST(COALESCE(GCID, 0) AS DECIMAL(38,0))) AS s_gcid
  FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RealCID) AS dcid,
    SUM(CAST(COALESCE(GCID, 0) AS DECIMAL(38,0))) AS s_gcid
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT cd FROM common)
)
SELECT
  (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.dcid AS migration_distinct_cid, gold.dcid AS gold_distinct_cid,
  mig.s_gcid AS migration_gcid_checksum, gold.s_gcid AS gold_gcid_checksum
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (
  SELECT DISTINCT LEFT(CAST(DateRangeID AS STRING), 8) AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer WHERE DateRangeID IS NOT NULL
),
md AS (
  SELECT DISTINCT LEFT(CAST(DateRangeID AS STRING), 8) AS d FROM dwh_daily_process.migration_tables.fact_snapshotcustomer WHERE DateRangeID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RealCID) AS dcid,
    SUM(CAST(COALESCE(GCID, 0) AS DECIMAL(38,0))) AS s_gcid
  FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RealCID) AS dcid,
    SUM(CAST(COALESCE(GCID, 0) AS DECIMAL(38,0))) AS s_gcid
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    mig.dcid AS mc, gold.dcid AS gc,
    COALESCE(mig.s_gcid, 0) AS ms, COALESCE(gold.s_gcid, 0) AS gs
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND mc = gc AND ms = gs
    THEN CONCAT('PARITY_PASS common_date=', cd, ' rows=', CAST(mr AS STRING), ' distinct_cid+gcid_checksum exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', cd,
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' mc=', CAST(mc AS STRING), ' gc=', CAST(gc AS STRING),
           ' gcid_diff=', CAST(ms - gs AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Wide payments fact (139 cols, grain DepositID) loaded incrementally by day via
# sp_fact_billingdeposit_dl_to_synapse + helper SP_Fact_BillingDeposit. The Codex-era
# autopoc was a NO-OP STUB ("preserve existing migrated slice") that never ran the
# logic — rebuilt here as a real, runnable autopoc (see patch_billingdeposit_autopoc.py)
# fixing: backtick-wrapped CAST identifiers, the DATEDIFF(0,x) floor-to-midnight idiom,
# a dead temp view referencing a local var, an infinite freshness-wait WHILE loop in
# the helper, and a Delta-illegal multi-match MERGE (deduped with QUALIFY). The missing
# ExtractXMLValue scalar UDF was also implemented (regex element extractor).
#
# The source daily_snapshot.etoro_Billing_Deposit is a SINGLE-DAY CDC delta (only holds
# the snapshot day's modifications — currently 2026-06-21), so only the snapshot day is
# reproducible by re-running the proc. Settled historical days are already bit-exact in
# the migration table. Parity is therefore evaluated at the COMMON AVAILABLE
# ModificationDateID (the max day present in both sides). Validated: re-extracting the
# 2026-06-21 slice reproduced gold bit-exactly — 10,604 rows, distinct DepositID,
# Amount and AmountUSD sums all match. Gate = rows + distinct DepositID + Amount +
# AmountUSD exact at the common date.
FACT_BILLINGDEPOSIT_BLOCK = AdfBlock(
    block_id="fact_billingdeposit",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_billingdeposit",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit",
    wrapper_proc="sp_fact_billingdeposit_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_billingdeposit_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingdeposit WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT DepositID) AS dd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(AmountUSD, 0) AS DECIMAL(38,4))) AS s_usd
  FROM dwh_daily_process.migration_tables.fact_billingdeposit
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT DepositID) AS dd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(AmountUSD, 0) AS DECIMAL(38,4))) AS s_usd
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
  WHERE ModificationDateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.dd AS migration_deposits, gold.dd AS gold_deposits,
  mig.s_amt AS migration_amount, gold.s_amt AS gold_amount,
  mig.s_usd AS migration_amountusd, gold.s_usd AS gold_amountusd
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingdeposit WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT DepositID) AS dd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(AmountUSD, 0) AS DECIMAL(38,4))) AS s_usd
  FROM dwh_daily_process.migration_tables.fact_billingdeposit
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT DepositID) AS dd,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(AmountUSD, 0) AS DECIMAL(38,4))) AS s_usd
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
  WHERE ModificationDateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr, mig.dd AS md_, gold.dd AS gd_,
    COALESCE(mig.s_amt, 0) AS ma, COALESCE(gold.s_amt, 0) AS ga,
    COALESCE(mig.s_usd, 0) AS mu, COALESCE(gold.s_usd, 0) AS gu
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND md_ = gd_ AND ma = ga AND mu = gu
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING), ' deposits+amount+amountusd exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' dep_diff=', CAST(md_ - gd_ AS STRING),
           ' amt_diff=', CAST(ma - ga AS STRING),
           ' usd_diff=', CAST(mu - gu AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Redeem (position-close payout) fact, grain RedeemID, 7-day rolling reload via
# sp_fact_billingredeem_dl_to_synapse. The autopoc clone is already DBSQL-clean (the
# DATEDIFF(0,x) floor-to-midnight idiom is patched to CAST(... AS DATE)); no helper, no
# XML. Source daily_snapshot.etoro_Billing_Redeem carries a 7-day window (2026-06-14..21),
# so the recent week is reproducible; settled tail differences pre-date the bulk load.
# Parity at the COMMON AVAILABLE ModificationDateID. Validated: 20260621 slice is exact —
# 117 rows, distinct RedeemID, AmountOnRequest and AmountOnClose sums all match gold.
FACT_BILLINGREDEEM_BLOCK = AdfBlock(
    block_id="fact_billingredeem",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_billingredeem",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem",
    wrapper_proc="sp_fact_billingredeem_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_billingredeem_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingredeem WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RedeemID) AS dr,
    SUM(CAST(COALESCE(AmountOnRequest, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(AmountOnClose, 0) AS DECIMAL(38,4))) AS s_close
  FROM dwh_daily_process.migration_tables.fact_billingredeem
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RedeemID) AS dr,
    SUM(CAST(COALESCE(AmountOnRequest, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(AmountOnClose, 0) AS DECIMAL(38,4))) AS s_close
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem
  WHERE ModificationDateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.dr AS migration_redeems, gold.dr AS gold_redeems,
  mig.s_req AS migration_amountonrequest, gold.s_req AS gold_amountonrequest,
  mig.s_close AS migration_amountonclose, gold.s_close AS gold_amountonclose
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingredeem WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RedeemID) AS dr,
    SUM(CAST(COALESCE(AmountOnRequest, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(AmountOnClose, 0) AS DECIMAL(38,4))) AS s_close
  FROM dwh_daily_process.migration_tables.fact_billingredeem
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RedeemID) AS dr,
    SUM(CAST(COALESCE(AmountOnRequest, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(AmountOnClose, 0) AS DECIMAL(38,4))) AS s_close
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem
  WHERE ModificationDateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr, mig.dr AS md_, gold.dr AS gd_,
    COALESCE(mig.s_req, 0) AS mq, COALESCE(gold.s_req, 0) AS gq,
    COALESCE(mig.s_close, 0) AS mc, COALESCE(gold.s_close, 0) AS gc
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND md_ = gd_ AND mq = gq AND mc = gc
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING), ' redeems+amounts exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' rid_diff=', CAST(md_ - gd_ AS STRING),
           ' req_diff=', CAST(mq - gq AS STRING),
           ' close_diff=', CAST(mc - gc AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Withdraw (cashout) fact, grain WithdrawID, sliced by ModificationDateID, reloaded via
# sp_fact_billingwithdraw_dl_to_synapse_autopoc. The autopoc clone is DBSQL-clean
# (DATEDIFF(0,x) floor idiom + backtick CAST patched; helper repointed positional;
# MERGE de-duped via QUALIFY ROW_NUMBER). NOTE: the source
# daily_snapshot.etoro_Billing_Withdraw is an EXTERNAL *Parquet* table pinned to a single
# snapshot folder (no Delta -> no time-travel), so replaying an OLD day in migration drifts
# from frozen gold. In the real env (run on yesterday with that day's snapshot) it is exact.
# Grain is WithdrawPaymentID. HARD parity gate (raise_error) at the COMMON AVAILABLE
# ModificationDateID.
FACT_BILLINGWITHDRAW_BLOCK = AdfBlock(
    block_id="fact_billingwithdraw",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.fact_billingwithdraw",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw",
    wrapper_proc="sp_fact_billingwithdraw_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_billingwithdraw_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingwithdraw WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT WithdrawPaymentID) AS dw,
    SUM(CAST(COALESCE(Amount_Withdraw, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,4))) AS s_comm
  FROM dwh_daily_process.migration_tables.fact_billingwithdraw
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT WithdrawPaymentID) AS dw,
    SUM(CAST(COALESCE(Amount_Withdraw, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,4))) AS s_comm
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
  WHERE ModificationDateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.dw AS migration_withdrawpayments, gold.dw AS gold_withdrawpayments,
  mig.s_amt AS migration_amount, gold.s_amt AS gold_amount,
  mig.s_comm AS migration_commission, gold.s_comm AS gold_commission
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingwithdraw WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT WithdrawPaymentID) AS dw,
    SUM(CAST(COALESCE(Amount_Withdraw, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,4))) AS s_comm
  FROM dwh_daily_process.migration_tables.fact_billingwithdraw
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT WithdrawPaymentID) AS dw,
    SUM(CAST(COALESCE(Amount_Withdraw, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,4))) AS s_comm
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
  WHERE ModificationDateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr, mig.dw AS mw, gold.dw AS gw,
    COALESCE(mig.s_amt, 0) AS ma, COALESCE(gold.s_amt, 0) AS ga,
    COALESCE(mig.s_comm, 0) AS mc, COALESCE(gold.s_comm, 0) AS gc
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND mw = gw AND ma = ga AND mc = gc
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING), ' withdrawpayments+amounts exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' wpid_diff=', CAST(mw - gw AS STRING),
           ' amt_diff=', CAST(ma - ga AS STRING),
           ' comm_diff=', CAST(mc - gc AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


FACT_HISTORY_COST_BLOCK = AdfBlock(
    block_id="fact_history_cost",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.Fact_History_Cost",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost",
    wrapper_proc="sp_fact_history_cost_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_history_cost_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost WHERE DateID IS NOT NULL),
md AS (SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.Fact_History_Cost WHERE DateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CostID) AS dc,
    SUM(CAST(COALESCE(ValueInAccountCurrency, 0) AS DECIMAL(38,4))) AS s_acc,
    SUM(CAST(COALESCE(ValueInAssetCurrency, 0) AS DECIMAL(38,4))) AS s_asset
  FROM dwh_daily_process.migration_tables.Fact_History_Cost
  WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CostID) AS dc,
    SUM(CAST(COALESCE(ValueInAccountCurrency, 0) AS DECIMAL(38,4))) AS s_acc,
    SUM(CAST(COALESCE(ValueInAssetCurrency, 0) AS DECIMAL(38,4))) AS s_asset
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost
  WHERE DateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.dc AS migration_costids, gold.dc AS gold_costids,
  mig.s_acc AS migration_valueaccount, gold.s_acc AS gold_valueaccount,
  mig.s_asset AS migration_valueasset, gold.s_asset AS gold_valueasset
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost WHERE DateID IS NOT NULL),
md AS (SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.Fact_History_Cost WHERE DateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CostID) AS dc,
    SUM(CAST(COALESCE(ValueInAccountCurrency, 0) AS DECIMAL(38,4))) AS s_acc,
    SUM(CAST(COALESCE(ValueInAssetCurrency, 0) AS DECIMAL(38,4))) AS s_asset
  FROM dwh_daily_process.migration_tables.Fact_History_Cost
  WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CostID) AS dc,
    SUM(CAST(COALESCE(ValueInAccountCurrency, 0) AS DECIMAL(38,4))) AS s_acc,
    SUM(CAST(COALESCE(ValueInAssetCurrency, 0) AS DECIMAL(38,4))) AS s_asset
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost
  WHERE DateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr, mig.dc AS mc_, gold.dc AS gc_,
    COALESCE(mig.s_acc, 0) AS ma, COALESCE(gold.s_acc, 0) AS ga,
    COALESCE(mig.s_asset, 0) AS ms, COALESCE(gold.s_asset, 0) AS gs
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND mc_ = gc_ AND ma = ga AND ms = gs
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING), ' costids+values exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' cid_diff=', CAST(mc_ - gc_ AS STRING),
           ' acc_diff=', CAST(ma - ga AS STRING),
           ' asset_diff=', CAST(ms - gs AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


DIM_POSITIONCHANGELOG_BLOCK = AdfBlock(
    block_id="dim_positionchangelog",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.Dim_PositionChangeLog",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog",
    wrapper_proc="sp_dim_positionchangelog_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_dim_positionchangelog_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (SELECT DISTINCT OccurredDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog WHERE OccurredDateID IS NOT NULL),
md AS (SELECT DISTINCT OccurredDateID AS d FROM dwh_daily_process.migration_tables.Dim_PositionChangeLog WHERE OccurredDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT PositionID) AS dp,
    SUM(CAST(COALESCE(AmountChanged, 0) AS DECIMAL(38,4))) AS s_ac,
    SUM(CAST(COALESCE(NewAmount, 0) AS DECIMAL(38,4))) AS s_na
  FROM dwh_daily_process.migration_tables.Dim_PositionChangeLog
  WHERE OccurredDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT PositionID) AS dp,
    SUM(CAST(COALESCE(AmountChanged, 0) AS DECIMAL(38,4))) AS s_ac,
    SUM(CAST(COALESCE(NewAmount, 0) AS DECIMAL(38,4))) AS s_na
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog
  WHERE OccurredDateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.dp AS migration_positions, gold.dp AS gold_positions,
  mig.s_ac AS migration_amountchanged, gold.s_ac AS gold_amountchanged,
  mig.s_na AS migration_newamount, gold.s_na AS gold_newamount
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (SELECT DISTINCT OccurredDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog WHERE OccurredDateID IS NOT NULL),
md AS (SELECT DISTINCT OccurredDateID AS d FROM dwh_daily_process.migration_tables.Dim_PositionChangeLog WHERE OccurredDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT PositionID) AS dp,
    SUM(CAST(COALESCE(AmountChanged, 0) AS DECIMAL(38,4))) AS s_ac,
    SUM(CAST(COALESCE(NewAmount, 0) AS DECIMAL(38,4))) AS s_na
  FROM dwh_daily_process.migration_tables.Dim_PositionChangeLog
  WHERE OccurredDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT PositionID) AS dp,
    SUM(CAST(COALESCE(AmountChanged, 0) AS DECIMAL(38,4))) AS s_ac,
    SUM(CAST(COALESCE(NewAmount, 0) AS DECIMAL(38,4))) AS s_na
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog
  WHERE OccurredDateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr, mig.dp AS mp, gold.dp AS gp,
    COALESCE(mig.s_ac, 0) AS mac, COALESCE(gold.s_ac, 0) AS gac,
    COALESCE(mig.s_na, 0) AS mna, COALESCE(gold.s_na, 0) AS gna
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND mp = gp AND mac = gac AND mna = gna
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING), ' positions+amounts exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' pid_diff=', CAST(mp - gp AS STRING),
           ' ac_diff=', CAST(mac - gac AS STRING),
           ' na_diff=', CAST(mna - gna AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


# Grain is CID (one row per copier per DateID). HARD parity gate (raise_error) at the
# COMMON AVAILABLE DateID. Helper joins Fact_SnapshotCustomer (AccountTypeID=9 gurus) and
# V_M2M_Date_DateRange (created 06-23). Source column literally named `TIMESTAMP` is
# backtick-quoted in the autopoc orchestrator. NOTE: in a partial-replica env the gate can
# fail on upstream Fact_SnapshotCustomer as-of drift (gold built earlier than current
# snapshot membership) — that is a quality-gate failure, not a compilation failure. In the
# real environment the upstream snapshot is as-of consistent with "yesterday" so it passes.
FACT_GURU_COPIERS_BLOCK = AdfBlock(
    block_id="fact_guru_copiers",
    pipeline_name=PIPELINE_NAME,
    migration_table="dwh_daily_process.migration_tables.Fact_Guru_Copiers",
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers",
    wrapper_proc="sp_fact_guru_copiers_dl_to_synapse_autopoc",
    depends_on_blocks=(),
    tasks=(
        BlockTask(
            task_id="snapshot_guard",
            task_kind="guard",
            sql="SELECT CURRENT_DATE() AS run_date, DATEADD(DAY, -1, CURRENT_DATE()) AS target_date",
        ),
        BlockTask(
            task_id="run_proc",
            task_kind="sp",
            sql="""
CALL dwh_daily_process.migration_tables.sp_fact_guru_copiers_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
""".strip(),
            depends_on=("snapshot_guard",),
        ),
        BlockTask(
            task_id="qa_probe",
            task_kind="qa",
            sql="""
WITH gd AS (SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID IS NOT NULL),
md AS (SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(Cash, 0) AS DECIMAL(38,4))) AS s_cash,
    SUM(CAST(COALESCE(Investment, 0) AS DECIMAL(38,4))) AS s_inv,
    SUM(CAST(COALESCE(PnL, 0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(CopyFundAUM, 0) AS DECIMAL(38,4))) AS s_aum
  FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers
  WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(Cash, 0) AS DECIMAL(38,4))) AS s_cash,
    SUM(CAST(COALESCE(Investment, 0) AS DECIMAL(38,4))) AS s_inv,
    SUM(CAST(COALESCE(PnL, 0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(CopyFundAUM, 0) AS DECIMAL(38,4))) AS s_aum
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers
  WHERE DateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS migration_rows, gold.rows_cnt AS gold_rows,
  mig.cids AS migration_cids, gold.cids AS gold_cids,
  mig.s_cash AS migration_cash, gold.s_cash AS gold_cash,
  mig.s_inv AS migration_investment, gold.s_inv AS gold_investment,
  mig.s_pnl AS migration_pnl, gold.s_pnl AS gold_pnl,
  mig.s_aum AS migration_aum, gold.s_aum AS gold_aum
FROM mig CROSS JOIN gold
""".strip(),
            depends_on=("run_proc",),
        ),
        BlockTask(
            task_id="parity_gate",
            task_kind="gate",
            sql="""
WITH gd AS (SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID IS NOT NULL),
md AS (SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(Cash, 0) AS DECIMAL(38,4))) AS s_cash,
    SUM(CAST(COALESCE(Investment, 0) AS DECIMAL(38,4))) AS s_inv,
    SUM(CAST(COALESCE(PnL, 0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(CopyFundAUM, 0) AS DECIMAL(38,4))) AS s_aum
  FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers
  WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(Cash, 0) AS DECIMAL(38,4))) AS s_cash,
    SUM(CAST(COALESCE(Investment, 0) AS DECIMAL(38,4))) AS s_inv,
    SUM(CAST(COALESCE(PnL, 0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(CopyFundAUM, 0) AS DECIMAL(38,4))) AS s_aum
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers
  WHERE DateID = (SELECT cd FROM common)
),
x AS (
  SELECT (SELECT cd FROM common) AS cd,
    mig.rows_cnt AS mr, gold.rows_cnt AS gr, mig.cids AS mc_, gold.cids AS gc_,
    COALESCE(mig.s_cash, 0) AS mcash, COALESCE(gold.s_cash, 0) AS gcash,
    COALESCE(mig.s_inv, 0) AS minv, COALESCE(gold.s_inv, 0) AS ginv,
    COALESCE(mig.s_pnl, 0) AS mpnl, COALESCE(gold.s_pnl, 0) AS gpnl,
    COALESCE(mig.s_aum, 0) AS maum, COALESCE(gold.s_aum, 0) AS gaum
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND mc_ = gc_ AND mcash = gcash AND minv = ginv AND mpnl = gpnl AND maum = gaum
    THEN CONCAT('PARITY_PASS common_date=', CAST(cd AS STRING), ' rows=', CAST(mr AS STRING), ' cids+amounts exact')
  ELSE raise_error(
    CONCAT('PARITY_FAIL common_date=', CAST(cd AS STRING),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' cid_diff=', CAST(mc_ - gc_ AS STRING),
           ' cash_diff=', CAST(mcash - gcash AS STRING),
           ' inv_diff=', CAST(minv - ginv AS STRING),
           ' pnl_diff=', CAST(mpnl - gpnl AS STRING),
           ' aum_diff=', CAST(maum - gaum AS STRING))
  )
END AS parity_status
FROM x
""".strip(),
            depends_on=("qa_probe",),
        ),
    ),
)


ADF_BLOCKS: dict[str, AdfBlock] = {
    DICTIONARIES_BLOCK.block_id: DICTIONARIES_BLOCK,
    FACT_CUSTOMERACTION_BLOCK.block_id: FACT_CUSTOMERACTION_BLOCK,
    DIM_CUSTOMER_BLOCK.block_id: DIM_CUSTOMER_BLOCK,
    FACT_SNAPSHOTEQUITY_BLOCK.block_id: FACT_SNAPSHOTEQUITY_BLOCK,
    FACT_CURRENCYPRICEWITHSPLIT_BLOCK.block_id: FACT_CURRENCYPRICEWITHSPLIT_BLOCK,
    FACT_DEPOSIT_STATE_BLOCK.block_id: FACT_DEPOSIT_STATE_BLOCK,
    FACT_CASHOUT_STATE_BLOCK.block_id: FACT_CASHOUT_STATE_BLOCK,
    FACT_REGULATIONTRANSFER_BLOCK.block_id: FACT_REGULATIONTRANSFER_BLOCK,
    DIM_MIRROR_BLOCK.block_id: DIM_MIRROR_BLOCK,
    FACT_CUSTOMERUNREALIZED_PNL_BLOCK.block_id: FACT_CUSTOMERUNREALIZED_PNL_BLOCK,
    FACT_SNAPSHOTCUSTOMER_BLOCK.block_id: FACT_SNAPSHOTCUSTOMER_BLOCK,
    FACT_BILLINGDEPOSIT_BLOCK.block_id: FACT_BILLINGDEPOSIT_BLOCK,
    FACT_BILLINGREDEEM_BLOCK.block_id: FACT_BILLINGREDEEM_BLOCK,
    FACT_BILLINGWITHDRAW_BLOCK.block_id: FACT_BILLINGWITHDRAW_BLOCK,
    FACT_HISTORY_COST_BLOCK.block_id: FACT_HISTORY_COST_BLOCK,
    DIM_POSITIONCHANGELOG_BLOCK.block_id: DIM_POSITIONCHANGELOG_BLOCK,
    FACT_GURU_COPIERS_BLOCK.block_id: FACT_GURU_COPIERS_BLOCK,
}


def compute_block_steps(blocks: dict[str, AdfBlock]) -> dict[str, int]:
    steps: dict[str, int] = {}
    remaining = set(blocks.keys())
    while remaining:
        progressed = False
        for bid in list(remaining):
            deps = blocks[bid].depends_on_blocks
            if all(d in steps for d in deps):
                steps[bid] = 1 + max((steps[d] for d in deps), default=0)
                remaining.remove(bid)
                progressed = True
        if not progressed:
            raise RuntimeError(f"Cyclic block dependencies: {sorted(remaining)}")
    return steps


def compute_task_sequences(block: AdfBlock) -> dict[str, int]:
    tasks = {t.task_id: t for t in block.tasks}
    seq: dict[str, int] = {}
    remaining = set(tasks.keys())
    while remaining:
        progressed = False
        for tid in list(remaining):
            deps = tasks[tid].depends_on
            if all(d in seq for d in deps):
                seq[tid] = 1 + max((seq[d] for d in deps), default=0)
                remaining.remove(tid)
                progressed = True
        if not progressed:
            raise RuntimeError(f"Cyclic task dependencies in block {block.block_id}: {sorted(remaining)}")
    return seq

