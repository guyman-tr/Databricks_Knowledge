# Wallet.ManualApproveTransactionStatuses

> Links manual approval transactions to their approval workflow statuses, tracking whether a flagged transaction is pending, approved, rejected, or sent.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: (ManualApproveTransactionId, ManualApproveTransactionStatusId) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table links manual approval transactions (from `Wallet.ManualApproveTransaction`) to their approval statuses (from `Dictionary.ManualApproveTransactionStatus`). The composite PK records each status a transaction has reached. Currently empty (parent table is also empty), suggesting the manual approval flow is not actively used or has been replaced.

See [Manual Approve Transaction Status](../../_glossary.md#manual-approve-transaction-status) for values: 1=Pending, 2=Approved, 3=Rejected, 4=Sent.

---

## 2. Business Logic

No complex logic. Simple status-to-transaction junction table.

---

## 3. Data Overview

Table is empty (parent table ManualApproveTransaction is also empty).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManualApproveTransactionId | int | NO | - | CODE-BACKED | Parent manual approval transaction. Part of composite PK. Implicit reference to Wallet.ManualApproveTransaction.Id. |
| 2 | ManualApproveTransactionStatusId | int | NO | - | VERIFIED | Approval status: 1=Pending, 2=Approved, 3=Rejected, 4=Sent. FK to Dictionary.ManualApproveTransactionStatus. See [Manual Approve Transaction Status](../../_glossary.md#manual-approve-transaction-status). Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManualApproveTransactionStatusId | Dictionary.ManualApproveTransactionStatus | FK | Approval status value |

### 5.2 Referenced By (other objects point to this)

Not directly referenced.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ManualApproveTransactionStatuses (table)
└── Dictionary.ManualApproveTransactionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ManualApproveTransactionStatus | Table | FK target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddManualApproveTransactionStatus | Stored Procedure | Inserts statuses |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManualApproveTransactionStatuses_... | CLUSTERED PK | ManualApproveTransactionId, ManualApproveTransactionStatusId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_...ManualApproveTransactionStatusId | FK | -> Dictionary.ManualApproveTransactionStatus.Id |

---

## 8. Sample Queries

### 8.1 Get statuses for a transaction
```sql
SELECT mats.ManualApproveTransactionStatusId, dma.Name AS Status
FROM Wallet.ManualApproveTransactionStatuses mats WITH (NOLOCK)
JOIN Dictionary.ManualApproveTransactionStatus dma WITH (NOLOCK) ON mats.ManualApproveTransactionStatusId = dma.Id
WHERE mats.ManualApproveTransactionId = 1
```

### 8.2 Count by status
```sql
SELECT dma.Name, COUNT(*) AS Cnt
FROM Wallet.ManualApproveTransactionStatuses mats WITH (NOLOCK)
JOIN Dictionary.ManualApproveTransactionStatus dma WITH (NOLOCK) ON mats.ManualApproveTransactionStatusId = dma.Id
GROUP BY dma.Name
```

### 8.3 Pending approvals
```sql
SELECT ManualApproveTransactionId FROM Wallet.ManualApproveTransactionStatuses WITH (NOLOCK)
WHERE ManualApproveTransactionStatusId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ManualApproveTransactionStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ManualApproveTransactionStatuses.sql*
