-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_aftrouting  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN ID COMMENT 'Surrogate sequential identifier. NOT the primary key - included for convenience reference (e.g., admin UI row identification). The real routing key is the composite PK (CountryID, CardTypeID, RegulationID, DepotID).';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN CountryID COMMENT 'Country of the customer initiating the AFT transaction. Part of the composite PK. Implicit FK to Dictionary.Country. Combined with CardTypeID and RegulationID to identify the applicable routing set. Used as an optional filter in AftRoutingGet (@CountryID=NULL means all countries).';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN CardTypeID COMMENT 'Credit/debit card network type. Part of the composite PK. All current rows: 1=Visa (82%), 2=MasterCard (18%). FK to Dictionary.CardType. Determines which card network''s AFT routing rules apply.';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN RegulationID COMMENT 'Regulatory jurisdiction governing the customer''s account. Part of the composite PK. Current values: 1=CySEC (69%), 2=FCA (5%), 4=ASIC (5%), 9=FSA Seychelles (3%), 10=ASIC & GAML (5%). FK to Dictionary.Regulation. Determines jurisdiction-specific AFT gateway eligibility.';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN DepotID COMMENT 'The payment gateway depot eligible for AFT processing for this country/card/regulation combination. Part of the composite PK. FK to Billing.Depot. Multiple DepotIDs per (CountryID, CardTypeID, RegulationID) tuple represent alternative eligible gateways.';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN ValidFrom COMMENT 'Timestamp when this routing rule became effective. Auto-managed by SQL Server temporal system. Populated on INSERT and each UPDATE. Earliest value: 2023-07-25 (table creation). Read-only - cannot be set by application code.';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN ValidTo COMMENT 'Timestamp when this routing rule was superseded. Auto-managed by SQL Server temporal system. Active rows: 9999-12-31 (open-ended). On UPDATE/DELETE, SQL Server sets this to the change timestamp and moves the row to History.BillingAftRouting. Read-only.';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN IsWhitelistedProvider COMMENT 'Whether this depot is explicitly preferred (forced) for this routing combination: true=whitelisted/forced, NULL=standard eligible. Only 3 rows have true - used for priority routing overrides. No false values currently exist.';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN IsBlacklistedProvider COMMENT 'Whether this depot is explicitly excluded from this routing combination despite being listed: false=explicitly excluded, NULL=standard eligible. Only 2 rows have false - used for suppression overrides. No true values currently exist (bit semantics: true would mean "is blacklisted").';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:27:20 UTC
-- Statements: 9/9 succeeded
-- ====================
