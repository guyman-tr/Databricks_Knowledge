# Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId

> Public variant of the mirror session history procedure: returns two result sets (money flow events and closed positions) for a specific copy session, subject to privacy restrictions and a 1-year look-back cap.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @mirrorId INT (public mirror detail, two result sets, 1-year cap) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the publicly-visible counterpart of `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId`. It powers the copy session detail page on a customer's public profile - when a visitor clicks on a specific copy relationship to see its history. The "Public" prefix means this is visible to other users; hence the OperationTypeID=3 privacy check.

Like its private counterpart, it returns two result sets:
1. **Money flow events** (cashflows, mirror state changes) - excluding position-closing credits
2. **Closed positions** within the mirror session

Key differences from the private version:
- **Privacy check**: RAISERROR(60090) if OperationTypeID=3 is blocked
- **1-year cap**: `Occurred > DATEADD(year,-1, GETUTCDATE())` applied to the #t staging; private version has no cap
- **No MirrorAmountDelta**: RS1 omits the payment amount column (public view doesn't show specific amounts)
- **No temp table indexes**: Private version creates CIX on PositionID and IX on CreditTypeID; this version does not

Note: if @startTime is NULL (the default), the condition `Occurred >= NULL` is UNKNOWN and the #t table will be empty, producing empty result sets. In practice callers always pass a @startTime.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Blocks access if customer has restricted profile visibility.

**Rules**: `IF EXISTS (SELECT CID FROM Customer.BlockedCustomerOperations WHERE CID=@cid AND OperationTypeID=3) RAISERROR(60090, 16, 1)` - same pattern as all Public family members.

### 2.2 ParentCID Resolution

**What**: Identifies the Popular Investor being copied.

**Rules**:
- `SELECT @parentCid = ParentCID FROM History.Mirror WHERE MirrorID=@mirrorId AND MirrorOperationID=1` - from the original mirror creation record
- `ISNULL(@parentCid, 0)` in RS2 - returns 0 if no creation record found

### 2.3 Credit Event Staging in #t (with 1-Year Cap)

**What**: Stages paginated credit events into temp table for dual result set output.

**Columns/Parameters Involved**: `#t`, `@startTime`, `@offsetRows`, `CreditTypeID`

**Rules**:
- `FROM History.Credit WHERE CID=@cid AND MirrorID=@mirrorId AND CreditTypeID IN (4,18,19,20,21,22,24,27)` - all mirror-related credit types
- `AND (Occurred >= @startTime AND Occurred > DATEADD(year,-1, GETUTCDATE()))` - must be after @startTime AND within 1 year (private version has no 1-year cap)
- OFFSET/FETCH pagination applied during staging
- `IsCopyDividend = CASE ISNULL(MirrorDividendID,0) WHEN 0 THEN 0 ELSE 1 END` - flags dividend credits

### 2.4 Result Set 1 - Money Flow Events (No Amount)

**What**: Returns cashflow and mirror state events, excluding position-closing rows.

**Rules**:
- `FROM #t WHERE CreditTypeID NOT IN (4, 22, 24)` - excludes position-closing credits
- No `MirrorAmountDelta` (Payment*-1) column - public view omits specific payment amounts
- Includes: IsMoneyOut, HistoryMirrorOperation, Occurred, IsCopyDividend
- Ordered by CreditID DESC (same as staging order)

### 2.5 Result Set 2 - Closed Copy Positions (NetProfit as %)

**What**: Returns closed positions joined from History.PositionSlim.

**Rules**:
- `INNER JOIN #t ON hp.PositionID = temp.PositionID WHERE temp.CreditTypeID IN (4,22,24)` - position-closing rows only
- Same 15-column structure as TAPI_GetPublicFlatCreditHistoryByCID
- NetProfit = percentage ROI: `100 * NetProfit / Amount`
- ParentCID = `ISNULL(@parentCid, 0)` for all rows

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Privacy check runs first. |
| 2 | @mirrorId | INT | NO | - | CODE-BACKED | Mirror session ID. Identifies the specific copy relationship. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Start of time window. Also subject to 1-year hard cap. When NULL: #t staging returns empty (null comparison). Callers should always pass a value. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number applied to the unified #t staging. |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size for #t staging. |

### Output - Result Set 1 (Money Flow Events)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IsMoneyOut | BIT | NO | - | CODE-BACKED | 1 = outflow (CreditTypeID IN 19,21,27). 0 = inflow or neutral. |
| 2 | HistoryMirrorOperation | INT | NO | - | CODE-BACKED | Mirror operation type: 1=register/deposit (type 20), 2=withdrawal (type 21), 10=money type 27, 3=general cashflow (types 18,19). |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Event timestamp. Sort key (CreditID DESC). |
| 4 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 = dividend from a copy position (MirrorDividendID is set). 0 = regular cashflow. |

Note: MirrorAmountDelta (payment amount) is NOT returned in the public variant - only the private variant returns payment amounts.

### Output - Result Set 2 (Closed Copy Positions)

Same 15-column structure as `Trade.TAPI_GetPublicFlatCreditHistoryByCID` output (PositionID, CID, ParentPositionID, ParentCID, InstrumentID, IsBuy, CloseReason, OpenRate, OpenDateTime, CloseRate, CloseDateTime, MirrorID, NetProfit as %, Leverage, LotCountDecimal).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| MirrorID, MirrorOperationID, ParentCID | History.Mirror | Lookup (READ) | @parentCid resolution (MirrorOperationID=1) |
| CID, MirrorID, CreditTypeID, Occurred | History.Credit | Lookup (READ) | Staged into #t for both result sets |
| CID, MirrorID, PositionID | History.PositionSlim | Lookup (READ) | RS2 position details via JOIN to #t |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg` (summary), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId` (private equivalent).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── History.Credit (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | @parentCid lookup (MirrorOperationID=1) |
| History.Credit | Table (cross-schema) | Mirror event staging in #t (paginated) |
| History.PositionSlim | Table (cross-schema) | RS2 closed position details |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table `#t`: heap (no CIX or IX unlike the private equivalent).

### 7.2 Constraints

None. Key behavioral characteristics:
- TWO result sets returned (applications must read both)
- Privacy check raises 60090 before any data access
- 1-year cap applied during #t staging (private version has no cap)
- @startTime=NULL -> empty #t -> empty both result sets
- No MirrorAmountDelta in RS1 (public omits payment amounts)
- WITH (NOLOCK) on all history tables

---

## 8. Sample Queries

### 8.1 Get public mirror session history

```sql
EXEC Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = DATEADD(year, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId.sql*
