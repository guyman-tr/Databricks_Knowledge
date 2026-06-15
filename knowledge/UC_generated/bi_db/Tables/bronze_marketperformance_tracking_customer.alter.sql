-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_marketperformance_tracking_customer
-- Generated: 2026-06-10 | one-shot AppsFlyer deployment
-- Target: Unity Catalog EXTERNAL Delta table comment + column comments
-- Source-of-truth: AppsFlyer field doc (proposals/AppsFlyer_Fields.pdf) for the
--                  three vendor-documented columns (AppsflyerID, IDFV, FirebaseID);
--                  observed values for the rest. Five fields explicitly carry a
--                  NEEDS REVIEW marker because semantic / enum mapping is unknown.
-- =============================================================================

-- ---- Table Comment ----
COMMENT ON TABLE main.bi_db.bronze_marketperformance_tracking_customer IS 'CID-to-mobile-device-identity bridge for AppsFlyer attribution. 48M rows, 1 row per CID. Joins to the AppsFlyer fact (main.de_output.de_output_appsflyer_silver_reports OR main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports) on AppsflyerID=AppsFlyerID (note vendor lowercase-f spelling on this side). Carries the device identifiers AppsflyerID / FirebaseID / IDFV alongside the CID and GCID, plus iOSAdTrackingPermissionID for ATT-state filtering. Use for any per-CID rollup of mobile-attributed events; on the AppsFlyer fact CustomerUserID is null on Installs / OrganicInstalls (no CID exists pre-registration) so the bridge join is the canonical path. Coverage: 20.9M of 48M CIDs (43%) carry a populated AppsflyerID (the share of CIDs who registered via the OneApp mobile path).';

-- ---- Table Tags ----
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer SET TAGS (
    'domain' = 'marketing_attribution',
    'object_type' = 'cid_device_bridge',
    'source_schema' = 'bi_db',
    'source_system' = 'marketperformance pipeline',
    'pipeline' = 'one-shot-appsflyer-deploy',
    'pipeline_version' = '2026-06-10',
    'primary_consumers' = 'main.de_output.de_output_appsflyer_silver_reports; main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports',
    'needs_review' = 'DeviceTypeID; PartitionCol; UserUniqueIdentifierCookie; AdditionalData; iOSAdTrackingPermissionID enum',
    'semantic_grade' = '3'
);

-- ---- Column Comments (11 columns) ----
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN CID COMMENT 'Customer ID (internal platform identifier). Foreign key to Dim_Customer. Primary key of this bridge table - one row per CID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN PartitionCol COMMENT 'INT 0-9 (with one outlier row at -1) used as a partition / distribution key on the upstream marketperformance source. Even hash distribution: ~4.8M rows per bucket. Treat as physical-storage metadata - not a business dimension. (Tier 3 - observed behaviour; semantic NEEDS REVIEW)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN GCID COMMENT 'Global Customer ID - cross-regulation unique identifier for a customer across all eToro entities. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN DeviceTypeID COMMENT 'Device-type enum, INT. Three observed values: 1 (~27M, dominant), 2 (~10.1M), 3 (~10.9M). Likely Android / iOS / Web but the 1-dominant split does not match the AppsFlyer Platform split (~75% android / ~23% ios) so it is NOT a one-to-one platform code. (Tier 3 - observed values only; full enum NEEDS REVIEW)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN AppsflyerID COMMENT 'AppsFlyer''s unique device+install identifier (vendor-issued, privacy-safe). Joins to AppsFlyerID on the AppsFlyer fact tables. NOTE the vendor lowercase-f spelling on this column versus the AppsFlyer-fact AppsFlyerID. Populated on 20.9M of 48M rows (43%) - the share of CIDs that registered via the mobile app. (Tier 1 - AppsFlyer field appsflyer_id)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN UserUniqueIdentifierCookie COMMENT 'STRING populated on 8.9M of 48M rows (18%). Per the column name, this is a per-user unique cookie identifier - presumably the web-tracking cookie ID stored alongside the CID for cross-device identity resolution. Treat as PII / pseudonymous identifier. (Tier 3 - inferred from name; usage and provenance NEED REVIEW)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN FirebaseID COMMENT 'Firebase Cloud Messaging install ID issued by Google Firebase to the OneApp mobile app installation. Populated on 9.3M of 48M rows (19%). Used by eToro for push-notification targeting and as an additional mobile install identifier alongside AppsflyerID. (Tier 2 - Firebase platform standard; eToro usage)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN iOSAdTrackingPermissionID COMMENT 'iOS App Tracking Transparency (ATT) permission state, INT. Two observed values: 0 (46.7M, 97%) and 1 (1.3M, 3%). The 97/3 split matches the empirical iOS14.5 ATT-opt-out reality. Treat as a 2-state ATT-Authorized vs Not-Authorized flag rather than a 4-state Apple ATTrackingManager enum. (Tier 3 - observed values only; full enum NEEDS REVIEW)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN UpdatedAt COMMENT 'Timestamp of the last update to this bridge row. (Tier 3 - ETL metadata)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN AdditionalData COMMENT 'STRING populated on 1.0M of 48M rows (2%). Sparse free-form / structured payload added by the upstream marketperformance pipeline. Content schema NEEDS REVIEW before relying on it; treat as opaque until documented. (Tier 3 - sparse field; content NEEDS REVIEW)';
ALTER TABLE main.bi_db.bronze_marketperformance_tracking_customer ALTER COLUMN IDFV COMMENT 'Apple Identifier for Vendor. Unique per app vendor on a device, iOS-only. Populated on 1.4M of 48M rows (3%) - iOS users who registered via OneApp iOS. (Tier 1 - AppsFlyer field idfv)';

-- == LAST EXECUTION ==
-- Timestamp: 2026-06-10 13:03:19 UTC
-- Batch: appsflyer one-shot deploy (proposals/appsflyer_one_shot/deploy.py)
-- Statements: 13/13 succeeded
-- ====================
