-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution > 3.4B-row performance-optimized derivative of Fact_CustomerAction for fee, compensation, and detach-from-mirror actions (ActionTypeIDs 35/36/32/19), enriched with position attributes from Dim_Position and point-in-time customer attributes from Fact_SnapshotCustomer. Covers April 2008 to present (6,356 days). HASH(PositionID) distribution enables co-located JOINs with position-distributed tables. Populated daily by SP_Fact_Customer_Action_Position_Distribution with post-insert integrity validation. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_CustomerAction + DWH_dbo.Dim_Position + DWH_dbo.Fact_SnapshotCustomer via SP_Fact_Customer_Action_Position_Distribution | | **Refresh** | Daily (SB_Daily, Priority 0) - DELETE WHERE DateID=@dateID + IN'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN DateID COMMENT 'Integer date key in YYYYMMDD format. DELETE+INSERT keyed on this column. 6,356 distinct dates from April 2008 to present. Passthrough from Fact_CustomerAction.DateID. (Tier 1 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RealCID COMMENT 'Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN PositionID COMMENT 'Position identifier. Allocated by Internal.GetPositionID_Bigint. Unique per position. HASH distribution key. DWH note: for ActionTypeID=36 + CompensationReasonID IN (117,118), extracted from Description field via reverse string parsing with TRY_CAST fallback. COALESCE prefers Dim_Position. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 5 - Expert Review)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN MirrorID COMMENT 'FK to Trade.Mirror. 0/NULL = manual trade. Positive = copy-trade position. DWH note: set to 0 if action Occurred after a detach-from-mirror event (ActionTypeID=19) for the same PositionID. COALESCE from Dim_Position. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Leverage COMMENT 'Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN InstrumentID COMMENT 'Tradeable instrument pair identifier. FK to Dim_Instrument. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 - Trade.Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsBuy COMMENT '1 = Long/Buy (profit when price rises), 0 = Short/Sell. Always NULL from Fact_CustomerAction, resolved entirely from Dim_Position. NULL if no Dim_Position match. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsAirDrop COMMENT '1 = position was created via an airdrop event (crypto). ISNULL(COALESCE(dp, fca), 0) - defaults to 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Amount COMMENT 'Action amount in dollars. Passthrough from Fact_CustomerAction. Can be negative (e.g., overnight fee = -0.01). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN ActionTypeID COMMENT 'Event type classifier. Filtered to 4 values: 35 (ticket fees, ~97%), 36 (compensations with reason 56/117/118), 32 (edit stop-loss), 19 (detach from mirror). FK to Dim_ActionType. (Tier 1 - DWH_dbo.Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN CompensationReasonID COMMENT 'Compensation reason for compensation events (ActionTypeID=36). References BackOffice.CompensationReason. 0 for non-compensation events. Filtered to IN (56, 117, 118) when ActionTypeID=36. (Tier 1 - History.Credit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsFeeDividend COMMENT 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. (Tier 2 - ETL-derived from Description)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Occurred COMMENT 'UTC timestamp when the action occurred. Passthrough from Fact_CustomerAction. (Tier 1 - source-dependent)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN TicketFeeAction COMMENT 'Simplified ticket fee classification. ''Open'' = OpenTotalFees, ''Close'' = CloseTotalFees. NULL for all other action types. 3 values: Open (8%), Close (8%), NULL (84%). (Tier 2 - SP_Fact_Customer_Action_Position_Distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Description COMMENT 'Human-readable description. For ActionTypeID=35: "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". Passthrough from Fact_CustomerAction. (Tier 1 - History.Credit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN GCID COMMENT 'Global Customer ID - cross-platform identifier linking RealCID to demo and external systems. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN CountryID COMMENT 'Customer''s registered country. DEFAULT 0. FK to Dim_Country. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN LabelID COMMENT 'Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. FK to Dim_Label. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. DEFAULT -1. FK to Dim_VerificationLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN PlayerStatusID COMMENT 'Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RiskStatusID COMMENT 'Customer risk assessment status. DEFAULT 0. FK to Dim_RiskStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RiskClassificationID COMMENT 'Risk classification tier for compliance. DEFAULT 0. FK to Dim_RiskClassification. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN GuruStatusID COMMENT 'Popular Investor (Guru) program status. DEFAULT 0. FK to Dim_GuruStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RegulationID COMMENT 'Customer''s assigned regulatory jurisdiction. DEFAULT 0. FK to Dim_Regulation. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AccountStatusID COMMENT 'Account enabled/suspended status. DEFAULT 0. FK to Dim_AccountStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AccountManagerID COMMENT 'Assigned account manager (sales/retention). DEFAULT 0. FK to Dim_Manager. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN PlayerLevelID COMMENT 'Account tier: 4=demo, other values=real tiers. DEFAULT 0. FK to Dim_PlayerLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AccountTypeID COMMENT 'Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. FK to Dim_AccountType. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsDepositor COMMENT '1 if the customer has made at least one real-money deposit (FTD detected). Never reverted to 0 once set. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN SuitabilityTestStatusID COMMENT 'MiFID suitability test completion status. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN MifidCategorizationID COMMENT 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. FK to Dim_MifidCategorization. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsValidCustomer COMMENT '1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsCreditReportValidCB COMMENT '1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AffiliateID COMMENT 'Affiliate/partner who referred this customer. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 - ETL metadata)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN SettlementTypeID COMMENT 'Modern settlement classification from Dim_Position. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. DWH note: switched from FCA to Dim_Position source (2025-10-15) because FCA shows NULL on overnights. (Tier 1 - Trade.PositionTbl)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsFeeDividend SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN TicketFeeAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN Description SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RiskStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RiskClassificationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AccountStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN SuitabilityTestStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:49:53 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 76/76 succeeded
-- ====================
