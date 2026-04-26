# BI_DB_dbo.BI_DB_FirstTimeRev10

> First-time milestone fact table recording when each customer (CID) first generated ≥$10 in aggregated commission from a single trading position. Exactly one row per CID; 2.9M rows covering 2017-06-01 to 2026-04-12. Populated daily by SP_FirstTimeRev10 (SB_Daily pipeline). Part of a $5/$10/$30 milestone series alongside BI_DB_FirstTimeRev5 and BI_DB_FirstTimeRev30.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Trade position close events (via SP_FirstTimeRev10) |
| **Refresh** | Daily; SP_FirstTimeRev10, Priority 0, SB_Daily process |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_FirstTimeRev10` tracks the first time each customer generates ≥$10 in trading commission (aggregated spread/revenue) from a single position. It is a deduplication table — once a CID appears, it will never appear again regardless of future qualifying positions. The record captures the exact position (`PositionID`), exact time (`Timestamp`), and the commission value (`AggregatedCommission`) of that milestone trade.

The table is part of the FirstTimeRev series:
- **BI_DB_FirstTimeRev5** — $5 threshold (min=$5.01, 994K CIDs, from 2022-03-01)
- **BI_DB_FirstTimeRev10** — $10 threshold (min=$10.01, 2.9M CIDs, from 2017-06-01) ← **this table**
- **BI_DB_FirstTimeRev30** — $30 threshold (min=$30.00, 229K CIDs, from 2023-01-01)

The milestone date in this table identifies when a customer first became a "meaningful revenue contributor" in the $10 tier — commonly used in marketing analytics (feeds into `BI_DB_MarketingMonthlyRawData` via `SP_Marketing_Cube`), retention analysis, and lifetime value modelling.

---

## 2. Business Logic

### 2.1 First-Time Milestone Deduplication

**What**: The table records only the FIRST qualifying event per CID — subsequent positions crossing $10 are not recorded.
**Columns Involved**: `CID`, `PositionID`, `Timestamp`, `AggregatedCommission`
**Rules**:
- Exactly 1 row per CID (confirmed: total_rows = distinct_cids = 2,899,549)
- Selection criterion: the position that FIRST caused AggregatedCommission ≥ $10 for a given CID
- Once a CID has a row, SP_FirstTimeRev10 will not insert a duplicate, even if the CID later closes positions with higher commissions
- `AggregatedCommission` reflects the commission from that specific first qualifying position (range: $10.01–$17,264.93; avg $17.65)

### 2.2 Commission Threshold ($10 Floor)

**What**: `AggregatedCommission` is always ≥ $10 in this table — this is the defining threshold.
**Columns Involved**: `AggregatedCommission`
**Rules**:
- All observed values ≥ $10.01 (minimum in production data)
- `AggregatedCommission` likely reflects the gross spread/commission eToro earned on the position, not the customer's P&L
- Contrast with sibling tables: Rev5 has min=$5.01 and Rev30 has min=$30.00, confirming the threshold naming convention
- The commission from a single position can be large (max $17,264.93) for heavily leveraged or large-notional trades

### 2.3 Date and Timestamp Semantics

**What**: `Date` and `Timestamp` capture the same event at different granularities.
**Columns Involved**: `Date`, `Timestamp`, `DateID`
**Rules**:
- `Timestamp` = exact datetime of the position close/commission recognition (e.g., 2026-04-12 22:05:25)
- `Date` = calendar date derived from Timestamp (e.g., 2026-04-12)
- `DateID` = integer YYYYMMDD representation of Date (e.g., 20260412) — used for joins to date dimension tables
- All three always represent the same moment at different precisions

---

## 3. Query Advisory

### 3.1 Distribution & Index

`HASH(CID)` — queries filtering by CID are co-located. The clustered index on `Date` makes date-bounded queries efficient for time-series analysis. Table is small (2.9M rows) — full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| When did a customer first hit $10 revenue? | `SELECT Date, Timestamp, AggregatedCommission FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] WHERE CID = @cid` |
| Monthly cohort of new $10 revenue customers | `SELECT YEAR(Date) AS yr, MONTH(Date) AS mo, COUNT(*) AS new_customers FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] GROUP BY YEAR(Date), MONTH(Date) ORDER BY yr, mo` |
| Customers who reached $10 but not yet $30 | `SELECT r10.CID FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] r10 LEFT JOIN [BI_DB_dbo].[BI_DB_FirstTimeRev30] r30 ON r10.CID = r30.CID WHERE r30.CID IS NULL` |
| Distribution of first-trade commission values | `SELECT CASE WHEN AggregatedCommission < 20 THEN '<$20' WHEN AggregatedCommission < 50 THEN '$20-$50' ELSE '$50+' END AS bucket, COUNT(*) AS cnt FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] GROUP BY CASE WHEN AggregatedCommission < 20 THEN '<$20' WHEN AggregatedCommission < 50 THEN '$20-$50' ELSE '$50+' END` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `r10.CID = dc.RealCID` | Customer demographics, registration date, country |
| BI_DB_dbo.BI_DB_FirstTimeRev30 | `r10.CID = r30.CID` | Identify which $10 customers also reached $30 tier |
| BI_DB_dbo.BI_DB_FirstTimeRev5 | `r10.CID = r5.CID` | Compare $5 vs $10 tier progression |

### 3.4 Gotchas

- **Never more than 1 row per CID** — COUNT(*) = COUNT(DISTINCT CID) always. Do not use GROUP BY CID expecting deduplication.
- **AggregatedCommission ≥ $10 always** — no null or sub-threshold values exist. The threshold is part of the SP selection logic.
- **SP code inaccessible** — `SP_FirstTimeRev10` exists in OpsDB (Daily, SB_Daily, P0) but SP definition is not exposed in sys.sql_modules or SSDT. Logic is inferred from data evidence.
- **Date ≠ UpdateDate** — UpdateDate is the ETL run timestamp (next-day early morning), not the trade date. Filter by `Date` for business date analysis.
- **Historical coverage from 2017-06-01** — customers who first crossed $10 before 2017-06-01 are not in this table (or the data predates the table's creation).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo wiki or production DB_Schema wiki) |
| Tier 2 | Derived from data sampling, sibling table comparison, or naming conventions |
| Tier 3 | Inferred from naming conventions or context only |
| Tier 4 | Undetermined — pending review |
| P | Propagation metadata (ETL timestamp columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date when this customer first generated ≥$10 in trading commission. Range: 2017-06-01 to 2026-04-12. (Tier 2 — data evidence) |
| 2 | Timestamp | datetime | YES | Exact datetime of the position close event that first crossed the $10 commission threshold for this CID. E.g., 2026-04-12 22:05:25.387. (Tier 2 — data evidence + naming) |
| 3 | CID | int | YES | Customer ID. Platform-internal primary key assigned at registration. This table has exactly 1 row per CID (2,899,549 distinct CIDs = 2,899,549 total rows). (Tier 1 — Customer.CustomerStatic) |
| 4 | PositionID | bigint | YES | ID of the trading position that was the first to generate ≥$10 in commission for this customer. FK to Trade.PositionTbl.PositionID. (Tier 2 — data evidence + naming) |
| 5 | AggregatedCommission | money | YES | Commission/spread revenue generated by the qualifying position. Always ≥ $10.01 (the threshold defining this table). Range: $10.01–$17,264.93; avg $17.65. This is eToro's earned revenue on the position, not the customer's P&L. (Tier 2 — data evidence) |
| 6 | DateID | int | YES | Integer date key in YYYYMMDD format (e.g., 20260412 for 2026-04-12). Used for joins to date dimension tables. Derived from Date. (Tier 2 — data evidence) |
| 7 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was written by SP_FirstTimeRev10. Typically next-day early morning (e.g., 2026-04-13 05:03:58 for Date=2026-04-12). (P) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | Trade position close event | close date | Calendar date of first qualifying event |
| Timestamp | Trade position close event | close timestamp | Exact datetime of first qualifying event |
| CID | Trade.PositionTbl / Customer | CID | Passthrough — first-occurrence dedup key |
| PositionID | Trade.PositionTbl | PositionID | Passthrough — position that crossed threshold |
| AggregatedCommission | Trade.PositionTbl | commission/spread | Commission from qualifying position |
| DateID | ETL | derived from Date | YYYYMMDD integer |
| UpdateDate | ETL pipeline | — | ETL write timestamp |

### 5.2 ETL Pipeline

```
Trade.PositionTbl (closed positions with commission ≥ $10)
  |-- SP_FirstTimeRev10 (Daily, SB_Daily, Priority 0) ---|
  |-- Filter: CID not already in BI_DB_FirstTimeRev10      |
  |-- Select: first qualifying position per CID            |
  v
BI_DB_dbo.BI_DB_FirstTimeRev10 (append-only, 1 row per CID)
  |-- SP_Marketing_Cube → BI_DB_dbo.BI_DB_MarketingMonthlyRawData (inferred)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer.CustomerStatic (CID) | Customer reference |
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer demographics |
| PositionID | Trade.PositionTbl (PositionID) | The qualifying trade position |

### 6.2 Referenced By

| Object | How Used |
|--------|---------|
| BI_DB_dbo.BI_DB_MarketingMonthlyRawData | Likely upstream — SP_Marketing_Cube reads FirstTimeRev milestones for cohort-level revenue attribution (confirm) |

---

## 7. Sample Queries

### Monthly cohort of first-time $10 revenue customers

```sql
SELECT
    YEAR(Date) AS yr,
    MONTH(Date) AS mo,
    COUNT(*) AS new_rev10_customers,
    AVG(AggregatedCommission) AS avg_first_commission
FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10]
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY yr, mo;
```

### Progression: customers who hit $10 but not $30

```sql
SELECT
    r10.CID,
    r10.Date AS first_rev10_date,
    r10.AggregatedCommission AS first_rev10_commission
FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] r10
LEFT JOIN [BI_DB_dbo].[BI_DB_FirstTimeRev30] r30 ON r10.CID = r30.CID
WHERE r30.CID IS NULL
  AND r10.Date >= '2026-01-01'
ORDER BY r10.Date DESC;
```

### Days to milestone: from registration to first $10 revenue

```sql
SELECT
    r10.CID,
    dc.RegisteredReal,
    r10.Date AS first_rev10_date,
    DATEDIFF(day, dc.RegisteredReal, r10.Date) AS days_to_rev10
FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] r10
JOIN [DWH_dbo].[Dim_Customer] dc ON r10.CID = dc.RealCID
WHERE r10.Date >= '2026-01-01'
ORDER BY days_to_rev10;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP_FirstTimeRev10 author details not available (SP definition inaccessible). Part of the FirstTimeRev milestone series (Rev5, Rev10, Rev30) used in marketing and revenue analytics.

---

*Generated: 2026-04-23 | Quality: 8.3/10 | Phases: 11/14*
*Tiers: 1 T1, 5 T2, 0 T3, 0 T4, 1 P | Elements: 7/7, Logic: 8/10, Data Evidence: 10/10*
*Object: BI_DB_dbo.BI_DB_FirstTimeRev10 | Type: Table | Production Source: Trade position events via SP_FirstTimeRev10*
