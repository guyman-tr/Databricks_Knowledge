# BI_DB_dbo.DWH_CIDsDailyRisk

> 4.7B-row daily portfolio risk table storing the average hourly portfolio standard deviation for every customer — calculated using a Markowitz-style weighted portfolio covariance model with 24 hourly iterations per day, covering Jan 2013 to present. Sources: Dim_Position (holdings), Dim_Instrument_Correlation (covariance matrix), V_Liabilities + History.Credit (equity). Refreshed daily by SP_DWH_CIDsDailyRisk via DELETE+INSERT by FullDate. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_CIDsDailyRisk` from Dim_Position + Dim_Instrument_Correlation + equity sources |
| **Refresh** | Daily — DELETE WHERE FullDate=@date + INSERT. Accumulating by date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (PK on FullDate, CID — NOT ENFORCED) + 2 NCIs |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table calculates the **daily portfolio risk** for every eToro customer using a **Markowitz-style portfolio standard deviation model**. For each day, the SP loops through all 24 hours, computing the portfolio standard deviation at each hour based on:

1. **Position weights**: Each open position's notional value (amount × forex rate × direction × conversion) relative to the customer's realized equity
2. **Instrument correlations**: The inter-instrument covariance matrix from Dim_Instrument_Correlation (weekly, using the most recent matrix with SampleSize > 100)
3. **Portfolio variance**: `sqrt(SUM(Weight_a × Weight_b × Covariance_ab))` across all instrument pairs

The 4.7B rows cover daily snapshots from Jan 2013 to Apr 2026. Each row stores the average of all hourly STD calculations (AvgSTD) and the number of hours with valid data (HoursInSample, avg ~20 hours per customer per day).

This is the **most compute-intensive SP in BI_DB** — the hourly WHILE loop with cross-join portfolio covariance calculations runs for approximately 45-90 minutes per day. It is a sibling to DWH_CIDs7DaysDeviation (which averages this table's output over a 7-day window) and ultimately feeds the copy-trading risk management system.

---

## 2. Business Logic

### 2.1 Hourly Portfolio Risk Calculation

**What**: Computes portfolio standard deviation every hour using weighted instrument covariance.
**Columns Involved**: AvgSTD, HoursInSample
**Rules**:
- WHILE loop iterates from hour 1 to hour 24 of the given date
- At each hour: build weighted portfolio (position value / equity) → cross-join with covariance → sqrt(SUM(w_a × w_b × cov_ab))
- Only customers with RealizedEquity > 0 are included
- Covariance matrix: most recent weekly entry from Dim_Instrument_Correlation with SampleSize > 100
- Negative variance (rare rounding artifacts) clamped to 0 before sqrt

### 2.2 Position Weighting

**What**: Calculates the portfolio weight of each instrument position.
**Columns Involved**: (intermediate calculation)
**Rules**:
- Weight = AmountInUnitsDecimal × InitForexRate × direction(+1/-1) × conversionRate / RealizedEquity
- Direction: IsBuy='true' → +1, else -1
- Conversion: SellCurrencyID=1 → 1, BuyCurrencyID=1 → 1/InitForexRate, else use PositionChangeLog or InitConversionRate
- Equity source: V_Liabilities (previous day) UNION History.Credit (intraday, most recent before each hour)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with NOT ENFORCED PK + 2 NCIs. **4.7B rows — second largest in BI_DB_dbo.** NCI on FullDate supports date-filtered queries. NCI on (CID, FullDate, AvgSTD) supports customer risk lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Risk for a customer on a date | `WHERE CID = X AND FullDate = @date` |
| High-risk customers today | `WHERE FullDate = @date AND AvgSTD > 0.04763` |
| Customer risk trend | `WHERE CID = X ORDER BY FullDate` |
| Low data quality (few hours) | `WHERE HoursInSample < 12` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| BI_DB_dbo.DWH_CIDs7DaysDeviation | CID + FullDate | 7-day rolling average |

### 3.4 Gotchas

- **4.7B rows**: ALWAYS filter by FullDate. Unfiltered scans will timeout.
- **HoursInSample < 24**: If a customer had no open positions for some hours, those hours have no data. Average is only over hours WITH data.
- **AvgSTD = 0**: Can mean only one instrument in portfolio (no covariance) or near-zero position weights.
- **Negative covariance clamped**: The sqrt formula clamps negative variance to 0, which can understate risk for perfectly negatively correlated portfolios.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FullDate | date | NO | Snapshot date. The target date for hourly risk calculation. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 2 | CID | int | NO | Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 3 | AvgSTD | float | YES | Average hourly portfolio standard deviation for this customer on this date. Calculated using Markowitz portfolio variance: sqrt(SUM(Weight_a × Weight_b × Covariance_ab)). Higher values = more volatile portfolio. Average across all 24 hourly iterations. (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 4 | HoursInSample | int | YES | Number of hourly iterations (out of 24) where this customer had valid data (open positions + positive equity). Average ~20. Lower values may indicate data gaps or intermittent position activity. (Tier 2 — SP_DWH_CIDsDailyRisk) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_DWH_CIDsDailyRisk. (Tier 5 — ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| FullDate | SP parameter | @date | passthrough |
| CID | Dim_Position | CID | passthrough (grouped by) |
| AvgSTD | Dim_Position + Dim_Instrument + Dim_Instrument_Correlation + V_Liabilities + History.Credit | Portfolio weights × covariance | Markowitz portfolio STD, averaged over 24 hourly iterations |
| HoursInSample | — | — | COUNT of hourly iterations with data |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open positions, amounts, forex rates)
DWH_dbo.Dim_Instrument (currency pair metadata)
DWH_dbo.Dim_Instrument_Correlation (weekly covariance matrix)
DWH_dbo.V_Liabilities (previous day equity)
etoro.History.Credit (intraday equity changes)
etoro.History.PositionChangeLog (intraday rate updates)
  |
  |-- SP_DWH_CIDsDailyRisk @date (daily, ~45-90 min runtime)
  |   WHILE loop: 24 hourly iterations
  |   Per hour: weighted portfolio → covariance cross-join → sqrt(variance)
  |   Final: AVG(hourly_std), COUNT(hours)
  |   DELETE WHERE FullDate=@date + INSERT
  v
BI_DB_dbo.DWH_CIDsDailyRisk (4.7B rows, accumulating daily)
  |
  |-- BI_DB_dbo.DWH_CIDs7DaysDeviation (downstream: 7-day rolling average)
  v
BI_DB_dbo.BI_DB_WeeklyCopyBlock (risk score bucketing for copy blocks)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.DWH_CIDs7DaysDeviation | Downstream (indirectly — both read Fact_CustomerUnrealized_PnL) | 7-day rolling deviation average |

---

## 7. Sample Queries

### 7.1 Riskiest Customers Yesterday

```sql
SELECT TOP 20 CID, AvgSTD, HoursInSample
FROM BI_DB_dbo.DWH_CIDsDailyRisk
WHERE FullDate = CAST(GETDATE()-1 AS DATE)
ORDER BY AvgSTD DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found. Context: core risk calculation SP owned by BI team, feeds copy-trading risk management.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 5/5, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.DWH_CIDsDailyRisk | Type: Table | Production Source: SP_DWH_CIDsDailyRisk (Markowitz portfolio risk from Dim_Position + covariance)*
