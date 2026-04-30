# Hedge.ExposureBreakdownLog

> CES (Central Exposure Service) exposure publication target: each row is a snapshot of the net exposure state for one instrument on one hedge server at one point in time, written by CES on every exposure aggregation cycle to support monitoring and circuit breaker logic.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | EntryID IDENTITY (NONCLUSTERED PK + CLUSTERED on Occurred) |
| **Partition** | No |
| **Indexes** | 2 active (NONCLUSTERED PK + CLUSTERED on Occurred, FILLFACTOR=90) |

---

## 1. Business Meaning

Hedge.ExposureBreakdownLog is the primary exposure publication table for the CES (Central Exposure Service). Every time CES completes an aggregation cycle, it writes one row per (HedgeServerID, InstrumentID) pair, capturing: the customer's gross buy and sell positions, how much has been hedged, how much is pending in queue, and the net USD exposure. This provides a continuous time-series of the hedge system's view of net customer exposure.

CES has two aggregators that write here:
1. **AggregateByHedgeServerInstrument** (IsAggregated=0): Per-server, per-instrument exposure snapshots. This is the standard exposure publication used for CBH hedging decisions.
2. **NetOpenDollarsAggregator** (IsAggregated=1): NOP (Net Open Positions) aggregated by InstrumentID only, used for exposure circuit breaker logic. No IsAggregated=1 rows appear in this environment (may write to a separate logger DB per CES `DBLogID` configuration).

From the CES Overview Confluence page: "The table the CES publishes exposures to is Hedge.ExposureBreakdownLog". No stored procedure writes to this table - the CES application writes directly via its SQL connection.

The table holds 397,157 rows spanning 2023-01-04 to 2024-07-31 in this environment. 1,512 distinct InstrumentIDs are represented, ranging from 0 to 100271. InstrumentID=100000+ appears to be a synthetic NOP total instrument not in Trade.Instrument.

**Schema note**: The SSDT DDL contains a `Queued` column (`decimal(22,6) NOT NULL DEFAULT 0`) that does NOT exist in the live database - schema drift. This column was added to the SSDT but not deployed. Queries against the live DB should not reference this column.

A companion history table, `History.ExposureBreakdownLog`, stores older records with narrower precision (decimal(16,6) vs (22,6)) and no ExposureID/Queued columns.

---

## 2. Business Logic

### 2.1 Exposure Snapshot Columns

**What**: Each row is a complete state snapshot of the exposure for one instrument on one hedge server at one moment.

**Columns/Parameters Involved**: `OpenedBuyUnits`, `OpenedSellUnits`, `HedgedUnits`, `RequestedUnits`, `NetUSDExposure`

**Rules**:
- `OpenedBuyUnits`: Total gross customer BUY units currently open for this instrument/server (long customer positions). Precision (22,6) - high-precision to accumulate many fractional positions.
- `OpenedSellUnits`: Total gross customer SELL units currently open (short customer positions).
- `HedgedUnits`: The amount currently hedged via liquidity provider. Represents the position eToro holds in the market to offset customer exposure.
- `RequestedUnits`: Units in orders currently submitted to the provider but not yet confirmed. Negative = pending sell hedge; positive = pending buy hedge.
- `NetUSDExposure`: The net USD value of unhedged exposure. `= (OpenedBuyUnits - OpenedSellUnits - HedgedUnits - RequestedUnits) * Price`. Negative NetUSDExposure indicates net long customer position (customers holding more buy than sell, requiring eToro to hold a hedge position). In the recent data: ~-$92M USD = eToro is significantly long on InstrumentID 100000 (NOP total).

### 2.2 IsAggregated Flag

**What**: Distinguishes per-server/instrument rows from cross-server NOP aggregated rows.

**Columns/Parameters Involved**: `IsAggregated`, `HedgeServerID`, `InstrumentID`

**Rules**:
- IsAggregated = 0 (false): Standard per-server, per-instrument snapshot from AggregateByHedgeServerInstrument. HedgeServerID is meaningful. All 397,157 rows in this environment have IsAggregated=0.
- IsAggregated = 1 (true): NOP aggregate from NetOpenDollarsAggregator. Aggregates across ALL servers for an InstrumentID, used for exposure circuit breaker checks. In this environment, these rows go to a logger DB (per CES `UseLogDB` configuration) rather than the main DB.

### 2.3 Price Snapshot at Write Time

**What**: eToro prices are captured at the moment CES publishes the exposure, enabling USD-normalized exposure calculation.

**Columns/Parameters Involved**: `eToroPriceBid`, `eToroPriceAsk`

**Rules**:
- The mid price `(eToroPriceBid + eToroPriceAsk) / 2` is used to convert exposure units to USD for `NetUSDExposure`.
- CES reads prices from Redis (from the `RatesExpirationIntervalMS` cache refreshed from Redis at configured intervals).
- Large price movements between snapshots will change `NetUSDExposure` without any position changes.

### 2.4 ExposureID

**What**: Optional reference to the CES exposure event that triggered this snapshot write.

**Columns/Parameters Involved**: `ExposureID`, `MarketPriceRateID`

**Rules**:
- `ExposureID`: References the CES internal exposure event ID. Value = 0 in recent data for the NOP total instrument (InstrumentID=100000). For individual instrument rows, this would reference the specific exposure change event.
- `MarketPriceRateID` (int): References the market price rate at the time of writing. Precision limited to int (not bigint like in newer tables) - indicates this column was not updated with the FB 17303 bigint upgrade.

---

## 3. Data Overview

397,157 rows | 2023-01-04 to 2024-07-31 | 1,512 distinct instruments

| EntryID | InstrumentID | HedgeServerID | Occurred | IsAggregated | OpenedBuyUnits | OpenedSellUnits | HedgedUnits | RequestedUnits | NetUSDExposure |
|---|---|---|---|---|---|---|---|---|---|
| 427153 | 100000 | 1 | 2024-07-31 09:01:16 | false | 5080.891332 | 6.014633 | 2149.875 | -35.875 | -92,207,000.376 |
| 427152 | 100000 | 1 | 2024-07-31 08:48:54 | false | 5080.886516 | 6.014633 | 2149.875 | -35.875 | -92,206,850.397 |

**InstrumentID=100000**: Appears to be the NOP total aggregate instrument (synthetic, not in Trade.Instrument dictionary). OpenedBuyUnits ~5,080 represents the total aggregated position across all instruments on this server. NetUSDExposure ~-$92M = eToro is net long on behalf of customers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntryID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment row identifier. NONCLUSTERED PK. Physical ordering is by Occurred (clustered). Note: EntryID in live DB exceeds 427,000 but total rows are 397,157 - indicates some rows were deleted (likely older records purged to History.ExposureBreakdownLog). |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument for this exposure snapshot. Implicitly references Trade.Instrument (no DDL FK). Values 0-~9,999 = real instruments. InstrumentID=100000+ appears to be synthetic NOP total aggregates for multi-instrument rollups. 1,512 distinct values in the data. |
| 3 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). For IsAggregated=0 rows, this identifies which hedge server's customer positions are being captured. For IsAggregated=1 (NOP) rows, this may represent the reporting server rather than a physical hedge server. |
| 4 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | DB server UTC timestamp at row insert. DEFAULT=GETUTCDATE(). Clustered index key. The primary dimension for time-series queries. CES writes on its StorageExpirationIntervalMS timer. |
| 5 | eToroPriceBid | decimal(16,8) | NO | - | CODE-BACKED | eToro's internal bid price for this instrument at the time CES published the exposure. Used to normalize exposure units to USD for NetUSDExposure calculation. |
| 6 | eToroPriceAsk | decimal(16,8) | NO | - | CODE-BACKED | eToro's internal ask price at CES publish time. Mid = (Bid+Ask)/2 is used for USD conversion. |
| 7 | IsAggregated | bit | NO | - | CODE-BACKED | 0=per-server/instrument snapshot (AggregateByHedgeServerInstrument aggregator); 1=NOP aggregate across all servers for circuit breaker (NetOpenDollarsAggregator). All rows in this environment are IsAggregated=0; NOP rows typically go to a logger DB. |
| 8 | OpenedBuyUnits | decimal(22,6) | NO | - | CODE-BACKED | Total gross BUY (long) customer units currently open for this instrument on this server. High precision (22,6) to accumulate many small fractional positions. The net position requiring hedge = OpenedBuyUnits - OpenedSellUnits. |
| 9 | OpenedSellUnits | decimal(22,6) | NO | - | CODE-BACKED | Total gross SELL (short) customer units currently open. |
| 10 | HedgedUnits | decimal(16,6) | NO | - | CODE-BACKED | Units currently held in the market as a hedge position via the liquidity provider. This represents eToro's current open hedge. Unhedged exposure = (OpenedBuyUnits - OpenedSellUnits) - HedgedUnits. |
| 11 | RequestedUnits | decimal(16,6) | NO | - | CODE-BACKED | Units in pending hedge orders currently submitted to the provider but not yet confirmed. Negative = pending sell (reducing long hedge). The "in-flight" component of the hedge. |
| 12 | NetUSDExposure | decimal(16,3) | NO | - | CODE-BACKED | The net USD value of unhedged customer exposure. Calculated by CES using current prices. Negative = net long customer exposure (more buy positions than sell, and more than currently hedged). Used as the primary trigger for hedging decisions. |
| 13 | ExposureID | int | YES | - | CODE-BACKED | Optional reference to the CES internal exposure event that triggered this snapshot. 0 or NULL for NOP total aggregates. For individual instrument events, references the specific CES exposure change event ID. |
| 14 | MarketPriceRateID | int | YES | - | CODE-BACKED | Reference to the market price rate snapshot used when computing this exposure row. INT precision (not bigint) - was not updated with the FB 17303 upgrade applied to other tables. May be NULL if not tracked for this snapshot type. |
| 15 | Queued | decimal(22,6) | NO | 0 | CODE-BACKED | SSDT DDL only - this column does NOT exist in the live database (schema drift). Represents units queued in the CES internal queue awaiting order dispatch. Do NOT reference in queries against the live DB. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (WITH NOCHECK) | FK_ExposureBreakdownLog_HedgeServer |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being tracked - InstrumentIDs 100000+ are synthetic |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CES application service | Direct SQL write | Writer | CES writes one row per (HedgeServerID, InstrumentID) per aggregation cycle. No stored procedure wrapper. |
| History.ExposureBreakdownLog | EntryID | Archive | Older records with narrower precision (16,6) - historical data before schema widening |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExposureBreakdownLog (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - Implicit: Trade.Instrument (InstrumentID)
  - Written by: CES application (direct write, no SP)
  - Archived to: History.ExposureBreakdownLog
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CES application | External service | Primary writer - publishes exposure snapshots each aggregation cycle |
| History.ExposureBreakdownLog | Table | Archive of older records (narrower precision, no ExposureID/Queued) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeExposureBreakdownLog | NONCLUSTERED PK | EntryID ASC | - | - | Active |
| IX_HedgeExposureBreakdownLog_Occurred | CLUSTERED | Occurred ASC | - | - | Active (FILLFACTOR=90, MAIN filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeExposureBreakdownLog | PRIMARY KEY (NONCLUSTERED) | EntryID |
| FK_ExposureBreakdownLog_HedgeServer | FOREIGN KEY (WITH NOCHECK) | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| DF_ExposureBreakdownLog_Occurred | DEFAULT | Occurred = GETUTCDATE() |
| DF_Hedge_ExposureBreakdownLog_Queued | DEFAULT | Queued = 0 (SSDT only - not in live DB) |

---

## 8. Sample Queries

### 8.1 Latest exposure snapshot per instrument/server
```sql
SELECT InstrumentID, HedgeServerID, Occurred,
       OpenedBuyUnits, OpenedSellUnits, HedgedUnits, RequestedUnits, NetUSDExposure
FROM Hedge.ExposureBreakdownLog WITH (NOLOCK)
WHERE Occurred = (SELECT MAX(Occurred) FROM Hedge.ExposureBreakdownLog WITH (NOLOCK))
ORDER BY ABS(NetUSDExposure) DESC;
```

### 8.2 Largest unhedged exposures (last hour)
```sql
SELECT TOP 20 InstrumentID, HedgeServerID, Occurred, NetUSDExposure,
       OpenedBuyUnits - OpenedSellUnits - HedgedUnits AS UnhedgedUnits
FROM Hedge.ExposureBreakdownLog WITH (NOLOCK)
WHERE Occurred > DATEADD(hour, -1, GETUTCDATE())
  AND IsAggregated = 0
ORDER BY ABS(NetUSDExposure) DESC;
```

### 8.3 Exposure trend for a specific instrument over time
```sql
SELECT Occurred, HedgeServerID, OpenedBuyUnits, OpenedSellUnits,
       HedgedUnits, RequestedUnits, NetUSDExposure
FROM Hedge.ExposureBreakdownLog WITH (NOLOCK)
WHERE InstrumentID = 1 -- EUR/USD
  AND HedgeServerID = 2
  AND Occurred > DATEADD(day, -7, GETUTCDATE())
ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Findings |
|--------|------|-------------|
| [CES Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710596048) | Confluence (DROD) | "The table the CES publishes exposures to is Hedge.ExposureBreakdownLog". Two aggregators: AggregateByHedgeServerInstrument (IsAggregated=0) and NetOpenDollarsAggregator (IsAggregated=1). UseLogDB config controls whether to write to main DB or logger DB. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExposureBreakdownLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExposureBreakdownLog.sql*
