-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_riskmanagementstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskManagementStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_riskmanagementstatus ALTER COLUMN RiskManagementStatusID COMMENT 'Primary key identifying the risk check outcome. 1=Success, 2 - 69=block/decline reason. Referenced by Billing.Deposit, Billing.CreditCardAuthentication, Billing.RiskManagementCheck, Billing.RiskManagementConfiguration, Billing.WithdrawToRiskManagementStatus. Set via Billing.DepositSetRiskManagementStatus, Billing.RiskManagementCheckAdd.';
ALTER TABLE main.general.bronze_etoro_dictionary_riskmanagementstatus ALTER COLUMN Name COMMENT 'Human-readable status label. UNIQUE (DRMS_NAME). Used for reporting, UI, and audit. 68 distinct values in live data (e.g., Success, CardIsBlocked, BinInBlackList, KYCLevel0, ML, BusinessRuleRisk).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:59 UTC
-- Statements: 2/2 succeeded
-- ====================
