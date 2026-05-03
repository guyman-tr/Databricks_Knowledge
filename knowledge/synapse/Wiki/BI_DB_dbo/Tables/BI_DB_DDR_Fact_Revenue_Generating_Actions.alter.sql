-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions > 3.1B-row comprehensive revenue fact table capturing 18 distinct revenue streams (spreads, rollovers, ticket fees, conversion fees, dormant fees, dividends, staking, options PFOF, and more) per customer per day, broken down by instrument type, position flags, and trade characteristics. Sourced from 16+ `Function_Revenue_*` TVFs, enriched with IBAN/recurring/CopyFund/C2P position attributes, assembled by `SP_DDR_Fact_Revenue_Generating_Actions` with daily DELETE/INSERT plus special reload strategies for Options (full history) and Staking (monthly lag). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Multiple - 16+ `Function_Revenue_*` TVFs + `Dim_Revenue_Metrics` + enrichment tables | | **Refresh** | Daily (DELETE/INSERT by DateID) + Options full reload + Staking'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN DateID COMMENT 'Date key in YYYYMMDD format. DELETE/INSERT partition key. Direct from revenue functions (except Staking: lagged one month via `DATEADD(MONTH,1,...)`). (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN Date COMMENT 'Calendar date. `@date` SP parameter for main INSERT; computed from DateID for Staking. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN RealCID COMMENT 'Customer identifier. Distribution key. From revenue functions (CID renamed to RealCID for some). (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN ActionTypeID COMMENT 'Trading action type. From `Function_Revenue_FullCommissions/Commissions.ActionTypeID` for trading fees; `ISNULL(...,-1)` - sentinel -1 for non-trading metrics. Values: 1=Open, 39=Close. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN ActionType COMMENT 'Action or revenue stream label. `Dim_ActionType.Name` for commissions; literal string for others (''Rollover'', ''SDRT'', ''CashoutFeeExclRedeem'', etc.). (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN InstrumentTypeID COMMENT 'Instrument asset class ID. Values: 1=Stocks, 2=Currencies, 3=Commodities, 4=Indices, 5=Crypto, 6=ETFs. Sentinel -1 = not applicable (account-level fees: CashoutFee, ConversionFee, DormantFee, InterestFee have no instrument). From Function_Revenue_* TVFs. (Tier 1 - Function_Revenue_FullCommissions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsSettled COMMENT '1 = real/settled asset (stocks, ETFs, crypto with actual ownership; eligible for dividends and share lending, no overnight rollover). 0 = CFD (derivative without ownership; subject to spread and rollover fees). Sentinel -1 = not applicable (account-level fees: DormantFee, ConversionFee, CashoutFee). From Function_Revenue_* TVFs via Dim_Instrument.IsSettled. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsCopy COMMENT 'Copy-trade flag. `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. C2F forced to -1. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN Metric COMMENT 'Revenue stream identifier. 18 distinct values: ''FullCommission'', ''Commission'', ''RollOverFee'', ''Dividends'', ''SDRT'', ''TicketFee'', ''TicketFeeByPercent'', ''CashoutFeeExclRedeem'', ''ConversionFee'', ''DormantFee'', ''InterestFee'', ''TransferCoinFee'', ''AdminFee'', ''SpotPriceAdjustment'', ''ShareLending'', ''CryptoToFiatFee'', ''StakingLagOneMonth'', ''Options_PFOF''. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN Amount COMMENT 'Revenue amount in USD. `SUM(fee_column)` aggregated per CID × Metric × flags group. Positive = revenue, negative possible for dividends paid out. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN CountTransactions COMMENT 'Number of transactions/positions in the group. `COUNT(RealCID)` or `SUM(CountTransactions)`; `ISNULL(...,0)`. NULL/0 for ShareLending and Staking. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IncludedInTotalRevenue COMMENT 'Revenue inclusion flag. From `Dim_Revenue_Metrics.IncludedInTotalRevenue`. 1 = counts toward total revenue, 0 = excluded (Commission, Dividends, SDRT). (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN CountAsActiveTrade COMMENT 'Active trade indicator. `CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0) = 0 THEN 1 ELSE 0 END`; `ISNULL(...,0)`. Only 1 for non-airdrop commission rows. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsBuy COMMENT 'Trade direction. `ISNULL(...,-1)`. 1=buy/long, 0=sell/short, -1=not applicable. Dividends: overridden to 1 if Amount>0, 0 if Amount<0. C2F: forced -1. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsLeveraged COMMENT 'Leverage flag. `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsFuture COMMENT 'Futures contract flag. From functions or `Dim_Instrument.IsFuture` (AdminFee/SpotAdjust). `ISNULL(...,-1)`. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsCopyFund COMMENT 'Smart Portfolio flag. `CASE WHEN BI_DB_CopyFund_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsOpenedFromIBAN COMMENT 'Position opened from eMoney IBAN flag. Set via UPDATE JOIN to `External_*_opened_from_iban_parquet`; `ISNULL(...,-1)`. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsClosedToIBAN COMMENT 'Position closed to eMoney IBAN flag. Set via UPDATE JOIN to `External_*_closed_to_iban_parquet`; `ISNULL(...,-1)`. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsRecurring COMMENT 'Recurring investment position flag. Set via UPDATE JOIN to `External_bi_db_recurringinvestment_positions_parquet`; `ISNULL(...,-1)`. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsAirDrop COMMENT 'AirDrop (free share) flag. From revenue functions; `ISNULL(...,-1)`. AirDrop positions excluded from active trade counts. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsSQF COMMENT 'Sustainable & Quality-Focused instrument flag. From functions or `Function_Instrument_Snapshot_Enriched`; `ISNULL(...,-1)`. NULL for Dividends/SDRT. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN RevenueMetricID COMMENT 'Revenue metric dictionary ID. From `Dim_Revenue_Metrics.RevenueMetricID` via Metric text match. 12=Staking, 18=Options. Enables ID-based filtering. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN RevenueMetricCategoryID COMMENT 'Revenue category ID. From `Dim_Revenue_Metrics.RevenueMetricCategoryID`. Groups metrics into categories (4=Staking, 5=Options). (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsMarginTrade COMMENT 'Margin trade flag. From revenue functions; `ISNULL(...,-1)`. Forced 0 for SDRT and Options_PFOF. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsC2P COMMENT 'Copy-to-Portfolio flag. `CASE WHEN V_C2P_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. NULL for non-position metrics. (Tier 2 - SP_DDR_Fact_Revenue_Generating_Actions)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN ActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN Metric SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN CountTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IncludedInTotalRevenue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN CountAsActiveTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsLeveraged SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsCopyFund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsOpenedFromIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsClosedToIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsSQF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN RevenueMetricID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN RevenueMetricCategoryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsMarginTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN IsC2P SET TAGS ('pii' = 'none');
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-16 08:43:40 UTC
-- TVF DDR enrichment deploy
-- Statements: 56/56 succeeded
-- ====================
