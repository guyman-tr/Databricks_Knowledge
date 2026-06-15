-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_protocolmidsettings  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN ID COMMENT '[CODE-BACKED] Surrogate PK (physical clustered key). Referenced as `ProtocolMIDSettingsID` in Billing.Deposit and Billing.WithdrawToFunding to record which routing config was used. NOT FOR REPLICATION.';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN ParameterID COMMENT '[CODE-BACKED] Protocol parameter type. Part of logical PK. References Billing.Parameter which defines the parameter name/type (e.g., "MID", "SecretKey", etc.).';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN DepotID COMMENT '[CODE-BACKED] Payment gateway/depot. Part of logical PK. Identifies the payment processor this MID belongs to.';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN DepotModeID COMMENT '[CODE-BACKED] Trading mode. Part of logical PK. 0=General, 1=Live, 2=Demo. Separates Live and Demo processing environments. 60% Demo, 37% Live.';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN Value COMMENT '[CODE-BACKED] The protocol identifier string (MID, merchant ID, API key, etc.). This is the actual routing value passed to the payment processor. Examples: "18989693", "18986763".';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN RegulationID COMMENT '[CODE-BACKED] Regulatory entity. Part of logical PK. Segments MIDs by legal jurisdiction (CySEC=1, FCA=2, etc.). Ensures transactions route through the correct legal entity''s acquiring relationship.';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN CurrencyID COMMENT '[CODE-BACKED] Currency restriction. Part of logical PK. 0=any currency. Most rows are 0. Non-zero restricts this MID to a specific currency.';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN Description COMMENT '[NAME-INFERRED] Human-readable description of this MID entry (e.g., which processor, account name).';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN SubTypeID COMMENT '[CODE-BACKED] Sub-routing type. 0=default (93.5%), 3=alternate (6.5%). Allows multiple routing paths within the same (depot, mode, regulation, currency).';
ALTER TABLE main.billing.bronze_etoro_billing_protocolmidsettings ALTER COLUMN MerchantAccountID COMMENT '[CODE-BACKED] Optional link to a specific merchant account configuration. 377 rows (25.6%) have this set for finer-grained routing.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:27:30 UTC
-- Statements: 10/10 succeeded
-- ====================
