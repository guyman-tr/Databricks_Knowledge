-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.FiatAccount
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount SET TBLPROPERTIES (
    'comment' = 'eMoney_dbo.FiatAccount > ~2.06M-row eMoney fiat-account dimension. One row per fiat account opened on the eToro Money (eMoney) platform - keyed by an internal numeric `Id`, joined to customers via `Gcid`, and tagged with the program/sub-program enrolment and the account creation timestamp. Effectively the customer <-> eMoney-program link that Payments and MIMO joins use to identify which eMoney program (Money, Money Crypto, etc.) a customer is enrolled in. | Property | Value | |----------|-------| | **Schema** | eMoney_dbo | | **Object Type** | Table | | **Production Source** | eMoney platform - fiat account creation events | | **Refresh** | Continuous (event-driven) - `SynapseUpdateDate` indicates the most recent ETL touch (4 AM cycle observed) | | **Row Count** | ~2,060,000 | | **Grain** | One row per eMoney fiat account | | | | | **Synapse Distribution** | (typically HASH on Gcid for cust'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount SET TAGS (
    'source_schema' = 'eMoney_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN Id COMMENT 'eMoney-internal numeric primary key. One row per fiat account. Append-only on creation. (Tier 1 - DDL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN Gcid COMMENT 'Global Customer ID - eToro-platform-side. Joins to `DWH_dbo.Dim_Customer.GCID` and `BI_DB_dbo.BI_DB_DDR_CID_Level.CID`. The single most common join key out of this table. (Tier 1 - DDL + sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN AccountGuid COMMENT 'UUID-style account identifier exposed to eMoney APIs and client systems. Primary handle for cross-reference into eMoney transaction streams (Tribe audit, eMoney IBAN tables). (Tier 1 - UC sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN Created COMMENT 'Timestamp when the eMoney fiat account was opened. Source-of-truth for "eMoney opened" events. (Tier 1 - UC sample, 2026-05-06 latest)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN AccountProgramId COMMENT 'Top-level enrollment program identifier. Two main families observed (1 and 2); 2 is dominant (>2M of ~2.06M rows). The (AccountProgramId, SubProgramId) pair encodes the specific eMoney offering. (Tier 2 - UC distribution audit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN SubProgramId COMMENT 'Sub-program / variant identifier within the parent AccountProgram. Distinct values 1-16 observed. (Tier 2 - UC distribution audit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN etr_y COMMENT 'Year string derived from `Created` (e.g. `''2026''`). Often empty in some rows - when blank, derive from `YEAR(Created)`. (Tier 3 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN etr_ym COMMENT 'Year-month string `''YYYY-MM''`. Same caveat as etr_y. (Tier 3 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN etr_ymd COMMENT 'Year-month-day string `''YYYY-MM-DD''`. Same caveat. (Tier 3 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN SynapseUpdateDate COMMENT 'Timestamp of the most recent Synapse-side ETL touch on this row. Useful for change-data capture (see `WHERE SynapseUpdateDate >= ...` for incremental). (Tier 1 - UC sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN partition_date COMMENT 'UC-side partition column - one partition per business day of ingestion. Push predicates on this for fast scans (e.g. `WHERE partition_date = CURRENT_DATE - 1`). (Tier 1 - DDL + UC partition spec)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN Id SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN Gcid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN AccountGuid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN Created SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN AccountProgramId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN SubProgramId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN etr_y SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN etr_ym SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN etr_ymd SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN SynapseUpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount ALTER COLUMN partition_date SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 10:51:19 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 4
-- Statements: 24/24 succeeded
-- ====================
