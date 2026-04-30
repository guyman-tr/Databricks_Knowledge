# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows

> Trading API router procedure that dispatches to the correct cashflow-filtered credit history implementation based on data age - returning only direct cash movement events (no position closes or mirror operations) for the customer-facing cashflows filter tab.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the public-facing TAPI endpoint for the "cashflows" filter view within the flat portfolio history section. While `Trade.TAPI_GetFlatCreditHistoryByCID` returns ALL account activity (including position closes and copy trading events), this variant filters to only direct cash movements: deposits, cashouts, bonuses, chargebacks, refunds, and corporate action adjustments. It powers the "Cashflows" tab or filter in the customer's portfolio history UI.

The routing logic is identical to the main flat history router: requests for data older than ~367 days are directed to the full historical archive (`History.Credit`), while recent or unfiltered requests use the active store (`History.ActiveCredit`).

Unlike the full flat history procedures, the cashflow delegates are simpler: single result set, no CTE, no mirror operations, no position detail second result set. This reflects the narrower scope - cashflows are pure money movements with no copy-trading or position P&L complexity.

---

## 2. Business Logic

### 2.1 Data Source Routing - The 367-Day Rule

**Rules** (identical to TAPI_GetFlatCreditHistoryByCID routing):
- `IF @startTime <= DATEADD(DAY, -367, GETUTCDATE())` -> route to `TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit`
- `ELSE` (including NULL) -> route to `TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit`

### 2.2 Cashflows vs Full Flat History

| Aspect | TAPI_GetFlatCreditHistoryByCID | TAPI_GetFlatCreditHistoryByCIDFilterByCashflows |
|--------|--------------------------------|------------------------------------------------|
| Credit types | 1,2,4,5,6,7,8,9,11,12,14,16,17,18,19,20,21,22,24 | 1,2,5,6,7,8,9,11,12,14,16,17 |
| Mirror events | Yes (MirrorOperationID 12,13) | No |
| Position close (type 4) | Yes | No |
| Mirror balance transfers (18-22,24) | Yes | No |
| Result sets | 2 (credits + position details) | 1 (credits only) |
| CTEs | Yes (closedMirrorAtEndTime) | No |
| ParentCID | From mirror lookup | Always NULL |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Forwarded to the delegate procedure. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. Drives routing: NULL or recent -> HistoryActiveCredit, >367 days ago -> HistoryCredit. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. Forwarded to delegate. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. Forwarded to delegate. |

### Output

Returns the result set from the delegate - see:
- `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit`
- `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit`

Single result set: 20 columns of cashflow credit events (no position detail second result set).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (recent data) | Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit | EXEC (delegation) | Delegate for @startTime = NULL or within ~1 year |
| (historical data) | Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit | EXEC (delegation) | Delegate for @startTime older than ~367 days |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser (Trading Data API service account).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows (router)
├── Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit
│   ├── History.ActiveCredit
│   ├── Billing.Withdraw
│   └── Dictionary.HistoryCreditActionsToHide
└── Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit
    ├── History.Credit
    ├── Billing.Withdraw
    └── Dictionary.HistoryCreditActionsToHide
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit | Stored Procedure | Delegate for recent/no-filter requests |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit | Stored Procedure | Delegate for historical (>367 days) requests |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. NULL @startTime routes to HistoryActiveCredit (same behavior as main flat history router).

---

## 8. Sample Queries

### 8.1 Get first page of cashflow history

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get cashflow history from historical archive

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows
    @cid = 12345,
    @startTime = '2024-01-01',
    @pageNumber = 1,
    @itemsPerPage = 50
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows.sql*
