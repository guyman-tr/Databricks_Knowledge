-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CID_Daily_NWA
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CID_Daily_NWA'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Date COMMENT 'Calendar date of the NWA snapshot. SP @Date parameter. Clustered index column - always filter on this. (Tier 2 - SP_CID_Daily_NWA, @Date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN CID COMMENT 'Customer ID from V_Liabilities.CID. Only customers with ActualNWA <> 0 and valid customer status. (Tier 2 - SP_CID_Daily_NWA, V_Liabilities.CID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Label COMMENT 'Brand label name from Dim_Label.Name via Fact_SnapshotCustomer.LabelID. Values: "eToro", etc. (Tier 2 - SP_CID_Daily_NWA, Dim_Label.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Country COMMENT 'Country name from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. Full name (e.g., "Spain", "United Kingdom"). (Tier 2 - SP_CID_Daily_NWA, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Region COMMENT 'Geographic region from Dim_Country.Region. Values: "Spain", "UK", "German", "Eastern Europe", "Australia", etc. Note: some region names match country names (e.g., Spain region = "Spain"). (Tier 2 - SP_CID_Daily_NWA, Dim_Country.Region)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN AccountType COMMENT 'Account type from Dim_AccountType.Name via Fact_SnapshotCustomer.AccountTypeID. Values: "Private", "Corporate", etc. (Tier 2 - SP_CID_Daily_NWA, Dim_AccountType.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Regulation COMMENT 'Regulation name from Dim_Regulation.Name. All regulations included (not filtered to specific ones). (Tier 2 - SP_CID_Daily_NWA, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN RealizedEquity COMMENT 'Cash balance after all realized gains and losses in USD. From V_Liabilities.RealizedEquity. ISNULL default 0. (Tier 2 - SP_CID_Daily_NWA, V_Liabilities.RealizedEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN PositionPnL COMMENT 'Unrealized profit/loss on open positions in USD. From V_Liabilities.PositionPnL. ISNULL default 0. (Tier 2 - SP_CID_Daily_NWA, V_Liabilities.PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN TotalPositionsAmount COMMENT 'Total margin allocated to open positions in USD. From V_Liabilities.TotalPositionsAmount. ISNULL default 0. (Tier 2 - SP_CID_Daily_NWA, V_Liabilities.TotalPositionsAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN ActualNWA COMMENT 'Non-Withdrawable Amount in USD - trading bonuses whose principal cannot be cashed out. From V_Liabilities.ActualNWA. ISNULL default 0. Filtered: only rows where ActualNWA <> 0 are inserted. (Tier 2 - SP_CID_Daily_NWA, V_Liabilities.ActualNWA)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN BonusCredit COMMENT 'Bonus/credit balance in USD. From V_Liabilities.BonusCredit. ISNULL default 0. Not withdrawable - affects equity but not NWA. (Tier 2 - SP_CID_Daily_NWA, V_Liabilities.BonusCredit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN CreditLine COMMENT 'Total credit line amount in USD. From BI_DB_Daily_CreditLine.TotalCLAmount (LEFT JOIN). ISNULL default 0. Represents leveraged buying power extended to the customer. (Tier 2 - SP_CID_Daily_NWA, BI_DB_Daily_CreditLine.TotalCLAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). (Tier 3 - SP_CID_Daily_NWA, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN IsGermanResident COMMENT 'Flag: 1 if customer''s CountryID = 79 (Germany). Added Nov 2020 for CMR automation. (Tier 2 - SP_CID_Daily_NWA, Fact_SnapshotCustomer.CountryID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN IsGermanBaFin COMMENT 'Flag: 1 if CID exists in V_GermanBaFin for this date. German BaFin regulatory indicator. (Tier 2 - SP_CID_Daily_NWA, V_GermanBaFin)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report validity flag. Direct from Fact_SnapshotCustomer.IsCreditReportValidCB. 1 = valid for CB reporting. (Tier 2 - SP_CID_Daily_NWA, Fact_SnapshotCustomer.IsCreditReportValidCB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN MifidCategorization COMMENT 'MiFID II client categorization from Dim_MifidCategorization.Name. Values: "Retail", "Retail Pending", "Professional", etc. EU regulatory classification. (Tier 2 - SP_CID_Daily_NWA, Dim_MifidCategorization.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN PlayerLevel COMMENT 'Customer tier/level from Dim_PlayerLevel.Name. Values: "Bronze", "Silver", "Gold", "Platinum", "Diamond", etc. (Tier 2 - SP_CID_Daily_NWA, Dim_PlayerLevel.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN PlayerStatus COMMENT 'Customer account status from Dim_PlayerStatus.Name. Values: "Normal", "Block Deposit & Trading", "Deposit Blocked", "Suspended", etc. (Tier 2 - SP_CID_Daily_NWA, Dim_PlayerStatus.Name)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN ActualNWA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN BonusCredit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN CreditLine SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN IsGermanResident SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN MifidCategorization SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN PlayerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
