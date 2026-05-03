# BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext — Review Needed

## 1. Tier 3 — All Columns (External Data Source)

All 86 columns are classified as Tier 3. This table is a raw data landing zone for AppsFlyer's Raw Data Export API. No upstream wiki exists in the repository, and no stored procedure writes to this table — data is loaded externally. Column descriptions are grounded in DDL structure, live sample data, and the downstream SP_AppFlyer_Reports which reveals data quality patterns (e.g., 'None' string values, dirty timestamp data in contributor fields).

**Reviewer action**: If AppsFlyer API documentation or an internal data dictionary for this feed exists, column descriptions can be upgraded to Tier 1 by referencing that documentation.

## 2. Data Quality Concerns

- **Contributor1TouchTime** may contain 'USD' or 'usd' instead of timestamps (observed in SP_AppFlyer_Reports CASE logic: `CASE WHEN [Contributor1TouchTime] IN ('None', 'USD','usd') THEN NULL`). This suggests upstream data quality issues in the AppsFlyer feed.
- **'None' string values**: Multiple columns use the string 'None' instead of SQL NULL for missing data. This is an AppsFlyer export convention, not a DWH issue.
- **CountryCode 'UK'**: Raw data uses 'UK' instead of ISO standard 'GB'. Normalized downstream but not in _Ext.

## 3. PII and Data Masking

- **City**: Dynamic data masking applied (`FUNCTION = 'default()'`). Non-privileged users see 'xxxx'.
- **IsReceiptValidated**: Dynamic data masking applied. Reason unclear — may contain receipt validation details considered sensitive.
- **IP**: Contains raw IPv4 addresses. No masking applied despite PII sensitivity.
- **CustomerUserID**: Contains hashed eToro user identifiers. Linkable to user accounts.
- **IMEI, IDFA, AdvertisingID, AndroidID, IDFV**: Device identifiers that may be subject to privacy regulations (GDPR, ATT).

**Reviewer action**: Confirm whether IP, CustomerUserID, and device identifier columns should also have data masking applied.

## 4. ETL Load Mechanism Unknown

The mechanism that loads data into _Ext is not visible in the SSDT codebase. No stored procedure writes to this table. Data likely arrives via an external pipeline (ADF, SSIS, or direct API integration). The load process that assigns DateID, Date, EtoroAppID, EtoroAppName, and EtoroReport is not documented in the repository.

**Reviewer action**: Identify and document the external load mechanism for this table.

## 5. Dormant/Active Status

The `_no_upstream_found.txt` marker is present, but the table contains 130.3M rows with data as recent as 2025-05-02 — the table is actively receiving data. The "no upstream" status refers to the lack of a resolvable wiki, not table activity.
