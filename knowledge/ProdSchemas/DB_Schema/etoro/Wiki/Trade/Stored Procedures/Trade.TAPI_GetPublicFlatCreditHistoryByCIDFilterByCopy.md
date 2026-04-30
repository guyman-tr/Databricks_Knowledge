# Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy

> Filter variant of the public flat credit history: returns only copy-trade positions (MirrorID > 0, OrigParentPositionID > 0) since 2019-01-01, with no 1-year cap.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (copy positions only, paginated, no 1-year cap) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the copy-positions-only filter variant within the `TAPI_GetPublicFlatCreditHistoryByCID` family. It returns the same column structure as the main SP but restricts results to copy-trade positions (MirrorID > 0 AND OrigParentPositionID > 0) without applying a 1-year look-back cap - copy positions are visible from the platform's launch (`CloseOccurred > '2019-01-01'`).

The procedure powers the "Copy" tab in the public trading history view, where visitors can see which Popular Investor's trades they copied. The `#closedMirrorAtEndTime` staging provides `ParentCID` (the Popular Investor's ID) for each position.

Like all family members, it checks OperationTypeID=3 privacy restriction and raises error 60090 if blocked. @startTime is present in the signature but is **not used** in the position filter for copy positions (the WHERE clause only uses `CloseOccurred > '20190101'`).

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Blocks access if customer has restricted their profile visibility.

**Rules**: Same as family - OperationTypeID=3 check, RAISERROR(60090, 16, 1) if blocked.

### 2.2 Closed Mirror Staging

**What**: Builds set of closed mirror sessions with their ParentCIDs.

**Columns/Parameters Involved**: `#closedMirrorAtEndTime`, `MirrorID`, `ParentCID`, `@startTime`

**Rules**:
- `SELECT MirrorID, ParentCID INTO #closedMirrorAtEndTime FROM History.Mirror WHERE CID=@cid AND MirrorOperationID=2 AND (ModificationDate > @startTime AND ModificationDate > DATEADD(year,-1, GETUTCDATE()))` - same as main SP
- NO sentinel (0,0) row inserted - copy positions always have MirrorID > 0, so the sentinel is not needed
- OPTION (RECOMPILE) for optimal plan

### 2.3 Copy-Only Position Filter

**What**: Restricts to copy-trade child positions only; no 1-year cap.

**Columns/Parameters Involved**: `MirrorID`, `OrigParentPositionID`, `CloseOccurred`, `@startTime`

**Rules**:
- `hp.MirrorID > 0` - copy-trade positions only (manual positions excluded)
- `hp.OrigParentPositionID > 0` - child positions with a parent; root copy positions (OrigParentPositionID=0) are excluded
- `CloseOccurred > '20190101'` - floor at platform launch date for copy trading
- **@startTime is NOT applied to position filtering** - unlike the manual filter variant; copy positions show full history since 2019
- INNER JOIN to #closedMirrorAtEndTime: only positions from mirror sessions closed within @startTime window are included (mirror filter drives recency, not position close date)

### 2.4 NetProfit as Percentage ROI

**What**: Returns profit as return percentage.

**Rules**: `CASE ISNULL(Amount,0) WHEN 0 THEN 0 ELSE 100 * ISNULL(NetProfit,0) / ISNULL(Amount,0) END` - same as all family members.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Privacy check runs first. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Used only for the #closedMirrorAtEndTime staging filter (ModificationDate > @startTime). NOT applied to position CloseOccurred filtering. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. |

### Output - Closed Copy-Trade Positions

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. Matches @cid. |
| 3 | ParentPositionID | INT | NO | 0 | CODE-BACKED | Parent position in copy tree. 0 = no parent. ISNULL defaults NULL to 0. |
| 4 | ParentCID | INT | NO | 0 | CODE-BACKED | The Popular Investor's CID. From History.Mirror via #closedMirrorAtEndTime. ISNULL defaults NULL to 0. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. FK to Trade.Instrument. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1=Long/Buy, 0=Short/Sell. |
| 7 | CloseReason | INT | YES | - | CODE-BACKED | ActionType alias. Close reason. FK to Dictionary.ClosePositionActionType. |
| 8 | OpenRate | DECIMAL | NO | - | CODE-BACKED | InitForexRate alias. Opening price rate. |
| 9 | OpenDateTime | DATETIME | NO | - | CODE-BACKED | InitDateTime alias. When position was opened. |
| 10 | CloseRate | DECIMAL | YES | - | CODE-BACKED | EndForexRate alias. Closing price rate. |
| 11 | CloseDateTime | DATETIME | NO | - | CODE-BACKED | CloseOccurred alias. When position was closed. Sort key (DESC). |
| 12 | MirrorID | INT | YES | - | CODE-BACKED | Copy session ID. Always > 0 for rows from this SP. |
| 13 | NetProfit | DECIMAL | NO | 0 | CODE-BACKED | Percentage ROI: (NetProfit / Amount) * 100. NOT absolute profit. |
| 14 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. |
| 15 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, MirrorID, MirrorOperationID, ParentCID | History.Mirror | Lookup (READ) | Staged into #closedMirrorAtEndTime for ParentCID enrichment |
| CID, MirrorID, OrigParentPositionID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of copy-trade position data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicFlatCreditHistoryByCID` (combined), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg` (stats), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual` (manual-only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Closed mirror session staging with ParentCID |
| History.PositionSlim | Table (cross-schema) | Source of copy-trade closed position data |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table `#closedMirrorAtEndTime`: heap.

### 7.2 Constraints

None. Key behavioral characteristics:
- @startTime controls only which MIRRORS are staged, NOT which positions are returned (copy positions go back to 2019)
- No (0,0) sentinel row - this SP is copy-only so the manual sentinel is not needed
- OPTION (RECOMPILE) on mirror staging SELECT
- WITH (NOLOCK) on all history tables

---

## 8. Sample Queries

### 8.1 Get copy-only positions, page 1

```sql
EXEC Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy
    @cid = 12345,
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
*Object: Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy.sql*
