-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CountryIPAnonymous
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN IPFrom COMMENT 'Start of the IP address range as a bigint integer (IPv4: octet1*16777216 + octet2*65536 + octet3*256 + octet4). Clustered index key. Source column: `ip_from` (rename). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN IPTo COMMENT 'End of the IP address range as a bigint integer. Clustered index key. Source column: `ip_to` (rename). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN ProxyType COMMENT '3-character IP2Location proxy type code. Values: DCH (Data Center/Hosting, 56%), PUB (Public Proxy, 36%), VPN (7%), SES (Search Engine Bot, 1%), WEB (<1%), TOR (<1%). Join to Dim_CountryIPAnonymousProxyType for full descriptions. Source column: `proxy_type` (rename). (Tier 3 - Dim_CountryIPAnonymousProxyType wiki + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN CountryCode COMMENT 'ISO 3166-1 alpha-2 country code from IP2Location. Source: `ISNULL(country_code, ''NA'')` - NULLs are replaced with ''NA'', which is Namibia''s ISO code, so unknown-country IPs will masquerade as Namibia. Used to resolve CountryID via JOIN to Dim_Country.Abbreviation.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN CountryName COMMENT 'Full country name as provided by IP2Location (e.g., "Australia", "Japan"). Informational. May differ from Dim_Country.Name in some edge cases. Source column: `country_name` (rename). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload. Reflects ETL run time, not source data freshness. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN CountryID COMMENT 'DWH integer country ID, resolved via UPDATE: `JOIN Dim_Country ON Dim_Country.Abbreviation = CountryCode`. NULL when CountryCode does not match any Dim_Country.Abbreviation. Not in the initial INSERT - populated by a subsequent UPDATE in the same SP. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN IPFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN IPTo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN ProxyType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN CountryCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymous ALTER COLUMN CountryID SET TAGS ('pii' = 'none');

