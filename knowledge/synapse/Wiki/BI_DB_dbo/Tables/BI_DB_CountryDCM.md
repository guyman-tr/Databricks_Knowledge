# BI_DB_dbo.BI_DB_CountryDCM

> 231-row static reference table mapping country names between DCM (Double Click Manager) and Affwiz naming conventions, with a manually assigned marketing region for each country. All rows loaded on 2021-10-13; no automated refresh. Used as a JOIN lookup by SP_DCM_Dashboard.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (manually loaded reference data; no writer SP exists) |
| **Refresh** | None (static; single UpdateDate 2021-10-13 across all rows) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Country_DCM ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | None |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_CountryDCM` is a 231-row static mapping table that bridges country-name differences between **DCM** (Google Double Click Campaign Manager) and the internal **Affwiz** affiliate tracking system. Each row maps one DCM country name (e.g. "Anguilla (BWI)") to its Affwiz equivalent (e.g. "Anguilla") and assigns a `MarketingRegionManualName` used for regional media-campaign reporting.

The table is consumed by `SP_DCM_Dashboard`, which JOINs on `Country_DCM` to translate DCM campaign-level country data into the Affwiz naming convention used throughout BI reporting, and to pull the marketing region grouping for aggregation.

There is no writer stored procedure. All 231 rows carry the same `UpdateDate` of 2021-10-13, indicating a one-time manual load. The table appears to be maintained via ad-hoc INSERT/UPDATE when country mappings change.

---

## 2. Business Logic

### 2.1 Country Name Translation

**What**: Maps DCM country names (which include parenthetical qualifiers like "(BWI)", "(Neth. Antilles)") to cleaner Affwiz names used internally.
**Columns Involved**: `Country_DCM`, `Country_Affwiz`
**Rules**:
- Most countries share the same name in both systems (e.g. "Afghanistan" = "Afghanistan")
- Differences arise from historical qualifiers: "Anguilla (BWI)" → "Anguilla", "Antigua & Barbuda (BWI)" → "Antigua and Barbuda"
- The JOIN in SP_DCM_Dashboard uses case-sensitive collation (`Latin1_General_CS_AS`) on `Country_DCM`

### 2.2 Marketing Region Assignment

**What**: Each country is assigned to one of 18 marketing regions for media-campaign reporting.
**Columns Involved**: `MarketingRegionManualName`
**Rules**:
- 18 distinct regions: ROW (90 countries), South & Central America (32), French (21), Asia (20), ROE (19), Arabic (16), Nordics (5), CEE (5), USA (5), German (4), Italian (3), Other EU (3), Spain (2), Australia (2), UK (1), Ireland (1), Mexico (1), SEA (1)
- "ROW" (Rest of World) is the catch-all region for countries not assigned to a specific marketing region
- These regions align with the media team's campaign targeting structure

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table uses ROUND_ROBIN distribution (231 rows — trivially small) with a CLUSTERED INDEX on `Country_DCM`. All queries will be fast regardless of approach.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Which marketing region does a country belong to? | `SELECT * FROM BI_DB_dbo.BI_DB_CountryDCM WHERE Country_DCM = 'Germany'` |
| List all countries in a region | `SELECT Country_DCM, Country_Affwiz FROM BI_DB_dbo.BI_DB_CountryDCM WHERE MarketingRegionManualName = 'Arabic'` |
| Find country naming differences | `SELECT * FROM BI_DB_dbo.BI_DB_CountryDCM WHERE Country_DCM != Country_Affwiz` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| External_Fivetran_double_click_campaign_manager_media_campaign | `ON a.country COLLATE Latin1_General_CS_AS = b.Country_DCM COLLATE Latin1_General_CS_AS` | Translate DCM country names to Affwiz names in SP_DCM_Dashboard |
| DWH_dbo.Dim_Country | `ON dc.Name = z.Country` (via Affwiz name) | Retrieve additional country attributes after name translation |

### 3.4 Gotchas

- **Case-sensitive JOIN**: SP_DCM_Dashboard uses `Latin1_General_CS_AS` collation on the JOIN — country name casing must match exactly
- **Static data**: No automated refresh exists. If DCM adds new countries or renames existing ones, this table must be manually updated
- **Not the same as Dim_Country**: This table has its own `MarketingRegionManualName` which may differ from `Dim_Country.MarketingRegionManualName` — both are manually maintained and could diverge
- **UpdateDate is load date, not row-change date**: All rows share the same timestamp (2021-10-13), so it cannot be used to identify recently changed mappings

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP/ETL code |
| Tier 3 | Inferred from DDL, data samples, and consuming SP context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Country_DCM | nvarchar(50) | YES | Country name as used in Google DCM (Double Click Campaign Manager) campaign data. Used as the JOIN key in SP_DCM_Dashboard to translate DCM country names to the internal Affwiz naming convention. Clustered index column. (Tier 3 — no upstream; manually loaded reference data) |
| 2 | Country_Affwiz | nvarchar(50) | YES | Country name as used in the internal Affwiz affiliate tracking system. Equivalent to the DCM country name but without parenthetical qualifiers (e.g. "Anguilla" instead of "Anguilla (BWI)"). Used as the output country name in SP_DCM_Dashboard reporting. (Tier 3 — no upstream; manually loaded reference data) |
| 3 | MarketingRegionManualName | nvarchar(50) | YES | Manually assigned marketing region grouping for the country. 18 distinct values (ROW, South & Central America, French, Asia, ROE, Arabic, Nordics, CEE, USA, German, Italian, Other EU, Spain, Australia, UK, Ireland, Mexico, SEA). Used in SP_DCM_Dashboard for regional media-campaign aggregation. (Tier 3 — no upstream; manually loaded reference data) |
| 4 | UpdateDate | datetime | YES | Timestamp indicating when the mapping row was loaded or last updated. Currently all 231 rows share the value 2021-10-13 15:45:53, indicating a single bulk load with no subsequent updates. (Tier 3 — no upstream; manually loaded reference data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Country_DCM | (Manual load) | — | Static reference value |
| Country_Affwiz | (Manual load) | — | Static reference value |
| MarketingRegionManualName | (Manual load) | — | Static reference value |
| UpdateDate | (Manual load) | — | Load timestamp |

### 5.2 ETL Pipeline

```
(Manual bulk load — no automated pipeline)
  |
  v
BI_DB_dbo.BI_DB_CountryDCM (231 rows, static since 2021-10-13)
  |
  |-- Read by SP_DCM_Dashboard (JOIN on Country_DCM) --|
  v
BI_DB_dbo.BI_DB_DCM_Dashboard (downstream consumer)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| — | — | No outbound foreign keys; standalone mapping table |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| Country_DCM | BI_DB_dbo.SP_DCM_Dashboard | JOIN key to translate DCM campaign country names to Affwiz names |
| Country_Affwiz | BI_DB_dbo.BI_DB_DCM_Dashboard | Output country name written to the DCM Dashboard table |

---

## 7. Sample Queries

### 7.1 Find the Marketing Region for a Specific Country

```sql
SELECT Country_DCM, Country_Affwiz, MarketingRegionManualName
FROM [BI_DB_dbo].[BI_DB_CountryDCM]
WHERE Country_DCM = 'Germany';
```

### 7.2 List All Countries Where DCM and Affwiz Names Differ

```sql
SELECT Country_DCM, Country_Affwiz
FROM [BI_DB_dbo].[BI_DB_CountryDCM]
WHERE Country_DCM != Country_Affwiz
ORDER BY Country_DCM;
```

### 7.3 Count Countries per Marketing Region

```sql
SELECT MarketingRegionManualName, COUNT(*) AS CountryCount
FROM [BI_DB_dbo].[BI_DB_CountryDCM]
GROUP BY MarketingRegionManualName
ORDER BY CountryCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this static mapping table.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 4 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 7/10, Lineage: 6/10*
*Object: BI_DB_dbo.BI_DB_CountryDCM | Type: Table | Production Source: Unknown (manually loaded reference data)*
