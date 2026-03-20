# DWH_dbo.Dim_RiskClassification

> Lookup table defining the 6 risk classification levels for customer accounts, with numeric RiskScore enabling quantitative risk comparison (Low=0 < Medium Low=25 < Medium=50 < Medium High=75 < High=100 < Unacceptable=200).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RiskClassification |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (RiskClassificationID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_RiskClassification defines the 6 overall risk classification levels for customer accounts. Each level has a numeric RiskScore enabling quantitative comparison: Low (0) < Medium Low (25) < Medium (50) < Medium High (75) < High (100) < Unacceptable (200). (Tier 1 - upstream wiki, Dictionary.RiskClassification)

Risk classification drives trading restrictions, deposit limits, and compliance review requirements. Customers with higher classifications may face reduced leverage, enhanced due diligence, or blocked access. The RiskCalculation schema computes classifications based on regulatory context (e.g., RiskCalculation.SetRiskClassificationForCySec) and stores them on BackOffice.Customer in two columns: RiskClassificationID (ongoing) and OnboardingRiskClassificationID (initial at registration).

Note: The DWH renames the production `Name` column to `RiskClassificationName`. No other DWH objects in the DWH_dbo schema reference this table directly - it is available for joins from fact tables that carry RiskClassificationID.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_RiskClassification.

---

## 2. Business Logic

### 2.1 Risk Score Hierarchy

**What**: The 6 levels are ordered by RiskScore, enabling threshold comparisons.

**Columns Involved**: `RiskClassificationID`, `RiskClassificationName`, `RiskScore`

**Rules**:
- Unacceptable (ID=3, Score=200): Highest risk - typically triggers immediate restrictions or account review
- High (ID=0, Score=100): Elevated risk - reduced leverage, enhanced monitoring
- Medium High (ID=4, Score=75): Between Medium and High
- Medium (ID=1, Score=50): Standard risk level for verified customers
- Medium Low (ID=5, Score=25): Between Low and Medium
- Low (ID=2, Score=0): Lowest risk - full trading privileges within regulatory bounds

**Note on IDs**: IDs are not ordered by severity. Always use RiskScore for ordered comparison.

```
Risk Score Hierarchy (ascending severity):
  ID=2 Low             ->  RiskScore=0
  ID=5 Medium Low      ->  RiskScore=25
  ID=1 Medium          ->  RiskScore=50
  ID=4 Medium High     ->  RiskScore=75
  ID=0 High            ->  RiskScore=100
  ID=3 Unacceptable    ->  RiskScore=200
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on RiskClassificationID. With 6 rows, REPLICATE is optimal. Join on RiskClassificationID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RiskClassificationID to label | `LEFT JOIN DWH_dbo.Dim_RiskClassification rc ON rc.RiskClassificationID = fact.RiskClassificationID` |
| Order classifications by severity | `ORDER BY rc.RiskScore DESC` |
| Customers with elevated risk (High or Unacceptable) | `WHERE rc.RiskScore >= 100` |

### 3.3 Gotchas

- **IDs not ordered by severity**: ID=0 is "High" (score=100) while ID=2 is "Low" (score=0). Do NOT use `ORDER BY RiskClassificationID` to sort by risk - use `ORDER BY RiskScore` instead.
- **No DWH views join this table**: No DWH_dbo views reference Dim_RiskClassification in the SSDT repo. Joins must be built manually from fact tables.
- **Name renamed**: Production column is `Name`; DWH stores it as `RiskClassificationName`.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.RiskClassification)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RiskClassificationID | int | YES | Primary key (nullable in DDL per REPLICATE pattern). 0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low. Referenced by CustomerStatic.RiskClassificationID and OnboardingRiskClassificationID. (Tier 1 - upstream wiki, Dictionary.RiskClassification) |
| 2 | RiskClassificationName | varchar(50) | YES | Human-readable classification label. Renamed from production `Name` column by ETL. Values: High, Medium, Low, Unacceptable, Medium High, Medium Low. (Tier 1 concept, Tier 2 - SP_Dictionaries_DL_To_Synapse rename) |
| 3 | RiskScore | int | YES | Numeric score for ordered risk comparison. Higher = higher risk. Range: 0 (Low) to 200 (Unacceptable). Use this column for severity ordering, NOT RiskClassificationID. (Tier 1 - upstream wiki, Dictionary.RiskClassification) |
| 4 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RiskClassificationID | etoro.Dictionary.RiskClassification | RiskClassificationID | passthrough |
| RiskClassificationName | etoro.Dictionary.RiskClassification | Name | rename |
| RiskScore | etoro.Dictionary.RiskClassification | RiskScore | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.RiskClassification.md (quality 9.2)

### 5.2 ETL Pipeline

```
etoro.Dictionary.RiskClassification -> Generic Pipeline -> DWH_staging.etoro_Dictionary_RiskClassification -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_RiskClassification
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.RiskClassification | 6 rows (IDs 0-5) |
| Staging | DWH_staging.etoro_Dictionary_RiskClassification | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Name -> RiskClassificationName. Adds UpdateDate. |
| Target | DWH_dbo.Dim_RiskClassification | 6 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns.

### 6.2 Referenced By (other objects point to this)

No DWH_dbo views or procedures reference this table directly in the SSDT repo. Fact tables carrying RiskClassificationID (e.g., CustomerStatic) can join to this table for label resolution.

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.CustomerStatic | RiskClassificationID | Customer ongoing risk classification |

---

## 7. Sample Queries

### 7.1 List all levels ordered by severity
```sql
SELECT
    RiskClassificationID,
    RiskClassificationName,
    RiskScore
FROM [DWH_dbo].[Dim_RiskClassification]
ORDER BY RiskScore ASC
```

### 7.2 Customer count by risk level
```sql
SELECT
    rc.RiskClassificationName,
    rc.RiskScore,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_RiskClassification] rc
    ON rc.RiskClassificationID = cs.RiskClassificationID
GROUP BY rc.RiskClassificationName, rc.RiskScore
ORDER BY rc.RiskScore DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 3 T1, 2 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_RiskClassification | Type: Table | Production Source: etoro.Dictionary.RiskClassification*
