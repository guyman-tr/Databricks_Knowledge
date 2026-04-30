# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit

> Trading API procedure that returns paginated cashflow-only credit history from the active credit store - deposits, cashouts, bonuses, chargebacks, and corporate actions, excluding position closes and mirror operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "recent data" implementation of the cashflows filter view, called by the router `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` when the requested start time is within approximately one year (or NULL). It reads from `History.ActiveCredit` and returns a single paginated result set of direct money movement events.

"Cashflows" in this context means the subset of credit types that represent direct cash entering or leaving the customer's account - deposits, withdrawals, bonuses, refunds, chargebacks, and corporate action adjustments. It explicitly excludes:
- CreditTypeID=4 (Close Position) - position P&L is shown separately
- CreditTypeID=18-22, 24 (mirror/copy balance transfers) - copy trading lifecycle events
- Mirror lifecycle events (MirrorOperationID rows) - not included at all

Compared to the full flat history delegate (`TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit`), this procedure is significantly simpler: no CTEs, no mirror event injection, no complex 4-branch copy filtering, single result set. The WHERE clause is a straightforward time filter with no copy/non-copy branching.

Also notable: `ParentCID` is always NULL here (hardcoded) since copy context is irrelevant for the cashflows view.

---

## 2. Business Logic

### 2.1 Cashflow CreditType Filter

**What**: Restricts to credit types representing direct money movements only.

**Columns/Parameters Involved**: `CreditTypeID`, `Description`

**Rules**:
- `CreditTypeID IN (1, 2, 5, 6, 7, 8, 9, 11, 12, 16, 17)` - money movements
- `OR (CreditTypeID = 14 AND Description LIKE 'CA Type=%')` - corporate action credits
- Excluded vs. full flat history: type 4 (Close Position), types 18-22, 24 (mirror balance transfers)
- Excluded always: type 3 (Open Position), type 10 (IB sync), type 13 (Edit Stop Loss), type 15 (Cashout Fee), type 23 (Hierarchical Open)
- HistoryCreditActionsToHide filter still applied: `hsa.CreditTypeID IS NULL`

**Included credit types**:
- 1=Deposit
- 2=Cashout
- 5=Champ Winner
- 6=Compensation
- 7=Bonus
- 8=Reverse cashout
- 9=Cashout request
- 11=Chargeback
- 12=Refund
- 14=Corporate Action (Description LIKE 'CA Type=%' only)
- 16=Refund As ChargeBack
- 17=FixHistoryCreditChargeBacks

### 2.2 Simple Time Filter

**What**: Straightforward time-based WHERE clause, no copy/non-copy branching.

**Rules**:
- `(@startTime IS NULL) OR (hc.Occurred >= @startTime)` - simple, no mirror-context complexity
- Ordered by CID, Occurred DESC, CreditID DESC with OFFSET/FETCH pagination

### 2.3 CashoutReasonID Enrichment

**What**: LEFT JOIN to Billing.Withdraw to add cashout reason.

**Rules**:
- Same as other flat history procedures: `ISNULL(bw.CashoutReasonID, 0)`.

### 2.4 ParentCID Always NULL

**What**: No mirror lookup, ParentCID is hardcoded NULL.

**Rules**:
- `NULL AS ParentCID` - cashflows view does not surface copy context.
- This differs from the full flat history delegates which compute ParentCID via closedMirrorAtEndTime CTE.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All history scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. Simple filter: Occurred >= @startTime. When NULL: no time filter. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Cashflow Credits - Paginated)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | INT | NO | - | CODE-BACKED | Credit record ID from History.ActiveCredit. Unique identifier for this credit event. |
| 2 | CreditTypeID | INT | NO | - | CODE-BACKED | Type of cash movement: 1=Deposit, 2=Cashout, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 11=Chargeback, 12=Refund, 14=Corporate Action (filtered), 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks. (Dictionary.CreditType) |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp of the cashflow event. Primary sort key (DESC). |
| 4 | Payment | MONEY | YES | - | CODE-BACKED | Dollar amount. Positive=credit, negative=debit. |
| 5 | PositionID | BIGINT | YES | - | CODE-BACKED | Associated position (when applicable). Not NULL-forced for CreditTypeID=6 here (unlike full flat history). |
| 6 | ChampionshipID | INT | YES | - | CODE-BACKED | Championship ID for CreditTypeID=5 events. |
| 7 | CashoutID | INT | YES | - | CODE-BACKED | Cashout transaction ID for types 2, 8, 9. FK to Billing.Cashout. |
| 8 | PaymentID | INT | YES | - | CODE-BACKED | Payment gateway transaction ID. |
| 9 | WithdrawID | INT | YES | - | CODE-BACKED | Withdrawal transaction ID. Used to JOIN to Billing.Withdraw. |
| 10 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Withdrawal processing batch ID. |
| 11 | DepositID | INT | YES | - | CODE-BACKED | Deposit transaction ID for CreditTypeID=1. FK to Billing.Deposit. |
| 12 | UpdateID | INT | YES | - | CODE-BACKED | Internal update batch identifier. |
| 13 | CampaignID | INT | YES | - | CODE-BACKED | Marketing campaign ID for campaign-linked credits. |
| 14 | BonusTypeID | INT | YES | - | CODE-BACKED | Bonus type for CreditTypeID=7. |
| 15 | CompensationReasonID | INT | YES | - | CODE-BACKED | Compensation reason for CreditTypeID=6. |
| 16 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Internal money movement reason code. |
| 17 | ParentCID | INT | YES | - | CODE-BACKED | Always NULL in this procedure. No copy context is needed for cashflows view. |
| 18 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 if this credit is a copy trading dividend (non-null/non-zero MirrorDividendID). 0 otherwise. |
| 19 | CashoutReasonID | INT | NO | - | CODE-BACKED | Cashout reason from Billing.Withdraw. ISNULL-defaulted to 0. |
| 20 | CorporateActionDescription | VARCHAR | YES | - | CODE-BACKED | Corporate action description for CreditTypeID=14 with 'CA Type=%'. NULL for all other types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.ActiveCredit | Lookup (READ) | Source for recent cashflow credit events |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | Enriches cashout credits with CashoutReasonID |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hides specific compensation types from customer view |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` (router). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit (procedure)
├── History.ActiveCredit (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table (cross-schema) | Primary source for recent cashflow credit data |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN for CashoutReasonID |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Exclude specific compensation types from view |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` (router). No other SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Unlike the full flat history delegates, this procedure does NOT use a temp table - single result set returned directly with OFFSET/FETCH.

### 7.2 Constraints

None. This is a simpler procedure than the full flat history variants - no CTEs, no mirror join, no complex copy-detection branching. The cashflows filter scope is defined entirely by the CreditType IN list.

---

## 8. Sample Queries

### 8.1 Get first page of cashflow history (recent)

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview cashflow credits directly

```sql
SELECT TOP 20
    hc.CreditID,
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Occurred,
    hc.Payment
FROM History.ActiveCredit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND (hc.CreditTypeID IN (1, 2, 5, 6, 7, 8, 9, 11, 12, 16, 17)
        OR (hc.CreditTypeID = 14 AND hc.Description LIKE 'CA Type=%'))
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit.sql*
