# BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned

> **Configuration/budget table — 0 rows (currently empty).** Stores manually-entered monthly planned targets for affiliate channel performance: new affiliates with FTDs, total active affiliates, churn rate, and total FTDs, broken down by desk. Consumed by SP_M_Active_Affiliate_Monthly (P99, SB_FinanceReportSPS) which LEFT JOINs planned values with actual affiliate metrics to produce BI_DB_ActiveAffiliatesPlanned_Actual. Author: Eti Rozolio (2020-01-29).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Manual input (budget/plan data) |
| **Refresh** | Manual — no automated ETL. Data is loaded by business users or analysts. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (YearMonth ASC, Desk ASC) |
| **Row Count** | 0 (empty — no plans currently loaded) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_ActiveAffiliatesPlanned` is a **plan/budget configuration table** for the affiliate channel. It is designed to hold monthly targets for key affiliate performance KPIs — how many new affiliates should bring FTDs, how many total active affiliates are expected, what churn rate is acceptable, and how many total FTDs should come through the affiliate channel, all segmented by desk (e.g., geographic or business unit groupings based on Dim_Country.Desk).

The table is consumed by `SP_M_Active_Affiliate_Monthly` which:
1. Computes actual affiliate metrics (registrations, FTDs, new vs returning affiliates) from `BI_DB_CIDFirstDates` + `Dim_Affiliate` + `Dim_Channel` + `Dim_Country`
2. LEFT JOINs these actuals against the planned values in this table
3. Inserts the combined actual-vs-planned record into `BI_DB_ActiveAffiliatesPlanned_Actual`

The SP filters affiliates by Channel IN ('Affiliate', 'Introducing Agents') and runs monthly at Priority 99 (FinanceReportSPS process).

**The table is currently empty (0 rows)**, meaning the planned-value columns in BI_DB_ActiveAffiliatesPlanned_Actual will be NULL for all months. This suggests the budget/plan upload process is either discontinued or uses an alternative mechanism.

---

## 2. Business Logic

### 2.1 Desk-Level Planning

**What**: Plans are segmented by desk, which maps to geographic/organizational groups from Dim_Country.
**Columns Involved**: Desk, YearMonth
**Rules**:
- Each row represents one desk's planned targets for one month
- Composite key: (YearMonth, Desk) — enforced by the clustered index
- Desk values correspond to DISTINCT Region→Desk mappings in Dim_Country

### 2.2 Plan vs Actual Comparison

**What**: Planned values are joined to actual metrics in the monthly SP.
**Columns Involved**: NewAffWithFTD, TotalActiveAff, Churn, TotalFTDs
**Rules**:
- LEFT JOIN on (YearMonth, Desk) ensures actuals appear even when no plan exists
- When plan is missing (0 rows as now), planned columns in _Actual table are NULL

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI(YearMonth, Desk). Table is empty. If populated, YearMonth+Desk is the natural lookup key.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| View current plans | `SELECT * FROM BI_DB_ActiveAffiliatesPlanned ORDER BY YearMonth, Desk` |
| Check if plans exist for a month | `WHERE YearMonth = '2026-04'` |
| Compare to actuals | `JOIN BI_DB_ActiveAffiliatesPlanned_Actual ON YearMonth AND Desk` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual | YearMonth, Desk | View planned vs actual side-by-side |

### 3.4 Gotchas

- **Table is empty**: No plan data is currently loaded. All planned columns in _Actual will be NULL.
- **Manual input table**: No automated ETL — data must be uploaded manually (INSERT or bulk load).
- **Column count**: DDL has 7 columns (not 8 as stated in the batch assignment).
- **Churn is a float**: No constraint on range — could contain values > 1 or negative if misloaded.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Desk | varchar(50) | NO | Affiliate desk/team identifier. Maps to geographic or organizational groups from Dim_Country.Desk (e.g., by region). Composite key with YearMonth. (Tier 4 — inferred from SP_M_Active_Affiliate_Monthly consumer) |
| 2 | YearMonth | varchar(7) | NO | Target month in YYYY-MM format (e.g., '2026-04'). Composite key with Desk. Clustered index leading column. (Tier 4 — inferred from SP_M_Active_Affiliate_Monthly consumer) |
| 3 | NewAffWithFTD | int | YES | Planned count of new affiliates expected to bring at least one first-time deposit in the target month. (Tier 4 — inferred from SP_M_Active_Affiliate_Monthly consumer) |
| 4 | TotalActiveAff | int | YES | Planned total count of active affiliates (those with at least one FTD) expected in the target month. (Tier 4 — inferred from SP_M_Active_Affiliate_Monthly consumer) |
| 5 | Churn | float | YES | Planned churn rate for affiliates in the target month. Expected as a decimal fraction (e.g., 0.15 = 15% churn). (Tier 4 — inferred from column name and context) |
| 6 | TotalFTDs | int | YES | Planned total count of first-time deposits expected through the affiliate channel in the target month. (Tier 4 — inferred from SP_M_Active_Affiliate_Monthly consumer) |
| 7 | UpdateDate | datetime | YES | Timestamp when the plan row was entered or last updated. Manual input — not set by ETL. (Tier 5 — ETL infrastructure convention) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Manual input | — | No automated ETL — manually populated budget/plan data |

### 5.2 ETL Pipeline

```
Manual Plan/Budget Input (analysts or business users)
  |-- INSERT / bulk load ---|
  v
BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned (0 rows — config/plan table)
  |-- LEFT JOIN by SP_M_Active_Affiliate_Monthly @date ---|
  v
BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual (actual vs planned comparison)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Desk | DWH_dbo.Dim_Country | Desk values map to Dim_Country geographic groupings |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.SP_M_Active_Affiliate_Monthly | LEFT JOIN reader | Reads planned values to compare with actual affiliate metrics |
| BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual | Downstream consumer | Stores the joined actual-vs-planned result |

---

## 7. Sample Queries

### 7.1 View All Plans (if any exist)

```sql
SELECT *
FROM [BI_DB_dbo].[BI_DB_ActiveAffiliatesPlanned]
ORDER BY YearMonth, Desk
```

### 7.2 Load Sample Plan Data

```sql
-- Example INSERT for populating planned values:
INSERT INTO [BI_DB_dbo].[BI_DB_ActiveAffiliatesPlanned]
(Desk, YearMonth, NewAffWithFTD, TotalActiveAff, Churn, TotalFTDs, UpdateDate)
VALUES ('Europe', '2026-05', 50, 200, 0.10, 500, GETDATE())
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 6 T4, 1 T5 | Elements: 7/7, Logic: 7/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned | Type: Table | Production Source: Manual input*
