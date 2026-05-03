-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.AftRouting
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_aftrouting
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_aftrouting (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting SET TBLPROPERTIES (
    'comment' = 'Temporal routing configuration table mapping (Country + CardType + Regulation + Depot) combinations for AFT (Automatic Fund Transfer) transactions, with optional provider whitelist/blacklist flags. Source: etoro.Billing.AftRouting on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_aftrouting SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'AftRouting',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN ID COMMENT 'Surrogate sequential identifier. NOT the primary key - included for convenience reference (e.g., admin UI row identification). The real routing key is the composite PK (CountryID, CardTypeID, RegulationID, DepotID). (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN CountryID COMMENT 'Country of the customer initiating the AFT transaction. Part of the composite PK. Implicit FK to Dictionary.Country. Combined with CardTypeID and RegulationID to identify the applicable routing set. Used as an optional filter in AftRoutingGet (@CountryID=NULL means all countries). (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN CardTypeID COMMENT 'Credit/debit card network type. Part of the composite PK. All current rows: 1=Visa (82%), 2=MasterCard (18%). FK to Dictionary.CardType. Determines which card network''s AFT routing rules apply. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN RegulationID COMMENT 'Regulatory jurisdiction governing the customer''s account. Part of the composite PK. Current values: 1=CySEC (69%), 2=FCA (5%), 4=ASIC (5%), 9=FSA Seychelles (3%), 10=ASIC & GAML (5%). FK to Dictionary.Regulation. Determines jurisdiction-specific AFT gateway eligibility. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN DepotID COMMENT 'The payment gateway depot eligible for AFT processing for this country/card/regulation combination. Part of the composite PK. FK to Billing.Depot. Multiple DepotIDs per (CountryID, CardTypeID, RegulationID) tuple represent alternative eligible gateways. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN Trace COMMENT 'Audit context column, computed at read time. JSON string capturing: HostName (server running the query), AppName (application name), SUserName (SQL login), SPID (session ID), DBName, ObjectName (stored procedure if any). Format: {"HostName": "...", "AppName": "...", ...}. Not stored persistently - recalculated every SELECT. Used to identify which application/process is reading routing data. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN ValidFrom COMMENT 'Timestamp when this routing rule became effective. Auto-managed by SQL Server temporal system. Populated on INSERT and each UPDATE. Earliest value: 2023-07-25 (table creation). Read-only - cannot be set by application code. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN ValidTo COMMENT 'Timestamp when this routing rule was superseded. Auto-managed by SQL Server temporal system. Active rows: 9999-12-31 (open-ended). On UPDATE/DELETE, SQL Server sets this to the change timestamp and moves the row to History.BillingAftRouting. Read-only. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN IsWhitelistedProvider COMMENT 'Whether this depot is explicitly preferred (forced) for this routing combination: true=whitelisted/forced, NULL=standard eligible. Only 3 rows have true - used for priority routing overrides. No false values currently exist. (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
ALTER TABLE main.billing.bronze_etoro_billing_aftrouting ALTER COLUMN IsBlacklistedProvider COMMENT 'Whether this depot is explicitly excluded from this routing combination despite being listed: false=explicitly excluded, NULL=standard eligible. Only 2 rows have false - used for suppression overrides. No true values currently exist (bit semantics: true would mean "is blacklisted"). (Tier 1 - upstream wiki, etoro.Billing.AftRouting)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
