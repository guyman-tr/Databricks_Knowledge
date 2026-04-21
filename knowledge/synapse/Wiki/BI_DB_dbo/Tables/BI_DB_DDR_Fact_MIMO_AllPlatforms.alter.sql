-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms > 91.5M-row transaction-level MIMO (Money In / Money Out) fact table unifying deposits and withdrawals across all four platforms - TradingPlatform, eMoney, Options (Apex), and MoneyFarm - with first-time deposit flags at both platform and global levels. Sourced from three sub-platform MIMO tables plus `Function_MIMO_First_Deposit_All_Platforms` for cross-platform FTD reconciliation, assembled by `SP_DDR_Fact_Fact_MIMO_AllPlatforms` with daily DELETE/INSERT by DateID for TP+eMoney and full DELETE/re-INSERT for Options and MoneyFarm. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Multiple - `BI_DB_DDR_Fact_MIMO_Trading_Platform`, `BI_DB_DDR_Fact_MIMO_eMoney_Platform`, `BI_DB_DDR_Fact_MIMO_Options_Platform`, `Function_MIMO_First_Deposit_All_Platforms` | | **Refresh** | Dail'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN DateID COMMENT 'Date key in YYYYMMDD integer format. Partition/filter key for daily DELETE/INSERT (TP+eMoney). Direct passthrough from sub-platform tables. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN Date COMMENT 'Calendar date corresponding to DateID. `@date` SP input parameter. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN RealCID COMMENT 'Customer identifier. Distribution key. Passthrough from sub-platform tables. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN MIMOAction COMMENT 'Transaction direction. `''Deposit''` for money in, `''Withdraw''` for money out. Passthrough from sub-platform tables. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN OrigIdentifier COMMENT 'Type label for the source transaction ID. Values: `''TransactionID''` (eMoney deposit), `''WithdrawPaymentID''` (withdrawal), `''DepositID''` (TP deposit/MoneyFarm). Passthrough from sub-platform tables. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN TransactionID COMMENT 'Source transaction identifier. `CAST(f.TransactionID AS VARCHAR(50))` for TP/eMoney; hardcoded `0` for Options and MoneyFarm (varchar incompatibility with lake schemas). (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN AmountUSD COMMENT 'Transaction amount in USD equivalent. Passthrough from sub-platform tables. Negative values may appear for withdrawals depending on platform source. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN AmountOrigCurrency COMMENT 'Transaction amount in original currency. Passthrough from sub-platform tables. `-1` sentinel for MoneyFarm (original amount unavailable). Negative for withdrawals on TP. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN FundingTypeID COMMENT 'Payment method identifier. Passthrough from sub-platform tables. `-1` sentinel for MoneyFarm. JOIN to `DWH_dbo.Dim_FundingType` for name. `FundingTypeID = 27` triggers C2USD UPDATE for TP. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN CurrencyID COMMENT 'Currency identifier. Passthrough from sub-platform tables. `3` (GBP) hardcoded for MoneyFarm. JOIN to `DWH_dbo.Dim_Currency`. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN Currency COMMENT 'Currency ISO code. Passthrough from sub-platform tables. `''GBP''` hardcoded for MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsPlatformFTD COMMENT 'Platform-level first-time deposit flag. 1 = first deposit on this specific platform (TP, eMoney, Options, or MoneyFarm independently). Renamed from IsFTD. Updated by FTD recovery logic for DateID >= 20250901. Note: 13K bad-FTD cohort (Aug 18-20 2025 $1 FTDs) excluded via REMOVE_BAD_FTDS in Function_MIMO_First_Deposit_All_Platforms. (Tier 1 - Function_MIMO_First_Deposit_All_Platforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsInternalTransfer COMMENT 'Internal fund transfer flag. `ISNULL(f.IsInternalTransfer, 0)`. 1 = transfer between platforms (TP <-> eMoney), not an external deposit/withdrawal. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsRedeem COMMENT 'eMoney redemption flag. `ISNULL(f.IsRedeem, 0)`. 1 = eMoney balance redeemed to bank account. Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsTradeFromIBAN COMMENT 'eMoney-initiated trade flag. `ISNULL(f.IsIBANTrade, 0)`. Renamed from `IsIBANTrade` in sub-platform tables. 1 = deposit originated from eMoney IBAN. Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN MIMOPlatform COMMENT 'Platform discriminator. Values: TradingPlatform (CFD/Stocks TP), eMoney (IBAN/wallet), Options (Apex/US Options via Gatsby), MoneyFarm (UK managed investment - FTD only, no withdrawals). Options is full delete/re-insert every run due to unreliable data arrival. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsGlobalFTD COMMENT 'Cross-platform first-time deposit flag. 1 = this deposit is the customer very first across ALL platforms. A deposit can be IsPlatformFTD=1 but IsGlobalFTD=0 (if customer already deposited on another platform). Old logic (IBAN+TP union) for FTDs before 2025-09-01; new logic (Dim_Customer-driven) for on/after. Excludes bad-FTD cohort. (Tier 1 - Function_MIMO_First_Deposit_All_Platforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsCryptoToFiat COMMENT 'Crypto-to-fiat deposit flag. `ISNULL(f.IsCryptoToFiat, 0)` from sub-platform tables; additionally `UPDATE SET IsCryptoToFiat=1 WHERE FundingTypeID=27 AND MIMOPlatform=''TradingPlatform'' AND DateID >= 20250701`. Dual-source indicator. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsRecurring COMMENT 'Recurring deposit flag. `ISNULL(f.IsRecurring, 0)`. 1 = deposit made via recurring/auto-deposit feature. Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsIBANQuickTransfer COMMENT 'eMoney Internal Transfer (quick transfer) flag. MoveMoneyReasonID=6. 1 = customer used the eMoney Internal Transfer feature to move funds. Distinct from TP internal transfers (IsInternalTransfer). Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN MIMOAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN OrigIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN AmountOrigCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsPlatformFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsInternalTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsRedeem SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsTradeFromIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN MIMOPlatform SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsGlobalFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsCryptoToFiat SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN IsIBANQuickTransfer SET TAGS ('pii' = 'none');
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-16 08:41:07 UTC
-- TVF DDR enrichment deploy
-- Statements: 44/44 succeeded
-- ====================
