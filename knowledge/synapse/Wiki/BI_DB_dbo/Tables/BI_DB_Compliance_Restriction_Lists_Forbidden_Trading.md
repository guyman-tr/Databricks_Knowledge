# BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading

> 885-row daily reference table classifying 200 countries across 14 AML/compliance forbidden-trading restriction categories (Rank 1/2 countries, No CFD at all, No real Crypto, No smart portfolio, No copy trader, etc.). Source: AML/Compliance-maintained Google Sheets spreadsheet synced via Fivetran to Azure Data Lake (Silver/SharePoint/forbiddentrading). Refreshed daily by TRUNCATE+INSERT. No date-range columns — this is a current-state classification only.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | AML/Compliance Google Sheets (forbiddentrading) via Fivetran → Silver/SharePoint |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild each run) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CountryID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Compliance_Restriction_Lists_Forbidden_Trading is a country-level forbidden-trading restriction reference table maintained by the AML/Compliance team. Each row assigns a country to a named trading restriction category. The data originates from a Google Sheets spreadsheet, synced to the data lake via Fivetran (Google Sheets connector) and exposed through a Synapse External Table before being loaded here daily by TRUNCATE+INSERT.

Unlike BI_DB_Compliance_Restriction_Lists_Countries, this table has no date-range columns (no FromDate/ToDate). It is a flat, current-state classification: if a country is in the table under a given List, that restriction applies now. Historical changes are not tracked.

The 14 restriction categories cover: regulatory tier classification (Rank 1/2 countries, Rank 1 countries), product-level bans (No CFD at all, No real Crypto, No crypto wallet, No real Equity, No smart portfolio, No copy trader, No Crypto X2 CFD Allowed), FSA-specific rules (Can only Copy FSA), CMT restrictions (Country restriction - No CMT), FX restrictions (no CFD trades on FX), and broader regulatory classifications (Country VBT, Regulation VBD).

**CountryID NULL**: Some countries may have NULL CountryID where the country has no DWH CountryID mapping. Country name is always populated and is the reliable identifier.

---

## 2. Business Logic

### 2.1 Country Restriction Assignment

**What**: AML/Compliance team assigns countries to named trading restriction categories.

**Columns Involved**: Country, CountryID, List

**Rules**:
- One row = one country under one restriction category
- A country can appear on multiple restriction categories (multiple rows per country)
- CountryID is provided when the country maps to a DWH record; NULL when not mapped
- No effective date range — this is a point-in-time classification refreshed daily

### 2.2 Restriction Categories

**What**: The 14 distinct List values group countries by the type of trading restriction applied.

**Columns Involved**: List

**Rules** (ordered by row count from live data):
- `Rank 1/2 countries` (136): Countries in regulatory tier 1 or 2 — highest regulatory oversight
- `Country restriction - No CMT` (118): Countries where CMT (Copy Manual Trading) is restricted
- `No CFD at all` (108): Countries where CFD trading is entirely forbidden
- `No real Crypto` (108): Countries where real (non-CFD) crypto trading is forbidden
- `No crypto wallet` (105): Countries where the crypto wallet product is forbidden
- `No real Equity` (102): Countries where real (non-CFD) equity trading is forbidden
- `No smart portfolio` (80): Countries where the Smart Portfolio product is forbidden
- `No copy trader` (80): Countries where the Copy Trader feature is forbidden
- `Rank 1 countries` (16): Countries in the highest regulatory tier only
- `Can only Copy FSA` (13): Countries where customers can only use copy trading under FSA regulation
- `No Crypto X2 CFD Allowed` (12): Countries where leveraged (x2) crypto CFDs are forbidden
- `Country VBT` (3): Country-level VBT (Virtual Book Transfer) classification
- `no CFD trades on FX` (3): Countries where CFD trades on FX instruments are forbidden
- `Regulation VBD` (1): Countries under VBD (Virtual Book Distribution) regulatory classification

### 2.3 No Historical Data

**What**: This table has no date-range tracking columns.

**Columns Involved**: Country, CountryID, List, UpdateDate

**Rules**:
- No FromDate/ToDate — unlike BI_DB_Compliance_Restriction_Lists_Countries, this table does not track when a restriction was added or removed
- TRUNCATE+INSERT means yesterday's state is gone — no trend analysis possible
- UpdateDate is an ETL timestamp (GETDATE() at INSERT), not a business date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: ROUND_ROBIN — small table (885 rows), distribution is irrelevant for performance.

**Index**: CLUSTERED INDEX (CountryID ASC) — efficient for CountryID lookups. Note: NULL CountryIDs are not indexed effectively. Use Country name for joins when CountryID is NULL.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is a country fully CFD-forbidden? | `WHERE Country = @country AND List = 'No CFD at all'` |
| All crypto-restricted countries | `WHERE List IN ('No real Crypto', 'No crypto wallet', 'No Crypto X2 CFD Allowed')` |
| Countries restricted from Copy Trader | `WHERE List = 'No copy trader'` |
| Rank 1 regulatory tier countries | `WHERE List IN ('Rank 1 countries', 'Rank 1/2 countries')` |
| All restrictions for a country | `WHERE Country = @country ORDER BY List` |
| Countries without DWH mapping | `WHERE CountryID IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON fbt.CountryID = dc.CountryID | Country attributes where CountryID is not NULL |

### 3.4 Gotchas

- **No date-range columns**: Unlike BI_DB_Compliance_Restriction_Lists_Countries, there are no FromDate/ToDate columns. Every row is implicitly "currently active." Historical restriction changes cannot be derived from this table.
- **CountryID can be NULL**: Some countries have no DWH CountryID mapping. JOIN on CountryID silently drops these. Use Country name for reliable matching.
- **Full rebuild daily**: TRUNCATE+INSERT means no historical trend data. This is a current-state reference, not a log.
- **List column is varchar(500)**: Unlike the other restriction tables (varchar(100)), the List column here is wider — reflects longer, free-text restriction names from the source sheet.
- **External Table has unnamed `[_]` column**: The source External Table (External_Fivetran_google_sheets_forbiddentrading) includes a `[_]` column not present in the physical DDL. This is a Fivetran artifact (row-index column) that the SP SELECT omits. It does not appear in this table.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 — SP code / ETL logic | (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | YES | DWH country identifier. NULL when the country has no mapping in Dim_Country. FK to Dim_Country.CountryID where not NULL. Sourced from Google Sheet (country_id, nvarchar) — implicitly cast to int at INSERT. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 2 | Country | varchar(100) | YES | Country name as entered in the AML/Compliance Google Sheet. Always populated in practice. Use this column for reliable joins when CountryID is NULL. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 3 | List | varchar(500) | YES | Trading restriction category name. 14 distinct values (see Section 2.2). Note: varchar(500) — wider than other restriction list tables. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline (set to GETDATE() at INSERT). Not a business date. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | forbiddentrading Google Sheet | country_id (nvarchar) | Implicit cast nvarchar → int |
| Country | forbiddentrading Google Sheet | country | Passthrough |
| List | forbiddentrading Google Sheet | list | Passthrough |
| UpdateDate | ETL | GETDATE() | Set at INSERT time |

### 5.2 ETL Pipeline

```
AML/Compliance team Google Sheets (forbiddentrading spreadsheet)
  |-- Fivetran (Google Sheets connector) ---|
  v
Azure Data Lake: Silver/SharePoint/forbiddentrading/ (Parquet)
  |-- External Table: BI_DB_dbo.External_Fivetran_google_sheets_forbiddentrading
  |   (includes Fivetran artifact column [_] not loaded to physical table)
  |-- SP_CID_Compliance_CID_And_Country_Risk_Lists (TRUNCATE + INSERT SELECT)
  v
BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading (885 rows)
  |-- UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country.CountryID | Country dimension (where not NULL) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_Compliance_Forbidden_Trades | BI_DB_Compliance_Restriction_Lists_Forbidden_Trading | Forbidden trade product/country restriction checks |

---

## 7. Sample Queries

### 7.1 All product restrictions for a given country

```sql
SELECT Country,
       List,
       UpdateDate
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Forbidden_Trading]
WHERE  Country = 'United States'
ORDER BY List;
```

### 7.2 Countries banned from CFD or Crypto products

```sql
SELECT Country,
       CountryID,
       List
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Forbidden_Trading]
WHERE  List IN ('No CFD at all', 'No real Crypto', 'No crypto wallet', 'No Crypto X2 CFD Allowed')
ORDER BY Country, List;
```

### 7.3 Restriction count per country (most restricted countries)

```sql
SELECT Country,
       COUNT(DISTINCT List) AS restriction_count,
       STRING_AGG(List, ' | ') AS restrictions
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Forbidden_Trading]
GROUP BY Country
HAVING COUNT(DISTINCT List) > 5
ORDER BY restriction_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading | Type: Table | Production Source: AML/Compliance Google Sheets (forbiddentrading) via Fivetran*
