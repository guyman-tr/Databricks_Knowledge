# Column Lineage: Dealing_dbo.Dealing_LP_StocksNOP

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_LP_StocksNOP` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `Dealing_staging.etoro_History_Netting_History`, `Dealing_staging.etoro_Hedge_Netting` |
| **ETL SP** | `Dealing_dbo.SP_Capital_Adequacy_IFR_KPMG` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `Dealing_staging.Etoro_Hedge_ExecutionLog` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Dealing_staging.etoro_History_Netting_History ─┐
Dealing_staging.etoro_Hedge_Netting ───────────┤
DWH_dbo.Fact_CurrencyPriceWithSplit ──────────┤──► #hedge ──► #hedge1 ──► #LP ──► #temp_NOP ──► #temp ──► Dealing_LP_StocksNOP
DWH_dbo.Dim_Instrument ──────────────────────┤                                     ▲
Dealing_staging.Etoro_Hedge_ExecutionLog ─────┘──── #LPVolume ──────────────────────┘
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived/calculated by ETL SP. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter | Input reporting date |
| HedgeServerID | #hedge1 | HedgeServerID | passthrough | Via etoro_History_Netting_History / etoro_Hedge_Netting | LP hedge server identifier |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | join-enriched | Via InstrumentID JOIN from netting data | Asset class |
| Real/CFD | — | HedgeServerID | ETL-computed | `CASE WHEN HedgeServerID IN (3,9,102,112,125,126,81) THEN 'Real' ELSE 'CFD' END` | Hardcoded server-to-settlement mapping |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |
| LP_VolumeBuy | Dealing_staging.Etoro_Hedge_ExecutionLog | Units, ExecutionRate | ETL-computed | `SUM(CASE WHEN IsBuy=1 THEN Units*ExecutionRate ELSE 0 END)` WHERE HedgeServerID=81 AND Success=1. Only Real Stocks server. ISNULL(...,0) for other servers. | LP buy volume for the day |
| LP_VolumeSell | Dealing_staging.Etoro_Hedge_ExecutionLog | Units, ExecutionRate | ETL-computed | `SUM(CASE WHEN IsBuy=0 THEN Units*ExecutionRate ELSE 0 END)` WHERE HedgeServerID=81 AND Success=1. ISNULL(...,0) for other servers. | LP sell volume for the day |
| OPLong | #hedge1 + #Prices | Units, Bid, IsBuy, Currency* | ETL-computed | `Units*Bid*(2*IsBuy-1)*FX_rate` when IsBuy=1, else 0. FX conversion: multi-step via SellCurrencyID/BuyCurrencyID to CurrencyID=1 (USD). Aggregated: `SUM(OPLong)` grouped by HedgeServerID, InstrumentType, Real/CFD. | LP long open position value in USD |
| OPShort | #hedge1 + #Prices | Units, Ask, IsBuy, Currency* | ETL-computed | `Units*Ask*(2*IsBuy-1)*FX_rate` when IsBuy=0, else 0. FX conversion same as OPLong but uses Ask prices. Aggregated: `SUM(OPShort)`. | LP short open position value in USD (negative) |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 6 |
| **Join-enriched** | 1 |
| **Passthrough** | 1 |
| **Total** | 9 (including Date from SP param) |
