---
object: Dealing_Execution_Slippage_AssetType_RequestTime
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Execution_Slippage_AssetType_RequestTime

Source SP: `Dealing_dbo.SP_Execution_Slippage`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Date` parameter | SP parameter | 2 |
| InstrumentType | `DI.InstrumentType` (from #FX_Rate → Dim_Instrument) | DWH_dbo.Dim_Instrument | 2 |
| HedgingMode | `CASE WHEN HBC.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END` | Dealing_staging.Etoro_Hedge_HBCOrderLog | 2 |
| SlippageInDollar | `SUM((IsBuy=1?1:-1)×(eToro_RequestTimePrice−ExecutionRate)×Units×FX_Rate)` | Computed from #Total_RequestTime → #AssetType_RequestTime | 2 |
| UpdateDate | `GETDATE()` | System timestamp at SP execution | 2 |

### Aggregation Path

```
Dealing_staging.Etoro_Hedge_ExecutionLog    (#ExecutionRate, #ExecutionRate1)
CopyFromLake.PriceLog_History_CurrencyPrice (#eToroPrice_RequestTime — CROSS APPLY: last Occurred ≤ ExecutionTime)
DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument  (#FX_Rate — USD conversion)
Dealing_staging.Etoro_Hedge_HBCOrderLog    (HedgingMode lookup)
    │
    ▼  #Total_RequestTime  (row per InstrumentID × RequestTime × ExecutionTime)
    │
    ▼  #AssetType_RequestTime  (GROUP BY InstrumentType, HedgingMode → SUM SlippageInDollar)
    │
    ▼
Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime
```

### Notes
- No dependency on `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` (Kusto) — this is why it remains active while the SendTime variant is stale.
- `eToro_RequestTimePrice` = `CASE WHEN IsBuy=1 THEN Ask ELSE Bid END` from the PriceLog record with `Occurred <= ExecutionTime` (i.e., the last eToro price before the LP executed).
