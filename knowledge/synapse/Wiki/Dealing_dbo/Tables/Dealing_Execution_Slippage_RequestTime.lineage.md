---
object: Dealing_Execution_Slippage_RequestTime
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Execution_Slippage_RequestTime

Source SP: `Dealing_dbo.SP_Execution_Slippage`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Date` parameter | SP parameter | 2 |
| InstrumentID | `ER.InstrumentID` | Dealing_staging.Etoro_Hedge_ExecutionLog | 1 |
| RequestTime | `A.Occurred` (CROSS APPLY TOP 1 from PriceLog where Occurred ≤ ExecutionTime) | CopyFromLake.PriceLog_History_CurrencyPrice | 2 |
| ExecutionTime | `ER.ExecutionTime` | Dealing_staging.Etoro_Hedge_ExecutionLog | 2 |
| IsBuy | `ER.IsBuy` | Dealing_staging.Etoro_Hedge_ExecutionLog | 2 |
| Units | `SUM(ER.Units)` | Dealing_staging.Etoro_Hedge_ExecutionLog | 2 |
| ExecutionRate | `ER.ExecutionRate` | Dealing_staging.Etoro_Hedge_ExecutionLog | 2 |
| eToro_RequestTimePrice | `CASE WHEN IsBuy=1 THEN A.Ask ELSE A.Bid END` | CopyFromLake.PriceLog_History_CurrencyPrice | 2 |
| ProviderAmount_USD | `SUM(Units × ExecutionRate × FX_Rate)` | Computed | 2 |
| eToro_RequestTimeAmountUSD | `SUM(Units × eToro_RequestTimePrice × FX_Rate)` | Computed | 2 |
| FX_Rate | Complex CASE: SellCurrencyID=1→1; BuyCurrencyID=1→1/Bid(Ask); GBX→FX/100; cross→1/rate | DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument | 2 |
| Slippage | `(IsBuy=1?+1:-1)×(ExecutionRate−eToro_RequestTimePrice)` | Computed | 2 |
| SlippageInDollar | `(IsBuy=1?+1:-1)×(eToro_RequestTimePrice−ExecutionRate)×Units×FX_Rate` | Computed | 2 |
| Slippage_Percent | `(IsBuy=1?+1:-1)×(ExecutionRate−eToro_RequestTimePrice)/eToro_RequestTimePrice` | Computed | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |
| HedgingMode | `CASE WHEN HBC.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END` | Dealing_staging.Etoro_Hedge_HBCOrderLog | 2 |
| NumberofTransaction | `COUNT(*)` | Dealing_staging.Etoro_Hedge_ExecutionLog | 2 |

### Pipeline Flow

```
Dealing_staging.Etoro_Hedge_ExecutionLog   (#ExecutionRate1 — filtered: Success=1, ExecutionTime in @Date, HedgeServerID≠5000)
Dealing_staging.Etoro_Hedge_HBCOrderLog    (LEFT JOIN for HedgingMode)
DWH_dbo.Fact_CurrencyPriceWithSplit        (#Rates — daily FX)
DWH_dbo.Dim_Instrument                     (#FX_Rate — with CCY logic)
    │
    ▼  #ExecutionRate  (+ FX_Rate, HedgingMode)
    │
    ├── CopyFromLake.PriceLog_History_CurrencyPrice  (CROSS APPLY: Occurred ≤ ExecutionTime)
    │
    ▼  #eToroPrice_RequestTime  (+ eToro Bid/Ask at RequestTime)
    │
    ▼  #Total_RequestTime  (GROUP BY InstrumentID, Occurred, ExecutionTime, IsBuy, ExecutionRate, HedgingMode, FX_Rate)
    │
    ▼
Dealing_dbo.Dealing_Execution_Slippage_RequestTime
```

### Notes
- `InstrumentID` is Tier 1 (FK to Dim_Instrument, documented in upstream wiki as Trade.Instrument PK).
- All other columns are Tier 2 from SP_Execution_Slippage code analysis.
- No Kusto dependency — pipeline survives `PricesFromProvider_MarketCurrencyPrice` outage.
