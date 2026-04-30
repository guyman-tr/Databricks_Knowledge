# BackOffice.GetCashoutRollbackTotalAmount

> Returns the total rollback amount in currency for all rollback records associated with a specific WithdrawToFunding ID, used during cashout reversal processing to determine the cumulative amount already reversed.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID - specific WTF record; returns one row with total rollback amount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCashoutRollbackTotalAmount` answers: "How much of this withdrawal processing has already been rolled back?" When a cashout (withdrawal payment) needs to be reversed - for example, due to a payment failure, fraud, or regulatory action - rollback transactions are recorded in `Billing.CashoutRollbackTracking`. This procedure sums those rollback amounts for a given `WithdrawToFunding` ID.

A `WithdrawToFunding` (WTF) record represents a specific disbursement attempt of a withdrawal to a particular funding source (e.g., "send $500 to the customer's credit card"). When that disbursement is reversed, one or more rollback records are created. This procedure is called to validate whether further rollbacks are permitted (i.e., whether the sum already rolled back equals or exceeds the original disbursement amount).

**Note on typo**: The column name in `Billing.CashoutRollbackTracking` is `WitdrawToFundingID` (missing 'h' in "Withdraw") - a legacy typo preserved in the production schema.

---

## 2. Business Logic

### 2.1 SUM with ISNULL Default

**What**: Returns the sum of RollbackAmountInCurrency for all rollback records for the WTF ID, defaulting to 0 if none exist.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `Billing.CashoutRollbackTracking.RollbackAmountInCurrency`, `WitdrawToFundingID`

**Rules**:
- `SUM(RollbackAmountInCurrency)` across all records matching the WTF ID.
- `ISNULL(@TotalRollbackAmountInCurrency, 0)` - returns 0 if no rollback records exist (new WTF with no reversals yet).
- RollbackAmountInCurrency is MONEY type (precision currency amount in the transaction's currency).
- The procedure does NOT filter by IsCanceled or PaymentStatusID - all rollback records are summed regardless of their cancellation state. The caller is responsible for interpreting the total.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | INT | NO | - | CODE-BACKED | WithdrawToFunding identifier. Corresponds to Billing.CashoutRollbackTracking.WitdrawToFundingID (note typo - missing 'h'). |
| 2 | TotalRollbackAmount | MONEY | NO | 0 | CODE-BACKED | Sum of all RollbackAmountInCurrency values for this WTF record. ISNULL default: 0 if no rollback records exist. Represents the total amount already reversed from this disbursement in the transaction's original currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | Billing.CashoutRollbackTracking | Primary source | Sums all rollback amounts for this WTF ID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by cashout rollback management services. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCashoutRollbackTotalAmount (procedure)
└── Billing.CashoutRollbackTracking (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRollbackTracking | Table (cross-schema) | SUM(RollbackAmountInCurrency) WHERE WitdrawToFundingID = @WithdrawToFundingID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by cashout rollback processing services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Billing.CashoutRollbackTracking should have an index on WitdrawToFundingID for the SUM pattern. Column name has legacy typo WitdrawToFundingID (missing 'h').

### 7.2 Constraints

SET NOCOUNT ON. No NOLOCK. No JOINs. Scalar variable pattern (@TotalRollbackAmountInCurrency) used to enable ISNULL default. All rollback records counted regardless of IsCanceled or PaymentStatusID state.

---

## 8. Sample Queries

### 8.1 Get total rollback amount for a WTF record
```sql
EXEC BackOffice.GetCashoutRollbackTotalAmount @WithdrawToFundingID = 199488;
```

### 8.2 Inline equivalent
```sql
SELECT ISNULL(SUM(RollbackAmountInCurrency), 0) AS TotalRollbackAmount
FROM Billing.CashoutRollbackTracking
WHERE WitdrawToFundingID = 199488;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCashoutRollbackTotalAmount | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCashoutRollbackTotalAmount.sql*
