-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ExecutionOperationType
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype ALTER COLUMN OperationTypeId COMMENT 'Primary key. Integer code identifying the trading execution operation type. Values: 0=OrderForOpen, 1=OrderForOpenInMirror, 2=OrderForClose, 3=OrderForCloseInMirror, 4=CancelDelayedOrderForOpen, 5=CancelDelayedOrderForClose, 6=CancelOrderForOpen, 7=CancelOrderForClose, 8=OrderForOpenStatusUpdateRejected, 9=OrderForCloseStatusUpdateRejected, 10=OrderForCloseStatusUpdateFilled, 11=OrderForOpenStatusUpdateFilled, 12=PositionClose, 13=PositionCloseByLimit, 14=PositionOpen, 15=OperationalOpenPosition, 16=OperationalClosePosition, 17=OperationalPositionAdjustment, 18=DirectOpenPosition, 19=DirectClosePosition, 20=OrderForCloseByLimit, 21=OrderForCloseByRate, 22=AdminOrderForOpenWithHedge, 23=AdminOrderForOpenWithoutHedge, 24=AdminPositionOpen. Renamed from `Id` in source. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype ALTER COLUMN OperationType COMMENT 'Human-readable operation type name. Passthrough from source column with same name. Uses nvarchar(max) in DWH (oversized for these short strings). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL constraint (unlike most other DWH dict tables). Does not reflect production source update time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype ALTER COLUMN OperationTypeId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype ALTER COLUMN OperationType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

