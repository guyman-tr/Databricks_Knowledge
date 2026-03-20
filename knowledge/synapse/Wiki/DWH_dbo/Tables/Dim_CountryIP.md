# DWH_dbo.Dim_CountryIP

> Large IP geolocation table (6.8M rows) mapping IPv4 address ranges (as integers) to country and sub-national region. Used for IP-to-country resolution during registration, login, and fraud detection.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CountryIP |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (IPFrom ASC, IPTo ASC, CountryID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CountryIP` is a 6.8-million-row IP geolocation range table. Each row maps a contiguous range of IPv4 addresses (stored as bigint integers) to a DWH CountryID and optionally a sub-national RegionID. When a customer connects to eToro, their IP address is converted to an integer and matched against this table via a range lookup (`WHERE @IPInteger BETWEEN IPFrom AND IPTo`) to determine their geographic location.

This geolocation data drives: auto-detection of registration country (pre-filling the registration form), fraud detection (validating IP location matches expected patterns), and risk scoring context. In production, this is served by `Internal.GetCountryIDByIP` / `Internal.GetCountryNameByIP` / `Internal.GetRegionIDByIP` functions.

The ETL is a full TRUNCATE+INSERT daily reload from `DWH_staging.etoro_Dictionary_CountryIP`. All 4 source columns are passthroughs; only UpdateDate is ETL-computed.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryIP.md`.

---

## 2. Business Logic

### 2.1 IP Range Lookup

**What**: Convert an IPv4 address to integer, then find the row where `IPInteger BETWEEN IPFrom AND IPTo`.

**Columns Involved**: `IPFrom`, `IPTo`, `CountryID`, `RegionID`

**Rules**:
- IPv4 to integer: `IP = octet1*16777216 + octet2*65536 + octet3*256 + octet4`
- Example: 1.0.0.0 = 16777216, 1.0.0.255 = 16777471 (see row 1 in live data)
- Lookup: `WHERE @IPInteger BETWEEN IPFrom AND IPTo`
- Multiple non-contiguous ranges can map to the same CountryID (IP allocation is fragmented)
- RegionID provides sub-national granularity. NULL when region is not available for the range.
- Smallest ranges can be a single IP (IPFrom = IPTo); largest are /8 blocks (16M addresses)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE with a CLUSTERED INDEX on (IPFrom, IPTo, CountryID). At 6.8M rows, REPLICATE is borderline large - verify Synapse is actually replicating and not falling back to round-robin. The clustered composite index supports range overlap queries.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED). Z-ORDER BY IPFrom, IPTo for efficient range lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve IP to country | `SELECT CountryID FROM Dim_CountryIP WHERE @ip BETWEEN IPFrom AND IPTo` |
| Count IP ranges per country | `GROUP BY CountryID ORDER BY COUNT(*) DESC` |
| Find all ranges for a country | `WHERE CountryID = @id ORDER BY IPFrom` |

### 3.3 Gotchas

- IP ranges in this table use bigint integers, not dotted-decimal notation. Convert before querying.
- A given IP integer may match multiple rows in edge cases (overlapping ranges). In production, the shortest range (IPTo - IPFrom smallest) is preferred.
- REPLICATE at 6.8M rows: may incur memory pressure on small Synapse SKUs.

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
| 1 | CountryID | int | NO | FK to DWH_dbo.Dim_Country. Identifies which country owns this IP range. Part of the clustered index. (Tier 1 - Dictionary.CountryIP upstream wiki) |
| 2 | IPFrom | bigint | NO | Start of the IP address range as an integer (IPv4: octet1*16777216 + octet2*65536 + octet3*256 + octet4). Part of the clustered index. Used with IPTo for BETWEEN lookups. (Tier 1 - Dictionary.CountryIP upstream wiki) |
| 3 | IPTo | bigint | NO | End of the IP address range as an integer. When IPFrom = IPTo the range covers exactly one IP address. Part of the clustered index. (Tier 1 - Dictionary.CountryIP upstream wiki) |
| 4 | RegionID | int | YES | Sub-national region ID within the country. Provides geographic granularity below country level (e.g., state, province). NULL when regional data is not available for this IP range. References an internal region lookup (not directly a DWH dimension). (Tier 2 - SP passthrough; CODE-BACKED in upstream wiki) |
| 5 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload via SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.CountryIP | CountryID | passthrough |
| IPFrom | etoro.Dictionary.CountryIP | IPFrom | passthrough |
| IPTo | etoro.Dictionary.CountryIP | IPTo | passthrough |
| RegionID | etoro.Dictionary.CountryIP | RegionID | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryIP.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CountryIP
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_CountryIP (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_CountryIP (6.8M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CountryIP | Master IP geolocation range table. ~6.8M rows. Updated periodically from external GeoIP databases. |
| Staging | DWH_staging.etoro_Dictionary_CountryIP | Raw staging. Same 4-column structure. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. All 4 columns passthrough. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_CountryIP | Final DWH IP lookup (6.8M rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | IP range maps to a DWH country. Implicit FK (not enforced). |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_CountryIPAnonymous | CountryCode/CountryID | The anonymous proxy IP table is a related lookup for suspicious/proxy IPs (separate ETL via SP_Dictionaries_Country_DL_To_Synapse). |

---

## 7. Sample Queries

### 7.1 Resolve integer IP to country
```sql
DECLARE @ip bigint = 87965770; -- 5.39.217.74
SELECT c.Name AS Country, d.RegionID
FROM [DWH_dbo].[Dim_CountryIP] d
JOIN [DWH_dbo].[Dim_Country] c ON d.CountryID = c.CountryID
WHERE @ip BETWEEN d.IPFrom AND d.IPTo;
```

### 7.2 Count IP ranges per country
```sql
SELECT c.Name AS Country, COUNT(*) AS RangeCount
FROM [DWH_dbo].[Dim_CountryIP] d
JOIN [DWH_dbo].[Dim_Country] c ON d.CountryID = c.CountryID
GROUP BY c.Name
ORDER BY RangeCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryIP.md`.

---

*Generated: 2026-03-19 | Quality: 8.0/10 (4 stars) | Phases: 7/14 (simple passthrough, upstream wiki)*
*Tiers: 3 T1, 2 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CountryIP | Type: Table | Production Source: etoro.Dictionary.CountryIP*
