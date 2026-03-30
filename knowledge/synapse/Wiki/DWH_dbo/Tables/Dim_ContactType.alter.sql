-- =============================================================================
-- ALTER Script: DWH_dbo.Dim_ContactType
-- UC Target:    Not in Generic Pipeline mapping - not exported to Gold/UC
-- Resolution:   Wiki property table
-- Generated:    2026-03-22
-- Source Wiki:   knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ContactType.md
-- Quality:      4.5/10
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. TABLE COMMENT
-- ---------------------------------------------------------------------------
ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
SET TBLPROPERTIES (
    'comment' = '`Dim_ContactType` is a dimension table whose purpose is to enumerate categories of "contact types" - likely customer contact methods or interaction channel types (e.g., email, phone, chat). However, the table has **0 rows** and its intended business meaning cannot be confirmed from data. No upstream production source has been found for this table. Exhaustive searching across the Dataplatform SSDT repo found no stored procedure that writes to it, no staging table that feeds it, no DWH_Migration script that seeded it, and no entry in the Generic Pipeline mapping. The DB_Schema etoro repository has no ContactType table or wiki. This table appears to be a planned dimension that was never populated or connected to an ETL pipeline. The presence of `DWHContactTypeID` (a standard DWH surrogate key column pattern seen on SP_Dictionaries-loaded tables) suggests this table was designed to be populated by `SP_Dictionaries_DL_To_Synapse`, but the corresponding ETL section was never implemented. This table is a candidat...'
);

-- ---------------------------------------------------------------------------
-- 2. TABLE TAGS
-- ---------------------------------------------------------------------------
ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
SET TAGS (
    'domain' = 'DWH',
    'object_type' = 'Table',
    'synapse_schema' = 'DWH_dbo',
    'synapse_object_name' = 'Dim_ContactType',
    'refresh_frequency' = 'None - empty table, no active ETL',
    'source_system' = 'Unknown - no ETL SP, staging table, migration script, or production DB equivalent found',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ContactTypeID ASC)',
    'uc_format' = '_Pending - resolved during write-objects_',
    'pipeline' = 'Generic Pipeline (daily export)',
    'semantic_grade' = '4.5',
    'semantic_wiki' = 'DWH_dbo/Tables/Dim_ContactType.md'
);

-- ---------------------------------------------------------------------------
-- 3. COLUMN COMMENTS
-- ---------------------------------------------------------------------------

ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
ALTER COLUMN ContactTypeID COMMENT 'Natural key identifying the contact type. 0 rows - values never loaded. Expected to match a production Dictionary.ContactType.ContactTypeID if ETL is ever implemented. (Tier 3b - SSDT DDL, DWH_dbo.Dim_ContactType)';

ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
ALTER COLUMN Name COMMENT '[UNVERIFIED] Short label for the contact type category (e.g., "Email", "Phone", "Chat"). No data exists to confirm actual values. (Tier 4 - inferred)';

ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
ALTER COLUMN DWHContactTypeID COMMENT 'DWH surrogate key - standard DWH pattern where DWH{X}ID mirrors the source PK. Expected to equal ContactTypeID if loaded by SP_Dictionaries pattern. 0 rows - never populated. (Tier 3b - SSDT DDL DWH design pattern)';

ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - would record GETDATE() on each SP_Dictionaries refresh. Currently NULL (0 rows, no ETL). (Tier 3b - SSDT DDL, SP_Dictionaries pattern)';

ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
ALTER COLUMN InsertDate COMMENT 'ETL insert timestamp - would record GETDATE() when row first loaded. Currently NULL (0 rows, no ETL). (Tier 3b - SSDT DDL, SP_Dictionaries pattern)';

ALTER TABLE Not in Generic Pipeline mapping - not exported to Gold/UC
ALTER COLUMN StatusID COMMENT 'Active/inactive flag - standard SP_Dictionaries convention (1 = active). Currently NULL (0 rows, no ETL). (Tier 3b - SSDT DDL, SP_Dictionaries pattern)';

-- ---------------------------------------------------------------------------
-- 4. COLUMN PII TAGS
-- ---------------------------------------------------------------------------
-- No PII-sensitive columns detected for this object.

-- =============================================================================
-- END OF ALTER SCRIPT
-- =============================================================================
