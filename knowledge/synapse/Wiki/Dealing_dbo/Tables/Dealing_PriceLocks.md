# Dealing_dbo.Dealing_PriceLocks

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_PriceLocks |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_PriceLocks(@date)` |
| **Refresh** | Daily (Priority 0, SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~6.9M |
| **Date Range** | 2021-02-25 → 2026-03-10 (active ✅) |
| **PII** | None |

---

## 1. Business Meaning

Daily instrument-level log of **price lock events** on eToro's trading platform. A price lock occurs when an instrument's pricing feed is temporarily suspended due to either:
- **SpreadLock (EventType=1)**: Bid-ask spread exceeds a configured threshold
- **VolatilityLock (EventType=2)**: Price volatility exceeds a configured threshold

Each row captures aggregated statistics for one instrument × one event type × one date — total lock count, total locked duration (ms), and timing breakdowns relative to market session hours (first 10/15 min, last 5 min, during-session vs off-hours). Used by Dealing/Risk teams to monitor pricing feed quality, identify instruments with frequent lock events, and evaluate LP performance.

Migrated from Databricks (SR-244984, Mar 2024); updated to use new market schedule table (SR-258289).

---

## 2. Grain

One row = one InstrumentID × one EventName (SpreadLock or VolatilityLock) × one Date.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `Date` | date | Report date |
| `DateID` | int | Date as integer (YYYYMMDD) |
| `InstrumentID` | int | Instrument identifier |
| `InstrumentTypeID` | int | Instrument type from Dim_Instrument |
| `InstrumentDisplayName` | nvarchar | Display name from Dim_Instrument |
| `Exchange` | varchar | Normalised exchange description (lowercase) from Dim_ExchangeInfo |
| `EventName` | varchar | 'SpreadLock' or 'VolatilityLock' |
| `TotalLocks` | int | COUNT of lock events for this instrument/type/date |
| `TotalDuration` | bigint | SUM of all lock durations in milliseconds |
| `DuringSession` | int | COUNT of locks that occurred within market session hours |
| `minVolatility_Pips` | float | Minimum volatility threshold (parsed from event Details field) |
| `maxVolatility_Pips` | float | Maximum volatility threshold (parsed from event Details field) |
| `SpreadLockThresholdPercentage` | float | Spread threshold % that triggered locks (parsed from Details) |
| `minTimeOut_MS` | int | Minimum lock timeout in milliseconds (from event Details) |
| `maxTimeOut_MS` | int | Maximum lock timeout in milliseconds (from event Details) |
| `EOD_Price` | float | End-of-day price for the instrument |
| `TotalInFirst10Min` | int | Lock count in first 10 minutes of session (added Apr 2022) |
| `LiquidityAccountID` | int | Primary liquidity provider for this instrument |
| `LA_Name` | varchar | LP display name |
| `TotalInFist15Min` | int | Lock count in first 15 minutes of session (**typo "Fist" in DDL** — preserved from source) |
| `TotalInLast5Min` | int | Lock count in last 5 minutes of session |
| `UpdateDate` | datetime | ETL metadata timestamp |

---

## 4. Common Query Patterns

```sql
-- Most-locked instruments on a date
SELECT InstrumentDisplayName, EventName, TotalLocks, TotalDuration/1000.0 AS DurationSec,
       DuringSession, TotalInFirst10Min, TotalInFist15Min, TotalInLast5Min
FROM Dealing_dbo.Dealing_PriceLocks
WHERE Date = '2026-03-10'
ORDER BY TotalLocks DESC;

-- Daily lock trend for a specific instrument
SELECT Date, EventName, SUM(TotalLocks) AS Locks, SUM(TotalDuration)/1000 AS TotalSecLocked
FROM Dealing_dbo.Dealing_PriceLocks
WHERE InstrumentID = 1234
  AND Date >= '2026-01-01'
GROUP BY Date, EventName
ORDER BY Date;
```

> ⚠️ **~6.9M rows** — always filter by Date or InstrumentID. Note `TotalInFist15Min` column name has a typo (should be "First") — match exact spelling in queries.

---

## 5. Known Issues & Quirks

- **Column name typo**: `TotalInFist15Min` — the word "Fist" is a typo for "First" — preserved from the DDL and cannot be changed without a schema migration
- **Duration in milliseconds**: `TotalDuration` is in ms, not seconds — divide by 1000 for human-readable output
- **Details parsing**: volatility/spread thresholds are parsed from a semi-structured `Details` text field in the source log — may be NULL if event format changed
- **Market hours dependency**: `DuringSession` and time-window columns (First10Min, First15Min, Last5Min) depend on `External_CalendarDB_Market_MergedDailySchedules` being current
- **Two OpsDB entries**: Both the original and migrated SP appear in OpsDB — Priority 0, Daily, SB_Daily for both

---

## 6. Lineage Summary

Sources: CopyFromLake.DealingLogs_Price_InstrumentEventLog (lock events) + Dealing_staging.External_CalendarDB_Market_MergedDailySchedules (session hours) + DWH_dbo.Dim_Instrument + Dim_ExchangeInfo + LP mapping tables. See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `CopyFromLake.DealingLogs_Price_InstrumentEventLog` | Primary source — price lock event log |
| `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules` | Market session hours (for DuringSession/time-window columns) |
| `DWH_dbo.Dim_Instrument` | Instrument metadata, Tradable filter |
| `DWH_dbo.Dim_ExchangeInfo` | Exchange descriptions |

---

*Quality score: 7.5/10 — active, important dealing ops table; column typo is a known wart*
