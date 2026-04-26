# BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers

## 1. Business Meaning

Daily outlier balance movement report for EU-regulated customers, split by credit report status transition direction. Each row represents one balance component metric for a given date, tracking the net balance movements of customers who transitioned between "valid credit report" and "invalid credit report" status.

"Outliers" in the CMR context are customers whose balance cycle gap status changed -- specifically those transitioning from Valid To Invalid (their credit report became invalid, flagging a potential issue) or Invalid to Valid (their credit report became valid again, resolving a prior flag). The table records what balance movements drove these transitions.

Written daily from `BI_DB_Outliers_New`, pivoting the Transition dimension into two columns: ValidToInvalid and InvalidToValid. This allows Finance to see the net balance impact for each direction of credit status change, broken down by 21 balance component types.

- **16,254 rows** across **774 dates** (2022-01-02 to 2026-04-07)
- **Always 21 rows per date** (SP inserts all metric rows regardless of zero values -- due to duplicate ExcelOrder 13 producing 21 instead of 20 rows)
- Latest non-zero activity: 2026-03-31 (all InvalidToValid direction)
- UC Target: _Not_Migrated

---

## 2. Business Logic

### Source
`BI_DB_dbo.BI_DB_Outliers_New` stores daily customer-level balance movements for outlier customers, with a Transition column classifying the direction of credit status change ('Valid To Invalid' or 'Invalid to Valid').

The SP queries `BI_DB_Outliers_New` for @dateID, running 20 UNION ALL branches -- one per balance component metric. Each branch sums the relevant CBCAN column grouped by Transition. The outer query then pivots:
```
ValidToInvalid = SUM(CASE WHEN Transition = 'Valid To Invalid' THEN MetricValue ELSE 0 END)
InvalidToValid = SUM(CASE WHEN Transition = 'Invalid to Valid' THEN MetricValue ELSE 0 END)
```

### Metrics (ExcelOrder 1-20, with duplicate ExcelOrder 13)
| ExcelOrder | Metric | Notes |
|---|---|---|
| 1 | Deposit Amounts | |
| 2 | Compensation Deposit | |
| 3 | GivenBonus | |
| 4 | Compensation | |
| 5 | Compensation PI | Popular Investor compensation |
| 6 | Compensation To Affiliates | |
| 7 | Cashout Amounts | |
| 8 | Compensation Cashouts | |
| 9 | Cashout Fee | |
| 10 | Chargeback | |
| 11 | Refund | |
| 12 | ClientBalanceCommission | |
| 13 | Over The Weekend Fee | SP defect: shares ExcelOrder 13 with Lost Debt |
| 13 | Lost Debt | SP defect: shares ExcelOrder 13 with Over The Weekend Fee |
| 14 | Chargeback Loss | |
| 15 | Other Negative | |
| 16 | Foreclosure | |
| 17 | Compensation P&L Adjustment | |
| 18 | Compensation DormantFee | |
| 19 | ClientBalance Realized PnL | |
| 20 | Unrealized Commission Change | |

---

## 3. Query Advisory

### Distribution
- ROUND_ROBIN distribution; no skew risk.
- CLUSTERED INDEX on `DateID ASC` -- use DateID in WHERE predicates.
- Exactly 21 rows per date; small table overall (16,254 rows).

### Typical Access Patterns
- Filter on `Date` or `DateID` for a specific day.
- Filter on `ExcelOrder` or `Metric` to extract a specific balance component.
- Sum ValidToInvalid and InvalidToValid separately to compare directions.

### Known Gotchas
1. **Duplicate ExcelOrder 13.** Two metrics share ExcelOrder 13 in the SP: 'Over The Weekend Fee' and 'Lost Debt'. Filtering on `ExcelOrder = 13` returns 2 rows per date. Use `Metric` column to distinguish them.
2. **Zero rows are always inserted.** The SP inserts all 21 metric rows per date even when both ValidToInvalid and InvalidToValid are 0. Most rows on quiet days have all-zero values. Filter `WHERE ValidToInvalid <> 0 OR InvalidToValid <> 0` to find active movement.
3. **Values can be negative.** Balance components like Compensation Deposit and Cashout Fee can be negative in the outlier context.
4. **"EU" scope is implicit.** Despite the table name, the SP reads from `BI_DB_Outliers_New` without an explicit EU regulation filter. The "EU" scope comes from how `BI_DB_Outliers_New` is populated upstream.
5. **21 rows per date, not 20.** The duplicate ExcelOrder 13 means COUNT(DISTINCT ExcelOrder) = 20 but COUNT(DISTINCT Metric) = 21. Expect 21 rows per date in any per-date count.

---

## 4. Elements

| # | Column | Type | Nullable | PK | Description | Tier |
|---|--------|------|----------|----|-------------|------|
| 1 | Date | date | YES | -- | Reporting date. Matches @date SP parameter. | Tier 2 |
| 2 | DateID | int | YES | -- | Integer date key (YYYYMMDD). Derived as CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Clustered index key. | Tier 2 |
| 3 | ExcelOrder | int | YES | -- | Row sequence number hardcoded in SP. Note: values 1-20 with duplicate 13 ('Over The Weekend Fee' and 'Lost Debt' both have ExcelOrder = 13 -- SP defect). | Tier 2 |
| 4 | Metric | varchar(200) | YES | -- | Balance component name, hardcoded in SP. 21 distinct values (including two with ExcelOrder = 13). | Tier 2 |
| 5 | ValidToInvalid | money | YES | -- | Net balance movement amount for customers transitioning from valid to invalid credit report status on this date, for this metric. Zero when no such transitions occurred. Can be negative. | Tier 2 |
| 6 | InvalidToValid | money | YES | -- | Net balance movement amount for customers transitioning from invalid to valid credit report status on this date, for this metric. Zero when no such transitions occurred. Can be negative. | Tier 2 |
| 7 | UpdateDate | datetime | YES | -- | ETL load timestamp. GETDATE() at INSERT time. | Propagation |

---

## 5. Lineage

See: [BI_DB_CMR_Phase2_EU_Outliers.lineage.md](BI_DB_CMR_Phase2_EU_Outliers.lineage.md)

**Writer SP**: `BI_DB_dbo.SP_CMR_Phase2_EU_Outliers`
**Refresh**: Daily (OpsDB Priority 15)
**Load Pattern**: DELETE WHERE Date = @date + INSERT

### Source Objects
| Source | Role |
|--------|------|
| `BI_DB_dbo.BI_DB_Outliers_New` | Sole source; customer balance movements by Transition type per date |

### Pipeline
```
BI_DB_dbo.BI_DB_Outliers_New (DateID = @dateID)
  20 UNION ALL branches (one per metric, with duplicate ExcelOrder 13)
  Inner GROUP BY: Date, DateID, Transition
  Outer pivot by Transition into ValidToInvalid / InvalidToValid
  GROUP BY ExcelOrder, Metric (produces 21 rows per date)

SP_CMR_Phase2_EU_Outliers(@date)
  DELETE FROM BI_DB_CMR_Phase2_EU_Outliers WHERE Date = @date
  INSERT INTO BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| `BI_DB_dbo.BI_DB_Outliers_New` | Source (sole upstream) | Customer-level outlier balance movements with Transition classification |
| `BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance` | Sibling (same CMR suite) | Full balance metrics pivoted vertically |
| `BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap` | Sibling (same CMR suite) | Daily cycle gap by regulation group |
| `BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp` | Sibling (same CMR suite) | Liability decomposition metrics |

---

## 7. Sample Queries

### Latest active day -- non-zero outlier movements
```sql
SELECT
    ExcelOrder,
    Metric,
    ValidToInvalid,
    InvalidToValid
FROM BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers
WHERE Date = (
    SELECT MAX(Date)
    FROM BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers
    WHERE ValidToInvalid <> 0 OR InvalidToValid <> 0
)
ORDER BY ExcelOrder, Metric;
```

### Net outlier balance impact by metric (last 30 days)
```sql
SELECT
    Metric,
    SUM(ValidToInvalid) AS TotalValidToInvalid,
    SUM(InvalidToValid) AS TotalInvalidToValid,
    SUM(InvalidToValid) - SUM(ValidToInvalid) AS NetImpact
FROM BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers
WHERE Date >= DATEADD(day, -30, GETDATE())
GROUP BY Metric
ORDER BY ABS(SUM(InvalidToValid) - SUM(ValidToInvalid)) DESC;
```

### Trend of deposit amount outlier movements by month
```sql
SELECT
    DATEFROMPARTS(YEAR(Date), MONTH(Date), 1) AS MonthStart,
    SUM(ValidToInvalid) AS ValidToInvalid_Deposits,
    SUM(InvalidToValid) AS InvalidToValid_Deposits
FROM BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers
WHERE Metric = 'Deposit Amounts'
GROUP BY DATEFROMPARTS(YEAR(Date), MONTH(Date), 1)
ORDER BY MonthStart DESC;
```

---

## 8. Atlassian Knowledge

No Confluence or Jira sources found for this table. Business context derived from SP code analysis and data sampling.
