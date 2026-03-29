# BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data

> Daily data-prep table for futures finance — reconstructs position change ledger entries within settlement windows, categorizing each event (Open, Hold, Close, PartialClose, EditSL, ChildClose) to feed the downstream Marex & custodian money transfer calculation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (ETL intermediate / prep) |
| **Production Source** | DWH-computed from Dim_PositionChangeLog, Fact_Position_Futures_Snapshot, Dim_Instrument_Snapshot, Dim_Position |
| **Refresh** | Daily — DELETE for @dateID + INSERT (SP_Futures_Finance_Prep_Data @date) |
| | |
| **Synapse Distribution** | HASH(PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_Futures_Finance_Prep_Data` is a daily intermediate data preparation table that reconstructs the position change ledger for **futures positions only**, filtered to events within the instrument's settlement time window. It is the first stage of a two-step pipeline:

1. **This table** (prep): Builds a complete daily picture — "opening balance" rows (yesterday's end-state for held-over positions) + today's intraday change events — and categorizes each event into an `ActionType` (Open, Hold, CloseOrig, PartialCloseOrig, EditSLIncreaseAmount, EditSLReduceAmount, ChildClose).

2. **SP_Finance_Real_Futures_Custody_And_Transfers** (consumer): Reads this prep data to compute the final Marex & custodian money transfers by building parent/child position chains and calculating margin movements.

### Why This Exists

The raw position changelog (`Dim_PositionChangeLog`) records all position events across all instruments. Futures require a settlement-window-specific view: only events between the previous and current settlement times matter. This table:
- Filters the changelog to futures positions only (via `Fact_Position_Futures_Snapshot`)
- Clips events to the settlement window (between `SettlementTimePrev` and `SettlementTime`)
- Produces "Hold" rows for positions carried over from the previous day with zero-delta amounts
- Null-fills `LotCountDecimal` / `PreviousLotCountDecimal` from historical changelog entries where the original event didn't record lot counts

Created: 2025-01-26 by Guy Manova. Author comment: *"daily data prep needed for the final Marex & custodian money transfers daily, which requires some running totals logics"*.

---

## 2. Business Logic

### 2.1 ActionType Classification

**What**: Categorizes each position change event into a finance-relevant action type.

**Columns Involved**: `ActionType`, `ChangeTypeID`

**Rules**:
- **Open**: `ChangeTypeID = 0` (initial open event) — OR — `OpenOccurred` falls between `SettlementTimePrev` and `SettlementTime` (for held-over rows)
- **Hold**: Position had its last event before yesterday — carried over with zero delta (`AmountChanged = 0`, `PreviousAmount = NewAmount`, `ChangeTypeID = 99`)
- **CloseOrig**: `ChangeTypeID = 6` — original position fully closed
- **PartialCloseOrig**: `ChangeTypeID = 12` — partial close on original position
- **EditSLIncreaseAmount**: `ChangeTypeID = 1` AND `PreviousAmount <= NewAmount` — SL edit that increased amount
- **EditSLReduceAmount**: `ChangeTypeID = 1` AND `PreviousAmount > NewAmount` — SL edit that reduced amount
- **ChildClose**: `ChangeTypeID = 11` — child position closed (from partial close)

### 2.2 Settlement Window Filtering

**What**: Only changelog events within the instrument's settlement window are included.

**Rules**:
- Current-day events: `OccurredDateID IN (@dateID, @datePrevID) AND Occurred BETWEEN SettlementTimePrev AND SettlementTime`
- Previous-day holdover events: `OccurredDateID < @dateID AND Occurred < SettlementTimePrev` — last event per `OriginalPositionID` (ROW_NUMBER = 1 by Occurred DESC)
- Only `ChangeTypeID IN (0, 1, 6, 11, 12)` are included; other change types are excluded

### 2.3 LotCount Null-Fill

**What**: Forward-fills NULL `LotCountDecimal` values from earlier changelog entries.

**Rules**:
- Uses `CROSS APPLY` to find the nearest prior non-NULL `LotCountDecimal` for the same `PositionID`
- Sets `PreviousLotCountDecimal = 0` for open events (`ChangeTypeID = 0`)
- Remaining NULLs are filled via `LAG(LotCountDecimal)` over the same `PositionID`

### 2.4 Hold Row Adjustments

**What**: Positions held over from yesterday are normalized to show zero movement.

**Rules**:
- `AmountChanged = 0` (no intraday change)
- `PreviousAmount = NewAmount` (no amount delta)
- `ChangeTypeID = 99` (synthetic marker — not a real ChangeTypeID from the source)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH(PositionID)**: Co-located with Dim_PositionChangeLog and Dim_Position for efficient JOINs. Always filter on DateID for date-specific queries.

**CLUSTERED COLUMNSTORE INDEX**: Good for analytical scans over date ranges.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Full position details, IsSettled fallback |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Instrument name, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer details |

### 3.3 Gotchas

- **ChangeTypeID = 99 is synthetic**: Not a real changelog change type — it marks "Hold" rows inserted by this SP. Do not attempt to join this value to any ChangeType dimension.
- **Multiple rows per PositionID per DateID**: A position can have a Hold row + multiple intraday events. Do not assume one row per position per day.
- **RN is NULL for current-day rows**: Only holdover rows from `#ledgerPrev` have a non-NULL RN (always = 1, since it's the last event per OriginalPositionID).
- **LotCountDecimal may still be NULL**: The null-fill logic only fills from prior events. If no prior event had a non-NULL lot count, it remains NULL.
- **Daily DELETE+INSERT**: The table is rebuilt daily for each `@dateID`. Historical data is preserved — this is not a full truncate.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_Futures_Finance_Prep_Data) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Settlement date as YYYYMMDD integer, computed from SP input parameter @date. (Tier 2 — SP_Futures_Finance_Prep_Data) |
| 2 | PositionID | bigint | NULL | Position identifier. Distribution key. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 3 | CID | int | NULL | Customer ID who owns the position. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 4 | Occurred | datetime | NULL | Exact timestamp when the position change occurred. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 5 | OccurredDateID | int | NULL | YYYYMMDD int of the Occurred timestamp. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 6 | ChangeTypeID | int | NULL | Type of position change event. Original values: 0=Open, 1=Rate/SL change, 6=Close, 11=ChildClose, 12=PartialClose. Value **99** is synthetic — injected by SP for Hold rows. (Tier 2 — SP_Futures_Finance_Prep_Data, SP-adjusted) |
| 7 | PreviousAmount | decimal(18,6) | NULL | Position amount before this change. For Hold rows, set equal to NewAmount (zero delta). (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse, SP-adjusted) |
| 8 | AmountChanged | decimal(18,6) | NULL | Change in amount. For Hold rows, set to 0. Otherwise = NewAmount − PreviousAmount. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse, SP-adjusted) |
| 9 | NewAmount | decimal(18,6) | NULL | Position amount after this change. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 10 | PreviousIsSettled | int | NULL | Before the change: 1 = real asset, 0 = CFD asset. NULL if the event did not involve settlement. From Dim_PositionChangeLog. (Tier 5 — Expert Review) |
| 11 | IsSettled | int | NULL | After the change: 1 = real asset, 0 = CFD asset. COALESCE(changelog, Dim_Position.IsSettled). (Tier 5 — Expert Review) |
| 12 | PreviousStopRate | decimal(18,6) | NULL | Stop-loss rate before this change. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 13 | StopRate | decimal(18,6) | NULL | Stop-loss rate after this change. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 14 | PreviousAmountInUnits | decimal(18,6) | NULL | Unit count (lots/shares) before this change. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 15 | AmountInUnits | decimal(18,6) | NULL | Unit count after this change. Passthrough from Dim_PositionChangeLog. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 16 | LotCountDecimal | decimal(18,6) | NULL | Lot count after change. Null-filled from historical changelog events via CROSS APPLY forward-fill. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse, SP-adjusted) |
| 17 | PreviousLotCountDecimal | decimal(18,6) | NULL | Lot count before change. Set to 0 for open events (ChangeTypeID=0); otherwise null-filled via LAG. (Tier 2 — SP_Dim_PositionChangeLog_DL_To_Synapse, SP-adjusted) |
| 18 | InstrumentID | int | NULL | Futures instrument traded. From Fact_Position_Futures_Snapshot (DISTINCT for @date). Only IsFuture=1 instruments. (Tier 2 — Dim_Instrument_Snapshot) |
| 19 | OriginalPositionID | bigint | NULL | Parent position ID for partial-close child positions. Equals PositionID for non-partial positions. From Fact_Position_Futures_Snapshot. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 20 | SettlementTime | datetime | NULL | Current settlement time for the futures instrument on @date. From Dim_Instrument_Snapshot. (Tier 2 — Dim_Instrument_Snapshot) |
| 21 | SettlementTimePrev | datetime | NULL | Previous settlement time for the instrument. Computed as LAG(SettlementTime) OVER (PARTITION BY InstrumentID ORDER BY SettlementTime). (Tier 2 — SP_Futures_Finance_Prep_Data) |
| 22 | IsBuy | int | NULL | Direction: 1 = long (buy), 0 = short (sell). From Fact_Position_Futures_Snapshot. (Tier 2 — Dim_Position) |
| 23 | InitForexRate | decimal(18,6) | NULL | Opening price / forex rate at position open. From Fact_Position_Futures_Snapshot. (Tier 2 — Dim_Position) |
| 24 | EndForexRate | decimal(18,6) | NULL | Closing price / forex rate. MAX(EndForexRate) grouped per position in Fact_Position_Futures_Snapshot. (Tier 2 — SP_Futures_Finance_Prep_Data) |
| 25 | RN | int | NULL | Row sequence number. 1 for holdover rows (last event per OriginalPositionID before @dateID). NULL for current-day event rows. (Tier 2 — SP_Futures_Finance_Prep_Data) |
| 26 | ActionType | varchar(100) | NULL | Finance-relevant event classification: Open, Hold, CloseOrig, PartialCloseOrig, EditSLIncreaseAmount, EditSLReduceAmount, ChildClose. Derived from ChangeTypeID + settlement timing logic. (Tier 2 — SP_Futures_Finance_Prep_Data) |
| 27 | UpdateDate | datetime | NOT NULL | ETL load timestamp — GETDATE(). (Tier 2 — SP_Futures_Finance_Prep_Data) |

---

## 5. Lineage

### 5.1 Pipeline

```
DWH_dbo.Dim_PositionChangeLog + DWH_dbo.Fact_Position_Futures_Snapshot
+ DWH_dbo.Dim_Instrument_Snapshot + DWH_dbo.Dim_Position
    │
    └─ SP_Futures_Finance_Prep_Data(@date)
        ├─ #prevPerLotPrep (instrument settlement times + margin per lot with LAG)
        ├─ #prevPricePrep (latest settlement price per instrument)
        ├─ #uniquesFromFuturesTable (distinct futures positions for @date)
        ├─ #fullLedger (changelog entries filtered to settlement window)
        ├─ #ledgerPrev (yesterday's end-state per OriginalPositionID)
        ├─ #ledgerCurrent (today's events within settlement window)
        ├─ #final (UNION ALL ledgerPrev + ledgerCurrent)
        ├─ UPDATE: null-fill lots from #ledgerHistory
        ├─ UPDATE: zero-out Hold rows
        ├─ DELETE WHERE DateID = @dateID
        └─ INSERT INTO BI_DB_Futures_Finance_Prep_Data
```

### 5.2 Key Source Tables

| Source | Columns Used |
|--------|-------------|
| DWH_dbo.Dim_PositionChangeLog | PositionID, CID, Occurred, OccurredDateID, ChangeTypeID, PreviousAmount, AmountChanged, NewAmount, PreviousIsSettled, IsSettled, PreviousStopRate, StopRate, PreviousAmountInUnits, AmountInUnits, LotCountDecimal, PreviousLotCountDecimal |
| DWH_dbo.Fact_Position_Futures_Snapshot | PositionID, OriginalPositionID, InstrumentID, OpenOccurred, IsBuy, InitForexRate, EndForexRate |
| DWH_dbo.Dim_Instrument_Snapshot | InstrumentID, SettlementTime, Multiplier, ProviderMarginPerLot, eToroMarginPerLot, IsFuture |
| DWH_dbo.Dim_Position | PositionID, IsSettled (COALESCE fallback) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Position | PositionID | Position master details |
| DWH_dbo.Dim_Customer | CID | Customer who owns the position |
| DWH_dbo.Dim_Instrument | InstrumentID | Futures instrument |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_Finance_Real_Futures_Custody_And_Transfers | PositionID, DateID | Reads prep data to build parent/child position chains for Marex & custodian transfers |

---

## 7. Sample Queries

### 7.1 Daily position events for a specific date

```sql
SELECT  PositionID, OriginalPositionID, ActionType, ChangeTypeID,
        PreviousAmount, AmountChanged, NewAmount,
        LotCountDecimal, Occurred
FROM    [BI_DB_dbo].[BI_DB_Futures_Finance_Prep_Data]
WHERE   DateID = 20260320
ORDER BY OriginalPositionID, Occurred;
```

### 7.2 Hold positions vs intraday events

```sql
SELECT  ActionType,
        COUNT(*) AS EventCount,
        COUNT(DISTINCT OriginalPositionID) AS UniquePositions
FROM    [BI_DB_dbo].[BI_DB_Futures_Finance_Prep_Data]
WHERE   DateID = 20260320
GROUP BY ActionType
ORDER BY EventCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Futures trading](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12961316878) | Confluence | General futures trading concepts — contract types, closing positions |
| [Exchange Traded Futures Expiration](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/13044056149) | Confluence | Settlement procedures for cash/physical settled futures — references FuturesMetaData |

---

*Generated: 2026-03-22 | Quality: 8.5/10 (★★★★☆) | Phases: 12/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data | Type: Table | Source: DWH-computed (Dim_PositionChangeLog + Fact_Position_Futures_Snapshot)*
