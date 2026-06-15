-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_recurringinvestment_dictionary_orderstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.OrderStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_orderstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the order status. 1=Received, 2=Placed, 3=Filled, 4=Rejected, 5=PartiallyFilled, 6=PendingCancel, 7=Canceled, 8=Expired, 9=CanceledPartiallyFilled, 10=RejectedPartiallyFilled, 11=WaitingForMarket. See [Order Status](../../_glossary.md#order-status).';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_orderstatus ALTER COLUMN OrderStatus COMMENT 'Human-readable label for the order lifecycle state. Aligns with Trading API enum values (per Confluence).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:29 UTC
-- Statements: 2/2 succeeded
-- ====================
