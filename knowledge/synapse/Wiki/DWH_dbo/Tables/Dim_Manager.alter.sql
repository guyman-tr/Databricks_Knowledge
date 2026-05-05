-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Manager
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_Manager` is the reference table for eToro''s BackOffice customer-success managers -- the people (support agents, account managers, team leaders) assigned to serve customer accounts. A customer account typically has an assigned ManagerID that identifies the primary relationship owner in the BackOffice/CRM system. The table holds 5,152 rows: 1,367 currently active managers (`IsActive=True`) including 1 active team leader, plus 3,785 historical/departed managers (`IsActive=False`). Since rows are never deleted, the table preserves the full history of everyone who has ever been a manager in the system. Key columns: `FirstName`, `LastName` (personal details), `IsActive` (currently employed/assigned), `IsTeamLeader` (hierarchy flag), `SFManagerID` (Salesforce CRM ID, 18-char), `CalendlyID` (scheduling link). The `UserGroup` and `ParentUserGroup` columns are **not populated** -- both are hardcoded to `''Not Available''` in the ETL SP. ETL pattern: `SP_Dictionaries_DL_To_Synapse` -- loads a staging inter...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP, PK_ManagerID NOT ENFORCED',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN ManagerID COMMENT 'Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the ''acting staff'' reference. (Tier 1 - BackOffice.Manager)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN UserGroup COMMENT 'Hardcoded to ''Not Available'' for all rows. The ETL SP sets this to a literal constant: `''Not Available'' as UserGroup`. Intended to represent the manager''s team/group but not populated. Do not use. (Tier 3 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN ParentUserGroup COMMENT 'Hardcoded to ''Not Available'' for all rows. Same as UserGroup -- intended to represent the manager''s parent team hierarchy but not populated. Do not use. (Tier 3 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN FirstName COMMENT 'Staff member''s first name. Combined with LastName in views and procedures to produce display names (e.g., BackOffice.GetMyCustomers sets [Manager] = FirstName + '' '' + LastName). (Tier 1 - BackOffice.Manager)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN LastName COMMENT 'Staff member''s last name. Combined with FirstName for display. LastName=''*'' indicates a functional/shared account (e.g., the generic ''support'' account). (Tier 1 - BackOffice.Manager)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN IsActive COMMENT 'Logical soft-delete flag controlling login access and visibility. 1=active (staff currently employed, can authenticate). 0=deactivated (former staff or suspended; LOGIN is blocked). Do NOT physically delete manager rows - use IsActive=0 to preserve audit history. (Tier 1 - BackOffice.Manager)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN IsTeamLeader COMMENT 'Marks this manager as a team leader within their department. 1=team leader role. 0=individual contributor. Used in LoadManagers/LoadManagerByUsername responses for role-based UI rendering. (Tier 1 - BackOffice.Manager)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN DWHManagerID COMMENT 'Always equal to ManagerID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN UpdateDate COMMENT 'ETL run timestamp for the most recent UPDATE that touched this row. Set to GETDATE() on every daily UPDATE. Reflects last ETL run, not production modification. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN InsertDate COMMENT 'ETL run timestamp when the manager row was first inserted into Dim_Manager. Set once on INSERT; not updated on subsequent runs. Unlike most DWH tables, this may reflect the actual first-appearance date for the manager. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN SFManagerID COMMENT 'Salesforce CRM 18-character object ID for this manager (e.g., 0050800000DitvwAAB). Set via post-load UPDATE from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping. NULL for managers not present in the Salesforce mapping. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN CalendlyID COMMENT 'Calendly scheduling identifier for this manager. Exposed via GetManagers procedure for the customer-facing scheduler that lets customers book calls with their account manager. (Tier 1 - BackOffice.Manager)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN ManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN UserGroup SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN ParentUserGroup SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN FirstName SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN LastName SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN IsTeamLeader SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN DWHManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN SFManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager ALTER COLUMN CalendlyID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:11:22 UTC
-- Batch deploy resume: DWH_dbo deploy batch 10
-- Statements: 28/28 succeeded
-- ====================
