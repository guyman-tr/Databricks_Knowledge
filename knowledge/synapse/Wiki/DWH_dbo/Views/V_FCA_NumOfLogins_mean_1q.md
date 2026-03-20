# DWH_dbo.V_FCA_NumOfLogins_mean_1q

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_FCA_NumOfLogins_mean_1q]` |
| **Type** | View |
| **Base Tables** | `Fact_CustomerAction` |
| **Purpose** | Computes the rolling 3-month daily average login count per real customer (RealCID) for FCA regulatory reporting. |

## 2. Business Context

This view supports **FCA (Financial Conduct Authority)** regulatory requirements by measuring customer engagement through login frequency. It calculates a rolling quarterly average: total login events in the past 3 months divided by the number of calendar days in that window.

### Key Filters
- `ActionTypeID = 14` — Logins only (from the `Fact_CustomerAction` event table)
- `DateID` between 3 months ago and today
- Groups by `RealCID` to aggregate across demo/sub-accounts

### Computed at Query Time
The view uses `GETDATE()` for date boundaries, meaning it always reflects the trailing 3-month window relative to the query execution time. This makes it non-deterministic — results change daily without underlying data changes.

## 3. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | `Date` | date | Current date at query time (`CAST(GETDATE() AS DATE)`). Anchor for the rolling window. (Tier 2 — view DDL) |
| 2 | `RealCID` | int | Real customer ID. Groups all account types for one customer. FK to Dim_Customer. (Tier 2 — view DDL) |
| 3 | `NumOfLogins_mean_1q` | float | Average daily logins over the trailing 3-month window. Formula: `COUNT(*) / DATEDIFF(day, DATEADD(month,-3,GETDATE()), GETDATE())`. (Tier 2 — view DDL) |

## 4. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| Non-deterministic | Low | Uses `GETDATE()` — results shift daily. Not suitable for snapshot comparisons without materializing. |
| NOLOCK hint | Medium | Reads with `NOLOCK` — may return uncommitted data during Fact_CustomerAction ETL windows. |

---
*Generated: 2026-03-19 | Quality: 8/10 | FCA regulatory login frequency view*
