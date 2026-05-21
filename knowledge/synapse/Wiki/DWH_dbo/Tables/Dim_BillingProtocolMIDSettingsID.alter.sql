-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_BillingProtocolMIDSettingsID
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Surrogate primary key. Renamed from `ID` in the production Billing.ProtocolMIDSettings table. Referenced by fact deposit and withdrawal tables to record which routing configuration was used per transaction. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN ParameterID COMMENT 'Protocol parameter type. Part of logical routing key. References Billing.Parameter which defines the parameter name/type (e.g., MID, SecretKey, ApiKey). Together with DepotID, DepotModeID, RegulationID, CurrencyID forms the unique routing key. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN DepotID COMMENT 'Payment gateway/depot. Part of logical routing key. References Billing.Depot (DWH: Dim_BillingDepot.DepotID). Identifies the payment processor this MID configuration belongs to. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN DepotModeID COMMENT 'Trading mode. Part of logical routing key. 0=General (applies to both), 1=Live, 2=Demo. Separates Live and Demo payment processing environments. ~60% Demo, ~37% Live. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN Value COMMENT 'The protocol identifier string (MID, merchant ID, API key, etc.). This is the actual routing value passed to the payment processor. Examples: "18989693", "18986763" (Tier 1 - Billing.ProtocolMIDSettings.md)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN RegulationID COMMENT 'Regulatory entity. Part of logical routing key. Segments MIDs by legal jurisdiction: 0=None, 1=CySEC (EU), 2=FCA (UK), plus additional ASIC/other values. Ensures transactions route through the correct legal entity''s acquiring relationship. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN CurrencyID COMMENT 'Currency restriction. Part of logical routing key. 0=any currency (most rows). Non-zero values restrict this MID entry to a specific transaction currency. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN Description COMMENT 'Human-readable description of this MID entry (e.g., processor name, account identifier). Nullable; not all rows have a description. (Tier 3 - name-inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN SubTypeID COMMENT 'Sub-routing type. 0=default routing (~94% of rows); 3=alternate sub-routing for specific processor subsets (~6% of rows). Allows multiple routing paths within the same (depot, mode, regulation, currency). (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN MerchantAccountID COMMENT 'Optional link to a merchant account defined in Billing.MerchantAccountRouting (the master routing table; Billing.MerchantAccountValues stores parameter values for those accounts). When set (~25% of rows), enables finer-grained routing to a specific acquiring account within a depot. NULL when not applicable.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Monitor for freshness -- live data as of 2026-03-18 shows last load was 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN ProtocolMIDSettingsID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN ParameterID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN DepotID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN DepotModeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN Value SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN Description SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN SubTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN MerchantAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_billingprotocolmidsettingsid ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

