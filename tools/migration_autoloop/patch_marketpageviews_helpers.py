#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    create_table_sql = """
CREATE TABLE IF NOT EXISTS dwh_daily_process.migration_tables.Fact_MarketPageViews_SWITCH_SINGLE (
  RealCID BIGINT,
  MarketPageViewID BIGINT,
  InstrumentID BIGINT,
  SourceID INT,
  Occurred TIMESTAMP,
  DateID INT,
  UpdateDate TIMESTAMP
) USING DELTA
"""
    create_ext_sql = """
CREATE TABLE IF NOT EXISTS dwh_daily_process.migration_tables.Ext_MarketPageViews (
  MarketPageViewID BIGINT,
  CID BIGINT,
  Occurred TIMESTAMP,
  InstrumentID BIGINT,
  SourceID INT,
  UpdateDate TIMESTAMP
) USING DELTA
"""
    create_trackingids_sql = """
CREATE TABLE IF NOT EXISTS dwh_daily_process.migration_tables.TrackingIDs (
  Identifier STRING,
  CID BIGINT
) USING DELTA
"""
    create_helper_sql = """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_MarketPageViews_Create_SWITCH_SINGLE()
LANGUAGE SQL SQL SECURITY INVOKER
AS BEGIN
  CREATE TABLE IF NOT EXISTS dwh_daily_process.migration_tables.Fact_MarketPageViews_SWITCH_SINGLE (
    RealCID BIGINT,
    MarketPageViewID BIGINT,
    InstrumentID BIGINT,
    SourceID INT,
    Occurred TIMESTAMP,
    DateID INT,
    UpdateDate TIMESTAMP
  ) USING DELTA;
END
"""
    switch_sql = """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_MarketPageViews_SWITCH()
LANGUAGE SQL SQL SECURITY INVOKER
AS BEGIN
  SELECT 1;
END
"""

    execute_sql(w, sql_text=create_table_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    execute_sql(w, sql_text=create_ext_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    execute_sql(w, sql_text=create_trackingids_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    execute_sql(w, sql_text=create_helper_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    execute_sql(w, sql_text=switch_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print("created_or_updated=marketpageviews_helpers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
