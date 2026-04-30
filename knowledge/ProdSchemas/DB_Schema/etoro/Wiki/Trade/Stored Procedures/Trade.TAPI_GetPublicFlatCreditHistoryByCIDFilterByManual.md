# Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual

> Filter variant of the public flat credit history: returns only manually-opened root positions (MirrorID=0, OrigParentPositionID=0/NULL) within @startTime and a 1-year cap, without any mirror staging.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (manual positions only, 1-year cap, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the manual-positions-only filter variant within the `TAPI_GetPublicFlatCreditHistoryByCID` family. It returns closed positions that were manually opened by the customer (not via copy-trading), within @startTime and a 1-year look-back window.

Unlike the copy filter variant (`FilterByCopy`), this SP has **no mirror staging temp table** - manual positions have no associated Mirror record to look up, so the ParentCID is hardcoded to 0. This makes it simpler and more performant: a single direct query against History.PositionSlim.

Like all family members, it checks OperationTypeID=3 privacy restriction first.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Blocks access if customer has restricted their profile.

**Rules**: OperationTypeID=3 check, RAISERROR(60090, 16, 1) if blocked. Same as all family members.

### 2.2 Manual Root Position Filter with 1-Year Cap

**What**: Restricts to independently-opened, non-copy-trade root positions within the specified window.

**Columns/Parameters Involved**: `MirrorID`, `OrigParentPositionID`, `CloseOccurred`, `@startTime`

**Rules**:
- `ISNULL(hp.MirrorID, 0) = 0` - manual positions only (MirrorID=0 or NULL)
- `ISNULL(hp.OrigParentPositionID, 0) = 0` - root positions only (OrigParentPositionID=0 or NULL); child positions from copy trees are excluded
- `CloseOccurred >= @startTime` - from the specified start
- `CloseOccurred > DATEADD(year,-1, GETUTCDATE())` - 1-year hard cap; unlike copy filter which has no such cap
- All conditions in AND (no OR branch needed - manual only, simpler than main SP)

### 2.3 ParentCID Hardcoded to 0

**What**: Manual positions have no Popular Investor - ParentCID is always 0.

**Rules**:
- `0 AS ParentCID` - hardcoded in SELECT; no lookup needed
- Contrast with FilterByCopy where ParentCID comes from History.Mirror

### 2.4 NetProfit as Percentage ROI

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
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of look-back window. Applied to CloseOccurred (inclusive: >=). Also capped by 1-year look-back. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. |

### Output - Closed Manual Positions

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. Matches @cid. |
| 3 | ParentPositionID | INT | NO | 0 | CODE-BACKED | Parent in copy tree. 0 = root. ISNULL defaults NULL to 0. |
| 4 | ParentCID | INT | NO | 0 | CODE-BACKED | Always 0. Manual positions have no Popular Investor. Hardcoded. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. FK to Trade.Instrument. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1=Long/Buy, 0=Short/Sell. |
| 7 | CloseReason | INT | YES | - | CODE-BACKED | ActionType alias. Close reason. FK to Dictionary.ClosePositionActionType. |
| 8 | OpenRate | DECIMAL | NO | - | CODE-BACKED | InitForexRate alias. Opening price rate. |
| 9 | OpenDateTime | DATETIME | NO | - | CODE-BACKED | InitDateTime alias. When position was opened. |
| 10 | CloseRate | DECIMAL | YES | - | CODE-BACKED | EndForexRate alias. Closing price rate. |
| 11 | CloseDateTime | DATETIME | NO | - | CODE-BACKED | CloseOccurred alias. When position was closed. Sort key (DESC). |
| 12 | MirrorID | INT | YES | - | CODE-BACKED | Always 0 or NULL for manual positions. |
| 13 | NetProfit | DECIMAL | NO | 0 | CODE-BACKED | Percentage ROI: (NetProfit / Amount) * 100. NOT absolute profit. |
| 14 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. |
| 15 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, MirrorID, OrigParentPositionID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of manual closed position data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicFlatCreditHistoryByCID` (combined), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg` (stats), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy` (copy-only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.PositionSlim | Table (cross-schema) | Source of manual closed position data |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables. Simpler than FilterByCopy.

### 7.2 Constraints

None. Key behavioral characteristics:
- No temp table - direct query against History.PositionSlim
- 1-year hard cap always applied (CloseOccurred > DATEADD(year,-1, GETUTCDATE()))
- @startTime filter uses inclusive >= (vs main SP which uses some exclusive >)
- ParentCID = 0 hardcoded (no mirror staging needed)
- WITH (NOLOCK) on History.PositionSlim

---

## 8. Sample Queries

### 8.1 Get manual-only positions, page 1

```sql
EXEC Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual
    @cid = 12345,
    @startTime = DATEADD(year, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview directly

```sql
SELECT
    hp.PositionID,
    hp.CID,
    ISNULL(hp.ParentPositionID, 0) AS ParentPositionID,
    0 AS ParentCID,
    hp.InstrumentID,
    hp.IsBuy,
    hp.ActionType AS CloseReason,
    hp.InitForexRate AS OpenRate,
    hp.InitDateTime AS OpenDateTime,
    hp.EndForexRate AS CloseRate,
    hp.CloseOccurred AS CloseDateTime,
    hp.MirrorID,
    CASE ISNULL(hp.Amount,0) WHEN 0 THEN 0
        ELSE 100 * ISNULL(hp.NetProfit,0) / ISNULL(hp.Amount,0) END AS NetProfit,
    hp.Leverage,
    hp.LotCountDecimal
FROM History.PositionSlim hp WITH (NOLOCK)
WHERE hp.CID = 12345
    AND ISNULL(hp.MirrorID, 0) = 0
    AND ISNULL(hp.OrigParentPositionID, 0) = 0
    AND hp.CloseOccurred >= DATEADD(year, -1, GETUTCDATE())
ORDER BY hp.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual.sql*
