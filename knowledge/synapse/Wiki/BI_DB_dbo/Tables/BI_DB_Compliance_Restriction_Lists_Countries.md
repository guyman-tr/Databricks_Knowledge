# BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries

> 774-row daily reference table classifying 229 countries across 15 AML/regulatory restriction list types (ASIC_Forbidden, FCA_Forbidden, US_Forbidden, FATF, EU sanctions, UN sanctions, etc.). Source: AML-maintained Google Sheets synced via Fivetran to Azure Data Lake (Silver/SharePoint/compliance_help_countries). Refreshed daily by TRUNCATE+INSERT. UsedIn and Source columns are always NULL — present in DDL and source sheet but omitted from the SP INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | AML Google Sheets (compliance_help_countries) via Fivetran → Silver/SharePoint |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild each run) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CountryID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Compliance_Restriction_Lists_Countries is a country-level compliance reference table listing 229 countries on 15 AML and regulatory risk lists. Each row assigns a country to a named restriction or monitoring list with an effective date range. The data is maintained manually by the AML team in a Google Sheets spreadsheet, synced to the data lake via Fivetran and loaded into Synapse daily.

The 15 list types cover: regulatory forbiddance lists (ASIC_Forbidden, FCA_Forbidden, US_Forbidden, CySEC_Forbidden), sanctions (EU_Sanctions, UN_Sanctions, HMTreasury_UKList), FATF high-risk classifications, EEA membership, EU tax classification, trading alerts (Test___Trading_Alert_HighLeverage, Test___Trading_Alert_CFD), and AML monitoring control (AML_Alerts_Ignore).

**Important**: Two columns present in the DDL (`UsedIn`, `Source`) and in the External Table source (`used_in`, `source`) are deliberately NOT populated by the SP INSERT. They are always NULL in the physical table. These fields may be informational metadata in the Google Sheet but were not included in the ETL pipeline.

**CountryID NULL**: Countries without a DWH CountryID mapping appear with NULL CountryID (e.g., Jersey, Palestine, French Southern and Antarctic Territories). The Country name is always populated and is the reliable identifier.

---

## 2. Business Logic

### 2.1 Country Risk List Assignment

**What**: AML team assigns countries to named regulatory and risk monitoring lists with effective date ranges.

**Columns Involved**: Country, CountryID, List, FromDate, ToDate

**Rules**:
- One row = one country on one list for one date range
- A country can appear on multiple lists (multiple rows per country)
- CountryID is provided when the country maps to a DWH Dim_Country record; NULL when not mapped
- Date ranges represent when the classification was/is active

### 2.2 Restriction List Categories

**What**: The 15 distinct List values group countries into regulatory and risk categories.

**Columns Involved**: List

**Rules** (ordered by row count):
- `Test___Trading_Alert_HighLeverage` (179): Countries where high-leverage trading triggers alerts — test category
- `ASIC_Forbidden` (75): Countries forbidden under ASIC regulatory jurisdiction
- `US_Forbidden` (72): Countries forbidden under US regulatory requirements
- `FCA_Forbidden` (70): Countries forbidden under FCA regulatory jurisdiction
- `AML_Alerts_Ignore` (67): Countries for which AML alerts should be suppressed
- `FATF` (57): Countries on FATF high-risk or monitored list
- `EU_High_Risk_Third` (50): EU classification of high-risk third countries
- `EEA` (38): European Economic Area member countries
- `CySEC_Forbidden` (33): Countries forbidden under CySEC regulatory jurisdiction
- `Test___Trading_Alert_CFD` (30): Countries where CFD trading triggers alerts — test category
- `EU_Sanctions` (29): Countries under EU sanctions
- `UN_Sanctions` (27): Countries under UN sanctions
- `HMTreasury_UKList` (26): Countries on HM Treasury UK financial sanctions list
- `EU_Tax` (19): EU tax-relevant country classification
- NULL (2): Rows with no list classification (data quality gap in source sheet)

### 2.3 Omitted Columns

**What**: Two DDL columns exist but are never populated.

**Columns Involved**: UsedIn, Source

**Rules**:
- Both columns are NULL for all 774 rows
- The External Table source (compliance_help_countries) has `used_in` and `source` columns
- The SP INSERT explicitly names target columns and excludes UsedIn and Source
- Intended to document which systems use each list and the list's origin — never implemented

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: ROUND_ROBIN — small table (774 rows), distribution is irrelevant for performance.

**Index**: CLUSTERED INDEX (CountryID ASC) — efficient for CountryID lookups. Note: NULL CountryIDs are not indexed effectively. Use Country name for joins when CountryID is NULL.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is a country on the FCA forbidden list? | `WHERE Country = @country AND List = 'FCA_Forbidden'` |
| All forbidden countries for a regulation | `WHERE List IN ('FCA_Forbidden','ASIC_Forbidden','US_Forbidden','CySEC_Forbidden')` |
| Countries on UN or EU sanctions | `WHERE List IN ('UN_Sanctions','EU_Sanctions')` |
| FATF high-risk countries | `WHERE List = 'FATF'` |
| Currently active entries | `WHERE FromDate <= CAST(GETDATE() AS date) AND (ToDate IS NULL OR ToDate >= CAST(GETDATE() AS date))` |
| Countries without DWH mapping | `WHERE CountryID IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON crl.CountryID = dc.CountryID | Country attributes where CountryID is not NULL |

### 3.4 Gotchas

- **CountryID can be NULL**: Countries like Jersey, Palestine, French Southern and Antarctic Territories have no DWH CountryID. JOIN on CountryID silently drops these countries. Use Country name for reliable matching.
- **UsedIn and Source are always NULL**: Despite being in the DDL, these columns are never populated. Do not rely on them.
- **Test___ prefix lists**: Lists starting with `Test___` (Test___Trading_Alert_HighLeverage, Test___Trading_Alert_CFD) may be legacy or test categories. Verify with AML team whether these are still operationally used.
- **NULL List rows**: 2 rows have NULL List — data quality gap from source Google Sheet.
- **Full rebuild daily**: TRUNCATE+INSERT means no historical trend data. This is a current-state reference, not a log.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 — SP code / ETL logic | (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Country | varchar(100) | YES | Country name as entered in the AML Google Sheet. Always populated. Use this column for reliable joins when CountryID is NULL. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 2 | CountryID | int | YES | DWH country identifier. NULL when the country has no mapping in Dim_Country (e.g., Jersey, Palestine). FK to Dim_Country.CountryID where not NULL. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 3 | List | varchar(100) | YES | Regulatory or AML risk list name. Values (15 types): 'ASIC_Forbidden', 'AML_Alerts_Ignore', 'CySEC_Forbidden', 'EEA', 'EU_High_Risk_Third', 'EU_Sanctions', 'EU_Tax', 'FATF', 'FCA_Forbidden', 'HMTreasury_UKList', 'Test___Trading_Alert_CFD', 'Test___Trading_Alert_HighLeverage', 'UN_Sanctions', 'US_Forbidden', NULL (2 rows). (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 4 | FromDate | date | YES | Start date of this country's active period on this risk list. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 5 | ToDate | date | YES | End date of this country's active period on this risk list. NULL = open-ended or not specified. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 7 | UsedIn | varchar(100) | YES | Always NULL — SP INSERT omits this column despite it existing in both the DDL and External Table source (used_in field). Intended to document which systems consume each restriction list. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 8 | Source | varchar(100) | YES | Always NULL — SP INSERT omits this column despite it existing in both the DDL and External Table source (source field). Intended to document the origin of each restriction list entry. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Country | compliance_help_countries Google Sheet | country | Passthrough |
| CountryID | compliance_help_countries Google Sheet | country_id (nvarchar) | Implicit cast nvarchar → int |
| List | compliance_help_countries Google Sheet | list | Passthrough |
| FromDate | compliance_help_countries Google Sheet | from_date | Passthrough |
| ToDate | compliance_help_countries Google Sheet | to_date | Passthrough |
| UpdateDate | ETL | GETDATE() | Set at INSERT time |
| UsedIn | NOT POPULATED | — | Omitted from SP INSERT; always NULL |
| Source | NOT POPULATED | — | Omitted from SP INSERT; always NULL |

### 5.2 ETL Pipeline

```
AML team Google Sheets (compliance_help_countries tab)
  |-- Fivetran (Google Sheets/SharePoint connector) ---|
  v
Azure Data Lake: Silver/SharePoint/compliance_help_countries/ (Parquet)
  |-- External Table: BI_DB_dbo.External_Fivetran_gsheets_compliance_help_countries
  |-- SP_CID_Compliance_CID_And_Country_Risk_Lists (TRUNCATE + INSERT SELECT, cols: Country/CountryID/List/FromDate/ToDate/UpdateDate only)
  v
BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries (774 rows)
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
| SP_Compliance_Forbidden_Trades | BI_DB_Compliance_Restriction_Lists_Countries | Forbidden trade country checks |
| SP_RBSF | BI_DB_Compliance_Restriction_Lists_Countries | Risk-based supervision country-level checks |
| SP_Y_RBSF | BI_DB_Compliance_Restriction_Lists_Countries | Yearly RBSF country-level checks |

---

## 7. Sample Queries

### 7.1 All sanctioned countries (UN + EU + HM Treasury)

```sql
SELECT Country,
       CountryID,
       List,
       FromDate,
       ToDate
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Countries]
WHERE  List IN ('UN_Sanctions', 'EU_Sanctions', 'HMTreasury_UKList')
ORDER BY List, Country;
```

### 7.2 Countries on multiple lists (regulatory overlap)

```sql
SELECT Country,
       COUNT(DISTINCT List) AS list_count,
       STRING_AGG(List, ', ') AS lists
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Countries]
WHERE  List IS NOT NULL
GROUP BY Country
HAVING COUNT(DISTINCT List) > 3
ORDER BY list_count DESC;
```

### 7.3 Countries without DWH mapping (no CountryID)

```sql
SELECT DISTINCT Country
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Countries]
WHERE  CountryID IS NULL
  AND  Country IS NOT NULL
ORDER BY Country;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 9.1/10 | Phases: 14/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries | Type: Table | Production Source: AML Google Sheets (compliance_help_countries) via Fivetran*
