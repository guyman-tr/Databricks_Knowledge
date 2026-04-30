# History.GetClosedPositionsPerPageAndTimeFrame

> Returns a customer's closed positions within a caller-specified date range, with dynamic sorting and pagination, enriched with instrument info, CopyTrader context, and extended PositionType values including detached variants.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @From/@To date filter; @NumberOfItems + @OrderBy/@SortDirection for presentation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **time-range-flexible** counterpart to `History.GetClosedPositionsPerPage`. Where that procedure has a hard-coded 3-month limit, this one accepts caller-specified `@From` and `@To` date bounds, making it suitable for wider history queries (e.g., tax reporting, annual portfolio reviews). It also adds dynamic sort order (sort column + direction), a richer PositionType classification including "detached" variants, and returns additional columns (`Action`, `CloseReason`, `parentCID`).

This procedure is called by the trading history UI when a customer applies a custom date filter to their closed position history.

---

## 2. Business Logic

### 2.1 Extended PositionType Classification (Includes Detached)

**What**: 5-value classification using OrigParentPositionID to distinguish active vs detached copy positions.

**Columns/Parameters Involved**: `ParentPositionID`, `MirrorID`, `OrigParentPositionID`

**Rules**:
- `Regular`: ISNULL(OrigParentPositionID,0)=0 - never part of a copy trade.
- `CopyPlus`: ParentPositionID>0 AND MirrorID=0 AND OrigParentPositionID>0 - active Copy Plus position.
- `Mirror`: ParentPositionID>0 AND MirrorID>0 AND OrigParentPositionID>0 - active Mirror (CopyTrader) position.
- `CopyPlus detached`: ParentPositionID=0 AND MirrorID=0 AND OrigParentPositionID>0 - was Copy Plus but parent position closed.
- `Mirror detached`: ParentPositionID=0 AND MirrorID>0 AND OrigParentPositionID>0 - was mirrored but leader/mirror disconnected.

*Note: GetClosedPositionsPerPage only has 3 position types; this procedure adds the two "detached" variants.*

### 2.2 Dynamic Sort Order

**What**: Caller controls sort column and direction via @OrderBy and @SortDirection parameters.

**Supported sort columns**: CloseDate, Amount, Units, OpenRate, CloseRate, NetProfit, CloseReason, Gain, Action.

**Rules**:
- CASE WHEN @OrderBy (case-insensitive) = '{column}' AND @SortDirection = 'asc'/'desc' THEN {column} END - evaluated per column.
- Unknown @OrderBy or @SortDirection falls back to natural table order.

### 2.3 Date Range Filter and SET ROWCOUNT

**Rules**:
- `WHERE hp.EndDateTime BETWEEN @From1 AND @To1` (uses local variables to avoid parameter sniffing)
- `SET ROWCOUNT @NumberOfItems` limits the total result set to @NumberOfItems rows before pagination.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose closed positions are retrieved. |
| 2 | @NumberOfItems | INT | NO | - | CODE-BACKED | Total row limit (SET ROWCOUNT). Also used as items per page. |
| 3 | @From | DATETIME | NO | - | CODE-BACKED | Start of date range filter on hp.EndDateTime (close date). |
| 4 | @To | DATETIME | NO | - | CODE-BACKED | End of date range filter on hp.EndDateTime (close date). |
| 5 | @OrderBy | VARCHAR(24) | NO | - | CODE-BACKED | Column to sort by. Supported: CloseDate, Amount, Units, OpenRate, CloseRate, NetProfit, CloseReason, Gain, Action. |
| 6 | @SortDirection | VARCHAR(4) | NO | - | CODE-BACKED | Sort direction: 'ASC' or 'DESC'. |

**Result set columns** (superset of GetClosedPositionsPerPage):

| Column | Added vs #11 | Description |
|--------|-------------|-------------|
| parent CID | YES | Caller's CID (aliased as "parent CID") |
| PositionID | - | Unique position identifier |
| Action | YES | Trade direction string: "BUY EUR/USD", "SELL AAPL", etc. |
| GameName | - | Game type name |
| IsBuy | - | 1=Buy/Long, 0=Sell/Short |
| CurrencyBuy/CurrencySell | - | Buy/sell currency IDs |
| BuyCurAbbreviation/SellCurAbbreviation | - | Currency abbreviations |
| BuyCurrencyTypeID/SellCurrencyTypeID | - | Currency type IDs |
| OpenDate/CloseDate | - | Open and close timestamps |
| Amount/Units | - | Invested amount and position size |
| OpenRate/CloseRate | - | Open and close exchange rates |
| Spread | - | CommissionOnClose (no *100 multiplication here) |
| NetProfit/Gain | - | PnL in USD and as percentage |
| MirrorID/ParentPositionID | - | Copy trade identifiers |
| PositionType | Extended | 5-value type (adds CopyPlus detached, Mirror detached) |
| CloseReason | YES | Close reason name (renamed from ClosePositionActionName) |
| ParentUserName | - | CopyTrader leader username |
| parentCID | YES | Leader's CID |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source; filtered by CID + date range. |
| JOIN | History.ForexResult | Read | GameTypeID lookup. |
| JOIN | Dictionary.GameType | Lookup | Game name. |
| JOIN | Trade.Instrument | Lookup | Currency IDs for instrument. |
| JOIN | Dictionary.Currency (x2) | Lookup | Buy/sell currency abbreviations and type IDs. |
| JOIN | Dictionary.ClosePositionActionType | Lookup | Close reason name. |
| LEFT JOIN | History.Mirror | Read | Leader's ParentUserName and ParentCID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| eToro platform API | EXEC | Direct call | Position history page with custom date range filter. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetClosedPositionsPerPageAndTimeFrame (procedure)
├── History.Position (table)
├── History.ForexResult (table)
├── History.Mirror (table)
├── Dictionary.GameType (table) [cross-schema]
├── Dictionary.Currency (table) [cross-schema - x2]
├── Dictionary.ClosePositionActionType (table) [cross-schema]
└── Trade.Instrument (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source filtered by CID + EndDateTime date range. |
| History.ForexResult | Table | JOIN for GameTypeID. |
| History.Mirror | Table | LEFT JOIN for ParentUserName + ParentCID. |
| Dictionary.GameType | Table | Game name lookup. |
| Dictionary.Currency | Table | Currency abbreviation and type ID lookup (x2). |
| Dictionary.ClosePositionActionType | Table | Close reason lookup. |
| Trade.Instrument | Table | Instrument currency IDs. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro platform (application) | External | Position history with date range filter UI. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET ROWCOUNT @NumberOfItems | Row limiter | Hard cap on total rows returned before applying pagination. |
| Local variable copy for @From/@To | Anti-sniffing | @From1 = @From pattern prevents parameter sniffing on date range parameters. |
| Case-insensitive OrderBy | Design | Uses lower(@OrderBy) = lower('{column}') comparisons. |

---

## 8. Sample Queries

### 8.1 Get closed positions for January 2025

```sql
EXEC History.GetClosedPositionsPerPageAndTimeFrame
    @CID = 12345,
    @NumberOfItems = 100,
    @From = '2025-01-01',
    @To = '2025-01-31',
    @OrderBy = 'CloseDate',
    @SortDirection = 'DESC';
```

### 8.2 Get sorted by NetProfit descending

```sql
EXEC History.GetClosedPositionsPerPageAndTimeFrame
    @CID = 12345,
    @NumberOfItems = 50,
    @From = '2024-01-01',
    @To = '2024-12-31',
    @OrderBy = 'NetProfit',
    @SortDirection = 'DESC';
```

### 8.3 Count closed positions in a date range directly

```sql
SELECT COUNT(*) AS ClosedPositions
FROM History.Position WITH (NOLOCK)
WHERE CID = 12345
  AND EndDateTime BETWEEN '2024-01-01' AND '2024-12-31';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetClosedPositionsPerPageAndTimeFrame | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetClosedPositionsPerPageAndTimeFrame.sql*
