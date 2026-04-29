# BI_DB_dbo.BI_DB_Revenue14DaysToBigQuery

> 1.64M-row daily table tracking cumulative revenue generated within the first 14 days after a customer's first deposit. Sourced from Dim_Customer (customer cohort) and BI_DB_CID_BalanceDays (14-day revenue metric). Used as a BigQuery export for LTV modeling. Refreshed daily via SP_Revenue14DaysToBigQuery since August 2022.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + BI_DB_dbo.BI_DB_CID_BalanceDays via SP_Revenue14DaysToBigQuery |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE+INSERT by cohort date |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated (BigQuery export — not in Unity Catalog) |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table captures the **first-14-day revenue** for every valid depositing customer, organized by their first deposit date cohort. Each row represents one customer's total revenue earned in the 14-day window starting from their first deposit.

The SP runs daily, targeting the cohort that deposited exactly 14 days prior (allowing the full 14-day window to complete). It first deletes any existing rows for that cohort date, then inserts fresh calculations. This creates a rolling dataset of all cohorts since August 2022.

**Purpose**: Exported to Google BigQuery for customer Lifetime Value (LTV) modeling. The 14-day revenue is a leading indicator used to predict long-term customer value.

**Key characteristics**:
- Only valid customers (`IsValidCustomer=1`) from Dim_Customer
- Revenue comes from BI_DB_CID_BalanceDays.Revenue14days (cumulative spread revenue in first 14 days)
- 12% of rows have NULL Revenue (customer had no trading activity in their first 14 days)
- Negative revenue (~0.2% of rows) indicates customers whose positions lost money during the window

---

## 2. Business Logic

### 2.1 Cohort Window Calculation

**What**: Each customer belongs to a single cohort defined by their FirstDepositDate.
**Columns Involved**: FirstDepositeDate, CID
**Rules**:
- SP parameter @date determines the run date
- @14daysbefore = @date - 14 days
- Only customers with FirstDepositDate = @14daysbefore are processed
- This ensures the full 14-day window has elapsed before capturing the metric

### 2.2 Revenue Metric

**What**: Cumulative revenue earned by the customer within their first 14 calendar days.
**Columns Involved**: Revenue
**Rules**:
- Source is BI_DB_CID_BalanceDays.Revenue14days — pre-computed by SP_CID_BalanceDays
- NULL = customer has not yet reached the D+14 milestone or had no activity
- Zero = customer traded but generated no revenue (e.g., zero-spread instruments)
- Negative = positions lost money during the window (rare, ~0.2%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key optimization possible. Table is small (1.64M rows) and designed for bulk export to BigQuery, not interactive Synapse queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average 14-day revenue by cohort month | `SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, FirstDepositeDate), 0), AVG(Revenue) GROUP BY ...` |
| Revenue percentile distribution | `SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Revenue) OVER()` |
| Cohort with highest LTV signal | `WHERE Revenue > 100 GROUP BY CAST(FirstDepositeDate AS DATE)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Enrich with customer demographics (country, regulation, player status) |
| BI_DB_dbo.BI_DB_CID_BalanceDays | CID = CID | Compare 14-day vs 30-day/60-day revenue milestones |

### 3.4 Gotchas

- **Column name typo**: `FirstDepositeDate` (extra 'e') — do not search for `FirstDepositDate` in this table
- **NULL Revenue**: Does not mean $0 — it means the milestone has not been calculated yet or the customer had zero activity
- **No PK enforced**: Duplicates are theoretically possible (though DELETE+INSERT pattern should prevent them)
- **BigQuery export target**: This table exists primarily for external export — it may not be the most efficient source for Synapse-internal analytics

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verified from upstream wiki (production DB documentation) | Upstream wiki verbatim |
| Tier 2 | Derived from SP code analysis | SP source code |
| Tier 5 | ETL infrastructure / metadata | System convention |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FirstDepositeDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from Dim_Customer (column name typo: "Deposite" vs "Deposit" in source). (Tier 2 — SP_Dim_Customer) |
| 2 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | Revenue | money | YES | Cumulative revenue from FTD through first 14 days. NULL = not yet at D+14 milestone, or no activity. Renamed from Revenue14days. (Tier 2 — SP_CID_BalanceDays) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the pipeline (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-----------------|---------------|-----------|
| FirstDepositeDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough (typo rename) |
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| Revenue | BI_DB_dbo.BI_DB_CID_BalanceDays | Revenue14days | Rename |
| UpdateDate | — | GETDATE() | ETL generated |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (7.8M rows, HASH(RealCID))
  + BI_DB_dbo.BI_DB_CID_BalanceDays (Revenue14days metric)
    |-- SP_Revenue14DaysToBigQuery @date (Daily, Priority 0)
    |-- JOIN ON RealCID = CID, WHERE IsValidCustomer=1, FirstDepositDate = @date-14
    v
BI_DB_dbo.BI_DB_Revenue14DaysToBigQuery (1.64M rows, ROUND_ROBIN HEAP)
    |-- External export ---|
    v
Google BigQuery (LTV modeling)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension lookup |

### 6.2 Referenced By (other objects point to this)

| Object | Context |
|--------|---------|
| BI_DB_dbo.BI_DB_CID_BalanceDays | References this table as a downstream consumer of Revenue14days |

---

## 7. Sample Queries

### 7.1 Average 14-Day Revenue by Cohort Month

```sql
SELECT
    FORMAT(FirstDepositeDate, 'yyyy-MM') AS CohortMonth,
    COUNT(*) AS Customers,
    AVG(Revenue) AS AvgRevenue14d,
    SUM(CASE WHEN Revenue > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctPositiveRevenue
FROM [BI_DB_dbo].[BI_DB_Revenue14DaysToBigQuery]
WHERE Revenue IS NOT NULL
GROUP BY FORMAT(FirstDepositeDate, 'yyyy-MM')
ORDER BY CohortMonth DESC
```

### 7.2 High-Value Early Revenue Customers

```sql
SELECT r.CID, r.Revenue, r.FirstDepositeDate, dc.CountryName, dc.RegulationName
FROM [BI_DB_dbo].[BI_DB_Revenue14DaysToBigQuery] r
JOIN [DWH_dbo].[Dim_Customer] dc ON r.CID = dc.RealCID
WHERE r.Revenue > 1000
ORDER BY r.Revenue DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. The table is referenced in BI_DB_CID_BalanceDays documentation as a downstream consumer for BigQuery LTV modeling.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 1 T1, 2 T2, 0 T3, 0 T4, 1 T5 | Elements: 4/4, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Revenue14DaysToBigQuery | Type: Table | Production Source: DWH_dbo.Dim_Customer + BI_DB_CID_BalanceDays*
