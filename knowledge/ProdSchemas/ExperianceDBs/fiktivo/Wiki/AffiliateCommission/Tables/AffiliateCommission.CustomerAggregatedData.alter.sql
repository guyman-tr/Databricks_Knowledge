-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.CustomerAggregatedData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.CustomerAggregatedData.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata (business_group=general) ----
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata SET TBLPROPERTIES (
    'comment' = 'Aggregated trading activity summary per customer, tracking cumulative commission amounts and last position timestamps for fast reporting and commission eligibility checks. Source: fiktivo.AffiliateCommission.CustomerAggregatedData on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.CustomerAggregatedData.md).'
);

ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'CustomerAggregatedData',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN CID COMMENT 'Customer ID. PK. Uses int (vs bigint elsewhere) - earlier table design. One row per customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN TotalCommissionOnOpen COMMENT 'Cumulative commission earned from position opening events across all time. NULL when no open commissions have been recorded for this customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN TotalCommissionOnClose COMMENT 'Cumulative commission earned from position closing events across all time. Primary metric for affiliate commission reporting. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN LastClosedPosition COMMENT 'Timestamp of the customer''s most recent position close. NULL if the customer has never closed a position. Used for activity recency checks. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN LastOpenedPosition COMMENT 'Timestamp of the customer''s most recent position open. NULL if the customer has never opened a position. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN OpenedPositionsCommissionOnOpen COMMENT 'Current total commission on positions that are still open. Decreases as positions close (commission moves to TotalCommissionOnClose). NOT NULL - defaults to 0. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';
ALTER TABLE main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata ALTER COLUMN DateModified COMMENT 'Last time this aggregate was updated. NULL in most records observed, suggesting incremental update logic may not always set this field. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CustomerAggregatedData)';

