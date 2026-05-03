-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance > Daily ASIC/ASIC+GAML regulatory client-balance finance report - one row per customer per day showing balance decomposition (opening balance, deposits, withdrawals, closed PnL, current day balance, unrealized position delta, equity, margin, real crypto). ~230K rows per day across 2,451 dates from 2019-07-28 to 2026-04-12 (~565M total rows). Loaded by SP_ASIC_ClientBalanceFinance (Katy F, migrated from RegReportDB_Prod 2019-07-30). Regulatory file - ProcessType 4 (FinanceReportSPS), Priority 99. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_SnapshotCustomer + V_Liabilities + Fact_CustomerAction via SP_ASIC_ClientBalanceFinance | | **Refresh** | Daily (ProcessType=4 FinanceReportSPS, Priority 99). DELETE WHERE Date=@StartDate + INSERT. | | **Synapse Distribut'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN DateID COMMENT 'ETL date integer key in YYYYMMDD format. Computed as CONVERT(VARCHAR(8), @StartDate, 112). Used for date-range JOIN with DateRange tables. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: filtered to ASIC/ASIC+GAML regulated, IsCreditReportValidCB=1 population from Fact_SnapshotCustomer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Date COMMENT 'Snapshot date for this row. The @StartDate parameter value passed to the SP. One row per CID per date. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Customer COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. DWH note: passthrough from Dim_Customer.ExternalID, stored as varchar(50); in ASIC context serves as the ASIC account identifier (20-digit numeric string, e.g., "56652263734277170001"). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN PreviuosDayBalance COMMENT 'Previous day''s opening balance (closing equity from yesterday). ROUND(V_Liabilities.Liabilities - negative_liability_adjustment, 2) at DateID=@dprev_int. DDL typo: ''PreviuosDayBalance'' not ''PreviousDayBalance'' - baked into DDL and SP; all queries must use the misspelled name. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Deposit COMMENT 'Net daily inflow. Composite: SUM(Fact_CustomerAction.Amount) for deposit/credit ActionTypeIDs (7,11,12,13,35,36), minus Commission (ActionTypeID=30), plus ChargebackLoss and OtherNegative adjustments from V_Liabilities negative-balance split. Not a pure deposit event count - includes compensations and negative-equity adjustments. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Withdrawal COMMENT 'Daily cashout amount (negative sign). ROUND(SUM(-Amount) WHERE ActionTypeID=8, 2). Stored as negative value representing customer-initiated withdrawals. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN ClosedPnL COMMENT 'Realized profit/loss from closed positions on this date. ROUND(SUM(Fact_CustomerAction.NetProfit) WHERE ActionTypeID IN(4,5,6,28,40), 2). (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN CurrentDayBalance COMMENT 'Calculated closing balance: PreviuosDayBalance + Deposit + ClosedPnL. Does not include open-position floating PnL (that is captured in OpenPosition and Equity separately). (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN OpenPosition COMMENT 'Change in unrealized open-position PnL from yesterday to today. ROUND(today.PositionPnL - yesterday.PositionPnL, 2) from V_Liabilities. Positive = portfolio P&L improved; negative = deteriorated. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Equity COMMENT 'Closing total equity for the day. ROUND(V_Liabilities.Liabilities - negative_liability_adjustment, 2) at DateID=@d_int. Includes all assets (cash + open positions + crypto). (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN TotalOpenMargin COMMENT 'Total open-position margin committed (TotalPositionsAmount from V_Liabilities). Sum of all open position notional values. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN RealAssetEquity COMMENT 'Real crypto asset value. ISNULL(TotalRealCrypto,0) + ISNULL(PositionPnLCryptoReal,0) from V_Liabilities. Represents the customer''s crypto holdings plus crypto unrealized PnL. 30.4% of rows have this non-zero on 2026-04-12. (Tier 2 - SP_ASIC_ClientBalanceFinance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN CurrentLabel COMMENT 'Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = ''eToro''). DWH note: simplified via CASE WHEN Name LIKE ''%eToro%'' THEN ''eToro''; current-day snapshot. Values: eToro (99.8%), ICMarkets (0.2%), Royal-CM (<0.1%). (Tier 1 - Dictionary.Label)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN PrevLabel COMMENT 'Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = ''eToro''). DWH note: simplified via CASE WHEN Name LIKE ''%eToro%'' THEN ''eToro''; previous-day snapshot. Difference from CurrentLabel signals a label migration event. (Tier 1 - Dictionary.Label)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Country COMMENT 'ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). DWH note: passthrough from Dim_Country.Abbreviation; represents customer''s registered country at snapshot date. (Tier 1 - Dictionary.Country upstream wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN UpdateDate COMMENT 'ETL batch run timestamp. GETDATE() at SP execution time. All rows in a single SP run share the same UpdateDate. (Propagation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN RegulationName COMMENT 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. DWH note: only ASIC (DWHRegulationID=4) and ASIC & GAML (DWHRegulationID=10) appear in this table by construction. (Tier 1 - upstream wiki, Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN IsGermanBaFin COMMENT 'Legacy binary flag. 1 if customer is German (CountryID=79), registered before 2023-07-13 (BaFin crypto regulation cut-off), AND holds non-zero real crypto (LiabilitiesCryptoReal != 0 in V_Liabilities). Determined via V_GermanBaFin JOIN. As of 2026-04-12 only 1 row has value 1 - effectively obsolete. (Tier 2 - SP_ASIC_ClientBalanceFinance via V_GermanBaFin)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Customer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN PreviuosDayBalance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Deposit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Withdrawal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN ClosedPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN CurrentDayBalance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN OpenPosition SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Equity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN TotalOpenMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN RealAssetEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN CurrentLabel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN PrevLabel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN RegulationName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:25:29 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 40/40 succeeded
-- ====================
