-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_PaymentHistory
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory SET TBLPROPERTIES (
    'comment' = 'Central payment ledger recording every affiliate commission payout batch, with detailed per-tier breakdowns across all 8 commission types, multi-level approval workflow, and currency support. Source: fiktivo.dbo.tblaff_PaymentHistory on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_PaymentHistory',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentID COMMENT 'Auto-incrementing primary key. NOT FOR REPLICATION. Referenced by all _Commissions tables'' PaymentID column and tblaff_Files.PaymentID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN AffiliateID COMMENT 'The affiliate receiving this payment. Trigger enforces RI against tblaff_Affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDate COMMENT 'When the payment record was created. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentAmount COMMENT 'Total payment amount: sum of all tier commissions + adjustment. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentAdjustment COMMENT 'Manual adjustment amount applied by finance. Positive = bonus, negative = deduction. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDescription COMMENT 'Short description/label for this payment. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1CPA through Tier5CPA` COMMENT 'Count of CPA events per tier included in this payment batch. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1CPACommission through Tier5CPACommission` COMMENT 'CPA commission amount per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1Sales through Tier5Sales` COMMENT 'Count of sales events per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1SalesCommission through Tier5SalesCommission` COMMENT 'Sales commission amount per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1Registrations through Tier5Registrations` COMMENT 'Count of registration events per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1RegistrationsCommission through Tier5RegistrationsCommission` COMMENT 'Registration commission amount per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1Leads through Tier5Leads, Tier1LeadsCommission through Tier5LeadsCommission` COMMENT 'Lead counts and commission amounts per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1Clicks through Tier5Clicks, Tier1ClicksCommission through Tier5ClicksCommission` COMMENT 'Click counts and commission amounts per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentRange COMMENT 'Date range label for this payment period. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN Comment COMMENT 'Free-text comment from finance/approver. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ManagerApproved COMMENT 'First-level approval by account manager. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN Approved COMMENT 'Final aggregate approval flag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ApprovalDate COMMENT 'When the final approval was granted. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN RequestedBy COMMENT 'Admin user ID who created/requested this payment. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ApprovedBy COMMENT 'Admin user ID who gave final approval. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN VPMarketingApproved COMMENT 'Second-level VP Marketing approval. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN CurrencyID COMMENT 'Payment currency. Default 1 = USD. References Dictionary.Currency. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN LastApprovalDate COMMENT 'Timestamp of the most recent approval step. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN Tier1eCostCommission COMMENT 'eCost commission amount (Tier 1 only - no multi-tier for eCost in this summary). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDetailsID COMMENT 'References the affiliate''s payment method/bank details. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDetailsOnApprove COMMENT 'Snapshot of payment details captured at approval time for audit. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentMethodOnApprove COMMENT 'Payment method code captured at approval time. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1CopyTraders through Tier5CopyTraders, Tier1CopyTradersCommission through Tier5CopyTradersCommission` COMMENT 'CopyTrader event counts and commission amounts per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN `Tier1FirstPositions through Tier5FirstPositions, Tier1FirstPositionsCommission through Tier5FirstPositionsCommission` COMMENT 'FirstPosition event counts and commission amounts per tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentRowStatusID COMMENT 'Payment processing status. FK to Dictionary.PaymentRowStatus: 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected. See Payment Row Status. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN eCostHistoryID COMMENT 'References tblaff_eCostHistory.eCostHistoryID (explicit FK). Links this payment to an eCost reconciliation record. NULL when no eCost linkage. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN FinanceApproved COMMENT 'Third-level finance team approval. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentPeriod COMMENT 'The payment period this batch covers (first day of month). E.g., 2026-02-01 = February 2026 commissions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentGroupCode COMMENT 'GUID grouping related payment rows into a single batch for bulk processing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN AmountInCurrency COMMENT 'Payment amount converted to the affiliate''s preferred currency (per CurrencyID). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ReferenceNumber COMMENT 'External payment reference number (bank transfer reference, wire confirmation, etc.). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN RowVersion COMMENT 'Optimistic concurrency control. Auto-incrementing binary value used to detect concurrent updates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN FinanceManagerApproved COMMENT 'Fourth-level finance manager approval for high-value payments. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentHistory)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
