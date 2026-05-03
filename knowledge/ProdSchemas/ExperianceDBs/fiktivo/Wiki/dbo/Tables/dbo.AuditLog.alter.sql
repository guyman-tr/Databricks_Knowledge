-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.AuditLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.AuditLog.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiktivo_dbo_auditlog
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiktivo_dbo_auditlog (business_group=general) ----
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog SET TBLPROPERTIES (
    'comment' = 'Tracks all admin user changes to affiliate platform configuration, recording who changed what field, in which section, with old and new values plus reason for change. Source: fiktivo.dbo.AuditLog on the fiktivo production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.AuditLog.md).'
);

ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'AuditLog',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN AuditID COMMENT 'Primary key. Sequential audit entry identifier. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ChangedOnDate COMMENT 'Timestamp when the change was made. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ChangedByUserID COMMENT 'FK to dbo.tblaff_User.UserID. The admin user who made the change. NULL if system-generated. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ChangedSectionID COMMENT 'FK to Dictionary.ChangedSections.SectionID. Identifies which business area was modified: 1=Affiliates, 2=AffiliateTypes, 3=Affiliate Group, 4=Announcements, etc. See Changed Sections. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ChangedFieldName COMMENT 'Name of the field that was changed (e.g., "AffiliateTypeID", "AccountStatus"). MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN OldFieldValue COMMENT 'Previous value of the field before the change. MASKED. Stores raw values (IDs, codes). (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN NewFieldValue COMMENT 'New value of the field after the change. MASKED. Stores raw values. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ReasonOfChange COMMENT 'Admin-provided reason for making this change. Required field - enforces accountability. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ReferencedChangedID COMMENT 'ID of the entity that was changed (e.g., AffiliateID, AffiliateTypeID). Combined with ChangedSectionID to identify the exact record modified. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN ActionID COMMENT 'FK to Dictionary.Action. Type of operation: 1=Insert, 2=Update, 3=Delete. See Action. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN OldFieldDescription COMMENT 'Human-readable description of the old value (e.g., resolved lookup name instead of just the ID). (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN NewFieldDescription COMMENT 'Human-readable description of the new value. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
ALTER TABLE main.general.bronze_fiktivo_dbo_auditlog ALTER COLUMN UserEmail COMMENT 'Email of the admin user who made the change. MASKED. Denormalized from tblaff_User for quick display. (Tier 1 - upstream wiki, fiktivo.dbo.AuditLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
