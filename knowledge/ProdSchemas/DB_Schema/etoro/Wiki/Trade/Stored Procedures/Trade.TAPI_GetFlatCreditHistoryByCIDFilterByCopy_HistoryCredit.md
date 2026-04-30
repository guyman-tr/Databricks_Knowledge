# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit

> Trading API procedure that returns paginated copy-trading-only history from the full historical archive - identical logic to the HistoryActiveCredit variant but sourced from History.Credit and History.Position for data older than approximately one year.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "historical data" implementation of the copy filter view, called by the router `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy` when the requested start time is older than approximately 367 days. It reads from `History.Credit` and `History.Position` - the full historical archives - and returns the same copy trading-related credit events as its sibling `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit`.

All business logic, CTE architecture, CreditType filter, time filter, result set schema, and pagination are **identical** to the HistoryActiveCredit variant. The only differences are:
1. `History.Credit` instead of `History.ActiveCredit` as the credit event source
2. `History.Position` instead of `History.PositionSlim` as the position detail source for Result Set 2

See `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit` for full business logic documentation.

---

## 2. Business Logic

All logic identical to HistoryActiveCredit variant. Key summary:

- Copy-only CreditType filter: `CreditTypeID IN (4, 18, 19, 20, 21, 22, 24)`
- Mirror-context time filter: `(@startTime IS NULL) OR (cm.Occurred IS NOT NULL)`
- Mirror lifecycle injection: UNION ALL for MirrorOperationID IN (12, 13)
- Two result sets: credits from #t + position details from History.Position

**Key Data Source Difference**:

| Aspect | HistoryActiveCredit variant | HistoryCredit variant (this) |
|--------|-----------------------------|-----------------------------|
| Credit source | History.ActiveCredit | History.Credit |
| Position source | History.PositionSlim | History.Position |
| Data age | Recent (~<1 year) | Historical (>~367 days) |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All queries scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. This delegate is called when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). Mirror-context filter applied. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1

Identical schema to `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit` Result Set 1 (20 columns: CreditID, CreditTypeID, MirrorOperationID, Occurred, Payment, PositionID, ChampionshipID, CashoutID, PaymentID, WithdrawID, WithdrawProcessingID, DepositID, UpdateID, CampaignID, BonusTypeID, CompensationReasonID, MoveMoneyReasonID, ParentCID, IsCopyDividend, CashoutReasonID).

### Output - Result Set 2

Same 34-column schema as the HistoryActiveCredit variant, but sourced from `History.Position` instead of `History.PositionSlim`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.Credit | Lookup (READ) | Source for historical copy credit events (full archive) |
| MirrorID, CID | History.Mirror | Lookup (READ) | Mirror closure context + lifecycle event injection |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | CashoutReasonID |
| PositionID | History.Position | Lookup (LEFT JOIN/INNER JOIN) | ActionType filter + position detail result set (historical) |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hide filter |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy` (router) when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit (procedure)
├── History.Credit (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
├── History.Position (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Primary source for historical copy credit data |
| History.Mirror | Table (cross-schema) | Mirror closure context + lifecycle event injection |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN for CashoutReasonID |
| History.Position | Table (cross-schema) | ActionType filter + position detail result set |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Hide filter |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy` (router). No other SQL dependents.

---

## 7. Technical Details

N/A for stored procedure. Uses temp table #t.

---

## 8. Sample Queries

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit
    @cid = 12345,
    @startTime = '2024-01-01',
    @pageNumber = 1,
    @itemsPerPage = 20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit.sql*
