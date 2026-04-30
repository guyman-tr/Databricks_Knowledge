# Trade.TAPI_GetHistoryMirrorByCidAndParentCid

> Trading API procedure that returns a paginated list of closed copy-trading relationships (mirrors) between a customer and a specific Popular Investor, including financial performance summaries and accumulated fees per mirror.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @parentCid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TAPI procedure powers the detailed history view for a customer's copy trading relationship with a specific Popular Investor (trader). When a customer views the history of their copy trading with "trader X", this procedure returns the paginated list of all individual copy sessions (mirrors) the customer had with that trader - each with its own financial summary: how much was invested, what profit/loss was made, how many deposits and withdrawals were made to the copy, and the accumulated holding fees.

Each row represents one complete copy session - a period during which the customer was copying trader X, from `Occurred` (start) to `ModificationDate` (end, when the copy was closed with MirrorOperationID=2).

The procedure is the paginated counterpart to `Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg` which returns the aggregate totals across all sessions with the same trader.

---

## 2. Business Logic

### 2.1 Closed Mirror Sessions Filter

**What**: Returns only completed copy sessions (closed mirrors).

**Columns/Parameters Involved**: `MirrorOperationID`, `CID`, `ParentCID`, `ModificationDate`

**Rules**:
- `MirrorOperationID = 2`: Only closed mirror records (MirrorOperationID=2 = mirror closed event in History.Mirror)
- `CID = @cid`: The customer who was copying
- `ParentCID = @parentCid`: The specific Popular Investor being copied
- `ModificationDate >= @startTime OR @startTime IS NULL`: The session ended within the time window
- Ordered by `ID DESC` (newest sessions first), paginated with OFFSET/FETCH

### 2.2 Accumulated Fees Aggregation

**What**: CTE computes total holding fees from all positions closed within each mirror.

**Columns/Parameters Involved**: `History.Position.EndOfWeekFee`, `MirrorID`

**Rules**:
- `closedPositionFees` CTE: SUM(EndOfWeekFee) per MirrorID from History.Position for this customer
- ISNULL(..., 0) ensures 0 when a mirror had no positions or no fees
- LEFT JOIN to the CTE on MirrorID to attach TotalFees to each mirror record

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. The customer who was copying. |
| 2 | @parentCid | INT | NO | - | CODE-BACKED | The Popular Investor CID being copied. Filters to only mirror sessions with this specific trader. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional time filter on mirror close date (ModificationDate >= @startTime). When NULL: returns all closed mirrors with this trader. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Closed Mirror Sessions - Paginated)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | INT | NO | - | CODE-BACKED | Unique identifier for this copy session. FK to History.Mirror.MirrorID. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID who was copying (same as @cid). |
| 3 | AvailableAmount | MONEY | YES | - | CODE-BACKED | Amount allocated to the copy at time of closure. From History.Mirror.Amount. |
| 4 | StopLossAmount | MONEY | NO | - | CODE-BACKED | Stop-loss dollar threshold set on this copy. ISNULL-defaulted to 0. |
| 5 | StopLossPercentage | DECIMAL | NO | - | CODE-BACKED | Stop-loss percentage threshold. ISNULL-defaulted to 0. |
| 6 | IsPaused | BIT | NO | - | CODE-BACKED | Whether the copy was paused at time of closure. ISNULL-defaulted to 0. |
| 7 | CopyExistingPositions | BIT | NO | - | CODE-BACKED | Whether the customer opted to copy the trader's existing open positions when starting the copy. From History.Mirror.IsOpenOpen. ISNULL-defaulted to 0. |
| 8 | InitialInvestment | MONEY | NO | - | CODE-BACKED | The initial amount allocated when the copy was first started. ISNULL-defaulted to 0. |
| 9 | DepositSummary | MONEY | NO | - | CODE-BACKED | Total additional deposits made into this copy session after the initial investment. ISNULL-defaulted to 0. |
| 10 | WithdrawalSummary | MONEY | NO | - | CODE-BACKED | Total withdrawals made from this copy session. ISNULL-defaulted to 0. |
| 11 | ParentUserName | NVARCHAR | YES | - | CODE-BACKED | The username of the Popular Investor being copied. From History.Mirror.ParentUserName. |
| 12 | ClosedPositionsNetProfit | MONEY | NO | - | CODE-BACKED | Total net profit from all positions closed within this copy session. From History.Mirror.NetProfit. ISNULL-defaulted to 0. |
| 13 | StartedCopyDate | DATETIME | NO | - | CODE-BACKED | When the customer started this copy session. From History.Mirror.Occurred. |
| 14 | EndedCopyDate | DATETIME | YES | - | CODE-BACKED | When the customer ended (closed) this copy session. From History.Mirror.ModificationDate. |
| 15 | ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor CID (same as @parentCid). |
| 16 | TotalFees | MONEY | NO | - | CODE-BACKED | Total holding fees (EndOfWeekFee) accumulated across all positions in this copy session. Aggregated from History.Position via closedPositionFees CTE. ISNULL-defaulted to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, ParentCID, MirrorOperationID | History.Mirror | Lookup (READ) | Source for closed copy session records |
| CID, MirrorID | History.Position | Lookup (CTE aggregation) | Computes accumulated holding fees (TotalFees) per mirror |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account. Companion to `Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg` (aggregation).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryMirrorByCidAndParentCid (procedure)
├── History.Mirror (table - cross-schema)
└── History.Position (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table (cross-schema) | Primary source: closed mirror session records with financial summaries |
| History.Position | Table (cross-schema) | CTE: aggregate EndOfWeekFee per MirrorID |

### 6.2 Objects That Depend On This

No SQL dependents found. Companion: `Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg`. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Note: the @startTime filter applies to `ModificationDate` (when the mirror was closed), not to the mirror's start date (`Occurred`). This means sessions that started before @startTime but closed after it are included.

---

## 8. Sample Queries

### 8.1 Get copy history with a specific trader

```sql
EXEC Trade.TAPI_GetHistoryMirrorByCidAndParentCid
    @cid = 12345,
    @parentCid = 67890,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview closed mirrors directly

```sql
SELECT TOP 10
    hm.MirrorID,
    hm.CID,
    hm.ParentCID,
    hm.ParentUserName,
    hm.Amount AS AvailableAmount,
    hm.InitialInvestment,
    ISNULL(hm.NetProfit, 0) AS ClosedPositionsNetProfit,
    hm.Occurred AS StartedCopyDate,
    hm.ModificationDate AS EndedCopyDate
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.CID = 12345
    AND hm.ParentCID = 67890
    AND hm.MirrorOperationID = 2
ORDER BY hm.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryMirrorByCidAndParentCid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryMirrorByCidAndParentCid.sql*
