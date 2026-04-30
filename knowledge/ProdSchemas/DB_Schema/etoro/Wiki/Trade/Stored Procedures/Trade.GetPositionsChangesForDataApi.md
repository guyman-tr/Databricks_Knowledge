# Trade.GetPositionsChangesForDataApi

> Returns position change log events enriched with current or historical position context, filtered by time window and multiple optional criteria, for consumption by the EngineDataApi service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID + ChangeLogID (PositionChangeID from History.PositionChangeLog_Active) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure surfaces the **position change log** to the external EngineDataApi service. Each row returned represents a specific change event (open, SL edit, partial close, etc.) that occurred to a trading position within the requested time window. The change is enriched with the position's core attributes (instrument, leverage, direction, parent) and customer identifiers (CID, GCID, ApexID, CountryID) needed for downstream analytics and compliance reporting.

The procedure exists because the EngineDataApi consumes a cross-system view of position mutation history. It needs to know not just what changed and when, but the full context of the position (instrument type, Apex external ID, country, mirror association) to build normalized data feeds. Without this procedure, the API would need to join several tables across schemas, which is encapsulated here with appropriate performance guards.

Data flows: The primary source is `History.PositionChangeLog_Active` (time-partitioned, indexed on Occurred). Each change log row is joined to `Customer.CustomerStatic` for GCID/ApexID/CountryID (inner join, so only customers with an ApexID are returned). The current position state is fetched from `Trade.PositionTbl` (StatusID=1 = open) via a LEFT JOIN; closed positions fall back to `History.PositionSlim` via another LEFT JOIN. Instrument metadata (Cusip, InstrumentTypeID) comes from `Trade.InstrumentMetaData`. The result merges open and closed position context using `ISNULL(live, historical)` coalesce patterns.

---

## 2. Business Logic

### 2.1 One-Day Time Window Constraint

**What**: The procedure enforces a maximum 1-day date range to protect performance on the high-volume PositionChangeLog_Active table.

**Columns/Parameters Involved**: `@StartTime`, `@EndTime`

**Rules**:
- If `ABS(DATEDIFF(DAY, @StartTime, @EndTime)) > 1`, the procedure raises error 16 ("Data range must be up to one day") and returns immediately.
- Callers must page through history by advancing the window, not by widening it.
- @StartTime is inclusive (`>=`), @EndTime is exclusive (`<`).

**Diagram**:
```
Valid:   @StartTime = '2021-06-05 00:00', @EndTime = '2021-06-06 00:00'  -> 1 day OK
Invalid: @StartTime = '2021-06-05 00:00', @EndTime = '2021-06-08 00:00'  -> RAISERROR
```

### 2.2 Optional TVP Filter Pattern

**What**: Each of the six filter dimensions is optional. An empty TVP means "no filter" for that dimension. A non-empty TVP means "restrict to these values only."

**Columns/Parameters Involved**: `@GCIDs`, `@ApexIDs`, `@Positions`, `@ChangeTypeIDs`, `@InstrumentTypes`, `@CountryIDs`

**Rules**:
- A flag variable (@FilterByXxx BIT) is set to 1 if the TVP has rows, 0 if empty.
- WHERE clause uses `(@FilterByXxx=0 OR Column IN (SELECT ... FROM @Xxx))` pattern - when flag=0 the condition short-circuits and all rows pass.
- All six filters can be combined; they are ANDed together.
- The @ChangeTypeIDs filter maps to `Dictionary.PCL_ChangeType` values (0=Open, 1=Edit SL, 2=Edit TP, 5=Detach from Mirror, 6=Close, 8=RedeemCancel, 9=RedeemPending, 10=RedeemClose, 11=Partial close, etc.).

**Diagram**:
```
Caller passes empty @GCIDs  -> @FilterByGCIDs=0 -> no GCID filter applied
Caller passes 3 GCIDs       -> @FilterByGCIDs=1 -> only those 3 GCIDs returned
```

### 2.3 Open vs. Closed Position Coalesce Pattern

**What**: A position at the time of the change may be currently open (in Trade.PositionTbl) or already closed (in History.PositionSlim). The procedure handles both with a LEFT JOIN + ISNULL coalesce.

**Columns/Parameters Involved**: `InstrumentID`, `ParentPositionID`, `IsBuy`, `Leverage`, `OpenOccurred`, `PositionCloseActionType`

**Rules**:
- `Trade.PositionTbl` joined WHERE `StatusID=1` (open only). If the position was since closed, TP columns will be NULL.
- `History.PositionSlim` joined for closed positions. If the position is still open, HPS columns will be NULL.
- Output columns use `ISNULL(TP.Column, HPS.Column)` so the live value is preferred; historical is the fallback.
- `PositionCloseActionType` (HPS.ActionType) will be NULL for open positions - indicates position is not yet closed.
- `CloseOccurred` will be NULL for open positions.
- Positions are filtered to valid action type ranges: HPS.ActionType must be NULL or in (0,1,2,5,8,9,10,12,13,17,18); TP.OpenActionType must be NULL or in (-1,0,1,2,3) - this excludes administrative/system-generated actions that are not relevant to normal data API consumers.

### 2.4 Pagination via OFFSET/FETCH

**What**: When both @RowsToSkip and @RowsToTake are provided with valid values, the procedure uses SQL Server's OFFSET/FETCH for server-side pagination. Without them, all matching rows are returned.

**Columns/Parameters Involved**: `@RowsToSkip`, `@RowsToTake`

**Rules**:
- Both must be non-NULL, @RowsToSkip >= 0, @RowsToTake > 0 for the paginated path to execute.
- The ORDER BY is on `HPCL.Occurred` (ascending), ensuring deterministic pagination.
- Paginated results are ordered by change occurrence time.
- Without pagination, results are unordered (no ORDER BY in the non-paginated branch).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartTime | DATETIME | NO | - | CODE-BACKED | Start of the change log time window (inclusive). Combined with @EndTime, the range must not exceed 1 calendar day or the procedure raises an error. |
| 2 | @EndTime | DATETIME | NO | - | CODE-BACKED | End of the change log time window (exclusive). Must be within 1 day of @StartTime. |
| 3 | @GCIDs | Trade.IdIntList READONLY | NO | - | CODE-BACKED | Optional TVP filter: list of Group Customer IDs. If populated, only change events for positions owned by customers in this GCID list are returned. Empty = no GCID filter. |
| 4 | @ApexIDs | Trade.ApexIDsList READONLY | NO | - | CODE-BACKED | Optional TVP filter: list of Apex external system IDs. If populated, only customers whose Customer.CustomerStatic.ApexID is in this list are returned. Empty = no ApexID filter. |
| 5 | @Positions | Trade.PositionIDsTbl READONLY | NO | - | CODE-BACKED | Optional TVP filter: list of specific PositionIDs. If populated, only change events for these positions are returned. Empty = no position filter. |
| 6 | @ChangeTypeIDs | Trade.TinyIntList READONLY | NO | - | VERIFIED | Optional TVP filter: list of change type IDs from Dictionary.PCL_ChangeType. Values: 0=Open Position, 1=Edit Stop Loss, 2=Edit Take Profit, 3=Edit Over Weekend, 4=EOW Fee, 5=Detach from Mirror, 6=Close Position, 7=Enable/Disable TSL, 8=PositionRedeemCancel, 9=PositionRedeemPending, 10=PositionRedeemClose, 11=Partial close, 12=Edit due to partial close, 13=Edit Is Settled, 14=Data Fix. Empty = no filter. |
| 7 | @InstrumentTypes | Trade.IdIntList READONLY | NO | - | CODE-BACKED | Optional TVP filter: list of InstrumentTypeIDs (from Trade.InstrumentMetaData). If populated, only positions in those instrument types are returned. Empty = no instrument type filter. |
| 8 | @CountryIDs | Trade.IdIntList READONLY | NO | - | CODE-BACKED | Optional TVP filter: list of CountryIDs (from Customer.CustomerStatic). If populated, only customers from those countries are returned. Empty = no country filter. |
| 9 | @RowsToSkip | INT | YES | NULL | CODE-BACKED | Pagination offset: number of rows to skip (0-based). If NULL or paired with a NULL/invalid @RowsToTake, the full result set is returned without pagination. |
| 10 | @RowsToTake | INT | YES | NULL | CODE-BACKED | Pagination page size: number of rows to return after skipping. Must be > 0 for pagination to activate. If NULL, all matching rows are returned. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 11 | PositionID | BIGINT | NO | - | CODE-BACKED | The trading position this change event belongs to. FK to Trade.PositionTbl / History.PositionSlim. |
| 12 | ChangeLogID | BIGINT | NO | - | CODE-BACKED | Unique identifier of the change event. From History.PositionChangeLog_Active.PositionChangeID. |
| 13 | ChangeLogTypeID | TINYINT | NO | - | VERIFIED | Type of change that occurred. From History.PositionChangeLog_Active.ChangeTypeID. See Dictionary.PCL_ChangeType: 0=Open Position, 1=Edit Stop Loss, 2=Edit Take Profit, 5=Detach from Mirror, 6=Close Position, 11=Partial close, etc. |
| 14 | ChangeLogOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp of when the change event was recorded. From History.PositionChangeLog_Active.Occurred. Used as the ORDER BY column for pagination. |
| 15 | ChangeLogAmount | DECIMAL | YES | - | CODE-BACKED | The new investment amount after the change event. From History.PositionChangeLog_Active.NewAmount. Relevant for partial close events. |
| 16 | ChangeLogAmountInUnits | DECIMAL | YES | - | CODE-BACKED | The new position size in units (e.g., shares or contract units) after the change event. From History.PositionChangeLog_Active.AmountInUnits. |
| 17 | ChangeLogRate | DECIMAL | YES | - | CODE-BACKED | The instrument price (last operation price rate) at the time of the change event. From History.PositionChangeLog_Active.LastOpPriceRate. |
| 18 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. From History.PositionChangeLog_Active.CID. Joined to Customer.CustomerStatic to resolve GCID/ApexID/CountryID. |
| 19 | GCID | INT | YES | - | CODE-BACKED | Group Customer ID. From Customer.CustomerStatic.GCID. The group-level identifier used in external reporting systems. |
| 20 | ApexID | VARCHAR | NO | - | CODE-BACKED | External Apex system customer identifier. From Customer.CustomerStatic.ApexID. The INNER JOIN on CustomerStatic requires ApexID IS NOT NULL, so only customers registered in the Apex system are included. |
| 21 | Cusip | VARCHAR | YES | - | CODE-BACKED | Committee on Uniform Security Identification Procedures code for the instrument. From Trade.InstrumentMetaData.Cusip. Used by the data API for instrument identification in external reporting. |
| 22 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument category type ID. From Trade.InstrumentMetaData.InstrumentTypeID. Matches @InstrumentTypes TVP filter. |
| 23 | CountryID | INT | YES | - | CODE-BACKED | Customer's country of residence. From Customer.CustomerStatic.CountryID. Matches @CountryIDs TVP filter. |
| 24 | MirrorID | INT | YES | - | CODE-BACKED | If the position is a copy-trade position, the ID of the Mirror relationship. From Trade.PositionTbl.MirrorID. 0 or NULL = manual (non-copy) position. Only populated for open positions (NULL for closed). |
| 25 | PositionOpenActionType | INT | YES | - | CODE-BACKED | How the position was originally opened. From Trade.PositionTbl.OpenActionType. Filtered to values in (-1, 0, 1, 2, 3): -1=unknown/internal, 0=Customer manual, 1=Hierarchical (CopyTrader copy), 2=Mirror portfolio, 3=other. NULL for closed positions (not available from PositionSlim). |
| 26 | PositionCloseActionType | INT | YES | - | CODE-BACKED | How the position was closed. From History.PositionSlim.ActionType. Filtered to values in (0,1,2,5,8,9,10,12,13,17,18) to exclude non-standard closure types. NULL if the position is still open. |
| 27 | InstrumentID | INT | NO | - | CODE-BACKED | The traded instrument. Coalesced as ISNULL(Trade.PositionTbl.InstrumentID, History.PositionSlim.InstrumentID) - live position preferred, historical fallback. |
| 28 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For copy-trade positions, the ID of the leader's position this was copied from. Coalesced from live then historical. 0 or 1 = root (non-copy). Positive = copy of referenced position. |
| 29 | IsBuy | BIT | NO | - | VERIFIED | Direction of the position. Coalesced from live then historical. 1 = Buy/Long, 0 = Sell/Short. |
| 30 | Leverage | DECIMAL | NO | - | CODE-BACKED | Leverage multiplier applied to the position at open. Coalesced from live then historical. 1 = no leverage (real stocks). |
| 31 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was originally opened. Coalesced as ISNULL(Trade.PositionTbl.Occurred, History.PositionSlim.OpenOccurred). |
| 32 | CloseOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the position was closed. From History.PositionSlim.CloseOccurred. NULL if the position is still open. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCIDs | Trade.IdIntList | TVP type | Passes list of Group Customer IDs for filter |
| @ApexIDs | Trade.ApexIDsList | TVP type | Passes list of Apex external IDs for filter |
| @Positions | Trade.PositionIDsTbl | TVP type | Passes list of Position IDs for filter |
| @ChangeTypeIDs | Trade.TinyIntList | TVP type | Passes list of PCL change type IDs for filter |
| @InstrumentTypes | Trade.IdIntList | TVP type | Passes list of instrument type IDs for filter |
| @CountryIDs | Trade.IdIntList | TVP type | Passes list of country IDs for filter |
| ChangeLogTypeID | Dictionary.PCL_ChangeType | Lookup | Change event type: 0=Open Position, 6=Close Position, 11=Partial close, etc. |
| CID / PositionID | History.PositionChangeLog_Active | Primary source | All change log events read from this table |
| CID | Customer.CustomerStatic | JOIN | GCID, ApexID, CountryID lookup; INNER JOIN requires ApexID IS NOT NULL |
| PositionID | Trade.PositionTbl | JOIN | Live position context (open only, StatusID=1) |
| PositionID | History.PositionSlim | JOIN | Historical position context (closed positions) |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Cusip and InstrumentTypeID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EngineDataApi (DB user) | GRANT EXECUTE | Permission | The EngineDataApi service is the designated consumer of this procedure, as evidenced by EXECUTE permission in UsersPermissions/EngineDataApi.sql |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsChangesForDataApi (procedure)
├── History.PositionChangeLog_Active (table)
├── Customer.CustomerStatic (table)
├── Trade.PositionTbl (table)
├── History.PositionSlim (table)
└── Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog_Active | Table | Primary source - all change log events are read from this table, filtered by Occurred time window |
| Customer.CustomerStatic | Table | INNER JOIN on CID to resolve GCID, ApexID, CountryID; requires ApexID IS NOT NULL |
| Trade.PositionTbl | Table | LEFT JOIN on PositionID (StatusID=1) to get live position context (MirrorID, OpenActionType, InstrumentID, etc.) |
| History.PositionSlim | Table | LEFT JOIN on PositionID to get closed position context (CloseOccurred, CloseActionType, InstrumentID fallback) |
| Trade.InstrumentMetaData | Table | INNER JOIN on InstrumentID (coalesced from live/historical) to get Cusip and InstrumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EngineDataApi (application service) | External application | Calls this procedure to build normalized position change feeds for downstream analytics and compliance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range validation | Business rule | ABS(DATEDIFF(DAY, @StartTime, @EndTime)) <= 1; enforced via RAISERROR 16 if violated |
| ApexID filter | JOIN constraint | INNER JOIN on CustomerStatic with ApexID IS NOT NULL - only Apex-registered customers are included |
| Open position filter | JOIN constraint | Trade.PositionTbl joined WHERE StatusID=1 AND PartitionCol=PositionID%50 |
| Pagination guard | Parameter validation | @RowsToSkip >= 0 AND @RowsToTake > 0 required for paginated path |

---

## 8. Sample Queries

### 8.1 Get all position changes for a specific day (no filters)

```sql
DECLARE @GCIDs Trade.IdIntList;
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @Positions Trade.PositionIDsTbl;
DECLARE @ChangeTypeIDs Trade.TinyIntList;
DECLARE @InstrumentTypes Trade.IdIntList;
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetPositionsChangesForDataApi
    @StartTime = '2024-01-15 00:00:00',
    @EndTime   = '2024-01-16 00:00:00',
    @GCIDs = @GCIDs,
    @ApexIDs = @ApexIDs,
    @Positions = @Positions,
    @ChangeTypeIDs = @ChangeTypeIDs,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs;
```

### 8.2 Get partial close and close events only, paginated

```sql
DECLARE @GCIDs Trade.IdIntList;
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @Positions Trade.PositionIDsTbl;
DECLARE @ChangeTypeIDs Trade.TinyIntList;
INSERT INTO @ChangeTypeIDs VALUES (6), (11); -- 6=Close, 11=Partial close
DECLARE @InstrumentTypes Trade.IdIntList;
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetPositionsChangesForDataApi
    @StartTime     = '2024-01-15 00:00:00',
    @EndTime       = '2024-01-16 00:00:00',
    @GCIDs         = @GCIDs,
    @ApexIDs       = @ApexIDs,
    @Positions     = @Positions,
    @ChangeTypeIDs = @ChangeTypeIDs,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs    = @CountryIDs,
    @RowsToSkip    = 0,
    @RowsToTake    = 100;
```

### 8.3 Get changes for specific customers and instrument types

```sql
DECLARE @GCIDs Trade.IdIntList;
INSERT INTO @GCIDs VALUES (1983593),(5054942);
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @Positions Trade.PositionIDsTbl;
DECLARE @ChangeTypeIDs Trade.TinyIntList;
DECLARE @InstrumentTypes Trade.IdIntList;
INSERT INTO @InstrumentTypes VALUES (4),(10); -- specific instrument type IDs
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetPositionsChangesForDataApi
    @StartTime = '2024-01-15 00:00:00',
    @EndTime   = '2024-01-16 00:00:00',
    @GCIDs = @GCIDs,
    @ApexIDs = @ApexIDs,
    @Positions = @Positions,
    @ChangeTypeIDs = @ChangeTypeIDs,
    @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsChangesForDataApi | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsChangesForDataApi.sql*
