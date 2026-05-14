-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Compliance_Illegal_Trades_Alerts
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Compliance_Illegal_Trades_Alerts > 259,077-row cumulative daily compliance alert log - each row captures one instance of a customer triggering a forbidden-trade or compliance-violation rule, covering 30+ active rule types from blocked-country deposits to leverage exceedances and regulation restrictions. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_SnapshotCustomer + Dim_Position + multiple DWH dims via SP_Compliance_Forbidden_Trades | | **Refresh** | Daily incremental - DELETE WHERE Date = @Date + INSERT | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED INDEX (Date ASC) | | **UC Target** | `_Not_Migrated` | | **UC Format** | - | | **UC Partitioned By** | - | | **UC Table Type** | - | | **Author** | Guy Manova (2020-07-15); actively maintained | ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Date COMMENT 'Reporting date - the @Date parameter passed to SP_Compliance_Forbidden_Trades. Clustered index key. Range: 2023-01-01 to 2026-04-11. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN AlertType COMMENT 'Compliance rule code. Values: BU1, BC3, BC4, BC7, PC1 - PC53 (subset). See section 2.1 for full inventory. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Synopsis COMMENT 'Human-readable description of the triggered rule. Hardcoded per rule in SP. E.g., ''Trade exceeded leverage restrictions'', ''Client Traded Sanctioned stock''. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN RealCID COMMENT 'Customer ID stored as VARCHAR. Actual CID value (platform-internal primary key). HASH distribution key. Use CAST(RealCID AS INT) for joins. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Country COMMENT 'Customer''s registered country name from Dim_Country.Name. Sourced via #pop. (Tier 1 - Dim_Country wiki, Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN AccountMgr COMMENT 'Customer''s assigned account manager (FirstName+LastName from Dim_Manager). May be truncated to 10 chars in older rules. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN UserName COMMENT 'Customer''s eToro platform username from Dim_Customer.UserName. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Language COMMENT 'Customer''s platform language from Dim_Language.Name via Fact_SnapshotCustomer.LanguageID. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN MifidCategorization COMMENT 'Customer''s MiFID II categorization from Dim_MifidCategorization.Name. Values: ''Retail'', ''Professional'', ''Elective professional'', ''Pending''. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Regulation COMMENT 'Customer''s regulatory jurisdiction from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. E.g., ''CySEC'', ''FCA'', ''ASIC & GAML''. (Tier 1 - Dim_Regulation wiki, Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PositionID COMMENT 'Position ID from Dim_Position.PositionID. NULL for non-position alerts (deposit/registration rules). (Tier 2 - Dim_Position wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN OpenDateID COMMENT 'Position open date as YYYYMMDD string. NULL for non-position alerts. Cast to INT/date for filtering. (Tier 2 - Dim_Position wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InvestedAmount COMMENT 'Position invested amount (from Dim_Position.Amount or Volume depending on rule). NULL for non-position alerts. Stored as varchar. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InstrumentType COMMENT 'Instrument category text label from Dim_Instrument.InstrumentType (e.g., ''Stocks'', ''Commodities'', ''Crypto Currencies''). NULL for non-position alerts. (Tier 2 - Dim_Instrument wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN IsSettled COMMENT 'Settlement flag as varchar: ''1''=Real asset, ''0''=CFD. NULL for non-position alerts. (Tier 2 - Dim_Position wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Leverage COMMENT 'Position leverage ratio as varchar (e.g., ''1'', ''5'', ''10''). NULL for non-position alerts. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN IsCopy COMMENT 'Copy-trade indicator as varchar. Derived from position MirrorID/ParentPositionID. NULL for non-position alerts. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatus COMMENT 'Customer account status at alert time from Dim_PlayerStatus.Name. E.g., ''Normal'', ''Blocked''. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatusReason COMMENT 'Reason for current player status from Dim_PlayerStatusReasons.Name. NULL if no block reason. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerSubReason COMMENT 'Sub-reason for player status from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. NULL if no sub-reason. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN VerificationLevelID COMMENT 'Customer''s KYC verification level as varchar: 0=Level 0, 1=Level 1, 2=Level 2, 3=Level 3. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN RegisteredReal COMMENT 'Real account registration date as varchar ISO format (yyyy-mm-dd). (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was inserted. (Propagation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN BlockDate COMMENT 'Date when customer''s account was most recently blocked (PlayerStatusID IN 2,4,9,13,15). NULL if never blocked. Computed from Fact_SnapshotCustomer PlayerStatus history. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN FirstDepositDate COMMENT 'Date of customer''s first deposit from Dim_Customer.FirstDepositDate. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatusReasonID COMMENT 'Integer FK for player status reason. References Dim_PlayerStatusReasons.PlayerStatusReasonID. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatusSubReasonID COMMENT 'Integer FK for player status sub-reason. References Dim_PlayerStatusSubReasons.PlayerStatusSubReasonID. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN DepositDate COMMENT 'Customer''s most recent deposit date from BI_DB_CIDFirstDates.LastDepositDate. NULL for non-deposit alerts. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN GCID COMMENT 'Global Customer ID from Dim_Customer.GCID - cross-platform identifier. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN TranID COMMENT 'Transaction/deposit ID for deposit-related alerts (e.g., BC4 uses DepositID). NULL for position-only alerts. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Occurred COMMENT 'Deposit or transaction occurred timestamp as varchar. Populated for deposit-related alerts. NULL for position-only alerts. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN AmountUSD COMMENT 'Transaction amount in USD as varchar. Populated for deposit-related alerts. NULL for position-only alerts. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN State COMMENT 'Transaction state as varchar (rule-specific context). Populated by a subset of rules only. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN CryptoName COMMENT 'Crypto asset name. Populated only for crypto-specific rules (e.g., PC33, PC36, PC44). NULL otherwise. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN CryptoID COMMENT 'Crypto asset ID. Populated only for crypto-specific rules. NULL otherwise. (Tier 3 - SP inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name from Dim_Instrument. NULL for non-position alerts. (Tier 2 - Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN UpdatedClub COMMENT 'Customer''s current Club tier name at alert time from Dim_PlayerLevel.Name. E.g., ''Silver'', ''Gold'', ''Diamond''. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InstrumentID COMMENT 'Instrument ID FK to Dim_Instrument. NULL for non-position alerts. (Tier 2 - Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN SeychellesCategorizationID COMMENT 'FSA Seychelles KYC categorization ID from External_etoro_BackOffice_Customer. 2=Advanced, other=Basic. NULL for non-FSA-Seychelles customers. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN SeychellesCategorization COMMENT '''Advanced'' (SeychellesCategorizationID=2) or ''Basic'' (all others). NULL for non-FSA-Seychelles customers. (Tier 2 - SP_Compliance_Forbidden_Trades)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN RecordID COMMENT 'Running unique record identifier per batch: max(existing RecordID) + ROW_NUMBER() per day. NULL for rows predating column addition (2025-03-09). Not a replayable sequence - re-running a date reassigns new RecordIDs. (Tier 2 - SP_Compliance_Forbidden_Trades)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN AlertType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Synopsis SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN AccountMgr SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Language SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN MifidCategorization SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN OpenDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatusReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerSubReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN RegisteredReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN BlockDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatusReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN PlayerStatusSubReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN DepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN TranID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN State SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN CryptoName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN CryptoID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN UpdatedClub SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN SeychellesCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN SeychellesCategorization SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN RecordID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:33:00 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 84/84 succeeded
-- ====================
