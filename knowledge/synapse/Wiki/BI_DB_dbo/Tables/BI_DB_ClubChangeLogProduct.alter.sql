-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_ClubChangeLogProduct
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_ClubChangeLogProduct > 49.4M-row append-only event log capturing every eToro Club loyalty tier change for 46.4M customers from 2007-08-22 to 2026-04-12. Each row records one club event: initial assignment (FirstClub), promotion (Upgrade), or demotion (Downgrade), with the customer''s old and new tier, club name, and sort rank. The IsFTC flag identifies a customer''s first-ever promotion above Bronze. Updated daily by SP_ClubChangeLogProduct via DELETE-then-append (idempotent replay from @Date). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_SnapshotCustomer × Dim_PlayerLevel × Dim_Range (via SP_ClubChangeLogProduct) | | **Refresh** | Daily - DELETE WHERE Date >= @Date + INSERT (append-only, idempotent per-date) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN Date COMMENT 'Business event date - the SP run date (@Date parameter) on which the club change was detected. Clustered index key. Use this column for date-range scans. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN OldTier COMMENT 'Previous loyalty tier PlayerLevelID before this change. NULL for FirstClub/First Club events (no prior tier). FK to Dim_PlayerLevel. Not in rank order - use OldSort for ordering. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN OldClub COMMENT 'Previous club name resolved from Dim_PlayerLevel.Name at the time of the last prior event. NULL for FirstClub events. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN OldSort COMMENT 'Previous tier sort order from Dim_PlayerLevel.Sort. NULL for FirstClub events. 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use this column (not OldTier) for rank ordering. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CurrentTier COMMENT 'Current loyalty tier PlayerLevelID from Fact_SnapshotCustomer on the event date. FK to Dim_PlayerLevel. Non-sequential: 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. Use CurrentSort for ordering. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CurrentClub COMMENT 'Current club name resolved from Dim_PlayerLevel.Name at ETL time. Denormalized - no JOIN needed for display. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CurrentSort COMMENT 'Current tier sort order from Dim_PlayerLevel.Sort. 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use this column for correct tier rank ordering. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN PLChangeType COMMENT 'Club event type. IMPORTANT - dual naming: ''FirstClub'' (current SP, 14.9M rows) and ''First Club'' (legacy SP, 31.5M rows) both indicate initial tier assignment. ''Upgrade'' (2.2M): Sort improved. ''Downgrade'' (695K): Sort decreased. Always use IN or LIKE when filtering on first-assignment events. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to SYSUTCDATETIME() at INSERT and again at IsFTC UPDATE. (Tier 2 - SP_ClubChangeLogProduct)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN IsFTC COMMENT 'First Time Club flag. 1 = this is the customer''s first-ever promotion to a tier above Bronze (CurrentTier > 1 AND cumulative rank = 1 by Date). 0 = all other events, including Bronze first-assignments and subsequent tier changes. (Tier 2 - SP_ClubChangeLogProduct)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN OldTier SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN OldClub SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN OldSort SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CurrentTier SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CurrentClub SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN CurrentSort SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN PLChangeType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ALTER COLUMN IsFTC SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:32:08 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 24/24 succeeded
-- ====================
