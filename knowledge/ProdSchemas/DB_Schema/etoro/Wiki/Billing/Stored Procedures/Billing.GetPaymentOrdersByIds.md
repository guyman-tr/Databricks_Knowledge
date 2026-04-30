# Billing.GetPaymentOrdersByIds

> Returns paginated withdrawal-to-funding (cashout payment order) records for a given set of IDs, enriched with depot name, manager name, funding instrument data, and the latest status remark from history - used by the CashoutTool for bulk payment order review.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated result set of Billing.WithdrawToFunding rows enriched with related entity names |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentOrdersByIds` retrieves a page of withdrawal payment orders - `Billing.WithdrawToFunding` records - for a caller-supplied set of IDs. Each returned row represents one cashout payment request (a specific withdrawal-to-funding-instrument mapping) enriched with human-readable fields: the depot name, the processing manager's name, the funding instrument's raw XML data, and the most recent status remark from the history log.

The procedure was created in January 2022 (MIMOPSA-6554) as the data-layer endpoint for the CashoutTool's payment order listing screen. It enables bulk retrieval of payment orders by ID (typically after an upstream search/filter step returns matching IDs), with server-side pagination to handle large result sets efficiently.

Data flows as follows: CashoutTool performs a prior query that yields a set of WithdrawToFunding IDs. It passes those IDs as a `BackOffice.IDs` table-valued parameter to this procedure, along with pagination parameters. The procedure joins `Billing.WithdrawToFunding` against the TVP for set-based filtering, then LEFT JOINs to `Billing.Funding` (for FundingData and FundingTypeID), `Billing.Depot` (for depot name), and `BackOffice.Manager` (for manager name). An OUTER APPLY retrieves the most recent `History.WithdrawToFundingAction` remark for the current status. Results are ordered by ID and paginated with OFFSET/FETCH.

---

## 2. Business Logic

### 2.1 TVP-Based Bulk ID Filtering

**What**: The caller supplies a set of WithdrawToFunding IDs as a table-valued parameter (`BackOffice.IDs` UDT) rather than a single ID or a CSV string. This is the modern (post-2012) pattern for passing ID sets to SQL Server procedures, enabling set-based INNER JOIN filtering without string parsing.

**Columns/Parameters Involved**: `@PaymentOrdersIds`, `Billing.WithdrawToFunding.ID`

**Rules**:
- `BackOffice.IDs` is a UDT defined in the BackOffice schema containing a single INT column `ID`
- The TVP is READONLY - the procedure cannot modify it
- The INNER JOIN to `@PaymentOrdersIds` filters `Billing.WithdrawToFunding` to only the requested IDs
- All other JOINs are LEFT JOINs, so the result always includes the requested WithdrawToFunding rows even if related records are missing

### 2.2 Latest Status Remark via OUTER APPLY

**What**: Each payment order may have multiple history action records in `History.WithdrawToFundingAction`. The OUTER APPLY retrieves the most recent remark for the current status, providing the cashout tool with a human-readable explanation of why the order is in its current state.

**Columns/Parameters Involved**: `bwtf.CashoutStatusID`, `History.WithdrawToFundingAction.CashoutStatusID`, `History.WithdrawToFundingAction.Remark`

**Rules**:
- Filter: `HWFA.BW2F_ID = bwtf.ID AND bwtf.CashoutStatusID = HWFA.CashoutStatusID` - matches history records for the same WTF ID AND the same current status
- `TOP 1 ... ORDER BY WithdrawToFundingActionID DESC` - gets the most recent remark for the current status
- Result mapped to output column `Comment` - if no matching history record, Comment is NULL (OUTER APPLY does not exclude rows)

### 2.3 Server-Side Pagination

**What**: OFFSET/FETCH provides server-side pagination with configurable page size.

**Rules**:
- Formula: `OFFSET (@PageNumber-1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY`
- @PageNumber defaults to 1 (first page)
- @PageSize defaults to 2000 (max rows per page)
- ORDER BY bwtf.ID ensures stable page ordering

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentOrdersIds | BackOffice.IDs READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the set of `Billing.WithdrawToFunding.ID` values to retrieve. `BackOffice.IDs` is a UDT with a single INT column `ID`. INNER JOINed to filter results. |
| 2 | @PageNumber | INT | NO | 1 | CODE-BACKED | 1-based page number for pagination. Page 1 returns rows 1 through @PageSize, page 2 returns rows @PageSize+1 through 2*@PageSize, etc. Defaults to 1. |
| 3 | @PageSize | INT | NO | 2000 | CODE-BACKED | Number of rows per page. Defaults to 2000 (the standard CashoutTool batch size). Used in OFFSET/FETCH. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 4 | Id | Billing.WithdrawToFunding.ID | CODE-BACKED | PK of the WithdrawToFunding record - the payment order identifier. |
| 5 | Comment | History.WithdrawToFundingAction.Remark | CODE-BACKED | Most recent status remark from history for the current CashoutStatus. Explains why the order is in its current state. NULL if no history action recorded for this status. |
| 6 | Amount | Billing.WithdrawToFunding.RefundAmountInDepositCurrency | CODE-BACKED | Refund/payout amount expressed in the deposit's original currency. |
| 7 | CurrencyId | Billing.WithdrawToFunding.ProcessCurrencyID | CODE-BACKED | Processing currency ID. FK to Dictionary.Currency. The currency in which the cashout is being processed. |
| 8 | PaymentId | Billing.Funding.FundingID | CODE-BACKED | The funding instrument's ID (aliased as PaymentId for the CashoutTool API contract). |
| 9 | DepositID | Billing.WithdrawToFunding.DepositID | CODE-BACKED | Associated deposit ID if this cashout is a refund of a specific deposit. 0 or NULL if not deposit-linked. |
| 10 | Depot | Billing.Depot.Name | CODE-BACKED | Human-readable name of the processing depot/bank that will execute this cashout. |
| 11 | DepotID | Billing.WithdrawToFunding.DepotID | CODE-BACKED | FK to Billing.Depot. The depot assigned to process this cashout. |
| 12 | ExchangeRate | Billing.WithdrawToFunding.ExchangeRate | CODE-BACKED | Exchange rate applied for currency conversion (deposit currency to processing currency). |
| 13 | BaseExchangeRate | Billing.WithdrawToFunding.BaseExchangeRate | CODE-BACKED | Base exchange rate before fee adjustments. |
| 14 | ExchangeFee | Billing.WithdrawToFunding.ExchangeFee | CODE-BACKED | Fee applied for currency exchange. |
| 15 | PaymentDetails | Billing.Funding.FundingData | CODE-BACKED | Raw XML payment instrument data from Billing.Funding (aliased as PaymentDetails). Contains card number hash, bank details, e-wallet identifiers depending on FundingTypeID. DDM-masked in production. |
| 16 | AmountInUSD | Billing.WithdrawToFunding.Amount | CODE-BACKED | Cashout amount in USD (the base processing currency). |
| 17 | Status | Billing.WithdrawToFunding.CashoutStatusID | CODE-BACKED | Current cashout status code. FK to Dictionary.CashoutStatus. |
| 18 | PaymentMethodType | Billing.Funding.FundingTypeID | CODE-BACKED | Payment method type (1=CreditCard, 2=Wire, 3=PayPal, etc.). From Billing.Funding via LEFT JOIN. |
| 19 | CreateDate | Billing.WithdrawToFunding.CreationDate | CODE-BACKED | Timestamp when this payment order was created. |
| 20 | StatusModificationDate | Billing.WithdrawToFunding.ModificationDate | CODE-BACKED | Timestamp of the last status change on this payment order. |
| 21 | Type | Billing.WithdrawToFunding.CashoutTypeID | CODE-BACKED | Cashout type (e.g., standard cashout, bonus cashout, internal). FK to Dictionary.CashoutType. |
| 22 | EntryMethod | Billing.WithdrawToFunding.CashoutModeID | CODE-BACKED | Cashout mode/entry method (manual vs automated). FK to Dictionary.CashoutMode. |
| 23 | ManagerID | Billing.WithdrawToFunding.ManagerID | CODE-BACKED | ID of the BackOffice manager who processed or is assigned to this payment order. |
| 24 | ManagerFirstName | BackOffice.Manager.FirstName | CODE-BACKED | First name of the assigned manager. From BackOffice.Manager via LEFT JOIN on ManagerID. |
| 25 | ManagerLastName | BackOffice.Manager.LastName | CODE-BACKED | Last name of the assigned manager. From BackOffice.Manager via LEFT JOIN on ManagerID. |
| 26 | WithdrawID | Billing.WithdrawToFunding.WithdrawID | CODE-BACKED | The parent withdrawal request ID (FK to Billing.Withdraw). Added 2024-01-14 (KateM). Links the payment order back to the originating withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentOrdersIds.ID | Billing.WithdrawToFunding.ID | INNER JOIN | Filters to the requested payment order IDs |
| bwtf.FundingID | Billing.Funding | LEFT JOIN | Retrieves payment instrument data and FundingTypeID |
| bwtf.DepotID | Billing.Depot | LEFT JOIN | Retrieves depot name for display |
| bwtf.ManagerID | BackOffice.Manager | LEFT JOIN | Retrieves manager name for display |
| bwtf.ID / CashoutStatusID | History.WithdrawToFundingAction | OUTER APPLY | Retrieves most recent status remark from audit history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool | GRANT EXECUTE | Permission | The CashoutTool application uses this to retrieve payment order lists for display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentOrdersByIds (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── BackOffice.Manager (table - cross-schema)
└── History.WithdrawToFundingAction (table - cross-schema, OUTER APPLY)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary data source; INNER JOINed to TVP for filtering |
| Billing.Funding | Table | LEFT JOINed for FundingData (PaymentDetails) and FundingTypeID |
| Billing.Depot | Table | LEFT JOINed for depot name |
| BackOffice.Manager | Table | LEFT JOINed for manager first/last name |
| History.WithdrawToFundingAction | Table | OUTER APPLYed for latest status remark |
| BackOffice.IDs | User Defined Type | TVP type for @PaymentOrdersIds parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool | DB Security Principal | EXECUTE permission - reads payment orders for cashout management UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Change history**:
- 2022-01-05: Initial version created by Kate M. (MIMOPSA-6554)
- 2024-01-14: WithdrawID column added to result set (KateM) to support linking back to the parent withdrawal

---

## 8. Sample Queries

### 8.1 Call with a set of IDs (first page, default page size)
```sql
-- Declare and populate the TVP
DECLARE @ids BackOffice.IDs
INSERT INTO @ids VALUES (100001), (100002), (100003)

EXEC [Billing].[GetPaymentOrdersByIds]
    @PaymentOrdersIds = @ids,
    @PageNumber = 1,
    @PageSize = 2000
```

### 8.2 Get a specific page of results
```sql
DECLARE @ids BackOffice.IDs
INSERT INTO @ids SELECT ID FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE CashoutStatusID = 1 AND CreationDate >= DATEADD(DAY, -7, GETUTCDATE())

EXEC [Billing].[GetPaymentOrdersByIds]
    @PaymentOrdersIds = @ids,
    @PageNumber = 2,
    @PageSize = 100
```

### 8.3 Equivalent manual query to understand the data shape
```sql
SELECT TOP 5
    bwtf.ID AS Id,
    t.Remark AS Comment,
    bwtf.RefundAmountInDepositCurrency AS Amount,
    bwtf.ProcessCurrencyID AS CurrencyId,
    bf.FundingID AS PaymentId,
    bwtf.DepositID,
    bd.Name AS Depot,
    bwtf.CashoutStatusID AS Status,
    bwtf.WithdrawID
FROM Billing.WithdrawToFunding bwtf WITH (NOLOCK)
OUTER APPLY (
    SELECT TOP 1 Remark
    FROM History.WithdrawToFundingAction HWFA WITH (NOLOCK)
    WHERE HWFA.BW2F_ID = bwtf.ID AND bwtf.CashoutStatusID = HWFA.CashoutStatusID
    ORDER BY WithdrawToFundingActionID DESC
) t
LEFT JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bwtf.FundingID
LEFT JOIN Billing.Depot bd WITH (NOLOCK) ON bd.DepotID = bwtf.DepotID
ORDER BY bwtf.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-6554 (referenced in code comment) | Jira | Initial creation of this procedure in Jan 2022 for the CashoutTool payment order listing feature |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPSA-6554 referenced in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentOrdersByIds | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentOrdersByIds.sql*
