# BI_DB_dbo.BI_DB_PI_GainDaily

> ~6.9M-row PI-specific shadow cache of DWH_GainDaily storing multi-horizon compound portfolio returns (daily, weekly, monthly, quarterly, half-yearly, yearly, MTD, YTD, QTD) for every active Popular Investor and CopyFund account, covering Jan 2013 to Apr 2024. Maintained incrementally by SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 3.1-3.2) to avoid re-scanning the 6.25B-row DWH_GainDaily during dashboard computation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (sections 3.1, 3.2) from DWH_GainDaily |
| **Refresh** | Daily — DELETE WHERE @yesterday=Date + INSERT. New PIs backfilled with full history on first appearance. |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PI_GainDaily` is a filtered shadow cache of `DWH_GainDaily` containing only rows for **active Popular Investors (PIs)** and **CopyFund accounts**. It exists solely to avoid re-scanning the massive 6.25B-row `DWH_GainDaily` table during the daily PI Dashboard computation.

The table holds ~6.9M rows spanning Jan 2013 to Apr 2024, with ~3,400-4,400 distinct CIDs per year at peak. All 9 gain columns are **direct passthroughs** from `DWH_GainDaily` — no transformation is applied. The only difference from the source is the population filter: only customers who are currently PIs (GuruStatusID IN 2,3,4,5,6 AND IsValidCustomer=1) or CopyFund accounts (AccountTypeID=9) are included.

**ETL pattern**: The SP has two insertion paths:
1. **New PI backfill** (section 3.1): When a customer first enters the PI population, ALL their historical gain data from `DWH_GainDaily` is copied in. This uses a cursor-like WHILE loop iterating by CID.
2. **Daily incremental** (section 3.2): Each day, DELETE rows for @yesterday and INSERT yesterday's gains from `DWH_GainDaily` for the current PI population.

**Consumers** (all within the same SP):
- Section 3.3: YTD, QTD, MTD, monthly, daily gain extraction for the `#YTD` temp table
- Section 3.5: Positive months percentage calculation
- Section 3.7 (indirectly): Average yearly gain via `#AvgGain0` UNION with `BI_DB_PastYearsGain`

**Data stopped refreshing around 2024-04-14**, consistent with the parent dashboard table `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`.

---

## 2. Business Logic

### 2.1 PI Population Filter

**What**: Only PI-eligible and CopyFund customers are cached.

**Columns Involved**: `CID`

**Rules**:
- Active Popular Investors: `Dim_Customer.GuruStatusID IN (2,3,4,5,6) AND Dim_Customer.IsValidCustomer = 1`
- CopyFund accounts: `Dim_Customer.AccountTypeID = 9`
- Population is determined from `#pop` temp table built in section 1 of the SP
- GuruStatusID values: 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro

### 2.2 New PI Backfill (Section 3.1)

**What**: When a customer first appears in the PI population, their full gain history is loaded.

**Columns Involved**: All columns

**Rules**:
- SP checks for PIs in `#pop` that have no existing rows in `BI_DB_PI_GainDaily`
- For each new PI, ALL historical rows from `DWH_GainDaily` where `Date < @yesterday` are inserted
- Uses a WHILE loop iterating CID by CID (descending order)
- This ensures that metrics like `Positive_Months_percent` and `Avg_Yearly_gain` have full history from day one

### 2.3 Daily Incremental Refresh (Section 3.2)

**What**: Yesterday's gain data is refreshed for the entire PI population.

**Columns Involved**: All columns

**Rules**:
- `DELETE FROM BI_DB_PI_GainDaily WHERE @yesterday = Date`
- `INSERT` from `DWH_GainDaily` joined to `#pop` on `CID = RealCID` where `@yesterday = Date`
- Idempotent: re-running the SP for the same date replaces the data cleanly

### 2.4 Gain Value Semantics

**What**: All gain values are compound portfolio returns expressed as decimal fractions.

**Columns Involved**: All Gain_* columns

**Rules**:
- Values are decimal fractions: 0.05 = 5% gain, -0.10 = 10% loss
- NULL means the interval is not available (insufficient trading history for that horizon)
- Zero-gain customers are excluded upstream by DWH_GainDaily's source filter (WHERE Gain <> 0)
- Trailing intervals: Gain_w=7 days, Gain_m=30 days, Gain_q=90 days, Gain_h=180 days, Gain_y=365 days
- To-date intervals: Gain_MTD=month-to-date, Gain_QTD=quarter-to-date, Gain_YTD=year-to-date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distributed — no co-located JOINs. CLUSTERED INDEX on (Date, CID) supports date-filtered queries and point lookups by date+CID combination. ~6.9M rows total; per-day slices are small (~3,400 rows), so single-date queries are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI's latest gains | `WHERE CID = @cid AND Date = (SELECT MAX(Date) FROM BI_DB_PI_GainDaily WHERE CID = @cid)` |
| All PI gains for a date | `WHERE Date = @date` (~3,400 rows) |
| PI's monthly gain history | `WHERE CID = @cid AND DAY(Date) = 1` (first-of-month snapshots) |
| Positive months for a PI | `WHERE CID = @cid AND DAY(Date) = 1 AND ISNULL(Gain_m, 0) > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile, country, regulation |
| BI_DB_dbo.DWH_GainDaily | CID + Date | Cross-reference with full customer gain table |
| BI_DB_dbo.BI_DB_PastYearsGain | CID | UNION for average yearly gain calculation |
| BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide | CID + Date | Parent dashboard table |

### 3.4 Gotchas

- **Shadow cache, not primary data**: This table is a filtered copy of `DWH_GainDaily`. For non-PI customers, query `DWH_GainDaily` directly.
- **Data stops at 2024-04-14**: The table has not been refreshed since this date based on live data. The parent SP appears to have stopped running.
- **Gain values are decimals, not percentages**: 0.0216 = 2.16% gain. Multiply by 100 for display.
- **NULL gain columns**: NULL means the interval is not available (insufficient history), NOT 0% return. Use ISNULL only when you understand this distinction.
- **New PI backfill is per-CID cursor**: For large numbers of new PIs, the backfill can be slow (WHILE loop with individual INSERTs).
- **Population drift**: If a PI loses their status (e.g., demoted to GuruStatusID=1 or 7), their historical rows remain in the table but no new rows are added. The table does not purge demoted PIs.
- **ROUND_ROBIN distribution**: JOINs on CID with HASH(CID) tables (like DWH_GainDaily) will trigger data movement.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (DWH_GainDaily, Dim_Customer) |
| Tier 2 | SP-computed / ETL-derived |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | NO | Snapshot date for which gains were calculated. Passthrough from DWH_GainDaily. Used as DELETE+INSERT key. Part of clustered index (Date, CID). (Tier 2 — DWH_GainDaily) |
| 2 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). (Tier 1 — Customer.CustomerStatic) |
| 3 | Gain_w | float | YES | Trailing 7-day (weekly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=7 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 4 | Gain_m | float | YES | Trailing 30-day (monthly) compound portfolio return as a decimal. IntervalTypeID=106 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 5 | Gain_q | float | YES | Trailing 90-day (quarterly) compound portfolio return as a decimal. IntervalTypeID=108 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 6 | Gain_h | float | YES | Trailing 180-day (half-yearly) compound portfolio return as a decimal. IntervalTypeID=109 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 7 | Gain_y | float | YES | Trailing 365-day (yearly) compound portfolio return as a decimal. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 9 | Gain_MTD | float | YES | Month-to-date compound portfolio return as a decimal. From first of current month to Date. IntervalTypeID=101 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 10 | Gain_YTD | float | YES | Year-to-date compound portfolio return as a decimal. From Jan 1 to Date. IntervalTypeID=103 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 11 | Gain_d | float | YES | Daily compound portfolio return as a decimal. Single-day gain for this Date. IntervalTypeID=1 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 12 | Gain_QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. From first of current quarter to Date. IntervalTypeID=102 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | BI_DB_dbo.DWH_GainDaily | Date | Passthrough |
| CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough (filtered to PI/CopyFund population) |
| Gain_w | BI_DB_dbo.DWH_GainDaily | Gain_w | Passthrough |
| Gain_m | BI_DB_dbo.DWH_GainDaily | Gain_m | Passthrough |
| Gain_q | BI_DB_dbo.DWH_GainDaily | Gain_q | Passthrough |
| Gain_h | BI_DB_dbo.DWH_GainDaily | Gain_h | Passthrough |
| Gain_y | BI_DB_dbo.DWH_GainDaily | Gain_y | Passthrough |
| UpdateDate | — | — | ETL-computed: GETDATE() |
| Gain_MTD | BI_DB_dbo.DWH_GainDaily | Gain_MTD | Passthrough |
| Gain_YTD | BI_DB_dbo.DWH_GainDaily | Gain_YTD | Passthrough |
| Gain_d | BI_DB_dbo.DWH_GainDaily | Gain_d | Passthrough |
| Gain_QTD | BI_DB_dbo.DWH_GainDaily | Gain_QTD | Passthrough |

### 5.2 ETL Pipeline

```
TradeGain Ranking Service (production, external)
  |-- Compound gains by IntervalTypeID
  v
BI_DB_dbo.External_TradeGain_Ranking_Compound_Gain_Completed
  |-- SP_DWH_GainDaily (daily pivot)
  v
BI_DB_dbo.DWH_GainDaily (6.25B rows, all customers)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide sections 3.1 + 3.2
  |   Population filter: #pop (GuruStatusID IN 2-6 + AccountTypeID=9)
  |   Section 3.1: New PI backfill (WHILE loop, full history)
  |   Section 3.2: Daily DELETE WHERE Date=@yesterday + INSERT
  v
BI_DB_dbo.BI_DB_PI_GainDaily (~6.9M rows, PI/CopyFund only)
  |
  |-- Same SP sections 3.3, 3.5, 3.7 (consumer)
  |   → #GainDaily → #YTD (YTD/QTD/MTD/monthly/daily gains)
  |   → #positive_months → #positive_months_percent
  |   → #AvgGain0 (UNION with BI_DB_PastYearsGain) → #AvgGain
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide
  (PI Dashboard — final output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Sections 3.3, 3.5, 3.7 | Consumed to compute YTD/MTD/QTD gains, positive months percent, and average yearly gain for the PI Dashboard |

---

## 7. Sample Queries

### 7.1 PI gain snapshot for the latest date

```sql
SELECT CID, Gain_d, Gain_w, Gain_m, Gain_YTD, Gain_y
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]
WHERE [Date] = (SELECT MAX([Date]) FROM [BI_DB_dbo].[BI_DB_PI_GainDaily])
ORDER BY Gain_YTD DESC;
```

### 7.2 Positive months percentage for a PI

```sql
SELECT CID,
       COUNT(CASE WHEN ISNULL(Gain_m, 0) > 0 THEN 1 END) AS Positive_Months,
       COUNT(*) AS Total_Months,
       COUNT(CASE WHEN ISNULL(Gain_m, 0) > 0 THEN 1 END) * 1.0 / COUNT(*) AS Positive_Pct
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]
WHERE CID = 2990627
  AND DAY([Date]) = 1
GROUP BY CID;
```

### 7.3 YTD performance ranking across all PIs

```sql
SELECT TOP 20 CID, Gain_YTD, Gain_d, Gain_w, Gain_m
FROM [BI_DB_dbo].[BI_DB_PI_GainDaily]
WHERE [Date] = '2024-04-14'
  AND Gain_YTD IS NOT NULL
ORDER BY Gain_YTD DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 11 T2, 0 T3, 0 T4, 0 T5 | Elements: 12/12, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PI_GainDaily | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 3.1-3.2 from DWH_GainDaily)*
