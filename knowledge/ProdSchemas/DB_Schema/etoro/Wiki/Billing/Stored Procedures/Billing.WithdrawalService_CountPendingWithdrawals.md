# Billing.WithdrawalService_CountPendingWithdrawals

> Returns the count of pending (CashoutStatusID=1) withdrawal requests for a given customer. Used by the Withdrawal Service to check if a customer has existing open withdrawal requests before allowing a new one.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawalService_CountPendingWithdrawals` is a lightweight check procedure used by the Withdrawal Service to count how many withdrawal requests a customer currently has in Pending status (CashoutStatusID=1). Business rules typically limit the number of concurrent pending withdrawals a customer can have to prevent abuse or operational backlogs.

The DDL comment says "new SP for billing service" - this was created specifically for the Withdrawal Service application to call before allowing a new withdrawal request to be submitted.

---

## 2. Business Logic

### 2.1 Pending Withdrawal Count

**What**: Counts pending withdrawals for a customer.

**Rules**:
- `SELECT COUNT(*) AS NumOfPendings FROM Billing.Withdraw WITH (NOLOCK) WHERE CID = @CID AND CashoutStatusID = 1`
- CashoutStatusID=1 = Pending/Requested
- WITH(NOLOCK): read without locking (acceptable for this count check)
- Returns exactly one row: `NumOfPendings INT`
- RETURN 0 always (no business-level error codes)
- No error handling beyond RETURN 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters `Billing.Withdraw.CID` to count only this customer's pending withdrawals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Withdraw | SELECT (COUNT) | Counts pending withdrawal records for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal Service (application) | Pre-withdrawal check | Application call | Validates pending withdrawal count before allowing new withdrawal submission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_CountPendingWithdrawals (procedure)
+-- Billing.Withdraw (table) [SELECT COUNT - CashoutStatusID=1]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | COUNT WHERE CID=@CID AND CashoutStatusID=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal Service (application) | Application | Calls to enforce concurrent withdrawal limits per customer |
| Billing.WithdrawRequestAdd | Stored Procedure | Likely called as a pre-check before creating a new withdrawal |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH(NOLOCK) | Concurrency | Non-blocking read; dirty reads possible but acceptable for a count check |
| RETURN 0 always | Design | No error signaling; callers interpret NumOfPendings themselves |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Check pending withdrawals for a customer
```sql
EXEC Billing.WithdrawalService_CountPendingWithdrawals
    @CID = 123456;
-- Returns: NumOfPendings INT
```

### 8.2 Inline check
```sql
SELECT COUNT(*) AS NumOfPendings
FROM Billing.Withdraw WITH (NOLOCK)
WHERE CID = 123456
  AND CashoutStatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WithdrawalService_CountPendingWithdrawals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_CountPendingWithdrawals.sql*
