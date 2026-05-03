-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.RedeemApproval
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.RedeemApproval.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_redeemapproval
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_redeemapproval (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval SET TBLPROPERTIES (
    'comment' = 'Multi-group approval records for Bitcoin/crypto redemption requests, tracking each user group''s approval decision, manager, and reason for a given redeem. Source: etoro.BackOffice.RedeemApproval on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.RedeemApproval.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'RedeemApproval',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN ApprovedRedeemID COMMENT 'Surrogate primary key. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each approval record. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN RedeemID COMMENT 'FK to Billing.Redeem.RedeemID. Identifies the crypto redemption request being approved or rejected. Multiple rows can share a RedeemID (one per approval group). (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN CID COMMENT 'Customer ID of the redeem requestor. Denormalised here for query performance (avoids joining Billing.Redeem). Populated from Billing.Redeem.CID at insert time. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN UserGroupID COMMENT 'FK to Dictionary.UserGroup.UserGroupID. Identifies which approval group this row represents. Examples: 2=Operations, 3=Risk. Each group submits one approval row per redeem. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN ManagerID COMMENT 'FK to BackOffice.Manager.ManagerID. The specific back-office manager who submitted this group''s approval decision. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN RedeemApprovalReasonID COMMENT 'FK to Dictionary.RedeemApprovalReason.RedeemApprovalReasonID. Reason for the decision. Currently only 1=Other is defined in the lookup table. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN Approved COMMENT '1=This group approved the redeem. 0=This group rejected the redeem. A redeem requires all required groups to have Approved=1 (checked by IsApprovedByAllUserGroups). (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN Occurred COMMENT 'UTC timestamp when this approval decision was recorded. Set to GETUTCDATE() by the SP on insert and on each update. Defaults to GETDATE() for direct inserts. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_redeemapproval ALTER COLUMN Comment COMMENT 'Free-text comment provided by the approving/rejecting manager explaining the decision. Required field (NOT NULL). May contain compliance notes or rejection rationale. (Tier 1 - upstream wiki, etoro.BackOffice.RedeemApproval)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
