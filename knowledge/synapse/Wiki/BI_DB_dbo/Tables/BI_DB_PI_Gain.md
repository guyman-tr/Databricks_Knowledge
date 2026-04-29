# BI_DB_dbo.BI_DB_PI_Gain

> 402K-row table of Popular Investor and Portfolio gain percentages at monthly, quarterly, and yearly granularity. Covers 5,873 distinct PIs/Portfolios from 2013 to present. Daily TRUNCATE+INSERT from BI_DB_DailyGain_History with compound gain calculation for Q/Y aggregations.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_DailyGain_History + DWH_dbo.Fact_SnapshotCustomer via `SP_PI_Gain` |
| **Refresh** | Daily (TRUNCATE+INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Dan (2021-03-10), migrated by Tom Boksenbojm (2023-12-01) |
| **Row Count** | ~402,141 (as of 2026-04-12) |

---

## 1. Business Meaning

`BI_DB_PI_Gain` provides gain percentages for Popular Investors and Smart Portfolios at three time granularities: monthly (M), quarterly (Q), and yearly (Y). Each row represents one PI/Portfolio's gain for one time period. The data spans from 2013 to present, covering 5,873 distinct PIs/Portfolios.

Monthly gains are taken directly from `BI_DB_DailyGain_History`. Quarterly and yearly gains are computed using compound product methodology: `100 * (PRODUCT(1 + daily_gain/100) - 1)`, implemented via `EXP(SUM(LOG(ABS(1 + Gain/100))))` with sign handling for negative gains. This correctly compounds daily returns rather than simple averaging.

Population: Active PIs (GuruStatusID >= 2 in Fact_SnapshotCustomer, valid customer) and Smart Portfolios (AccountTypeID = 9). Linked to DailyGain_History via Dim_Customer.ID (GUID).

Breakdown: PI = 94% of rows (317K monthly + 30K quarterly + 32K yearly), Portfolio = 6% (17K monthly + 3.4K quarterly + 2.2K yearly).

---

## 2. Business Logic

### 2.1 Compound Gain Calculation

**What**: Quarterly and yearly gains are compound products of daily gains, not simple sums.
**Columns Involved**: `Gain`, `TimeFarme`
**Rules**:
- Monthly (M): Gain is passed through directly from DailyGain_History
- Quarterly (Q): `100 * (PRODUCT(1 + Gain_daily/100) - 1)` for the quarter (last year + current year only)
- Yearly (Y): Same compound formula for the full year
- Sign handling: if any daily gain = -100%, product is 0; if odd number of negative daily returns, result is negative
- Implementation: `EXP(SUM(LOG(ABS(NULLIF(1+Gain/100, 0)))))` with CASE for sign

### 2.2 CopyType Classification

**What**: Distinguishes Popular Investors from Smart Portfolios.
**Columns Involved**: `CopyType`
**Rules**:
- AccountTypeID = 9 → 'Portfolio' (Smart Portfolio)
- All others → 'PI' (Popular Investor)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — filter on RealCID + TimeFarme for specific PI analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest monthly gains for all PIs | `WHERE TimeFarme = 'M' AND EndPeriod = (SELECT MAX(EndPeriod) FROM ... WHERE TimeFarme='M')` |
| Yearly performance ranking | `WHERE TimeFarme = 'Y' AND Year = YEAR(GETDATE()) ORDER BY Gain DESC` |
| Specific PI history | `WHERE RealCID = {cid} ORDER BY TimeFarme, StartPeriod` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| DWH_dbo.Dim_GuruStatus | `GuruStatusID` (via Dim_Customer) | PI tier |

### 3.4 Gotchas

- **TimeFarme typo**: Column name is `TimeFarme` (not TimeFrame) — preserved from original SP
- **IsLast is always NULL**: The column exists in DDL but the SP does not populate it
- **Q/Y gains are compound, not additive**: Do not sum monthly gains to get quarterly — use the Q/Y rows directly
- **Column count**: Batch assignment said 12 — DDL has 12 (including IsLast which is unpopulated)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID of the PI or Portfolio account. Primary key equivalent (with TimeFarme + period). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | UserName | varchar(max) | YES | Customer login username. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | CopyType | varchar(max) | YES | 'PI' for Popular Investor accounts, 'Portfolio' for Smart Portfolio accounts (AccountTypeID=9). (Tier 2 — SP_PI_Gain) |
| 4 | Year | int | YES | Calendar year of the period start date. (Tier 2 — SP_PI_Gain) |
| 5 | Quarter | int | YES | Calendar quarter (1-4) of the period. For yearly rows, this is the MAX quarter in the year. (Tier 2 — SP_PI_Gain) |
| 6 | Month | int | YES | Calendar month (1-12) of the period start. For Q/Y rows, this is the MAX month in the aggregation. (Tier 2 — SP_PI_Gain) |
| 7 | TimeFarme | varchar(max) | YES | Time granularity: 'M'=monthly, 'Q'=quarterly, 'Y'=yearly. Note: column name has typo (TimeFarme, not TimeFrame). (Tier 2 — SP_PI_Gain) |
| 8 | StartPeriod | datetime | YES | Start date of the gain period. For M: direct from DailyGain_History. For Q/Y: MIN(StartPeriod) in the aggregation. (Tier 2 — SP_PI_Gain) |
| 9 | EndPeriod | datetime | YES | End date of the gain period. For M: direct from DailyGain_History. For Q/Y: MAX(EndPeriod) in the aggregation. (Tier 2 — SP_PI_Gain) |
| 10 | Gain | float | YES | Gain percentage for the period. Monthly: direct from DailyGain_History. Quarterly/Yearly: compound product of daily gains via EXP(SUM(LOG(ABS(1+Gain/100)))). Can be negative. (Tier 2 — SP_PI_Gain, BI_DB_DailyGain_History) |
| 11 | IsLast | int | YES | Not populated by the SP — always NULL. Likely a legacy flag for identifying the latest period. (Tier 2 — SP_PI_Gain) |
| 12 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 — SP_PI_Gain) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |
| UserName | Customer.CustomerStatic | UserName | passthrough via Dim_Customer |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (PIs: GuruStatusID>=2 OR Portfolios: AccountTypeID=9)
  + DWH_dbo.Dim_Customer (UserName, ID)
  + BI_DB_dbo.BI_DB_DailyGain_History (daily gain data, joined on ID)
  |
  |-- SP_PI_Gain @date (daily TRUNCATE+INSERT)
  |   Step 1: Build PI/Portfolio population from Fact_SnapshotCustomer
  |   Step 2: Join to DailyGain_History via Dim_Customer.ID
  |   Step 3: Monthly gains = direct passthrough
  |   Step 4: Quarterly gains = compound product (last year + current)
  |   Step 5: Yearly gains = compound product (all time)
  |   Step 6: UNION M + Q + Y → TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_PI_Gain (402K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | PI/Portfolio customer |
| Gain | BI_DB_dbo.BI_DB_DailyGain_History | Source gain data |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Top PIs by Yearly Gain (Current Year)

```sql
SELECT RealCID, UserName, CopyType, Gain
FROM BI_DB_dbo.BI_DB_PI_Gain
WHERE TimeFarme = 'Y' AND Year = YEAR(GETDATE())
ORDER BY Gain DESC
```

### 7.2 Monthly Gain Trend for a Specific PI

```sql
SELECT Year, Month, Gain, StartPeriod, EndPeriod
FROM BI_DB_dbo.BI_DB_PI_Gain
WHERE RealCID = {target_cid} AND TimeFarme = 'M'
ORDER BY StartPeriod
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 2 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 12/12, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_PI_Gain | Type: Table | Production Source: BI_DB_DailyGain_History + Fact_SnapshotCustomer via SP_PI_Gain*
