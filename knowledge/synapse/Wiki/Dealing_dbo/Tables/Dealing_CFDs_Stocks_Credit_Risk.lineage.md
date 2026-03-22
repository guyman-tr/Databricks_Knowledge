# Column Lineage: Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | `BI_DB_dbo.BI_DB_PositionPnL` (Clients), `Dealing_staging.etoro_History_Netting_History` / `etoro_Hedge_Netting` (LP) |
| **ETL SP** | `Dealing_dbo.SP_CFDs_Stocks_Credit_Risk` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
LP path:
  etoro_History_Netting_History ──┐
  etoro_Hedge_Netting ────────────┤──► #hedge ──► #hedge1 ──► #LP (NOP, HedgeServerID IN 2,101 only)
  Fact_CurrencyPriceWithSplit ────┤                                    │
  Dim_Instrument ─────────────────┘                                    │
                                                                       ├──► #Eff_Leverage ──► #Buffer ──► #Final ──► #Scenarios2 ──► #Scenarios ──► INSERT
Client path:                                                           │                                                              ▲
  BI_DB_PositionPnL ──────┐                                            │                                                              │
  Dim_Instrument ─────────┤──► #Clients_NOP ──► #Eff_LeveragePerPosition ─┘                                            Dealing_DailyZeroPnL_Stocks ──► #Commission
  Dim_Customer ───────────┘
```

## Column Lineage

| DWH Column | Transform | Computation Formula |
|-----------|-----------|---------------------|
| Date | ETL-computed | `@Date` SP parameter |
| InstrumentID | passthrough | From Dim_Instrument via netting/position data |
| InstrumentType | join-enriched | `Dim_Instrument.InstrumentType` — filtered to InstrumentTypeID IN (5,6) = Stocks/ETF |
| InstrumentName | join-enriched | `Dim_Instrument.Name` |
| InstrumentDisplayName | join-enriched | `Dim_Instrument.InstrumentDisplayName` |
| OPLong | ETL-computed | `SUM(CASE WHEN IsBuy=1 THEN ABS(Clients_NOP) ELSE 0 END)` — total long open position value |
| EffLevLong | ETL-computed | NOP-weighted avg effective leverage for longs: `SUM(ABS(NOP)*EffLev)/SUM(ABS(NOP))` where EffLev = `ABS(NOP)/(Amount+PositionPnL)` |
| OPShort | ETL-computed | `SUM(CASE WHEN IsBuy=0 THEN ABS(Clients_NOP) ELSE 0 END)` |
| EffLevShort | ETL-computed | NOP-weighted avg effective leverage for shorts |
| Clients_NOP | ETL-computed | `SUM(Clients_NOP)` from BI_DB_PositionPnL, CFD only (IsSettled=0), valid customers, HedgeServerID IN (2,101) |
| LP_NOP | ETL-computed | `SUM(Units*Price*(2*IsBuy-1)*FX_rate)` from netting, HedgeServerID IN (2,101), InstrumentTypeID IN (5,6) |
| NetExposure(Clients-LP) | ETL-computed | `Clients_NOP - LP_NOP` |
| Buffer_Long | ETL-computed | `1/EffLevLong` — equity buffer fraction before margin call |
| Buffer_Short | ETL-computed | `1/EffLevShort` |
| Scenario_1_-15% | ETL-computed | `CASE WHEN Buffer_Long>0.15 THEN 0 ELSE OPLong*(0.15-Buffer_Long) END` |
| Scenario_2_-20% | ETL-computed | `CASE WHEN Buffer_Long>0.20 THEN 0 ELSE OPLong*(0.20-Buffer_Long) END` |
| Scenario_3_-25% | ETL-computed | `CASE WHEN Buffer_Long>0.25 THEN 0 ELSE OPLong*(0.25-Buffer_Long) END` |
| Scenario_4_-30% | ETL-computed | `CASE WHEN Buffer_Long>0.30 THEN 0 ELSE OPLong*(0.30-Buffer_Long) END` |
| Scenario_5_15% | ETL-computed | `CASE WHEN Buffer_Short>0.15 THEN 0 ELSE OPShort*(0.15-Buffer_Short) END` |
| Scenario_6_20% | ETL-computed | `CASE WHEN Buffer_Short>0.20 THEN 0 ELSE OPShort*(0.20-Buffer_Short) END` |
| Scenario_7_25% | ETL-computed | `CASE WHEN Buffer_Short>0.25 THEN 0 ELSE OPShort*(0.25-Buffer_Short) END` |
| Scenario_8_30% | ETL-computed | `CASE WHEN Buffer_Short>0.30 THEN 0 ELSE OPShort*(0.30-Buffer_Short) END` |
| Scenario_9_-50% | ETL-computed | `CASE WHEN Buffer_Long>0.50 THEN 0 ELSE OPLong*(0.50-Buffer_Long) END` |
| Scenario_10_50% | ETL-computed | `CASE WHEN Buffer_Short>0.50 THEN 0 ELSE OPShort*(0.50-Buffer_Short) END` |
| UpdateDate | ETL-computed | `GETDATE()` |
| Commissions30Days | ETL-computed | `SUM(RealizedCommission)` from `Dealing_DailyZeroPnL_Stocks` for past 30 days per instrument |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 21 |
| **Join-enriched** | 3 |
| **Passthrough** | 1 |
| **Total** | 25 |
