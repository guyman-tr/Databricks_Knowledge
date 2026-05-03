-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PlayerStatusSubReasons
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_playerstatussubreasons
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_playerstatussubreasons (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatussubreasons SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 83 granular sub-reasons for account status changes - providing detailed classification under each parent reason for compliance investigations, chargebacks, verification failures, and screening results. Source: etoro.Dictionary.PlayerStatusSubReasons on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_playerstatussubreasons SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PlayerStatusSubReasons',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatussubreasons ALTER COLUMN PlayerStatusSubReasonID COMMENT 'Primary key identifying the granular sub-reason. Range 0-82. Referenced by BackOffice.PlayerStatusReasonToSubReason (FK) and Customer.CustomerStatic (FK). Used as parameter in BackOffice.UpdateRiskUserInfo. 0=None (default). Provides second-level detail beneath PlayerStatusReasonID. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerStatusSubReasons)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatussubreasons ALTER COLUMN Name COMMENT 'Human-readable sub-reason label. Nullable (same as parent Reasons table). Used in BackOffice reporting JOINs and customer history views. Displayed in BackOffice UI alongside the parent reason. Contains abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, LEI=Legal Entity Identifier, PEP=Politically Exposed Person, SAR=Suspicious Activity Report, WCH=World Check, CRS=Common Reporting Standard. (Tier 1 - upstream wiki, etoro.Dictionary.PlayerStatusSubReasons)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
