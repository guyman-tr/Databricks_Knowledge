-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateClicks.ClicksImpressionsAggregation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateClicks/Tables/AffiliateClicks.ClicksImpressionsAggregation.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation (business_group=general) ----
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation SET TBLPROPERTIES (
    'comment' = 'Primary storage for daily aggregated click and impression counts on affiliate tracking links, partitioned by affiliate ID for efficient querying and used for admin and portal reporting dashboards. Source: fiktivo.AffiliateClicks.ClicksImpressionsAggregation on the fiktivo production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateClicks/Tables/AffiliateClicks.ClicksImpressionsAggregation.md).'
);

ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateClicks',
    'source_table' = 'ClicksImpressionsAggregation',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN AffiliateID COMMENT 'Affiliate identifier. Identifies which affiliate partner''s tracking link generated the clicks/impressions. Part of the 6-column deduplication key. Source of the partition column (AffiliateID % 100). Maps to AffiliateAdmin.Affiliates. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN PartitionCol100 COMMENT 'Persisted computed column: AffiliateID modulo 100. Partition column for the PS_Mod100 scheme. Distributes data across 100 partitions for parallel query execution. Included in both indexes for partition elimination. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN UpdateDate COMMENT 'Date of the aggregation period (24-hour daily resolution per Confluence). All clicks and impressions for the same key combination on this date are summed into one row. Leading column of the clustered index for efficient date-range queries and purge operations. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN BannerID COMMENT 'Marketing banner/creative identifier. Identifies which specific ad creative was clicked or viewed. Part of the 6-column deduplication key. Maps to AffiliateAdmin.Banners. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN Campaign COMMENT 'Affiliate marketing campaign tracking tag. Free-text identifier set by the affiliate in their tracking URL. Part of the deduplication key. May contain encoded tracking parameters (e.g., "AFFID_117443_AffwizclickIDxxxx_yy"). (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN CountryID COMMENT 'Country identifier of the user who clicked/viewed. 0 = unknown or unresolved country. Used for geographic segmentation of affiliate traffic. Maps to Dictionary.Country. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN ClicksCount COMMENT 'Total number of clicks on the affiliate tracking link for this aggregation key on this date. A click represents a user actively following the tracking link. Per Confluence: counted by the aff-clicksimp service. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN ImpressionsCount COMMENT 'Total number of impressions (views) of the affiliate banner/link for this aggregation key on this date. An impression represents the ad being displayed, whether or not the user clicked. Per Confluence: counted by the aff-clicksimp service. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
ALTER TABLE main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation ALTER COLUMN AdditionalData COMMENT 'Additional tracking metadata associated with the click/impression event. Free-text field for extensible tracking parameters. Part of the deduplication key. Added in PART-3693 (Nov 2024). Default is empty string. (Tier 1 - upstream wiki, fiktivo.AffiliateClicks.ClicksImpressionsAggregation)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
