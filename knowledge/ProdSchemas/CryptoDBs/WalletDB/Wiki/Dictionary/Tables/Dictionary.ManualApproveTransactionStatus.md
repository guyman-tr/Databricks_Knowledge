# Dictionary.ManualApproveTransactionStatus

> Lookup table defining the lifecycle statuses for transactions requiring manual compliance approval before execution.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the workflow statuses for cryptocurrency transactions that are flagged for manual approval by the compliance or operations team. Certain high-risk or high-value transactions cannot proceed automatically and require human review before they are sent to the blockchain.

Manual approval is a critical compliance control. When a transaction triggers manual review rules (e.g., exceeds a threshold, involves a flagged address, or matches a risk pattern), it enters this workflow. Compliance officers review the transaction details, and either approve it for execution or reject it.

The table is FK-referenced by `Wallet.ManualApproveTransactionStatuses` and consumed by approval workflow stored procedures.

---

## 2. Business Logic

### 2.1 Manual Approval Workflow

**What**: Four-state lifecycle for manually reviewed transactions.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Pending` (1): Transaction awaiting compliance review. Sits in the approval queue until an authorized reviewer acts on it.
- `Approved` (2): Reviewer approved the transaction. It proceeds to the normal execution flow (sent to blockchain provider).
- `Rejected` (3): Reviewer rejected the transaction. Funds are returned to the customer's wallet balance. A rejection reason may be recorded.
- `Sent` (4): Approved transaction has been submitted to the blockchain for execution. Terminal state for the approval workflow; further tracking continues in the sent transaction lifecycle.

**Diagram**:
```
Transaction flagged --> Pending (1)
                          |
              +-----------+-----------+
              |                       |
         Approved (2)           Rejected (3)
              |                  [Funds returned]
              v
          Sent (4)
      [Submitted to blockchain]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Pending | Transaction is in the manual review queue. A compliance officer must examine the transaction details (amount, destination address, risk flags) and make an approve/reject decision. Time-sensitive - delays may affect the customer experience. |
| 2 | Approved | Compliance officer has reviewed and approved the transaction. The system proceeds to execute the transaction through the normal blockchain submission flow. |
| 3 | Rejected | Compliance officer has reviewed and rejected the transaction. The customer's funds are released back to their wallet balance. The rejection should include a reason for audit trail purposes. |
| 4 | Sent | The approved transaction has been submitted to the blockchain provider for execution. This is the handoff point from the manual approval workflow to the standard transaction monitoring workflow. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Unique identifier for the approval status. Values: 1=Pending, 2=Approved, 3=Rejected, 4=Sent. FK target for Wallet.ManualApproveTransactionStatuses. |
| 2 | Name | varchar(24) | NO | - | CODE-BACKED | Short label for the status. Notably uses varchar(24) - smaller than typical Dictionary tables (varchar(64)) - suggesting this was designed for compact status display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ManualApproveTransactionStatuses | ManualApproveTransactionStatusId | FK | Records status transitions for manual approval transactions |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualApproveTransactionStatuses | Table | FK on ManualApproveTransactionStatusId |
| Wallet.GetPendingManualApproveTransactions | Stored Procedure | Filters for Pending status |
| Wallet.GetManualApprovedTransactions | Stored Procedure | Filters for Approved status |
| Wallet.AddManualApproveTransactionStatus | Stored Procedure | Inserts status transitions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManualApproveTransactionStatus | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all manual approval statuses
```sql
SELECT Id, Name FROM Dictionary.ManualApproveTransactionStatus WITH (NOLOCK) ORDER BY Id
```

### 8.2 Pending transactions awaiting approval
```sql
SELECT mat.Id, mats.Name AS Status, mat.Created
FROM Wallet.ManualApproveTransaction mat WITH (NOLOCK)
JOIN Wallet.ManualApproveTransactionStatuses mats_r WITH (NOLOCK) ON mats_r.ManualApproveTransactionId = mat.Id
JOIN Dictionary.ManualApproveTransactionStatus mats WITH (NOLOCK) ON mats_r.ManualApproveTransactionStatusId = mats.Id
WHERE mats.Id = 1 -- Pending
```

### 8.3 Approval rate analysis
```sql
SELECT mats.Name AS Status, COUNT(*) AS Count
FROM Wallet.ManualApproveTransactionStatuses r WITH (NOLOCK)
JOIN Dictionary.ManualApproveTransactionStatus mats WITH (NOLOCK) ON r.ManualApproveTransactionStatusId = mats.Id
GROUP BY mats.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ManualApproveTransactionStatus | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ManualApproveTransactionStatus.sql*
