# DWH_dbo.Dim_Instrument_Snapshot

> Daily point-in-time snapshot of the futures-relevant configuration columns from `Dim_Instrument` -- preserving the exact Multiplier, margins, SettlementTime, and IsFuture flag for each instrument as of each calendar date, enabling accurate historical analysis of futures instruments whose configuration changes over time.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Instrument (daily snapshot; data originates from Trade.ProviderToInstrument + Trade.FuturesMetaData) |
| **Refresh** | Daily (Append -- new date partition added each day) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, InstrumentID ASC) |
| | |
| **UC Target** | Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned) |
| **UC Format** | delta |
| **UC Partitioned By** | None (Append strategy; partitioned logically by DateID) |
| **UC Table Type** | Gold export (Generic Pipeline, Append, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Instrument_Snapshot` is a daily append table that captures the state of nine futures-relevant columns from `DWH_dbo.Dim_Instrument` as of each calendar date. Because futures instrument configuration (Multiplier, ProviderMarginPerLot, eToroMarginPerLot, SettlementTime) can be updated in production at any time, `Dim_Instrument` itself always reflects the current state only. The snapshot table bridges this gap: by recording the exact configuration values observed on each ETL run, it enables analysts to reconstruct what the futures parameters were on any historical date.

The snapshot was introduced 2024-12-22 (by Inbal BML). As of 2026-03-10, it holds 5,311,079 rows across 444 daily snapshots. Each snapshot contains one row per instrument in `Dim_Instrument` at the time of the ETL run (~15,707 rows per day, growing over time as new instruments are added).

The ETL is driven by `SP_Dim_Instrument_Snapshot`, which is called at the end of `SP_Dim_Instrument` (the master instrument ETL). It deletes the previous entry for the date and inserts fresh data from `Dim_Instrument`. The `DateID` represents "yesterday" in yyyymmdd integer format, so the daily load (running ~02:08 UTC on day T) stamps rows as day T-1 (the business date just completed).

**Primary use case**: Historical futures P&L attribution -- joining `DateID` + `InstrumentID` to get the exact Multiplier and margin parameters that were in effect on a given date.

---

## 2. Business Logic

### 2.1 DateID "Yesterday" Stamping

**What**: Each daily ETL run stamps snapshot rows with the *previous* calendar date (not the run date).

**Columns Involved**: `DateID`, `UpdateDate`

**Rules**:
- In SP_Dim_Instrument_Snapshot: `@Yesterday = CAST(@dt as DATETIME)`, and `@Yesterdayint` = yyyymmdd of @Yesterday.
- The SP is called as `EXEC SP_Dim_Instrument_Snapshot @dt` where `@dt` is the current run date. So the snapshot for "today's" instrument state is stored under DateID = yyyymmdd of yesterday.
- `UpdateDate` = GETDATE() (actual run timestamp). `UpdateDate` and `DateID` will therefore differ by ~1 day (e.g., UpdateDate 2026-03-11 02:08 for DateID 20260310).
- DELETE + INSERT pattern: the SP first deletes any existing rows for DateID in `[@Yesterdayint, @CurrentDateint)`, then inserts fresh rows. This is an idempotent daily overwrite of the previous day's snapshot, not a true historical accumulation per run.

**Implication**: For most purposes, every DateID represents one unique daily snapshot. If the SP runs multiple times on day T, only the last run's data survives for DateID T-1.

### 2.2 SettlementTime DATETIME Conversion

**What**: The `SettlementTime` stored in Dim_Instrument is a `time(7)` value (e.g., 22:00:00). The snapshot stores it as `datetime2(7)` by combining the snapshot date with the time component.

**Column Involved**: `SettlementTime`

**SP Logic**: `CONVERT(DATETIME, CONVERT(CHAR(8), @dt, 112) + ' ' + CONVERT(CHAR(8), SettlementTime, 108))`

**Result**: A full DATETIME value where the date portion = @dt and the time portion = the instrument's settlement time. Example: `2026-03-10 22:00:00` = "on 2026-03-10, settlement was at 22:00 UTC". This makes settlement time easy to compare against position timestamps.

### 2.3 Snapshot Scope -- Futures Config Columns Only

**What**: The snapshot captures only the 7 futures-relevant columns, not all 47 Dim_Instrument columns. Non-futures instruments are included (IsFuture=0) but their Multiplier/ProviderMarginPerLot/eToroMarginPerLot are NULL.

**Distribution on 2026-03-10**:
- IsFuture=1: 243 instruments (1.6%) -- these are the meaningful rows for futures analysis
- IsFuture=0: 15,463 instruments (98.4%) -- present but futures columns are NULL
- IsFuture=NULL: 1 (ID=0 placeholder)

**Implication**: When querying for futures-specific analysis, always filter `WHERE IsFuture = 1` to exclude the ~98% of non-futures rows.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed. Unlike most dimension tables, this one is too large (5.3M rows and growing) for REPLICATE. The CLUSTERED INDEX on `(DateID, InstrumentID)` makes date+instrument lookups highly efficient and supports range scans by date.

**ROUND_ROBIN note**: JOINs to other tables (e.g., `Dim_Instrument`) may incur data movement. For large-scale historical analysis, consider filtering on DateID first to minimize shuffle.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get futures config for a specific date | `WHERE DateID = 20260310 AND IsFuture = 1` |
| Get Multiplier history for one instrument | `WHERE InstrumentID = 998 ORDER BY DateID` |
| Join to fact for historical margin attribution | `JOIN Dim_Instrument_Snapshot ON DateID + InstrumentID WHERE IsFuture = 1` |
| Check when SettlementTime changed | `SELECT DateID, SettlementTime FROM ... WHERE InstrumentID = X ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON InstrumentID` | Get full instrument details (Name, InstrumentType, etc.) for the snapshot row |
| DWH_dbo.Dim_Date | `ON DateID` | Get calendar metadata for the snapshot date |
| DWH_dbo fact tables | `ON DateID + InstrumentID` | Historical futures config attribution in P&L / position calculations |

### 3.4 Gotchas

- **DateID = yesterday, not today**: Rows loaded by the 02:08 UTC run on 2026-03-11 carry DateID=20260310. Don't expect DateID=20260311 until the next day's run.
- **Non-futures rows inflate counts**: 98.4% of rows per snapshot have IsFuture=0. Always filter `WHERE IsFuture = 1` for futures analysis.
- **SettlementTime is DATETIME, not TIME**: The date portion is the snapshot date; only the time portion (e.g., 22:00:00) is meaningful as a time-of-day value.
- **ProviderMarginPerLot is often NULL**: Even for futures instruments, ProviderMarginPerLot may be NULL if the instrument lacks a FuturesInstrumentsInitialMarginByProviderMapping entry.
- **No historical backfill before 2024-12-22**: DateID < 20241222 does not exist. For historical analysis before this date, futures config must be inferred from other sources.
- **Growth rate**: ~15,700 new rows per day. At 5.3M rows and growing ~5.7M rows/year, expect this table to reach 10M+ rows by end of 2026.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dim_Instrument_Snapshot)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NO | Snapshot date in yyyymmdd integer format -- represents "yesterday" relative to the ETL run date. The daily snapshot for business date 20260310 is loaded by the ETL run on 2026-03-11. FK to DWH_dbo.Dim_Date (DateID). Part of the natural composite key (DateID + InstrumentID). (Tier 2 -- SP_Dim_Instrument_Snapshot) |
| 2 | InstrumentID | int | NO | Instrument identifier -- FK to DWH_dbo.Dim_Instrument(InstrumentID). Includes all instruments present in Dim_Instrument on the load date, including non-futures (IsFuture=0). Range: 0 (placeholder) to ~21M allocated IDs. (Tier 2 -- SP_Dim_Instrument_Snapshot) |
| 3 | Multiplier | decimal(38,18) | YES | Futures contract size multiplier from Dim_Instrument.Multiplier. Determines how many units of the underlying asset one contract represents. NULL for non-futures instruments (IsFuture=0). Example values: 2.0 (InstrumentID=998), 100.0 (InstrumentID=999), 5.0 (InstrumentID=200000+). (Tier 3 -- live data) |
| 4 | ProviderID | int | YES | Liquidity provider ID from Dim_Instrument.ProviderID. Identifies which external market maker prices this instrument. NULL for ID=0 placeholder only. Most instruments have ProviderID=1. (Tier 3 -- live data) |
| 5 | ProviderMarginPerLot | decimal(38,18) | YES | Provider's initial margin requirement per lot from Dim_Instrument.ProviderMarginPerLot. NULL for non-futures instruments and for futures instruments without a FuturesInstrumentsInitialMarginByProviderMapping entry. Example range: 1,711 to 2,354 (in instrument currency units). (Tier 3 -- live data) |
| 6 | eToroMarginPerLot | decimal(38,18) | YES | eToro's internal margin per lot in asset currency from Dim_Instrument.eToroMarginPerLot. NULL for non-futures instruments. May differ from ProviderMarginPerLot due to eToro's own risk parameters. Example range: 1,993 to 3,130. (Tier 3 -- live data) |
| 7 | SettlementTime | datetime2(7) | YES | Settlement datetime combining the snapshot date with the instrument's TIME-valued settlement time from Dim_Instrument. Computed in SP: `CONVERT(DATETIME, yyyymmdd_string + ' ' + HH:MM:SS_string)`. The date portion = @dt (snapshot date); the time portion = actual settlement time. Example: 2026-03-10 22:00:00 means settlement was at 22:00 UTC on the snapshot date. NULL for non-futures instruments. (Tier 2 -- SP_Dim_Instrument_Snapshot) |
| 8 | IsFuture | int | YES | Flag indicating if the instrument is a futures contract: 1=futures (243 instruments as of 2026-03-10), 0=non-futures (15,463), NULL=placeholder (ID=0). Copied from Dim_Instrument.IsFuture. Meaningful futures analysis requires filtering WHERE IsFuture = 1. (Tier 3 -- live data) |
| 9 | UpdateDate | datetime2(7) | NO | ETL run timestamp -- GETDATE() at load time. Differs from DateID by ~1 day (e.g., UpdateDate 2026-03-11 02:08 for DateID 20260310). Use DateID for business date identification; UpdateDate reflects the actual load time. (Tier 2 -- SP_Dim_Instrument_Snapshot) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateID | SP_Dim_Instrument_Snapshot | @dt parameter | ETL-computed: @Yesterdayint = yyyymmdd(@dt - 1) |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough |
| Multiplier | DWH_dbo.Dim_Instrument | Multiplier | passthrough |
| ProviderID | DWH_dbo.Dim_Instrument | ProviderID | passthrough |
| ProviderMarginPerLot | DWH_dbo.Dim_Instrument | ProviderMarginPerLot | passthrough |
| eToroMarginPerLot | DWH_dbo.Dim_Instrument | eToroMarginPerLot | passthrough |
| SettlementTime | DWH_dbo.Dim_Instrument | SettlementTime (time(7)) | cast: CONVERT(DATETIME, date_string + time_string) |
| IsFuture | DWH_dbo.Dim_Instrument | IsFuture | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

Upstream production sources (via Dim_Instrument): `etoro.Trade.ProviderToInstrument` (SettlementTime, margins, ProviderID), `etoro.Trade.FuturesMetaData` (Multiplier), `etoro.Trade.InstrumentGroups` (IsFuture flag).

### 5.2 ETL Pipeline

```
etoro.Trade.ProviderToInstrument + Trade.FuturesMetaData (etoroDB-REAL)
  -> SP_Dim_Instrument (daily, full reload)
  -> DWH_dbo.Dim_Instrument (current state)
  -> SP_Dim_Instrument_Snapshot @dt (called at end of SP_Dim_Instrument)
     DELETE DateID=@Yesterdayint, then INSERT from Dim_Instrument
  -> DWH_dbo.Dim_Instrument_Snapshot (5,311,079 rows, 444 daily snapshots)
  -> Generic Pipeline (Append, 1440min)
  -> Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/
     (UC: uc_table not assigned)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Instrument | Parent table; current state of all instruments |
| ETL | SP_Dim_Instrument_Snapshot | DELETE @Yesterday + INSERT from Dim_Instrument with date-combined SettlementTime |
| Target | DWH_dbo.Dim_Instrument_Snapshot | 5.3M rows, grows ~15.7K rows/day |
| Export | Generic Pipeline (Append) | Appends new Gold delta partition daily |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Parent instrument dimension -- all columns sourced from here |
| DateID | DWH_dbo.Dim_Date | Snapshot date reference |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Dim_Instrument | (calls) | Parent SP calls EXEC SP_Dim_Instrument_Snapshot @dt at end of daily reload |
| Historical P&L SPs | DateID + InstrumentID | Expected consumers for point-in-time futures config lookup (see Query Advisory) |

---

## 7. Sample Queries

### 7.1 Get current futures configuration for all futures instruments

```sql
SELECT
    s.DateID,
    i.Name,
    i.Symbol,
    s.Multiplier,
    s.ProviderMarginPerLot,
    s.eToroMarginPerLot,
    s.SettlementTime,
    s.ProviderID
FROM [DWH_dbo].[Dim_Instrument_Snapshot] s
JOIN [DWH_dbo].[Dim_Instrument] i ON s.InstrumentID = i.InstrumentID
WHERE s.DateID = 20260310
  AND s.IsFuture = 1
ORDER BY s.InstrumentID;
```

### 7.2 Track Multiplier history for a specific futures instrument

```sql
SELECT
    s.DateID,
    s.Multiplier,
    s.ProviderMarginPerLot,
    s.eToroMarginPerLot,
    s.SettlementTime,
    s.UpdateDate
FROM [DWH_dbo].[Dim_Instrument_Snapshot] s
WHERE s.InstrumentID = 998   -- example futures instrument
ORDER BY s.DateID;
```

### 7.3 Detect instruments that changed Multiplier between two dates

```sql
SELECT
    a.InstrumentID,
    i.Name,
    a.Multiplier AS Multiplier_Before,
    b.Multiplier AS Multiplier_After
FROM [DWH_dbo].[Dim_Instrument_Snapshot] a
JOIN [DWH_dbo].[Dim_Instrument_Snapshot] b
    ON a.InstrumentID = b.InstrumentID
   AND b.DateID = 20260310
JOIN [DWH_dbo].[Dim_Instrument] i ON a.InstrumentID = i.InstrumentID
WHERE a.DateID = 20260101
  AND a.IsFuture = 1
  AND b.IsFuture = 1
  AND a.Multiplier <> b.Multiplier;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.6/10 (★★★★☆) | Phases: 8/14*
*Tiers: 0 T1, 4 T2, 5 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Instrument_Snapshot | Type: Table | Production Source: DWH_dbo.Dim_Instrument (snapshot child)*
