# DWH_dbo.Dim_State_and_Province

> Geographic dimension mapping 181 IP-based region codes to country-level sub-divisions (states, provinces, territories). Joins etoro.Dictionary.RegionByIP codes with Dictionary.RegionName full labels. Sourced daily via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RegionByIP + etoro.Dictionary.RegionName (JOIN) |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (implied — see DDL) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_State_and_Province` maps IP-based geographic region identifiers to human-readable sub-country labels (states, provinces, territories). When customers register or transact, their IP address is resolved to a country and sub-country region. This dimension bridges the numeric `RegionByIP_ID` (from `Dictionary.RegionByIP`) with the full geographic name from `Dictionary.RegionName`.

The table contains 181 rows — a subset of the full `Dictionary.RegionByIP` (4,206 entries). The reduction occurs because the ETL uses an INNER JOIN between `RegionByIP` (indexed by RegionByIP_ID, CountryID, and a short code in Name) and `RegionName` (which stores full ShortName and Name per country). Only regions with a matching `RegionName.ShortName = RegionByIP.Name` for the same country appear in DWH.

Source pipeline: SP_Dictionaries_DL_To_Synapse performs TRUNCATE + INSERT with:
```sql
SELECT rei.RegionByIP_ID, ren.CountryID, ren.ShortName, ren.Name, GETDATE()
FROM etoro_Dictionary_RegionByIP AS rei
JOIN etoro_Dictionary_RegionName AS ren
  ON rei.Name = ren.ShortName AND rei.CountryID = ren.CountryID
```

---

## 2. Business Logic

### 2.1 IP Region to Full Name Resolution

**What**: Maps the numeric IP-geolocation region code (RegionByIP_ID) to a country and human-readable geographic name.

**Columns Involved**: `RegionByIP_ID`, `CountryID`, `ShortName`, `Name`

**Rules**:
- `RegionByIP_ID` is the join key used in customer fact/dim tables (stored in `Customer.CustomerStatic.RegionByIP_ID`)
- `ShortName` is the short alphanumeric code used by IP geolocation providers (e.g., "CA", "NY", "64")
- `Name` is the full geographic label (e.g., "California", "New York") from Dictionary.RegionName
- The INNER JOIN means only 181 of 4,206 total regions are present — regions without a matching `RegionName` entry are excluded from DWH
- `CountryID` references DWH_dbo.Dim_Country for country-level lookups

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 181-row table — full local copy on every node, zero data movement on JOINs to large customer fact tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer geographic distribution by state/province | JOIN customer fact/dim ON RegionByIP_ID |
| Filter to specific country regions | WHERE CountryID = <DWH country ID> |
| Resolve region code to full name | JOIN ON RegionByIP_ID, display Name column |

### 3.3 Gotchas

- **181 rows ≠ complete global coverage**: Only regions with matching RegionName entries are present. Customer regions not in this table will produce NULL JOINs
- **Two "name" concepts**: `ShortName` is the geolocation provider's short code; `Name` is the human-readable full label
- **CountryID in DWH context**: References Dim_Country.CountryID for country enrichment

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Dictionary.RegionByIP) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RegionByIP_ID | int | NOT NULL | Primary join key. Auto-incrementing surrogate PK from `Dictionary.RegionByIP` (IDENTITY NOT FOR REPLICATION). Stored in `Customer.CustomerStatic.RegionByIP_ID` and used to identify the sub-country region detected from a customer's IP address at registration. (Tier 1 — upstream wiki, Dictionary.RegionByIP) |
| 2 | CountryID | int | NOT NULL | Country this region belongs to. FK to `DWH_dbo.Dim_Country.CountryID`. Sourced from `Dictionary.RegionName.CountryID` (the RegionName side of the join). Used for country-level geographic aggregation. (Tier 1 — upstream wiki, Dictionary.RegionByIP) |
| 3 | ShortName | nvarchar(50) | YES | Short alphanumeric region code used by IP geolocation providers. Examples: "CA", "NY", "64". This is the code that matched `Dictionary.RegionByIP.Name` in the ETL join condition. Used for cross-referencing with geolocation provider outputs. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 4 | Name | nvarchar(50) | YES | Full human-readable geographic name of the region — state, province, or territory. Sourced from `Dictionary.RegionName.Name`. Examples: "California", "New York", "Ontario". Used in reporting to display readable geographic labels. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RegionByIP_ID | etoro.Dictionary.RegionByIP | RegionByIP_ID | Passthrough (JOIN driver key) |
| CountryID | etoro.Dictionary.RegionName | CountryID | Passthrough |
| ShortName | etoro.Dictionary.RegionName | ShortName | Passthrough (also the JOIN condition with RegionByIP.Name) |
| Name | etoro.Dictionary.RegionName | Name | Passthrough |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.RegionByIP (etoroDB-REAL, 4,206 rows)
  + etoro.Dictionary.RegionName (full region names)
  |
  v [INNER JOIN on rei.Name = ren.ShortName AND rei.CountryID = ren.CountryID]
  |
  v [Generic Pipeline — daily, Override]
DWH_staging.etoro_Dictionary_RegionByIP + DWH_staging.etoro_Dictionary_RegionName
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT (JOIN result)]
DWH_dbo.Dim_State_and_Province (181 rows — inner join subset)
```

| Step | Object | Description |
|------|--------|-------------|
| Source A | etoro.Dictionary.RegionByIP | 4,206 IP region codes |
| Source B | etoro.Dictionary.RegionName | Full geographic names per country/shortcode |
| Lake | Bronze/etoro/Dictionary/RegionByIP/, RegionName/ | Daily full exports |
| Staging | DWH_staging.etoro_Dictionary_RegionByIP + etoro_Dictionary_RegionName | Raw staging imports |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT with INNER JOIN; 181 rows result |
| Target | DWH_dbo.Dim_State_and_Province | 181 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RegionByIP_ID | etoro.Dictionary.RegionByIP | Primary production source |
| CountryID | DWH_dbo.Dim_Country | Country dimension for geographic rollup |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | RegionByIP_ID | Customer's detected IP region at registration |

---

## 7. Sample Queries

### 7.1 List all states/provinces

```sql
SELECT RegionByIP_ID, CountryID, ShortName, Name
FROM [DWH_dbo].[Dim_State_and_Province]
ORDER BY CountryID, Name
```

### 7.2 Customer count by state/province (US example)

```sql
SELECT
    sp.Name AS StateName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_State_and_Province] sp
    ON dc.RegionByIP_ID = sp.RegionByIP_ID
JOIN [DWH_dbo].[Dim_Country] c
    ON sp.CountryID = c.CountryID
WHERE c.CountryName = 'United States'
GROUP BY sp.Name
ORDER BY CustomerCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT COUNT(*) AS RowCount, MAX(UpdateDate) AS LastUpdate
FROM [DWH_dbo].[Dim_State_and_Province]
-- RowCount should be ~181; LastUpdate should be today
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — simple-dict fast-path.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4-Inferred | Elements: 9.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 7.5/10*
*Object: DWH_dbo.Dim_State_and_Province | Type: Table | Production Source: etoro.Dictionary.RegionByIP + etoro.Dictionary.RegionName*
