# Billing.RedeemPayoutProcess_GetNegativeBalanceRecords

> Returns all redeem payout records where the customer has a negative balance condition (status 25), ordered by last modification date.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set (no DML, no locking) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

During the redemption payout process, some redeems may be halted when the system detects that proceeding would result in or is caused by a negative account balance. `Billing.RedeemPayoutProcess_GetNegativeBalanceRecords` is the query procedure that retrieves all such stalled records for review or special processing.

RedeemStatusID=25 represents the "negative balance" exception state in the Redeem lifecycle - these are records that cannot be auto-processed and require manual intervention or a specific recovery flow.

Unlike the other GetRecords procedures in this group, this procedure does NOT acquire a processing lock (no InProcess flag update). It is a read-only query used by the monitoring or exception-handling layer.

Note: @CorrelationID is accepted as a parameter but is not used in the current implementation - likely reserved for future lock-based processing or added for API consistency.

---

## 2. Business Logic

### 2.1 Negative Balance Exception State

**What**: Retrieves redeems stuck in the negative-balance exception state for special handling.

**Columns/Parameters Involved**: `RedeemStatusID = 25`

**Rules**:
- Returns all records with RedeemStatusID=25 (NegativeBalance). No batch size limit.
- Ordered by LastModificationDate DESC (most recently updated first).
- Read-only - no updates to lock flags.
- Does not filter by InProcess flags - returns all negative-balance records regardless of processing state.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | Accepted parameter but unused in the current implementation. Maintained for API consistency with other RedeemPayoutProcess procedures. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ProcessID | INT | NO | - | CODE-BACKED | Billing.RedeemPayoutProcess.RedeemPayoutProcessID. |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | Trading position associated with the stalled redeem. |
| 4 | RedeemID | INT | NO | - | CODE-BACKED | Billing.Redeem record in NegativeBalance state (status 25). |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID of the affected account. |
| 6 | AmountOnRequest | MONEY | YES | - | CODE-BACKED | Originally requested redemption amount. Used to assess whether the negative balance can be offset. |
| 7 | LastModificationDate | DATETIME | NO | - | CODE-BACKED | When the redeem record was last updated. Result set ordered DESC by this column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemStatusID=25 | Billing.Redeem | READ | Source of negative-balance redeem records |
| ProcessID | Billing.RedeemPayoutProcess | READ | Joined to get process ID |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the exception-handling or monitoring layer for negative balance cases.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_GetNegativeBalanceRecords (procedure)
├── Billing.Redeem (table)
└── Billing.RedeemPayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Source of records with RedeemStatusID=25 |
| Billing.RedeemPayoutProcess | Table | INNER JOIN to get ProcessID |

### 6.2 Objects That Depend On This

No SQL dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No locking | Design | Read-only procedure - no InProcess flag updates. Callers must handle concurrency separately. |

---

## 8. Sample Queries

### 8.1 Get all negative balance redeems

```sql
EXEC Billing.RedeemPayoutProcess_GetNegativeBalanceRecords
    @CorrelationID = '00000000-0000-0000-0000-000000000000'
```

### 8.2 View negative balance redeems with amounts

```sql
SELECT r.RedeemID, r.CID, r.PositionID, r.AmountOnRequest, r.LastModificationDate,
       p.RedeemPayoutProcessID AS ProcessID
FROM Billing.Redeem r WITH (NOLOCK)
JOIN Billing.RedeemPayoutProcess p WITH (NOLOCK) ON r.RedeemID = p.RedeemID
WHERE r.RedeemStatusID = 25
ORDER BY r.LastModificationDate DESC
```

### 8.3 Count negative balance redeems by day

```sql
SELECT CAST(r.LastModificationDate AS DATE) AS ModDate, COUNT(*) AS Count
FROM Billing.Redeem r WITH (NOLOCK)
WHERE r.RedeemStatusID = 25
GROUP BY CAST(r.LastModificationDate AS DATE)
ORDER BY ModDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_GetNegativeBalanceRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_GetNegativeBalanceRecords.sql*
