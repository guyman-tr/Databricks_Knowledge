# BI_DB_dbo.BI_DB_Payoneer_Revenue_Report

> 8.6K-row monthly aggregation comparing revenue from Payoneer depositors vs non-Payoneer depositors by country. Covers 47 months from June 2022 to present. Daily DELETE+INSERT by month from Fact_SnapshotCustomer + Fact_BillingDeposit + BI_DB_DailyCommisionReport.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (population) + BI_DB_DailyCommisionReport (revenue) via `SP_Payoneer_Revenue_Report` |
| **Refresh** | Daily (DELETE+INSERT by EndofMonth, @Date parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~8,611 (as of 2026-04-13) |

---

## 1. Business Meaning

`BI_DB_Payoneer_Revenue_Report` is a monthly aggregation table that segments the customer base by whether they have ever used Payoneer (FundingTypeID=39) as a deposit method, then measures revenue generated per country. This supports business analysis of Payoneer as a payment method — comparing client counts and revenue between Payoneer users and customers using only other Methods of Payment (MOP).

The population is restricted to: valid customers (`IsValidCustomer=1`), depositors (`IsDepositor=1`), fully verified (`VerificationLevelID=3`), Normal or Warning status (`PlayerStatusID IN 1,5`), with first deposit date on or after 2020-01-01. Customers are identified via `Fact_SnapshotCustomer` with date range validity from `Dim_Range`.

Revenue is computed from `BI_DB_DailyCommisionReport` as `SUM(FullCommissions + RollOverFee)` for the month. The Payoneer indicator checks all historical deposits (from 2020 onward) — if a customer has EVER deposited via Payoneer, they are classified as "Payoneer Only/Both Payoneer and other MOP" regardless of whether the revenue-generating month used Payoneer.

As of 2026-04-13: 8,611 aggregated rows across 47 months (Jun 2022 to Apr 2026). Payoneer usage is extremely small: 491 country-month rows (11K total clients, $202K revenue) vs 8,120 rows for non-Payoneer (182M client-months, $2.2B revenue).

---

## 2. Business Logic

### 2.1 Client Type Classification

**What**: Binary segmentation of customers by Payoneer usage history.
**Columns Involved**: `Client Type`
**Rules**:
- 'Payoneer Only/Both Payoneer and other MOP': Customer has at least one deposit with FundingTypeID=39, PaymentStatusID=2, ModificationDate since 2020-01-01
- 'Only Other MOP': No Payoneer deposits found
- Classification is LIFETIME (not per-month) — once a Payoneer user, always classified as Payoneer

### 2.2 Revenue Calculation

**What**: Monthly revenue from BI_DB_DailyCommisionReport.
**Columns Involved**: `Revenue`, `Clients Generated Revenue`
**Rules**:
- Revenue = SUM(FullCommissions + RollOverFee) for DateID within the month
- Clients Generated Revenue = COUNT of customers with Revenue >= 0 (includes zero-revenue clients)
- Clients = total COUNT of customers in the group (including NULL/negative revenue)

### 2.3 Monthly Partitioning

**What**: Data is partitioned by EndofMonth. Daily runs DELETE+INSERT the current month only.
**Columns Involved**: `EndofMonth`
**Rules**:
- EndofMonth = EOMONTH(@Date) — always the last day of the parameter month
- Historical months are not re-computed unless the SP is re-run with an older date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table, no optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Payoneer revenue by month | `WHERE [Client Type] LIKE 'Payoneer%' GROUP BY EndofMonth` |
| Country-level Payoneer penetration | `GROUP BY Country, [Client Type]` |
| Monthly trend | `GROUP BY EndofMonth ORDER BY EndofMonth` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| No common JOINs | — | Self-contained aggregation table |

### 3.4 Gotchas

- **Column with space**: `[Client Type]` and `[Clients Generated Revenue]` require square brackets
- **Payoneer is lifetime**: A customer classified as Payoneer in one month stays Payoneer forever, even if they stop using it
- **Revenue can be negative**: Due to rollover fees or reversed commissions
- **Clients Generated Revenue vs Clients**: "Generated Revenue" counts clients with Revenue >= 0 (inclusive of zero), not strictly positive revenue
- **FTD >= 2020**: Only customers with FirstDepositDate from 2020 onward are included — older accounts excluded

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | EndofMonth | date | YES | Last day of the reporting month. Computed as EOMONTH(@Date). Used as the partition key for DELETE+INSERT. (Tier 2 — SP_Payoneer_Revenue_Report) |
| 2 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 3 | Client Type | varchar(50) | YES | Binary classification: 'Payoneer Only/Both Payoneer and other MOP' if customer has ever deposited via Payoneer (FundingTypeID=39, PaymentStatusID=2, since 2020); 'Only Other MOP' otherwise. Lifetime flag, not per-month. (Tier 2 — SP_Payoneer_Revenue_Report) |
| 4 | Clients Generated Revenue | int | YES | Count of distinct customers in the group who generated non-negative revenue (Revenue >= 0) during the month. Includes zero-revenue clients. (Tier 2 — SP_Payoneer_Revenue_Report) |
| 5 | Clients | int | YES | Total count of distinct customers in the Country + Client Type group for the month. Includes customers with NULL or negative revenue. (Tier 2 — SP_Payoneer_Revenue_Report) |
| 6 | Revenue | money | YES | Total monthly revenue for the group. SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport. Can be negative due to reversed commissions or rollover fees. (Tier 2 — SP_Payoneer_Revenue_Report, BI_DB_DailyCommisionReport) |
| 7 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 — SP_Payoneer_Revenue_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (verified depositors, VL3, Normal/Warning)
  + DWH_dbo.Dim_Customer (FirstDepositDate >= 2020)
  + DWH_dbo.Dim_Country (country name)
  + DWH_dbo.Dim_Range (date range validity)
  + DWH_dbo.Fact_BillingDeposit (Payoneer FundingTypeID=39)
  + BI_DB_dbo.BI_DB_DailyCommisionReport (FullCommissions + RollOverFee)
  |
  |-- SP_Payoneer_Revenue_Report @Date (daily DELETE+INSERT by EndofMonth)
  |   Step 1: Find verified depositors active in month (via Fact_SnapshotCustomer + Dim_Range)
  |   Step 2: Mark Payoneer indicator (any deposit with FundingTypeID=39 since 2020)
  |   Step 3: Calculate monthly revenue from DailyCommisionReport
  |   Step 4: Aggregate by EndofMonth + Country + Client Type
  |   Step 5: DELETE current month + INSERT new data
  v
BI_DB_dbo.BI_DB_Payoneer_Revenue_Report (8.6K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | DWH_dbo.Dim_Country (Name) | Country dimension |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | Revenue source (FullCommissions + RollOverFee) |
| (population) | DWH_dbo.Fact_SnapshotCustomer | Customer population source |
| (Payoneer flag) | DWH_dbo.Fact_BillingDeposit | Deposit method classification |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Monthly Payoneer Revenue Trend

```sql
SELECT EndofMonth, [Client Type], SUM(Clients) AS total_clients, SUM(Revenue) AS total_revenue
FROM BI_DB_dbo.BI_DB_Payoneer_Revenue_Report
GROUP BY EndofMonth, [Client Type]
ORDER BY EndofMonth DESC
```

### 7.2 Top Countries by Payoneer Adoption

```sql
SELECT Country, SUM(Clients) AS payoneer_clients, SUM(Revenue) AS payoneer_revenue
FROM BI_DB_dbo.BI_DB_Payoneer_Revenue_Report
WHERE [Client Type] LIKE 'Payoneer%'
GROUP BY Country
ORDER BY payoneer_clients DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 1 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Payoneer_Revenue_Report | Type: Table | Production Source: Fact_SnapshotCustomer + DailyCommisionReport via SP_Payoneer_Revenue_Report*
