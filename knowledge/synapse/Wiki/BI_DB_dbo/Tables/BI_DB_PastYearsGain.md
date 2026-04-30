# BI_DB_dbo.BI_DB_PastYearsGain

> ~20.2M-row historical yearly gain archive storing the trailing 365-day compound portfolio return (Gain_y) for every customer on Jan 1 of each year, covering 2007 through 2023. Used by the PI Dashboard SP to compute average yearly performance across all completed calendar years. Append-only, refreshed annually via SP_PI_Dashboard_COPYDATA_RuningSideBySide.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (section 3.4) from DWH_GainDaily |
| **Refresh** | Annual — INSERT fires only when @yesterday = Jan 1 (conditional within a daily SP). Append-only, no DELETE. |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PastYearsGain` is a historical archive that captures each customer's trailing 365-day compound portfolio return (Gain_y from `DWH_GainDaily`) on Jan 1 of each year. The `Year1` column stores the completed calendar year the gain covers (e.g., a row with Date=2024-01-01 has Year1=2023, representing calendar year 2023 performance).

The table is consumed by SP_PI_Dashboard_COPYDATA_RuningSideBySide (section 3.7), where it is UNIONed with the current year's YTD gain to compute `AVG(Gain_y)` — the average yearly performance across all completed years for each Popular Investor (PI). This metric appears in the PI Dashboard as `Avg_Yearly_gain`.

**Population**: All customers present in `DWH_GainDaily` on Jan 1 of each year who had a non-zero yearly gain. The table holds ~20.2M rows across 17 distinct years (Year1 2007–2023).

**Append-only pattern**: The SP conditionally inserts rows only when `@yesterday` falls on Jan 1 (determined by joining `DWH_GainDaily.Date` against `V_Dim_Date WHERE DayNumberOfYear=1`). There is no DELETE — each year's snapshot accumulates permanently.

**Historical pattern shift**: Rows for Year1 2007–2020 have Date values on Dec 1 (legacy behavior); rows for Year1 2021–2023 use Jan 1 dates (current SP logic). The Year1 formula `YEAR(Date)-1` is correct for Jan 1 dates; the Dec 1 rows predate this formula and have `Year1 = YEAR(Date)`.

---

## 2. Business Logic

### 2.1 Annual Gain Snapshot

**What**: Captures the trailing 365-day compound return from DWH_GainDaily on Jan 1 of each year.

**Columns Involved**: `Date`, `CID`, `Gain_y`, `Year1`

**Rules**:
- SP joins `DWH_GainDaily` with `V_Dim_Date WHERE DayNumberOfYear = 1` and filters `Date = @yesterday`
- Only fires when @yesterday is Jan 1 of any year
- Gain_y values are decimal fractions: 0.0914 = 9.14% gain, -0.0179 = 1.79% loss
- Year1 = `YEAR(Date) - 1` — the completed calendar year the return covers
- Zero-gain customers (Gain=0 in DWH_GainDaily) are excluded upstream by the DWH_GainDaily source filter

### 2.2 Average Yearly Gain Calculation (Consumer)

**What**: SP section 3.7 unions this table with the current YTD gain to compute lifetime average.

**Columns Involved**: `Year1`, `CID`, `Gain_y`

**Rules**:
```
#AvgGain0 = 
  SELECT Y.year, CID, Y.Gain_YTD AS Gain_y FROM #YTD Y      -- current year (YTD)
  UNION ALL
  SELECT Year1, CID, Gain_y FROM BI_DB_PastYearsGain          -- past completed years

#AvgGain = SELECT CID, AVG(Gain_y) AS Avg_Yearly_gain FROM #AvgGain0 GROUP BY CID
```
- The AVG includes both completed past years and the current partial year (as YTD)
- This produces the `Avg_Yearly_gain` column in `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distributed — no co-located JOINs. CLUSTERED INDEX on Date supports date-range scans. For ~20.2M rows, queries without a Date or Year1 filter are manageable but should still be bounded.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's yearly returns across all years | `WHERE CID = @cid ORDER BY Year1` |
| Average yearly return for a customer | `SELECT CID, AVG(Gain_y) FROM BI_DB_PastYearsGain WHERE CID = @cid GROUP BY CID` |
| All customers with >50% annual return in a given year | `WHERE Year1 = 2023 AND Gain_y > 0.5` |
| Count of customers per year | `SELECT Year1, COUNT(*) FROM BI_DB_PastYearsGain GROUP BY Year1 ORDER BY Year1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile, country, regulation |
| BI_DB_dbo.DWH_GainDaily | CID + Date | Cross-reference daily gain data for the snapshot date |

### 3.4 Gotchas

- **Gain_y is a decimal, not a percentage**: 0.0914 = 9.14% gain. Multiply by 100 for display.
- **Year1 does not always equal YEAR(Date)-1**: Legacy rows (2007–2020) have Date on Dec 1 and Year1=YEAR(Date). Only rows from 2022+ follow the current formula `Year1 = YEAR(Date) - 1`.
- **Append-only, no idempotent reload**: There is no DELETE before INSERT. If the SP runs twice on Jan 1, duplicate rows may appear. In practice this is prevented by the daily SP execution schedule.
- **No row for Year1=2020 via Jan 1**: The transition from Dec 1 to Jan 1 pattern means 2020's gain appears on Date=2020-12-01 (legacy) and 2021's gain appears on Date=2022-01-01. No Date=2021-01-01 row exists.
- **Latest data is Year1=2023** (Date=2024-01-01). Year1=2024 would only appear after 2025-01-01 run.
- **Not migrated to Unity Catalog**: No UC target exists for this table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (DWH_GainDaily, Dim_Customer) |
| Tier 2 | SP code / ETL-computed |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | NO | Jan 1 snapshot date from which the trailing yearly gain was captured. Sourced from DWH_GainDaily.Date, filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1. Historical rows (2007-2020) use Dec 1 instead. Part of logical PK (Date, CID). (Tier 2 — DWH_GainDaily) |
| 2 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Part of logical PK (Date, CID). (Tier 1 — Customer.CustomerStatic) |
| 3 | Gain_y | float | YES | Trailing 365-day (yearly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=110 from TradeGain service. Passthrough from DWH_GainDaily. (Tier 2 — DWH_GainDaily) |
| 4 | Year1 | int | YES | The completed calendar year the gain covers. ETL-computed: YEAR(Date)-1 for Jan 1 rows. E.g., Date=2024-01-01 yields Year1=2023. Historical Dec 1 rows have Year1=YEAR(Date). (Tier 2 — DWH_GainDaily) |
| 5 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | BI_DB_dbo.DWH_GainDaily | Date | Passthrough (filtered to Jan 1 via V_Dim_Date) |
| CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough |
| Gain_y | BI_DB_dbo.DWH_GainDaily | Gain_y | Passthrough |
| Year1 | BI_DB_dbo.DWH_GainDaily | Date | ETL-computed: YEAR(Date)-1 |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
TradeGain Ranking Service (production, external)
  |-- Compound gains by IntervalTypeID
  v
BI_DB_dbo.External_TradeGain_Ranking_Compound_Gain_Completed
  |-- SP_DWH_GainDaily (daily pivot)
  v
BI_DB_dbo.DWH_GainDaily (6.25B rows, daily accumulating)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide section 3.4
  |   JOIN V_Dim_Date WHERE DayNumberOfYear=1 (Jan 1 filter)
  |   AND Date = @yesterday (only fires on Jan 1)
  |   Year1 = YEAR(Date)-1
  |   INSERT (append-only, no DELETE)
  v
BI_DB_dbo.BI_DB_PastYearsGain (~20.2M rows, 17 years)
  |
  |-- SP section 3.7: UNION with current YTD
  |   AVG(Gain_y) per CID
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide.Avg_Yearly_gain
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
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Section 3.7 (#AvgGain0) | Consumed to compute average yearly gain for PI dashboard |

---

## 7. Sample Queries

### 7.1 Average yearly return per customer across all years

```sql
SELECT CID, AVG(Gain_y) AS Avg_Yearly_Gain, COUNT(*) AS Years_Tracked
FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
GROUP BY CID
HAVING COUNT(*) >= 3
ORDER BY Avg_Yearly_Gain DESC;
```

### 7.2 Year-over-year gain distribution

```sql
SELECT Year1,
       COUNT(*) AS Customers,
       AVG(Gain_y) AS Avg_Gain,
       MIN(Gain_y) AS Min_Gain,
       MAX(Gain_y) AS Max_Gain
FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
GROUP BY Year1
ORDER BY Year1;
```

### 7.3 Specific customer's yearly performance history

```sql
SELECT Year1, Gain_y,
       Gain_y * 100 AS Gain_Percent
FROM [BI_DB_dbo].[BI_DB_PastYearsGain]
WHERE CID = 15310291
ORDER BY Year1;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — regen harness mode.)

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PastYearsGain | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (section 3.4 from DWH_GainDaily)*
