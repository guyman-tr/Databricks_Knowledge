-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_customertofunding  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN CID COMMENT '[CODE-BACKED] Customer ID; part of composite PK. Identifies the eToro customer who registered this payment method.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN FundingID COMMENT '[CODE-BACKED] Payment instrument ID; part of composite PK. References the global Billing.Funding record for this payment method.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN Occurred COMMENT '[CODE-BACKED] UTC timestamp when this customer first linked this funding. Defaults to current time on INSERT. Range: 2017-01-01 to present.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN DepositTypeID COMMENT '[CODE-BACKED] Type of deposit this funding was last used for. 1=Regular (99.88%), 2=CvvFree (0.12%), 3=Recurring (0.008%). See 2.5 for full map.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN ReasonID COMMENT '[CODE-BACKED] Reason code for last registration event. 6=ByUser (99.71%), 1=FtdApproved (0.22%). See 2.6 for full map.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN LastUsedDate COMMENT '[CODE-BACKED] UTC timestamp of last usage. Updated by CustomerToFunding_Upsert on each subsequent deposit attempt. Range: 2017-01-01 to present.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN CustomerFundingStatusID COMMENT '[CODE-BACKED] Per-customer activation status of this payment method. 0=Deactivated (50.4%), 1=Active (49.5%), 3=RemovedFromDeposit (0.03%), 4=ExtendedActive/PAYUSOLA-6470 (0.05%), 2=Unknown (0.03%). See 2.2 for full state machine.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN IsBlocked COMMENT '[CODE-BACKED] Whether this customer''s use of this funding is blocked. Set atomically with Billing.Funding.IsBlocked via Billing.FundingBlock. All 9.26M active rows are NOT blocked.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN IsRefundExcluded COMMENT '[CODE-BACKED] Whether this funding is excluded from refund payouts for this customer. 1.6% of rows are refund-excluded. Checked by GetCustomerLastFundingByFundingType with @FilterWithdrawBlocked=1.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN ManagerID COMMENT '[CODE-BACKED] ID of BO manager who last blocked/updated this record. NULL when the funding block mirrors the system-level block. Copied from Billing.Funding.ManagerID during FundingBlock.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN BlockedAt COMMENT '[CODE-BACKED] UTC timestamp when this record was blocked. Set by FundingBlock/BlockCurrentMeanOfPayment. NULL when not blocked.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN BlockedDescription COMMENT '[CODE-BACKED] Human-readable reason for blocking. Set by FundingBlock procedure. Mirrors Billing.Funding.BlockedDescription.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN IsVerified COMMENT '[CODE-BACKED] Verification flag added PAYIL-5743 (Jan 2023). Only 7 rows are true; feature is sparse. Included in all History.ActiveCustomerToFunding OUTPUT clauses.';
ALTER TABLE main.billing.bronze_etoro_billing_customertofunding ALTER COLUMN BlockManagerID COMMENT '[CODE-BACKED] ID of the BO manager who issued the block command. Distinct from ManagerID; added to FundingBlock procedure (PAYIL-5724, Jan 2023).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:19 UTC
-- Statements: 14/14 succeeded
-- ====================
