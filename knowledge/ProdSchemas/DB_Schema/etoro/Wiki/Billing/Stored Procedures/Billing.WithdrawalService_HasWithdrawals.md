# Billing.WithdrawalService_HasWithdrawals

> Checks whether a customer has any active or completed withdrawal requests; returns a single row (value 1) if yes, empty result if no.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INTEGER - the customer to check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a lightweight existence check used by the withdrawal service to determine whether a customer has ever submitted a withdrawal request that is still active or was successfully processed. The application calls this before allowing certain operations - for example, to enforce business rules that require a withdrawal history, to gate UI features that only appear after a first withdrawal, or to validate state transitions in the customer lifecycle.

The procedure intentionally excludes cancelled withdrawals (CashoutStatusID=4) from the check. This means it answers: "does this customer have a withdrawal that is pending, in-process, processed, or in one of the other active statuses?" not "has this customer ever clicked the withdrawal button?" A customer who submitted and cancelled every withdrawal would return no rows.

The `SELECT TOP(1) 1` pattern returns a result set of one row (the constant value 1) if any matching withdrawal exists, or an empty result set if none. The caller tests for the presence of a row rather than reading a return value.

---

## 2. Business Logic

### 2.1 Active Withdrawal Status Filter

**What**: Checks for withdrawals in any active or completed state, excluding cancelled requests.

**Columns/Parameters Involved**: `CashoutStatusID` (filter: 1, 2, 3, 5, 6)

**Rules**:
- CashoutStatusID=1: Pending - withdrawal submitted but not yet processed
- CashoutStatusID=2: InProcess - withdrawal is being actively processed
- CashoutStatusID=3: Processed (26.4% of all withdrawals) - payment completed and sent
- CashoutStatusID=5 and 6: Additional approved/completed states
- CashoutStatusID=4 (Cancelled, 71.3% of all withdrawals) is explicitly excluded - cancelled requests do not count
- `TOP(1)` with `NOLOCK` makes this a near-zero-cost existence check regardless of withdrawal volume

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | integer | NO | - | CODE-BACKED | Input parameter. The customer identifier to check for active/completed withdrawals. Matched against Billing.Withdraw.CID. |
| 2 | (result column) | int | NO | - | CODE-BACKED | Output column. Constant value 1 returned when any active/completed withdrawal exists for the customer. Caller checks for presence of a row: row present = customer has withdrawals, empty result = no active/completed withdrawals found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | Billing.Withdraw | Read | Existence check - scans for any row with matching CID and active CashoutStatusID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Referenced in PROD_BIadmins permissions; called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_HasWithdrawals (procedure)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Existence check - SELECT TOP(1) 1 WHERE CID=@CID AND CashoutStatusID IN (1,2,3,5,6) WITH NOLOCK |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the check for a specific customer

```sql
EXEC Billing.WithdrawalService_HasWithdrawals @CID = 12345;
-- Returns 1 row (value=1) if customer has active/completed withdrawals; empty if none
```

### 8.2 Equivalent direct existence check

```sql
SELECT  TOP(1) 1 AS HasWithdrawals
FROM    Billing.Withdraw WITH (NOLOCK)
WHERE   CID = 12345
        AND CashoutStatusID IN (1, 2, 3, 5, 6);
```

### 8.3 Count active withdrawals per status for a customer (diagnostic query)

```sql
SELECT  CashoutStatusID,
        COUNT(*) AS WithdrawalCount
FROM    Billing.Withdraw WITH (NOLOCK)
WHERE   CID = 12345
GROUP BY CashoutStatusID
ORDER BY CashoutStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawalService_HasWithdrawals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_HasWithdrawals.sql*
