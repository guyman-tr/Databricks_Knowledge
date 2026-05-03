-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_AffiliateTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliateTypes.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes SET TBLPROPERTIES (
    'comment' = 'Commission plan templates that define how affiliates earn money - which event types trigger commissions, rate structures across up to 5 tiers, slab-based pricing, payout thresholds, and what data affiliates can see. Source: fiktivo.dbo.tblaff_AffiliateTypes on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliateTypes.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_AffiliateTypes',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AffiliateTypeID COMMENT 'Primary key. Identifies the commission plan. Referenced by tblaff_Affiliates.AffiliateTypeID, tblaff_AffiliateTypeCategories.AffiliateTypeID, tblaff_Announcement_AffiliateType.AffiliateTypeID, tblaff_Country.AffiliateTypeID, tblaff_CPACountriesToAffiliateTypeID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN Description COMMENT 'Human-readable plan name (e.g., "RevShare 25%", "CPL $2", "CPA $300"). Shown in admin UI and affiliate dashboards. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN Notes COMMENT 'Internal notes about the commission plan for admin reference. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN Tiers COMMENT 'Number of hierarchical tiers (1-5). Tier 1 = direct affiliate. Tiers 2-5 = sub-affiliates who referred the tier-1 affiliate. Default 1 = single tier (no sub-affiliate commissions). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN TierType COMMENT 'Controls how tier commissions are calculated. 0 = standard tier calculation. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerDeposit COMMENT 'Enables deposit-based commissions. 1 = affiliates earn when referred customers deposit funds. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerSale COMMENT 'Enables sale/trading activity commissions. 1 = affiliates earn from trading revenue. Default ON - most plans include sale commissions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerLead COMMENT 'Enables lead/download commissions. 1 = affiliates earn per qualified lead. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerRegistration COMMENT 'Enables registration commissions. 1 = affiliates earn per customer registration. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerClick COMMENT 'Enables click-based commissions. 1 = affiliates earn per click on tracking links. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN FlatRateOrPercentOfSale COMMENT 'Commission calculation mode for sales. 0 = percentage of sale revenue (RevShare). 1 = flat rate per sale (CPA-style). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CPAOrCPAD COMMENT 'CPA model selector. 0 = standard CPA (cost per acquisition). 1 = CPAD (CPA with deposit requirement - only pays when customer also deposits). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerDepositRate COMMENT 'Tier 1 deposit commission rate. Percentage or flat amount depending on FlatRateOrPercentOfSale. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerDepositRate2 COMMENT 'Tier 2 deposit commission rate for sub-affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerDepositRate3 COMMENT 'Tier 3 deposit commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerDepositRate4 COMMENT 'Tier 4 deposit commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerDepositRate5 COMMENT 'Tier 5 deposit commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerSaleRate COMMENT 'Tier 1 sale commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerSaleRate2 COMMENT 'Tier 2 sale commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerSaleRate3 COMMENT 'Tier 3 sale commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerSaleRate4 COMMENT 'Tier 4 sale commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerSaleRate5 COMMENT 'Tier 5 sale commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerLeadRate COMMENT 'Tier 1 lead commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerLeadRate2 COMMENT 'Tier 2 lead commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerLeadRate3 COMMENT 'Tier 3 lead commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerLeadRate4 COMMENT 'Tier 4 lead commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerLeadRate5 COMMENT 'Tier 5 lead commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerRegistrationRate COMMENT 'Tier 1 registration commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerRegistrationRate2 COMMENT 'Tier 2 registration commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerRegistrationRate3 COMMENT 'Tier 3 registration commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerRegistrationRate4 COMMENT 'Tier 4 registration commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerRegistrationRate5 COMMENT 'Tier 5 registration commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerClickRate COMMENT 'Tier 1 click commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerClickRate2 COMMENT 'Tier 2 click commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerClickRate3 COMMENT 'Tier 3 click commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerClickRate4 COMMENT 'Tier 4 click commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerClickRate5 COMMENT 'Tier 5 click commission rate. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AutomaticallyAcceptSales COMMENT 'Auto-approval for sale events. 1 = sale commissions are automatically accepted without manual review. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AutomaticallyAcceptLeads COMMENT 'Auto-approval for lead events. 1 = lead commissions are automatically accepted. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowDepositDetail COMMENT 'Affiliate portal: show detailed deposit event data to affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSalesDetail COMMENT 'Affiliate portal: show detailed sale event data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowPendingSalesCount COMMENT 'Affiliate portal: show count of pending (unprocessed) sale events. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowTieredAffiliateCount COMMENT 'Affiliate portal: show count of sub-affiliates in the hierarchy. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowTieredAffiliateDetail COMMENT 'Affiliate portal: show detailed sub-affiliate information. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CookieExpiration COMMENT 'Attribution cookie lifetime in days. Default 30 days. Determines how long after a click the affiliate can be credited for a conversion. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN MinimumPayout COMMENT 'Minimum accumulated commission balance (in USD) before payment is generated. $99,999,999 for internal plans prevents payouts. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowLeadDetail COMMENT 'Affiliate portal: show detailed lead event data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowPendingLeadCount COMMENT 'Affiliate portal: show count of pending lead events. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSaleOptional1 COMMENT 'Affiliate portal: show Optional1 field in sale detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSaleOptional2 COMMENT 'Affiliate portal: show Optional2 field in sale detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSaleOptional3 COMMENT 'Affiliate portal: show Optional3 field in sale detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSaleAmount COMMENT 'Affiliate portal: show sale amount in detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSaleOrderNumber COMMENT 'Affiliate portal: show order number in sale detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowSaleCountry COMMENT 'Affiliate portal: show customer country in sale detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowLeadNumber COMMENT 'Affiliate portal: show lead number in detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowLeadOptional1 COMMENT 'Affiliate portal: show Optional1 field in lead detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowLeadOptional2 COMMENT 'Affiliate portal: show Optional2 field in lead detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowLeadOptional3 COMMENT 'Affiliate portal: show Optional3 field in lead detail view. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositCommission1BonusType COMMENT 'Bonus structure type for deposit commission tier 1. Controls how the bonus is calculated. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositCommission1BonusAmount COMMENT 'Bonus amount for deposit commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositCommission1BonusThreshold COMMENT 'Volume threshold that must be reached before the deposit bonus tier 1 activates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositCommission2BonusType COMMENT 'Bonus structure type for deposit commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositCommission2BonusAmount COMMENT 'Bonus amount for deposit commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositCommission2BonusThreshold COMMENT 'Volume threshold for deposit bonus tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleCommission1BonusType COMMENT 'Bonus structure type for sale commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleCommission1BonusAmount COMMENT 'Bonus amount for sale commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleCommission1BonusThreshold COMMENT 'Volume threshold for sale bonus tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleCommission2BonusType COMMENT 'Bonus structure type for sale commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleCommission2BonusAmount COMMENT 'Bonus amount for sale commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleCommission2BonusThreshold COMMENT 'Volume threshold for sale bonus tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadCommission1BonusType COMMENT 'Bonus structure type for lead commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadCommission1BonusAmount COMMENT 'Bonus amount for lead commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadCommission1BonusThreshold COMMENT 'Volume threshold for lead bonus tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadCommission2BonusType COMMENT 'Bonus structure type for lead commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadCommission2BonusAmount COMMENT 'Bonus amount for lead commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadCommission2BonusThreshold COMMENT 'Volume threshold for lead bonus tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ClickCommission1BonusType COMMENT 'Bonus structure type for click commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ClickCommission1BonusAmount COMMENT 'Bonus amount for click commission tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ClickCommission1BonusThreshold COMMENT 'Volume threshold for click bonus tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ClickCommission2BonusType COMMENT 'Bonus structure type for click commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ClickCommission2BonusAmount COMMENT 'Bonus amount for click commission tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ClickCommission2BonusThreshold COMMENT 'Volume threshold for click bonus tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DeleteCookieAfterSale COMMENT 'Cookie behavior: delete attribution cookie after a sale event fires. 1 = one-time attribution per sale. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DeleteCookieAfterLead COMMENT 'Cookie behavior: delete attribution cookie after a lead event fires. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DeleteCookieAfterClick COMMENT 'Cookie behavior: delete attribution cookie after a click event. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ShowCreateALinkOption COMMENT 'Affiliate portal: show the "Create a Link" tool allowing affiliates to generate custom tracking URLs. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AllTiersRate2 COMMENT 'Override rate for all commission types at tier 2 (cross-event tier-2 rate). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AllTiersRate3 COMMENT 'Override rate for all commission types at tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AllTiersRate4 COMMENT 'Override rate for all commission types at tier 4. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN AllTiersRate5 COMMENT 'Override rate for all commission types at tier 5. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab1To COMMENT 'Upper boundary of deposit slab tier 1 (e.g., up to $1,000). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab2To COMMENT 'Upper boundary of deposit slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab3To COMMENT 'Upper boundary of deposit slab tier 3. Volume above this falls in tier 4. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab1Amount COMMENT 'Commission amount/rate for deposit slab tier 1 (lowest volume). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab2Amount COMMENT 'Commission amount/rate for deposit slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab3Amount COMMENT 'Commission amount/rate for deposit slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN DepositSlab4Amount COMMENT 'Commission amount/rate for deposit slab tier 4 (highest volume, uncapped). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab1To COMMENT 'Upper boundary of sale slab tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab2To COMMENT 'Upper boundary of sale slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab3To COMMENT 'Upper boundary of sale slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab1Percent COMMENT 'Commission percentage for sale slab tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab2Percent COMMENT 'Commission percentage for sale slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab3Percent COMMENT 'Commission percentage for sale slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN SaleSlab4Percent COMMENT 'Commission percentage for sale slab tier 4 (highest volume). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CPADPercent COMMENT 'Additional percentage applied under the CPAD (CPA with deposit) model when CPAOrCPAD=1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab1To COMMENT 'Upper boundary of PnL slab tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab2To COMMENT 'Upper boundary of PnL slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab3To COMMENT 'Upper boundary of PnL slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab1Percent COMMENT 'Commission percentage for PnL slab tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab2Percent COMMENT 'Commission percentage for PnL slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab3Percent COMMENT 'Commission percentage for PnL slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PNLSlab4Percent COMMENT 'Commission percentage for PnL slab tier 4. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerPNL COMMENT 'Enables PnL-based commissions. 1 = affiliates earn from customer profit and loss. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN LeadPerCountry COMMENT 'Enables country-specific lead rates. 1 = different lead commission rates per country (uses tblaff_CPACountriesToAffiliateTypeID). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN RegistrationPerCountry COMMENT 'Enables country-specific registration rates. 1 = different registration rates per country. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerCopyTrader COMMENT 'Enables copy trader commissions. 1 = affiliates earn when referred customers use CopyTrader. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab1To COMMENT 'Upper boundary of copy trader slab tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab2To COMMENT 'Upper boundary of copy trader slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab3To COMMENT 'Upper boundary of copy trader slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab1Amount COMMENT 'Commission amount for copy trader slab tier 1. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab2Amount COMMENT 'Commission amount for copy trader slab tier 2. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab3Amount COMMENT 'Commission amount for copy trader slab tier 3. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CopyTraderSlab4Amount COMMENT 'Commission amount for copy trader slab tier 4 (highest volume). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerFirstPosition COMMENT 'Enables first-position commissions. 1 = affiliates earn when referred customers open their first trading position. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN PerFirstPositionRate COMMENT 'Commission rate for first position events. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN FatherAffiliateTypeID COMMENT 'Self-referencing FK to parent affiliate type. Enables plan hierarchy/inheritance. NULL = top-level plan. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN IsActive COMMENT 'Whether this plan is available for assignment. NULL/0 = inactive/archived, 1 = active and assignable. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN MinimumCommission COMMENT 'Minimum commission amount per event. Events below this threshold may not generate commissions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN Trace COMMENT 'Computed audit column. JSON with session metadata (HostName, AppName, SUserName, SPID, DBName, ObjectName). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ValidFrom COMMENT 'System-versioning period start. Hidden. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN ValidTo COMMENT 'System-versioning period end. Hidden. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN CommissionByOpenPosition COMMENT 'Enables commission calculation based on open (active) positions rather than closed/completed trades. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN IsTradeRequired COMMENT 'Whether a customer must complete a trade before the affiliate earns commission. 1 = trade required for CPA qualification. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN BlockTrackingLinks COMMENT 'Controls whether tracking links are blocked for this affiliate type. 0 = allowed, >0 = blocked. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes ALTER COLUMN BlockCreatives COMMENT 'Controls whether creative/banner assets are blocked for this affiliate type. 0 = allowed, >0 = blocked. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliateTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
