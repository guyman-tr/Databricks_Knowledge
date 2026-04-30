# Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy

> Trading API procedure that returns a paginated list of closed copy-trade positions within a specific mirror session, ordered by most recently closed first.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @mirrorId INT (copy positions only, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the positions-only filter variant within the mirror history family. It returns the paginated list of individual closed copy-trade positions within a specific mirror session - the "Copy" tab in the mirror detail view that shows all trades that were copied from the Popular Investor.

The filter uses `MirrorID = @mirrorId` directly on `History.PositionSlim` - unlike the cashflows filter which reads `History.Credit`, this goes directly to the positions table. The `@startTime` filter here applies to `CloseOccurred` (when each position closed), not to a credit event timestamp.

The result set structure is identical to `TAPI_GetHistoryPositionsByCidAndInstrumentId` and Result Set 2 of `TAPI_GetMirrorHistoryWithCIDAndMirrorId`, with the key difference that `ParentCID` is populated from the mirror's creation record (`@parentCid` from `History.Mirror WHERE MirrorOperationID = 1`), identifying the Popular Investor being copied.

---

## 2. Business Logic

### 2.1 Copy Positions Filter (MirrorID = @mirrorId)

**What**: Returns all positions that were part of the specified copy session.

**Columns/Parameters Involved**: `@mirrorId`, `MirrorID`, `@cid`, `CloseOccurred`, `@startTime`

**Rules**:
- `WHERE CID = @cid AND MirrorID = @mirrorId` - only positions belonging to this specific copy session
- `AND (@startTime IS NULL OR CloseOccurred >= @startTime)` - optional date filter on position close date
- Ordered by `CloseOccurred DESC` - most recently closed position appears first
- MirrorID > 0 is implied (a specific mirrorId is provided); contrast with FilterByInstruments which uses MirrorID=0

### 2.2 ParentCID Resolution

**What**: Identifies the Popular Investor being copied for display in the position list.

**Columns/Parameters Involved**: `@parentCid`, `ParentCID`, `MirrorOperationID`

**Rules**:
- `SELECT @parentCid = ParentCID FROM History.Mirror WHERE MirrorID = @mirrorId AND MirrorOperationID = 1`
- MirrorOperationID = 1 is the original mirror creation record which stores the ParentCID
- ISNULL(@parentCid, 0) in the SELECT - returns 0 if no creation record found
- ParentCID in the result set identifies who the copier was following

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Scopes position results to this customer's copy trades. |
| 2 | @mirrorId | INT | NO | - | CODE-BACKED | Mirror session ID. Only positions opened as part of this copy session are returned. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start filter on CloseOccurred. When NULL: all closed positions for this mirror. When provided: only positions closed on or after @startTime. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of position rows per page. |

### Output - Closed Copy-Trade Positions

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Amount | DECIMAL | NO | - | CODE-BACKED | Invested amount in USD for this copy position. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID (copier). Always matches @cid. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument traded by the Popular Investor and copied. FK to Trade.InstrumentMetaData. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1=Buy/Long, 0=Sell/Short. Copied from the leader's position direction. |
| 5 | Leverage | INT | NO | - | CODE-BACKED | Leverage used by the Popular Investor's position (copied). |
| 6 | InitDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the copy position was opened. |
| 7 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Opening rate of the instrument when the copy position was opened. |
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. |
| 9 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop-Loss rate for this copy position. NULL if none. |
| 10 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take-Profit rate for this copy position. NULL if none. |
| 11 | AmountInUnitsDecimal | DECIMAL | NO | 0 | CODE-BACKED | Position size in instrument units. ISNULL defaults NULL to 0. |
| 12 | EndOfWeekFee | DECIMAL | YES | - | CODE-BACKED | Overnight/weekend holding fee for this copy position. |
| 13 | InitialAmountInDollars | DECIMAL | NO | - | CODE-BACKED | Original invested amount in USD. Derived: InitialAmountCents / 100. |
| 14 | OrderID | INT | NO | 0 | CODE-BACKED | Pending order ID: 0 = not from a pending order. ISNULL defaults NULL to 0. |
| 15 | ParentPositionID | BIGINT | NO | 0 | CODE-BACKED | Parent position in copy tree hierarchy. 0 = no parent. ISNULL defaults NULL to 0. |
| 16 | MirrorID | INT | NO | 0 | CODE-BACKED | Copy session ID. Matches @mirrorId. ISNULL defaults NULL to 0. |
| 17 | ActionType | INT | NO | - | CODE-BACKED | Reason the position was closed. FK to Dictionary.ClosePositionActionType. |
| 18 | NetProfit | DECIMAL | YES | - | CODE-BACKED | Realized P&L for this copy position in USD. |
| 19 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Closing rate of the instrument when the copy position was closed. |
| 20 | CloseOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the copy position was closed. Sort key (DESC). |
| 21 | ParentCID | INT | NO | 0 | CODE-BACKED | The Popular Investor's customer ID. Resolved from History.Mirror MirrorOperationID=1. Non-zero for copy positions (distinguishes from manual trades where ParentCID=0). |
| 22 | IsSettled | BIT | NO | - | CODE-BACKED | Legacy settlement type: 1=real stock, 0=CFD. Inherited from the copy position. |
| 23 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type. FK to Dictionary.SettlementTypes. |
| 24 | RedeemStatus | INT | NO | 0 | CODE-BACKED | Redemption status: 0=not a redemption close. ISNULL defaults NULL to 0. |
| 25 | OriginalPositionID | BIGINT | NO | - | CODE-BACKED | Original position ID before any reopen/split. Falls back to PositionID via ISNULL. |
| 26 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | Unit count at copy position open time. |
| 27 | OpenActionType | INT | YES | - | CODE-BACKED | Reason/method the copy position was opened. FK to Dictionary.OpenPositionActionType. |
| 28 | CloseTotalFees | DECIMAL | YES | - | CODE-BACKED | Fees charged at close for this copy position. |
| 29 | CloseTotalTaxes | DECIMAL | YES | - | CODE-BACKED | Taxes at close. |
| 30 | OpenTotalFees | DECIMAL | YES | - | CODE-BACKED | Fees charged at open. |
| 31 | OpenTotalTaxes | DECIMAL | YES | - | CODE-BACKED | Taxes at open. |
| 32 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |
| 33 | InitialLotCount | DECIMAL | YES | - | CODE-BACKED | Lot count at open time. |
| 34 | OriginalOpenActionType | INT | YES | - | CODE-BACKED | Open action type from original position (before reopen). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of all copy position data for this mirror session |
| MirrorID, MirrorOperationID | History.Mirror | Lookup (READ) | @parentCid resolution from original mirror creation record |
| InstrumentID | Trade.InstrumentMetaData | Implicit FK | Identifies the traded asset |
| ActionType | Dictionary.ClosePositionActionType | Implicit FK | Position close reason |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId` (full two-result-set), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg` (summary), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows` (cashflows only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy (procedure)
├── History.PositionSlim (table - cross-schema)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Source of all copy position data for this mirror session |
| History.Mirror | Table (cross-schema) | @parentCid lookup (MirrorOperationID=1 = original creation record) |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables.

### 7.2 Constraints

None. Key behavioral characteristics:
- Single result set (positions only - no cashflow events)
- @startTime filter applies to CloseOccurred (not Credit.Occurred as in FilterByCashflows)
- WITH (NOLOCK) on both History tables
- @parentCid can be NULL if History.Mirror has no MirrorOperationID=1 record - ISNULL converts to 0 in output

---

## 8. Sample Queries

### 8.1 Get copy positions for a mirror session, first page

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get copy positions from last 6 months

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = DATEADD(MONTH, -6, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.3 Preview copy positions for a mirror directly

```sql
SELECT TOP 10
    hp.PositionID,
    hp.InstrumentID,
    hp.NetProfit,
    hp.ActionType,
    hp.CloseOccurred,
    hm.ParentCID
FROM History.PositionSlim hp WITH (NOLOCK)
JOIN History.Mirror hm WITH (NOLOCK)
    ON hm.MirrorID = hp.MirrorID AND hm.MirrorOperationID = 1
WHERE hp.CID = 12345
    AND hp.MirrorID = 67890
ORDER BY hp.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy.sql*
