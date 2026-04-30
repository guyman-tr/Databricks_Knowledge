# BackOffice.AmendCashoutState

> Transitions a processed cashout request from CashoutStatusID=3 to status 5 when the withdrawal's total amount exceeds the sum of its funded portions by more than $1, handling partial-funding discrepancies.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure corrects a specific edge case in the withdrawal processing pipeline: a cashout that has been processed (CashoutStatusID=3) but whose total withdrawal amount is more than $1 greater than the sum of amounts in its `Billing.WithdrawToFunding` funding legs. This discrepancy can occur when a withdrawal was partially funded - the funded portion was processed but the full amount was not covered.

The procedure exists to allow BackOffice operators or automated processes to mark these partially-funded processed withdrawals with a distinct status (5) for separate handling or reconciliation. The $1 threshold (`BW.Amount - 1 > BWT.SumAmount`) is a business tolerance: small rounding differences (up to $1) are acceptable and do not trigger the state change. Only genuine under-funding gaps exceeding $1 cause the transition.

The procedure returns @AffectedRows OUTPUT to indicate whether the update occurred (1 = amended, 0 = condition not met or record not found). It is referenced in the `PROD_BIadmins` permissions script, indicating it is used by BI admin operations.

Data flow: a single UPDATE on `Billing.Withdraw` joined to a subquery on `Billing.WithdrawToFunding`. No reads return to the caller beyond the @AffectedRows output.

---

## 2. Business Logic

### 2.1 Partial-Funding Discrepancy Detection

**What**: The $1 threshold check ensures only genuine under-funding gaps (not rounding noise) trigger the status transition.

**Columns/Parameters Involved**: `Billing.Withdraw.Amount`, `Billing.WithdrawToFunding.Amount` (aggregated), `CashoutStatusID`

**Rules**:
- Source join: Billing.WithdrawToFunding WHERE CashoutStatusID=3 AND WithdrawID=@WithdrawID, grouped to get SUM(Amount)
- Condition: `BW.Amount - 1 > BWT.SumAmount` -> the withdraw amount minus $1 tolerance exceeds the funded total
- If condition is NOT met (funding covers within $1): no update, @AffectedRows = 0
- If condition IS met: UPDATE CashoutStatusID from 3 to 5

**Diagram**:
```
Billing.Withdraw (CashoutStatusID=3, Amount=X)
       |
       v (join Billing.WithdrawToFunding, CashoutStatusID=3, SUM(Amount)=Y)
   X - 1 <= Y  ->  No change (funding adequate within $1 tolerance)
   X - 1 > Y   ->  SET CashoutStatusID = 5 (partial-funding discrepancy)
```

### 2.2 CashoutStatus Transition: 3 -> 5

**What**: Only Billing.Withdraw records already in status 3 (Processed) are eligible for this amendment.

**Columns/Parameters Involved**: `CashoutStatusID` (Billing.Withdraw), `CashoutStatusID` (Billing.WithdrawToFunding)

**Rules**:
- Billing.Withdraw WHERE CashoutStatusID=3: the request must be in Processed state
- Billing.WithdrawToFunding WHERE CashoutStatusID=3: funding legs must also be in status 3
- Status 5 from the Billing.Withdraw distribution represents approximately 1.2% of all withdrawals (20,127 records) - the "Amended" or "Partial" processing state

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used in the WHERE clause to ensure the withdrawal belongs to the correct customer (anti-tampering guard). |
| 2 | @WithdrawID | INT | NO | - | CODE-BACKED | Withdrawal request identifier. FK to Billing.Withdraw.WithdrawID and Billing.WithdrawToFunding.WithdrawID. |
| 3 | @AffectedRows | INT | NO | - | CODE-BACKED | OUTPUT parameter. Set to @@ROWCOUNT after the UPDATE: 1 if the transition occurred, 0 if conditions were not met or the record was not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @WithdrawID | Billing.Withdraw | MODIFIER | Updates CashoutStatusID from 3 to 5 when the partial-funding condition is met |
| @WithdrawID | Billing.WithdrawToFunding | Lookup (JOIN) | Reads funded amounts to compare against the withdrawal total |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | Permissions | EXECUTE grant | BI admin users have EXECUTE permission on this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AmendCashoutState (procedure)
|- Billing.Withdraw (table) [UPDATE target - sets CashoutStatusID=5]
+-- Billing.WithdrawToFunding (table) [subquery - sums funded amounts to compare]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | UPDATE target: sets CashoutStatusID=3->5 when partial-funding discrepancy > $1 |
| Billing.WithdrawToFunding | Table | Subquery to sum WithdrawToFunding.Amount for CashoutStatusID=3 legs of the withdrawal |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BI admin operations | External | EXECUTE permission granted to PROD_BIadmins; called during reconciliation or withdrawal auditing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| $1 tolerance | Business | `BW.Amount - 1 > BWT.SumAmount` - allows up to $1 rounding difference before treating as under-funded |
| Status guard | Application | Both Billing.Withdraw and Billing.WithdrawToFunding must have CashoutStatusID=3; other states are not affected |
| CID guard | Application | CID filter on Billing.Withdraw prevents amending a different customer's withdrawal |

---

## 8. Sample Queries

### 8.1 Amend a specific cashout that is partially funded

```sql
DECLARE @Affected INT
EXEC BackOffice.AmendCashoutState
    @CID = 12345,
    @WithdrawID = 99001,
    @AffectedRows = @Affected OUTPUT
SELECT @Affected AS RowsAffected -- 1 if amended, 0 if not applicable
```

### 8.2 Check if a withdrawal is eligible for amendment

```sql
-- Check withdraw amount vs funded total
SELECT
    BW.WithdrawID, BW.CID, BW.Amount AS WithdrawAmount, BW.CashoutStatusID,
    ISNULL(SUM(BTF.Amount), 0) AS FundedTotal,
    BW.Amount - ISNULL(SUM(BTF.Amount), 0) AS Discrepancy
FROM Billing.Withdraw BW WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding BTF WITH (NOLOCK)
    ON BTF.WithdrawID = BW.WithdrawID AND BTF.CashoutStatusID = 3
WHERE BW.WithdrawID = 99001
GROUP BY BW.WithdrawID, BW.CID, BW.Amount, BW.CashoutStatusID
-- Eligible if CashoutStatusID=3 AND Discrepancy > 1
```

### 8.3 Find withdrawals in amended state (CashoutStatusID=5)

```sql
SELECT TOP 20 WithdrawID, CID, Amount, CashoutStatusID, ModificationDate
FROM Billing.Withdraw WITH (NOLOCK)
WHERE CashoutStatusID = 5
ORDER BY ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AmendCashoutState | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AmendCashoutState.sql*
