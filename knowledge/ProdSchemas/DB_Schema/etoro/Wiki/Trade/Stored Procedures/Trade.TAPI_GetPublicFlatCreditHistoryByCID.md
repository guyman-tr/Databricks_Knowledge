# Trade.TAPI_GetPublicFlatCreditHistoryByCID

> Trading API procedure that returns a publicly-visible paginated list of a customer's closed trading positions (both manual and copy-trade), subject to privacy restrictions. NetProfit is expressed as percentage ROI rather than absolute value.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (public closed positions, combined manual + copy, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the publicly-visible trading history for a Popular Investor's (or any customer's) profile page - the list of closed positions that any other user can view on their public profile. Because it is publicly visible, it first checks `Customer.BlockedCustomerOperations` for OperationTypeID=3 (privacy restriction): if the customer has blocked profile visibility, error 60090 is raised and no data is returned.

The result combines two types of closed positions in a single paginated result:
1. **Manual positions** (MirrorID=0, root): filtered by @startTime and a 1-year look-back cap
2. **Copy-trade positions** (MirrorID>0): no 1-year cap applied - these go back to '2019-01-01' (the "first ever mirror position created" per code comment)

The merge is achieved by staging closed mirror session IDs into `#closedMirrorAtEndTime` (includes (0,0) as a sentinel for manual positions), then INNER JOINing PositionSlim to it on `ISNULL(hp.MirrorID, 0) = hm.MirrorID`. This join both filters and enriches: copy-trade rows get `ParentCID` from the mirror record; manual rows get `ParentCID = 0` (from the sentinel row).

NetProfit is returned as a **percentage ROI** (`100 * NetProfit / Amount`), not as an absolute dollar value. This is consistent with the public profile display which typically shows profit percentage rather than dollar amounts.

Family: `TAPI_GetPublicFlatCreditHistoryByCIDAgg` (summary stats), `TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy` (copy only), `TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual` (manual only).

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Blocks data access if the customer has restricted their profile visibility.

**Columns/Parameters Involved**: `Customer.BlockedCustomerOperations`, `OperationTypeID`, `@cid`

**Rules**:
- `IF EXISTS (SELECT CID FROM Customer.BlockedCustomerOperations WHERE CID = @cid AND OperationTypeID = 3)` - checks for a privacy restriction
- OperationTypeID = 3 = profile history visibility restriction
- `RAISERROR(60090, 16, 1)` - raises a named error code; caller should handle 60090 as "account is private"
- Check runs before any data access; no positions returned if restricted

### 2.2 Closed Mirror Session Staging

**What**: Builds the set of mirror session IDs whose history falls in the requested window, plus the manual-position sentinel.

**Columns/Parameters Involved**: `#closedMirrorAtEndTime`, `MirrorID`, `ParentCID`, `MirrorOperationID`, `ModificationDate`

**Rules**:
- `SELECT MirrorID, ParentCID INTO #closedMirrorAtEndTime FROM History.Mirror WHERE CID=@cid AND MirrorOperationID=2 AND (ModificationDate > @startTime AND ModificationDate > DATEADD(year,-1, GETUTCDATE()))` - closed mirrors (op 2) within 1 year and after @startTime; ParentCID = the Popular Investor's ID
- `INSERT INTO #closedMirrorAtEndTime (MirrorID,ParentCID) VALUES (0,0)` - sentinel row: enables manual positions to join (MirrorID=0 -> ParentCID=0)
- OPTION (RECOMPILE) on the mirror select for optimal plan generation with variable parameters

### 2.3 Dual Time-Window Filter (Manual vs Copy)

**What**: Applies different time window logic for manual vs copy-trade positions.

**Columns/Parameters Involved**: `MirrorID`, `CloseOccurred`, `@startTime`

**Rules**:
- Manual (MirrorID=0): `CloseOccurred >= @startTime AND CloseOccurred > DATEADD(year,-1, GETUTCDATE())` - must be within @startTime AND within 1 year
- Copy (MirrorID>0): `CloseOccurred > '20190101'` - only the absolute floor date applies (1-year cap does NOT apply to copy positions)
- Comment: "this date is for the first ever mirror position created" - '2019-01-01' is the floor for all copy positions ever
- Outer: `CloseOccurred > '20190101'` on all rows, then per-type conditions refined in OR branches

### 2.4 NetProfit as Percentage ROI

**What**: Returns profit as a return percentage on invested amount, not absolute dollars.

**Columns/Parameters Involved**: `NetProfit`, `Amount`

**Rules**:
- `CASE ISNULL(Amount, 0) WHEN 0 THEN 0 ELSE 100 * ISNULL(NetProfit,0) / ISNULL(Amount,0) END AS NetProfit`
- Returns: (NetProfit / Amount) * 100 = percentage return on invested amount
- Amount=0 guard prevents division by zero (returns 0 in that case)
- Positive = profitable close, negative = loss, 0 = break-even or zero amount

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID whose public history is being retrieved. Privacy check runs against this CID first. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the look-back window. Manual positions: must also be within 1 year. Copy positions: floor is '2019-01-01' regardless of @startTime. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. Number of position rows returned per page. |

### Output - Closed Positions (Combined Manual + Copy)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. Matches @cid for all rows. |
| 3 | ParentPositionID | INT | NO | 0 | CODE-BACKED | Parent position in copy tree. 0 = root position. ISNULL defaults NULL to 0. |
| 4 | ParentCID | INT | NO | 0 | CODE-BACKED | For copy positions: the Popular Investor's CID (from History.Mirror). For manual positions: 0 (from sentinel row). ISNULL defaults NULL to 0. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. FK to Trade.Instrument. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1=Long/Buy, 0=Short/Sell. |
| 7 | CloseReason | INT | YES | - | CODE-BACKED | Alias for ActionType. Close reason code. FK to Dictionary.ClosePositionActionType (0=Customer, 1=Stop Loss, 5=Take Profit, 9=Hierarchical Close). |
| 8 | OpenRate | DECIMAL | NO | - | CODE-BACKED | Alias for InitForexRate. Opening price rate. |
| 9 | OpenDateTime | DATETIME | NO | - | CODE-BACKED | Alias for InitDateTime. When position was opened. |
| 10 | CloseRate | DECIMAL | YES | - | CODE-BACKED | Alias for EndForexRate. Closing price rate. |
| 11 | CloseDateTime | DATETIME | NO | - | CODE-BACKED | Alias for CloseOccurred. When position was closed. Sort key (ORDER BY DESC). |
| 12 | MirrorID | INT | NO | 0 | CODE-BACKED | Copy session ID. 0 = manual position; positive = copy-trade session. ISNULL treated as 0 via join. |
| 13 | NetProfit | DECIMAL | NO | 0 | CODE-BACKED | **Percentage ROI**: (NetProfit / Amount) * 100. NOT absolute profit. Positive = gain, negative = loss. 0 when Amount is NULL or 0. |
| 14 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier used. |
| 15 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check before any data access |
| CID, MirrorID, MirrorOperationID, ModificationDate, ParentCID | History.Mirror | Lookup (READ) | Staged into #closedMirrorAtEndTime; provides ParentCID for copy positions |
| CID, MirrorID, CloseOccurred, PositionID | History.PositionSlim | Lookup (READ) | Source of all closed position data |
| ActionType | Dictionary.ClosePositionActionType | Implicit FK | Close reason lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg` (aggregate stats), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy` (copy-only), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual` (manual-only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicFlatCreditHistoryByCID (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check (OperationTypeID=3) |
| History.Mirror | Table (cross-schema) | Closed mirror session staging (#closedMirrorAtEndTime) with ParentCID |
| History.PositionSlim | Table (cross-schema) | Source of closed position data |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table `#closedMirrorAtEndTime`: heap, no indexes. Small result set (one row per closed mirror session + 1 sentinel).

### 7.2 Constraints

None. Key behavioral characteristics:
- Raises error 60090 if OperationTypeID=3 privacy block exists - no partial data returned
- Dual time-window logic: 1-year cap for manual, '2019-01-01' floor for copy
- NetProfit is ROI percentage, NOT absolute profit
- OPTION (RECOMPILE) on mirror staging SELECT
- WITH (NOLOCK) on all history tables
- Paginated: OFFSET/FETCH pattern

---

## 8. Sample Queries

### 8.1 Get public history page 1

```sql
EXEC Trade.TAPI_GetPublicFlatCreditHistoryByCID
    @cid = 12345,
    @startTime = DATEADD(month, -6, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview copy-trade positions in the combined result

```sql
-- Copy positions: no 1-year cap, floor at 2019-01-01
SELECT
    hp.PositionID,
    hp.CID,
    hm.ParentCID,
    hp.InstrumentID,
    hp.CloseOccurred,
    hp.MirrorID,
    CASE ISNULL(hp.Amount,0) WHEN 0 THEN 0
        ELSE 100 * ISNULL(hp.NetProfit,0) / ISNULL(hp.Amount,0) END AS NetProfitPct
FROM History.PositionSlim hp WITH (NOLOCK)
JOIN History.Mirror hm WITH (NOLOCK)
    ON hm.MirrorID = hp.MirrorID AND hm.CID = hp.CID AND hm.MirrorOperationID = 2
WHERE hp.CID = 12345
    AND hp.MirrorID > 0
    AND hp.CloseOccurred > '20190101'
ORDER BY hp.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicFlatCreditHistoryByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCID.sql*
