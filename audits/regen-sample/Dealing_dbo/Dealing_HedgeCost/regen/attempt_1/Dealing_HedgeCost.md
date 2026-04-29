# Dealing_dbo.Dealing_HedgeCost

> Daily hedge cost analysis table for USD-denominated stocks and ETFs, containing 7.85M rows from 2021-01-04 to 2026-04-25 -- compares client net position costs against liquidity provider execution costs per instrument, hedge server, and settlement type (Real/CFD) to quantify the daily hedging P&L gap.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | SP_HedgeCost (Author: Sarah Benchitrit, 2020-10-01) |
| **Refresh** | Daily (DELETE-INSERT by Date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_HedgeCost` quantifies the daily cost of hedging client positions for stocks and ETFs (InstrumentTypeID IN (5,6)) denominated in USD (SellCurrencyID=1). Each row represents one combination of Date + InstrumentID + HedgeServerID + IsSettled (Real/CFD), capturing both the client-side net position metrics and the liquidity provider (LP) execution metrics for that group.

The hedge cost (`HC`) is the core metric: it measures the difference between what clients paid (adjusted for commissions) and what the LP executed at, both marked to the end-of-day market price (AskSpreaded from Fact_CurrencyPriceWithSplit). A positive HC means hedging cost eToro money; a negative HC means the hedge was profitable.

**Data scope**: 7.85M rows, 6,447 distinct instruments, 25 distinct hedge servers. IsSettled has two values: "Real" (settled/stock ownership positions, ~64% of 2026 rows) and "CFD" (contract-for-difference, ~36%). LP execution data shows many rows with zero LP_Executed_Units, indicating instruments where eToro internalizes the risk without hedging to an external LP.

**ETL pattern**: `SP_HedgeCost` runs daily with `@Date` parameter. It DELETEs existing rows for that date, then rebuilds from multiple sources: LP fills from `CopyFromLake.etoro_Hedge_ExecutionLog` (successful fills only, filtered by ExecutionTime), client positions from `Dim_Position` (opened or closed on the date), with IsSettled correction via `Dim_PositionChangeLog` (ChangeTypeID=13), realized commissions from `Dealing_DailyZeroPnL_Stocks`, variable spread from `BI_DB_VarCommission`, and market prices from `Fact_CurrencyPriceWithSplit`.

**Key change (2024-12-24, SR-286858)**: LP execution source was migrated from direct `etoro.Hedge.ExecutionLog` to `CopyFromLake.etoro_Hedge_ExecutionLog` (Data Lake copy).

---

## 2. Business Logic

### 2.1 Hedge Cost Formula

**What**: The HC column computes the net hedging cost by comparing client-side and LP-side positions marked to the same market price.

**Columns Involved**: `HC`, `Clients_Units`, `AvgRateClientsNoSpread`, `FullCommission`, `LP_Executed_Units`, `LP_Avg_Rate`

**Rules**:
- HC = (AskSpreaded * NetUnits - (NetUnits * AvgRate - FullCommission)) - (AskSpreaded * LP_Executed_Units - (LP_Executed_Units * LP_Avg_Rate))
- Client cost component: AskSpreaded * NetUnits - ClientCostBasis (where ClientCostBasis = NetUnits * AvgRate - FullCommission)
- LP cost component: AskSpreaded * LP_Executed_Units - LP_CostBasis (where LP_CostBasis = LP_Executed_Units * LP_Avg_Rate)
- AskSpreaded is the end-of-day spread-adjusted ask price from Fact_CurrencyPriceWithSplit
- Positive HC = hedging cost to eToro; Negative HC = hedging profit

### 2.2 IsSettled Classification with ChangeLog Correction

**What**: Positions are classified as Real (settled stock) or CFD based on their IsSettled status at the report date, correcting for any subsequent settlement changes.

**Columns Involved**: `IsSettled`, `HedgeServerID`

**Rules**:
- The SP joins positions to Dim_PositionChangeLog (ChangeTypeID=13, OccurredDateID > @DateInt) to find the FIRST settlement change AFTER the report date
- Uses ISNULL(PreviousIsSettled, IsSettled) to recover what IsSettled was ON the report date, before any later changes
- ROW_NUMBER() OVER (PARTITION BY PositionID ORDER BY Occurred) with RN=1 picks the earliest subsequent change
- Final mapping: IsSettled=1 -> 'Real', IsSettled=0 -> 'CFD'
- LP side uses HedgeServerID directly: HedgeServerID IN (9,102,112,125,126) -> 'Real', else -> 'CFD'

### 2.3 Client Position Aggregation (Opens + Closes)

**What**: Client metrics are computed by combining positions opened AND positions closed on the report date, with directional signing.

**Columns Involved**: `Clients_Units`, `AvgRateClientsNoSpread`, `VolumeMarket`

**Rules**:
- Positions opened on @DateInt: IsBuy sign convention (IsBuy*2-1), ForexRate = InitForexRate, Commission = FullCommissionByUnits
- Positions closed on @DateInt: IsBuy direction is FLIPPED (CASE WHEN IsBuy=0 THEN 1 ELSE 0 END), ForexRate = EndForexRate, Commission = FullCommissionOnClose
- Both filtered to: SellCurrencyID=1 (USD instruments), InstrumentTypeID IN (5,6) (stocks/ETFs), IsValidCustomer=1
- Clients_Units = SUM((IsBuy*2-1)*AmountInUnitsDecimal) -- net signed units
- AvgRateClientsNoSpread = (NetUnits*AvgRate - FullCommission) / NULLIF(NetUnits, 0) -- commission-adjusted average
- VolumeMarket = SUM(Volume) from all matched positions

### 2.4 LP Execution Aggregation

**What**: Liquidity provider execution metrics from the hedge execution log.

**Columns Involved**: `LP_Executed_Units`, `LP_Avg_Rate`, `LP_Volume`

**Rules**:
- Source: CopyFromLake.etoro_Hedge_ExecutionLog (success=1 fills only)
- Filtered to: CAST(ExecutionTime AS Date) = @Date, SellCurrencyID=1, InstrumentTypeID IN (5,6)
- LP_Executed_Units = SUM(Units*(IsBuy*2-1)) -- net signed execution units
- LP_Avg_Rate = SUM(Units*(IsBuy*2-1)*ExecutionRate) / NULLIF(SUM(Units*(IsBuy*2-1)), 0)
- LP_Volume = SUM(Units*ExecutionRate) -- total execution notional
- Many instruments show LP_Executed_Units=0 (55% of 2026 rows), indicating internalized risk

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution with **CLUSTERED INDEX on Date ASC**. Date-range queries are efficient. No co-location benefit for JOINs -- use Date filter first, then instrument or hedge server filters.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily total hedge cost | `SELECT Date, SUM(HC) FROM Dealing_HedgeCost WHERE Date = @d GROUP BY Date` |
| Hedge cost by instrument for a date | `WHERE Date = @d ORDER BY ABS(HC) DESC` |
| Real vs CFD hedge cost breakdown | `WHERE Date BETWEEN @start AND @end GROUP BY Date, IsSettled` |
| Instruments with no LP hedging | `WHERE LP_Executed_Units = 0 AND Date = @d` |
| Top hedging costs by hedge server | `GROUP BY Date, HedgeServerID ORDER BY SUM(HC) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument type, display name, asset class |
| Dealing_dbo.Dealing_DailyZeroPnL_Stocks | ON Date, InstrumentID, HedgeServerID | Compare hedge cost with realized zero P&L |
| DWH_dbo.Fact_CurrencyPriceWithSplit | ON InstrumentID, OccurredDateID | Get market price for HC verification |

### 3.4 Gotchas

- **IsSettled is varchar, not int**: Values are 'Real' and 'CFD' (strings), not 0/1. Different from Dim_Position.IsSettled (int).
- **LP_Executed_Units = 0 is common**: ~55% of 2026 rows have zero LP units, meaning the instrument was not hedged externally. HC still has a value because it reflects mark-to-market on client positions.
- **FullCommission here is NOT from Dim_Position**: The column is named FullCommission but actually stores SUM(RealizedCommission) from Dealing_DailyZeroPnL_Stocks. This is a naming mismatch in the SP INSERT mapping.
- **VariableSpread can be NULL**: ~29% of 2026 rows have NULL VariableSpread (no matching BI_DB_VarCommission row).
- **Clients_Units can be negative**: Negative values indicate net short exposure for the instrument group.
- **HC can be negative**: Negative hedge cost means the hedge was profitable for eToro (LP execution was cheaper than client rates).
- **24/7 instruments**: Recent data includes 24/7 trading instruments (e.g., NVDA.24-7/USD) with HedgeServerID=226.
- **USD-only**: Only instruments with SellCurrencyID=1 (USD denomination) are included. Non-USD stocks/ETFs are excluded.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, source)` |
| *** | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_HedgeCost)` |
| ** | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the hedge cost snapshot. SP parameter @Date. (Tier 2 -- SP_HedgeCost) |
| 2 | InstrumentID | int | YES | The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. Filtered to SellCurrencyID=1 (USD) and InstrumentTypeID IN (5,6) (stocks/ETFs). (Tier 1 -- upstream wiki, Hedge.ExecutionLog via Dim_Instrument) |
| 3 | Name | varchar(50) | YES | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). Passthrough from Dim_Instrument. (Tier 1 -- upstream wiki, Trade.Instrument via Dim_Instrument) |
| 4 | IsSettled | varchar(20) | YES | Settlement type classification: 'Real' = settled stock ownership position (IsSettled=1 or HedgeServerID IN (9,102,112,125,126) for LP side), 'CFD' = contract-for-difference. Client-side uses Dim_PositionChangeLog correction (ChangeTypeID=13) to recover the IsSettled value AS OF the report date before any subsequent changes. (Tier 2 -- SP_HedgeCost) |
| 5 | Clients_Units | decimal(16,6) | YES | Net signed client position units for the instrument group: SUM((IsBuy*2-1)*AmountInUnitsDecimal). Positive = net long exposure, negative = net short. Combines positions opened on @Date (using InitForexRate) and closed on @Date (using EndForexRate with flipped IsBuy direction). (Tier 2 -- SP_HedgeCost) |
| 6 | AvgRateClientsNoSpread | decimal(16,6) | YES | Commission-adjusted average client rate: (NetUnits*AvgRate - FullCommission) / NULLIF(NetUnits, 0). Represents the effective cost basis for client positions after removing commission impact. Returns 0 when NetUnits is 0. (Tier 2 -- SP_HedgeCost) |
| 7 | VolumeMarket | decimal(16,6) | YES | Total client trading volume in USD for the instrument group: SUM(Volume) from Dim_Position for positions opened or closed on the report date. (Tier 2 -- SP_HedgeCost) |
| 8 | LP_Executed_Units | decimal(16,6) | YES | Net signed liquidity provider execution units: ISNULL(SUM(Units*(IsBuy*2-1)), 0) from successful hedge fills (Success=1) in CopyFromLake.etoro_Hedge_ExecutionLog. Zero when no external hedging occurred (internalized risk). (Tier 2 -- SP_HedgeCost) |
| 9 | LP_Avg_Rate | decimal(16,6) | YES | Volume-weighted average execution rate from the liquidity provider: ISNULL(SUM(Units*(IsBuy*2-1)*ExecutionRate) / NULLIF(SUM(Units*(IsBuy*2-1)), 0), 0). Zero when no LP executions exist. (Tier 2 -- SP_HedgeCost) |
| 10 | LP_Volume | decimal(16,6) | YES | Total LP execution notional volume: ISNULL(SUM(Units*ExecutionRate), 0) from successful hedge fills. Zero when no external hedging occurred. (Tier 2 -- SP_HedgeCost) |
| 11 | HC | decimal(16,6) | YES | Hedge cost: the net cost of hedging client positions against LP executions, marked to end-of-day market price. Formula: (AskSpreaded*NetUnits - (NetUnits*AvgRate - FullCommission)) - (AskSpreaded*LP_Executed_Units - (LP_Executed_Units*LP_Avg_Rate)). Positive = cost to eToro, negative = hedging profit. AskSpreaded from Fact_CurrencyPriceWithSplit. (Tier 2 -- SP_HedgeCost) |
| 12 | UpdateDate | datetime | YES | SP execution timestamp (GETDATE()). Not a business date -- reflects when the ETL batch ran. (Tier 3 -- SP_HedgeCost, GETDATE()) |
| 13 | HedgeServerID | int | YES | Hedge server that managed the position set. FK to Trade.HedgeServer. Grouping key -- positions and LP fills are matched by HedgeServerID. 25 distinct values in 2026 data. (Tier 2 -- SP_HedgeCost) |
| 14 | FullCommission | decimal(16,6) | YES | Aggregate realized commission from positions closed on the report date. Despite the column name, this is sourced from SUM(RealizedCommission) in Dealing_DailyZeroPnL_Stocks, NOT from Dim_Position.FullCommission. (Tier 2 -- SP_HedgeCost, Dealing_DailyZeroPnL_Stocks.RealizedCommission) |
| 15 | VariableSpread | decimal(16,6) | YES | Total spread-based (variable) commission for the instrument on the report date. Passthrough from BI_DB_VarCommission.VarCommission, matched by DateID, InstrumentID, IsSettled, and HedgeServerID. NULL when no matching VarCommission row exists (~29% of 2026 rows). (Tier 2 -- SP_HedgeCost, BI_DB_VarCommission.VarCommission) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @Date | Passthrough |
| InstrumentID | DWH_dbo.Dim_Position + CopyFromLake.etoro_Hedge_ExecutionLog | InstrumentID | Passthrough (grouping key) |
| Name | DWH_dbo.Dim_Instrument | Name | Passthrough (final JOIN) |
| IsSettled | DWH_dbo.Dim_PositionChangeLog + Dim_Position | PreviousIsSettled / IsSettled | CASE to 'Real'/'CFD' with changelog correction |
| Clients_Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal, IsBuy | SUM((IsBuy*2-1)*AmountInUnitsDecimal) |
| AvgRateClientsNoSpread | DWH_dbo.Dim_Position | AmountInUnitsDecimal, ForexRate, FullCommission | (NetUnits*AvgRate-Commission)/NULLIF(NetUnits,0) |
| VolumeMarket | DWH_dbo.Dim_Position | Volume | SUM(Volume) |
| LP_Executed_Units | CopyFromLake.etoro_Hedge_ExecutionLog | Units, IsBuy | ISNULL(SUM(Units*(IsBuy*2-1)),0) |
| LP_Avg_Rate | CopyFromLake.etoro_Hedge_ExecutionLog | Units, IsBuy, ExecutionRate | Weighted avg: SUM(U*D*R)/NULLIF(SUM(U*D),0) |
| LP_Volume | CopyFromLake.etoro_Hedge_ExecutionLog | Units, ExecutionRate | ISNULL(SUM(Units*ExecutionRate),0) |
| HC | Fact_CurrencyPriceWithSplit + aggregated columns | AskSpreaded + all client/LP metrics | Complex formula (see Section 2.1) |
| UpdateDate | ETL-computed | -- | GETDATE() |
| HedgeServerID | DWH_dbo.Dim_Position + CopyFromLake.etoro_Hedge_ExecutionLog | HedgeServerID | Passthrough (grouping key) |
| FullCommission | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | RealizedCommission | SUM(RealizedCommission) |
| VariableSpread | BI_DB_dbo.BI_DB_VarCommission | VarCommission | Passthrough |

### 5.2 ETL Pipeline

```
CopyFromLake.etoro_Hedge_ExecutionLog (LP fills, Success=1, SellCurrencyID=1, InstrumentTypeID IN (5,6))
  -> #LP (aggregated by InstrumentID, HedgeServerID, IsSettled)

DWH_dbo.Dim_Position (OpenDateID=@DateInt OR CloseDateID=@DateInt)
  + DWH_dbo.Dim_Instrument (SellCurrencyID=1, InstrumentTypeID IN (5,6))
  + DWH_dbo.Dim_Customer (IsValidCustomer=1)
  -> #Position (UNION ALL: opens + closes with flipped direction)

DWH_dbo.Dim_PositionChangeLog (ChangeTypeID=13, OccurredDateID > @DateInt)
  -> #IsSettled_pcl (IsSettled correction to report-date value)

#Position + #IsSettled_pcl -> #Position_IsSettled (corrected settlement type)
  -> #Clients (aggregated by InstrumentID, HedgeServerID, IsSettled)

#Clients
  + LEFT JOIN #LP (on InstrumentID, IsSettled, HedgeServerID)
  + LEFT JOIN Dealing_DailyZeroPnL_Stocks (on Date, InstrumentID, HedgeServerID, IsCFD)
  + LEFT JOIN BI_DB_VarCommission (on DateID, InstrumentID, IsSettled, HedgeServerID)
  -> #Final

#Final
  + JOIN Dim_Instrument (Name)
  + LEFT JOIN Fact_CurrencyPriceWithSplit (AskSpreaded for HC calculation)
  -> DELETE/INSERT into Dealing_dbo.Dealing_HedgeCost
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata (name, type, currency pair) |
| HedgeServerID | Trade.HedgeServer (implicit) | Hedge server identification |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.Dealing_DailyZeroPnL_Stocks | -- | Listed as downstream in DailyZeroPnL_Stocks wiki |

---

## 7. Sample Queries

### 7.1 Daily total hedge cost by settlement type

```sql
SELECT Date,
       IsSettled,
       SUM(HC) AS TotalHedgeCost,
       SUM(VolumeMarket) AS TotalClientVolume,
       SUM(LP_Volume) AS TotalLPVolume,
       COUNT(1) AS InstrumentCount
FROM [Dealing_dbo].[Dealing_HedgeCost]
WHERE Date = '2026-04-24'
GROUP BY Date, IsSettled
ORDER BY IsSettled;
```

### 7.2 Top 10 most expensive hedging instruments on a date

```sql
SELECT hc.InstrumentID,
       hc.Name,
       hc.IsSettled,
       hc.HC,
       hc.Clients_Units,
       hc.LP_Executed_Units,
       hc.FullCommission,
       hc.VariableSpread
FROM [Dealing_dbo].[Dealing_HedgeCost] hc
WHERE hc.Date = '2026-04-24'
ORDER BY hc.HC DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 7.3 Instruments with unhedged client exposure (no LP execution)

```sql
SELECT Date,
       COUNT(1) AS UnhedgedInstruments,
       SUM(ABS(Clients_Units)) AS TotalUnhedgedUnits,
       SUM(VolumeMarket) AS TotalUnhedgedVolume
FROM [Dealing_dbo].[Dealing_HedgeCost]
WHERE LP_Executed_Units = 0
  AND Date >= '2026-04-01'
GROUP BY Date
ORDER BY Date;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 2 T1, 12 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: Dealing_dbo.Dealing_HedgeCost | Type: Table | Production Source: SP_HedgeCost (Sarah Benchitrit, 2020-10-01)*
