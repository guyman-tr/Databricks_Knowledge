# DWH_dbo.Dim_CountryIPAnonymous

> Large anonymous/proxy IP range table (4.8M rows) from the IP2Location Anonymous IP database, mapping IP ranges to proxy type (VPN, TOR, DCH, etc.) and country. Used for fraud detection and risk scoring.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | IP2Location Anonymous IP database (via DWH_staging.IP2Location) |
| **Refresh** | Daily (SP_Dictionaries_Country_DL_To_Synapse, TRUNCATE+INSERT + CountryID UPDATE) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (IPFrom ASC, IPTo ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CountryIPAnonymous` is a 4.8-million-row IP range lookup table identifying anonymous traffic sources: VPNs, Tor exit nodes, public proxies, datacenter hosts, and search engine bots. Each row maps a range of IPv4 addresses to a 3-character proxy type code (ProxyType) and the card-issuing country. It is the sibling table to `Dim_CountryIP` (regular IP geolocation) but focused specifically on anonymizing/masking IP addresses.

This data feeds fraud detection: when a customer's IP matches a range in this table, it signals potentially anonymous access. The `ProxyType` code is propagated into `Fact_CustomerAction` by `SP_Fact_CustomerAction` to flag suspicious login/deposit events. `Dim_CountryIPAnonymousProxyType` provides human-readable descriptions and anonymity risk levels for each code.

The ETL (part of SP_Dictionaries_Country_DL_To_Synapse, which also loads Dim_Country) is:
1. TRUNCATE + INSERT from `DWH_staging.IP2Location` (external IP2Location database)
2. UPDATE to resolve CountryID from Dim_Country via `b.Abbreviation = a.CountryCode`

The staging source uses snake_case column names (ip_from, ip_to, proxy_type, country_code, country_name) - all renamed in DWH.

---

## 2. Business Logic

### 2.1 Anonymous IP Detection

**What**: IP range lookup identifies whether a customer is connecting through an anonymizing service.

**Columns Involved**: `IPFrom`, `IPTo`, `ProxyType`, `CountryID`

**Rules**:
- Lookup: `WHERE @IPInteger BETWEEN IPFrom AND IPTo`
- ProxyType codes (from Dim_CountryIPAnonymousProxyType):
  - DCH (Data Center/Hosting, Low anonymity): 2.7M rows (56% of table) - benign but monitored
  - PUB (Public Proxy, High anonymity): 1.7M rows (36%) - elevated fraud risk
  - VPN (VPN service, High anonymity): 335K rows (7%) - elevated fraud risk
  - SES (Search Engine Spider, Low anonymity): 37K rows (1%) - benign
  - WEB (Web proxy, High anonymity): 1K rows (<1%)
  - TOR (Tor exit node, High anonymity): 456 rows (<1%) - highest fraud risk
- High-anonymity proxy types (PUB, VPN, WEB, TOR) are fraud signals during deposit or login
- DCH and SES are Low-anonymity (datacenter and crawlers) - less concerning

### 2.2 Namibia NULL Guard

**What**: The ISO alpha-2 code for Namibia is "NA" which SQL reads as NULL. The ETL explicitly guards against this.

**Columns Involved**: `CountryCode`

**Rules**:
- `isnull([country_code], 'NA')` in SP: if country_code IS NULL in IP2Location source, it is set to 'NA' (Namibia's ISO code)
- This is intentional per the SP comment: `--Namibia`
- Without this guard, NULL country_code rows would silently drop Namibia's proxy ranges

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE at 4.8M rows is borderline large. The CLUSTERED INDEX on (IPFrom, IPTo) is appropriate for range lookups. JOIN to this table from fact tables should filter by IP before scanning.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED). Z-ORDER BY IPFrom for efficient range lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Check if an IP is from a proxy | `WHERE @ip BETWEEN IPFrom AND IPTo` |
| Count proxy events by type | `JOIN Dim_CountryIPAnonymousProxyType ON ProxyType` |
| High-risk proxy countries | `WHERE ProxyType IN ('VPN','TOR','PUB') GROUP BY CountryID` |

### 3.3 Gotchas

- CountryCode is ISO alpha-2 (e.g., "AU", "JP") but CountryID is the DWH integer ID from Dim_Country. Both are present - use CountryID for DWH JOINs.
- CountryCode='NA' ambiguity: could be Namibia (intentional via NULL guard) or genuinely unresolved. Check CountryID - if NULL, the code didn't match any Dim_Country row.
- No primary key defined in DWH DDL. BinCode uniqueness is not enforced. The IP2Location source may have overlapping ranges for different proxy types.
- ProxyType joins to `Dim_CountryIPAnonymousProxyType` for full descriptions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | IPFrom | bigint | YES | Start of the IP address range as a bigint integer (IPv4: octet1*16777216 + octet2*65536 + octet3*256 + octet4). Clustered index key. Source column: `ip_from` (rename). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 2 | IPTo | bigint | YES | End of the IP address range as a bigint integer. Clustered index key. Source column: `ip_to` (rename). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 3 | ProxyType | varchar(3) | YES | 3-character IP2Location proxy type code. Values: DCH (Data Center/Hosting, 56%), PUB (Public Proxy, 36%), VPN (7%), SES (Search Engine Bot, 1%), WEB (<1%), TOR (<1%). Join to Dim_CountryIPAnonymousProxyType for full descriptions. Source column: `proxy_type` (rename). (Tier 3 - Dim_CountryIPAnonymousProxyType wiki + live data) |
| 4 | CountryCode | varchar(50) | YES | ISO 3166-1 alpha-2 country code from IP2Location. Source: `ISNULL(country_code, 'NA')` — NULLs are replaced with 'NA', which is Namibia's ISO code, so unknown-country IPs will masquerade as Namibia. Used to resolve CountryID via JOIN to Dim_Country.Abbreviation. |
| 5 | CountryName | varchar(500) | YES | Full country name as provided by IP2Location (e.g., "Australia", "Japan"). Informational. May differ from Dim_Country.Name in some edge cases. Source column: `country_name` (rename). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 6 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload. Reflects ETL run time, not source data freshness. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 7 | CountryID | int | YES | DWH integer country ID, resolved via UPDATE: `JOIN Dim_Country ON Dim_Country.Abbreviation = CountryCode`. NULL when CountryCode does not match any Dim_Country.Abbreviation. Not in the initial INSERT - populated by a subsequent UPDATE in the same SP. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| IPFrom | IP2Location Anonymous IP database | ip_from | rename |
| IPTo | IP2Location Anonymous IP database | ip_to | rename |
| ProxyType | IP2Location Anonymous IP database | proxy_type | rename |
| CountryCode | IP2Location Anonymous IP database | country_code | rename + NULL guard (ISNULL(country_code,'NA')) |
| CountryName | IP2Location Anonymous IP database | country_name | rename |
| UpdateDate | - | - | ETL-computed (GETDATE()) |
| CountryID | DWH_dbo.Dim_Country | CountryID | UPDATE-patch: JOIN on Dim_Country.Abbreviation = CountryCode |

### 5.2 ETL Pipeline

```
IP2Location Anonymous IP database (external commercial data provider)
  -> [Generic Pipeline or direct load]
  -> DWH_staging.IP2Location (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse
    -> TRUNCATE + INSERT (6 columns from staging)
    -> UPDATE: resolve CountryID from DWH_dbo.Dim_Country via Abbreviation match
  -> DWH_dbo.Dim_CountryIPAnonymous (4.8M rows)
```

Note: SP_Dictionaries_Country_DL_To_Synapse loads both Dim_Country AND Dim_CountryIPAnonymous in the same execution. Dim_Country must be loaded first since CountryID resolution depends on it.

| Step | Object | Description |
|------|--------|-------------|
| Source | IP2Location Anonymous IP | Commercial GeoIP/proxy database. Updated externally by IP2Location. |
| Staging | DWH_staging.IP2Location | Raw staging: snake_case column names (ip_from, ip_to, proxy_type, country_code, country_name). |
| ETL | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse | TRUNCATE + INSERT with column renames and NULL guard on country_code. Then UPDATE to set CountryID. |
| Target | DWH_dbo.Dim_CountryIPAnonymous | Final DWH anonymous IP lookup (4.8M rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country of the IP range. Resolved via Abbreviation match. Implicit FK. |
| ProxyType | DWH_dbo.Dim_CountryIPAnonymousProxyType | Lookup for proxy type descriptions and anonymity levels. Implicit FK on ProxyType. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_CustomerAction | IPFrom/IPTo/ProxyType | CustomerAction ETL joins this table to flag anonymous IPs and propagate ProxyType to Fact_CustomerAction. [UNVERIFIED - inferred from Dim_CountryIPAnonymousProxyType wiki description] |

---

## 7. Sample Queries

### 7.1 Check if an IP is from a proxy
```sql
DECLARE @ip bigint = 16777216; -- 1.0.0.0
SELECT a.ProxyType, a.CountryName, a.CountryID, p.ProxyTypeDescription, p.Anonymity
FROM [DWH_dbo].[Dim_CountryIPAnonymous] a
JOIN [DWH_dbo].[Dim_CountryIPAnonymousProxyType] p ON a.ProxyType = p.ProxyType
WHERE @ip BETWEEN a.IPFrom AND a.IPTo;
```

### 7.2 Proxy type distribution
```sql
SELECT a.ProxyType, p.ProxyTypeDescription, p.Anonymity, COUNT(*) AS RangeCount
FROM [DWH_dbo].[Dim_CountryIPAnonymous] a
JOIN [DWH_dbo].[Dim_CountryIPAnonymousProxyType] p ON a.ProxyType = p.ProxyType
GROUP BY a.ProxyType, p.ProxyTypeDescription, p.Anonymity
ORDER BY RangeCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.

---

*Generated: 2026-03-19 | Quality: 7.8/10 (3 stars) | Phases: 8/14 (no Atlassian)*
*Tiers: 0 T1, 6 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10*
*Object: DWH_dbo.Dim_CountryIPAnonymous | Type: Table | Production Source: IP2Location Anonymous IP database*
