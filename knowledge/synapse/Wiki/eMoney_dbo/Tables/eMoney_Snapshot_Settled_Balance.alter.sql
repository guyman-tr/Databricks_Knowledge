-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Snapshot_Settled_Balance
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance SET TBLPROPERTIES (
    'comment' = '`eMoney_Snapshot_Settled_Balance` is the daily account balance snapshot for all eToro Money accounts. **Grain**: one row per (DateID, AccountID, CurrencyBalanceISOCode) - one row per account per currency balance as of the most recent completed day (GETDATE()-1). As of 2026-04-11, the table holds 1,287,999 rows covering 1,287,453 distinct accounts across 4 currencies: EUR (832,610 rows), GBP (434,329), AUD (20,629), DKK (431). **What the table captures**: the cumulative settled balance for each account as of yesterday, broken down by transaction type category. `HolderBalance` is the all-time net settled balance (TotalMI + TotalMO); the table retains only the current day''s snapshot (TRUNCATE before INSERT), so no historical balance time series is maintained here. For historical balance history, refer to `eMoney_Calculated_Balance` (stale as of 2025-06-09) or `eMoneyClientBalance`. **Balance structure**: TotalMI (gross money-in) and TotalMO (gross money-out) are the top-level flows. Each is further decomposed...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `DateID` COMMENT 'YYYYMMDD integer representing the settled balance snapshot date (GETDATE()-1 at SP run time, e.g., 20260411). The entire table always contains only one DateID. (Tier 2 - SP_eMoney_Snapshot_Settled_Balance)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `AccountID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. DWH note: renamed from `Id` in dbo.FiatAccount. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CurrencyBalanceISOCode` COMMENT 'ISO 4217 numeric currency code for this account''s balance (978=EUR, 826=GBP, 36=AUD, 208=DKK). One row per account per currency. Distribution: EUR=64.7%, GBP=33.7%, AUD=1.6%, DKK<0.1%. (Tier 2 - SP_eMoney_Snapshot_Settled_Balance)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `HolderBalanceCurrency` COMMENT 'Text currency label for HolderBalanceCurrency (e.g., ''EUR'', ''GBP'', ''AUD''). Derived from eMoney_Currency_Instrument_Mapping_Static by CurrencyBalanceISOCode. NULL for DKK (208) - no mapping in static table. (Tier 2 - eMoney_Currency_Instrument_Mapping_Static)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `HolderBalance` COMMENT 'Cumulative net settled balance for this account as of DateID. Computed as SUM(HolderAmount) for all settled transactions (TxStatusID=2) through the snapshot date. HolderBalance = TotalMI + TotalMO. Range: -597,856.82 to +999,628.82. 733,266 rows = 0.00 (56.9%). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CountTxsHolderBalance` COMMENT 'Total count of settled transactions (TxStatusID=2) for this account contributing to HolderBalance. Includes all transaction types. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `TotalMI` COMMENT 'Gross cumulative money-in (positive HolderAmount) settled transactions. TotalMI = CardTxMI + IBANInMI + IBANOutMI + DirectDebitMI + OtherMI (non-NULL category components). All 1,287,999 rows have TotalMI populated. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CountTxsMI` COMMENT 'Count of money-in transactions contributing to TotalMI. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `TotalMO` COMMENT 'Gross cumulative money-out (negative HolderAmount) settled transactions. TotalMO = CardTxMO + IBANInMO + IBANOutMO + DirectDebitMO + OtherMO (non-NULL components, all negative). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CountTxsMO` COMMENT 'Count of money-out transactions contributing to TotalMO. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CardTxMI` COMMENT 'Cumulative money-in from debit card transactions (card credits, cashback, card reversals). NULL if account has no card MI activity (99.81% of rows). 2,423 rows non-NULL. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CardTxMO` COMMENT 'Cumulative money-out from debit card transactions (card purchases and payments, negative). NULL if account has no card MO activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANInMI` COMMENT 'Cumulative money-in from inbound IBAN transfers (bank -> eTM, SEPA received). The dominant MI channel; 1,287,158 rows non-NULL (99.9%). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANInMO` COMMENT 'Cumulative money-out from inbound IBAN transfer reversals (SEPA received payment returned to sender, negative, rare). NULL if no inbound reversals. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANOutMI` COMMENT 'Cumulative money-in from outbound IBAN transfer reversals (eTM -> bank transfers returned to account). NULL if no outbound reversals. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANOutMO` COMMENT 'Cumulative money-out from outbound IBAN transfers (eTM -> bank, SEPA sent, negative). NULL if account has never sent a bank transfer. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `DirectDebitMI` COMMENT 'Cumulative money-in from direct debit refunds or reversals (positive). NULL if no direct debit MI activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `DirectDebitMO` COMMENT 'Cumulative money-out from direct debit deductions (automated UK bank debits, negative). NULL if account has no direct debit activity (593 rows non-NULL). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `OtherMI` COMMENT 'Cumulative money-in from transaction types not covered by Card, IBAN In, IBAN Out, or Direct Debit categories. NULL if no uncategorised MI activity (11,580 rows non-NULL). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `OtherMO` COMMENT 'Cumulative money-out from uncategorised transaction types. NULL if no uncategorised MO activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxDate` COMMENT 'Reference date for the USD FX rate used in USDApprox* columns. Set to GETDATE()-1 (same business date as DateID). (Tier 2 - SP_eMoney_Snapshot_Settled_Balance)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxBalance` COMMENT 'HolderBalance converted to USD using the FX rate for USDApproxDate from Fact_CurrencyPriceWithSplit. Indicative approximation only. NULL for DKK (208) - no USD instrument mapping. (Tier 2 - Fact_CurrencyPriceWithSplit)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxTotalMI` COMMENT 'TotalMI converted to USD. NULL for DKK. Indicative; uses single-day spot rate. (Tier 2 - Fact_CurrencyPriceWithSplit)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxTotalMO` COMMENT 'TotalMO converted to USD (negative value). NULL for DKK. Indicative; uses single-day spot rate. (Tier 2 - Fact_CurrencyPriceWithSplit)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `UpdateDate` COMMENT 'Timestamp when this record was written by the SP. Set to GETDATE() at TRUNCATE+INSERT time. Reflects the SP run time, not the business event. (Tier 2 - SP_eMoney_Snapshot_Settled_Balance)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `DateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `AccountID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CurrencyBalanceISOCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `HolderBalanceCurrency` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `HolderBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CountTxsHolderBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `TotalMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CountTxsMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `TotalMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CountTxsMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CardTxMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `CardTxMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANInMI` SET TAGS ('pii' = 'direct');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANInMO` SET TAGS ('pii' = 'direct');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANOutMI` SET TAGS ('pii' = 'direct');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `IBANOutMO` SET TAGS ('pii' = 'direct');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `DirectDebitMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `DirectDebitMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `OtherMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `OtherMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxTotalMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `USDApproxTotalMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
