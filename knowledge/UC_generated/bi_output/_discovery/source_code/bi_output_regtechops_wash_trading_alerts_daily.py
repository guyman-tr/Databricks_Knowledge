# ==========================================================================
# Source: system.access.table_lineage → Workspace API export
# Object:  main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
# Writer:  /Users/matanmo@etoro.com/market-abuse-monitor/RegTech_WashTrading_Daily_Detection
# Language: PYTHON
# Captured: 2026-05-19T14:44:14Z
# Source URL: databricks://workspace/Users/matanmo@etoro.com/market-abuse-monitor/RegTech_WashTrading_Daily_Detection
# ==========================================================================

# >>>>> writer #1 role=primary job=832857154712514 task=notebook_task_RegTech_WashTrading_Daily_Detection
# Databricks notebook source
# DBTITLE 1,RegTech Wash Trading - Daily Detection Pipeline
# MAGIC %md
# MAGIC # RegTech Wash Trading - Daily Detection Pipeline
# MAGIC
# MAGIC **Purpose:** Runs nightly to detect wash trading patterns and writes pre-computed alerts to a Delta table.  
# MAGIC **Schedule:** Daily at 04:00 UTC  
# MAGIC **Output:** `main.bi_output.bi_output_regtechops_wash_trading_alerts_daily`  
# MAGIC **Path Convention:** BI_OUTPUT/RegTechOps/wash_trading_alerts_daily  
# MAGIC **Consumer:** RegTech Market Abuse Monitor Streamlit App (reads from this table for instant loading)
# MAGIC
# MAGIC **Detection Signals:**
# MAGIC 1. **Opposing Pairs** — Same CID opens Buy + Sell on same instrument within configurable time window
# MAGIC 2. **Rapid Round-Trips** — Position opened and closed quickly with near-zero P&L
# MAGIC
# MAGIC **Exclusions:** Copy trades (ParentPositionID / MirrorID not null)

# COMMAND ----------

# DBTITLE 1,Configuration
# ─── Configuration ─────────────────────────────────────────────────────────────

ALERTS_TABLE = "main.bi_output.bi_output_regtechops_wash_trading_alerts_daily"

# Detection parameters
LOOKBACK_DAYS = 30
TIME_WINDOW_MINUTES = 60
RAPID_THRESHOLD_MINUTES = 30
PNL_THRESHOLD_PCT = 1.0
MIN_PAIRS = 3
MIN_ROUNDTRIPS = 5

# Risk scoring thresholds
HIGH_THRESHOLD = 70
MEDIUM_THRESHOLD = 40

# Register as widgets for SQL cells
dbutils.widgets.text("LOOKBACK_DAYS", str(LOOKBACK_DAYS))
dbutils.widgets.text("TIME_WINDOW_MINUTES", str(TIME_WINDOW_MINUTES))
dbutils.widgets.text("RAPID_THRESHOLD_MINUTES", str(RAPID_THRESHOLD_MINUTES))
dbutils.widgets.text("PNL_THRESHOLD_PCT", str(PNL_THRESHOLD_PCT))
dbutils.widgets.text("MIN_PAIRS", str(MIN_PAIRS))
dbutils.widgets.text("MIN_ROUNDTRIPS", str(MIN_ROUNDTRIPS))
dbutils.widgets.text("HIGH_THRESHOLD", str(HIGH_THRESHOLD))
dbutils.widgets.text("MEDIUM_THRESHOLD", str(MEDIUM_THRESHOLD))

print(f"Configuration loaded. Output table: {ALERTS_TABLE}")

# COMMAND ----------

# DBTITLE 1,Create output table if not exists
# MAGIC %sql
# MAGIC CREATE TABLE IF NOT EXISTS main.bi_output.bi_output_regtechops_wash_trading_alerts_daily (
# MAGIC     snapshot_date DATE,
# MAGIC     CID INT,
# MAGIC     InstrumentID INT,
# MAGIC     InstrumentDisplayName STRING,
# MAGIC     Symbol STRING,
# MAGIC     wash_pair_count INT,
# MAGIC     roundtrip_count INT,
# MAGIC     total_volume DECIMAL(20,4),
# MAGIC     avg_time_between_pairs DOUBLE,
# MAGIC     avg_hold_minutes DOUBLE,
# MAGIC     first_detected TIMESTAMP,
# MAGIC     last_detected TIMESTAMP,
# MAGIC     risk_score INT,
# MAGIC     risk_level STRING,
# MAGIC     detection_type STRING,
# MAGIC     alert_status STRING,
# MAGIC     assigned_to STRING,
# MAGIC     created_at TIMESTAMP,
# MAGIC     updated_at TIMESTAMP
# MAGIC )
# MAGIC USING DELTA
# MAGIC PARTITIONED BY (snapshot_date)
# MAGIC COMMENT 'Daily pre-computed wash trading alerts for RegTech Market Abuse Monitor app'
# MAGIC TBLPROPERTIES ('quality' = 'gold', 'team' = 'RegTechOps')

# COMMAND ----------

# DBTITLE 1,Delete today's snapshot (idempotent refresh)
from datetime import datetime, timezone

today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
spark.sql(f"DELETE FROM {ALERTS_TABLE} WHERE snapshot_date = '{today_str}'")
print(f"Cleared existing data for {today_str}")

# COMMAND ----------

# DBTITLE 1,Run detection and INSERT into alerts table
# MAGIC %sql
# MAGIC INSERT INTO main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
# MAGIC
# MAGIC WITH organic_positions AS (
# MAGIC     SELECT
# MAGIC         hp.PositionID,
# MAGIC         hp.CID,
# MAGIC         hp.InstrumentID,
# MAGIC         hp.IsBuy,
# MAGIC         hp.InitDateTime,
# MAGIC         hp.OpenOccurred,
# MAGIC         hp.CloseOccurred,
# MAGIC         hp.Amount,
# MAGIC         hp.NetProfit,
# MAGIC         hp.Leverage,
# MAGIC         hp.AmountInUnitsDecimal,
# MAGIC         im.InstrumentDisplayName,
# MAGIC         im.Symbol,
# MAGIC         im.InstrumentTypeID
# MAGIC     FROM main.trading.bronze_etoro_history_position_datafactory hp
# MAGIC     JOIN main.trading.bronze_etoro_trade_instrumentmetadata im
# MAGIC         ON hp.InstrumentID = im.InstrumentID
# MAGIC     WHERE hp.InitDateTime >= DATEADD(DAY, -${LOOKBACK_DAYS}, CURRENT_DATE())
# MAGIC         AND hp.ParentPositionID = 0
# MAGIC         AND hp.MirrorID = 0
# MAGIC         AND hp.Amount > 0
# MAGIC ),
# MAGIC
# MAGIC -- Signal 1: Opposing positions (Buy + Sell on same instrument within time window)
# MAGIC opposing_pairs AS (
# MAGIC     SELECT
# MAGIC         a.CID,
# MAGIC         a.InstrumentID,
# MAGIC         a.InstrumentDisplayName,
# MAGIC         a.Symbol,
# MAGIC         a.PositionID AS buy_position_id,
# MAGIC         b.PositionID AS sell_position_id,
# MAGIC         a.InitDateTime AS buy_open_time,
# MAGIC         b.InitDateTime AS sell_open_time,
# MAGIC         ABS(TIMESTAMPDIFF(MINUTE, a.InitDateTime, b.InitDateTime)) AS time_diff_minutes,
# MAGIC         a.Amount AS buy_amount,
# MAGIC         b.Amount AS sell_amount,
# MAGIC         a.NetProfit AS buy_profit,
# MAGIC         b.NetProfit AS sell_profit
# MAGIC     FROM organic_positions a
# MAGIC     JOIN organic_positions b
# MAGIC         ON a.CID = b.CID
# MAGIC         AND a.InstrumentID = b.InstrumentID
# MAGIC         AND a.IsBuy = TRUE
# MAGIC         AND b.IsBuy = FALSE
# MAGIC         AND a.PositionID < b.PositionID
# MAGIC         AND ABS(TIMESTAMPDIFF(MINUTE, a.InitDateTime, b.InitDateTime)) <= ${TIME_WINDOW_MINUTES}
# MAGIC ),
# MAGIC
# MAGIC -- Signal 2: Rapid round-trips (open + close quickly with near-zero P&L)
# MAGIC rapid_roundtrips AS (
# MAGIC     SELECT
# MAGIC         CID,
# MAGIC         InstrumentID,
# MAGIC         InstrumentDisplayName,
# MAGIC         Symbol,
# MAGIC         PositionID,
# MAGIC         InitDateTime,
# MAGIC         CloseOccurred,
# MAGIC         TIMESTAMPDIFF(MINUTE, InitDateTime, CloseOccurred) AS hold_duration_minutes,
# MAGIC         Amount,
# MAGIC         NetProfit,
# MAGIC         ABS(NetProfit / NULLIF(Amount, 0)) * 100 AS pnl_pct
# MAGIC     FROM organic_positions
# MAGIC     WHERE CloseOccurred IS NOT NULL
# MAGIC         AND TIMESTAMPDIFF(MINUTE, InitDateTime, CloseOccurred) <= ${RAPID_THRESHOLD_MINUTES}
# MAGIC         AND ABS(NetProfit / NULLIF(Amount, 0)) < ${PNL_THRESHOLD_PCT} / 100.0
# MAGIC ),
# MAGIC
# MAGIC -- Aggregate opposing pairs per CID + Instrument
# MAGIC wash_signals AS (
# MAGIC     SELECT
# MAGIC         CID,
# MAGIC         InstrumentID,
# MAGIC         MAX(InstrumentDisplayName) AS InstrumentDisplayName,
# MAGIC         MAX(Symbol) AS Symbol,
# MAGIC         COUNT(*) AS wash_pair_count,
# MAGIC         SUM(buy_amount + sell_amount) AS total_volume,
# MAGIC         AVG(time_diff_minutes) AS avg_time_between_pairs,
# MAGIC         MIN(buy_open_time) AS first_detected,
# MAGIC         MAX(GREATEST(buy_open_time, sell_open_time)) AS last_detected,
# MAGIC         AVG(ABS(buy_profit + sell_profit) / NULLIF(buy_amount + sell_amount, 0)) * 100 AS avg_pnl_pct
# MAGIC     FROM opposing_pairs
# MAGIC     GROUP BY CID, InstrumentID
# MAGIC     HAVING COUNT(*) >= ${MIN_PAIRS}
# MAGIC ),
# MAGIC
# MAGIC -- Aggregate rapid round-trips per CID + Instrument
# MAGIC roundtrip_signals AS (
# MAGIC     SELECT
# MAGIC         CID,
# MAGIC         InstrumentID,
# MAGIC         MAX(InstrumentDisplayName) AS InstrumentDisplayName,
# MAGIC         MAX(Symbol) AS Symbol,
# MAGIC         COUNT(*) AS roundtrip_count,
# MAGIC         SUM(Amount) AS roundtrip_volume,
# MAGIC         AVG(hold_duration_minutes) AS avg_hold_minutes,
# MAGIC         AVG(pnl_pct) AS avg_pnl_pct_rt
# MAGIC     FROM rapid_roundtrips
# MAGIC     GROUP BY CID, InstrumentID
# MAGIC     HAVING COUNT(*) >= ${MIN_ROUNDTRIPS}
# MAGIC ),
# MAGIC
# MAGIC -- Final combined scoring
# MAGIC scored_alerts AS (
# MAGIC     SELECT
# MAGIC         CURRENT_DATE() AS snapshot_date,
# MAGIC         COALESCE(w.CID, r.CID) AS CID,
# MAGIC         COALESCE(w.InstrumentID, r.InstrumentID) AS InstrumentID,
# MAGIC         COALESCE(w.InstrumentDisplayName, r.InstrumentDisplayName) AS InstrumentDisplayName,
# MAGIC         COALESCE(w.Symbol, r.Symbol) AS Symbol,
# MAGIC         COALESCE(w.wash_pair_count, 0) AS wash_pair_count,
# MAGIC         COALESCE(r.roundtrip_count, 0) AS roundtrip_count,
# MAGIC         CAST(COALESCE(w.total_volume, 0) + COALESCE(r.roundtrip_volume, 0) AS DECIMAL(20,4)) AS total_volume,
# MAGIC         COALESCE(w.avg_time_between_pairs, 0) AS avg_time_between_pairs,
# MAGIC         COALESCE(r.avg_hold_minutes, 0) AS avg_hold_minutes,
# MAGIC         COALESCE(w.first_detected, CAST(NULL AS TIMESTAMP)) AS first_detected,
# MAGIC         COALESCE(w.last_detected, CAST(NULL AS TIMESTAMP)) AS last_detected,
# MAGIC         CAST(LEAST(100, ROUND(
# MAGIC             LEAST(40, COALESCE(w.wash_pair_count, 0) * 8) +
# MAGIC             LEAST(35, COALESCE(r.roundtrip_count, 0) * 5) +
# MAGIC             LEAST(15, LOG2(COALESCE(w.total_volume, 0) + COALESCE(r.roundtrip_volume, 0) + 1) * 1.5) +
# MAGIC             CASE
# MAGIC                 WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 0.1 THEN 10
# MAGIC                 WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 0.5 THEN 7
# MAGIC                 WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 1.0 THEN 4
# MAGIC                 ELSE 0
# MAGIC             END
# MAGIC         )) AS INT) AS risk_score,
# MAGIC         CASE
# MAGIC             WHEN LEAST(100, ROUND(
# MAGIC                 LEAST(40, COALESCE(w.wash_pair_count, 0) * 8) +
# MAGIC                 LEAST(35, COALESCE(r.roundtrip_count, 0) * 5) +
# MAGIC                 LEAST(15, LOG2(COALESCE(w.total_volume, 0) + COALESCE(r.roundtrip_volume, 0) + 1) * 1.5) +
# MAGIC                 CASE WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 0.1 THEN 10
# MAGIC                      WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 0.5 THEN 7
# MAGIC                      WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 1.0 THEN 4 ELSE 0 END
# MAGIC             )) >= ${HIGH_THRESHOLD} THEN 'HIGH'
# MAGIC             WHEN LEAST(100, ROUND(
# MAGIC                 LEAST(40, COALESCE(w.wash_pair_count, 0) * 8) +
# MAGIC                 LEAST(35, COALESCE(r.roundtrip_count, 0) * 5) +
# MAGIC                 LEAST(15, LOG2(COALESCE(w.total_volume, 0) + COALESCE(r.roundtrip_volume, 0) + 1) * 1.5) +
# MAGIC                 CASE WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 0.1 THEN 10
# MAGIC                      WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 0.5 THEN 7
# MAGIC                      WHEN COALESCE(w.avg_pnl_pct, r.avg_pnl_pct_rt, 1) < 1.0 THEN 4 ELSE 0 END
# MAGIC             )) >= ${MEDIUM_THRESHOLD} THEN 'MEDIUM'
# MAGIC             ELSE 'LOW'
# MAGIC         END AS risk_level,
# MAGIC         CASE
# MAGIC             WHEN COALESCE(w.wash_pair_count, 0) > 0 AND COALESCE(r.roundtrip_count, 0) > 0 THEN 'Wash Trading + Round-Trip'
# MAGIC             WHEN COALESCE(w.wash_pair_count, 0) > 0 THEN 'Wash Trading'
# MAGIC             ELSE 'Rapid Round-Trip'
# MAGIC         END AS detection_type,
# MAGIC         'New' AS alert_status,
# MAGIC         CAST(NULL AS STRING) AS assigned_to,
# MAGIC         CURRENT_TIMESTAMP() AS created_at,
# MAGIC         CURRENT_TIMESTAMP() AS updated_at
# MAGIC     FROM wash_signals w
# MAGIC     FULL OUTER JOIN roundtrip_signals r
# MAGIC         ON w.CID = r.CID AND w.InstrumentID = r.InstrumentID
# MAGIC )
# MAGIC
# MAGIC SELECT
# MAGIC     snapshot_date, CID, InstrumentID, InstrumentDisplayName, Symbol,
# MAGIC     wash_pair_count, roundtrip_count, total_volume,
# MAGIC     avg_time_between_pairs, avg_hold_minutes,
# MAGIC     first_detected, last_detected,
# MAGIC     risk_score, risk_level, detection_type,
# MAGIC     alert_status, assigned_to, created_at, updated_at
# MAGIC FROM scored_alerts
# MAGIC ORDER BY risk_score DESC

# COMMAND ----------

# DBTITLE 1,Summary and logging
# ─── Summary and Exit ──────────────────────────────────────────────────────────

count = spark.sql(f"SELECT COUNT(*) as n FROM {ALERTS_TABLE} WHERE snapshot_date = '{today_str}'").collect()[0]['n']
high = spark.sql(f"SELECT COUNT(*) as n FROM {ALERTS_TABLE} WHERE snapshot_date = '{today_str}' AND risk_level = 'HIGH'").collect()[0]['n']
medium = spark.sql(f"SELECT COUNT(*) as n FROM {ALERTS_TABLE} WHERE snapshot_date = '{today_str}' AND risk_level = 'MEDIUM'").collect()[0]['n']
low = spark.sql(f"SELECT COUNT(*) as n FROM {ALERTS_TABLE} WHERE snapshot_date = '{today_str}' AND risk_level = 'LOW'").collect()[0]['n']

print(f"═══════════════════════════════════════════════")
print(f"  RegTech Wash Trading Detection - {today_str}")
print(f"═══════════════════════════════════════════════")
print(f"  Total alerts:  {count}")
print(f"  HIGH risk:     {high}")
print(f"  MEDIUM risk:   {medium}")
print(f"  LOW risk:      {low}")
print(f"═══════════════════════════════════════════════")

dbutils.notebook.exit(f"Success: {count} alerts generated for {today_str} (HIGH={high}, MEDIUM={medium}, LOW={low})")

# COMMAND ----------

# DBTITLE 1,Quick validation query
# MAGIC %sql
# MAGIC SELECT risk_level, detection_type, COUNT(*) AS alert_count, 
# MAGIC     ROUND(AVG(risk_score), 1) AS avg_score,
# MAGIC     ROUND(SUM(total_volume), 0) AS total_flagged_volume
# MAGIC FROM main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
# MAGIC WHERE snapshot_date = CURRENT_DATE()
# MAGIC GROUP BY risk_level, detection_type
# MAGIC ORDER BY avg_score DESC

