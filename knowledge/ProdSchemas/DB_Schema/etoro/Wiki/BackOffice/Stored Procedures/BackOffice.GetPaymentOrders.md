# BackOffice.GetPaymentOrders

> Flexible multi-filter query for withdrawal payment orders (WithdrawToFunding records) - supports filtering by customer, withdrawal ID, status, funding type, and funding ID via dynamic SQL; returns full payment order details including latest status comment and manager info.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @WithdrawID, @StatusIds (TVP), @FundingTypeID, @FundingID - all optional |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary payment order search endpoint for the CashoutTool and ApprovalTool services. It queries `Billing.WithdrawToFunding` - the junction table linking withdrawal requests to specific funding instruments (payment methods) - and returns fully enriched payment order records for BackOffice agent review and processing.

A payment order represents one specific funding-method leg of a withdrawal. A single withdrawal (`Billing.Withdraw`) may have multiple payment orders if it is being paid via multiple methods. This procedure returns the list matching the caller's filter criteria, enriched with depot info, manager name, exchange rate details, and the most recent status comment.

**Key design feature**: Uses dynamic SQL (`sp_executesql`) to build the query conditionally. Only supplied parameters add clauses - unspecified parameters are ignored. The `@StatusIds` TVP provides multi-status filtering in a single call.

**Permission**: EXECUTE granted to CashoutTool and ApprovalUserEtoro.

**Change history**:
- 2019-10-22 Michal: Added column (RD-14713)
- 2019-11-04 Ran Ovadia: Subquery to get top 1 remark from History for Comment field
- 2019-11-05 Stav: Added ManagerID, FirstName, LastName output columns
- 2022-02-09 KateM: Added WITH(NOLOCK) hints
- 2023-09-11 KateM: CalculateWithdrawPIPsUSD calculation referenced (may have been reverted)

---

## 2. Business Logic

### 2.1 Dynamic SQL Construction

**What**: Builds a flexible SELECT query by concatenating SQL fragments based on which parameters are supplied.

**Columns/Parameters Involved**: All parameters

**Rules**:
- `@SQL1`: Fixed SELECT + JOIN clauses (always applied).
- `@SQL2`: WHERE 1=1 base + conditional AND clauses for each non-NULL parameter.
- `@StatusIds` filter: Applied as a JOIN (not WHERE) so that status filtering works with the TVP. If `@StatusIds` is empty (no rows), the JOIN clause is not added and all statuses are returned.
- `@CID`: Added as a parameterized WHERE condition (`w.CID = @CID`). Safe from SQL injection.
- `@WithdrawID`, `@FundingTypeID`, `@FundingID`: Added via string CONVERT concatenation (safe because they are INT parameters - no injection risk).
- Final query: `sp_executesql @SQL, @ParamDef, ...` - executes the dynamically built query with all parameters bound.
- PRINT @SQL: Logs the generated query to the SQL output (useful for debugging).

### 2.2 Latest Comment Resolution

**What**: For each payment order, retrieves the most recent remark matching the current status from the audit history.

**Columns/Parameters Involved**: History.WithdrawToFundingAction.Remark, bwtf.CashoutStatusID

**Rules**:
- Correlated subquery: `SELECT TOP 1 Remark FROM History.WithdrawToFundingAction WHERE BW2F_ID = bwtf.ID AND CashoutStatusID = bwtf.CashoutStatusID ORDER BY WithdrawToFundingActionID DESC`
- Returns the most recent remark recorded when the payment order was set to its current status. This is the "current status comment" visible to BackOffice agents.
- Returns NULL if no history record matches the current status.

### 2.3 Conversion Cost Calculation

**What**: Computes the FX conversion cost in USD for approved cashouts.

**Columns/Parameters Involved**: bwtf.CashoutStatusID, bwtf.ExchangeFeeInUSD

**Rules**:
- `CASE WHEN bwtf.CashoutStatusID = 3 THEN ISNULL(bwtf.ExchangeFeeInUSD, 0) ELSE 0 END AS ConversionCost`
- CashoutStatusID = 3 = Approved. Only for approved payment orders is the conversion cost reported; for pending/in-process orders, ConversionCost = 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Optional. Filter to payment orders belonging to a specific customer. Matched via `Billing.Withdraw.CID` (the parent withdrawal). NULL = all customers. |
| 2 | @WithdrawID | INT | YES | NULL | CODE-BACKED | Optional. Filter to payment orders for a specific withdrawal record. Matched via `bwtf.WithdrawID`. NULL = all withdrawals. |
| 3 | @StatusIds | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of CashoutStatusIDs to include. Empty TVP = no status filter (all statuses returned). Non-empty = only matching statuses returned via JOIN. |
| 4 | @FundingTypeID | INT | YES | NULL | CODE-BACKED | Optional. Filter by payment method type (e.g., credit card, bank wire, PayPal). Matched via `Billing.Funding.FundingTypeID`. NULL = all types. |
| 5 | @FundingID | INT | YES | NULL | CODE-BACKED | Optional. Filter by specific funding instrument record. NULL = all funding records. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | INT | NO | - | CODE-BACKED | Payment order ID (`Billing.WithdrawToFunding.ID`). Primary identifier. |
| 2 | Comment | NVARCHAR | YES | - | CODE-BACKED | Most recent remark for the current status from `History.WithdrawToFundingAction`. NULL if no history matches. |
| 3 | Amount | DECIMAL | YES | - | CODE-BACKED | Refund amount in the deposit's original currency (`RefundAmountInDepositCurrency`). This is the amount in the customer's deposit currency, not USD. |
| 4 | CurrencyId | INT | YES | - | CODE-BACKED | Process currency identifier (`ProcessCurrencyID`). The currency used for this payment order's processing. References Dictionary.Currency. |
| 5 | PaymentId | INT | YES | - | CODE-BACKED | Funding record identifier (`Billing.Funding.FundingID`). The specific payment instrument (credit card, bank account, etc.) used for this cashout. |
| 6 | DepositID | INT | YES | - | CODE-BACKED | The deposit record linked to this payment order. Used for refund-to-source tracing. |
| 7 | Depot | NVARCHAR | YES | - | CODE-BACKED | Depot name (`Billing.Depot.Name`) - the financial institution or routing depot for this payment. NULL if no depot assigned. |
| 8 | DepotID | INT | YES | - | CODE-BACKED | Depot identifier (`bwtf.DepotID`). References Billing.Depot. |
| 9 | ExchangeRate | DECIMAL | YES | - | CODE-BACKED | FX rate applied to convert between currencies for this payment order. |
| 10 | BaseExchangeRate | DECIMAL | YES | - | CODE-BACKED | Base FX rate before fee adjustments. |
| 11 | ExchangeFee | DECIMAL | YES | - | CODE-BACKED | FX conversion fee charged (in non-USD terms). |
| 12 | PaymentDetails | NVARCHAR | YES | - | CODE-BACKED | Funding instrument data (`FundingData`) - serialized payment method details (e.g., masked card number, bank details). |
| 13 | AmountInUSD | DECIMAL | YES | - | CODE-BACKED | Payment order amount in USD (`bwtf.Amount`). The USD equivalent. |
| 14 | Status | INT | NO | - | CODE-BACKED | Current cashout status ID (`CashoutStatusID`). Callers resolve to name via Dictionary.CashoutStatus. Common values: 1=Pending, 2=In Process, 3=Approved, 5=Pending Review. |
| 15 | PaymentMethodType | INT | YES | - | CODE-BACKED | Funding type identifier (`Billing.Funding.FundingTypeID`). Identifies the payment method type (1=Credit Card, 2=Wire Transfer, etc.). |
| 16 | CreateDate | DATETIME | YES | - | CODE-BACKED | When the payment order was created (`CreationDate`). |
| 17 | StatusModificationDate | DATETIME | YES | - | CODE-BACKED | When the current status was last set (`bwtf.ModificationDate`). |
| 18 | Type | INT | YES | - | CODE-BACKED | Cashout type (`CashoutTypeID`) - distinguishes withdrawal types (e.g., standard, refund, chargeback). |
| 19 | EntryMethod | INT | YES | - | CODE-BACKED | How the cashout was entered (`CashoutModeID`) - e.g., manual BackOffice entry vs. automated. |
| 20 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager assigned to or last acting on this payment order. |
| 21 | ManagerFirstName | NVARCHAR | YES | - | CODE-BACKED | Assigned manager's first name. NULL if no manager. |
| 22 | ManagerLastName | NVARCHAR | YES | - | CODE-BACKED | Assigned manager's last name. NULL if no manager. |
| 23 | ConversionCost | DECIMAL | NO | 0 | CODE-BACKED | FX conversion cost in USD for approved cashouts (CashoutStatusID=3). 0 for all other statuses. |
| 24 | ExchangeFeeInUSD | DECIMAL | YES | - | CODE-BACKED | Raw FX fee in USD regardless of status. ConversionCost is the conditional version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Main data | Billing.WithdrawToFunding | Read (FROM) | Primary data source - payment order records |
| CID lookup | Billing.Withdraw | Left Join | Access to CID for customer filter |
| Payment method | Billing.Funding | Left Join | Payment instrument details (FundingTypeID, FundingData) |
| Depot name | Billing.Depot | Left Join | Depot/routing institution name |
| Manager | BackOffice.Manager | Left Join | Manager name resolution |
| Status filter | @StatusIds TVP | Join | Optional multi-status filter (BackOffice.IDs UDT) |
| Comment | History.WithdrawToFundingAction | Correlated subquery | Latest remark for current status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool service | EXECUTE | Caller | Primary consumer for cashout agent UI |
| ApprovalUserEtoro service | EXECUTE | Caller | Approval workflow service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPaymentOrders (procedure)
+-- Billing.WithdrawToFunding (table)
+-- Billing.Withdraw (table - LEFT JOIN for CID)
+-- Billing.Funding (table - LEFT JOIN for payment details)
+-- Billing.Depot (table - LEFT JOIN for depot name)
+-- BackOffice.Manager (table - LEFT JOIN for manager name)
+-- History.WithdrawToFundingAction (table - correlated subquery for Comment)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM clause; primary data source |
| Billing.Withdraw | Table | LEFT JOIN; CID lookup for customer filter |
| Billing.Funding | Table | LEFT JOIN; funding type and data |
| Billing.Depot | Table | LEFT JOIN; depot name |
| BackOffice.Manager | Table | LEFT JOIN; manager first/last name |
| History.WithdrawToFundingAction | Table | Correlated subquery; latest remark for Comment |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool | External service | Payment order search for cashout processing |
| ApprovalUserEtoro | External service | Approval workflow payment order retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL via sp_executesql | Architecture | Allows flexible filter combinations without N separate procedures |
| @CID parameterized | SQL safety | CID added as bound parameter - injection-safe |
| @WithdrawID, @FundingTypeID, @FundingID as CONVERT(VARCHAR) | SQL safety | Integer conversion before concatenation - safe because all are INT parameters |
| No NOLOCK on main table | Note | Billing.WithdrawToFunding has no NOLOCK; left joins do have NOLOCK |
| @StatusIds empty = no filter | Design | Empty TVP skips JOIN entirely; all statuses returned |
| CashoutStatusID=3 for ConversionCost | Business rule | Only approved cashouts report FX conversion cost |

---

## 8. Sample Queries

### 8.1 Get all payment orders for a customer

```sql
DECLARE @StatusIds BackOffice.IDs;
-- Empty @StatusIds = all statuses

EXEC BackOffice.GetPaymentOrders
    @CID = 12345678,
    @StatusIds = @StatusIds;
```

### 8.2 Get pending payment orders (status 1 and 5)

```sql
DECLARE @StatusIds BackOffice.IDs;
INSERT INTO @StatusIds VALUES (1), (5);  -- 1=Pending, 5=Pending Review

EXEC BackOffice.GetPaymentOrders
    @StatusIds = @StatusIds;
```

### 8.3 Get payment orders for a specific withdrawal by credit card (FundingTypeID=1)

```sql
DECLARE @StatusIds BackOffice.IDs;

EXEC BackOffice.GetPaymentOrders
    @WithdrawID = 9876543,
    @FundingTypeID = 1,
    @StatusIds = @StatusIds;
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian page found. Related context: CashoutTool service documentation covers payment order management (see GetPaymentOrderHistory documentation for CashoutTool API context). Jira RD-14713 referenced in code comments for a 2019 column addition.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 app service consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPaymentOrders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPaymentOrders.sql*
