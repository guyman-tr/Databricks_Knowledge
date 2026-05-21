# DWH_dbo.Dim_CountryIPAnonymousProxyType

> Static reference table from IP2Location's Anonymous IP database, mapping 3-character proxy type codes (DCH, TOR, VPN, etc.) to full descriptions and anonymity levels — used to classify anonymous IP addresses in `Dim_CountryIPAnonymous` and ultimately `Fact_CustomerAction`.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | IP2Location Anonymous IP database (external reference documentation — static load) |
| **Refresh** | None — static reference table, no active ETL |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ProxyType ASC) |
| | |
| **UC Target** | Not in Generic Pipeline mapping — not exported to Gold/UC |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CountryIPAnonymousProxyType` is a reference lookup dimension containing the 6 proxy type codes used by IP2Location's Anonymous IP database to classify anonymous internet traffic. Each row defines a proxy category — from datacenter hosting providers (DCH) to Tor exit nodes (TOR) and VPN services (VPN) — along with a detailed description and an anonymity level (High or Low).

This table serves as the reference taxonomy for the `ProxyType` column in `Dim_CountryIPAnonymous`. The ETL pipeline `SP_Dictionaries_Country_DL_To_Synapse` loads raw ProxyType codes (e.g., "VPN", "TOR") into `Dim_CountryIPAnonymous`, and `SP_Fact_CustomerAction` then propagates the ProxyType code into `Fact_CustomerAction` when an IP address matches an anonymous range. Analysts can JOIN this table to decode the 3-char code into a human-readable description and anonymity level.

The table was loaded manually from IP2Location documentation and is frozen — UpdateDate is NULL for all 6 rows. No active ETL exists to refresh it. This is appropriate since IP2Location's proxy type taxonomy rarely changes; updates would require a manual re-load if IP2Location extends its classification scheme.

---

## 2. Business Logic

### 2.1 Proxy Type Classification

**What**: IP2Location's taxonomy classifying the nature and anonymity risk of proxy/VPN/Tor internet traffic.

**Columns Involved**: `ProxyType`, `ProxyTypeDescription`, `Anonymity`

**Rules**:
- ProxyType is a 3-character code — the natural key. No numeric surrogate key exists.
- Anonymity = "High" for types that hide the user's true IP completely (PUB, TOR, VPN, WEB).
- Anonymity = "Low" for types that may anonymize but are commonly benign (DCH, SES — data centers and search engine bots).
- This classification can be used for fraud detection: High-anonymity IPs (TOR, VPN) during deposit or login events are elevated risk signals.

**Value Map**:
```
ProxyType | Anonymity | Description
 DCH      | Low       | Hosting Provider, Data Center, or CDN — flagged because they can enable anonymity
 PUB      | High      | Public Proxies — proxy server software listening on a port
 SES      | Low       | Search Engine Robots — crawlers/bots (typically benign)
 TOR      | High      | Tor Exit Nodes — high-anonymity Tor network
 VPN      | High      | Anonymizing VPN services — commercial VPNs hiding IP
 WEB      | High      | Web Proxies — web-based proxies (simpler than VPN/PUB)
```

### 2.2 Integration with Fact_CustomerAction

**What**: ProxyType codes flow from this reference table through two hops into the main fact table.

**Columns Involved**: `ProxyType`

**Flow**:
```
IP2Location Docs (external)
  -> Dim_CountryIPAnonymousProxyType (this table, 6 rows, static)

Customer IP range lookup:
  SP_Dictionaries_Country_DL_To_Synapse
    -> Dim_CountryIPAnonymous.ProxyType (3-char code per IP range)

  SP_Fact_CustomerAction:
    JOIN Dim_CountryIPAnonymous ON IPNumber BETWEEN IPFrom AND IPTo
    SET ProxyType = di.ProxyType on Fact_CustomerAction rows
```

Analysts can JOIN `Dim_CountryIPAnonymousProxyType` on `ProxyType` to decode the code in fact queries.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `ProxyType` (varchar(3)). REPLICATE is optimal — 6 rows total, every compute node needs a copy to avoid shuffle on JOINs. The clustered index on the string PK enables fast point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is NOT in the Generic Pipeline mapping and is not exported to Gold/UC. For UC queries involving ProxyType, join to `Dim_CountryIPAnonymous` which does contain the code.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode ProxyType code to description | `JOIN DWH_dbo.Dim_CountryIPAnonymousProxyType ON ProxyType` |
| Filter to high-anonymity IPs only | `WHERE Anonymity = 'High'` (or ProxyType IN ('TOR','VPN','PUB','WEB')) |
| Count Fact_CustomerAction by anonymity level | `JOIN Dim_CountryIPAnonymous + Dim_CountryIPAnonymousProxyType, GROUP BY Anonymity` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_CountryIPAnonymous | ON Dim_CountryIPAnonymous.ProxyType = Dim_CountryIPAnonymousProxyType.ProxyType | Decode the 3-char code to description + anonymity level |
| DWH_dbo.Fact_CustomerAction | ON Fact_CustomerAction.ProxyType = Dim_CountryIPAnonymousProxyType.ProxyType | Enrich fact rows with proxy descriptions |

### 3.4 Gotchas

- **6 rows only**: This is a tiny reference table. All 6 IP2Location proxy types are present. Outer JOINs from Fact_CustomerAction may return NULLs when ProxyType = NULL (non-anonymous IPs) or when a customer IP did not match any anonymous range.
- **Static data**: UpdateDate is NULL for all rows — the table has never been refreshed. If IP2Location adds new proxy type codes, this table must be manually updated.
- **ProxyType not in Dim_CountryIPAnonymousProxyType does not mean non-anonymous**: It means the IP did not match any anonymous range in Dim_CountryIPAnonymous, so ProxyType on Fact_CustomerAction is NULL.
- **No direct SP writes to this table**: Loaded by a one-time INSERT (no SSDT SP found). Changes require a manual DML operation.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★ | Tier 3 | Live data / sampling — verified from actual Synapse table rows |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProxyType | varchar(3) | YES | 3-character IP2Location proxy type code (nullable varchar(3)). Not a formal primary key per DDL. Used to categorise proxy connections detected by IP geolocation. |
| 2 | ProxyTypeDescription | varchar(500) | YES | Full IP2Location description of the proxy type category. Human-readable explanation suitable for reports and documentation. (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType) |
| 3 | Anonymity | varchar(10) | YES | IP2Location anonymity risk level for this proxy type: "High" (PUB, TOR, VPN, WEB — user IP is hidden) or "Low" (DCH, SES — may anonymize but commonly benign). Use for fraud/risk segmentation. (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp — always NULL (static reference table, no active ETL refresh). (Tier 3 — live data, DWH_dbo.Dim_CountryIPAnonymousProxyType) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProxyType | IP2Location Anonymous IP Database documentation | ProxyType code | Passthrough |
| ProxyTypeDescription | IP2Location Anonymous IP Database documentation | Description | Passthrough |
| Anonymity | IP2Location Anonymous IP Database documentation | Anonymity level | Passthrough |
| UpdateDate | — | — | ETL-computed (never set — static load) |

No upstream wiki. Source: IP2Location external reference (ip2location.com Anonymous IP database taxonomy). Not in Generic Pipeline.

### 5.2 ETL Pipeline

```
IP2Location Anonymous IP Database (external documentation)
  -> Manual one-time DML INSERT (no SSDT SP)
    -> DWH_dbo.Dim_CountryIPAnonymousProxyType (6 rows, static)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | IP2Location Anonymous IP Database | External GeoIP vendor — defines proxy type taxonomy |
| ETL | None (manual) | One-time INSERT. No SSDT SP found for this table. |
| Target | DWH_dbo.Dim_CountryIPAnonymousProxyType | 6 rows, frozen since load |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No foreign key relationships. Leaf reference dimension. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_CountryIPAnonymous | ProxyType | ProxyType codes in Dim_CountryIPAnonymous can be decoded via JOIN to this table. Loaded by SP_Dictionaries_Country_DL_To_Synapse. |
| DWH_dbo.Fact_CustomerAction | ProxyType | ProxyType propagated from Dim_CountryIPAnonymous to Fact_CustomerAction by SP_Fact_CustomerAction; decode via JOIN to this table. |

---

## 7. Sample Queries

### 7.1 View all proxy types with descriptions

```sql
SELECT ProxyType, Anonymity, LEFT(ProxyTypeDescription, 80) AS ShortDesc
FROM DWH_dbo.Dim_CountryIPAnonymousProxyType
ORDER BY Anonymity DESC, ProxyType
```

### 7.2 Count customer actions by anonymity level

```sql
SELECT
    COALESCE(pt.Anonymity, 'Non-anonymous') AS AnonymityLevel,
    pt.ProxyType,
    COUNT(*) AS ActionCount
FROM DWH_dbo.Fact_CustomerAction fca
LEFT JOIN DWH_dbo.Dim_CountryIPAnonymousProxyType pt
    ON fca.ProxyType = pt.ProxyType
GROUP BY pt.Anonymity, pt.ProxyType
ORDER BY ActionCount DESC
```

### 7.3 Find high-anonymity registrations with IP context

```sql
SELECT
    fca.CID,
    fca.ActionTypeID,
    fca.ProxyType,
    pt.ProxyTypeDescription,
    pt.Anonymity
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_CountryIPAnonymousProxyType pt
    ON fca.ProxyType = pt.ProxyType
WHERE pt.Anonymity = 'High'
    AND fca.ActionTypeID = 1  -- Registration action type
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — static reference table from external IP2Location documentation; Jira/Confluence unlikely to contain additional metadata.)

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 0 T2b, 4 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_CountryIPAnonymousProxyType | Type: Table | Production Source: IP2Location Anonymous IP Database (external reference)*
