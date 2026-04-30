# Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId

> Trading API procedure that returns a paginated list of closed manual positions for a specific customer and instrument, ordered by most recently closed first.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @instrumentId INT (composite filter, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the position list view within the "per-instrument drill-down" in portfolio history. When a customer selects a specific instrument from their instrument breakdown (e.g., as returned by `TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments`), this procedure retrieves the paginated list of individual closed trades for that instrument.

Only manually-opened positions are returned (`MirrorID = 0`). Positions opened through CopyTrader sessions are excluded - those belong in the mirror history view. The optional `@startTime` filter narrows results to positions closed within a time window; when NULL, all-time history for that instrument is returned.

The result set provides the full set of fields needed to render a position list row: identity keys, trade direction, leverage, size, open/close rates, P&L, fees, the reason for closing (`ActionType`), and attribution fields (OriginalPositionID, ParentPositionID for position tree context). The hardcoded `0 AS ParentCID` confirms all returned positions are manual (not from a copy relationship), so ParentCID is always meaningless/zero for this query.

The companion procedure `TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg` provides the total counts and sums for the same filter (used to render the summary header above the list).

---

## 2. Business Logic

### 2.1 Manual Positions Only (MirrorID = 0 + Instrument Filter)

**What**: Dual filter to isolate the customer's own manual trades in a specific instrument.

**Columns/Parameters Involved**: `@cid`, `@instrumentId`, `MirrorID`, `CloseOccurred`, `@startTime`

**Rules**:
- `WHERE CID = @cid AND InstrumentID = @instrumentId AND MirrorID = 0` - filters to the exact customer + instrument + manual-only combination
- `AND (CloseOccurred >= @startTime OR @startTime IS NULL)` - optional date range from close timestamp
- Sorted by `CloseOccurred DESC` - most recently closed position appears first (typical for history lists)
- MirrorID = 0 ensures copy positions are excluded; they are served by the mirror history procedures

### 2.2 Hardcoded ParentCID = 0

**What**: The ParentCID output column is always zero for this procedure.

**Columns/Parameters Involved**: `ParentCID` (output), `MirrorID`

**Rules**:
- `0 AS ParentCID` - hardcoded constant in the SELECT
- Since MirrorID = 0 filter already guarantees manual positions, no ParentCID (copy-trader) relationship exists
- The column is included in the result set to maintain schema compatibility with other position-list procedures that may return positions from both manual and copy sources where ParentCID would be non-zero

### 2.3 Null-Safe Column Defaults

**What**: Several nullable columns are coalesced to 0 for API compatibility.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `OrderID`, `ParentPositionID`, `MirrorID`, `RedeemStatus`, `OriginalPositionID`

**Rules**:
- `ISNULL(AmountInUnitsDecimal, 0)` - units may be NULL for older positions pre-dating this field
- `ISNULL(OrderID, 0)` - 0 = position was not created from a pending order
- `ISNULL(ParentPositionID, 0)` - 0 = not a child position in a copy tree
- `ISNULL(MirrorID, 0)` - redundant with the MirrorID=0 filter but safe
- `ISNULL(RedeemStatus, 0)` - 0 = position is not part of a redemption
- `ISNULL(OriginalPositionID, PositionID)` - fallback to self when no original position exists (original differs after reopen/split scenarios)
- `InitialAmountCents / 100 AS InitialAmountInDollars` - converts cents to dollars

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Scopes all results to this customer's positions only. |
| 2 | @instrumentId | INT | NO | - | CODE-BACKED | Instrument ID filter. Only closed positions for this specific instrument are returned. FK to Trade.InstrumentMetaData. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional period start. When NULL: all-time position history for this instrument. When provided: only positions closed on or after @startTime (CloseOccurred >= @startTime). |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). Results sorted by CloseOccurred DESC before paging. |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of position rows per page. |

### Output - Individual Closed Manual Positions

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Amount | DECIMAL | NO | - | CODE-BACKED | Invested amount in USD for this position. The trade size in dollars at the time of opening. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. Always matches @cid. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID. Always matches @instrumentId. FK to Trade.InstrumentMetaData. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy (Long), 0 = Sell (Short). For real stock positions (IsSettled=1), always 1. |
| 5 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier at open (e.g., 1, 2, 5, 10, 100). Real stock positions use Leverage=1. |
| 6 | InitDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was opened. |
| 7 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Opening rate (price) of the instrument at position open time. Used for P&L calculation reference. |
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. Primary key from History.PositionSlim. |
| 9 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop-Loss rate set on the position at close. NULL if no Stop Loss was configured. |
| 10 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take-Profit rate set on the position at close. NULL if no Take Profit was configured. |
| 11 | AmountInUnitsDecimal | DECIMAL | NO | 0 | CODE-BACKED | Position size in instrument units (e.g., number of shares). ISNULL defaults NULL to 0 for older positions where this field was not populated. |
| 12 | EndOfWeekFee | DECIMAL | YES | - | CODE-BACKED | Overnight/weekend holding fee accumulated over the life of this position. |
| 13 | InitialAmountInDollars | DECIMAL | NO | - | CODE-BACKED | Original invested amount in USD. Derived: InitialAmountCents / 100. Stored as cents in History.PositionSlim; converted to dollars here. |
| 14 | OrderID | INT | NO | 0 | CODE-BACKED | Pending order ID that triggered position open: 0 = position was opened at market (not from a pending order). ISNULL defaults NULL to 0. |
| 15 | ParentPositionID | BIGINT | NO | 0 | CODE-BACKED | Parent position in a copy-tree hierarchy: 0 = no parent (not a child copy position). ISNULL defaults NULL to 0. Since MirrorID=0 for all results, this will typically be 0. |
| 16 | MirrorID | INT | NO | 0 | CODE-BACKED | Copy session ID: always 0 for this procedure (enforced by MirrorID=0 WHERE filter). Included for result-set schema compatibility with other position-list procedures. |
| 17 | ActionType | INT | NO | - | CODE-BACKED | Reason the position was closed. Values: manual user close, Stop Loss trigger, Take Profit trigger, system liquidation, margin call, redemption, etc. FK to Dictionary.ClosePositionActionType. |
| 18 | NetProfit | DECIMAL | YES | - | CODE-BACKED | Realized P&L for this position in USD. Positive = profit, negative = loss. |
| 19 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Closing rate (price) of the instrument at position close time. |
| 20 | CloseOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was closed. Sort key (DESC order). |
| 21 | ParentCID | INT | NO | 0 | CODE-BACKED | Hardcoded to 0. Since all returned positions are manual (MirrorID=0), there is no Popular Investor parent. Included for schema compatibility with procedures that also return copy positions. |
| 22 | IsSettled | BIT | NO | - | CODE-BACKED | Legacy settlement type: 1 = real stock position (owned shares), 0 = CFD. Predates SettlementTypeID. |
| 23 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type (newer). FK to Dictionary.SettlementTypes. NULL uses IsSettled as fallback. |
| 24 | RedeemStatus | INT | NO | 0 | CODE-BACKED | Stock redemption status: 0 = not a redemption close. When > 0 indicates redemption-related close state. ISNULL defaults NULL to 0. |
| 25 | OriginalPositionID | BIGINT | NO | - | CODE-BACKED | The original position ID before any reopen/split events. Falls back to PositionID if NULL (via ISNULL) - meaning this is the original position. |
| 26 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | Unit count at position open time. May differ from AmountInUnitsDecimal if partial close occurred. |
| 27 | OpenActionType | INT | YES | - | CODE-BACKED | Reason/method the position was opened. FK to Dictionary.OpenPositionActionType. |
| 28 | CloseTotalFees | DECIMAL | YES | - | CODE-BACKED | Total fees charged at position close (spread, commission, etc.). |
| 29 | CloseTotalTaxes | DECIMAL | YES | - | CODE-BACKED | Total taxes collected at position close. |
| 30 | OpenTotalFees | DECIMAL | YES | - | CODE-BACKED | Total fees charged at position open. |
| 31 | OpenTotalTaxes | DECIMAL | YES | - | CODE-BACKED | Total taxes collected at position open. |
| 32 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots (standard lot units). Used for lot-based reporting. |
| 33 | InitialLotCount | DECIMAL | YES | - | CODE-BACKED | Lot count at position open time. May differ from LotCountDecimal after partial close. |
| 34 | OriginalOpenActionType | INT | YES | - | CODE-BACKED | Open action type from the original position (before reopen). Used to trace the original open method after position reopen scenarios. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentID, MirrorID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of all closed position data for this customer + instrument |
| InstrumentID | Trade.InstrumentMetaData | Implicit FK | Identifies the traded asset |
| ActionType | Dictionary.ClosePositionActionType | Implicit FK | Lookup for position close reason |
| OpenActionType | Dictionary.OpenPositionActionType | Implicit FK | Lookup for position open reason |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit FK | Lookup for settlement type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account. Companion: `Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg` provides the aggregate totals for the same filter.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId (procedure)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Source of all output columns; filtered to manual trades for @cid + @instrumentId |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Key behavioral characteristics:
- Returns multiple rows (paginated list, sorted by CloseOccurred DESC)
- MirrorID = 0 enforced - no copy positions ever returned
- ParentCID hardcoded to 0 - schema compatibility constant
- WITH (NOLOCK) on History.PositionSlim

---

## 8. Sample Queries

### 8.1 Get positions for customer on a specific instrument, last year

```sql
EXEC Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId
    @cid = 12345,
    @instrumentId = 1,
    @startTime = DATEADD(YEAR, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get all-time positions for a specific instrument (no date filter)

```sql
EXEC Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId
    @cid = 12345,
    @instrumentId = 1,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.3 Preview raw data from History.PositionSlim for this filter

```sql
SELECT TOP 5
    hp.PositionID,
    hp.Amount,
    hp.NetProfit,
    hp.ActionType,
    hp.CloseOccurred
FROM History.PositionSlim hp WITH (NOLOCK)
WHERE hp.CID = 12345
    AND hp.InstrumentID = 1
    AND hp.MirrorID = 0
ORDER BY hp.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId.sql*
