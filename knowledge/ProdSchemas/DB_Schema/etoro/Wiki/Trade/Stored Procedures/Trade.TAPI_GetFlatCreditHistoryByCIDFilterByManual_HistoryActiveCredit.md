# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit

> Trading API procedure that returns paginated non-copy (manual) position close history from the active credit store - position closes where the customer opened the position directly, not via copy trading.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "recent data" implementation of the manual filter view, called by the router `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual` when the requested start time is within approximately one year (or NULL). It reads from `History.ActiveCredit` and returns only position close credits for positions that were NOT opened via copy trading (`MirrorID = 0`).

"Manual" in this context means the customer personally opened and closed these positions - direct trading without using the copy trading feature. This contrasts with the Copy filter which shows position closes within copy relationships.

The procedure is significantly simpler than the Copy and full flat history variants: no CTE architecture, no mirror event injection, no mirror-context time filtering. The time filter is a simple `Occurred >= @startTime`. ParentCID is always NULL (no copy context). CashoutReasonID is not included (manual closes don't have cashout reasons).

The procedure uses a temp table (#t) with SELECT INTO + OFFSET/FETCH to paginate, then returns two result sets: the paginated close credits and position details from History.PositionSlim.

---

## 2. Business Logic

### 2.1 Manual Position Close Filter

**What**: Restricts to non-copy position close credit types.

**Columns/Parameters Involved**: `CreditTypeID`, `MirrorID`

**Rules**:
- `CreditTypeID IN (4, 22, 24)` - position close types only
  - 4=Close Position (standard close)
  - 22=Mirror Hierarchical Close position (but MirrorID=0 means this is a hierarchical close on a manual position's sub-position)
  - 24=Close position by recovery (recovery-induced close on a non-copy position)
- `ISNULL(hc.MirrorID, 0) = 0` - only non-copy positions (no mirror relationship)
- `ISNULL(p.ActionType, 0) != 20` - exclude system close action type 20
- `hsa.CreditTypeID IS NULL` - HistoryCreditActionsToHide filter

### 2.2 Simple Time Filter

**What**: Direct date-based filtering, no mirror context complexity.

**Rules**:
- `(@startTime IS NULL) OR (hc.Occurred >= @startTime)` - simple event-date filter
- No branching for copy vs. non-copy (all records in this filter are non-copy by definition)

### 2.3 Result Set Architecture

**What**: Two result sets via temp table.

**Rules**:
- SELECT INTO #t with ORDER BY + OFFSET/FETCH pagination
- Result Set 1: SELECT from #t (18 columns - note: no CashoutReasonID, no CorporateActionDescription vs other variants)
- Result Set 2: History.PositionSlim INNER JOIN #t on PositionID (34 columns, ParentCID=0 hardcoded)
- Result Set 2 WHERE: `hp.CID = @cid` only (no IsCredit=1 filter - all #t rows are credit rows here since there are no synthetic mirror event rows)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All queries scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. Simple event-date filter: Occurred >= @startTime. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Manual Position Close Credits - Paginated)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | INT | NO | - | CODE-BACKED | Credit record ID from History.ActiveCredit. |
| 2 | CreditTypeID | INT | NO | - | CODE-BACKED | Position close type: 4=Close Position, 22=Mirror Hierarchical Close (non-copy), 24=Close by recovery (non-copy). (Dictionary.CreditType) |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Position close timestamp. Primary sort key (DESC). |
| 4 | Payment | MONEY | YES | - | CODE-BACKED | Credit amount from position close. Can be positive (profit) or negative (loss). |
| 5 | PositionID | BIGINT | YES | - | CODE-BACKED | The position that was closed. FK to History.PositionSlim.PositionID. |
| 6 | ChampionshipID | INT | YES | - | CODE-BACKED | Championship ID (not applicable for manual closes, but retained for schema consistency). |
| 7 | CashoutID | INT | YES | - | CODE-BACKED | Not applicable for position closes. |
| 8 | PaymentID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 9 | WithdrawID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 10 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 11 | DepositID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 12 | UpdateID | INT | YES | - | CODE-BACKED | Internal update batch identifier. |
| 13 | CampaignID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 14 | BonusTypeID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 15 | CompensationReasonID | INT | YES | - | CODE-BACKED | Not applicable for manual closes. |
| 16 | ParentCID | INT | YES | - | CODE-BACKED | Always NULL - manual positions have no copy parent. |
| 17 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Internal reason code for money movement. |
| 18 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 if copy dividend (non-null MirrorDividendID). Typically 0 for manual closes. |

### Output - Result Set 2 (Position Details - from History.PositionSlim)

Same 34-column schema as other flat history delegates (Amount, CID, InstrumentID, IsBuy, Leverage, InitDateTime, InitForexRate, PositionID, StopRate, LimitRate, AmountInUnitsDecimal, EndOfWeekFee, InitialAmountInDollars, OrderID, ParentPositionID, MirrorID, ActionType, NetProfit, EndForexRate, CloseOccurred, ParentCID, IsSettled, SettlementTypeID, RedeemStatus, OriginalPositionID, InitialUnits, OpenActionType, CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes, LotCountDecimal, InitialLotCount, OriginalOpenActionType). Note: ParentCID is hardcoded to 0 (not from mirror lookup).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.ActiveCredit | Lookup (READ) | Source for recent non-copy position close credits |
| PositionID | History.PositionSlim | Lookup (LEFT JOIN/INNER JOIN) | ActionType filter + position detail result set |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hide filter |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual` (router). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit (procedure)
├── History.ActiveCredit (table - cross-schema)
├── History.PositionSlim (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table (cross-schema) | Primary source for recent non-copy close credits |
| History.PositionSlim | Table (cross-schema) | ActionType filter + position detail result set |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Hide filter |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual` (router). No other SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table #t.

### 7.2 Constraints

None. Note differences from other filter variants:
- No Billing.Withdraw JOIN (no CashoutReasonID in output)
- No History.Mirror JOIN (no mirror events, no closedMirrorAtEndTime CTE)
- Result Set 2 WHERE has no IsCredit filter (all #t rows are credit rows, no synthetic mirror events)
- ParentCID is hardcoded 0 in Result Set 2 (not from temp table)

---

## 8. Sample Queries

### 8.1 Get manual position close history

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview manual position closes directly

```sql
SELECT TOP 20
    hc.CreditID,
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Occurred,
    hc.Payment,
    hc.PositionID
FROM History.ActiveCredit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND hc.CreditTypeID IN (4, 22, 24)
    AND ISNULL(hc.MirrorID, 0) = 0
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit.sql*
