# BI_DB_dbo.BI_DB_CO_Cluster_Daily

> Daily cashout-cluster classification for customers who made a cashout on each report date. One row per customer per date cashed out. 13 columns, 4.6M rows, 1.7M distinct CIDs, data from 2024-01-01. Sourced from Fact_CustomerAction (ActionTypeID=8), Fact_SnapshotCustomer, Dim_Customer, and V_Liabilities via SP_BI_DB_CO_Cluster_Daily.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction (ActionTypeID=8) + DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Customer + DWH_dbo.V_Liabilities |
| **Refresh** | Daily — WHILE loop via SP_BI_DB_CO_Cluster_Daily (SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CO_Cluster_Daily classifies customers into behavioral segments ("clusters") on each day they make a cashout. It answers: **"What type of cashout behavior did this customer exhibit as of today's cashout?"**

Each row represents a single customer on a specific report date. Only customers who actually made a cashout (ActionTypeID=8 in Fact_CustomerAction) on that date appear. Customers who did not cash out on a given date have no row for that date.

The cluster assignment is cumulative — it reflects the customer's full cashout history up to and including the current date:

| CO_Cluster | Business Meaning |
|------------|-----------------|
| Null_Equity | Customer has no equity data (RealizedEquity = NULL) — cannot be classified |
| Churn_CO | Low-equity cashout: RealizedEquity at last CO < $10 — likely churning |
| OTC | One-Time Cashout: first and last CO are the same date — never cashed out before or since |
| Regular_CO | Frequent and/or recent cashout pattern — high withdrawal cadence or new-enough customer with multiple COs |
| Occasional_CO | Infrequent or lapsed cashout pattern — lower frequency or long gap since previous CO |
| Uncategorized | Does not fit any defined cluster — fallback category |

The table is primarily used by Retention, CRM, and Finance teams to segment withdrawing customers, monitor cashout behavior trends, and inform anti-churn interventions.

**Coverage**: 4.6M rows, 1.7M distinct CIDs. Data starts 2024-01-01 (hardcoded SP fallback if table is empty). Most recent data through 2026-04-12.

---

## 2. Business Logic

### 2.1 Population Filter — Cashout Customers Only

**What**: Only customers who cashed out on @Date are included in the daily output.

**Columns Involved**: CID, Report_Date

**Rules**:
- The SP uses `ActionTypeID=8` to identify cashouts in Fact_CustomerAction.
- ActionTypeID=8 is a cashout, not a redeem or airdrop.
- Only GCIDs who had a cashout on @Date are processed. Customers without a cashout that day have no row for that Report_Date.
- The SP then pulls **all historical cashouts** for those GCIDs (not just today's) to compute cumulative metrics.

### 2.2 CO_Cluster Classification Logic

**What**: Each row is assigned to one of 6 mutually-exclusive clusters based on equity, cashout count, seniority, and CO gap.

**Columns Involved**: CO_Cluster, RealizedEquity_CO, ACC_Cashouts, Seniority_in_Days, Prev_CO_Date, CO_Last_Transaction

**Rules** (applied in priority order — first match wins):

| Cluster | Condition | Priority |
|---------|-----------|----------|
| Null_Equity | RealizedEquity IS NULL | 1 (highest) |
| Churn_CO | RealizedEquity < 10 | 2 |
| OTC | CO_First_Transaction = CO_Last_Transaction AND RealizedEquity >= 10 | 3 |
| Regular_CO | Equity >= 10 AND (ACC_Cashouts >= 5 AND gap(Prev_CO_Date→Last_CO) <= 360d) | 4a |
| Regular_CO | Equity >= 10 AND (Seniority_in_Days <= 360 AND ACC_Cashouts >= 3) | 4b |
| Occasional_CO | Equity >= 10 AND (ACC_Cashouts >= 5 AND gap > 360d) | 5a |
| Occasional_CO | Equity >= 10 AND (Seniority_in_Days > 360 AND ACC_Cashouts IN (2,3,4)) | 5b |
| Occasional_CO | Equity >= 10 AND (Seniority_in_Days <= 360 AND ACC_Cashouts = 2) | 5c |
| Uncategorized | None of above | 6 (fallback) |

Key thresholds: RealizedEquity $10, ACC_Cashouts 3/5, Seniority/gap 360 days.

### 2.3 Cumulative Cashout Metrics

**What**: Metrics reflect ALL historical cashouts for the customer up to and including @Date.

**Columns Involved**: ACC_CO_AmountUSD, ACC_Cashouts, CO_First_Transaction, CO_Last_Transaction, Prev_CO_Date

**Rules**:
- `ACC_CO_AmountUSD`: SUM of all cashout amounts ever (ActionTypeID=8) for the customer.
- `ACC_Cashouts`: COUNT of all cashout transactions ever. This count is what drives the Regular/Occasional boundary.
- `CO_First_Transaction`: earliest ever cashout date (MIN).
- `CO_Last_Transaction`: most recent cashout date (MAX) — equals @Date for that day's row.
- `Prev_CO_Date`: second-most-recent cashout date, computed via ROW_NUMBER OVER (PARTITION BY CID ORDER BY Occurred DESC) — rn=2. Used to compute the CO frequency gap.

### 2.4 Equity Lookup — V_Liabilities at Last CO Date

**What**: RealizedEquity is looked up at the last cashout date, not today.

**Columns Involved**: RealizedEquity_CO

**Rules**:
- The SP joins `V_Liabilities` where `DateID = Last_Transaction_ID` (the DateID of the customer's last CO).
- `CASE WHEN RealizedEquity < 0 THEN 0 ELSE RealizedEquity END` — floored at 0 to prevent negative equity from triggering Churn_CO incorrectly.
- NULL if the customer has no V_Liabilities row for that DateID → assigned Null_Equity cluster.

### 2.5 DELETE + INSERT Pattern (Idempotent Per Date)

**What**: Each report date can be safely replayed.

**Columns Involved**: Report_Date_ID

**Rules**:
- SP DELETEs all rows WHERE Report_Date_ID = @DateID, then re-inserts.
- Historical rows (prior dates) are never touched.
- The WHILE loop processes from `MAX(Report_Date)+1` to `GETDATE()-1`. Starting point defaults to 2024-01-01 if the table is empty.

### 2.6 Seniority Definition

**What**: Seniority_in_Days measures customer age from first deposit to last cashout, not from registration.

**Columns Involved**: Seniority_in_Days

**Rules**:
- `DATEDIFF(DAY, Dim_Customer.FirstDepositDate, Last_CO_Transaction)`.
- Measures how long after first deposit the customer has been active.
- Used in the Regular_CO and Occasional_CO boundary conditions (360-day threshold).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CID) + HEAP. CID-based JOINs are co-located and efficient. No index — full scans are expected; filter on Report_Date_ID (an int) for date-range queries rather than Report_Date (a date column) where possible, as the SP stores Report_Date_ID as a bigint CAST of the YYYYMMDD integer.

### 3.2 One Row Per Customer Per Cashout Date

Each customer appears at most once per Report_Date. If a customer cashes out multiple times on the same day, the row reflects their cumulative state for that date (not one row per transaction). There is no transaction-level granularity here.

### 3.3 CO_Cluster is Point-in-Time on Report_Date

The cluster assignment as of Report_Date reflects metrics computed on that day. A customer's cluster can change from day to day as ACC_Cashouts and Seniority_in_Days accumulate. For the most recent cluster, query `MAX(Report_Date)` per CID, or filter to the latest available date.

### 3.4 No Rows for Non-Cashout Days

A customer who last cashed out on 2025-03-01 has no row for 2025-03-02 through 2026-04-12 (unless they cash out again). Do not use this table to track all customers or all dates — it is a sparse activity log for cashout days only.

### 3.5 Current_Day_CO_Amount Type Mismatch

`Current_Day_CO_Amount` is defined as `INT` in the DDL, not `MONEY`. Large cashout amounts may be truncated. Use `ACC_CO_AmountUSD` (money) for accurate total cashout amount. `Current_Day_CO_Amount` should be treated as an approximate integer amount.

### 3.6 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What cluster is customer X in today? | WHERE CID=X AND Report_Date = MAX(Report_Date) |
| Daily cluster distribution over time | GROUP BY Report_Date, CO_Cluster, COUNT(DISTINCT CID) |
| Customers who churned in last 30 days | WHERE CO_Cluster='Churn_CO' AND Report_Date >= DATEADD(DAY,-30,GETDATE()) |
| First-time cashout customers (OTC) | WHERE CO_Cluster='OTC' |
| High-value regular cashers | WHERE CO_Cluster='Regular_CO' AND RealizedEquity_CO > 1000 |
| Cluster migration — was Regular, now Occasional? | Self-join on CID between two Report_Dates |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - SP code / live data | (T2 - SP_BI_DB_CO_Cluster_Daily) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Report_Date | date | YES | The date for which this row was computed — the date the customer made a cashout. One row per CID per Report_Date. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 2 | Report_Date_ID | bigint | YES | Integer representation of Report_Date (YYYYMMDD format, e.g. 20240101). Used in DELETE/INSERT idempotency logic. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 3 | CID | int | YES | Customer identifier (RealCID). FK into DWH_dbo.Dim_Customer. HASH distribution key — CID-based JOINs are co-located. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 4 | CO_Cluster | nvarchar(50) | YES | Behavioral cashout cluster as of Report_Date. Values: Null_Equity, Churn_CO, OTC, Regular_CO, Occasional_CO, Uncategorized. See Business Logic §2.2 for full classification rules. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 5 | CO_First_Transaction | date | YES | Date of the customer's first-ever cashout (MIN of Occurred WHERE ActionTypeID=8). Equal to CO_Last_Transaction for OTC customers. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 6 | CO_Last_Transaction | date | YES | Date of the customer's most recent cashout (MAX of Occurred WHERE ActionTypeID=8). Always equals Report_Date for the daily output row. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 7 | Prev_CO_Date | date | YES | Date of the customer's second-most-recent cashout (rn=2 via ROW_NUMBER ORDER BY Occurred DESC). NULL for first-time cashout customers (OTC). Used in Regular_CO/Occasional_CO gap calculation. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 8 | Seniority_in_Days | int | YES | Days from customer's FirstDepositDate (Dim_Customer) to their last CO date. Measures cashout tenure, not account age. Threshold: 360 days separates Regular/Occasional boundaries. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 9 | RealizedEquity_CO | money | YES | Customer's realized equity (from V_Liabilities) as of their last cashout date. Floored at 0 (negative values set to 0). NULL if no V_Liabilities row exists for that DateID → Null_Equity cluster. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 10 | ACC_CO_AmountUSD | money | YES | Accumulated total USD cashout amount across all cashout transactions ever for this customer (SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=8). (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 11 | ACC_Cashouts | int | YES | Total number of cashout transactions ever for this customer (COUNT WHERE ActionTypeID=8). Key input to cluster thresholds: ≥3 and ≥5 are meaningful boundaries. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 12 | Current_Day_CO_Amount | int | YES | Today's cashout amount (SUM of Amount WHERE ActionTypeID=8 AND Occurred=@Date). Stored as INT — may truncate large values. Use ACC_CO_AmountUSD for accuracy. (T2 - SP_BI_DB_CO_Cluster_Daily) |
| 13 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_BI_DB_CO_Cluster_Daily (GETDATE()). (T2 - SP_BI_DB_CO_Cluster_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source Object | Notes |
|--------|---------------|-------|
| CID | DWH_dbo.Fact_CustomerAction | RealCID of customers with ActionTypeID=8 cashout on @Date |
| CO_First_Transaction | DWH_dbo.Fact_CustomerAction | MIN(Occurred) WHERE ActionTypeID=8 |
| CO_Last_Transaction | DWH_dbo.Fact_CustomerAction | MAX(Occurred) WHERE ActionTypeID=8 |
| Prev_CO_Date | DWH_dbo.Fact_CustomerAction | rn=2 in ROW_NUMBER OVER CID ORDER BY Occurred DESC |
| ACC_CO_AmountUSD | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8 |
| ACC_Cashouts | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=8 |
| Current_Day_CO_Amount | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8 AND Occurred=@Date |
| Seniority_in_Days | DWH_dbo.Dim_Customer | DATEDIFF(DAY, FirstDepositDate, Last_CO_Transaction) |
| RealizedEquity_CO | DWH_dbo.V_Liabilities | RealizedEquity WHERE DateID = Last_Transaction_ID; floored at 0 |
| IsValidCustomer filter | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer=1, IsDepositor filter via Dim_Customer |
| CO_Cluster | Computed | CASE WHEN rules on RealizedEquity, ACC_Cashouts, Seniority, CO gap |
| Report_Date | Computed | @Date (current loop date) |
| Report_Date_ID | Computed | CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) |
| UpdateDate | Computed | GETDATE() |

Full column-level mapping: see `BI_DB_CO_Cluster_Daily.lineage.md`.

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=8 cashouts — scope: GCIDs with CO on @Date, all historical COs)
  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer, PlayerLevelID, GCID → RealCID)
  + DWH_dbo.Dim_Range (date range filter: @DateID BETWEEN FromDateID AND ToDateID)
  + DWH_dbo.Dim_Customer (FirstDepositDate for Seniority_in_Days, IsDepositor filter)
  + DWH_dbo.V_Liabilities (RealizedEquity at last CO date: DateID = Last_Transaction_ID)
  -> SP_BI_DB_CO_Cluster_Daily (no @date parameter — self-determines from MAX(Report_Date))
     [WHILE loop from MAX(Report_Date)+1 to GETDATE()-1]
     [DELETE WHERE Report_Date_ID = @DateID + INSERT per date]
  -> BI_DB_dbo.BI_DB_CO_Cluster_Daily
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Object | Join Column | Purpose |
|--------|------------|---------|
| DWH_dbo.Fact_CustomerAction | RealCID, ActionTypeID=8 | Source of all cashout events and amounts |
| DWH_dbo.Fact_SnapshotCustomer | RealCID | Customer validity and GCID→RealCID mapping |
| DWH_dbo.Dim_Customer | RealCID | FirstDepositDate for Seniority_in_Days |
| DWH_dbo.V_Liabilities | DateID | RealizedEquity at last CO date |
| DWH_dbo.Dim_Range | DateID | Date range filtering for daily scope |

### 6.2 Referenced By (other objects point to this)

| Source Object | Use | Description |
|--------------|-----|-------------|
| Retention / CRM reports | CID + CO_Cluster + Report_Date | Daily cashout segmentation for intervention targeting |
| Finance / Risk dashboards | CO_Cluster + RealizedEquity_CO | Cashout risk monitoring, churn detection |
| Customer lifecycle analytics | ACC_Cashouts + Seniority_in_Days | Behavioral trend analysis |

---

## 7. Sample Queries

### 7.1 Daily cluster distribution for last 30 days

```sql
SELECT Report_Date,
       CO_Cluster,
       COUNT(DISTINCT CID)      AS distinct_customers,
       SUM(Current_Day_CO_Amount) AS total_co_amount
FROM   [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]
WHERE  Report_Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY Report_Date, CO_Cluster
ORDER BY Report_Date DESC, distinct_customers DESC;
```

### 7.2 Latest cluster assignment for a specific customer

```sql
SELECT TOP 1
       CID, CO_Cluster, Report_Date,
       ACC_Cashouts, RealizedEquity_CO, Seniority_in_Days
FROM   [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]
WHERE  CID = 12345678
ORDER BY Report_Date DESC;
```

### 7.3 Customers who were Regular_CO but are now Churn_CO (cluster regression)

```sql
WITH latest AS (
    SELECT CID, CO_Cluster AS current_cluster, Report_Date AS latest_date
    FROM   [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]
    WHERE  Report_Date = (SELECT MAX(Report_Date) FROM [BI_DB_dbo].[BI_DB_CO_Cluster_Daily])
),
prior AS (
    SELECT CID, CO_Cluster AS prior_cluster
    FROM   [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]
    WHERE  Report_Date = DATEADD(DAY, -30, (SELECT MAX(Report_Date) FROM [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]))
)
SELECT l.CID, p.prior_cluster, l.current_cluster, l.latest_date
FROM   latest l
JOIN   prior p ON l.CID = p.CID
WHERE  p.prior_cluster = 'Regular_CO'
  AND  l.current_cluster = 'Churn_CO';
```

### 7.4 OTC (one-time cashout) customers — first-time withdrawers

```sql
SELECT COUNT(DISTINCT CID)        AS otc_customers,
       AVG(RealizedEquity_CO)     AS avg_equity,
       AVG(Current_Day_CO_Amount) AS avg_co_amount
FROM   [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]
WHERE  CO_Cluster = 'OTC'
  AND  Report_Date >= DATEADD(DAY, -90, GETDATE());
```

### 7.5 High-equity Regular_CO customers in last 7 days (retention priority)

```sql
SELECT CID, Report_Date, RealizedEquity_CO, ACC_Cashouts, Seniority_in_Days
FROM   [BI_DB_dbo].[BI_DB_CO_Cluster_Daily]
WHERE  CO_Cluster = 'Regular_CO'
  AND  RealizedEquity_CO > 5000
  AND  Report_Date >= DATEADD(DAY, -7, GETDATE())
ORDER BY RealizedEquity_CO DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. Cashout cluster documentation may exist in Confluence under "Retention" or "CO Cluster" pages. SP logic is the primary authoritative source.

---

*Generated: 2026-04-23 | Quality: 8.3/10 (***) | Phases: 11/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_CO_Cluster_Daily | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction + Fact_SnapshotCustomer + Dim_Customer + V_Liabilities*
