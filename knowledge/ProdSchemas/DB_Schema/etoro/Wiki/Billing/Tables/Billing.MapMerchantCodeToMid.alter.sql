-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.MapMerchantCodeToMid
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_billing_mapmerchantcodetomid
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_billing_mapmerchantcodetomid (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_billing_mapmerchantcodetomid SET TBLPROPERTIES (
    'comment' = 'Lookup table mapping payment provider merchant codes (as they appear in transaction records) to human-readable Merchant ID (MID) labels, scoped by regulatory entity and account currency. Source: etoro.Billing.MapMerchantCodeToMid on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_billing_mapmerchantcodetomid SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'MapMerchantCodeToMid',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_billing_mapmerchantcodetomid ALTER COLUMN RegulationID COMMENT 'eToro regulatory entity under which the transaction was processed. 1=CySEC (EU), 2=FCA (UK), 4=ASIC (Australia), 9=FSA Seychelles. Forms part of the composite PK. Explicit FK to Dictionary.Regulation(ID). Used in Billing.GetMIDDescription to scope the MID lookup by the deposit''s ProcessRegulationID or the customer''s RegulationID. (Tier 1 - upstream wiki, etoro.Billing.MapMerchantCodeToMid)';
ALTER TABLE main.bi_db.bronze_etoro_billing_mapmerchantcodetomid ALTER COLUMN CurrencyID COMMENT 'Account denomination currency of the transaction. Explicit FK to Dictionary.Currency. Combined with RegulationID to narrow the merchant code lookup. The same MerchantCode often has different underlying MID values per currency (different numeric merchant accounts per currency). (Tier 1 - upstream wiki, etoro.Billing.MapMerchantCodeToMid)';
ALTER TABLE main.bi_db.bronze_etoro_billing_mapmerchantcodetomid ALTER COLUMN MerchantCode COMMENT 'The raw merchant identifier as provided by the payment provider or used in eToro''s own systems. Three formats: (1) Numeric string = Skrill merchant account code (e.g., "5075493"); (2) Alphanumeric string = Neteller merchant account code (e.g., "AAABbn2n6r56x4Qe"); (3) eToro internal code = eToro''s own merchant account identifier (e.g., "ETOROEUOCTPT", "ETOROEUSALES"). Joined against Billing.ProtocolMIDSettings.Value in Billing.GetMIDDescription. (Tier 1 - upstream wiki, etoro.Billing.MapMerchantCodeToMid)';
ALTER TABLE main.bi_db.bronze_etoro_billing_mapmerchantcodetomid ALTER COLUMN MID COMMENT 'Human-readable Merchant ID label or numeric merchant account number. Two forms: (1) Label = friendly name used in BackOffice UI (SkrillEU, SkrillUK, SkrillAU, NetellerEU, NetellerFCA); (2) Numeric = eToro''s actual merchant account number at the payment gateway (e.g., 18986763). Returned by Billing.GetMIDDescription and displayed in payment investigation views. (Tier 1 - upstream wiki, etoro.Billing.MapMerchantCodeToMid)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
