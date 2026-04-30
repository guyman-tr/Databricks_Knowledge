# BackOffice.GetWithdraw

> Returns core financial details for a single withdrawal request - status, amounts, currencies, and AlreadyPaid calculation showing how much has already been disbursed.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID (required, default 285760); returns Billing.Withdraw row with AlreadyPaid aggregate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdraw` retrieves the essential financial data for a specific withdrawal request. It is used by Back Office and application services to check the current state of a withdrawal: its status, requested amount, how much has already been paid out, and the currency details. The `AlreadyPaid` calculation is the key enrichment - it sums completed funding transfers (excluding transfers finished without money movement) to show how much of the total withdrawal has been disbursed.

Added by Stav R. (July 2021, MIMOPS-4622) specifically for the AlreadyPaid calculation.

---

## 2. Business Logic

### 2.1 AlreadyPaid Calculation

**What**: Computes how much of the withdrawal amount has been successfully paid out.

**Columns/Parameters Involved**: `AlreadyPaid`, `Billing.WithdrawToFunding.Amount`, `Dictionary.CashoutStatus.IsFinishedWithoutMoneyTransfer`

**Rules**:
- CTE FundingAmount: SUM(BWTF.Amount) WHERE WithdrawID = @WithdrawID AND IsFinishedWithoutMoneyTransfer = 0
- `IsFinishedWithoutMoneyTransfer = 0` excludes funding records where the process completed but no actual money moved (e.g., cancellations, zero-amount settlements)
- ISNULL(AlreadyPaid, 0) in the outer SELECT - 0 if no qualifying funding records exist
- Difference between Amount and AlreadyPaid = remaining amount to be disbursed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | YES | 285760 | CODE-BACKED | Primary key of the withdrawal request to retrieve. Default=285760 is a hardcoded test/example ID in the DDL. Required for production use. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerId | INT | NO | - | CODE-BACKED | Customer ID of the withdrawal requestor (Billing.Withdraw.CID). |
| 2 | STATUS | INT | NO | - | CODE-BACKED | Numeric cashout status (Billing.Withdraw.CashoutStatusID). Raw ID - join Dictionary.CashoutStatus for name. |
| 3 | Amount | MONEY | YES | - | CODE-BACKED | Total requested withdrawal amount (Billing.Withdraw.Amount). |
| 4 | AlreadyPaid | MONEY | NO | - | VERIFIED | Sum of amounts already transferred via Billing.WithdrawToFunding WHERE IsFinishedWithoutMoneyTransfer=0. 0 if nothing paid yet. Added MIMOPS-4622. |
| 5 | CurrencyID | INT | YES | - | CODE-BACKED | Currency of the withdrawal (Billing.Withdraw.CurrencyID). Links to Dictionary.Currency. |
| 6 | AccountCurrencyID | INT | YES | - | CODE-BACKED | Currency of the customer's account (Billing.Withdraw.AccountCurrencyID). May differ from CurrencyID if the withdrawal is in a different currency than the account. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BW.WithdrawID = @WithdrawID | Billing.Withdraw | Read (primary) | Withdrawal record |
| BWTF.WithdrawID + CashoutStatus | Billing.WithdrawToFunding | CTE (LEFT JOIN) | AlreadyPaid calculation |
| DCS.CashoutStatusID | Dictionary.CashoutStatus | INNER JOIN (in CTE) | IsFinishedWithoutMoneyTransfer flag |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO withdrawal processing) | @WithdrawID | Application | Called to get withdrawal financials for processing/display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdraw (procedure)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table) - AlreadyPaid CTE
└── Dictionary.CashoutStatus (table) - IsFinishedWithoutMoneyTransfer flag
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary - amount, status, currency |
| Billing.WithdrawToFunding | Table | CTE SUM for AlreadyPaid |
| Dictionary.CashoutStatus | Table | CTE JOIN for IsFinishedWithoutMoneyTransfer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO application layer for withdrawal processing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Default @WithdrawID=285760 | Implementation | Hardcoded default is a specific historical withdrawal ID. Always pass explicit @WithdrawID in production; the default is for development/testing convenience. |
| IsFinishedWithoutMoneyTransfer=0 | Logic | Excludes zero-money-movement funding records from AlreadyPaid sum. These represent process completions that didn't transfer funds (e.g., internal reversals). |

---

## 8. Sample Queries

### 8.1 Get withdrawal details
```sql
EXEC [BackOffice].[GetWithdraw] @WithdrawID = 123456
```

### 8.2 Check remaining amount to disburse
```sql
DECLARE @WithdrawID INT = 123456
EXEC [BackOffice].[GetWithdraw] @WithdrawID = @WithdrawID
-- PendingAmount = Amount - AlreadyPaid from result
```

### 8.3 Direct equivalent query
```sql
SELECT BW.CID AS CustomerId, BW.CashoutStatusID AS STATUS,
       BW.Amount, ISNULL(FA.AlreadyPaid, 0) AS AlreadyPaid,
       BW.CurrencyID, BW.AccountCurrencyID
FROM Billing.Withdraw BW WITH (NOLOCK)
LEFT JOIN (
    SELECT WithdrawID, SUM(Amount) AS AlreadyPaid
    FROM Billing.WithdrawToFunding BWTF WITH (NOLOCK)
    INNER JOIN Dictionary.CashoutStatus DCS WITH (NOLOCK) ON BWTF.CashoutStatusID = DCS.CashoutStatusID
    WHERE WithdrawID = 123456 AND IsFinishedWithoutMoneyTransfer = 0
    GROUP BY WithdrawID
) FA ON BW.WithdrawID = FA.WithdrawID
WHERE BW.WithdrawID = 123456
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-4622 | Jira (DDL comment) | Added AlreadyPaid calculation (Stav R., July 2021) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPS-4622 from DDL comment) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdraw | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdraw.sql*
