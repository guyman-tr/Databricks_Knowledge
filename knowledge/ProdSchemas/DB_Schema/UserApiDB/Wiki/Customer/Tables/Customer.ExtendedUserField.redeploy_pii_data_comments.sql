-- =============================================================================
-- Redeploy: column comments for main.pii_data.bronze_userapidb_customer_extendeduserfield
-- Reason: UC drift — partial overwrite after 2026-05-03 batch deploy left FieldId/Value
--         empty and mixed History-table comments on current-state columns.
-- Source: Customer.ExtendedUserField.alter.sql lines 31-38 (unchanged canonical text)
-- Executed: 2026-06-23 via Databricks MCP (user-databricks_sql)
-- Siblings unchanged: compliance masked + history tables were already correct.
-- =============================================================================

ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN GCID COMMENT 'Part of unique clustered key. Global Customer ID. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN FieldId COMMENT 'Part of unique clustered key. FK to Dictionary.ExtendedUserField. Identifies which field: 0=province, 6=TaxId, 7=NationalPin, etc. See Extended User Field. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN Value COMMENT 'The user-provided value for this field (e.g., the actual tax number, national PIN). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN LastModified COMMENT 'When this field value was last updated. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN TypeId COMMENT 'Value subtype. Maps to Dictionary.ExtendedUserValueType for further classification (e.g., which specific type of tax ID). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN ID COMMENT 'Surrogate PK (NONCLUSTERED). Auto-incrementing. Used for row identification. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN CountryId COMMENT 'Part of unique clustered key. Country context for this field value. Allows per-country field values. (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.pii_data.bronze_userapidb_customer_extendeduserfield ALTER COLUMN AdditionalDetails COMMENT 'JSON or freeform additional data (e.g., document details, validation metadata). (Tier 1 - upstream wiki, UserApiDB.Customer.ExtendedUserField)';
