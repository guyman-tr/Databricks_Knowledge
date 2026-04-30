# Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId

> Trading API procedure that returns paginated mirror session history as two result sets: (1) money flow events and mirror state changes, (2) closed copy-trade positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @mirrorId INT (mirror session scope, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the detail view for a specific copy-trading session (mirror). When a customer drills into one of their past copy relationships - "I copied Trader X from Jan to Aug" - this procedure provides the full timeline: every deposit/withdrawal made to/from the copy allocation, every copy-trade position that was closed within the session, and any special mirror state events (pauses, resumes).

The procedure solves a complex pagination challenge: two fundamentally different data types (balance credits from `History.Credit` and closed positions from `History.PositionSlim`) need to be merged into a single chronological, paginated timeline. The solution stages them into a unified temp table `#t` ordered by `Occurred DESC` with OFFSET/FETCH pagination, then queries from `#t` to produce two separate result sets:

- **Result Set 1**: Money flow events (deposits to mirror, withdrawals from mirror, dividends) and mirror state changes (pauses, resumes), excluding position-closing credits
- **Result Set 2**: Full position details for each closed copy position, by joining `#t` (filtered to position-closing credit types 4, 22, 24) with `History.PositionSlim`

The procedure also resolves `@parentCid` (the Popular Investor's CID) from the mirror's original creation record (`MirrorOperationID = 1`) in `History.Mirror`.

---

## 2. Business Logic

### 2.1 Unified Timeline Staging in #t

**What**: Merges credit events and mirror state changes into a single temp table before paginating.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`, `@startTime`, `CreditTypeID`, `MirrorOperationID`

**Rules**:
- First branch (IsCredit=1): History.Credit WHERE CID=@cid AND MirrorID=@mirrorId AND CreditTypeID IN (4, 18, 19, 20, 21, 22, 24, 27)
  - CreditTypeID 4 = Close Position (position P&L credit)
  - CreditTypeID 18 = Account balance to mirror (copy session deposit)
  - CreditTypeID 19 = Mirror balance to account (money out of copy session)
  - CreditTypeID 20 = Register new mirror (initial mirror allocation)
  - CreditTypeID 21 = Mirror de-allocation (withdrawal/reduction)
  - CreditTypeID 22, 24 = Mirror-related position close credits
  - CreditTypeID 27 = Mirror money movement type 10
- Second branch (IsCredit=0): History.Mirror WHERE MirrorID=@mirrorId AND CID=@cid AND MirrorOperationID IN (12, 13) - special mirror state events
- UNION ALL, sorted by Occurred DESC, OFFSET/FETCH applied to the combined set
- CIX on #t(PositionID) for the position JOIN in Result Set 2; NC IX on CreditTypeID for Result Set 1 filter

### 2.2 Result Set 1 - Money Flows and Mirror Events

**What**: Financial events within the copy session and special mirror state changes.

**Columns/Parameters Involved**: `CreditTypeID`, `HistoryMirrorOperation`, `IsMoneyOut`, `IsCopyDividend`, `Payment`

**Rules**:
- Excludes position-closing credits (CreditTypeID NOT IN (4, 22, 24)) from the credit branch
- Includes mirror state rows (IsCredit=0) from History.Mirror MirrorOperationID 12, 13
- CreditTypeID conversion to HistoryMirrorOperation:
  - CreditTypeID 20 -> HistoryMirrorOperation 1 (deposit/start)
  - CreditTypeID 21 -> HistoryMirrorOperation 2 (withdrawal), IsMoneyOut=1
  - CreditTypeID 27 -> HistoryMirrorOperation 10, IsMoneyOut=1
  - Others (18, 19) -> HistoryMirrorOperation 3 (general cashflow)
- IsMoneyOut=1 when CreditTypeID IN (19, 21, 27) - funds flowing out of the mirror
- Payment multiplied by -1 (Payment in History.Credit is stored as negative for debits; flipping gives the positive amount)
- IsCopyDividend: 1 when MirrorDividendID is populated (dividend from a copy position)

### 2.3 Result Set 2 - Closed Copy Positions

**What**: Full position details for each copy-trade position closed within this mirror session.

**Columns/Parameters Involved**: `CreditTypeID IN (4, 22, 24)`, `PositionID`, `@parentCid`

**Rules**:
- Joins #t to History.PositionSlim ON PositionID where #t.CreditTypeID IN (4, 22, 24) and IsCredit=1
- CreditTypeIDs 4, 22, 24 are the position-closing credit types that carry a PositionID
- @parentCid resolved from History.Mirror WHERE MirrorID=@mirrorId AND MirrorOperationID=1 (original open record)
- Result set is identical in structure to the position list from TAPI_GetHistoryPositionsByCidAndInstrumentId, but here ParentCID = @parentCid (the Popular Investor's real CID, not hardcoded 0)
- Sorted by CloseOccurred DESC

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). All data scoped to this customer within the specified mirror session. |
| 2 | @mirrorId | INT | NO | - | CODE-BACKED | Mirror session ID. Identifies the specific copy relationship whose history is being retrieved. FK to History.Mirror.MirrorID and History.Credit.MirrorID. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start of the time window. Applies to both Credit.Occurred and Mirror.ModificationDate. When NULL: all history for this mirror session. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. Applied to the unified timeline (credits + mirror events combined). |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size for the unified timeline. Both result sets are derived from the same paginated #t temp table. |

### Output - Result Set 1 (Money Flow Events and Mirror State Changes)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HistoryMirrorOperation | INT | NO | - | CODE-BACKED | Standardized mirror operation type for display. Derived from CreditTypeID (for credit rows) or MirrorOperationID (for mirror state rows). Values: 1=Deposit/register, 2=Withdrawal/de-alloc, 3=General cashflow (types 18,19), 10=Mirror money type 27, 12/13=Mirror state events. Converts Dictionary.CreditType values to Dictionary.MirrorOperation values. |
| 2 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp of the event. From Credit.Occurred for cashflow rows, Mirror.ModificationDate for mirror state rows. Timeline sort key. |
| 3 | MirrorAmountDelta | DECIMAL | NO | - | CODE-BACKED | Amount of money that moved (Payment * -1). Positive = money flowing in direction of the event. Credit.Payment is stored as negative for debits, so inversion gives the display amount. |
| 4 | IsMoneyOut | BIT | NO | - | CODE-BACKED | 1 = funds left the mirror allocation (withdrawal, de-allocation, type 27 outflow). 0 = funds entered or neutral event. Derived from CreditTypeID IN (19, 21, 27). Mirror state rows always 0. |
| 5 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 = this cashflow event is a dividend received on a copy position (MirrorDividendID is populated). 0 = standard cashflow. Only non-zero for credit rows with MirrorDividendID set. Mirror state rows always 0. |

### Output - Result Set 2 (Closed Copy Positions within this Mirror)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-34 | (Same columns as TAPI_GetHistoryPositionsByCidAndInstrumentId output) | - | - | CODE-BACKED | Identical position field set. Key difference: ParentCID = @parentCid (the Popular Investor's CID, resolved from History.Mirror MirrorOperationID=1). Only positions with CreditTypeID IN (4, 22, 24) in #t are included - these are position-closing credits that carry a PositionID linking back to the position. |

Notable difference from TAPI_GetHistoryPositionsByCidAndInstrumentId:
- **ParentCID**: `ISNULL(@parentCid, 0)` - populated from History.Mirror's original creation record. Non-zero identifies the Popular Investor.
- **MirrorID filter**: `hp.MirrorID = @mirrorId` instead of `MirrorID = 0` - returns copy positions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, CreditTypeID | History.Credit | Lookup (READ) | Source of all financial events within the mirror session |
| MirrorID, CID, MirrorOperationID | History.Mirror | Lookup (READ) | Source of mirror state events (pause/resume) and @parentCid resolution |
| CID, MirrorID, PositionID | History.PositionSlim | Lookup (READ) | Source of closed position details (Result Set 2), joined via #t |
| CreditTypeID | Dictionary.CreditType | Implicit FK | Classifies each financial event type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg` (summary), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows` (cashflows only), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy` (positions only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId (procedure)
├── History.Credit (table - cross-schema)
├── History.Mirror (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Financial event data for the mirror session |
| History.Mirror | Table (cross-schema) | Mirror state events and @parentCid lookup |
| History.PositionSlim | Table (cross-schema) | Closed position details for Result Set 2 |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table indexes created within the procedure:
- `CIX ON #t(PositionID)` - clustered index; enables efficient JOIN to History.PositionSlim for Result Set 2
- `IX ON #t(CreditTypeID)` - nonclustered; enables efficient WHERE CreditTypeID IN (...) filtering for both result sets

### 7.2 Constraints

None. Key behavioral characteristics:
- TWO result sets returned in sequence (applications must read both)
- Pagination applied to the unified #t set; Result Set 2 may contain fewer rows than @itemsPerPage (only the position-closing rows from the page are included)
- @parentCid is NULL when History.Mirror has no record with MirrorOperationID=1 for this mirrorId (edge case); ISNULL converts to 0

---

## 8. Sample Queries

### 8.1 Retrieve full mirror history timeline, first page

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Retrieve timeline with a date filter

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = DATEADD(MONTH, -6, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.3 Preview cashflow credits for a mirror session directly

```sql
SELECT
    hc.CreditTypeID,
    hc.Payment,
    hc.Occurred,
    CASE hc.CreditTypeID WHEN 20 THEN 1 WHEN 21 THEN 2 WHEN 27 THEN 10 ELSE 3 END AS HistoryMirrorOperation,
    CASE WHEN hc.CreditTypeID IN (19,21,27) THEN 1 ELSE 0 END AS IsMoneyOut
FROM History.Credit hc WITH (NOLOCK)
WHERE hc.CID = 12345
    AND hc.MirrorID = 67890
    AND hc.CreditTypeID IN (18, 19, 20, 21, 27)
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId.sql*
