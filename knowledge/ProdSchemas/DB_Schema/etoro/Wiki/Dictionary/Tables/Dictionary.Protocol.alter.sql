-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Protocol
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Protocol.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_protocol
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_protocol (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_protocol SET TBLPROPERTIES (
    'comment' = 'Configuration table defining 45 payment protocols — each mapping a payment service provider (PSP) to a DLL implementation class, communication direction, and dynamic routing flag — forming the core of eToro''s payment processing infrastructure. Source: etoro.Dictionary.Protocol on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Protocol.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_protocol SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Protocol',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_protocol ALTER COLUMN ProtocolID COMMENT 'Primary key identifying the payment protocol. Values 1-49 (with gaps). Referenced by ProtocolParameter, Response, Billing.Terminal, Billing.Depot, and multiple billing procedures. (Tier 1 - upstream wiki, etoro.Dictionary.Protocol)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocol ALTER COLUMN PaymentServiceID COMMENT 'FK → Billing.PaymentService. Identifies which PSP backs this protocol. Multiple protocols can share a PaymentServiceID. Indexed for lookup performance. (Tier 1 - upstream wiki, etoro.Dictionary.Protocol)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocol ALTER COLUMN ProtocolDirectionID COMMENT 'FK → Dictionary.ProtocolDirection. 1=Direct (server-to-server), 2=Redirect (browser redirect). Indexed for lookup. (Tier 1 - upstream wiki, etoro.Dictionary.Protocol)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocol ALTER COLUMN Name COMMENT 'Human-readable protocol label (e.g., "Adyen", "PayPal Express Checkout"). Used in admin UI and billing logs. (Tier 1 - upstream wiki, etoro.Dictionary.Protocol)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocol ALTER COLUMN ClassKey COMMENT '.NET DLL class identifier used by the billing engine to instantiate the correct payment processor (e.g., "AdyenPaymentDll"). Multiple protocols can share a ClassKey (e.g., ACHCrossRiver and ACHSilvergate both use "ACHPaymentDll"). (Tier 1 - upstream wiki, etoro.Dictionary.Protocol)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocol ALTER COLUMN IsDynamicRouting COMMENT 'When true, the billing engine uses BIN routing, quota management, and country rules to dynamically select the optimal terminal. Null treated as false. (Tier 1 - upstream wiki, etoro.Dictionary.Protocol)';

