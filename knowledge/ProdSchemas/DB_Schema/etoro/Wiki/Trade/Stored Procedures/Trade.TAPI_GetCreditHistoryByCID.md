# Trade.TAPI_GetCreditHistoryByCID

> Trading API procedure that returns a paginated list of money-movement credit events (deposits, cashouts, bonuses, chargebacks, etc.) for a customer's portfolio history - excluding position open/close events.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a TAPI (Trading API) endpoint that powers the customer-facing portfolio history view - specifically the "Account Activity" or "History" section showing money movements. It returns a paginated, chronologically-descending list of credit events that represent cash flows: deposits, cashouts, bonuses, chargebacks, refunds, and similar monetary transactions.

The procedure excludes position-related credit events (CreditTypeIDs 3=Open Position, 4=Close Position) because position P&L is shown separately in the portfolio view. The 11 included credit types (1,2,5,6,7,8,9,11,12,16,17) represent all money transfers that directly affect the customer's available cash balance.

Data flows as follows: `History.ActiveCredit` holds the customer's recent credit history. A LEFT JOIN to `Billing.Withdraw` enriches cashout records with their reason code. The result is paginated using OFFSET/FETCH for scalable API response sizes. The procedure is called by the TDAPIUser (Trading Data API service account), indicating it serves the public-facing trading platform API.

---

## 2. Business Logic

### 2.1 CreditType Filter - Money Movements Only

**What**: The IN list filters to only credit types that represent direct cash movements in the portfolio, excluding position P&L events.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- Included credit types (from Dictionary.CreditType):
  - 1 = Deposit (customer adds funds)
  - 2 = Cashout (customer withdraws funds)
  - 5 = Champ Winner (championship prize credit)
  - 6 = Compensation (manual compensation from support)
  - 7 = Bonus (promotional bonus credit)
  - 8 = Reverse cashout (cashout reversal)
  - 9 = Cashout request (cashout pending/fee deduction)
  - 11 = Chargeback (credit card chargeback)
  - 12 = Refund (refund of fees or costs)
  - 16 = Refund As ChargeBack (refund processed as chargeback)
  - 17 = FixHistoryCreditChargeBacks (data correction for chargebacks)
- Excluded: 3=Open Position, 4=Close Position, 10=IB synchronization, 13=Edit Stop Loss, 14=End Of Week Fee, 15=Cashout Fee, 18-33 (mirror ops, recovery, data fixes)
- Code comment explicitly states the intent: "money movements that affect the portfolio (excluding the closing of positions)"

### 2.2 Pagination

**What**: Server-side pagination using OFFSET/FETCH for efficient API responses.

**Columns/Parameters Involved**: `@pageNumber`, `@itemsPerPage`, `@offsetRows`

**Rules**:
- `@offsetRows = @itemsPerPage * (@pageNumber - 1)` - 1-based page numbering.
- Page 1 = `OFFSET 0 ROWS FETCH NEXT @itemsPerPage ROWS ONLY`.
- Page 2 = `OFFSET @itemsPerPage ROWS FETCH NEXT @itemsPerPage ROWS ONLY`.
- Results ordered by `CreditID DESC` (newest first) before pagination is applied.

### 2.3 Copy Dividend Detection

**What**: Computed flag that indicates whether a credit event relates to a dividend received through copy trading.

**Columns/Parameters Involved**: `MirrorDividendID`, `IsCopyDividend`

**Rules**:
- `CASE ISNULL(MirrorDividendID, 0) WHEN 0 THEN 0 ELSE 1 END AS IsCopyDividend`
- IsCopyDividend = 1 when the credit event has a non-null, non-zero MirrorDividendID.
- IsCopyDividend = 0 for regular (non-copy) dividends and all other credit types.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Filters all results to this customer. Required - the procedure always scopes to a single customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start date/time filter. When provided, returns only credit events with Occurred >= @startTime. When NULL, returns all history. Used by clients to load incremental updates. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number for pagination. Combined with @itemsPerPage to compute OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of rows to return per page (page size). Used in both OFFSET calculation and FETCH NEXT clause. |

### Output Columns (Result Set)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | INT | NO | - | VERIFIED | Type of credit event: 1=Deposit, 2=Cashout, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 11=Chargeback, 12=Refund, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks. (Dictionary.CreditType) |
| 2 | Payment | MONEY | YES | - | CODE-BACKED | Dollar amount of the credit event. Positive = credit to account, negative = debit from account. |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the credit event occurred. Used for ORDER BY (CreditID DESC is the ordering key, but Occurred is the human-visible time). |
| 4 | ChampionshipID | INT | YES | - | CODE-BACKED | Championship identifier for CreditTypeID=5 (Champ Winner) events. NULL for non-championship credits. |
| 5 | CashoutID | INT | YES | - | CODE-BACKED | Cashout transaction identifier. Populated for CreditTypeIDs 2, 8, 9 (cashout events). FK to Billing.Cashout. |
| 6 | PaymentID | INT | YES | - | CODE-BACKED | Payment provider transaction identifier. Populated for deposit and cashout events processed via payment gateway. |
| 7 | WithdrawID | INT | YES | - | CODE-BACKED | Withdrawal transaction identifier from History.ActiveCredit. Used to JOIN to Billing.Withdraw for CashoutReasonID. |
| 8 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Processing batch identifier for the withdrawal. Links to the payment processing batch in the billing system. |
| 9 | DepositID | INT | YES | - | CODE-BACKED | Deposit transaction identifier. Populated for CreditTypeID=1 (Deposit) events. FK to Billing.Deposit. |
| 10 | UpdateID | INT | YES | - | CODE-BACKED | Internal update identifier for this credit record. Used for tracking which batch or operation created/updated this record. |
| 11 | CampaignID | INT | YES | - | CODE-BACKED | Marketing campaign identifier for bonus/deposit events tied to campaigns. NULL for non-campaign credits. |
| 12 | BonusTypeID | INT | YES | - | CODE-BACKED | Bonus type for CreditTypeID=7 (Bonus) events. FK to a bonus type lookup. NULL for non-bonus credits. |
| 13 | CompensationReasonID | INT | YES | - | CODE-BACKED | Reason for CreditTypeID=6 (Compensation) events. FK to a compensation reason lookup. NULL for non-compensation credits. |
| 14 | IsCopyDividend | BIT | NO | - | CODE-BACKED | Computed flag: 1 if this credit event is a dividend received through copy trading (MirrorDividendID is non-null/non-zero), 0 otherwise. |
| 15 | CashoutReasonID | INT | NO | - | CODE-BACKED | Reason code for cashout events. Sourced from Billing.Withdraw.CashoutReasonID via LEFT JOIN on WithdrawID. Returns 0 (via ISNULL) when no matching Billing.Withdraw record exists. |
| 16 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Reason code for internal money movement operations. Used for regulatory or compliance tracking of specific transfer reasons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.ActiveCredit | Lookup (READ) | Primary source: credit history for the customer |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | Enriches cashout records with CashoutReasonID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the Trading Data API service (TDAPIUser) - a dedicated service account for the customer-facing trading platform API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetCreditHistoryByCID (procedure)
├── History.ActiveCredit (table - cross-schema)
└── Billing.Withdraw (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table (cross-schema) | Primary data source for paginated credit history |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN to retrieve CashoutReasonID for cashout events |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by TDAPIUser (Trading Data API service account).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get first page of credit history for a customer

```sql
EXEC Trade.TAPI_GetCreditHistoryByCID
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get credit history since a specific date (page 1)

```sql
EXEC Trade.TAPI_GetCreditHistoryByCID
    @cid = 12345,
    @startTime = '2026-01-01',
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.3 Preview raw credit history with type names

```sql
SELECT TOP 20
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Payment,
    hc.Occurred,
    CASE ISNULL(hc.MirrorDividendID, 0) WHEN 0 THEN 0 ELSE 1 END AS IsCopyDividend
FROM History.ActiveCredit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND hc.CreditTypeID IN (1, 2, 5, 6, 7, 8, 9, 11, 12, 16, 17)
ORDER BY hc.CreditID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetCreditHistoryByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetCreditHistoryByCID.sql*
