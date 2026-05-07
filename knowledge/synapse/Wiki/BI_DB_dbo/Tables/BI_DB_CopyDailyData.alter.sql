-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CopyDailyData
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CopyDailyData | Property | Value | |----------|-------| | Schema | BI_DB_dbo | | Object | BI_DB_CopyDailyData | | Type | Table | | Rows | Append-mode historical table (one batch per @date; volume grows daily) | | Distribution | ROUND_ROBIN | | Index | CLUSTERED INDEX(CID ASC) | | Production Source | DWH_dbo.Fact_SnapshotCustomer (PI + Portfolio population) | | Writer SP | BI_DB_dbo.SP_CopyDailyData | | Refresh Cadence | Daily DELETE(WHERE Date=@date) + INSERT - append-mode, preserves history | | UC Target | _Not_Migrated | | Batch | 74 | | Documented | 2026-04-23 | ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic via Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN UserName COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 - DWH_dbo.Dim_Customer via Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN ID COMMENT 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 - DWH_dbo.Dim_Customer via Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Language COMMENT 'Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. NOTE: char(500) is over-provisioned - RTRIM() before use. (Tier 1 - DWH_dbo.Dim_Language via Dictionary.Language)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Country COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - DWH_dbo.Dim_Country via Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Region COMMENT 'Geographic region grouping for Country. Used in regional reporting aggregations. (Tier 2 - DWH_dbo.Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Manager COMMENT 'Account manager display name: FirstName + '' '' + LastName from Dim_Manager. (Tier 2 - DWH_dbo.Dim_Manager)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Gender COMMENT 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 - DWH_dbo.Dim_Customer via Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN GuruStatusID COMMENT 'eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. Values: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. (Tier 1 - DWH_dbo.Dim_Customer via BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_Level COMMENT 'Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 - DWH_dbo.Dim_GuruStatus via Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN MifidCatigorization COMMENT 'Human-readable MiFID II classification label. Column name is a typo (should be MifidCategorization). MiFID II client tiers: 0=None (non-EU), 1=Retail, 2=Professional, 3=Elective Professional, 4=Retail Pending, 5=Pending. (Tier 1 - DWH_dbo.Dim_MifidCategorization via Dictionary.MifidCategorization)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Registered COMMENT 'Account registration date (renamed from Dim_Customer.RegisteredReal). Default=getdate() at registration. (Tier 1 - DWH_dbo.Dim_Customer via Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN FirstDepositDate COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 - DWH_dbo.Dim_Customer via SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Club COMMENT 'Tier display name from Dim_PlayerLevel: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - DWH_dbo.Dim_PlayerLevel via Dictionary.PlayerLevel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CopyType COMMENT 'PI category: ''Portfolio'' for AccountTypeID=9 (Copy Portfolio accounts), ''PI'' for all other active Popular Investors. (Tier 2 - derived from Fact_SnapshotCustomer.AccountTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN ProtfoilioType COMMENT 'Portfolio fund type name from Dim_FundType. Column name is a typo (should be PortfolioType). NULL for PI accounts. (Tier 2 - DWH_dbo.Dim_FundType via Dim_Fund)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN AffiliateAccount COMMENT 'Affiliate (partner) ID under which the customer was acquired (renamed from Dim_Customer.AffiliateID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 - DWH_dbo.Dim_Customer via Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Acc_RiskIndex COMMENT 'Account-level risk classification index from BI_DB_User_Segment_Snapshot as of @date. (Tier 2 - BI_DB_dbo.BI_DB_User_Segment_Snapshot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN LastNightRiskScore COMMENT 'Portfolio volatility score 1 - 10 mapped from V_Liabilities.StandardDeviation using 10-band thresholds. 0 = no V_Liabilities record or StandardDeviation is NULL. Higher score = higher portfolio volatility. (Tier 2 - DWH_dbo.V_Liabilities.StandardDeviation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN TotalEquity COMMENT 'PI''s total equity: Liabilities + ActualNWA from V_Liabilities. Represents total account value including liabilities. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CurrenyEquity COMMENT 'Current open-position equity: TotalPositionsAmount + PositionPnL. Column name is a typo (should be CurrentEquity). Different from TotalEquity - excludes cash, includes unrealized P&L. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN RealizedEquity COMMENT 'Realized equity from closed positions. Source: V_Liabilities.RealizedEquity. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN TotalPositionsAmount COMMENT 'Total invested amount across all open positions (excluding P&L). Source: V_Liabilities.TotalPositionsAmount. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Credit COMMENT 'Credit balance (bonus funds) in the account. Source: V_Liabilities.Credit. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_CopyAUM COMMENT 'Copy-trading AUM: V_Liabilities.AUM + V_Liabilities.CopyPositionPnL. Total value managed through copy relationships. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_ManualStocks COMMENT 'PI''s manually-managed stock portfolio: TotalStockManualPosition + ManualStockPositionPnL. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_ManualCrypto COMMENT 'PI''s manually-managed crypto portfolio: TotalCryptoManualPosition + ManualCryptoPositionPnL. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN InProcessCashouts COMMENT 'Pending withdrawal amounts not yet settled. Source: V_Liabilities.InProcessCashouts. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN NumOfCopiers COMMENT 'Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers. (Tier 2 - general.etoroGeneral_History_GuruCopiers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CopyAUM COMMENT 'Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers. (Tier 2 - general.etoroGeneral_History_GuruCopiers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN DateID COMMENT 'Integer date key: CONVERT(VARCHAR(8), @date, 112) - YYYYMMDD format. (Tier 2 - derived from Date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN DaysAsPI COMMENT 'Number of days since this customer first achieved PI status (GuruStatusID >= 2): DATEDIFF(DAY, MIN(FullDate), @date) from Fact_SnapshotCustomer. (Tier 2 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN commission COMMENT 'Cumulative copy commissions earned by this PI since 2011-01-01 through @date. Multi-condition formula across open, closed, and straddling positions via Dim_Position+Dim_Mirror. NOTE: not a daily delta - each row is cumulative. (Tier 2 - DWH_dbo.Dim_Position via Dim_Mirror)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN MI COMMENT 'Money In for @date: SUM(-Amount) for mirror-in flows (ActionTypeID 15=Mirror In, 17=New Mirror) from Fact_CustomerAction. (Tier 2 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN MO COMMENT 'Money Out for @date: SUM(Amount) for mirror-out flows (ActionTypeID 16=Mirror Out, 18=UnMirror) from Fact_CustomerAction. (Tier 2 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN netMI COMMENT 'Net mirror flow for @date: SUM(-Amount) for all ActionTypeID IN (15,16,17,18) from Fact_CustomerAction. Positive = net inflow, negative = net outflow. (Tier 2 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN NewMirror COMMENT 'Number of new copy-start events on @date (ActionTypeID=17) from Fact_CustomerAction. (Tier 2 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN UnMirror COMMENT 'Number of copy-stop events on @date (ActionTypeID=18) from Fact_CustomerAction. (Tier 2 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN DaysInCurrnetStatus COMMENT 'Days since the PI entered their current GuruStatus tier. Column name is a typo (should be DaysInCurrentStatus). Computed from Fact_SnapshotCustomer status-change transitions. (Tier 2 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CopyPnL COMMENT 'Copiers'' unrealized P&L attributed to this PI: ISNULL(SUM(PnL+DetachedPosInvestment+Dit_PnL), 0) from etoroGeneral_History_GuruCopiers. (Tier 2 - general.etoroGeneral_History_GuruCopiers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN LastContactDate COMMENT 'Most recent successful manager contact (phone call or email) recorded in Salesforce for this PI, where contact was by the PI''s own account manager. Sentinel: ''1900-01-01'' = no contact on record. (Tier 2 - BI_DB_dbo.BI_DB_UsageTracking_SF)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_Level_Previous COMMENT 'PI tier name (GuruStatusName) as of @date - 1 day. Used to detect tier changes. NULL if no prior-day snapshot exists. (Tier 2 - DWH_dbo.Dim_GuruStatus via DWH_dbo.Fact_SnapshotCustomer)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Language SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_Level SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN MifidCatigorization SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Registered SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CopyType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN ProtfoilioType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN AffiliateAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Acc_RiskIndex SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN LastNightRiskScore SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN TotalEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CurrenyEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_CopyAUM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_ManualStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_ManualCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN InProcessCashouts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN NumOfCopiers SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CopyAUM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN DaysAsPI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN commission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN MI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN MO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN netMI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN NewMirror SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN UnMirror SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN DaysInCurrnetStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN CopyPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN LastContactDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN PI_Level_Previous SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 08:58:19 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 11
-- Statements: 88/88 succeeded
-- ====================
