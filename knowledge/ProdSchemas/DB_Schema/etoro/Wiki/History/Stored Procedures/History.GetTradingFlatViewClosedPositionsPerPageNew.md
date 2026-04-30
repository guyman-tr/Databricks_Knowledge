# History.GetTradingFlatViewClosedPositionsPerPageNew

> Returns a paginated list of closed trading positions for a customer within a date range, with human-readable action labels, close reasons, and gain percentage - used to power the trading history UI.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to query; @PageNum/@ItemsPerPage - pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.GetTradingFlatViewClosedPositionsPerPageNew` retrieves a single page of closed positions for a customer within a specified date range, formatted for display in the trading history UI (the "flat view"). The result set provides human-readable labels (action direction + instrument pair or name, close reason) alongside financial data (open/close rates, profit, units, gain percentage).

The procedure builds its result set from `History.Position` - the platform's 124-column unified view covering all closed positions from Q3 2007 to present - enriched by joins to Dictionary tables for labels and to `History.Mirror` for CopyTrader parent information. The "New" suffix distinguishes it from an older predecessor version.

Data flows from `History.Position` (the central closed-position interface) through six additional JOIN tables for enrichment. The procedure uses a CTE with ROW_NUMBER() for pagination rather than OFFSET/FETCH, executed via `sp_executesql` to allow dynamic ORDER BY and sort direction.

---

## 2. Business Logic

### 2.1 Dynamic Pagination with ROW_NUMBER CTE

**What**: Server-side pagination using a CTE + ROW_NUMBER approach with dynamic SQL.

**Columns/Parameters Involved**: `@ItemsPerPage`, `@PageNum`, `@OrderBy`, `@SortDirection`

**Rules**:
- ROW_NUMBER() is computed OVER (ORDER BY {dynamic @OrderBy} {dynamic @SortDirection}, PositionID ASC)
- PositionID ASC is a stable tiebreaker to ensure consistent ordering within each page
- Outer query: WHERE RowNum BETWEEN (@ItemsPerPage * (@PageNum - 1)) + 1 AND (@ItemsPerPage * @PageNum) - page 1 = rows 1 to @ItemsPerPage
- @OrderBy and @SortDirection are injected directly into dynamic SQL - callers are responsible for providing safe, column-name-only values
- Pagination parameters passed via sp_executesql parameterized query (@ParamDef)

**Diagram**:
```
CTE: History_GetClosedPositions
  ROW_NUMBER() OVER (ORDER BY @OrderBy @SortDirection, PositionID ASC)
        |
        v
Outer query:
  WHERE RowNum BETWEEN (@ItemsPerPage * (@PageNum - 1) + 1) AND (@ItemsPerPage * @PageNum)
  ORDER BY RowNum ASC
```

### 2.2 Date Range Filter (Date-Only, No Time)

**What**: The date range filter truncates timestamps to date only before comparison.

**Columns/Parameters Involved**: `@From`, `@To`, `hp.EndDateTime`

**Rules**:
- CONVERT(CHAR(8), @From, 112) and CONVERT(CHAR(8), @To, 112) strip the time component, converting to YYYYMMDD format
- The filter `hp.EndDateTime BETWEEN '{YYYYMMDD}' AND '{YYYYMMDD}'` includes the full start day (00:00:00) through end of the end date (effectively midnight, since EndDateTime has time component and string comparison starts at midnight of @To)
- Callers should pass date boundaries (e.g., start of day to end of day) to capture all intraday closes

### 2.3 Action Label Construction (Forex vs Non-Forex)

**What**: Computes a human-readable trade direction label based on instrument type and buy/sell direction.

**Columns/Parameters Involved**: `hp.IsBuy`, `buyCur.CurrencyTypeID`, `buyCur.Abbreviation`, `sellCur.Abbreviation`, `buyCur.Name`

**Rules**:
- CurrencyTypeID = 1 means Forex instrument - format: "{BUY|SELL} BaseCurrAbbr/QuoteCurrAbbr" (e.g., "BUY EUR/USD")
- CurrencyTypeID != 1 means Stock/Crypto/other - format: "{BUY|SELL} InstrumentName" (e.g., "BUY Apple")
- IsBuy = 1 -> "BUY"; IsBuy = 0 -> "SELL"
- buyCur = Dictionary.Currency matched to Trade.Instrument.BuyCurrencyID; sellCur = matched to SellCurrencyID

### 2.4 Gain Percentage Calculation

**What**: Inline P&L percentage calculation from NetProfit and Amount.

**Columns/Parameters Involved**: `hp.NetProfit`, `hp.Amount`

**Rules**:
- Gain = (NetProfit / Amount) * 100.0 - percentage return on invested amount
- No null guard - assumes Amount is always non-zero for closed positions
- Returned as a decimal percentage (e.g., 5.25 = 5.25% return)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Injected as a literal INTO the dynamic SQL via CAST(@CID AS VARCHAR(10)) for the WHERE hp.CID = filter. Only positions belonging to this customer are returned. |
| 2 | @ItemsPerPage | INT | YES | NULL | CODE-BACKED | Page size - number of positions per page. Used in the RowNum BETWEEN calculation. NULL if not provided (pagination disabled - but this would return no rows since RowNum BETWEEN NULL AND NULL matches nothing). |
| 3 | @PageNum | INT | YES | NULL | CODE-BACKED | 1-based page number. Page 1 returns rows 1 to @ItemsPerPage; page 2 returns rows @ItemsPerPage+1 to @ItemsPerPage*2, etc. NULL if not provided. |
| 4 | @From | DATETIME | NO | - | CODE-BACKED | Start of the date range for closed positions. Time component is stripped (CONVERT to YYYYMMDD) before use in BETWEEN filter on hp.EndDateTime. |
| 5 | @To | DATETIME | NO | - | CODE-BACKED | End of the date range for closed positions. Time component stripped to YYYYMMDD. Positions closed on or before this date (at midnight) are included. |
| 6 | @OrderBy | VARCHAR(24) | NO | - | CODE-BACKED | Column name to sort by. Injected directly into the ORDER BY clause of the dynamic SQL. Valid values correspond to output column names (e.g., 'OpenDate', 'CloseDate', 'NetProfit', 'Gain'). Caller is responsible for input safety. |
| 7 | @SortDirection | VARCHAR(4) | NO | - | CODE-BACKED | Sort direction. Injected directly into the dynamic SQL ORDER BY. Expected values: 'ASC' or 'DESC'. Caller is responsible for input safety. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | VERIFIED | Unique identifier of the closed position. From History.Position. |
| 2 | OpenDate | DATETIME | YES | - | VERIFIED | When the position was opened. From History.Position.OpenOccurred. |
| 3 | CloseDate | DATETIME | YES | - | VERIFIED | When the position was closed. From History.Position.EndDateTime. Used as the date range filter. |
| 4 | Amount | DECIMAL | NO | - | VERIFIED | The invested amount (in USD). From History.Position.Amount. Used as the denominator in the Gain calculation. |
| 5 | Units | DECIMAL | YES | - | CODE-BACKED | Position size in units (shares/contracts/coins). From History.Position.AmountInUnitsDecimal. |
| 6 | OpenRate | DECIMAL | NO | - | VERIFIED | The opening rate (price) of the position. From History.Position.InitForexRate. |
| 7 | CloseRate | DECIMAL | NO | - | VERIFIED | The closing rate (price) of the position. From History.Position.EndForexRate. |
| 8 | NetProfit | DECIMAL | NO | - | VERIFIED | Net profit/loss in USD after fees. From History.Position.NetProfit. Used in Gain calculation. |
| 9 | Gain | DECIMAL | NO | - | CODE-BACKED | Percentage return on the invested amount. Computed: (NetProfit / Amount) * 100.0. Positive = profit, negative = loss. |
| 10 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For CopyTrader positions: the PositionID of the position in the leader's portfolio that this position copied. From History.Position.ParentPositionID. NULL for manual trades. |
| 11 | Action | VARCHAR | YES | - | CODE-BACKED | Human-readable trade direction label. Forex: "BUY EUR/USD" or "SELL EUR/USD". Stock/Crypto: "BUY Apple" or "SELL Bitcoin". Computed from IsBuy + CurrencyTypeID + currency abbreviations/name. See Business Logic 2.3. |
| 12 | CloseReason | VARCHAR | YES | - | CODE-BACKED | Human-readable name for why the position was closed. From Dictionary.ClosePositionActionType.ClosePositionActionName, matched to History.Position.ActionType. Examples: "User Close", "Stop Loss", "Take Profit", "Margin Call". |
| 13 | ParentUserName | VARCHAR | YES | - | CODE-BACKED | For CopyTrader positions: the username of the leader whose position this is copying. From History.Mirror.ParentUserName via LEFT JOIN on MirrorID. NULL for manual trades or positions not in a copy-trade relationship. |
| 14 | MirrorID | INT | YES | - | CODE-BACKED | The CopyTrader mirror relationship ID. From History.Position.MirrorID. 0 or NULL for non-copy trades. Used as JOIN key to History.Mirror. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.Position | Reads (base) | Primary source - the unified closed-positions view |
| (body) | History.ForexResult | Reads (subquery JOIN) | Provides GameTypeID per position (via ForexResultID) |
| (body) | Dictionary.GameType | Reads (JOIN) | Lookup for GameTypeID from ForexResult |
| (body) | Trade.Instrument | Reads (JOIN) | Provides BuyCurrencyID and SellCurrencyID for action label |
| (body) | Dictionary.Currency (x2) | Reads (JOIN x2) | buyCur and sellCur for action label construction |
| (body) | Dictionary.ClosePositionActionType | Reads (JOIN) | Provides ClosePositionActionName for CloseReason |
| (body) | History.Mirror | Reads (LEFT JOIN) | Provides ParentUserName and ParentCID for CopyTrader positions |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetTradingFlatViewClosedPositionsPerPageNew (procedure)
├── History.Position (view - 124-col unified closed positions)
│     (see History.Position.md for full dependency tree)
├── History.ForexResult (table)
├── Dictionary.GameType (table)
├── Trade.Instrument (table)
├── Dictionary.Currency (table - buyCur alias)
├── Dictionary.Currency (table - sellCur alias)
├── Dictionary.ClosePositionActionType (table)
└── History.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | View | FROM - driving source for closed position data |
| History.ForexResult | Table | Subquery JOIN on ForexResultID - provides GameTypeID |
| Dictionary.GameType | Table | JOIN on GameTypeID - position game type |
| Trade.Instrument | Table | JOIN on InstrumentID - provides BuyCurrencyID/SellCurrencyID |
| Dictionary.Currency | Table | JOIN x2 (buyCur/sellCur) on CurrencyID - currency abbreviations and names for action label |
| Dictionary.ClosePositionActionType | Table | JOIN on ActionType/ID - provides ClosePositionActionName (CloseReason) |
| History.Mirror | Table | LEFT JOIN on MirrorID - provides ParentUserName for CopyTrader |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Important technical notes**:
- Uses `sp_executesql` with dynamic SQL for ORDER BY flexibility. @OrderBy and @SortDirection are injected as string literals, not parameterized - caller must ensure safe input.
- Date range uses CONVERT(CHAR(8), ..., 112) - strips time, uses date-only BETWEEN. @From and @To should be passed as date boundaries.
- `SET NOCOUNT ON` applied.

---

## 8. Sample Queries

### 8.1 Get page 1 of closed positions for a customer, ordered by close date descending

```sql
EXEC History.GetTradingFlatViewClosedPositionsPerPageNew
    @CID = 12345,
    @ItemsPerPage = 20,
    @PageNum = 1,
    @From = '2024-01-01',
    @To = '2024-12-31',
    @OrderBy = 'CloseDate',
    @SortDirection = 'DESC'
```

### 8.2 Get page 2 of results

```sql
EXEC History.GetTradingFlatViewClosedPositionsPerPageNew
    @CID = 12345,
    @ItemsPerPage = 20,
    @PageNum = 2,
    @From = '2024-01-01',
    @To = '2024-12-31',
    @OrderBy = 'NetProfit',
    @SortDirection = 'DESC'
```

### 8.3 Equivalent direct query for a customer's closed positions with gain

```sql
SELECT TOP 20
    hp.PositionID,
    hp.OpenOccurred AS OpenDate,
    hp.EndDateTime AS CloseDate,
    hp.Amount,
    hp.NetProfit,
    (hp.NetProfit / hp.Amount) * 100.0 AS Gain,
    AT.ClosePositionActionName AS CloseReason
FROM History.Position hp WITH (NOLOCK)
INNER JOIN Dictionary.ClosePositionActionType AT WITH (NOLOCK)
    ON AT.ID = hp.ActionType
WHERE hp.CID = 12345
  AND hp.EndDateTime BETWEEN '20240101' AND '20241231'
ORDER BY hp.EndDateTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.GetTradingFlatViewClosedPositionsPerPageNew | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetTradingFlatViewClosedPositionsPerPageNew.sql*
