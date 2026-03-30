-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_BillingRedeem
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Fact_BillingRedeem` records every copy-trading position redeem request on the eToro platform. A "redeem" is the act of cashing out a position - closing a copied investment and requesting the return of funds. The table captures the request state, the amounts (at request time vs. at close), the payment instrument used, and the current processing status. This table represents the withdrawal/liquidation side of eToro''s copy-trading financial flow: customers may redeem a position (convert the position value back to cash) via the cashier system. The `RedeemID` is the primary key identifying each individual redeem request. **ETL pattern**: `SP_Fact_BillingRedeem_DL_To_Synapse` uses a 7-day rolling window strategy: 1. DELETE from `Ext_FBR_Fact_BillingRedeem` (staging table) for the last 7 days by ModificationDateID 2. INSERT fresh data from `DWH_staging.etoro_Billing_Redeem` into Ext_FBR for the same window 3. DELETE from main `Fact_BillingRedeem` for the same 7-day window 4. INSERT from Ext_FBR into the ...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem SET TAGS (
    'domain' = 'billing',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (RedeemID)',
    'synapse_index' = 'CLUSTERED (ModificationDateID ASC) + NC (RedeemID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN CID COMMENT 'Customer ID. Identifies the eToro customer who initiated the redeem request. References DWH_dbo.Dim_Customer. Primary join key for customer-level redeem analytics. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RedeemID COMMENT 'Primary key for the redeem request. Distribution key (HASH). Uniquely identifies each redeem operation across the platform. Non-clustered index key for point lookups. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN PositionID COMMENT 'Trading position being redeemed. References the copy-trading position that is being closed/liquidated. BIGINT to accommodate the large position ID space. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RedeemStatusID COMMENT 'Current processing status of the redeem request. References DWH_dbo.Dim_RedeemStatus (documented in Batch 9). Tracks the lifecycle from submission through approval/rejection/processing. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RedeemReasonID COMMENT 'Reason code explaining why the redeem was initiated. References DWH_dbo.Dim_RedeemReason (documented in Batch 9). NULL when no specific reason was recorded. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN AmountOnRequest COMMENT 'Position value (in base currency) at the time the redeem request was submitted. Represents what the customer expected to receive. May differ from AmountOnClose if market moved during processing. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN AmountOnClose COMMENT 'Actual position value (in base currency) at close/settlement time. The final amount processed for the redeem. NULL if not yet settled. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN FundingID COMMENT 'Payment instrument (funding method) used for this redeem payout. References Billing.Funding. Identifies the credit card, bank account, or e-wallet that received the redeemed funds. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RequestDate COMMENT 'Datetime when the redeem request was submitted by the customer. Records the initiation time of the redeem lifecycle. No index - use ModificationDateID for range queries. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN LastModificationDate COMMENT 'Most recent datetime when this redeem record was modified. Used as the source for ModificationDateID. The ETL 7-day rolling window is based on this field. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN ModificationDateID COMMENT 'Clustered index key. Integer date in YYYYMMDD format derived from `CONVERT(INT, LastModificationDate)`. The ETL rolling 7-day window operates on this column. Use for date-range queries and partitioning in downstream systems. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to `GETDATE()` at SP execution time, not from the production source. Use for ETL freshness monitoring. (Tier 2 - SP_Fact_BillingRedeem_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RedeemID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RedeemStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RedeemReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN AmountOnRequest SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN AmountOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN RequestDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN LastModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:28:24 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 26/26 succeeded
-- ====================
