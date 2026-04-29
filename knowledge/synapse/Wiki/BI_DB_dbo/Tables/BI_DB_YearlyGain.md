# BI_DB_dbo.BI_DB_YearlyGain

> 211M-row rolling 12-month portfolio gain table storing the geometrically compounded annual return percentage for every customer, computed daily from BI_DB_MonthlyGain — covering date ranges from Feb 2017 to Dec 2023 with gains ranging from -100% to extreme outliers. Refreshed daily by SP_M_YearlyGain via DELETE+INSERT by EndDate. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_M_YearlyGain` from BI_DB_MonthlyGain |
| **Refresh** | Daily — DELETE WHERE EndDate=@date + INSERT. Accumulating by EndDate. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table provides the **rolling 12-month portfolio return** for every eToro customer. For each customer and date, the yearly gain is the cumulative compound return calculated by geometrically chaining all monthly gains from BI_DB_MonthlyGain over the trailing 12-month window.

The 211M rows represent one entry per customer per month-end date (Feb 2017 – Dec 2023). Each row captures the start date (first day of the 12-month window), end date, and the compound percentage gain. Values range from -100% (total loss) to extreme positive values (data quality outliers exist with gains > 10^18 suggesting missing cleanup on inactive/zero-equity accounts).

The SP runs daily — for each @date, it reads all monthly gains from @date-12months to @date, compounds them using `100*(EXP(SUM(LOG(1+MonthlyGain/100)))-1)`, and inserts one row per CID with the latest (most recent StartPeriod) result.

---

## 2. Business Logic

### 2.1 Geometric Compounding

**What**: Calculates cumulative return from monthly components using multiplicative (not additive) chaining.
**Columns Involved**: Gain
**Rules**:
- Formula: `100 * (EXP(SUM(LOG(1 + MonthlyGain/100))) - 1)`
- When `(1 + MonthlyGain/100) > 0`: uses standard LOG
- When `(1 + MonthlyGain/100) <= 0` (total monthly loss): substitutes -1 as LOG input (fallback for math domain)
- Only the row with ROW_NUMBER = 1 (latest StartPeriod DESC per CID) is kept

### 2.2 Rolling Window

**What**: Always covers exactly 12 months of history.
**Columns Involved**: StartDate, EndDate
**Rules**:
- EndDate = @date (the SP execution date)
- StartDate = first day after (EndDate - 1 year): `DATEADD(DAY, 1, DATEADD(YEAR, -1, @date))`
- Reads BI_DB_MonthlyGain WHERE StartPeriod BETWEEN @start_dt AND @date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no clustered index. Table is very large (211M rows). Always filter by EndDate or RealCID to avoid full scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest yearly gain for a customer | `WHERE RealCID = X ORDER BY EndDate DESC` (TOP 1) |
| Gain distribution for a specific period | `WHERE EndDate = 'YYYY-MM-DD'` |
| Customers with extreme gains | `WHERE EndDate = X AND Gain > 100` (or `< -50`) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer profile and segmentation |
| BI_DB_dbo.BI_DB_MonthlyGain | RealCID + date range | Underlying monthly components |

### 3.4 Gotchas

- **Extreme outliers**: Max gain values (>10^18) indicate data quality issues — likely customers with near-zero starting equity. Filter `WHERE Gain BETWEEN -100 AND 10000` for meaningful analysis.
- **211M rows with no index**: Full table scans are expensive. Always use WHERE EndDate = specific date for point-in-time queries.
- **Gain = 0**: Can mean either no trading activity or exact break-even. Check BI_DB_MonthlyGain for context.
- **-100% floor**: A gain of exactly -100 means total portfolio loss in the period.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki — verbatim description |
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID. FK to Dim_Customer.RealCID. One row per customer per EndDate. (Tier 2 — SP_M_YearlyGain) |
| 2 | StartDate | date | YES | First day of the 12-month rolling window. Calculated as DATEADD(DAY,1,DATEADD(YEAR,-1,EndDate)). (Tier 2 — SP_M_YearlyGain) |
| 3 | EndDate | date | YES | End of the 12-month rolling window. The SP execution date (@date). Used as DELETE+INSERT key. (Tier 2 — SP_M_YearlyGain) |
| 4 | Gain | float | YES | Geometrically compounded 12-month portfolio return as a percentage. Calculated as 100*(EXP(SUM(LOG(1+MonthlyGain/100)))-1). Range: -100 to extreme positives (outliers). Negative = loss, positive = gain, 0 = break-even or no activity. (Tier 2 — SP_M_YearlyGain) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_M_YearlyGain. (Tier 5 — ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| RealCID | BI_DB_MonthlyGain | RealCID | passthrough |
| StartDate | — | — | computed from @date |
| EndDate | — | @date | SP parameter |
| Gain | BI_DB_MonthlyGain | Gain | geometric compound over 12 months |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_MonthlyGain (monthly gain per CID)
  |
  |-- SP_M_YearlyGain @date (daily)
  |   Window: @date-12months to @date
  |   Formula: 100*(EXP(SUM(LOG(1+Gain/100)))-1)
  |   DELETE WHERE EndDate=@date + INSERT
  v
BI_DB_dbo.BI_DB_YearlyGain (211M rows, accumulating daily)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| — | — | No known downstream consumers in SSDT (likely consumed by reporting/dashboards) |

---

## 7. Sample Queries

### 7.1 Latest Yearly Gain Distribution

```sql
SELECT 
  CASE WHEN Gain < -50 THEN 'Heavy Loss (<-50%)'
       WHEN Gain BETWEEN -50 AND 0 THEN 'Loss (-50% to 0%)'
       WHEN Gain BETWEEN 0 AND 50 THEN 'Moderate Gain (0-50%)'
       WHEN Gain > 50 THEN 'Strong Gain (>50%)'
  END AS gain_bucket,
  COUNT(*) AS customers
FROM BI_DB_dbo.BI_DB_YearlyGain
WHERE EndDate = '2023-12-31'
GROUP BY CASE WHEN Gain < -50 THEN 'Heavy Loss (<-50%)'
              WHEN Gain BETWEEN -50 AND 0 THEN 'Loss (-50% to 0%)'
              WHEN Gain BETWEEN 0 AND 50 THEN 'Moderate Gain (0-50%)'
              WHEN Gain > 50 THEN 'Strong Gain (>50%)' END
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found for "YearlyGain". Context derived from SP code.

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 5/5, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_YearlyGain | Type: Table | Production Source: SP_M_YearlyGain (ETL-computed from BI_DB_MonthlyGain)*
