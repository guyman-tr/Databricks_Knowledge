-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Credit
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_credit
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_credit (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_credit SET TBLPROPERTIES (
    'comment' = 'Complete financial ledger spanning eToro''s entire history (2007 to present) - UNION ALL of History.ActiveCredit (current data) and 77 dbo.Credit_YYYY/YYYYQN archive tables - the canonical full-history credit view used by account statements, compliance reports, billing, customer data portability, and back-office reconciliation across 177 procedures. Source: etoro.History.Credit on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md).'
);

ALTER TABLE main.general.bronze_etoro_history_credit SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Credit',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN CreditID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN CID through StocksOrderID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MirrorEquity COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MirrorDividendID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MoveMoneyReasonID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN BSLRealFunds COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN OriginalPositionID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN SubCreditTypeID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN PartitionCol COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN DepositRollbackID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN InterestMonthlyID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN CreditID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN CID through ManagerID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN Credit, Payment COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN Description, Occurred, WithdrawProcessingID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MirrorID through StocksOrderID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MirrorEquity, MirrorDividendID, MoveMoneyReasonID, BSLRealFunds COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN OriginalPositionID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN SubCreditTypeID, PartitionCol, DepositRollbackID, InterestMonthlyID COMMENT '(no description in upstream wiki) (Tier 1 - upstream wiki, etoro.History.Credit)';

