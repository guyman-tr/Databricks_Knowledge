# History.PositionChangeLogFull

> Unified position event stream merging structured position change log entries (History.PositionChangeLog) with free-text data fix audit records (History.PositionDataFixLog) - exposes 32 core PCL columns plus 4 free-text audit fields, with each source populating only its relevant columns and NULLing the rest.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionChangeID (bigint; -1 for DataFix rows) |
| **Partition** | N/A (view - inherits from PositionChangeLog's archive/active sources) |
| **Indexes** | N/A (view - base source indexes used) |

---

## 1. Business Meaning

`History.PositionChangeLogFull` creates a single unified event stream for all position state changes and manual corrections by merging two distinct audit systems:

1. **History.PositionChangeLog** - the structured change audit log recording every lifecycle event for a trading position (open, edit SL/TP, EOW fee, close, detach, etc.), with typed before/after values for amounts, rates, fees, and flags.
2. **History.PositionDataFixLog** - the ad-hoc data fix audit log recording manual corrections applied outside the normal lifecycle, with free-text column-name/old-value/new-value fields.

The view uses a UNION ALL: PositionChangeLog rows expose their 32 typed change columns and receive NULLs for the 4 free-text audit fields; PositionDataFixLog rows expose their 4 free-text audit columns and receive NULLs (or sentinel -1) for the typed change columns. A consumer reading this view sees ALL position events - whether they came through the normal trading flow or through a manual data fix operation - in a single query ordered by PositionID and Occurred.

Note: This view selects only 32 of the 57 columns from History.PositionChangeLog (the original core columns, predating UM-25.2 additions). Consumers needing the full 57-column set (including IsNoStopLoss, IsNoTakeProfit, LotCountDecimal variants) should query History.PositionChangeLog directly.

---

## 2. Business Logic

### 2.1 Two-Branch UNION ALL Architecture

**What**: Two sources with complementary column sets are merged into a single 36-column output.

**Columns/Parameters Involved**: `PositionChangeID`, `ColumnName`, `OldValue`, `NewValue`, `ChangeDescription`

**Rules**:
- **Branch 1 (History.PositionChangeLog)**: Columns 1-32 are native typed values; columns 33-36 (ColumnName, OldValue, NewValue, ChangeDescription) are `CAST(NULL AS VARCHAR(255))`
- **Branch 2 (History.PositionDataFixLog)**: `PositionChangeID = -1` (sentinel, not a real PCL ID); most typed columns are NULL; ColumnName, OldValue, NewValue, ChangeDescription are native from the fix log; `ChangeTypeID = ISNULL(ChangeTypeID, 14)` - defaults to 14 (Data Fix) when NULL
- `PositionChangeID = -1` is the identifying marker for data fix rows; all real PCL rows have PositionChangeID > 0

**Diagram**:
```
History.PositionChangeLog
  (32 typed columns: amounts, rates, fees, flags, timestamps)
  + ColumnName=NULL, OldValue=NULL, NewValue=NULL, ChangeDescription=NULL
                 |
        UNION ALL|
                 |
History.PositionDataFixLog
  PositionChangeID=-1, most typed cols=NULL
  + ColumnName, OldValue, NewValue, ChangeDescription (native)
  + ChangeTypeID=ISNULL(ChangeTypeID,14)  -- defaults to Data Fix
                 |
                 v
     History.PositionChangeLogFull (36 columns)
     - Structured events: PositionChangeID > 0
     - Data fix events:   PositionChangeID = -1
```

### 2.2 ChangeTypeID Classification

**What**: ChangeTypeID identifies the type of position lifecycle event for both sources.

**Columns/Parameters Involved**: `ChangeTypeID`

**Rules** (Dictionary.PCL_ChangeType):
- 0 = Open Position - new position created
- 1 = Edit Stop Loss - SL rate or amount changed
- 2 = Edit Take Profit - TP rate or amount changed
- 3 = Edit Over Weekend - weekend flag changed
- 4 = EOW Fee (End Of Week Fee) - weekly financing fee applied
- 5 = Detach from Mirror - position unlinked from copy-trade portfolio
- 6 = Close Position - position closed
- 7 = Enable/Disable TSL - trailing stop-loss toggled
- 8 = PositionRedeemCancel - redemption cancelled
- 9 = PositionRedeemPending - redemption pending state
- 10 = PositionRedeemClose - position closed via redemption
- 11 = Partial close - partial position close
- 12 = Edit due to partial close - parent position adjusted after partial close
- 13 = Edit Is Settled - settlement status changed
- 14 = Data Fix - manual correction (all DataFix branch rows)

### 2.3 Partial PCL Column Coverage

**What**: The view exposes 32 of the 57 History.PositionChangeLog columns, covering the original schema only.

**Columns/Parameters Involved**: All 32 PCL-sourced columns in this view

**Rules**:
- Exposes: PositionChangeID through UnitsBaseValueCents (32 columns - the pre-UM-25.2 set)
- Does NOT expose: SnapshotTimestamp, PriceType, PreviousIsNoTakeProfit, PreviousIsNoStopLoss, IsNoStopLoss, IsNoTakeProfit, PreviousLotCountDecimal, LotCountDecimal, ClientVersion, and other extended columns added after this view was created
- This was the complete PCL schema when PositionChangeLogFull was created; newer PCL columns are only in History.PositionChangeLog

---

## 3. Data Overview

| PositionChangeID | PositionID | ChangeTypeID | CID | Occurred | ColumnName | OldValue | Meaning |
|-----------------|------------|-------------|-----|----------|-----------|---------|---------|
| 3713814537 | 2152976745 | 0 (Open) | 25158719 | 2026-03-21 11:50 | NULL | NULL | A position open event (type 0) - the structured PCL branch. ColumnName/OldValue are NULL for all PCL rows. PreviousAmount=20.19. |
| 3713814535 | 2152976743 | 6 (Close) | 14952810 | 2026-03-21 11:11 | NULL | NULL | A position close event (type 6) - structured PCL row capturing the position state at close time. |
| -1 | (any) | 14 (Data Fix) | NULL | (fix time) | OpenRate | 1.08543 | A data fix row from PositionDataFixLog - PositionChangeID=-1 sentinel identifies it. ColumnName shows which field was fixed; OldValue/NewValue show the correction. (No data fix records currently exist in this environment.) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionChangeID | bigint | YES | - | CODE-BACKED | Unique ID of the position change log entry (Branch 1). -1 (sentinel) for data fix rows (Branch 2). All real PCL entries have PositionChangeID > 0, allowing consumers to distinguish the two sources. |
| 2 | PositionID | bigint | YES | - | CODE-BACKED | The trading position this event relates to. Present in both branches. The common join key when querying all events for a specific position. |
| 3 | PreviousEndOfWeekFee | money | YES | - | CODE-BACKED | EOW fee amount before this change. From PositionChangeLog. NULL for DataFix rows and for change types that do not affect the EOW fee. |
| 4 | EndOfWeekFee | money | YES | - | CODE-BACKED | EOW fee amount after this change. From PositionChangeLog. Populated primarily for ChangeTypeID=4 (EOW Fee) events. |
| 5 | PreviousAmount | money | YES | - | CODE-BACKED | Position invested amount before this event. From PositionChangeLog. Live data: 20.19 and 99.97 seen for Open (type 0) events. NULL for DataFix rows. |
| 6 | AmountChanged | money | YES | - | CODE-BACKED | Delta of the position amount caused by this event. From PositionChangeLog. 0 for open events (amount set, not changed); non-zero for partial close or adjustment events. |
| 7 | PreviousLimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate before this change. From PositionChangeLog. NULL for changes not affecting TP rate. |
| 8 | LimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate after this change. From PositionChangeLog. Populated for ChangeTypeID=2 (Edit Take Profit). |
| 9 | PreviousStopRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate before this change. From PositionChangeLog. NULL for changes not affecting SL rate. |
| 10 | StopRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate after this change. From PositionChangeLog. Populated for ChangeTypeID=1 (Edit Stop Loss). |
| 11 | Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp of the event. Present in both branches (from PositionChangeLog.Occurred and PositionDataFixLog.Occurred). Primary ordering column for chronological event replay. |
| 12 | ParentPositionID | bigint | YES | - | CODE-BACKED | For copy-trading: the parent (leader) position this copier position follows. From PositionChangeLog. NULL for DataFix rows and non-copy positions. |
| 13 | LastOpPriceRate | dbo.dtPrice | YES | - | CODE-BACKED | Market mid-price at the time of this change. From PositionChangeLog. Enables reconstruction of market conditions at each lifecycle event. |
| 14 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Price record ID corresponding to LastOpPriceRate. From PositionChangeLog. Enables exact price trace. NULL for DataFix rows. |
| 15 | LastOpConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | USD conversion rate at time of change. From PositionChangeLog. Used for PnL normalization to USD. |
| 16 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Price record ID for the LastOpConversionRate. From PositionChangeLog. |
| 17 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade portfolio the position belongs to at time of change. From PositionChangeLog. 0 = no mirror. Live data: 0 for all recent rows. NULL for DataFix rows. |
| 18 | CID | int | YES | - | CODE-BACKED | Customer account ID. From PositionChangeLog. NULL for DataFix rows (DataFixLog does not track CID). |
| 19 | ChangeTypeID | int | YES | - | CODE-BACKED | Type of position change event. 0-13 for PCL events; 14 (Data Fix) for DataFix rows. See Section 2.2 for full value map. (Source: Dictionary.PCL_ChangeType) |
| 20 | NewAmount | money | YES | - | CODE-BACKED | Position amount after this change. From PositionChangeLog. Distinct from PreviousAmount+AmountChanged pattern - directly stores post-event amount. NULL for DataFix rows. |
| 21 | MirrorRealizedEquity | money | YES | - | CODE-BACKED | Realized equity in the copy-trade portfolio at time of change. From PositionChangeLog. NULL for non-mirror events and DataFix rows. |
| 22 | AccountRealizedEquity | money | YES | - | CODE-BACKED | Customer's total realized equity across all positions at time of change. From PositionChangeLog. Used for account-level monitoring. NULL for DataFix rows. |
| 23 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree ID: the root leader position grouping all follower positions. From PositionChangeLog. NULL for non-copy positions and DataFix rows. |
| 24 | IsTslEnabled | bit | YES | - | CODE-BACKED | Whether trailing stop-loss was enabled for the position at this event. From PositionChangeLog. Populated for ChangeTypeID=7 (Enable/Disable TSL). NULL for DataFix rows. |
| 25 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redemption status of the position at time of this event. From PositionChangeLog. Relevant for types 8-10 (redeem lifecycle). NULL for DataFix rows. |
| 26 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client-side idempotency key for the request that triggered this change. From PositionChangeLog. Enables deduplication of retried requests. NULL for DataFix rows. |
| 27 | PreviousIsSettled | bit | YES | - | CODE-BACKED | Settlement status before this change. From PositionChangeLog. Populated for ChangeTypeID=13 (Edit Is Settled). NULL for DataFix rows. |
| 28 | IsSettled | bit | YES | - | CODE-BACKED | Settlement status after this change. From PositionChangeLog. NULL for DataFix rows. |
| 29 | PreviousAmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in units (decimal) before this change. From PositionChangeLog. NULL for DataFix rows. |
| 30 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in units (decimal) after this change. From PositionChangeLog. NULL for DataFix rows. |
| 31 | PreviouseUnitsBaseValueCents | bigint | YES | - | CODE-BACKED | Base value of units in cents before this change. Note: "PreviouseUnitsBaseValueCents" has a typo ("Previouse") that is preserved from the base table DDL. From PositionChangeLog. NULL for DataFix rows. |
| 32 | UnitsBaseValueCents | bigint | YES | - | CODE-BACKED | Base value of units in cents after this change. From PositionChangeLog. NULL for DataFix rows. |
| 33 | ColumnName | varchar(255) | YES | - | CODE-BACKED | Name of the column that was corrected in a data fix operation. NULL for all PositionChangeLog rows. Populated only for DataFix branch (PositionChangeID=-1) rows from PositionDataFixLog. |
| 34 | OldValue | varchar(255) | YES | - | CODE-BACKED | Previous value of the corrected column (as string), before the data fix. NULL for all PositionChangeLog rows. Only populated for DataFix rows. |
| 35 | NewValue | varchar(255) | YES | - | CODE-BACKED | Replacement value applied to the corrected column (as string), after the data fix. NULL for all PositionChangeLog rows. Only populated for DataFix rows. |
| 36 | ChangeDescription | varchar(255) | YES | - | CODE-BACKED | Human-readable explanation of why the data fix was performed. NULL for all PositionChangeLog rows. Only populated for DataFix rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (branch 1) | History.PositionChangeLog | View (UNION ALL) | Structured position change log - 32 typed columns; full history via its own archive/active UNION ALL |
| (branch 2) | History.PositionDataFixLog | Table (UNION ALL) | Data fix audit log - free-text audit fields; PositionChangeID=-1 sentinel |
| ChangeTypeID | Dictionary.PCL_ChangeType | Implicit (inherited) | 15 event types (0=Open through 14=Data Fix) |
| PositionID | Trade.PositionTbl / History.Position | Implicit (inherited) | The position being audited |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the etoro SSDT repo directly reference History.PositionChangeLogFull. The constituent sources (History.PositionChangeLog and History.PositionDataFixLog) are referenced by ~12 and 0 procedures respectively.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionChangeLogFull (view)
|--> History.PositionChangeLog (view - full position change audit trail)
|       |--> [PositionChangeLogArchive linked server] (archive, records > 6 months old)
|       +--> History.PositionChangeLog_Active (view)
|                +--> History.PositionChangeLog_Active_BIGINT (table - 5.77M rows)
+--> History.PositionDataFixLog (table - data fix audit records, currently 0 rows)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog | View | UNION ALL branch 1 - structured PCL events with 32 typed columns |
| History.PositionDataFixLog | Table | UNION ALL branch 2 - data fix events with free-text audit fields |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on History.PositionChangeLog_Active_BIGINT's clustered (PositionID, Occurred) index for position-level queries, and on PositionDataFixLog's clustered (PositionID, Occurred) index. Filter by PositionID for efficient per-position event replay.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Full event timeline for a specific position

```sql
-- Get all events (including any data fixes) for a position in chronological order
SELECT
    pclf.PositionChangeID,
    pclf.ChangeTypeID,
    pclf.Occurred,
    pclf.PreviousAmount,
    pclf.NewAmount,
    pclf.PreviousStopRate,
    pclf.StopRate,
    pclf.ColumnName,
    pclf.OldValue,
    pclf.NewValue,
    pclf.ChangeDescription,
    CASE WHEN pclf.PositionChangeID = -1 THEN 'DataFix' ELSE 'PCL' END AS EventSource
FROM History.PositionChangeLogFull pclf WITH (NOLOCK)
WHERE pclf.PositionID = 2152976743
ORDER BY pclf.Occurred ASC
```

### 8.2 Find all data fix events across all positions

```sql
-- Data fix rows are identified by PositionChangeID = -1
SELECT
    pclf.PositionID,
    pclf.Occurred,
    pclf.ColumnName,
    pclf.OldValue,
    pclf.NewValue,
    pclf.ChangeDescription
FROM History.PositionChangeLogFull pclf WITH (NOLOCK)
WHERE pclf.PositionChangeID = -1
ORDER BY pclf.Occurred DESC
```

### 8.3 Position close events with pre-close state

```sql
-- Find positions that were closed (type 6) with their pre-close amount
SELECT TOP 100
    pclf.PositionID,
    pclf.CID,
    pclf.PreviousAmount,
    pclf.Occurred AS ClosedAt,
    pclf.LastOpPriceRate AS ClosePrice
FROM History.PositionChangeLogFull pclf WITH (NOLOCK)
WHERE pclf.ChangeTypeID = 6  -- Close Position
ORDER BY pclf.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 36 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionChangeLogFull | Type: View | Source: etoro/etoro/History/Views/History.PositionChangeLogFull.sql*
