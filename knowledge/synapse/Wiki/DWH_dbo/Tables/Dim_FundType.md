# DWH_dbo.Dim_FundType

> Fund type dimension - maps integer codes to labels classifying eToro Smart Portfolios as TopTraders (1), Partners (2), or Market (3).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.FundType |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (FundTypeID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FundType` is a 3-row dictionary classifying eToro Smart Portfolios (Funds) by their curation model:
- 1 = TopTraders: Portfolios built from eToro's highest-performing copy traders
- 2 = Partners: Portfolios curated by eToro partner organizations or affiliates
- 3 = Market: Thematic or sector-based market portfolios (the dominant type with 795 of 877 funds)

This dimension is the FK target for `DWH_dbo.Dim_Fund.FundType`. The data originates from `etoro.Dictionary.FundType` via `DWH_staging.etoro_Dictionary_FundType`. ETL: TRUNCATE + INSERT with `Description` renamed to `FundTypeName`.

---

## 2. Business Logic

### 2.1 Fund Type Classification

**What**: The three fund types represent different portfolio management models on eToro.

**Columns Involved**: `FundTypeID`, `FundTypeName`

**Rules**:
- 1 = TopTraders: Curated from eToro's best-performing copy traders; performance-driven
- 2 = Partners: Managed by external partners/affiliates; relationship-driven
- 3 = Market: Thematic (sectors, geographies, asset classes); the largest category

**Fund distribution** (from Dim_Fund, 2026-03-11):
```
1 (TopTraders):  38 funds  (4.3%)
2 (Partners):    44 funds  (5.0%)
3 (Market):     795 funds  (90.6%)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (3 rows - appropriate). CLUSTERED INDEX on FundTypeID. No data movement on joins from any table.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 3 rows - broadcast join automatic. No partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FundType code | `LEFT JOIN DWH_dbo.Dim_FundType ON FundType = FundTypeID` |
| Count funds by type | `JOIN Dim_Fund ON FundType = FundTypeID GROUP BY FundTypeName` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Fund | ON FundTypeID = FundType | Add fund type label to fund records |

### 3.4 Gotchas

- **Description renamed**: Source column is `Description`, not `FundTypeName`. If querying staging directly, use `Description`.
- **3 stable values**: Unlike most dictionary tables, FundType has been 3 values since inception. New fund types (e.g., "Crypto" portfolio type) would appear here first.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundTypeID | int | NO | Primary key identifying the fund category. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). Referenced by Trade.Fund to classify each CopyFund/SmartPortfolio. Replicated to SettingsDB for configuration management. (Tier 1 — Dictionary.FundType) |
| 2 | FundTypeName | varchar(50) | NO | Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category. (Tier 1 — Dictionary.FundType) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FundTypeID | etoro.Dictionary.FundType | FundTypeID | passthrough |
| FundTypeName | etoro.Dictionary.FundType | Description | rename: Description -> FundTypeName |
| UpdateDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.FundType -> Generic Pipeline -> DWH_staging.etoro_Dictionary_FundType -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 632) -> DWH_dbo.Dim_FundType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.FundType | Fund type dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/FundType/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_FundType | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Description -> FundTypeName rename. UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_FundType | 3-row REPLICATE/CLUSTERED fund type dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Fund | FundType | FK from Dim_Fund.FundType to this table's FundTypeID |

---

## 7. Sample Queries

### 7.1 All fund types

```sql
SELECT FundTypeID, FundTypeName
FROM DWH_dbo.Dim_FundType
ORDER BY FundTypeID
```

### 7.2 Fund count by type

```sql
SELECT ft.FundTypeName, COUNT(*) AS FundCount
FROM DWH_dbo.Dim_Fund f
JOIN DWH_dbo.Dim_FundType ft ON f.FundType = ft.FundTypeID
GROUP BY ft.FundTypeName
ORDER BY FundCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.0/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 8/10, Relationships: 8/10, Sources: 7/10*
*Object: DWH_dbo.Dim_FundType | Type: Table | Production Source: etoro.Dictionary.FundType*
