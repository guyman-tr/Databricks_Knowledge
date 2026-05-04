-- ============================================================================
-- main.bizops_output.bizops_output_spaceship_dim_customers  —  P6 UC ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/spaceship/schemas/bizops_output/Tables/bizops_output_spaceship_dim_customers.md
-- Tier source:  T4 (sample-anchored). Permitted under the framework's T4-deploy
--               rule when wording is fully grounded in [uc_sample] evidence.
-- ============================================================================

COMMENT ON TABLE main.bizops_output.bizops_output_spaceship_dim_customers IS
'BizOps-output bridge dim mapping eToro GCID to Spaceship contact identity (Spaceship_Contact_ID UUID + Salesforce account_id) for every customer linked across the two systems. Granularity: one row per linked customer (GCID-keyed). Read by SFDC sync jobs and BizOps reporting that need both identity spaces in one row. Pairs with bizops_output_spaceship_fact_customer_products (GCID + product grain) and bizops_output_spaceship_gold_daily_update (denormalised join). [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_dim_customers ALTER COLUMN GCID COMMENT
'eToro Global Customer ID. FK to main.bi_db.gold_sub_accounts_accounts.gcid. Primary key for this bridge dim. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_dim_customers ALTER COLUMN Connected_Spaceship_Customer COMMENT
'TRUE when this GCID has been linked to a Spaceship contact via the cross-sell bridge. Always TRUE in observed samples. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_dim_customers ALTER COLUMN Spaceship_Contact_ID COMMENT
'Spaceship contact UUID v4. FK to main.spaceship.bronze_spaceship_metabase_contact.user_id. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_dim_customers ALTER COLUMN account_id COMMENT
'Salesforce account_id (18-char SFDC format). FK to SFDC Account.Id. Used by BizOps SFDC sync as the customer-side join key. [uc_sample]';

ALTER TABLE main.bizops_output.bizops_output_spaceship_dim_customers ALTER COLUMN UpdateDate COMMENT
'Snapshot refresh timestamp (UTC, microsecond precision). All rows in a refresh share the same UpdateDate. [uc_sample]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 12:57:19 UTC
-- Batch deploy resume: bizops_output deploy batch 2
-- Statements: 0/6 succeeded
-- Error: PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_dim_customers'.
-- ====================
