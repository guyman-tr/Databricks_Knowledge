# DWH_dbo.V_FCA_NumOfLogins_mean_1q

> Computes the rolling 3-month daily average login count per real customer (RealCID) for FCA regulatory reporting, filtered to ActionTypeID = 14 (logins) from Fact_CustomerAction.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Tables** | DWH_dbo.Fact_CustomerAction |
| **Purpose** | FCA (Financial Conduct Authority) regulatory login frequency metric |

---

## 1. Business Meaning

`V_FCA_NumOfLogins_mean_1q` supports **FCA (Financial Conduct Authority)** regulatory requirements by measuring customer engagement through login frequency. It calculates a rolling quarterly average: total login events in the past 3 months divided by the number of calendar days in that window.

The view uses `GETDATE()` for date boundaries, meaning it always reflects the trailing 3-month window relative to the query execution time. This makes it non-deterministic — results change daily without underlying data changes.

### Key Filters
- `ActionTypeID = 14` — Logins only (from the Fact_CustomerAction event dictionary)
- `DateID` between 3 months ago and today (computed via DATEADD/CONVERT)
- Groups by `RealCID` to aggregate across all account types for one customer

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | Date | date | Computed | Current date at query time (`CAST(GETDATE() AS DATE)`). Anchor timestamp for the rolling 3-month window. Non-deterministic — changes daily. (Tier 2 — view DDL) |
| 2 | RealCID | int | Fact_CustomerAction.RealCID | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. GROUP BY key in this view. (Tier 1 — inherited from Fact_CustomerAction wiki) |
| 3 | NumOfLogins_mean_1q | float | Computed aggregate | Average daily logins over the trailing 3-month window. Formula: `COUNT(*) / DATEDIFF(day, DATEADD(month, -3, GETDATE()), GETDATE())`. Higher values indicate more engaged customers. (Tier 2 — view DDL) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Fact_CustomerAction | Source table (filtered WHERE ActionTypeID = 14) | Base table | Inbound |
| DWH_dbo.Dim_Customer | Via RealCID (not in view, logical FK) | Customer dimension | Logical |

---

## 4. ETL & Data Pipeline

No ETL — computed view with real-time evaluation. The underlying Fact_CustomerAction table receives daily inserts from the action tracking pipeline. The view's rolling window automatically shifts forward each day via `GETDATE()`.

---

## 5. Referenced By

| Object | Schema | Usage |
|--------|--------|-------|
| *(No downstream consumers found in SSDT)* | — | Leaf view — likely consumed by external reporting tools or FCA regulatory extracts |

---

## 6. Business Logic & Patterns

### Rolling Window Calculation

```sql
SELECT
    CAST(GETDATE() AS DATE) AS [Date],
    RealCID,
    COUNT(*) / CAST(DATEDIFF(day, DATEADD(month, -3, GETDATE()), GETDATE()) AS float)
        AS NumOfLogins_mean_1q
FROM [DWH_dbo].Fact_CustomerAction WITH(NOLOCK)
WHERE DateID BETWEEN
    CAST(CONVERT(VARCHAR(8), DATEADD(month, -3, GETDATE()), 112) AS INT)
    AND CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND ActionTypeID = 14
GROUP BY RealCID
```

The denominator (`DATEDIFF(day, ...)`) is the number of calendar days in the 3-month window, not the number of days the customer actually logged in. This produces a true daily average rate.

---

## 7. Query Advisory

### Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| Non-deterministic | Low | Uses `GETDATE()` — results shift daily. Not suitable for snapshot comparisons without materializing. |
| NOLOCK hint | Medium | Reads with `NOLOCK` — may return uncommitted/dirty reads during Fact_CustomerAction ETL windows. |
| Full scan | High | Scans all ActionTypeID = 14 rows in the trailing 3-month window across the entire ~11B row Fact_CustomerAction table. Filter on RealCID if joining. |

### Performance Notes

- Fact_CustomerAction is HASH-distributed on RealCID — the GROUP BY RealCID benefits from local aggregation
- The NCI on ActionTypeID+DateID supports the WHERE clause filter
- Consider materializing results if consumed by multiple downstream queries

---

*Generated: 2026-03-28 | Quality: 8.0/10 (★★★★☆) | Phases: 8/14 | Batch: 16*
*Tiers: 0 T1, 2 T2, 0 T3, 0 T4, 0 T5 (RealCID: T1 inherited from Fact_CustomerAction) | Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10*
*Object: DWH_dbo.V_FCA_NumOfLogins_mean_1q | Type: View | Base Tables: DWH_dbo.Fact_CustomerAction*
