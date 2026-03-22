# Column Lineage: Dealing_dbo.Dealing_ApexRecon_TradeActivity

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_Apex_Recon

## Pipeline Summary

```
Dealing_dbo.Dealing_Duco_ActivityRecon         ─┐ (eToro side — prerequisite)
Dealing_dbo.Dealing_Duco_EODRecon              ─┤ (eToro EOD — prerequisite)
Dealing_staging.LP_APEX_EXT872_3EU_217314      ─┤─► SP_Apex_Recon ──► Dealing_ApexRecon_TradeActivity
Dealing_staging.etoro_Trade_LiquidityAccounts  ─┤   (step 1 of 3)  (date replacement)
Fivetran HS/LA mapping                         ─┘
                                                         │
                                                         └──► Dealing_ApexRecon_Holdings (step 2)
                                                              └──► Dealing_ApexRecon_Hedging (step 3)
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @Date parameter | — | Report date |
| InstrumentID | Dealing_Duco_ActivityRecon | InstrumentID | Join key |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct join |
| ISINCode | Dealing_Duco_ActivityRecon | ISINCode | Direct passthrough |
| LiquidityAccountID | Fivetran HS/LA mapping | LiquidityAccountID | Resolved from HedgeServerID |
| IsBuy | — | CASE WHEN Buy/Sell='Buy' THEN 1 ELSE 0 | From ActivityRecon Buy/Sell column |
| Etoro_Units | Dealing_Duco_ActivityRecon | eToro_Units | eToro LP execution units |
| Apex_Units | Dealing_staging.LP_APEX_EXT872_3EU_217314 | Units | Apex broker reported units |
| Etoro_Rate | Dealing_Duco_ActivityRecon | eToro_AvgRate | eToro weighted average rate |
| Apex_Rate | Dealing_staging.LP_APEX_EXT872_3EU_217314 | Rate | Apex weighted average rate |
| Etoro_Amount | Dealing_Duco_ActivityRecon | eToroUSDAmount | eToro USD execution amount |
| Apex_Amount | Dealing_staging.LP_APEX_EXT872_3EU_217314 | Amount | Apex USD amount |
| UpdateDate | GETDATE() | — | Batch timestamp |
| HedgeServerID | Fivetran HS/LA mapping | HedgeServerID | From LP account mapping |
| AccountNumber | Dealing_staging.LP_APEX_EXT872_3EU_217314 | AccountNumber | Apex account identifier |

## FULL OUTER JOIN Pattern

```
Dealing_Duco_ActivityRecon (eToro side, @Date)
FULL OUTER JOIN
LP_APEX_EXT872_3EU_217314 (Apex side, @Date with DST adjustment)
ON LiquidityAccountID + InstrumentID + IsBuy direction
```

## ETL Pattern

- Date-range replacement for @Date
- Written as step 1 of 3 (before Holdings and Hedging)
- Additional intraday run via SP_Run_Recon at 12:00 UTC
- DST-aware date boundary for Apex file alignment
