-- ============================================================================
-- main.bizops_output.bizops_output_spaceship_gold_daily_update  —  P6 ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/spaceship/schemas/bizops_output/Tables/bizops_output_spaceship_gold_daily_update.md
-- Tier source:  T4 (sample-anchored).
-- ============================================================================

COMMENT ON TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update IS
'BizOps-output denormalised gold table that joins dim_customers (GCID + Spaceship contact identity + SFDC account_id) with fact_customer_products (per-product balance) to produce a single row per (GCID, product), preserving linked customers with no active product (empty Spaceship_Product). This is the SFDC-sync feed for Spaceship customer/product data. Refreshed daily — filter by latest UpdateDate for the freshest snapshot. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN GCID COMMENT
'eToro Global Customer ID. FK to main.bi_db.gold_sub_accounts_accounts.gcid. PK component (composite with Spaceship_Product). [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN Connected_Spaceship_Customer COMMENT
'TRUE when this GCID is linked to a Spaceship contact. Always TRUE in observed samples (consistent with the dim_customers source). [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN Spaceship_Product COMMENT
'BizOps product name. Values: '''' (91, no product on file), Voyager (20), Available Money (4), US Investing (3). Empty string indicates a linked customer with no active product balance. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN Spaceship_Product_External_ID COMMENT
'Equals fact_customer_products.Customer_Product_Internal_Unique_ID, format ''{GCID}_{Spaceship_Product}''. NULL when no product (matches empty Spaceship_Product). [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN Balance COMMENT
'Balance from fact_customer_products in AUD. 0.0 for customers with no product. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN Spaceship_Contact_ID COMMENT
'Spaceship contact UUID v4 (from dim_customers). FK to main.spaceship.bronze_spaceship_metabase_contact.user_id. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN account_id COMMENT
'Salesforce 18-char account_id (from dim_customers). FK to SFDC Account.Id. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_gold_daily_update ALTER COLUMN UpdateDate COMMENT
'Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 12:57:24 UTC
-- Batch deploy resume: bizops_output deploy batch 2
-- Statements: 0/9 succeeded
-- Error: PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_gold_daily_update'.
-- ====================
