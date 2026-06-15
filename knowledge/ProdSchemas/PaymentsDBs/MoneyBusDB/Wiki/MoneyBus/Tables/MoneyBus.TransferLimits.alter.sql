-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_moneybusdb_moneybus_transferlimits  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN CountryID COMMENT 'Country filter for the limit rule. NULL means the rule applies to all countries. When set, restricts this limit to users in the specified country. Currently all rows have NULL (global rules).';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN DebitAccountTypeID COMMENT 'Source account type being debited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Defines the "from" side of the transfer direction.';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN CreditAccountTypeID COMMENT 'Destination account type being credited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Defines the "to" side of the transfer direction.';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN MinAmount COMMENT 'Minimum transfer amount allowed in the specified currency. Currently set to 1 for all rules - prevents zero-amount transfers.';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN MaxAmount COMMENT 'Maximum transfer amount allowed in the specified currency. Ranges from 50,000 (flow-specific restriction) to 100,000,000 (default). The application rejects transfers exceeding this.';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN CurrencyID COMMENT 'Currency the limit applies to. Each currency requires its own limit row because acceptable ranges differ by currency denomination. Maps to an external currency reference.';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN PlayerLevelID COMMENT 'Player/user tier level filter. NULL means the rule applies to all levels. When set, allows different transfer limits for VIP vs. standard users. Currently all rows have NULL (uniform limits).';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN FlowID COMMENT 'Business flow identifier. NULL means "default for all flows." When specified (e.g., FlowID=2), applies a more specific limit that overrides the default. One row uses FlowID=2 with a lower MaxAmount, indicating a restricted flow type.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:38 UTC
-- Statements: 8/8 succeeded
-- ====================
