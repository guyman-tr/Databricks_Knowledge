-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyCommisionReport
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyCommisionReport **Schema**: BI_DB_dbo | **Object Type**: Table | **Batch**: 20 | **Generated**: 2026-04-21'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RealCID COMMENT 'Platform-internal customer ID (primary key). Sourced from BI_DB_Client_Balance_CID_Level_New.CID. Hash distribution key in temp tables.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UserName COMMENT 'Customer username from Dim_Customer.UserName as of @DateID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CountryID COMMENT 'Integer country key from Fact_SnapshotCustomer.CountryID as of @DateID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Country COMMENT 'Full country name - sourced from BI_DB_Client_Balance_CID_Level_New.Country (traces to Dim_Country.Name).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Region COMMENT 'Marketing region label - Dim_Country.MarketingRegionManualName via direct JOIN on Fact_SnapshotCustomer.CountryID. NOT geographic region - uses eToro marketing territory classification.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Manager COMMENT 'Account manager full name - Dim_Manager.FirstName + '' '' + LastName via Fact_SnapshotCustomer.AccountManagerID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Club COMMENT 'Customer club tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, etc.) as of @DateID. From BI_DB_Client_Balance_CID_Level_New.Club.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FirstDepositDate COMMENT 'Customer''s very first deposit date from Dim_Customer. Used for cohort (FTD Year) analysis in the Instrument_Agg satellite.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction label as of @DateID - from BI_DB_Client_Balance_CID_Level_New.ToRegulation (e.g., FCA, CySEC, FSA Seychelles).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Mifid COMMENT 'MiFID categorization label as of @DateID - from BI_DB_Client_Balance_CID_Level_New.MifidCategory. Values: Retail, Professional, Retail Pending, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RegulationID COMMENT 'Integer regulation key from Fact_SnapshotCustomer.RegulationID as of @DateID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN PlayerLevelID COMMENT 'Integer player level key (1=Silver, 2=Gold, 3=Platinum, 4=Demo, etc.) from Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN MifidCategorizationID COMMENT 'Integer MiFID categorization key from Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsValidCustomer COMMENT '1 if customer meets eToro''s valid customer criteria (non-demo, depositor, active) as of @DateID. From Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report validity flag for US credit bureau reporting. From Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Label COMMENT 'Customer segment label as of @DateID (e.g., ''Proprietary'', internal classification). From BI_DB_Client_Balance_CID_Level_New.Label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN PlayerStatusID COMMENT 'Integer player status key from Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN PlayerStatus COMMENT 'Player status name (Normal, Blocked, etc.) as of @DateID. From BI_DB_Client_Balance_CID_Level_New.PlayerStatus.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountStatusID COMMENT 'Integer account status key from Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountStatusName COMMENT 'Account status name from Dim_AccountStatus via LEFT JOIN.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountTypeID COMMENT 'Integer account type key (1=Personal, 2=Corporate, 14=SMSF, etc.) from Fact_SnapshotCustomer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountType COMMENT 'Account type name as of @DateID. From BI_DB_Client_Balance_CID_Level_New.AccountType.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsEtoroTradingCID COMMENT 'Flag for internal eToro trading/housekeeping accounts. From BI_DB_Client_Balance_CID_Level_New.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsGlenEagleAccount COMMENT 'Flag for Glen Eagle Securities subsidiary accounts. From BI_DB_Client_Balance_CID_Level_New.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN eToroTradingGroupUser COMMENT 'eToro trading group identifier string. From BI_DB_Client_Balance_CID_Level_New.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN US_State COMMENT 'US state/province short name for US-regulated customers - Dim_State_and_Province.ShortName via LEFT JOIN (RegionByIP_ID, CountryID=219). NULL for non-US customers.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsDLTUser COMMENT 'Distributed Ledger Technology user flag. From BI_DB_Client_Balance_CID_Level_New. Added 2024-07-30.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullDate COMMENT 'Reporting date - the @Date SP input parameter. Matches the DELETE key for idempotent reload.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN DateID COMMENT 'YYYYMMDD integer - CAST(CONVERT(CHAR(8),@Date,112) AS INT). Clustering key for date-range scans.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UpdateDate COMMENT 'GETDATE() at ETL execution time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InstrumentID COMMENT 'Instrument integer key from Dim_Instrument, propagated through revenue TVFs.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Instrument COMMENT 'Instrument name from Dim_Instrument.Name (e.g., EUR/USD, AAPL, BTC/USD).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type integer key (1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto Currencies, etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InstrumentType COMMENT 'Instrument type label from Dim_Instrument.InstrumentType.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsSettled COMMENT '1=real/settled position (customer owns underlying asset), 0=CFD. From Fact_CustomerAction/Dim_Position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsMirror COMMENT '1=copy-trading position (MirrorID>0), 0=manual trade. CASE WHEN MirrorID>0 THEN 1 ELSE 0.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsBuy COMMENT '1=long (buy) position, 0=short (sell) position. From Dim_Position.IsBuy.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsLeverage COMMENT '1 if position Leverage > 1, else 0. From Dim_Position.Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsLeverageMoreThen20 COMMENT '1 if position Leverage > 20, else 0. High-leverage flag with regulatory significance (ESMA/MiFID leverage limits).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsAirDrop COMMENT '1 for positions created via crypto airdrop distributions. From Dim_Position.IsAirDrop.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN SettlementTypeID COMMENT 'Position settlement type: CASE WHEN SettlementTypeID IS NULL THEN IsSettled ELSE SettlementTypeID END. Key values: 0=CFD, 1=Real, 5=Margin trade.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsMarginTrade COMMENT '1 if SettlementTypeID=5 (margin-funded position) in Fact_CustomerAction. Added 2025-10-23.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Commissions COMMENT 'Net commission - SUM(TotalCommission) from Function_Revenue_Commissions. Commission on opens (ActionTypeID IN 1,2,3,39) + CommissionOnClose adjustment on closes (ActionTypeID IN 4,5,6,28,40). The "net to eToro" commission figure.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissions COMMENT 'Gross full commission - SUM(TotalFullCommission) from Function_Revenue_FullCommissions. Used for MIFID regulatory revenue reporting. Includes the full spread-embedded commission without adjustments.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionOnOpen COMMENT 'Commission on position opens (ActionTypeID IN 1,2,3,39). Component of Commissions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionOnCloseAdjustment COMMENT 'Commission close adjustment - SUM(CommissionOnClose - CommissionByUnits) for close actions. Net of unit-based component on close.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionOnOpen COMMENT 'Gross full commission for open actions. Component of FullCommissions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionOnCloseAdjustment COMMENT 'Gross full commission adjustment on close - SUM(FullCommissionOnClose - FullCommissionByUnits) for close actions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionOnClose COMMENT 'Raw commission on closed positions (ActionTypeID IN 4,5,6,28,40) before unit adjustment.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedCommissionChange COMMENT 'Daily change in unrealized spread commission embedded in open positions: new positions opened on @DateID gain unrealized commission; positions closed on @DateID release it. Computed as (CommissionOnOpen for new opens) minus (CommissionByUnitsAtClose for closes on positions opened prior to @DateID).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionOnClose COMMENT 'Gross full commission on closed positions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RealizedFullCommission COMMENT 'Gross realized full commission - SUM(FullCommissionOnClose) for positions closed on @DateID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionByUnitsAtClose COMMENT '**Always NULL** - set to NULL in INSERT since 2025-07-16 overhaul. Legacy column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedCommissionNew COMMENT '**Always NULL** - legacy unrealized commission decomposition, not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedCommissionOldClosing COMMENT '**Always NULL** - legacy unrealized commission decomposition, not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RealizedCommission COMMENT '**Always NULL** - computed in intermediate temp table but explicitly set to NULL in the INSERT since 2025-07-16. Do not use.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionByUnitsAtClose COMMENT '**Always NULL** - legacy gross commission by units at close, not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedFullCommissionNew COMMENT '**Always NULL** - legacy gross unrealized decomposition, not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedFullCommissionOldClosing COMMENT '**Always NULL** - legacy gross unrealized decomposition, not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnealizedFullCommissionChange COMMENT '**Always NULL** - legacy gross unrealized change, not populated. **"Un*e*alized" is a persisted DDL typo** (missing ''r''); actual column name in the database contains the misspelling.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN VolumeOnOpen COMMENT 'USD trading volume for positions opened on @DateID - SUM(VolumeOpen) from Function_Trading_Volume.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN VolumeOnClose COMMENT 'USD trading volume for positions closed on @DateID - SUM(VolumeClose) from Function_Trading_Volume.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RollOverFee COMMENT 'Daily overnight rollover/carry fee - SUM(RolloverFee) from Function_Revenue_RolloverFee. Charged for holding leveraged positions overnight.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RollOverFee_SDRT COMMENT 'UK Stamp Duty Reserve Tax - SUM(SDRT) from Function_Revenue_SDRT. Applies to UK equity transactions. Added 2023-10-31.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN TradingFees COMMENT 'Composite trading fee total - ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0). Added 2024-02-25 as "Ticket Fee + Islamic Fee" summary.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN TicketFee COMMENT 'Per-ticket transaction fee - SUM(TicketFee) from Function_Revenue_TicketFee. Fixed fee per trade.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN TicketFeeByPercent COMMENT 'Percentage-based ticket fee - SUM(TicketFeeByPercent) from Function_Revenue_TicketFeeByPercent. Alternative percentage fee structure.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AdminFee COMMENT 'Islamic finance / administration fee - SUM(AdminFee) from Function_Revenue_AdminFee. Charged to swap-free (Islamic-compliant) accounts in lieu of rollover.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN SpotAdjustFee COMMENT 'Spot price adjustment fee - SUM(SpotAdjustFee) from Function_Revenue_SpotAdjustFee. Adjustment for real/settled position pricing.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InvestedAmountOpen COMMENT 'USD invested amount for positions opened on @DateID - SUM(InvestedAmountOpen) from Function_Trading_Volume.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CountUU COMMENT 'Count of unique customers in this grain combination - COUNT(DISTINCT CID) from Function_Trading_Volume. Typically 1 per row (grain includes RealCID), but may be >1 in aggregated contexts.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsOutlier COMMENT '**Always NULL** - not populated since 2025-07-16 SP overhaul. Was previously used to flag statistical outlier customers.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Transition COMMENT '**Always NULL** - legacy column for regulation transition tracking. Not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsGermanBaFIN COMMENT '**Always NULL** - legacy flag for German BaFin-regulated customers. Not populated (replaced by Regulation column logic).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RegulationIDPrev COMMENT '**Always NULL** - legacy tracking for previous regulation ID before a regulation change. Not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RegulationPrev COMMENT '**Always NULL** - legacy previous regulation name. Not populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsCreditReportValidCBPrev COMMENT '**Always NULL** - legacy previous credit report validity. Not populated.';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Mifid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsEtoroTradingCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsGlenEagleAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN eToroTradingGroupUser SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN US_State SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Instrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsMirror SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsLeverageMoreThen20 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsMarginTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Commissions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionOnCloseAdjustment SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionOnCloseAdjustment SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedCommissionChange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RealizedFullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CommissionByUnitsAtClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedCommissionNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedCommissionOldClosing SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RealizedCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN FullCommissionByUnitsAtClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedFullCommissionNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnrealizedFullCommissionOldClosing SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN UnealizedFullCommissionChange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN VolumeOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN VolumeOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RollOverFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RollOverFee_SDRT SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN TradingFees SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN TicketFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN TicketFeeByPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN AdminFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN SpotAdjustFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN InvestedAmountOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN CountUU SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsOutlier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN Transition SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsGermanBaFIN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RegulationIDPrev SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN RegulationPrev SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN IsCreditReportValidCBPrev SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 09:00:25 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 11
-- Statements: 156/156 succeeded
-- ====================
