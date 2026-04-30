# Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg

> Trading API procedure that returns mirror session summary data: metadata from the live or closed mirror, total holding fees, and item counts split by copy and cashflow event types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @mirrorId INT (single mirror session summary) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the summary/aggregate companion to `TAPI_GetMirrorHistoryWithCIDAndMirrorId`. It provides the header data for the mirror detail view: who was copied, the session settings (stop-loss, pause state), the financial summary (initial investment, deposits, withdrawals, P&L), total holding fees, and a count of how many events of each type the session contains.

The procedure handles two cases in a single UNION:
1. **Active mirror** (still being copied): reads from `Trade.Mirror` where the mirror is live; `AvailableAmount` = current allocation, `EndedCopyDate` = NULL
2. **Closed mirror** (copy session ended): reads from `History.Mirror` where `MirrorOperationID = 2` (closed); `AvailableAmount` = NULL, `EndedCopyDate` = the ModificationDate when the mirror closed

A CROSS JOIN with the `positionFees` CTE (single aggregate row from `History.Position`) merges the total holding fees into the mirror metadata without a complex multi-table JOIN. The credit count CTE (`creditTypeCategories`) classifies credits as 'Copy' (position closes) or 'Cashflow' (money movements) to give the application the total item counts needed to initialize pagination for the two filter variants.

---

## 2. Business Logic

### 2.1 Active vs Closed Mirror - UNION Strategy

**What**: Returns mirror data from Trade.Mirror (if active) or History.Mirror (if closed), unified into one row.

**Columns/Parameters Involved**: `AvailableAmount`, `EndedCopyDate`, `StartedCopyDate`

**Rules**:
- Trade.Mirror branch: `WHERE CID = @cid AND MirrorID = @mirrorId` - returns current live state; AvailableAmount = Amount (live allocation), EndedCopyDate = NULL
- History.Mirror branch: `WHERE CID = @cid AND MirrorID = @mirrorId AND MirrorOperationID = 2` - returns closed session state; AvailableAmount = NULL, EndedCopyDate = ModificationDate (when mirror was closed)
- For an active mirror: only Trade.Mirror row is returned (History.Mirror has no MirrorOperationID=2)
- For a closed mirror: Trade.Mirror row may or may not exist (mirror could have been archived); History.Mirror row definitively has the final state
- Both branches share the same column aliases; CROSS JOIN with positionFees adds TotalFees

### 2.2 Credit Type Category Counts

**What**: Counts how many events of each type exist in the mirror session timeline.

**Columns/Parameters Involved**: `CreditTypeID`, `TotalCopyItems`, `TotalCashflowItems`, `@startTime`

**Rules**:
- creditTypeCategories CTE: classifies credits from History.Credit WHERE CID=@cid AND MirrorID=@mirrorId
  - CreditTypeID IN (4, 22, 24) -> 'Copy' (position-closing events)
  - CreditTypeID IN (18, 19, 20, 21) -> 'Cashflow' (money movement events)
  - CreditTypeID 27 is NOT included in the count (excluded from IN clause, unlike the main SP)
- Grouped to get COUNT per category into #creditCategoryCounts
- TotalCopyItems = SUM of 'Copy' category (tells the app how many pages of positions exist)
- TotalCashflowItems = SUM of 'Cashflow' category (tells the app how many pages of cashflows exist)
- @startTime optionally filters which credits are counted

### 2.3 Position Fees Cross-Join

**What**: Aggregates total holding fees from History.Position for this mirror session.

**Columns/Parameters Involved**: `TotalFees`, `EndOfWeekFee`

**Rules**:
- positionFees CTE: `SELECT ISNULL(SUM(EndOfWeekFee), 0) as TotalFees FROM History.Position WHERE CID = @cid AND MirrorID = @mirrorId` - no date filter, all-time fees for the mirror
- CROSS JOIN used because positionFees always returns exactly one row (aggregate with ISNULL ensures non-null)
- Note: reads History.Position (full history table), not History.PositionSlim, for EndOfWeekFee

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Scopes all data to this customer's mirror session. |
| 2 | @mirrorId | INT | NO | - | CODE-BACKED | Mirror session ID. Identifies the specific copy relationship being summarized. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional period start for credit type counts. When NULL: counts all credits for this mirror. When provided: counts only credits with Occurred >= @startTime. Does NOT filter mirror metadata or position fees. |

### Output - Mirror Session Summary (Single Row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | INT | NO | - | CODE-BACKED | Mirror session identifier. Matches @mirrorId. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID (copier). Matches @cid. |
| 3 | AvailableAmount | DECIMAL | YES | - | CODE-BACKED | Current available allocation in the mirror (from Trade.Mirror.Amount). NULL when returned from the History.Mirror (closed mirror) branch - copy session no longer has available funds. |
| 4 | StopLossAmount | DECIMAL | NO | 0 | CODE-BACKED | Mirror Stop-Loss amount in dollars. Below this equity threshold, the copy session was/would be closed. ISNULL-wrapped to return 0. |
| 5 | StopLossPercentage | DECIMAL | NO | 0 | CODE-BACKED | Mirror Stop-Loss as percentage of initial investment. Default 2% if not explicitly set. ISNULL-wrapped to return 0. |
| 6 | IsPaused | BIT | NO | 0 | CODE-BACKED | 1 = copy session was paused (no new positions opened by copy mechanism). 0 = active copying. From PauseCopy column. ISNULL-wrapped to return 0. |
| 7 | CopyExistingPositions | BIT | NO | 0 | CODE-BACKED | 1 = the copier opted to also copy the leader's existing open positions when starting this copy session (IsOpenOpen setting). 0 = only new positions were copied. ISNULL-wrapped to return 0. |
| 8 | InitialInvestment | DECIMAL | NO | 0 | CODE-BACKED | Amount originally allocated to start this copy session. Matches History.Mirror.InitialInvestment. ISNULL-wrapped to return 0. |
| 9 | DepositSummary | DECIMAL | NO | 0 | CODE-BACKED | Total additional deposits made into this copy session after the initial allocation. ISNULL-wrapped to return 0. |
| 10 | WithdrawalSummary | DECIMAL | NO | 0 | CODE-BACKED | Total withdrawals from this copy session before or at close. ISNULL-wrapped to return 0. |
| 11 | ParentUserName | VARCHAR | YES | - | CODE-BACKED | Username of the Popular Investor being copied. Stored on the mirror record for display without needing a JOIN to Customer. |
| 12 | ClosedPositionsNetProfit | DECIMAL | NO | 0 | CODE-BACKED | Total realized P&L from all closed positions within this copy session (NetProfit from Mirror record). ISNULL-wrapped to return 0. |
| 13 | StartedCopyDate | DATETIME | NO | - | CODE-BACKED | Timestamp when this copy session started (Occurred on the Mirror record). |
| 14 | EndedCopyDate | DATETIME | YES | - | CODE-BACKED | Timestamp when the copy session ended (History.Mirror.ModificationDate for closed mirrors). NULL for the Trade.Mirror (active) branch. |
| 15 | ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID. Used to display their profile and link to their page. |
| 16 | TotalFees | DECIMAL | NO | 0 | CODE-BACKED | Total EndOfWeekFee (overnight/weekend holding fees) across ALL positions in this mirror session (no date filter). Derived from History.Position via CROSS JOIN. |
| 17 | TotalCopyItems | INT | NO | 0 | CODE-BACKED | Count of position-closing credit events (CreditTypeID IN 4, 22, 24) in the mirror session within @startTime. Used to calculate total pages for the "Copy" (position) filter pagination. |
| 18 | TotalCashflowItems | INT | NO | 0 | CODE-BACKED | Count of money movement credit events (CreditTypeID IN 18, 19, 20, 21) in the mirror session within @startTime. Used to calculate total pages for the "Cashflow" filter pagination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID | Trade.Mirror | Lookup (READ) | Active mirror metadata source (live copy sessions) |
| CID, MirrorID, MirrorOperationID | History.Mirror | Lookup (READ) | Closed mirror metadata source (MirrorOperationID=2) |
| CID, MirrorID | History.Position | Lookup (READ) | Source of TotalFees (EndOfWeekFee aggregate) |
| CID, MirrorID, CreditTypeID | History.Credit | Lookup (READ) | Source of TotalCopyItems and TotalCashflowItems counts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId` (full timeline), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows` (cashflows), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy` (positions).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg (procedure)
├── Trade.Mirror (table)
├── History.Mirror (table - cross-schema)
├── History.Position (table - cross-schema)
└── History.Credit (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Active mirror metadata (current state) |
| History.Mirror | Table (cross-schema) | Closed mirror metadata (historical state) |
| History.Position | Table (cross-schema) | EndOfWeekFee aggregate for TotalFees |
| History.Credit | Table (cross-schema) | Credit count categorization for TotalCopyItems/TotalCashflowItems |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table index:
- `#creditCategoryCounts` created inline from a CTE - no explicit index needed (small result set, single GROUP BY)

### 7.2 Constraints

None. Key behavioral characteristics:
- Returns at most 2 rows (one from Trade.Mirror + one from History.Mirror for MirrorOperationID=2) - typically 1 for an active mirror, 1 for a closed mirror
- CROSS JOIN with positionFees is safe because positionFees always produces exactly one aggregate row (ISNULL prevents NULL)
- @startTime only affects credit counts (TotalCopyItems, TotalCashflowItems) - does NOT filter mirror metadata or TotalFees
- positionFees reads History.Position (not PositionSlim) - intentional for EndOfWeekFee accuracy

---

## 8. Sample Queries

### 8.1 Get mirror session summary

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = NULL
```

### 8.2 Get credit counts scoped to a date range

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = DATEADD(YEAR, -1, GETUTCDATE())
```

### 8.3 Check if mirror is active or historical

```sql
-- Active mirrors are in Trade.Mirror; closed mirrors are in History.Mirror
SELECT
    m.MirrorID,
    m.CID,
    m.ParentCID,
    m.Amount AS AvailableAmount,
    m.Occurred AS StartedCopyDate,
    NULL AS EndedCopyDate,
    'Active' AS Status
FROM Trade.Mirror m WITH (NOLOCK)
WHERE m.CID = 12345 AND m.MirrorID = 67890

UNION ALL

SELECT
    hm.MirrorID,
    hm.CID,
    hm.ParentCID,
    NULL AS AvailableAmount,
    hm.Occurred AS StartedCopyDate,
    hm.ModificationDate AS EndedCopyDate,
    'Closed' AS Status
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.CID = 12345 AND hm.MirrorID = 67890 AND hm.MirrorOperationID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg.sql*
