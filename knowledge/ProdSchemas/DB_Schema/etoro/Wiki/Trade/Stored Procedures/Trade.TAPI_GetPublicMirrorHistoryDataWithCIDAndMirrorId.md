# Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId

> Public variant of the mirror session detail view: given a MirrorID, returns two paginated result sets showing (1) cashflow events in the copy session and (2) closed copy positions, with NetProfit as a percentage. CID is derived internally from the MirrorID rather than passed by the caller.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID INT (copy session scope, CID resolved internally, two result sets) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the detail view for a specific copy-trading session on a user's public profile. When a visitor views another user's public portfolio and clicks on a copy session (a mirror relationship with a Popular Investor), this procedure provides the full timeline: every cashflow event (deposits to/from the copy allocation, dividends) and every copy-trade position that was closed within the session.

The key architectural difference from the private variant (`TAPI_GetMirrorHistoryWithCIDAndMirrorId`) is that the caller provides only `@MirrorID` - the CID is resolved internally by looking up `Trade.Mirror` (active sessions) or falling back to `History.Mirror` (closed sessions). This design allows the public profile API to request history by mirror session without needing to pass the account owner's CID. Two additional safety checks are applied before data is returned: a negative `RealizedEquity` guard (60088) and the standard public history privacy block (60090).

The procedure uses a unified `#t` staging temp table to paginate the combined cashflow + position-close credit stream, then produces two result sets from it - cashflow events (RS1) and position details (RS2) - allowing the public timeline UI to render both in one API call.

Note: `TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest` is an identical copy of this procedure (same SQL body), preserved for testing purposes.

---

## 2. Business Logic

### 2.1 CID Resolution from MirrorID

**What**: Derives the account owner's CID from the mirror session, avoiding the need for the caller to supply it.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `@ParentCID`, `@RealizedEquity`

**Rules**:
- Primary lookup: `Trade.Mirror JOIN Customer.Customer ON CID` WHERE MirrorID=@MirrorID
  - Fetches @CID (the copier), @ParentCID (the Popular Investor), @RealizedEquity (equity amount used for MirrorAmountDelta calculation)
  - ISNULL(@RealizedEquity, 0) - defaults to 0 if not set
  - ISNULL(@ParentCID, 0) - defaults to 0 if no parent (unusual)
- Fallback: if @CID IS NULL (mirror no longer in Trade.Mirror - session closed and removed), queries `History.Mirror TOP 1 CID WHERE MirrorID=@MirrorID`
- This two-step CID resolution ensures both active and fully-closed historical sessions can be accessed

```
@MirrorID
    |
    v
Trade.Mirror JOIN Customer.Customer
    |-- CID found --> use it + load @RealizedEquity, @ParentCID
    |-- CID = NULL --> fallback: History.Mirror TOP 1 CID
```

### 2.2 Pre-Data Guards

**What**: Two checks that abort execution before any data is returned.

**Columns/Parameters Involved**: `@RealizedEquity`, `@CID`

**Rules**:
- Guard 1: `IF @RealizedEquity < 0 -> RAISERROR(60088, 16, 1)` - negative RealizedEquity (e.g., customer in drawdown) blocks the public view; equity must be >= 0 for public disclosure
- Guard 2: `IF EXISTS (Customer.BlockedCustomerOperations WHERE CID=@CID AND OperationTypeID=3) -> RAISERROR(60090, 16, 1)` - standard public history block. Note: the code comment acknowledges 60090 may need a distinct error code for the privacy case vs the equity case.

### 2.3 Unified Timeline Staging (#t)

**What**: Stages the paginated slice of History.Credit for this mirror into a temp table.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `@StartTime`, `CreditTypeID`

**Rules**:
- Source: `History.Credit WHERE MirrorID=@MirrorID AND CID=@CID AND CreditTypeID IN (4,18,19,20,21,22,24,27) AND (Occurred >= @StartTime OR @StartTime IS NULL)`
- CreditTypeID filter includes:
  - 4 = Close Position (P&L credit for a closed copy position)
  - 18 = Account balance to mirror (money deposited into copy session)
  - 19 = Mirror balance to account (money withdrawn from copy session)
  - 20 = Register new mirror (initial allocation / copy start)
  - 21 = Mirror de-allocation (partial withdrawal / reduction)
  - 22, 24 = Mirror position close credits (additional position-related credit types)
  - 27 = Mirror money movement (type 10 cashflow)
- `ORDER BY CreditID DESC OFFSET/FETCH` pagination applied here to the combined set
- `OPTION(RECOMPILE)` - prevents bad plan caching due to parameter sensitivity

### 2.4 Result Set 1 - Cashflow Events

**What**: Cashflow events and mirror operations visible on the public session timeline.

**Columns/Parameters Involved**: `CreditTypeID`, `Payment`, `@RealizedEquity`

**Rules**:
- Source: `#t WHERE CreditTypeID NOT IN (4,22,24)` - excludes position-closing credits (those go to RS2)
- Remaining types 18,19,20,21,27 represent money flows and mirror state changes
- `IsMoneyOut = 1` when CreditTypeID IN (19,21,27) - funds leaving the copy session
- `HistoryMirrorOperation` mapping: 20->1 (new copy/deposit), 21->2 (withdrawal), 27->10 (special), else->3 (general cashflow/dividend)
- `MirrorAmountDelta = (Payment / @RealizedEquity) * -100` - expresses the cashflow as a percentage of realized equity, negated (Payment in History.Credit is negative for debits; negating makes the delta positive for money-out events). 0 when @RealizedEquity=0.

### 2.5 Result Set 2 - Closed Copy Positions

**What**: Full position details for each copy-trade position closed within this session.

**Columns/Parameters Involved**: `CreditTypeID IN (4,22,24)`, `@ParentCID`, `@MirrorID`

**Rules**:
- Source: `History.Position JOIN #t ON PositionID WHERE CreditTypeID IN (4,22,24) AND CID=@CID`
- Uses `History.Position` (full history table) - note: the private variant uses `History.PositionSlim`
- `NetProfit = (NetProfit / IIF(Amount=0,1.0,Amount)) * 100` - return as percentage; IIF(Amount=0,1.0) prevents divide-by-zero
- `ParentCID = ISNULL(@ParentCID,0)` - the Popular Investor CID resolved in step 2.1
- `@MirrorID AS MirrorID` - hardcoded to the input; all positions in this result set belong to one mirror
- `OPTION(RECOMPILE)` on position query as well

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | Copy session identifier. CID is NOT passed - it is derived internally from this ID via Trade.Mirror (active) or History.Mirror (closed sessions). |
| 2 | @StartTime | DATETIME | YES | NULL | CODE-BACKED | Optional look-back window start for History.Credit.Occurred. When NULL: all credits for this mirror session are included. |
| 3 | @PageNumber | INT | NO | - | CODE-BACKED | 1-based page number. Applied to the unified #t staging set (all credit types combined). |
| 4 | @ItemsPerPage | INT | NO | - | CODE-BACKED | Page size. Applied to the unified #t set - both result sets are derived from the same paginated slice. |

### Output - Result Set 1 (Cashflow Events and Mirror Operations)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IsMoneyOut | BIT | NO | 0 | CODE-BACKED | 1 when funds left the copy session (CreditTypeID IN 19,21,27: withdrawal, de-allocation, or mirror money movement). 0 for deposits, dividends, copy start events. |
| 2 | HistoryMirrorOperation | INT | NO | 3 | CODE-BACKED | Standardized operation code derived from CreditTypeID: 1=new copy/deposit (type 20), 2=withdrawal (type 21), 10=special movement (type 27), 3=general cashflow (types 18,19 and others). |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp of the credit event from History.Credit.Occurred. Primary sort key (CreditID DESC). |
| 4 | MirrorAmountDelta | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Cashflow expressed as percentage of customer's RealizedEquity: (Payment / @RealizedEquity) * -100. Negative Payment (debit) becomes positive delta. 0 when @RealizedEquity=0. |
| 5 | IsCopyDividend | BIT | NO | 0 | CODE-BACKED | 1 when this credit is a dividend from a copied position (History.Credit.MirrorDividendID is non-null). 0 for all other credit types. |

### Output - Result Set 2 (Closed Copy Positions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the closed copy position. FK to Trade.InstrumentMetaData. |
| 2 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1=Buy (Long), 0=Sell (Short). |
| 3 | CloseReason | INT | NO | - | CODE-BACKED | Aliased from ActionType. Reason the copy position was closed. FK to Dictionary.ClosePositionActionType. |
| 4 | OpenDateTime | DATETIME | NO | - | CODE-BACKED | Aliased from InitDateTime. When the copy position was opened. |
| 5 | OpenRate | DECIMAL | NO | - | CODE-BACKED | Aliased from InitForexRate. Exchange rate at position open. |
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier from History.Position. Joining key between #t and History.Position. |
| 7 | NetProfit | DECIMAL(16,8) | NO | - | CODE-BACKED | Return percentage: (NetProfit / Amount) * 100. IIF(Amount=0,1.0,Amount) prevents divide-by-zero. NOT a dollar amount - consistent with public profile masking. |
| 8 | CloseRate | DECIMAL | NO | - | CODE-BACKED | Aliased from EndForexRate. Exchange rate at position close. |
| 9 | CloseDateTime | DATETIME | NO | - | CODE-BACKED | Aliased from CloseOccurred. When the copy position was closed. Primary sort key (DESC). |
| 10 | CID | INT | NO | - | CODE-BACKED | Customer ID (the copier). Resolved internally from @MirrorID. |
| 11 | ParentPositionID | INT | NO | 0 | CODE-BACKED | ISNULL(ParentPositionID, 0). 0 for standalone copy positions. Non-zero for positions in a copy tree hierarchy. |
| 12 | ParentCID | INT | NO | 0 | CODE-BACKED | ISNULL(@ParentCID, 0). The Popular Investor's CID - resolved from Trade.Mirror.ParentCID at the start of execution. 0 if not found. |
| 13 | MirrorID | INT | NO | - | CODE-BACKED | Hardcoded to @MirrorID - all positions in RS2 belong to this copy session. |
| 14 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier at time the position was opened. |
| 15 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID, CID, ParentCID | Trade.Mirror | Lookup (READ) | Primary CID resolution - loads CID, ParentCID, and RealizedEquity for the mirror session. |
| CID | Customer.Customer | Lookup (READ) | Joined to Trade.Mirror to load RealizedEquity for MirrorAmountDelta calculation. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy gate - OperationTypeID=3 blocks public history. |
| @MirrorID | History.Mirror | Lookup (READ) | Fallback CID resolution when mirror session is no longer in Trade.Mirror. |
| @MirrorID, CID, CreditTypeID | History.Credit | Lookup (READ) | Source of all cashflow events for the mirror session. Staged into #t with pagination. |
| PositionID | History.Position | Lookup (READ) | Source of position details for RS2. Joined to #t ON PositionID. Note: uses full History.Position, not PositionSlim. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Granted to TDAPIUser and TDAPIUserProd service accounts - called by the Trading Data API service to power the public copy session detail timeline. Companion: `TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest` (identical code, testing variant).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId (procedure)
├── Trade.Mirror (table)
├── Customer.Customer (table - cross-schema)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema, fallback CID lookup)
├── History.Credit (table - cross-schema)
└── History.Position (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | CID + ParentCID + RealizedEquity resolution for the @MirrorID. |
| Customer.Customer | Table | Joined to Trade.Mirror to load RealizedEquity. |
| Customer.BlockedCustomerOperations | Table | Privacy gate check. |
| History.Mirror | Table | Fallback CID lookup when Trade.Mirror has no row for @MirrorID. |
| History.Credit | Table | All cashflow and position-close credits for the mirror, paginated into #t. |
| History.Position | Table | Position detail rows joined to #t for RS2. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TDAPIUser service account | External | EXECUTE granted - called to serve public copy session detail timeline. |
| Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest | Procedure | Identical copy - see that SP's documentation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get public mirror history timeline (page 1)
```sql
EXEC Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId
    @MirrorID = 99999,
    @StartTime = NULL,
    @PageNumber = 1,
    @ItemsPerPage = 20
-- Returns RS1 (cashflows) and RS2 (positions) for the copy session
```

### 8.2 Get history for a mirror session within a specific time window
```sql
EXEC Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId
    @MirrorID = 99999,
    @StartTime = '2024-01-01',
    @PageNumber = 1,
    @ItemsPerPage = 20
```

### 8.3 Diagnose CID resolution for a mirror (check active vs closed)
```sql
-- Check if mirror is active (Trade.Mirror)
SELECT m.MirrorID, m.CID, m.ParentCID, c.RealizedEquity
FROM Trade.Mirror m WITH (NOLOCK)
INNER JOIN Customer.Customer c WITH (NOLOCK) ON m.CID = c.CID
WHERE m.MirrorID = 99999

-- If no row, check History.Mirror (closed session)
SELECT TOP 1 MirrorID, CID FROM History.Mirror WITH (NOLOCK) WHERE MirrorID = 99999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId.sql*
