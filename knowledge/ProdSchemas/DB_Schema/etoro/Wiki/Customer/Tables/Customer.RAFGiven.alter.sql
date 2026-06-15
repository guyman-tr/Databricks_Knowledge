-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_etoro_customer_rafgiven  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.RAFGiven.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferringCID COMMENT 'The customer who made the referral (the inviter). Not a formal FK but references Customer.CustomerStatic. Validated via Customer.Customer.ReferralID check in SetRafCompensation. Part of UNIQUE constraint with ReferredCID. Indexed together for fast count queries during compensation checks.';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferredCID COMMENT 'The newly registered customer who was referred (the invitee). UNIQUE constraint (UQ_RAFGiven_ReferredCID) enforces one-referral-per-referred-customer. The pair (ReferredCID, ReferralID=ReferringCID) is validated in Customer.Customer before compensation is granted.';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN RowInserted COMMENT 'UTC timestamp when the RAF compensation was successfully processed and this record was inserted. Defaults to GETUTCDATE()-3ms (`DATEADD(MS, -3, GETUTCDATE())`) - the -3ms offset appears to be a workaround comment in SetRafCompensation ("make sure RowInserted is valid").';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ID COMMENT 'Surrogate PK. IDENTITY NOT FOR REPLICATION. Provides a unique row identifier and the clustered index key. Not meaningful for business logic (use ReferredCID or (ReferringCID, ReferredCID) for lookups).';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferringCompensationAmount COMMENT 'Dollar amount paid to the referring customer as RAF bonus. Stored as whole dollars (converted from cents by dividing @ReferringCompensationInCents/100 in SetRafCompensation). Max observed: $500. NULL if referring party received no compensation (ReferringCompensationInCents=0 path skips SetBalanceCompensation but still inserts).';
ALTER TABLE main.experience.bronze_etoro_customer_rafgiven ALTER COLUMN ReferredCompensationAmount COMMENT 'Dollar amount paid to the referred customer as RAF bonus. Stored as whole dollars. Max observed: $20. NULL if referred party received no compensation. Both compensation amounts are set via Customer.SetBalanceCompensation (BonusTypeID=53=Referring, BonusTypeID=54=Referred).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:14 UTC
-- Statements: 6/6 succeeded
-- ====================
