# Billing.WithdrawService_GetFundingLastCurrency

> Returns the currency of the most recent successful transaction (deposit or withdrawal) on a given payment instrument, used by the withdrawal service to pre-populate the currency for a new withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID - payment instrument to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetFundingLastCurrency` answers the question: "What currency was last used with this payment instrument?" The withdrawal service uses this to suggest a default currency when a customer initiates a new withdrawal - if their last transaction using this payment method was in GBP, the withdrawal form should pre-populate with GBP.

The procedure exists because a payment instrument (e.g., a bank account or credit card) may have been used with different currencies at different times. Rather than guessing from the instrument's country or type, the service looks at the actual transaction history to find the most recently used currency. This improves UX by reducing the customer's need to manually select the currency.

Created November 2020 (MIMOPS-2805, Yaron Shmaria), this procedure was part of the withdrawal service infrastructure that was being built out at that time.

---

## 2. Business Logic

### 2.1 Most Recent Successful Transaction Currency (Union of Deposits and Withdrawals)

**What**: The currency is determined from the most recent successful transaction using this FundingID, combining both deposit and withdrawal history.

**Columns/Parameters Involved**: `@FundingID`, `Billing.Deposit.CurrencyID`, `Billing.WithdrawToFunding.ProcessCurrencyID`, `statusdate`

**Rules**:
- Successful deposit: `PaymentStatusID=2` (Approved) -> uses `Deposit.CurrencyID`.
- Successful withdrawal: `CashoutStatusID=3` (Processed) -> uses `WithdrawToFunding.ProcessCurrencyID`.
- Both are unioned and ordered by `statusdate` DESC; TOP 1 is returned.
- If no successful transaction exists for this FundingID, the procedure returns no rows (empty result set).
- Note: `Deposit.CurrencyID` and `WithdrawToFunding.ProcessCurrencyID` serve the same semantic role (the currency of the transaction) but are named differently in their respective tables.

**Diagram**:
```
Billing.Deposit WHERE FundingID=@FundingID AND PaymentStatusID=2
  -> (fundingid, PaymentDate AS statusdate, CurrencyID)

UNION

Billing.WithdrawToFunding WHERE FundingID=@FundingID AND CashoutStatusID=3
  -> (fundingid, ModificationDate AS statusdate, ProcessCurrencyID)

SELECT TOP 1 currency ORDER BY statusdate DESC
-> Returns CurrencyID of the most recent successful transaction
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | The payment instrument ID. FK to `Billing.Funding.FundingID`. Both deposits and withdrawals are searched for this FundingID. |

**Result Set**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | currency | INT | CurrencyID of the most recent successful transaction on this payment instrument. FK to `Dictionary.Currency`. Returns 0 or 1 row (TOP 1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Deposit | Lookup | Finds approved deposits (PaymentStatusID=2) for this funding instrument. |
| @FundingID | Billing.WithdrawToFunding | Lookup | Finds processed withdrawals (CashoutStatusID=3) for this funding instrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Called when a customer selects a payment method in the withdrawal flow to pre-populate the currency field. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetFundingLastCurrency (procedure)
├── Billing.Deposit (table) - approved deposits by FundingID
└── Billing.WithdrawToFunding (table) - processed withdrawals by FundingID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT FundingID, PaymentDate, CurrencyID WHERE FundingID=@FundingID AND PaymentStatusID=2 |
| Billing.WithdrawToFunding | Table | SELECT FundingID, ModificationDate, ProcessCurrencyID WHERE FundingID=@FundingID AND CashoutStatusID=3 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Returns empty result if no successful transaction exists for @FundingID.

---

## 8. Sample Queries

### 8.1 Get the last currency used for a funding instrument

```sql
EXEC Billing.WithdrawService_GetFundingLastCurrency @FundingID = 123456;
```

### 8.2 Get last currency with context (inline equivalent)

```sql
SELECT TOP 1
    t.currency,
    t.statusdate,
    t.source
FROM (
    SELECT d.CurrencyID AS currency, d.PaymentDate AS statusdate, 'Deposit' AS source
    FROM Billing.Deposit d WITH (NOLOCK)
    WHERE d.FundingID = 123456 AND d.PaymentStatusID = 2
    UNION ALL
    SELECT wtf.ProcessCurrencyID, wtf.ModificationDate, 'Withdrawal'
    FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
    WHERE wtf.FundingID = 123456 AND wtf.CashoutStatusID = 3
) t
ORDER BY t.statusdate DESC;
```

### 8.3 Find funding instruments with no currency history (never successfully transacted)

```sql
SELECT f.FundingID, f.FundingTypeID, f.DateCreated
FROM Billing.Funding f WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Billing.Deposit d WITH (NOLOCK)
    WHERE d.FundingID = f.FundingID AND d.PaymentStatusID = 2
)
AND NOT EXISTS (
    SELECT 1 FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
    WHERE wtf.FundingID = f.FundingID AND wtf.CashoutStatusID = 3
)
AND f.DateCreated > DATEADD(MONTH, -3, GETDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetFundingLastCurrency | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetFundingLastCurrency.sql*
