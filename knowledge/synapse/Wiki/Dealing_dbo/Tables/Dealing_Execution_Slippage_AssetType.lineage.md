---
object: Dealing_Execution_Slippage_AssetType
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Execution_Slippage_AssetType

Source SP: `Dealing_dbo.SP_Execution_Slippage`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Date` parameter | SP parameter | 2 |
| InstrumentType | `DI.InstrumentType` (from #FX_Rate → Dim_Instrument) | DWH_dbo.Dim_Instrument | 2 |
| HedgingMode | `CASE WHEN HBC.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END` | Dealing_staging.Etoro_Hedge_HBCOrderLog | 2 |
| SlippageInDollar | `SUM((IsBuy=1?1:-1)×(eToro_Price−ExecutionRate)×Units×FX_Rate)` | Computed from #Total → grouped in #AssetType | 2 |
| UpdateDate | `GETDATE()` | System timestamp at SP execution | 2 |

### Aggregation Path

```
Dealing_staging.Etoro_Hedge_ExecutionLog       (#ExecutionRate1)
CopyFromLake.PriceLog_History_CurrencyPrice    (#eToroPrice — eToro price at SendTime)
CopyFromLake.PricesFromProvider_MarketCurrencyPrice  (#KustoAll, #KustoPrices — LP price at ExecutionTime)
DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument  (#FX_Rate — USD conversion)
Dealing_staging.Etoro_Hedge_HBCOrderLog        (HedgingMode lookup)
    │
    ▼  #Total  (row per InstrumentID × rate × ExecutionTime)
    │
    ▼  #AssetType  (GROUP BY InstrumentType, HedgingMode → SUM SlippageInDollar)
    │
    ▼
Dealing_dbo.Dealing_Execution_Slippage_AssetType
```

### Notes
- This table is a strict aggregation of `Dealing_Execution_Slippage` by InstrumentType/HedgingMode — no additional columns beyond the group key and sum.
- Requires Kusto feed (`PricesFromProvider_MarketCurrencyPrice`) to be non-empty; if empty, #KustoPrices has no rows and no data is written.
