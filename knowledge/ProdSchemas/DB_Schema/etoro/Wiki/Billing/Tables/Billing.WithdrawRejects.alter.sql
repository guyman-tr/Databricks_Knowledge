-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.WithdrawRejects
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_withdrawrejects
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_withdrawrejects (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects SET TBLPROPERTIES (
    'comment' = 'Tracks manual withdrawal rejection records created by operations/compliance managers, including the reason, responsible manager, follow-up schedule, and whether the rejection is still active. Source: etoro.Billing.WithdrawRejects on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'WithdrawRejects',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN RejectID COMMENT 'Surrogate primary key, auto-incremented. NOT FOR REPLICATION. No business meaning beyond row identity. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN WithdrawID COMMENT 'FK to Billing.Withdraw (WithdrawID) - enforced by FK_BWWR_BW. Identifies the withdrawal being rejected. The CLUSTERED index on this column enables fast lookup of all rejection records for a withdrawal. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN RejectReasonID COMMENT 'FK to Dictionary.CashoutRejectReason (RejectReasonID) - enforced by FK_BWWR_DCRR. Reason the withdrawal was rejected. Key values: 0=Wrong Details MOP, 1=Missing Documents, 2=Missing Payment Info, 3=Missing Alternative MOP, 4=Unclaimed, 5=Denied, 6=Bonus Abuse, 7=Risk, 8=Off Market Abuse, 9=Management Approval, 10=Other, 11=Alternative Payment method (dominant), 15=CO Issues, 19=Missing/incorrect payment info, 27=Deceased client. Full list in Dictionary.CashoutRejectReason. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN ManagerID COMMENT 'FK to BackOffice.Manager (ManagerID) - enforced by FK_BWWR_BMNG. The operations/compliance manager who performed the rejection. Value 0 appears in recent automated/system rejections. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN RejectDate COMMENT 'Timestamp when the rejection was recorded. Set by Billing.WithdrawReject as @RejectDate parameter (caller provides timestamp). Used to sequence multiple rejections per withdrawal. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN FollowupDate COMMENT 'Date by which the operations team should follow up on this rejection (check if customer responded, re-submitted, or needs chasing). Typically set 3-7 business days from RejectDate. Updated by Billing.FollowupEdit. Drives the operations team''s work queue. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN CaseNumber COMMENT 'External support/CRM ticket number linked to this rejection. NULL on initial insert (set by Billing.FollowupEdit when a support case is created). Allows linking the DB rejection record to a support platform case. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN CaseDate COMMENT 'Date the external support case was created. NULL on initial insert, set alongside CaseNumber by Billing.FollowupEdit. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN IsActive COMMENT 'Whether this rejection record is the current active rejection for the withdrawal. 1=active (this is the current rejection), 0=superseded (a newer rejection has been recorded). Set to 1 on insert by Billing.WithdrawReject. Set to 0 by Billing.SetRejectsAsInactiveForWithdraw when a re-rejection occurs. Only one IsActive=1 record should exist per WithdrawID at any time. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
ALTER TABLE main.billing.bronze_etoro_billing_withdrawrejects ALTER COLUMN Comment COMMENT 'Free-text notes from the rejecting manager. May contain case reference numbers, customer instructions, or context for the rejection (e.g., "Missing IBAN for wire transfer", "25402491 follow up"). NULL is allowed but rarely used in practice. (Tier 1 - upstream wiki, etoro.Billing.WithdrawRejects)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
