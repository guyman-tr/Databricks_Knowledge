# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit

> Trading API procedure that returns paginated copy-trading-only history (position closes within mirrors, mirror balance transfers, mirror lifecycle events) from the active credit store, with a second result set of position details.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "recent data" implementation of the copy filter view, called by the router `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy` when the requested start time is within approximately one year (or NULL). It reads from `History.ActiveCredit` and returns only copy trading-related credit events: position closes that occurred within a copy relationship (CreditTypeID=4), mirror balance transfers (types 18-22, 24), and mirror lifecycle events (start/transfer, MirrorOperationID 12/13).

This is the mirror-image of `TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` - where cashflows excludes copy events, this procedure includes ONLY copy events. Together with the cashflows and manual filters, these three views partition the full flat history into distinct tabs.

The architecture is similar to the full flat history delegate: uses the `closedMirrorAtEndTime` CTE, injects mirror lifecycle events via UNION ALL, returns 2 result sets (credits + position details from History.PositionSlim). Key differences from the full flat history:
- CreditType filter is `IN (4, 18, 19, 20, 21, 22, 24)` - ONLY copy types
- No CorporateActionDescription column
- Time filter for credits is simplified: `(@startTime IS NULL) OR (cm.Occurred IS NOT NULL)` - copy credits only if the mirror was closed within the time window (regardless of the credit's own Occurred date)

---

## 2. Business Logic

### 2.1 Copy-Only CreditType Filter

**What**: Restricts to credit types that represent copy trading activity exclusively.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- `CreditTypeID IN (4, 18, 19, 20, 21, 22, 24)` - copy/mirror types only
- 4=Close Position (within a mirror), 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close position, 24=Close position by recovery
- HistoryCreditActionsToHide filter applied: `hsa.CreditTypeID IS NULL`
- ActionType=20 exclusion applied: `ISNULL(p.ActionType, 0) != 20`

### 2.2 Mirror-Context Time Filter

**What**: Copy credit events are included based on whether their associated mirror was closed within the time window, not the event's own Occurred date.

**Columns/Parameters Involved**: `@startTime`, `closedMirrorAtEndTime.Occurred`

**Rules**:
- Credit branch WHERE: `(@startTime IS NULL) OR (cm.Occurred IS NOT NULL)`
- When @startTime IS NULL: include all copy credits (cm join is LEFT, so non-closed mirrors may match via cm.MirrorID... wait, actually when @startTime IS NULL the closedMirrorAtEndTime CTE returns ALL closed mirrors. So cm.Occurred IS NOT NULL means the mirror was closed at some point.)
- When @startTime is set: the closedMirrorAtEndTime CTE is filtered to mirrors where ModificationDate > @startTime. So cm.Occurred IS NOT NULL means the mirror was closed after @startTime. This ensures copy events are shown in context of their mirror closure.
- This is simpler than the full flat history 4-branch logic: here only copy types are included, and ALL copy events (not just those with Occurred >= @startTime) are returned if the mirror closed within the window.

### 2.3 Mirror Lifecycle Event Injection (UNION ALL branch)

**What**: Injects synthetic rows for mirror start (12) and transfer (13) events.

**Rules** (identical to full flat history):
- INNER JOIN to closedMirrorAtEndTime - only events for mirrors closed within the time window
- MirrorOperationID IN (12, 13), filtered by ModificationDate >= @startTime
- IsCredit=0, zero financial values

### 2.4 Two Result Sets (with History.PositionSlim)

**What**: Same two-result-set pattern as full flat history delegates.

**Rules**:
- Result Set 1: paginated from temp table #t (20 columns, no CorporateActionDescription vs the 21 in full flat history)
- Result Set 2: History.PositionSlim INNER JOIN #t on PositionID, WHERE IsCredit=1

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All queries scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. When set: includes only copy credits where their mirror was closed after @startTime (mirror-context filter, not event-date filter). |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Copy Credit/Mirror Events - Paginated)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | INT | YES | - | CODE-BACKED | Credit record ID. 0 for mirror lifecycle events. |
| 2 | CreditTypeID | INT | YES | - | CODE-BACKED | Copy credit type: 4=Close Position (within mirror), 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close, 24=Close by recovery. NULL for mirror events. (Dictionary.CreditType) |
| 3 | MirrorOperationID | INT | YES | - | CODE-BACKED | Mirror lifecycle operation. NULL for credit rows. 12=start copy, 13=transfer for mirror events. |
| 4 | Occurred | DATETIME | NO | - | CODE-BACKED | Event timestamp. Primary sort key (DESC). |
| 5 | Payment | MONEY | YES | - | CODE-BACKED | Dollar amount. 0 for mirror events. |
| 6 | PositionID | BIGINT | YES | - | CODE-BACKED | Associated position. 0 for mirror events. |
| 7 | ChampionshipID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 8 | CashoutID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 9 | PaymentID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 10 | WithdrawID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 11 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 12 | DepositID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 13 | UpdateID | INT | YES | - | CODE-BACKED | Internal update identifier. 0 for mirror events. |
| 14 | CampaignID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 15 | BonusTypeID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 16 | CompensationReasonID | INT | YES | - | CODE-BACKED | Always 0 for copy credit types. |
| 17 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Internal money movement reason for mirror balance transfers. 0 for mirror events. |
| 18 | ParentCID | INT | YES | - | CODE-BACKED | The Popular Investor CID being copied. From closedMirrorAtEndTime.ParentCID. 0/NULL when no mirror match. |
| 19 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 if copy trading dividend (non-null MirrorDividendID). |
| 20 | CashoutReasonID | INT | NO | - | CODE-BACKED | From Billing.Withdraw. ISNULL-defaulted to 0 (usually 0 for copy types). |

### Output - Result Set 2 (Position Details - from History.PositionSlim)

Identical schema to `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit` Result Set 2 (34 columns). See that procedure for full element descriptions. Key columns:
- PositionID: joins to PositionID in Result Set 1
- MirrorID: non-zero for copy positions (these are all copy positions in this filter)
- ParentPositionID: non-zero for copy positions
- ParentCID: the Popular Investor CID from temp table
- NetProfit, CloseOccurred: P&L and timing of position close

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.ActiveCredit | Lookup (READ) | Source for recent copy credit events |
| MirrorID, CID | History.Mirror | Lookup (READ) | Mirror closure context (CTE) + lifecycle event injection |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | CashoutReasonID (usually 0 for copy types) |
| PositionID | History.PositionSlim | Lookup (LEFT JOIN/INNER JOIN) | ActionType filter + position details in Result Set 2 |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hide specific credit types from customer view |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy` (router). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit (procedure)
├── History.ActiveCredit (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
├── History.PositionSlim (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table (cross-schema) | Primary source for recent copy credit events |
| History.Mirror | Table (cross-schema) | Mirror closure context + lifecycle event injection |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN for CashoutReasonID |
| History.PositionSlim | Table (cross-schema) | ActionType filter + position detail result set |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Hide filter |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy` (router). No other SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table #t for paginated results (same pattern as full flat history delegates).

### 7.2 Constraints

None. Note: the time filter for this procedure is mirror-context based (`cm.Occurred IS NOT NULL`) rather than event-date based (`hc.Occurred >= @startTime`). This ensures copy events are shown in the context of their mirror's lifecycle, not filtered by when the individual credit was created.

---

## 8. Sample Queries

### 8.1 Get copy history for a customer

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview copy credits directly

```sql
SELECT TOP 20
    hc.CreditID,
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Occurred,
    hc.Payment,
    hc.MirrorID,
    hc.PositionID
FROM History.ActiveCredit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND hc.CreditTypeID IN (4, 18, 19, 20, 21, 22, 24)
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit.sql*
