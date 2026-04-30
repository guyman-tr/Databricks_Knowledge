# Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId

> Public variant of the per-instrument position drill-down: returns a paginated list of closed manual positions for a specific customer and instrument, with NetProfit expressed as a percentage of invested amount rather than dollar value.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @instrumentId INT + @startTime DATETIME (public position list, paginated, single result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the public variant of `TAPI_GetHistoryPositionsByCidAndInstrumentId`. It powers the position list view within the "per-instrument drill-down" on a user's public profile portfolio history. When a visitor views another user's public trading history and clicks on a specific instrument row (as returned by `TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual`), this procedure retrieves the paginated list of individual closed trades for that instrument.

The key difference from the private variant is that `NetProfit` is returned as a percentage of invested amount (100 * NetProfit / Amount) rather than as a raw dollar value. This design is intentional for public viewing - the exact profit/loss in dollars is not exposed, only the return percentage. The output also has fewer columns than the private variant, omitting sensitive fields such as `InitialAmountCents`, `RedeemStatus`, and `OrderID`.

Only manually-opened positions are returned (`MirrorID = 0`). Privacy check (OperationTypeID=3) applies first.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Validates the account has not been blocked from exposing trading history to the public.

**Columns/Parameters Involved**: `@cid`, `Customer.BlockedCustomerOperations.OperationTypeID`

**Rules**:
- Checks `Customer.BlockedCustomerOperations WHERE CID=@cid AND OperationTypeID=3`
- If row exists: `RAISERROR(60090, 16, 1)` - aborts execution before any data is returned
- OperationTypeID=3 = "view history" operation - when blocked, the public profile history API cannot expose positions

### 2.2 Manual Positions Only - Per-Instrument Filter

**What**: Returns only the customer's manual positions for a specific instrument within the time window.

**Columns/Parameters Involved**: `@cid`, `@instrumentId`, `MirrorID`, `OrigParentPositionID`, `CloseOccurred`, `@startTime`

**Rules**:
- `WHERE CID=@cid AND InstrumentID=@instrumentId AND MirrorID=0` - customer + instrument + manual-only
- `AND (OrigParentPositionID=0 OR OrigParentPositionID IS NULL)` - excludes partial-close remnant positions to avoid double-counting
- `AND (CloseOccurred >= @startTime AND CloseOccurred > DATEADD(year,-1,GETUTCDATE()))` - dual time gate: user-specified start AND hard 1-year cap. Unlike the private variant, @startTime is REQUIRED (no NULL default)
- `ORDER BY CloseOccurred DESC` - most recently closed positions first

### 2.3 NetProfit as Return Percentage (Public Masking)

**What**: Converts the raw dollar NetProfit to a return percentage for public display.

**Columns/Parameters Involved**: `NetProfit`, `Amount`

**Rules**:
- Formula: `CASE ISNULL(Amount, 0) WHEN 0 THEN 0 ELSE 100 * ISNULL(NetProfit, 0) / ISNULL(Amount, 0) END`
- Returns 0 when Amount is NULL or zero (prevents divide-by-zero)
- This is a percentage value (e.g., 15.5 means 15.5% return on invested amount)
- Contrast with private variant which returns raw `NetProfit` in dollars

### 2.4 Hardcoded ParentCID = 0

**What**: ParentCID is always zero since all returned positions are manual.

**Rules**:
- `0 AS ParentCID` - hardcoded constant; MirrorID=0 filter ensures no copy relationship exists
- Maintains output schema compatibility with other position-list procedures

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the account whose public history is being viewed). Privacy check uses this ID first. All positions scoped to this CID. |
| 2 | @instrumentId | INT | NO | - | CODE-BACKED | The specific instrument to drill into. Filters History.PositionSlim to this InstrumentID only. |
| 3 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start for CloseOccurred. Required (no NULL default). Combined with 1-year hard cap. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size - number of position rows per page. |

### Output - Closed Manual Positions for the Specified Instrument

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. From History.PositionSlim. Primary key for the closed position record. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID - same as @cid parameter. The account that owned this position. |
| 3 | ParentPositionID | INT | NO | 0 | CODE-BACKED | ISNULL(ParentPositionID, 0). 0 = not a child in a position tree. Non-zero indicates this position was a partial close or linked to a copy tree (not expected given MirrorID=0 filter). |
| 4 | ParentCID | INT | NO | 0 | CODE-BACKED | Hardcoded 0. Manual positions have no copy-trade parent customer. Included for output schema compatibility with mixed position-list endpoints where copy positions would have a non-zero ParentCID. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier - same as @instrumentId parameter. FK to Trade.InstrumentMetaData. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy (Long position), 0 = Sell (Short position). |
| 7 | CloseReason | INT | NO | - | CODE-BACKED | Aliased from ActionType. Reason the position was closed: manual close, stop loss hit, take profit hit, etc. FK to Dictionary.ClosePositionActionType. |
| 8 | OpenRate | DECIMAL | NO | - | CODE-BACKED | Aliased from InitForexRate. The exchange rate at which the position was opened. |
| 9 | OpenDateTime | DATETIME | NO | - | CODE-BACKED | Aliased from InitDateTime. Timestamp when the position was opened. |
| 10 | CloseRate | DECIMAL | NO | - | CODE-BACKED | Aliased from EndForexRate. The exchange rate at which the position was closed. |
| 11 | CloseDateTime | DATETIME | NO | - | CODE-BACKED | Aliased from CloseOccurred. Timestamp when the position was closed. Primary sort key (DESC). |
| 12 | MirrorID | INT | NO | 0 | CODE-BACKED | Always 0 for this result set (enforced by WHERE MirrorID=0 filter). 0 = manual position, not from a CopyTrader session. |
| 13 | NetProfit | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return as a percentage of invested amount: 100 * NetProfit / Amount. NOT a dollar value - this is a return percentage (e.g., 12.5 = 12.5% return). 0 when Amount is NULL or 0. Differs from private variant which returns raw dollar NetProfit. |
| 14 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier applied to this position (e.g., 1 = no leverage, 5 = 5x). |
| 15 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Size of the position in lots (fractional). Lot = standardized trading unit for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentID, MirrorID, OrigParentPositionID, CloseOccurred, and all output columns | History.PositionSlim | Lookup (READ) | Source of all position data. Filtered to manual positions (MirrorID=0) for a specific customer + instrument + time window. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy gate - OperationTypeID=3 blocks public history exposure. |
| CloseReason (ActionType) | Dictionary.ClosePositionActionType | Lookup | FK to action type dictionary - identifies how the position was closed. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Granted to TDAPIUser and TDAPIUserProd service accounts - called by the Trading Data API service to power the public per-instrument position drill-down list.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId (procedure)
├── History.PositionSlim (table - cross-schema)
└── Customer.BlockedCustomerOperations (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table | Main data source - queried with WHERE CID=@cid AND InstrumentID=@instrumentId AND MirrorID=0 AND OrigParentPositionID=0/NULL AND time filter. |
| Customer.BlockedCustomerOperations | Table | Privacy gate - SELECT to check OperationTypeID=3 for @cid before returning any data. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TDAPIUser service account | External | Granted EXECUTE permission - called by the Trading Data API to serve the public per-instrument position list. Companion aggregate: `Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg`. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get public manual positions for a customer in a specific instrument
```sql
EXEC Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId
    @cid = 12345,
    @instrumentId = 1001,
    @startTime = '2024-01-01',
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Check if a customer's public history is accessible before calling
```sql
-- First check privacy gate
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
    WHERE CID = 12345 AND OperationTypeID = 3
) THEN 'BLOCKED' ELSE 'ACCESSIBLE' END AS PublicHistoryStatus
```

### 8.3 Compare public vs private NetProfit reporting for the same position
```sql
-- Public endpoint returns percentage; private returns dollar amount
-- Diagnostic query to see actual position fields
SELECT ps.PositionID, ps.NetProfit AS NetProfitDollars, ps.Amount,
    CASE ISNULL(ps.Amount, 0) WHEN 0 THEN 0
    ELSE 100 * ISNULL(ps.NetProfit, 0) / ISNULL(ps.Amount, 0)
    END AS NetProfitPct_PublicValue,
    ps.ActionType AS CloseReason
FROM History.PositionSlim ps WITH (NOLOCK)
WHERE ps.CID = 12345 AND ps.InstrumentID = 1001
    AND ps.MirrorID = 0
    AND (ps.OrigParentPositionID = 0 OR ps.OrigParentPositionID IS NULL)
ORDER BY ps.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId.sql*
