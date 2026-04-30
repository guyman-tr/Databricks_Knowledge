# BackOffice.GetPaymentOrders_Withdraw

> Returns payment orders (WithdrawToFunding records) for a specific customer + withdrawal combination, with PIP-spread conversion cost calculated via BackOffice.CalculateWithdrawPIPsUSD - a static-SQL variant of GetPaymentOrders requiring both CID and WithdrawID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @WithdrawID - both required |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a focused variant of `BackOffice.GetPaymentOrders` that retrieves payment orders for a specific customer's specific withdrawal. It requires both `@CID` and `@WithdrawID` as mandatory filters (no optional filtering), and uses a static (non-dynamic) SQL query for simplicity.

The key differentiator from `GetPaymentOrders` is the conversion cost calculation: instead of using `ExchangeFeeInUSD` directly, this version calls `BackOffice.CalculateWithdrawPIPsUSD` - a table-valued function that computes the PIP spread cost in USD based on the process currency, exchange rate, base exchange rate, and amount. The result is returned as a **negative value** (cost = deduction from customer funds).

**Permission**: No active EXECUTE grants found in permission files. May be used for ad-hoc investigation or was superseded by `GetPaymentOrders`.

**Relationship to GetPaymentOrders**: Both share identical output schema (Id, Comment, Amount, CurrencyId, PaymentId, DepositID, Depot, DepotID, ExchangeRate, BaseExchangeRate, ExchangeFee, PaymentDetails, AmountInUSD, Status, PaymentMethodType, CreateDate, StatusModificationDate, Type, EntryMethod, ManagerID, ManagerFirstName, ManagerLastName, ConversionCost). The differences:
- This SP: static SQL, required CID+WithdrawID, ConversionCost uses `CalculateWithdrawPIPsUSD` (negative), no ExchangeFeeInUSD column, no status filter.
- GetPaymentOrders: dynamic SQL, all params optional, ConversionCost uses `ExchangeFeeInUSD` (positive), includes ExchangeFeeInUSD column.

---

## 2. Business Logic

### 2.1 Mandatory Dual-Key Filter

**What**: Retrieves all payment orders for a specific customer's specific withdrawal.

**Columns/Parameters Involved**: @CID, @WithdrawID, Billing.Withdraw.CID, Billing.WithdrawToFunding.WithdrawID

**Rules**:
- `w.CID = @CID AND bwtf.WithdrawID = @WithdrawID`: Both conditions required. Ensures the caller sees only their customer's withdrawal data (CID guard prevents cross-customer access).
- Returns all payment orders (across all statuses) for that withdrawal - no status filter.

### 2.2 Latest Comment Resolution

**What**: Retrieves the most recent remark for each payment order's current status.

**Columns/Parameters Involved**: History.WithdrawToFundingAction.Remark, bwtf.CashoutStatusID

**Rules**: Same as `GetPaymentOrders` - correlated subquery TOP 1 remark from `History.WithdrawToFundingAction` matching current `CashoutStatusID`, ordered by `WithdrawToFundingActionID DESC`.

### 2.3 PIP Spread Conversion Cost (Negative)

**What**: Calculates the FX spread/PIP cost in USD using the `CalculateWithdrawPIPsUSD` function.

**Columns/Parameters Involved**: BackOffice.CalculateWithdrawPIPsUSD, bwtf.ProcessCurrencyID, bwtf.ExchangeRate, bwtf.BaseExchangeRate, bwtf.Amount

**Rules**:
- `OUTER APPLY BackOffice.CalculateWithdrawPIPsUSD(ProcessCurrencyID, ExchangeRate, BaseExchangeRate, Amount) ConversionCost`
- OUTER APPLY ensures all rows are returned even if the function returns no rows (NULL-safe).
- `CASE WHEN CashoutStatusID = 3 THEN -ISNULL(ConversionCost.Value, 0) ELSE 0 END`: The conversion cost is returned as a **negative number** for approved cashouts (CashoutStatusID=3). This represents the cost to the customer - a deduction from their cashout proceeds. 0 for non-approved statuses.
- Unlike `GetPaymentOrders` which uses `ExchangeFeeInUSD` directly, this version computes the spread from the exchange rate differentials.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Required. Customer ID. Combined with @WithdrawID to scope results to a specific customer's withdrawal. |
| 2 | @WithdrawID | INT | NO | - | CODE-BACKED | Required. The withdrawal record ID. Combined with @CID to retrieve all payment orders for this withdrawal. |

**Output Columns** (same schema as BackOffice.GetPaymentOrders except no ExchangeFeeInUSD):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | INT | NO | - | CODE-BACKED | Payment order ID (Billing.WithdrawToFunding.ID). |
| 2 | Comment | NVARCHAR | YES | - | CODE-BACKED | Most recent remark for current status from History.WithdrawToFundingAction. |
| 3 | Amount | DECIMAL | YES | - | CODE-BACKED | Refund amount in the deposit's original currency (RefundAmountInDepositCurrency). |
| 4 | CurrencyId | INT | YES | - | CODE-BACKED | Process currency identifier (Dictionary.Currency FK). |
| 5 | PaymentId | INT | YES | - | CODE-BACKED | Funding record ID (Billing.Funding.FundingID). |
| 6 | DepositID | INT | YES | - | CODE-BACKED | Linked deposit record ID. |
| 7 | Depot | NVARCHAR | YES | - | CODE-BACKED | Depot/routing institution name. |
| 8 | DepotID | INT | YES | - | CODE-BACKED | Depot identifier. |
| 9 | ExchangeRate | DECIMAL | YES | - | CODE-BACKED | Applied FX rate. |
| 10 | BaseExchangeRate | DECIMAL | YES | - | CODE-BACKED | Base FX rate before fees. |
| 11 | ExchangeFee | DECIMAL | YES | - | CODE-BACKED | FX conversion fee (non-USD). |
| 12 | PaymentDetails | NVARCHAR | YES | - | CODE-BACKED | Serialized payment instrument data (FundingData). |
| 13 | AmountInUSD | DECIMAL | YES | - | CODE-BACKED | Payment order amount in USD (bwtf.Amount). |
| 14 | Status | INT | NO | - | CODE-BACKED | Current cashout status ID. See Dictionary.CashoutStatus. |
| 15 | PaymentMethodType | INT | YES | - | CODE-BACKED | Funding type ID (Billing.Funding.FundingTypeID). |
| 16 | CreateDate | DATETIME | YES | - | CODE-BACKED | Payment order creation timestamp. |
| 17 | StatusModificationDate | DATETIME | YES | - | CODE-BACKED | Last status change timestamp. |
| 18 | Type | INT | YES | - | CODE-BACKED | Cashout type (CashoutTypeID). |
| 19 | EntryMethod | INT | YES | - | CODE-BACKED | Entry method (CashoutModeID). |
| 20 | ManagerID | INT | YES | - | CODE-BACKED | Assigned manager ID. |
| 21 | ManagerFirstName | NVARCHAR | YES | - | CODE-BACKED | Manager first name. |
| 22 | ManagerLastName | NVARCHAR | YES | - | CODE-BACKED | Manager last name. |
| 23 | ConversionCost | DECIMAL | NO | 0 | CODE-BACKED | PIP spread cost in USD for approved cashouts (CashoutStatusID=3), returned as NEGATIVE (cost to customer). Calculated via BackOffice.CalculateWithdrawPIPsUSD. 0 for non-approved statuses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Main data | Billing.WithdrawToFunding | Read (FROM) | Primary data source |
| CID lookup | Billing.Withdraw | Left Join | Customer ID guard |
| Payment method | Billing.Funding | Left Join | Funding type and data |
| Depot | Billing.Depot | Left Join | Depot name |
| Manager | BackOffice.Manager | Left Join | Manager name |
| Comment | History.WithdrawToFundingAction | Correlated subquery | Latest remark for current status |
| ConversionCost | BackOffice.CalculateWithdrawPIPsUSD | OUTER APPLY | PIP spread cost calculation function |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPaymentOrders_Withdraw (procedure)
+-- Billing.WithdrawToFunding (table)
+-- Billing.Withdraw (table)
+-- Billing.Funding (table)
+-- Billing.Depot (table)
+-- BackOffice.Manager (table)
+-- History.WithdrawToFundingAction (table)
+-- BackOffice.CalculateWithdrawPIPsUSD (table-valued function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM clause; payment order data |
| Billing.Withdraw | Table | LEFT JOIN; CID lookup |
| Billing.Funding | Table | LEFT JOIN; payment instrument |
| Billing.Depot | Table | LEFT JOIN; depot name |
| BackOffice.Manager | Table | LEFT JOIN; manager name |
| History.WithdrawToFundingAction | Table | Correlated subquery; current status comment |
| BackOffice.CalculateWithdrawPIPsUSD | Function (TVF) | OUTER APPLY; computes PIP spread conversion cost in USD |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants; superseded by GetPaymentOrders or used ad-hoc |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Both params required | Design | @CID and @WithdrawID have no defaults - both must be provided |
| Static SQL | Architecture | Unlike GetPaymentOrders, no dynamic SQL - simpler but less flexible |
| ConversionCost NEGATIVE | Business convention | Cost returned as negative to represent a deduction from customer proceeds |
| OUTER APPLY | Null safety | Preserves rows even if CalculateWithdrawPIPsUSD returns no rows |

---

## 8. Sample Queries

### 8.1 Execute for a customer's specific withdrawal

```sql
EXEC BackOffice.GetPaymentOrders_Withdraw
    @CID = 12345678,
    @WithdrawID = 9876543
```

### 8.2 Compare conversion cost methods

```sql
-- This SP uses CalculateWithdrawPIPsUSD (PIP spread method)
-- GetPaymentOrders uses ExchangeFeeInUSD directly
-- Both report cost for CashoutStatusID = 3 (Approved) only
SELECT ProcessCurrencyID, ExchangeRate, BaseExchangeRate, Amount,
       ExchangeFeeInUSD AS [Direct FX Fee Method]
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE WithdrawID = 9876543;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8.8/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPaymentOrders_Withdraw | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPaymentOrders_Withdraw.sql*
