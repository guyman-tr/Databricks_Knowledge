# Billing.GetFundingIDByWithdrawID

> Resolves the FundingID associated with a given withdraw record, returning it as an output parameter for use in downstream payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A withdraw (cashout) transaction in Billing.Withdraw is always linked to a specific payment method (Billing.Funding via FundingID). When processing withdrawal-related operations - such as chargebacks, reversals, or regulatory inquiries - other services need to know which funding method was targeted for a specific withdrawal without querying the Withdraw table directly.

This procedure is the withdrawal-side counterpart to GetFundingIDByDepositID: both use the same OUTPUT parameter pattern to provide a lightweight, single-purpose lookup that resolves a transaction ID to its associated FundingID. The OUTPUT parameter pattern indicates this is called inline within other stored procedures or tightly coupled application code.

---

## 2. Business Logic

### 2.1 Withdraw-to-Funding Resolution

**What**: Simple primary key lookup on Billing.Withdraw to resolve the funding method used for a withdrawal.

**Rules**:
- `SELECT @FundingID = w.FundingID FROM Billing.Withdraw w WHERE w.WithdrawID = @WithdrawID`
- If the WithdrawID doesn't exist, @FundingID will retain its initial value (NULL by default)
- The OUTPUT pattern means the caller must declare @FundingID before the EXEC call
- No NOLOCK hint (unlike GetFundingIDByDepositID) - reads committed data only

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Primary key of Billing.Withdraw. Identifies the specific withdrawal whose funding method is being resolved. |
| 2 | @FundingID | INT | OUT | - | CODE-BACKED | OUTPUT parameter. Receives the FundingID from Billing.Withdraw.FundingID for the given WithdrawID. NULL if no matching withdrawal found (retains initial value). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | Lookup | Resolves WithdrawID -> FundingID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application refund/chargeback services | @WithdrawID + @FundingID | EXEC | Used to find which funding method was used for a withdrawal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingIDByWithdrawID (procedure)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT FundingID WHERE WithdrawID = @WithdrawID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get FundingID for a withdrawal

```sql
DECLARE @FundingID INT;
EXEC Billing.GetFundingIDByWithdrawID
    @WithdrawID = 98765432,
    @FundingID = @FundingID OUTPUT;
SELECT @FundingID AS ResolvedFundingID;
```

### 8.2 Direct lookup equivalent

```sql
SELECT FundingID
FROM Billing.Withdraw
WHERE WithdrawID = 98765432;
```

### 8.3 Get full funding details after resolving FundingID

```sql
DECLARE @FundingID INT;
EXEC Billing.GetFundingIDByWithdrawID @WithdrawID = 98765432, @FundingID = @FundingID OUTPUT;
SELECT f.FundingID, f.FundingTypeID, f.FundingData
FROM Billing.Funding f WITH (NOLOCK)
WHERE f.FundingID = @FundingID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingIDByWithdrawID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingIDByWithdrawID.sql*
