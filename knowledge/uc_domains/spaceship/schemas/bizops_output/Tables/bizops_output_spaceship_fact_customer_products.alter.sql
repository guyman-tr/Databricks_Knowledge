-- ============================================================================
-- main.bizops_output.bizops_output_spaceship_fact_customer_products  —  P6 ALTER
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/spaceship/schemas/bizops_output/Tables/bizops_output_spaceship_fact_customer_products.md
-- Tier source:  T4 (sample-anchored).
-- ============================================================================

COMMENT ON TABLE main.bizops_output.bizops_output_spaceship_fact_customer_products IS
'BizOps-output fact holding the latest balance per (GCID, Spaceship_Product) for Spaceship customers linked to eToro. Granularity: one row per linked-customer x product. Product taxonomy is the BizOps customer-facing one (Voyager, US Investing, Available Money), NOT the technical taxonomy in v_spaceship_aum (Super, Voyager, Nova, Money). The exact mapping is unconfirmed — likely US Investing -> Nova, Available Money -> Money; Super is absent. Balance is assumed AUD (Spaceship home currency). Pairs with bizops_output_spaceship_dim_customers (one row per GCID) and bizops_output_spaceship_gold_daily_update (denormalised join). [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_fact_customer_products ALTER COLUMN GCID COMMENT
'eToro Global Customer ID. FK to main.bi_db.gold_sub_accounts_accounts.gcid. Composite PK with Spaceship_Product. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_fact_customer_products ALTER COLUMN Spaceship_Product COMMENT
'BizOps-facing product name. Values: Voyager (88), US Investing (28), Available Money (23). NOT identical to v_spaceship_aum''s Super/Voyager/Nova/Money taxonomy. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_fact_customer_products ALTER COLUMN Customer_Product_Internal_Unique_ID COMMENT
'Synthesized PK = ''{GCID}_{Spaceship_Product}''. E.g. ''45090849_Voyager''. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_fact_customer_products ALTER COLUMN Balance COMMENT
'Latest balance for this (GCID, Spaceship_Product), denominated in AUD (Spaceship''s home currency). May be 0.0 for customers enrolled in a product but holding no balance. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_fact_customer_products ALTER COLUMN UpdateDate COMMENT
'Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 12:57:21 UTC
-- Batch deploy resume: bizops_output deploy batch 2
-- Statements: 0/6 succeeded
-- Error: PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_fact_customer_products'.
-- ====================
