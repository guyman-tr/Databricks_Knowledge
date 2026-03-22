---
object: Dealing_Execution_Slippage
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Execution_Slippage

Source SP: `Dealing_dbo.SP_Execution_Slippage`

### Source Tables
| Alias | Table | Role |
|-------|-------|------|
| EL | `Dealing_staging.Etoro_Hedge_ExecutionLog` | Primary execution records |
| PH | `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro internal price at SendTime (matched by RateIDAtSent) |
| LP | `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` | Kusto LP market price at SendTime |
| FX | `DWH_dbo.Fact_CurrencyPriceWithSplit` | FX rate for USD conversion |
| DI | `DWH_dbo.Dim_Instrument` | Instrument metadata (CCY1, CurrencyID) |
| HBC | `Dealing_staging.Etoro_Hedge_HBCOrderLog` | HedgingMode lookup (CBH vs HBC) |

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `CAST(EL.SendTime AS DATE)` | Etoro_Hedge_ExecutionLog | 2 |
| HedgeServerID | `EL.HedgeServerID` | Etoro_Hedge_ExecutionLog | 2 |
| InstrumentID | `EL.InstrumentID` | Etoro_Hedge_ExecutionLog → Dim_Instrument FK | 1 |
| AssetTypeID | `DI.AssetTypeID` | Dim_Instrument | 2 |
| IsBuy | `EL.IsBuy` | Etoro_Hedge_ExecutionLog | 2 |
| Units | `EL.Units` | Etoro_Hedge_ExecutionLog | 2 |
| eToroPrice | `PH.Rate` (matched by RateIDAtSent) | PriceLog_History_CurrencyPrice | 2 |
| ExecutionRate | `EL.ExecutionRate` | Etoro_Hedge_ExecutionLog | 2 |
| LPPrice | `LP.Price` (matched by timestamp) | PricesFromProvider_MarketCurrencyPrice | 2 |
| FX_Rate | `FX.Price` (via DI.CurrencyID, CCY1=USD) | Fact_CurrencyPriceWithSplit | 2 |
| SlippageInPoints | `(IsBuy=1 ? 1 : -1) × (ExecutionRate − eToroPrice)` | Computed | 2 |
| SlippageInDollar | `SlippageInPoints × Units × FX_Rate` | Computed | 2 |
| SlippageFromLP | `(IsBuy=1 ? 1 : -1) × (ExecutionRate − LPPrice)` | Computed | 2 |
| SlippagePctFromLP | `SlippageFromLP / LPPrice` | Computed | 2 |
| HedgingMode | `CASE WHEN HBC.OrderID IS NOT NULL THEN 'HBC' ELSE 'CBH' END` | Etoro_Hedge_HBCOrderLog | 2 |
| SendTime | `EL.SendTime` | Etoro_Hedge_ExecutionLog | 2 |
| ExecutionTime | `EL.ExecutionTime` | Etoro_Hedge_ExecutionLog | 2 |
| ExecutionTimeMs | `DATEDIFF(ms, EL.SendTime, EL.ExecutionTime)` | Computed | 2 |
| HedgeOrderID | `EL.HedgeOrderID` | Etoro_Hedge_ExecutionLog | 2 |
| PositionID | `EL.PositionID` | Etoro_Hedge_ExecutionLog | 2 |
| RateIDAtSent | `EL.RateIDAtSent` | Etoro_Hedge_ExecutionLog | 2 |

### Pipeline Flow

```
Dealing_staging.Etoro_Hedge_ExecutionLog   (primary execution records)
    │
    ├── CopyFromLake.PriceLog_History_CurrencyPrice  (eToro price at SendTime, via RateIDAtSent)
    ├── CopyFromLake.PricesFromProvider_MarketCurrencyPrice  (Kusto LP price — STALE since Oct 2024)
    ├── DWH_dbo.Fact_CurrencyPriceWithSplit  (FX rate for USD conversion)
    ├── DWH_dbo.Dim_Instrument  (instrument metadata: AssetTypeID, CCY1, CurrencyID)
    └── Dealing_staging.Etoro_Hedge_HBCOrderLog  (HedgingMode: CBH vs HBC)
                │
                ▼
    Dealing_dbo.SP_Execution_Slippage
                │
                ├── Dealing_dbo.Dealing_Execution_Slippage  ← THIS TABLE (STALE since Oct 2024)
                ├── Dealing_dbo.Dealing_Execution_Slippage_AssetType  (aggregated by asset type)
                ├── Dealing_dbo.Dealing_Execution_Slippage_RequestTime (execution-time based, ACTIVE)
                └── Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime (active)
```

### Notes
- All Tier 2 sourced from `SP_Execution_Slippage` SSDT repo analysis.
- `InstrumentID` is Tier 1 because it is a FK to `DWH_dbo.Dim_Instrument` (documented in upstream wiki as PK of `Trade.Instrument`).
- `LPPrice` and derived columns (`SlippageFromLP`, `SlippagePctFromLP`) require `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` which has been non-functional since ~2024-10-03.
