# BI_DB_dbo.BI_DB_ClusteringDailyPrepData

| Property | Value |
|----------|-------|
| **Object Type** | TABLE |
| **Schema** | BI_DB_dbo |
| **Row Count** | ~205,600,000 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ( [CalculationDateID] ASC ) |
| **Source System** | `Dim_Position` + `Dim_Mirror` + `BI_DB_PositionPnL` + `DWH_CIDsDailyRisk` |
| **Writer SP** | `SP_ClusteringDailyPrepData` |
| **ETL Pattern** | DELETE-INSERT per @dateid (daily incremental, keeps full history) |
| **Refresh** | Daily (SB_Daily, Priority 20) |

## 1. Business Meaning

`BI_DB_ClusteringDailyPrepData` is the feature engineering table for eToro's customer behaviour clustering model. Each row contains 6 computed trading metrics for a single customer on a specific calculation date, designed to feed an ML model that segments customers into behavioural clusters (e.g., investor, trader, crypto enthusiast).

The table computes features at **30-day intervals per customer** — a customer appears in the table every 30 days from their first action date, and only if they are V3-verified. This creates a rolling time-series of customer behaviour that the downstream `SP_CID_DailyCluster` consumes for cluster assignment.

**The six features are:**

| Feature | Business Meaning |
|---------|-----------------|
| **WeightedAvgDuration** | How long the customer holds investing positions (weighted by amount). Higher = buy-and-hold; lower = active trading. |
| **RiskIndex** | Average portfolio risk on a 1-10 scale (from daily standard deviation). Higher = more volatile portfolio. |
| **AvgDailyPositions** | Average number of positions opened per day. Higher = more active trader. |
| **EffectiveLev** | Volume-weighted average leverage. 1.0 = no leverage (real investing); >2 = leveraged trading. |
| **InvestingRatio** | Proportion of portfolio in long-term investing (Indices/Stocks/ETF at low leverage + copy-trading). |
| **CryptoRatio** | Proportion of portfolio in crypto assets (direct positions only). |

Note: `InvestingRatio + CryptoRatio + TradingRatio ≈ 1.0` — they partition the customer's portfolio into three behavioural segments. `TradingRatio` captures leveraged trading (high-leverage Indices/Stocks/ETF + Currencies/Commodities).

## 2. Business Logic

### 2.1 Population — 30-Day Cycle

Customers are included only if:
- V3-verified (`VerificationLevelID = 3` in Fact_SnapshotCustomer at @date via Dim_Range)
- `IsValidCustomer = 1`
- First action (buy position or first deposit) at least 30 days before @date
- **Seniority % 30 = 0** — features are computed only every 30 days per customer

### 2.2 WeightedAvgDuration

Combines investing positions (Indices/Stocks/ETF at leverage 1-2 from Dim_Position) and copy-trading positions (from Dim_Mirror) within 2 years of first action:
```
DurationRatio = DATEDIFF(DAY, OpenOccurred, CloseOccurred) / DATEDIFF(DAY, OpenOccurred, @date)
WeightedAvgDuration = SUM(DurationRatio * Amount) / SUM(Amount)
```
Returns `-1` if no qualifying positions (sentinel).

### 2.3 RiskIndex (1-10 Scale)

From `DWH_CIDsDailyRisk.AvgSTD` over 2 years, bucketed:

| AvgSTD Range | Score |
|-------------|-------|
| < 0.00034 | 1 |
| < 0.00068 | 2 |
| < 0.00204 | 3 |
| < 0.00340 | 4 |
| < 0.00544 | 5 |
| < 0.00816 | 6 |
| < 0.01361 | 7 |
| < 0.02722 | 8 |
| < 0.04763 | 9 |
| >= 0.04763 | 10 |

### 2.4 Three-Way Portfolio Ratio

All computed from `BI_DB_PositionPnL` daily snapshots (since 2022-12-30), volume-weighted:

| Ratio | Definition |
|-------|-----------|
| **InvestingRatio** | (Indices/Stocks/ETF at leverage 1-2) + all CopyTrading (MirrorID≠0) |
| **CryptoRatio** | Crypto (InstrumentTypeID=10), direct positions only |
| **TradingRatio** | (Indices/Stocks/ETF at leverage >2) + (Currencies + Commodities), direct only |

### 2.5 Hardcoded Lookback

`@Minus2YearsInt_PositionPnL = 20221230` — the BI_DB_PositionPnL lookback is hardcoded to start from 2022-12-30 rather than rolling 2 years, likely for performance reasons.

## 3. Query Advisory

### 3.1 Distribution & Index Strategy

- **ROUND_ROBIN** — even distribution. No collocated CID joins.
- **CLUSTERED INDEX (CalculationDateID ASC)** — efficient for date-range queries and DELETE-INSERT by date.

### 3.2 Recommended Patterns

| Use Case | Pattern |
|----------|---------|
| Latest features per customer | `WHERE CalculationDateID = (SELECT MAX(CalculationDateID) FROM BI_DB_ClusteringDailyPrepData)` |
| Specific date | `WHERE CalculationDateID = 20260310` — fast via clustered index |
| Date range | `WHERE CalculationDateID BETWEEN 20260101 AND 20260310` |
| Customer time-series | `WHERE CID = @cid ORDER BY CalculationDateID` — cross-distribution scan |

### 3.3 Performance Notes

- **205M+ rows** — large table. Always filter by `CalculationDateID` first (clustered index).
- Each daily run adds ~100-200K rows (not all customers calculated every day due to 30-day cycle).
- `WeightedAvgDuration = -1` is a sentinel — exclude from averages.
- CID queries require full scan across distributions (ROUND_ROBIN + no CID index).

### 3.4 Data Freshness

| Metric | Value |
|--------|-------|
| First data | 2021-01-25 |
| Last loaded | 2026-03-11 |
| Refresh frequency | Daily (incremental) |
| History | Full retention since 2021 |

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer Real account ID. V3-verified customers from Fact_FirstCustomerAction + Fact_SnapshotCustomer. (Tier 1 — Dim_Customer) |
| 2 | CalculationDate | date | YES | Date when features were computed. `@date` SP parameter. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed) |
| 3 | CalculationDateID | int | YES | Integer date key in YYYYMMDD format. Clustered index column. `CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed) |
| 4 | WeightedAvgDuration | numeric(38,6) | NO | Volume-weighted average holding duration ratio for investing positions (Indices/Stocks/ETF at leverage 1-2) and copy-trading. Range: -1 (sentinel: no positions) to 1.0 (all positions still open). (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from Dim_Position + Dim_Mirror) |
| 5 | RiskIndex | decimal(38,6) | YES | Average portfolio risk score on 1-10 scale over 2 years. Computed from `DWH_CIDsDailyRisk.AvgSTD` bucketed into 10 tiers. 1=very low risk, 10=very high risk. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from DWH_CIDsDailyRisk) |
| 6 | AvgDailyPositions | numeric(29,15) | NO | Average number of positions opened per day since first action. `COUNT(positions) / DATEDIFF(DAY, FirstActionDate, @date)`. 0 if no positions in window. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from Dim_Position) |
| 7 | EffectiveLev | numeric(38,6) | YES | Volume-weighted average leverage across all daily position snapshots. 1.0 = unleveraged (real investing); 2+ = leveraged trading. Weighted by daily invested amount. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from BI_DB_PositionPnL) |
| 8 | InvestingRatio | money | YES | Proportion of portfolio allocated to long-term investing: (Indices/Stocks/ETF at leverage 1-2) + copy-trading positions. Range 0-1. Part of 3-way ratio with CryptoRatio + TradingRatio ≈ 1.0. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from BI_DB_PositionPnL) |
| 9 | CryptoRatio | money | YES | Proportion of portfolio allocated to crypto assets (InstrumentTypeID=10, direct positions only). Range 0-1. Part of 3-way ratio. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from BI_DB_PositionPnL) |
| 10 | TradingRatio | money | YES | Proportion of portfolio allocated to leveraged trading: (Indices/Stocks/ETF at leverage >2) + (Currencies + Commodities), direct positions only. Range 0-1. Part of 3-way ratio. (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed from BI_DB_PositionPnL) |
| 11 | UpdateDate | datetime | NO | ETL execution timestamp. `GETDATE()`. Different per daily load (incremental pattern). (Tier 2 — SP_ClusteringDailyPrepData, ETL-computed) |

## 5. Lineage

| Source | Relationship | Objects |
|--------|-------------|---------|
| **DWH_dbo.Fact_FirstCustomerAction** | Population — first action dates | `RealCID`, `FirstOccurred`, `ActionTypeID` (1=Buy, 17=FirstDeposit) |
| **DWH_dbo.Fact_SnapshotCustomer** | Population — V3 verification check | `RealCID`, `VerificationLevelID` via `Dim_Range` |
| **DWH_dbo.Dim_Position** | WeightedAvgDuration + AvgDailyPositions | Position amounts, dates, leverage (non-mirror, 2-year window) |
| **DWH_dbo.Dim_Mirror** | WeightedAvgDuration | Copy-trading position amounts and dates |
| **BI_DB_dbo.BI_DB_PositionPnL** | EffectiveLev, InvestingRatio, CryptoRatio, TradingRatio | Daily position P&L with amount, leverage, instrument |
| **DWH_dbo.Dim_Instrument** | Asset class classification | `InstrumentTypeID`: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto |
| **BI_DB_dbo.DWH_CIDsDailyRisk** | RiskIndex | `AvgSTD` daily standard deviation |

Full column-level lineage: [BI_DB_ClusteringDailyPrepData.lineage.md](BI_DB_ClusteringDailyPrepData.lineage.md)

## 6. Relationships

| Related Object | Join Condition | Purpose |
|---------------|----------------|---------|
| DWH_dbo.Dim_Position | `ON CID = dp.CID AND OpenDateID BETWEEN @Minus2YearsInt AND @dateid` | Source: position data for duration + count |
| DWH_dbo.Dim_Mirror | `ON CID = dp.CID AND OpenDateID <= @dateid` | Source: copy-trading data for duration |
| BI_DB_dbo.BI_DB_PositionPnL | `ON CID = bdppl.CID AND DateID BETWEEN 20221230 AND @dateid` | Source: daily P&L for ratio calculations |
| BI_DB_dbo.DWH_CIDsDailyRisk | `ON CID = dcdr.CID AND FullDate <= @date` | Source: daily risk scores |
| BI_DB_dbo.BI_DB_ClusteringDailyPrepData → SP_CID_DailyCluster | _Downstream_ | Consumer: cluster assignment model |

## 7. Sample Queries

```sql
-- Latest features for a specific customer
SELECT  *
FROM    BI_DB_dbo.BI_DB_ClusteringDailyPrepData
WHERE   CID = @cid
ORDER BY CalculationDateID DESC;

-- Average feature values by most recent calculation date
SELECT  CalculationDateID,
        COUNT(*) AS Customers,
        AVG(CASE WHEN WeightedAvgDuration >= 0 THEN WeightedAvgDuration END) AS AvgDuration,
        AVG(RiskIndex) AS AvgRisk,
        AVG(EffectiveLev) AS AvgLeverage,
        AVG(InvestingRatio) AS AvgInvesting,
        AVG(CryptoRatio) AS AvgCrypto,
        AVG(TradingRatio) AS AvgTrading
FROM    BI_DB_dbo.BI_DB_ClusteringDailyPrepData
WHERE   CalculationDateID = 20260310
GROUP BY CalculationDateID;
```

## 8. Atlassian Knowledge Sources

_No specific Confluence/Jira pages found for the clustering prep data table. SP header credits Maor Hacun (2021-01-15 creation) with optimization by Eitan Lipo (2024-05-27)._

---

| Metric | Value |
|--------|-------|
| **Quality Score** | 9.0 / 10 |
| **Tier 1 Elements** | 1 / 11 (9%) |
| **Tier 2 Elements** | 10 / 11 (91%) |
| **Tier 4 Elements** | 0 |
| **Confidence** | HIGH — SP code fully analyzed, all 6 ML features documented with formulas |
