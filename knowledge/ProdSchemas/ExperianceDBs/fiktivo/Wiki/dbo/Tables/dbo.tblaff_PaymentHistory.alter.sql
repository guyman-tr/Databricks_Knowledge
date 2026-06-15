-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentID COMMENT 'Auto-incrementing primary key. NOT FOR REPLICATION. Referenced by all _Commissions tables'' PaymentID column and tblaff_Files.PaymentID.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN AffiliateID COMMENT 'The affiliate receiving this payment. Trigger enforces RI against tblaff_Affiliates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDate COMMENT 'When the payment record was created.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentAmount COMMENT 'Total payment amount: sum of all tier commissions + adjustment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentAdjustment COMMENT 'Manual adjustment amount applied by finance. Positive = bonus, negative = deduction.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDescription COMMENT 'Short description/label for this payment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentRange COMMENT 'Date range label for this payment period.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN Comment COMMENT 'Free-text comment from finance/approver.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ManagerApproved COMMENT 'First-level approval by account manager.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN Approved COMMENT 'Final aggregate approval flag.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ApprovalDate COMMENT 'When the final approval was granted.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN RequestedBy COMMENT 'Admin user ID who created/requested this payment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ApprovedBy COMMENT 'Admin user ID who gave final approval.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN VPMarketingApproved COMMENT 'Second-level VP Marketing approval.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN CurrencyID COMMENT 'Payment currency. Default 1 = USD. References Dictionary.Currency.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN LastApprovalDate COMMENT 'Timestamp of the most recent approval step.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN Tier1eCostCommission COMMENT 'eCost commission amount (Tier 1 only - no multi-tier for eCost in this summary).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDetailsID COMMENT 'References the affiliate''s payment method/bank details.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentDetailsOnApprove COMMENT 'Snapshot of payment details captured at approval time for audit.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentMethodOnApprove COMMENT 'Payment method code captured at approval time.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentRowStatusID COMMENT 'Payment processing status. FK to Dictionary.PaymentRowStatus: 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected. See [Payment Row Status](../../_glossary.md#payment-row-status).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN eCostHistoryID COMMENT 'References tblaff_eCostHistory.eCostHistoryID (explicit FK). Links this payment to an eCost reconciliation record. NULL when no eCost linkage.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN FinanceApproved COMMENT 'Third-level finance team approval.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentPeriod COMMENT 'The payment period this batch covers (first day of month). E.g., 2026-02-01 = February 2026 commissions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN PaymentGroupCode COMMENT 'GUID grouping related payment rows into a single batch for bulk processing.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN AmountInCurrency COMMENT 'Payment amount converted to the affiliate''s preferred currency (per CurrencyID).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN ReferenceNumber COMMENT 'External payment reference number (bank transfer reference, wire confirmation, etc.).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN RowVersion COMMENT 'Optimistic concurrency control. Auto-incrementing binary value used to detect concurrent updates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory ALTER COLUMN FinanceManagerApproved COMMENT 'Fourth-level finance manager approval for high-value payments.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:18:22 UTC
-- Statements: 29/29 succeeded
-- ====================
