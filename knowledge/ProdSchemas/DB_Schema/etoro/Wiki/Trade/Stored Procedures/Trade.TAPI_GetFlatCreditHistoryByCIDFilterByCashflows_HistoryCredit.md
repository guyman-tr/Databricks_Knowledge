# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit

> Trading API procedure that returns paginated cashflow-only credit history from the full historical archive - identical logic to the HistoryActiveCredit variant but sourced from History.Credit for data older than approximately one year.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "historical data" implementation of the cashflows filter view, called by the router `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` when the requested start time is older than approximately 367 days. It reads from `History.Credit` - the full historical archive - and returns the same cashflow credit types as its sibling `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit`.

The business logic, result set schema, CreditType filter, WHERE conditions, and pagination mechanism are **identical** to the HistoryActiveCredit variant. The only difference is the data source: `History.Credit` instead of `History.ActiveCredit`.

See `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit` for full business logic documentation.

---

## 2. Business Logic

All logic is identical to the HistoryActiveCredit variant. Key summary:

### 2.1 Cashflow CreditType Filter

Same filter: `CreditTypeID IN (1, 2, 5, 6, 7, 8, 9, 11, 12, 16, 17) OR (CreditTypeID=14 AND Description LIKE 'CA Type=%')`. Excludes position closes (type 4) and all mirror/copy transfer types.

### 2.2 Simple Time Filter

`(@startTime IS NULL) OR (hc.Occurred >= @startTime)` - no copy branching.

### 2.3 Key Difference: Data Source

| Aspect | HistoryActiveCredit variant | HistoryCredit variant (this) |
|--------|-----------------------------|-----------------------------|
| Credit source | History.ActiveCredit | History.Credit |
| Data age | Recent (~<1 year) | Historical (>~367 days) |
| Called when | @startTime NULL or recent | @startTime <= 367 days ago |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All history scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. Simple filter: Occurred >= @startTime. This delegate is called when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Cashflow Credits - Paginated, from History.Credit)

Identical schema to `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | INT | NO | - | CODE-BACKED | Credit record ID from History.Credit. |
| 2 | CreditTypeID | INT | NO | - | CODE-BACKED | Cash movement type: 1=Deposit, 2=Cashout, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 11=Chargeback, 12=Refund, 14=Corporate Action (filtered), 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks. (Dictionary.CreditType) |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Event timestamp. Primary sort key (DESC). |
| 4 | Payment | MONEY | YES | - | CODE-BACKED | Dollar amount. Positive=credit, negative=debit. |
| 5 | PositionID | BIGINT | YES | - | CODE-BACKED | Associated position (when applicable). |
| 6 | ChampionshipID | INT | YES | - | CODE-BACKED | Championship ID for CreditTypeID=5. |
| 7 | CashoutID | INT | YES | - | CODE-BACKED | Cashout transaction ID. FK to Billing.Cashout. |
| 8 | PaymentID | INT | YES | - | CODE-BACKED | Payment gateway transaction ID. |
| 9 | WithdrawID | INT | YES | - | CODE-BACKED | Withdrawal transaction ID for Billing.Withdraw JOIN. |
| 10 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Withdrawal processing batch ID. |
| 11 | DepositID | INT | YES | - | CODE-BACKED | Deposit transaction ID for CreditTypeID=1. |
| 12 | UpdateID | INT | YES | - | CODE-BACKED | Internal update batch identifier. |
| 13 | CampaignID | INT | YES | - | CODE-BACKED | Marketing campaign ID. |
| 14 | BonusTypeID | INT | YES | - | CODE-BACKED | Bonus type for CreditTypeID=7. |
| 15 | CompensationReasonID | INT | YES | - | CODE-BACKED | Compensation reason for CreditTypeID=6. |
| 16 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Internal money movement reason code. |
| 17 | ParentCID | INT | YES | - | CODE-BACKED | Always NULL - no copy context in cashflows view. |
| 18 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 if copy trading dividend (non-null MirrorDividendID). 0 otherwise. |
| 19 | CashoutReasonID | INT | NO | - | CODE-BACKED | From Billing.Withdraw. ISNULL-defaulted to 0. |
| 20 | CorporateActionDescription | VARCHAR | YES | - | CODE-BACKED | Corporate action description for CreditTypeID=14 with 'CA Type=%'. NULL otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.Credit | Lookup (READ) | Source for historical cashflow credit events (full archive) |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | Enriches cashout credits with CashoutReasonID |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hides specific compensation types from customer view |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` (router) when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit (procedure)
├── History.Credit (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Primary source for historical cashflow credit data (>~367 days) |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN for CashoutReasonID |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Exclude specific compensation types |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows` (router). No other SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Single result set, no temp table.

### 7.2 Constraints

None. Simplest variant in the flat credit history family - no CTEs, no mirror operations, direct OFFSET/FETCH query.

---

## 8. Sample Queries

### 8.1 Get historical cashflow page

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit
    @cid = 12345,
    @startTime = '2024-01-01',
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview historical cashflow data directly

```sql
SELECT TOP 20
    hc.CreditID,
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Occurred,
    hc.Payment
FROM History.Credit hc WITH (NOLOCK)
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

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit.sql*
