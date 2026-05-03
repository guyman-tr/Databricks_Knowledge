-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.RAFGiven
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.RAFGiven.md
-- Layer: bronze
-- UC Target: main.experience.bronze_etoro_customer_rafgiven
-- =============================================================================

-- ---- UC Target: main.experience.bronze_etoro_customer_rafgiven (business_group=experience) ----
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven SET TBLPROPERTIES (
    'comment' = 'Immutable record of confirmed Refer-A-Friend compensation events: one row per successful referral payout, recording the referring and referred customer pair plus the dollar amounts paid to each. Source: etoro.Customer.RAFGiven on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.RAFGiven.md).'
);

ALTER TABLE main.experience.bronze_etoro_customer_rafgiven SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'RAFGiven',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferringCID COMMENT 'The customer who made the referral (the inviter). Not a formal FK but references Customer.CustomerStatic. Validated via Customer.Customer.ReferralID check in SetRafCompensation. Part of UNIQUE constraint with ReferredCID. Indexed together for fast count queries during compensation checks. (Tier 1 - upstream wiki, etoro.Customer.RAFGiven)';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferredCID COMMENT 'The newly registered customer who was referred (the invitee). UNIQUE constraint (UQ_RAFGiven_ReferredCID) enforces one-referral-per-referred-customer. The pair (ReferredCID, ReferralID=ReferringCID) is validated in Customer.Customer before compensation is granted. (Tier 1 - upstream wiki, etoro.Customer.RAFGiven)';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN RowInserted COMMENT 'UTC timestamp when the RAF compensation was successfully processed and this record was inserted. Defaults to GETUTCDATE()-3ms (DATEADD(MS, -3, GETUTCDATE())) - the -3ms offset appears to be a workaround comment in SetRafCompensation ("make sure RowInserted is valid"). (Tier 1 - upstream wiki, etoro.Customer.RAFGiven)';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ID COMMENT 'Surrogate PK. IDENTITY NOT FOR REPLICATION. Provides a unique row identifier and the clustered index key. Not meaningful for business logic (use ReferredCID or (ReferringCID, ReferredCID) for lookups). (Tier 1 - upstream wiki, etoro.Customer.RAFGiven)';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferringCompensationAmount COMMENT 'Dollar amount paid to the referring customer as RAF bonus. Stored as whole dollars (converted from cents by dividing @ReferringCompensationInCents/100 in SetRafCompensation). Max observed: $500. NULL if referring party received no compensation (ReferringCompensationInCents=0 path skips SetBalanceCompensation but still inserts). (Tier 1 - upstream wiki, etoro.Customer.RAFGiven)';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferredCompensationAmount COMMENT 'Dollar amount paid to the referred customer as RAF bonus. Stored as whole dollars. Max observed: $20. NULL if referred party received no compensation. Both compensation amounts are set via Customer.SetBalanceCompensation (BonusTypeID=53=Referring, BonusTypeID=54=Referred). (Tier 1 - upstream wiki, etoro.Customer.RAFGiven)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
