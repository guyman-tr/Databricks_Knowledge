# BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws

> Filters a given set of withdrawal IDs to those eligible for automatic funding breakdown - InProcess or Partially Processed withdrawals that still have unallocated amount remaining.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawIDs (BackOffice.IDs TVP) - input set; returns subset of WithdrawIDs passing eligibility |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws` is a filter procedure used in the cashout processing pipeline. When a batch of withdrawal requests is being processed for "auto breakdown" - the automated step that splits each withdrawal into individual payment instrument allocations (`Billing.WithdrawToFunding` rows) - this procedure screens out any withdrawals that are not in the right state or have already been fully allocated.

The cashout breakdown process works as follows: a withdrawal (`Billing.Withdraw`) represents a customer's total requested cashout amount. This amount must be "broken down" into one or more funding instrument payments (credit card, bank transfer, etc.) stored in `Billing.WithdrawToFunding`. This procedure ensures the auto-breakdown tool only processes withdrawals that are (1) in an active processing state (InProcess=2 or Partially Processed=5) and (2) still have remaining unallocated amount (total withdrawal Amount minus already-allocated active WTF amounts is greater than zero).

The input is the `BackOffice.IDs` table-valued parameter - a batch of WithdrawIDs selected by the calling cashout tool. The output is the eligible subset. Withdrawals that are Canceled, Processed, Rejected, or fully allocated are excluded.

---

## 2. Business Logic

### 2.1 Cashout Status Eligibility Gate

**What**: Only withdrawals in InProcess or Partially Processed state can proceed to auto breakdown.

**Columns/Parameters Involved**: `BW.CashoutStatusID`

**Rules**:
- CashoutStatusID=2 (InProcess): Withdrawal has been approved and is actively being processed - eligible.
- CashoutStatusID=5 (Partially Processed): Some funding allocations have been made but the total amount is not yet fully covered - still needs more breakdown - eligible.
- All other statuses (1=Pending, 3=Processed, 4=Canceled, 6=Payment Sent, 7=Rejected, 8=RejectedByProvider, 9-17=various pipeline states) - NOT eligible.

**Full CashoutStatus map** (Dictionary.CashoutStatus):
1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed, 6=Payment Sent, 7=Rejected, 8=RejectedByProvider, 9=PendingByProvider, 10=SentToProvider, 11=SentToBilling, 12=ReceivedByBilling, 13=Failed, 14=Pending Review, 15=Under Review, 16=Reversed, 17=Partialy Reversed.

### 2.2 Remaining Unallocated Amount Check

**What**: Withdrawals that have already been fully allocated to funding instruments are excluded, even if their status is still InProcess/Partially Processed.

**Columns/Parameters Involved**: `BW.Amount`, `WTF.Amount`, `WTF.CashoutStatusID`

**Rules**:
- Calculates: `BW.Amount - ISNULL(SUM(active WTF amounts), 0) > 0`
- Active WTF allocations counted: those where WTF.CashoutStatusID NOT IN (1=Pending, 4=Canceled, 7=Rejected).
- Excluded WTF statuses (1, 4, 7) represent uncommitted or failed allocations that do not count toward the allocated total - only allocations that are in-process, processed, or beyond are counted.
- ISNULL(..., 0) handles withdrawals with no WTF records at all - they have 0 allocated, so the full amount is remaining.

**Diagram**:
```
WithdrawID=1001: Amount=1000
  WTF rows:
    500 (CashoutStatusID=2, InProcess)  -> COUNTS
    300 (CashoutStatusID=4, Canceled)   -> EXCLUDED
    200 (CashoutStatusID=1, Pending)    -> EXCLUDED

Unallocated = 1000 - 500 = 500 > 0 -> ELIGIBLE for more breakdown

WithdrawID=1002: Amount=1000
  WTF rows:
    1000 (CashoutStatusID=3, Processed)  -> COUNTS

Unallocated = 1000 - 1000 = 0 -> NOT eligible (fully allocated)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawIDs | BackOffice.IDs (TABLE) | NO | - | CODE-BACKED | Input batch of WithdrawIDs to evaluate. BackOffice.IDs is a table-valued type with a single INT column (ID) and a clustered PK. Passed ReadOnly - not modified by this procedure. Joined to Billing.Withdraw on WithdrawID=ID. |
| 2 | WithdrawID | INT | NO | - | CODE-BACKED | Output: WithdrawID values from the input batch that passed both eligibility checks (CashoutStatusID IN (2,5) AND unallocated amount > 0). These are the withdrawals that auto-breakdown should process. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawIDs.ID | Billing.Withdraw | JOIN - filter source | Retrieves withdrawal records matching input IDs. |
| BW.CashoutStatusID | Dictionary.CashoutStatus | Lookup | Filters on values 2=InProcess, 5=Partially Processed. |
| BW.WithdrawID | Billing.WithdrawToFunding | Correlated sub-query | Sums already-allocated amounts to compute remaining unallocated balance. |
| WTF.CashoutStatusID | Dictionary.CashoutStatus | Lookup | Excludes WTF records with status 1=Pending, 4=Canceled, 7=Rejected from the allocation sum. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by CashoutTool service account (external). No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws (procedure)
├── BackOffice.IDs (user defined type) [TVP]
├── Billing.Withdraw (table)
└── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | User Defined Type | Table-valued parameter type for the input batch of WithdrawIDs. |
| Billing.Withdraw | Table | INNER JOIN to filter by CashoutStatusID. Source of BW.Amount. |
| Billing.WithdrawToFunding | Table | Correlated sub-query to SUM allocated amounts (excluding Pending/Canceled/Rejected WTF rows). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by CashoutTool service. No SQL procedure callers in repository. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. NOLOCK on Billing.Withdraw. Correlated sub-query on Billing.WithdrawToFunding (no NOLOCK hint on WTF - reads with default locking). BackOffice.IDs TVP has a clustered PK on ID for efficient JOIN.

---

## 8. Sample Queries

### 8.1 Check which withdrawals from a manual list are eligible for breakdown
```sql
DECLARE @ids BackOffice.IDs;
INSERT INTO @ids (ID) VALUES (100001), (100002), (100003), (100004);

EXEC BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws
    @WithdrawIDs = @ids;
```

### 8.2 Inline equivalent: find eligible InProcess withdrawals
```sql
SELECT BW.WithdrawID
FROM Billing.Withdraw BW WITH (NOLOCK)
WHERE BW.CashoutStatusID IN (2, 5)  -- InProcess, Partially Processed
  AND (
      BW.Amount - ISNULL((
          SELECT SUM(WTF.Amount)
          FROM Billing.WithdrawToFunding WTF
          WHERE WTF.WithdrawID = BW.WithdrawID
            AND WTF.CashoutStatusID NOT IN (1, 4, 7)  -- exclude Pending, Canceled, Rejected
      ), 0)
  ) > 0;
```

### 8.3 Investigate a specific withdrawal's allocation state
```sql
SELECT
    BW.WithdrawID,
    BW.Amount AS TotalAmount,
    BW.CashoutStatusID,
    cs.Name AS StatusName,
    SUM(CASE WHEN WTF.CashoutStatusID NOT IN (1,4,7) THEN WTF.Amount ELSE 0 END) AS AllocatedAmount,
    BW.Amount - SUM(CASE WHEN WTF.CashoutStatusID NOT IN (1,4,7) THEN WTF.Amount ELSE 0 END) AS RemainingAmount
FROM Billing.Withdraw BW WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = BW.CashoutStatusID
LEFT JOIN Billing.WithdrawToFunding WTF WITH (NOLOCK) ON WTF.WithdrawID = BW.WithdrawID
WHERE BW.WithdrawID = 100001
GROUP BY BW.WithdrawID, BW.Amount, BW.CashoutStatusID, cs.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws.sql*
