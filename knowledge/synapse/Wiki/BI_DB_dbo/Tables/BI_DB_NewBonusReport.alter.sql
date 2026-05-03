-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_NewBonusReport
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_NewBonusReport > Account manager deposit and cash-out event report. Each row represents a single deposit or cash-out (CO) transaction by a customer (RealCID), enriched with the assigned account manager, customer segmentation (country, region, desk, channel, club tier), and contact tracking (IsContacted, DaysSinceContact). 56.7M rows covering 2017-08-31 to 2026-04-11; 4.9M distinct customers; 591 account managers. Populated daily by SP_NewBonusReport (SB_Daily pipeline). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Deposit and cash-out events + customer/manager assignments (via SP_NewBonusReport) | | **Refresh** | Daily; SP_NewBonusReport, Priority 0, SB_Daily process | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED INDEX (DateID ASC); NONCLUSTERED INDEX (Date) | | *'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. NOT NULL; primary join key for all CID-based queries. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN ManagerID COMMENT 'ID of the account manager assigned to this customer. 591 distinct managers observed. (Tier 3 - inferred from naming + data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Manager COMMENT 'Full name of the assigned account manager. Denormalized from manager roster. Examples: "Farzana Begum", "Harry Blagden". (Tier 3 - inferred from naming + data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN DateID COMMENT 'Integer date key in YYYYMMDD format (e.g., 20260411 for 2026-04-11). Primary sort column (CLUSTERED INDEX). (Tier 2 - data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Date COMMENT 'Calendar date of the deposit or cash-out event. Range: 2017-08-31 to 2026-04-11. Non-clustered index enables fast date-bounded queries. (Tier 2 - data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN TotalDepositAmount COMMENT 'USD amount of the deposit event. Positive when deposit row; $0 for cash-out rows. Use WHERE TotalDepositAmount > 0 to isolate deposit events. (Tier 2 - naming + data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN TotalCoAmount COMMENT 'USD amount of the cash-out (CO) event. Positive when cash-out row; $0 for deposit rows. Large values observed ($1.37M+) for institutional-scale withdrawals. "CO" likely = Cash Out - pending confirmation. (Tier 3 - inferred; "CO" meaning unconfirmed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN IsContacted COMMENT 'Contact status flag: 1 = account manager has contacted this customer about the event; 0 = not yet contacted. 97% of rows are 0 (uncontacted) in recent data. (Tier 3 - data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Country COMMENT 'Customer country name. Denormalized from customer dimension. Examples: "United Kingdom", "Germany", "France". (Tier 2 - data evidence + Dim_Customer passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Region COMMENT 'Sales region segment. Examples: "UK", "Eastern Europe", "French", "Other EU". Denormalized from customer dimension. (Tier 2 - data evidence + Dim_Customer passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Desk COMMENT 'Sales desk assignment. Examples: "UK", "French", "Other EU". Used to route customers to appropriate sales teams. (Tier 2 - data evidence + Dim_Customer passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Channel COMMENT 'Customer acquisition channel. Examples: "SEM", "Affiliate", "Direct", "Mobile Acquisition". Denormalized from customer acquisition data. (Tier 2 - data evidence + Dim_Customer passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN SubChannel COMMENT 'Acquisition sub-channel detail. Examples: "FB" (Facebook), "Mobile CPA", "Direct Mobile", "Affiliate". (Tier 2 - data evidence + Dim_Customer passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Club COMMENT 'eToro Club membership tier at the time of the event. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Distribution (April 2026): Bronze 44%, Gold 17%, Platinum 15%, Silver 14%, Platinum Plus 12%, Diamond 2%. (Tier 2 - data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was written by SP_NewBonusReport. All rows in a batch share the same UpdateDate. (P)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN ContactByManager COMMENT 'Name of the manager who last contacted this customer. May differ from the assigned Manager. NULL when no contact has been made. (Tier 3 - inferred from naming + data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN DaysSinceContact COMMENT 'Integer days elapsed since the last manager contact with this customer. Recomputed daily by ETL. NULL when no contact has been made. (Tier 3 - inferred from naming + data)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN ManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN TotalDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN TotalCoAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN IsContacted SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Desk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN ContactByManager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN DaysSinceContact SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:06:49 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 36/36 succeeded
-- ====================
