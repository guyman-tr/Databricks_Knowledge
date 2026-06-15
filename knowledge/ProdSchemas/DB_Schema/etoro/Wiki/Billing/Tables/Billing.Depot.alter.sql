-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_depot  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN DepotID COMMENT 'Primary key. Manually assigned (no IDENTITY). Stable identifier referenced by deposits, MID settings, and routing tables.';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN FundingTypeID COMMENT 'Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References `Dictionary.FundingType` implicitly (no FK constraint in DDL). 38 distinct values across 163 depots.';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN PaymentTypeID COMMENT 'Direction of payment flow. FK to `Dictionary.PaymentType` (FK_DPMT_BDPT): 1=Deposit, 2=Cashout, 3=Refund. Indexed (BDPT_PAYMENTTYPE).';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN ProtocolID COMMENT 'Payment processing protocol/gateway. FK to `Dictionary.Protocol` (FK_DPRT_BDPT). Identifies the specific API or connection used (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). Indexed (BDPT_PROTOCOL).';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN Name COMMENT 'Human-readable depot name (e.g., ''MoneyBookers USD'', ''Neteller'', ''Wire''). UNIQUE (BDPT_NAME index). Used in admin dashboards, routing logs, and discrepancy reports.';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN IsActive COMMENT 'Whether this depot is currently accepting transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. Queried as `IsActive = 1` in routing logic.';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN PayoutGeneration COMMENT 'Controls automated payout file generation capability: 1=enabled (system can generate payment batch files for this depot); 0=disabled (manual or provider-managed). Default=0.';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN Features COMMENT 'Depot-specific configuration features in structured text (JSON or XML format). Used for newer integrations requiring behavioral flags (e.g., 3DS2 settings, specific API options). NULL or empty for most legacy depots.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:12 UTC
-- Statements: 8/8 succeeded
-- ====================
