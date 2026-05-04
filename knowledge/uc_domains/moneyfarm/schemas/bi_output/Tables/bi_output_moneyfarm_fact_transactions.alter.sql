-- ============================================================================
-- main.bi_output.bi_output_moneyfarm_fact_transactions  —  P6 UC ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/moneyfarm/schemas/bi_output/Tables/bi_output_moneyfarm_fact_transactions.md
-- Tier source:  T1 = Confluence XP/13551468545 (V2 deposit-event HLD) for the
--               3 identity columns (event_correlation_ID, GCID, PortfolioID);
--               T4 [uc_sample] for the 4 measure/timestamp/operational columns.
-- ============================================================================

COMMENT ON TABLE main.bi_output.bi_output_moneyfarm_fact_transactions IS
'eToro-side fact of MoneyFarm portfolio-level deposits and withdrawals. Granularity: one row per source event in the sub-accounts event-hub stream (event_correlation_ID = ''{EventId UUID}_{EventType}''). ~29k events: Deposit (26.7k), Withdrawal (1.8k), Full Withdrawal (0.8k). Amount_GBP is signed (negative for withdrawals). Transaction_Date is source EventMetadata.CreatedAt UTC, NOT settlement value_date. Per-day aggregation lives in etoro_kpi_prep.v_moneyfarm_mimo; per-portfolio current state in bi_output_moneyfarm_fact_portfolio_snapshot. [Confluence/XP/13551468545]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN event_correlation_ID COMMENT
'Concatenated source event ID = ''{EventMetadata.EventId UUID}_{EventType}''. Primary key. Same EventId space as the sub-accounts EH MoneyFarm stream. [Confluence/XP/13551468545]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN GCID COMMENT
'eToro Global Customer ID at the time of the event. FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName=''Moneyfarm''). [Confluence/XP/13551468545]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN PortfolioID COMMENT
'MoneyFarm portfolio UUID v4 (8-4-4-4-12 with hyphens). FK to fact_portfolio_snapshot.PortfolioID. From event payload data.portfolioId. [Confluence/XP/13551468545]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN TransactionType COMMENT
'Direction enum. Values: Deposit (26712), Withdrawal (1815), Full Withdrawal (844). ''Full Withdrawal'' indicates portfolio-closing withdrawal (deplete to zero). [uc_sample]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN Transaction_Date COMMENT
'Source event timestamp (UTC, microsecond precision). From EventMetadata.CreatedAt. NOT the value date — for that, parse value_date from the event payload. [uc_sample]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN Amount_GBP COMMENT
'Signed GBP amount. Negative for Withdrawal/Full Withdrawal, positive for Deposit. From event_data_json $.data.amount. [uc_sample]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_transactions ALTER COLUMN UpdateDate COMMENT
'Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 12:58:09 UTC
-- Batch deploy resume: bi_output deploy batch 2
-- Statements: 8/8 succeeded
-- ====================
