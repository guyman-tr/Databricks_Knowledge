-- =============================================================================
-- ALTER Script: DWH_dbo.Dim_CountryIPAnonymousProxyType
-- UC Target:    Not in Generic Pipeline mapping — not exported to Gold/UC
-- Resolution:   Wiki property table
-- Generated:    2026-03-22
-- Source Wiki:   knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CountryIPAnonymousProxyType.md
-- Quality:      7.8/10
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. TABLE COMMENT
-- ---------------------------------------------------------------------------
ALTER TABLE Not in Generic Pipeline mapping — not exported to Gold/UC
SET TBLPROPERTIES (
    'comment' = '`Dim_CountryIPAnonymousProxyType` is a reference lookup dimension containing the 6 proxy type codes used by IP2Location''s Anonymous IP database to classify anonymous internet traffic. Each row defines a proxy category — from datacenter hosting providers (DCH) to Tor exit nodes (TOR) and VPN services (VPN) — along with a detailed description and an anonymity level (High or Low). This table serves as the reference taxonomy for the `ProxyType` column in `Dim_CountryIPAnonymous`. The ETL pipeline `SP_Dictionaries_Country_DL_To_Synapse` loads raw ProxyType codes (e.g., "VPN", "TOR") into `Dim_CountryIPAnonymous`, and `SP_Fact_CustomerAction` then propagates the ProxyType code into `Fact_CustomerAction` when an IP address matches an anonymous range. Analysts can JOIN this table to decode the 3-char code into a human-readable description and anonymity level. The table was loaded manually from IP2Location documentation and is frozen — UpdateDate is NULL for all 6 rows. No active ETL exists to refresh it. This is a...'
);

-- ---------------------------------------------------------------------------
-- 2. TABLE TAGS
-- ---------------------------------------------------------------------------
ALTER TABLE Not in Generic Pipeline mapping — not exported to Gold/UC
SET TAGS (
    'domain' = 'DWH',
    'object_type' = 'Table',
    'synapse_schema' = 'DWH_dbo',
    'synapse_object_name' = 'Dim_CountryIPAnonymousProxyType',
    'refresh_frequency' = 'None — static reference table, no active ETL',
    'source_system' = 'IP2Location Anonymous IP database (external reference documentation — static load)',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ProxyType ASC)',
    'uc_format' = '_Pending — resolved during write-objects_',
    'pipeline' = 'Generic Pipeline (daily export)',
    'semantic_grade' = '7.8',
    'semantic_wiki' = 'DWH_dbo/Tables/Dim_CountryIPAnonymousProxyType.md'
);

-- ---------------------------------------------------------------------------
-- 3. COLUMN COMMENTS
-- ---------------------------------------------------------------------------

ALTER TABLE Not in Generic Pipeline mapping — not exported to Gold/UC
ALTER COLUMN ProxyType COMMENT 'Primary key — 3-character IP2Location proxy type code. Values: DCH (Data Center/CDN), PUB (Public Proxy), SES (Search Engine Bot), TOR (Tor Exit Node), VPN (Anonymizing VPN), WEB (Web Proxy). Used as the JOIN key to decode proxy codes in Dim_CountryIPAnonymous and Fact_CustomerAction. (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType)';

ALTER TABLE Not in Generic Pipeline mapping — not exported to Gold/UC
ALTER COLUMN ProxyTypeDescription COMMENT 'Full IP2Location description of the proxy type category. Human-readable explanation suitable for reports and documentation. (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType)';

ALTER TABLE Not in Generic Pipeline mapping — not exported to Gold/UC
ALTER COLUMN Anonymity COMMENT 'IP2Location anonymity risk level for this proxy type: "High" (PUB, TOR, VPN, WEB — user IP is hidden) or "Low" (DCH, SES — may anonymize but commonly benign). Use for fraud/risk segmentation. (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType)';

ALTER TABLE Not in Generic Pipeline mapping — not exported to Gold/UC
ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp — always NULL (static reference table, no active ETL refresh). (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType)';

-- ---------------------------------------------------------------------------
-- 4. COLUMN PII TAGS
-- ---------------------------------------------------------------------------
-- No PII-sensitive columns detected for this object.

-- =============================================================================
-- END OF ALTER SCRIPT
-- =============================================================================
