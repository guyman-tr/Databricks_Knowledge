-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.WithdrawApproval
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_withdrawapproval
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_withdrawapproval (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval SET TBLPROPERTIES (
    'comment' = 'Multi-group approval records for customer withdrawal (cashout) requests, tracking each user group''s decision, manager, and reason. Mirrors to History.WithdrawApproval on every change. Source: etoro.BackOffice.WithdrawApproval on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'WithdrawApproval',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN ApprovedWithdrawID COMMENT 'Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each approval record. ~3.7M records as of 2026-03-17. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN WithdrawID COMMENT 'FK to Billing.Withdraw.WithdrawID (FK_BWIT_BWAP). Identifies the withdrawal request being approved. Multiple rows share a WithdrawID (one per approval group). Part of UNIQUE index (WithdrawID + UserGroupID). (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN UserGroupID COMMENT 'FK to Dictionary.UserGroup.UserGroupID (FK_DUGR_BWAP). Identifies which approval group this row represents. 1=Admin, 3=Risk, 4=Marketing, 6=Trading. Each group submits one row per withdrawal. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN ManagerID COMMENT 'FK to BackOffice.Manager.ManagerID (FK_BMNG_BWAP). The manager who submitted this group''s decision. ManagerID=0 indicates automated/system approval without human review. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN WithdrawApprovalReasonID COMMENT 'FK to Dictionary.WithdrawApprovalReason (FK_DWAP_BWAP). Reason for the approval decision. 7=Other (default for automated approvals). 1-6 and 8-16 indicate specific compliance reasons for manual holds/approvals. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN Approved COMMENT '1=This group approved the withdrawal. 0=This group rejected/held. A withdrawal proceeds only when all required groups (per Maintenance.Feature thresholds) have Approved=1. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN Occurred COMMENT 'Timestamp when this approval decision was recorded. Defaults to GETDATE() for direct inserts; set to GetDate() in WithdrawApprovalAdd SP. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';
ALTER TABLE main.billing.bronze_etoro_backoffice_withdrawapproval ALTER COLUMN Comment COMMENT 'Free-text comment from the approving/rejecting manager. Required field (NOT NULL). Contains compliance notes, rejection rationale, or auto-generated notes for system approvals. (Tier 1 - upstream wiki, etoro.BackOffice.WithdrawApproval)';

