-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.ManagerToPermission
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.ManagerToPermission.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_backoffice_managertopermission
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_backoffice_managertopermission (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_backoffice_managertopermission SET TBLPROPERTIES (
    'comment' = 'Access control mapping granting specific permissions to BackOffice agents per trading provider/entity. The authorization matrix that determines which BackOffice operations each agent can perform on each regulated entity. All changes are audit-logged to History.ManagerToPermission via trigger. Source: etoro.BackOffice.ManagerToPermission on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.ManagerToPermission.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_backoffice_managertopermission SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'ManagerToPermission',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_backoffice_managertopermission ALTER COLUMN ManagerID COMMENT 'BackOffice agent receiving the permission. Part of composite PK. FK (WITH CHECK) to BackOffice.Manager. See BackOffice.Manager for agent details. (Tier 1 - upstream wiki, etoro.BackOffice.ManagerToPermission)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_managertopermission ALTER COLUMN PermissionID COMMENT 'The specific permission being granted. Part of composite PK. FK (WITH CHECK) to Dictionary.Permission. 148 distinct permission types covering all BackOffice operations. (Tier 1 - upstream wiki, etoro.BackOffice.ManagerToPermission)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_managertopermission ALTER COLUMN ProviderID COMMENT 'The regulated entity/provider for which this permission applies. Part of composite PK. No FK constraint. Values: 0=global/entity-agnostic, 1=primary trading entity, 2=secondary entity. Matches the @ProviderID parameter in BackOffice.LogIn. (Tier 1 - upstream wiki, etoro.BackOffice.ManagerToPermission)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
