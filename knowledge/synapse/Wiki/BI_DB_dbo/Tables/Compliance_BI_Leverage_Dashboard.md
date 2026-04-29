# BI_DB_dbo.Compliance_BI_Leverage_Dashboard

> 534K-row daily leverage restriction snapshot tracking all active leverage settings (default and max) per country, regulation group, instrument, and instrument type — with change detection against the previous day's values. Built from SettingsDB system restrictions joined with CM (Capital Markets) provider leverage data. Refreshed daily by SP_BI_DB_Compliance_BI_Leverage_Dashboard via DELETE+INSERT by Date from Oct 2022 to present. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_BI_DB_Compliance_BI_Leverage_Dashboard` from SettingsDB + CM leverage data |
| **Refresh** | Daily — DELETE WHERE Date=@Date + INSERT. Accumulating by date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table provides a **daily compliance dashboard of leverage restrictions** across the eToro platform. It captures every leverage setting rule (both platform defaults and regulatory maximums) by country, regulation group, and instrument — and detects when settings change from one day to the next.

The 534K rows represent daily snapshots from Oct 2022 to Apr 2026. Each row is a specific leverage restriction rule for a given day, showing:
- The **target scope** (country, country+regulation, regulation group, or geo-registration date)
- The **instrument scope** (specific instrument by ID, or instrument type category)
- The **current values** (New_Settings = platform setting, New_CM = Capital Markets actual leverage)
- The **previous values** (Old_ columns = populated ONLY when a change was detected)

The SP reads from SettingsDB (system restrictions, resources, tags) to get the configured leverage rules, joins with the CM provider instrument leverage tables to get actual tradeable leverage levels, then compares against the previous day's snapshot to flag changes.

---

## 2. Business Logic

### 2.1 Restriction Type Classification

**What**: Each leverage rule is either a default or maximum restriction.
**Columns Involved**: RestrictionType, ResourceId
**Rules**:
- 'default' — from ResourceName LIKE '%leverages/default/%' — the platform's standard leverage
- 'max' — from ResourceName LIKE '%leverages/max/%' — the maximum allowed leverage

### 2.2 Scope Resolution (Tag System)

**What**: Restrictions are scoped to countries, regulation groups, or geo-registration dates.
**Columns Involved**: TagType, TagId, TagValue
**Rules**:
- TagType='Country': applies to a specific country (TagValue = country name)
- TagType='CountryAndRegulation': applies to a country+regulation combination (e.g., "netherlands_cysec")
- TagType='RegulationGroup': applies to a regulatory group (TagValue resolved from Dim_Regulation.Name)
- TagType='GeoRegistrationDate': applies based on registration date rules

### 2.3 Instrument Scope (Dual Path)

**What**: Restrictions target either a specific instrument or an instrument type category.
**Columns Involved**: InstrumentID, InstrumentName, InstrumentTypeID, InstrumentType
**Rules**:
- Specific instrument: InstrumentID populated, InstrumentTypeID=NULL — e.g., BTC/USD (100000)
- Instrument type: InstrumentTypeID populated, InstrumentID=NULL — e.g., crypto (10), stocks (5)
- InstrumentTypeID mapping: Currencies=1, commodities=2, indices=4, stocks=5, etf=6, crypto=10, else=999

### 2.4 Change Detection

**What**: Identifies leverage changes by comparing today's values with the most recent previous snapshot.
**Columns Involved**: Old_Settings_Default_Value, Old_Settings_Max_Value, Old_CM_Default_Value, Old_CM_Max_Value
**Rules**:
- Self-join: reads previous day's row (same RestrictionId, latest Date < @Date)
- Old_ columns populated ONLY when New_ value differs from previous day's New_ value
- NULL in Old_ columns means no change (or first appearance)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Filter by Date for daily snapshots. For change detection queries, look for non-NULL Old_ columns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's leverage settings for a country | `WHERE Date = @today AND TagValue = 'France'` |
| Recent leverage changes | `WHERE Old_Settings_Default_Value IS NOT NULL OR Old_CM_Max_Value IS NOT NULL` |
| Crypto leverage by regulation | `WHERE InstrumentType = 'crypto' AND TagType = 'RegulationGroup'` |
| Active restrictions (not expired) | `WHERE EndDate = '9999-12-31'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Full instrument details |
| DWH_dbo.Dim_Regulation | TagValue = Name (WHERE TagType='RegulationGroup') | Regulation details |
| DWH_dbo.Dim_Country | TagValue = Name (WHERE TagType='Country') | Country details |

### 3.4 Gotchas

- **EndDate sentinel**: 9999-12-31 means the restriction is still active. Do not interpret as an actual expiration date.
- **InstrumentID is varchar(100)**: Despite being a numeric ID, it's stored as varchar. CAST to int for JOINs with Dim_Instrument.
- **Old_ columns are sparse**: NULL = no change. Only non-NULL values indicate a setting was modified.
- **Dual instrument scope**: Each row targets EITHER a specific InstrumentID OR an InstrumentType — never both. JOIN logic must handle both paths.
- **InstrumentTypeID 999**: Represents "forex" or unrecognized types (the ELSE case in the mapping).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot date. The SP execution date (@Date). Used as DELETE+INSERT key for daily refresh. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 2 | RestrictionId | bigint | YES | Unique identifier of the leverage restriction rule from SettingsDB.Settings.SystemRestrictions. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 3 | RestrictionType | varchar(7) | YES | Type of leverage limit. 'default'=platform standard leverage, 'max'=regulatory maximum allowed. Derived from ResourceName path. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 4 | TagType | varchar(100) | NO | Scope dimension of the restriction. Values: 'Country', 'CountryAndRegulation', 'RegulationGroup', 'GeoRegistrationDate'. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 5 | TagId | bigint | NO | Identifier of the tag scope. FK to SettingsDB.Settings.Tags. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 6 | TagValue | varchar(100) | YES | Human-readable scope value. Country name (e.g., "France"), country+regulation (e.g., "netherlands_cysec"), or regulation group name (e.g., "ASIC", "FinCEN"). RegulationGroup values resolved from Dim_Regulation.Name. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 7 | ResourceId | bigint | NO | Resource identifier from SettingsDB.Settings.Resources. Links the restriction to its leverage path definition. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 8 | BeginDate | datetime2(7) | NO | When this restriction rule became effective. From SettingsDB.Settings.Resources.BeginDate. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 9 | EndDate | datetime2(7) | NO | When this restriction rule expires. 9999-12-31 23:59:59.999999 = still active (no expiration). From SettingsDB.Settings.Resources.EndDate. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 10 | InstrumentID | varchar(100) | YES | Specific instrument targeted by this restriction. Extracted from ResourceName path suffix. NULL when restriction targets an instrument TYPE instead. Stored as varchar despite being numeric. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 11 | InstrumentName | varchar(50) | YES | Display name of the targeted instrument. Resolved from Dim_Instrument.Name by InstrumentID. NULL when targeting instrument type. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 12 | InstrumentTypeID | int | YES | Instrument type category ID. 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto, 999=forex/other. NULL when targeting a specific instrument. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 13 | InstrumentType | varchar(100) | YES | Instrument type category name (lowercase). Values: 'Currencies', 'commodities', 'indices', 'stocks', 'etf', 'crypto', 'forex'. NULL when targeting a specific instrument. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 14 | New_Settings_Default_Value | varchar(1000) | YES | Current platform settings default leverage value for this restriction. From SettingsDB SelectedValue where ResourceName LIKE '%default%'. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 15 | New_Settings_Max_Value | varchar(1000) | YES | Current platform settings maximum leverage value for this restriction. From SettingsDB SelectedValue where ResourceName LIKE '%max%'. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 16 | New_CM_Default_Value | int | YES | Current Capital Markets default leverage (from provider instrument leverage data). SUM where IsDefault=1. Only for 'default' RestrictionType. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 17 | New_CM_Max_Value | int | YES | Current Capital Markets maximum leverage (MAX from provider instrument leverage data). Only for 'max' RestrictionType. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 18 | Old_Settings_Default_Value | varchar(1000) | YES | Previous day's Settings default leverage. Populated ONLY when a change was detected (New != Old). NULL = no change or first occurrence. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 19 | Old_Settings_Max_Value | varchar(1000) | YES | Previous day's Settings max leverage. Populated ONLY when a change was detected. NULL = no change. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 20 | Old_CM_Default_Value | int | YES | Previous day's CM default leverage. Populated ONLY when a change was detected. NULL = no change. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |
| 21 | Old_CM_Max_Value | int | YES | Previous day's CM max leverage. Populated ONLY when a change was detected. NULL = no change. (Tier 2 — SP_BI_DB_Compliance_BI_Leverage_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | SP parameter | @Date | passthrough |
| RestrictionId | SettingsDB.Settings.SystemRestrictions | RestrictionId | passthrough |
| RestrictionType | SettingsDB.Settings.Resources | ResourceName | computed path extraction |
| TagType/TagId/TagValue | SettingsDB.Settings.Tags + Dim_Regulation | TagType/TagId/TagValue/Name | passthrough + regulation name resolution |
| ResourceId/BeginDate/EndDate | SettingsDB.Settings.Resources | ResourceId/BeginDate/EndDate | passthrough |
| InstrumentID/Name | Resources + Dim_Instrument | ResourceName suffix / Name | computed extraction + dim lookup |
| InstrumentTypeID/Type | Resources | ResourceName suffix | computed mapping |
| New_Settings_* | SystemRestrictions | SelectedValue | passthrough (split by default/max) |
| New_CM_* | Trade.ProviderInstrumentToLeverage + Dictionary.Leverage | Leverage values | computed aggregation |
| Old_* | Self (previous day) | New_* | change detection |

### 5.2 ETL Pipeline

```
SettingsDB.Settings.Resources (leverage resource paths)
SettingsDB.Settings.SystemRestrictions (restriction rules + values)
SettingsDB.Settings.Tags (scope metadata)
  |-- External Tables (lake export)
  v
BI_DB_dbo.External_SettingsDB_Settings_* (3 external tables)
  +-- DWH_dbo.Dim_Regulation (regulation name lookup)
  +-- DWH_dbo.Dim_Instrument (instrument name lookup)
  +-- External_etoro_Trade_ProviderInstrumentToLeverage (CM leverage)
  +-- External_etoro_Dictionary_Leverage (leverage values)
  +-- External_etoro_Trade_InstrumentMetaData (instrument type)
  |
  |-- SP_BI_DB_Compliance_BI_Leverage_Dashboard @Date (daily)
  |   Steps: restrictions → instrument resolution → default/max split
  |   → CM leverage join → change detection vs previous day
  |   DELETE WHERE Date=@Date + INSERT
  v
BI_DB_dbo.Compliance_BI_Leverage_Dashboard (534K rows, accumulating daily)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument details (varchar FK) |
| TagValue | DWH_dbo.Dim_Regulation | Regulation name (for RegulationGroup tags) |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| Self (previous day) | Self-reference | Change detection reads own previous snapshot |

---

## 7. Sample Queries

### 7.1 Current Leverage Settings for Crypto by Regulation

```sql
SELECT TagValue AS Regulation, RestrictionType, New_Settings_Max_Value, New_CM_Max_Value
FROM BI_DB_dbo.Compliance_BI_Leverage_Dashboard
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.Compliance_BI_Leverage_Dashboard)
  AND InstrumentType = 'crypto'
  AND TagType = 'RegulationGroup'
ORDER BY TagValue, RestrictionType
```

### 7.2 Recent Leverage Changes

```sql
SELECT Date, TagValue, InstrumentType, InstrumentName, RestrictionType,
       Old_Settings_Max_Value AS previous, New_Settings_Max_Value AS current
FROM BI_DB_dbo.Compliance_BI_Leverage_Dashboard
WHERE Date >= DATEADD(DAY, -7, GETDATE())
  AND Old_Settings_Max_Value IS NOT NULL
ORDER BY Date DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found for "Compliance_BI_Leverage_Dashboard". Context derived from SP code and SettingsDB source structure.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.Compliance_BI_Leverage_Dashboard | Type: Table | Production Source: SP_BI_DB_Compliance_BI_Leverage_Dashboard (ETL-computed from SettingsDB + CM leverage)*
