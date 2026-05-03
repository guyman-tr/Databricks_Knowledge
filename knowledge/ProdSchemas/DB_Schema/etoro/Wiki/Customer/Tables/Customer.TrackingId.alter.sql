-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.TrackingId
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.TrackingId.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_customer_trackingid
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_customer_trackingid (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_customer_trackingid SET TBLPROPERTIES (
    'comment' = 'Marketing and analytics tracking identifiers per customer: stores AppsFlyer device IDs, user unique identifier cookies, and Firebase app instance IDs used for attribution and push notification routing. Source: etoro.Customer.TrackingId on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.TrackingId.md).'
);

ALTER TABLE main.general.bronze_etoro_customer_trackingid SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'TrackingId',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_customer_trackingid ALTER COLUMN CID COMMENT 'Customer identifier. Part of composite PK. References Customer.CustomerStatic (no FK enforced). (Tier 1 - upstream wiki, etoro.Customer.TrackingId)';
ALTER TABLE main.general.bronze_etoro_customer_trackingid ALTER COLUMN GCID COMMENT 'Group Customer ID - the cross-product identity. Stored alongside CID for data lake and analytics queries that work at the GCID level. (Tier 1 - upstream wiki, etoro.Customer.TrackingId)';
ALTER TABLE main.general.bronze_etoro_customer_trackingid ALTER COLUMN TrackingID COMMENT 'Type of tracking identifier. Implicit FK to Dictionary.Tracking. Values: 1=AppsFlyerDeviceID, 2=UserUniqueIdentifierCookie, 3=FirebaseAppInstanceId. Part of composite PK and the secondary NC index. (Tier 1 - upstream wiki, etoro.Customer.TrackingId)';
ALTER TABLE main.general.bronze_etoro_customer_trackingid ALTER COLUMN TrackingValue COMMENT 'The actual identifier value from the external platform. For TrackingID=1: the AppsFlyer device ID string. For TrackingID=2: the browser cookie unique ID. For TrackingID=3: the Firebase app instance ID. Included in the NC index (Idx_Customer_TrackingId_TrackingID_CID) for covering-index lookups by tracking type. (Tier 1 - upstream wiki, etoro.Customer.TrackingId)';
ALTER TABLE main.general.bronze_etoro_customer_trackingid ALTER COLUMN Occurred COMMENT 'UTC timestamp when this tracking identifier was recorded. Defaults to getutcdate() at INSERT. (Tier 1 - upstream wiki, etoro.Customer.TrackingId)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
