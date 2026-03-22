# Lineage Map — Dealing_dbo.Dealing_PriceLocks

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_PriceLocks(@date)` (migrated from Databricks SR-244984, Mar 2024)
**Pattern**: DELETE WHERE Date=@Date + INSERT (daily)

## ETL Chain

```
CopyFromLake.DealingLogs_Price_InstrumentEventLog
  (EventType IN 1=SpreadLock, 2=VolatilityLock; Occurred on @date)
  + Dealing_staging.External_DealingLogs_Dictionary_InstrumentEventType — event type name

Dealing_staging.External_CalendarDB_Market_MergedDailySchedules
  + DWH_dbo.Dim_ExchangeInfo — exchange description
  → #MarketsHours (session open/close times per instrument)

DWH_dbo.Dim_Instrument (Tradable=1)
  → #Exc_Ins (exchange normalisation per instrument)

#PriceLocks (instrument×lock event with LAG for duration)
  × market hours → DuringSession flag
  + EOD price → EOD_Price
  + LP mapping → LiquidityAccountID, LA_Name
        └── Dealing_dbo.Dealing_PriceLocks
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | @date parameter | — | Report date |
| DateID | Computed | @dateINT | DateToDateID(@date) |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Direct |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Direct |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct |
| Exchange | DWH_dbo.Dim_ExchangeInfo | ExchangeDescription | Normalised lowercase |
| EventName | Dealing_staging.External_DealingLogs_Dictionary_InstrumentEventType | Name | Direct (SpreadLock/VolatilityLock) |
| TotalLocks | CopyFromLake.DealingLogs_Price_InstrumentEventLog | — | COUNT of lock events |
| TotalDuration | CopyFromLake.DealingLogs_Price_InstrumentEventLog | Occurred - LAG_Occurred | SUM of lock durations (ms) |
| DuringSession | Computed | — | COUNT of locks within market session hours |
| minVolatility_Pips | CopyFromLake.DealingLogs_Price_InstrumentEventLog | Details | Parsed from event Details |
| maxVolatility_Pips | CopyFromLake.DealingLogs_Price_InstrumentEventLog | Details | Parsed from event Details |
| SpreadLockThresholdPercentage | CopyFromLake.DealingLogs_Price_InstrumentEventLog | Details | Parsed from event Details |
| minTimeOut_MS | CopyFromLake.DealingLogs_Price_InstrumentEventLog | Details | Parsed from event Details |
| maxTimeOut_MS | CopyFromLake.DealingLogs_Price_InstrumentEventLog | Details | Parsed from event Details |
| EOD_Price | Dealing_staging (EOD price source) | — | End-of-day price |
| TotalInFirst10Min | Computed | — | Locks within first 10 min of session (added Apr 2022) |
| LiquidityAccountID | Dealing_staging (LP mapping) | — | Primary LP for instrument |
| LA_Name | Dealing_staging (LP mapping) | — | LP display name |
| TotalInFist15Min | Computed | — | Locks in first 15 min of session (typo "Fist" preserved from DDL) |
| TotalInLast5Min | Computed | — | Locks in last 5 min of session |
| UpdateDate | GETDATE() | — | ETL timestamp |

## Governance

- **EventType 1**: SpreadLock (bid-ask spread exceeds threshold)
- **EventType 2**: VolatilityLock (price volatility exceeds threshold)
- **Source**: CopyFromLake.DealingLogs_Price_InstrumentEventLog (Dealing logs real-time feed)
- **OpsDB**: Priority 0, Daily, SB_Daily (two entries = both from original and migrated)
- **DDL note**: Column `TotalInFist15Min` has a typo (should be "First") — preserved from DDL
