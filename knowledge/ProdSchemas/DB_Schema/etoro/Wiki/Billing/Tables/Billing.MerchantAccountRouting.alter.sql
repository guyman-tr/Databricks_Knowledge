-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_etoro_billing_merchantaccountrouting  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN ID COMMENT '[CODE-BACKED] Surrogate PK. NOT FOR REPLICATION. Physical clustered key.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN DepotID COMMENT '[CODE-BACKED] Payment depot dimension. No explicit FK. All 645 rows use DepotID=92 (Checkout.com) in first 5 rows - routing table is depot-specific.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN DepotModeID COMMENT '[CODE-BACKED] Mode dimension. 1=Live (33 rows), 2=Demo (612 rows). No explicit FK.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN RegulationID COMMENT '[CODE-BACKED] Regulatory entity dimension (CySEC=1, FCA=2, ASIC=4, etc.). No explicit FK.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN CurrencyID COMMENT '[CODE-BACKED] Currency dimension. 0=any currency (wildcard). No explicit FK.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN PaymentTypeID COMMENT '[CODE-BACKED] Payment type dimension. 0=any payment type (wildcard). Differentiates routing for deposit vs withdrawal or different payment flows.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN CountryID COMMENT '[CODE-BACKED] Customer country dimension. 0=any country (wildcard). Country-specific rules (non-zero) take precedence over wildcards. No explicit FK.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN SubTypeID COMMENT '[CODE-BACKED] Sub-type dimension. 0=default. Matches SubTypeID in ProtocolMIDSettings for sub-routing variants.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN MerchantAccountID COMMENT '[CODE-BACKED] The resolved merchant account for this routing combination. Joined to MerchantAccountValues to get credentials.';
ALTER TABLE main.bi_db.bronze_etoro_billing_merchantaccountrouting ALTER COLUMN Description COMMENT '[NAME-INFERRED] Human-readable label for this routing rule (e.g., which processor/account). NULL in most rows.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:27:25 UTC
-- Statements: 10/10 succeeded
-- ====================
