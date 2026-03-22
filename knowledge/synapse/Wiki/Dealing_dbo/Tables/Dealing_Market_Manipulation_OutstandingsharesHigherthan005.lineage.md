# Lineage Map — Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_Market_Manipulation_OutstandingsharesHigherthan005(@Date)`
**Pattern**: DELETE WHERE Date=@Date + INSERT (daily)

## ETL Chain

```
CopyFromLake.etoro_Hedge_ExecutionLog (ExecutionTime on @Date)
  [HedgeServerID NOT IN CFD+Internal servers]
  → #EtoroExecutions (SUM(Units) by InstrumentID)

DWH_dbo.Dim_Instrument (InstrumentTypeID IN 5,6; InstrumentID<>2731)
  → #StocksADV_Shares (ADV_Last3Months, SharesOutStanding)

#EtoroExecutions JOIN #StocksADV_Shares
  WHERE EtoroVolumeInUnits/SharesOutStanding > 0.005
  → #EtoroDaily

DWH_dbo.Dim_Position + Dim_Customer (PlayerLevelID<>4, same-day open+close, IsSettled=1)
  JOIN #EtoroDaily
  HAVING VolumeInUnitsDailyRealized/SharesOutStanding > 0.0025
  → #TopCIDs (CID-level flags)

#TopCIDs + #EtoroExecutions + #TotalCustomerUnits
  → #CID_VolumeExternalised (final output with VolumeExternalised_CID)
        └── Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005
              └── (also TRUNCATE+INSERT → Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email)
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | @Date parameter | — | Report date |
| CID | DWH_dbo.Dim_Position | CID | Via #TopCIDs |
| InstrumentID | #EtoroDaily | InstrumentID | Direct |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Direct |
| ADV_Last3Months | DWH_dbo.Dim_Instrument | ADV_Last3Months | Direct |
| SharesOutStanding | DWH_dbo.Dim_Instrument | SharesOutStanding | Direct |
| VolumeInUnitsDailyRealized | DWH_dbo.Dim_Position | AmountInUnitsDecimal | SUM(×2 for round-trip) from #TopCIDs |
| RealizedZero | DWH_dbo.Dim_Position | FullCommissionOnClose+NetProfit | SUM — net P&L including commission |
| EtoroVolumeExternalized | CopyFromLake.etoro_Hedge_ExecutionLog | Units | SUM by InstrumentID |
| CustomersTotalUnits | DWH_dbo.Dim_Position | AmountInUnitsDecimal | SUM open+close for instrument |
| VolumeExternalised_CID | Computed | — | (VolumeInUnitsDailyRealized × EtoroVolumeExternalized) / CustomersTotalUnits |
| UpdateDate | GETDATE() | — | ETL timestamp |

## Governance

- **Threshold**: EtoroVolume/SharesOutstanding > 0.5% for instrument flagging; CID flagged if own realized > 0.25% of outstanding
- **HedgeServerID exclusions**: 2,7,101 (CFD), 121-124 (internal), 225-226 (EtoroX), 3,9,112,125,126,128 (Real stocks real LPs) — only measures non-LP-hedged flow
- **PlayerLevelID≠4**: Excludes eToro employees from CID detection
- **NULL sentinel**: If no breaches detected, #Date LEFT JOIN returns NULL row for date continuity
