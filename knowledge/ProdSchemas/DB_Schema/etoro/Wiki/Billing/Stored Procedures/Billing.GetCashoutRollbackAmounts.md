# Billing.GetCashoutRollbackAmounts

> Returns the cumulative rollback amounts for a specific withdrawal payment leg (WithdrawToFundingID) and its parent withdrawal request (WithdrawID), providing both the rolled-back amounts and original amounts for reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID, @WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCashoutRollbackAmounts` is a reconciliation procedure that answers: "How much of this withdrawal has been rolled back, and what was the original amount?" It computes the cumulative rollback sums from `Billing.CashoutRollbackTracking` and joins them against the original amounts from `Billing.WithdrawToFunding` and `Billing.Withdraw`, returning all four amounts in a single row for comparison.

A "rollback" in eToro's payment system is a reversal of a processed withdrawal payment — for example when a bank transfer is returned, a chargeback occurs, or a payment system error requires reversal. This procedure is used by the CashoutTool, BILLING_MANAGER role, and BI admins to check how much of a specific withdrawal has been recovered through rollbacks.

The procedure uses two CTEs to independently aggregate rollbacks at two granularity levels:
- **SumWithdrawToFunding**: total rolled back for the specific payment leg (`WitdrawToFundingID`)
- **SumWithdraw**: total rolled back across ALL legs of the parent withdrawal (`WithdrawID`)

Note: "WitdrawToFundingID" has a typo (missing 'h') in both the parameter name and table column — this is a legacy naming issue preserved for backward compatibility.

---

## 2. Business Logic

### 2.1 Two-Level Rollback Aggregation

**What**: Computes rollback totals at both the payment-leg level (WithdrawToFunding) and the withdrawal level (Withdraw), enabling granular and aggregate reconciliation.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `@WithdrawID`, `RollbackAmountInUSD`

**Rules**:
- `TotalCashoutRollbackAmountInUSD` = SUM of rollbacks for the specific payment leg (BWTF.ID = @WithdrawToFundingID). Partial withdrawals split across multiple payment methods each get their own sum.
- `TotalWithdrawRollbackAmountInUSD` = SUM of rollbacks for the entire withdrawal request (all payment legs combined). Should equal sum of all TotalCashoutRollbackAmountInUSD for the same withdrawal.
- `WithdrawOriginalAmountInUSD` = BW.Amount from Billing.Withdraw - the total amount the customer originally requested to withdraw.
- `CashoutOriginalAmountInUSD` = BWTF.Amount from Billing.WithdrawToFunding - the amount routed to this specific payment leg.
- ISNULL(..., 0) wraps all amounts - if no rollback records exist, returns 0 rather than NULL.

**Diagram:**
```
Billing.Withdraw (BW)         <- WithdrawOriginalAmountInUSD
    |
    |--> Billing.WithdrawToFunding (BWTF) <- CashoutOriginalAmountInUSD
              |
              |--> Billing.CashoutRollbackTracking
                    SUM by WitdrawToFundingID -> TotalCashoutRollbackAmountInUSD
                    SUM by WithdrawID         -> TotalWithdrawRollbackAmountInUSD
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | VERIFIED | The specific payment leg to check rollbacks for. References Billing.WithdrawToFunding.ID. Note: the column in CashoutRollbackTracking is named `WitdrawToFundingID` (typo - missing 'h'). |
| 2 | @WithdrawID | int | NO | - | VERIFIED | The parent withdrawal request. References Billing.Withdraw.WithdrawID. Used to look up the original withdrawal amount and cross-level rollback total. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalCashoutRollbackAmountInUSD | decimal | NO | 0 | VERIFIED | Sum of all RollbackAmountInUSD values from CashoutRollbackTracking for the specific payment leg (@WithdrawToFundingID). 0 if no rollbacks recorded. |
| 2 | TotalWithdrawRollbackAmountInUSD | decimal | NO | 0 | VERIFIED | Sum of all RollbackAmountInUSD values from CashoutRollbackTracking for the parent withdrawal (@WithdrawID) across all payment legs. 0 if no rollbacks recorded. |
| 3 | WithdrawOriginalAmountInUSD | money | NO | 0 | VERIFIED | The original withdrawal request amount from Billing.Withdraw.Amount. 0 if no matching Withdraw record (unlikely given the WHERE filter). |
| 4 | CashoutOriginalAmountInUSD | money | NO | 0 | VERIFIED | The original amount for this specific payment leg from Billing.WithdrawToFunding.Amount. 0 if no rollback amounts exist for comparison. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | Billing.WithdrawToFunding | Read | Main FROM table. Provides CashoutOriginalAmountInUSD (BWTF.Amount). |
| @WithdrawID | Billing.Withdraw | Read | LEFT JOINed to provide WithdrawOriginalAmountInUSD (BW.Amount). |
| RollbackAmountInUSD aggregation | Billing.CashoutRollbackTracking | Read (CTE) | Source of rollback amounts. Two CTEs aggregate by WitdrawToFundingID and by WithdrawID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool (role) | EXECUTE permission | Permission | Cashout operations tool uses this for rollback reconciliation. |
| BILLING_MANAGER (role) | EXECUTE permission | Permission | Billing manager role uses this for withdrawal reconciliation checks. |
| PROD_BIadmins (role) | EXECUTE permission | Permission | BI admin access for financial reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCashoutRollbackAmounts (procedure)
├── Billing.CashoutRollbackTracking (table)
├── Billing.WithdrawToFunding (table)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRollbackTracking | Table | Two CTEs aggregate RollbackAmountInUSD by WitdrawToFundingID and by WithdrawID. |
| Billing.WithdrawToFunding | Table | Main FROM table. Provides original payment leg amount. Filtered by BWTF.ID = @WithdrawToFundingID. |
| Billing.Withdraw | Table | LEFT JOINed on WithdrawID. Provides original withdrawal amount. Filtered by BW.WithdrawID = @WithdrawID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool (role) | Permission | Rollback reconciliation |
| BILLING_MANAGER (role) | Permission | Withdrawal financial checks |
| PROD_BIadmins (role) | Permission | Financial reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check rollback status for a specific payment leg
```sql
EXEC Billing.GetCashoutRollbackAmounts @WithdrawToFundingID = 12345, @WithdrawID = 67890
-- Returns: original amounts vs. total rolled-back amounts for reconciliation
```

### 8.2 Direct rollback aggregation by withdrawal
```sql
SELECT WithdrawID,
       SUM(RollbackAmountInUSD) AS TotalRolledBack,
       COUNT(*) AS RollbackEvents
FROM Billing.CashoutRollbackTracking WITH (NOLOCK)
WHERE WithdrawID = 67890
GROUP BY WithdrawID
```

### 8.3 Compare original amount vs. total rollbacks for a withdrawal
```sql
SELECT bw.WithdrawID, bw.Amount AS OriginalAmount,
       ISNULL(SUM(crt.RollbackAmountInUSD), 0) AS TotalRolledBack,
       bw.Amount - ISNULL(SUM(crt.RollbackAmountInUSD), 0) AS NetAmount
FROM Billing.Withdraw bw WITH (NOLOCK)
LEFT JOIN Billing.CashoutRollbackTracking crt WITH (NOLOCK) ON crt.WithdrawID = bw.WithdrawID
WHERE bw.WithdrawID = 67890
GROUP BY bw.WithdrawID, bw.Amount
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCashoutRollbackAmounts | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCashoutRollbackAmounts.sql*
