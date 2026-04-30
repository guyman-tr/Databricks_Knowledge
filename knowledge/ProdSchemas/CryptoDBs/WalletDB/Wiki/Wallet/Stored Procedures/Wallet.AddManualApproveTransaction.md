# Wallet.AddManualApproveTransaction

> Inserts a new manual approval transaction record, capturing a correlation ID and JSON data payload for transactions requiring human review before processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.ManualApproveTransaction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a manual approval transaction entry when a crypto transaction (typically a withdrawal or send) exceeds automated approval thresholds and requires human review. Transactions may be flagged for manual approval due to AML screening results, amount thresholds, suspicious patterns, or other compliance rules.

Without this procedure, the system could not queue transactions for human review, and all flagged transactions would remain in limbo. Manual approval is a key compliance control in the crypto withdrawal pipeline.

The procedure is called by the application service layer when a transaction is flagged. The @Data JSON contains the full transaction context needed by the compliance reviewer. The AmlUser role has EXECUTE permission on this procedure, indicating it is part of the AML/compliance workflow.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple INSERT with no conditional branching. The @Data JSON payload carries all business context but is opaque to the SQL layer. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links this manual approval entry to the parent transaction request. Used to correlate the approval decision back to the original send/withdrawal request. |
| 2 | @Data | nvarchar(3000) | NO | - | CODE-BACKED | JSON payload containing the full transaction context for the reviewer: amount, destination address, customer details, AML screening results, risk scores, and any flags that triggered manual review. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Wallet.ManualApproveTransaction | Writer | Creates the manual approval entry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser (role) | - | Permission | AmlUser role has EXECUTE permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddManualApproveTransaction (procedure)
  └── Wallet.ManualApproveTransaction (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualApproveTransaction | Table | INSERT target |

### 6.2 Objects That Depend On This

No SQL-level dependents found. Called by application services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Simple INSERT with no validation.

---

## 8. Sample Queries

### 8.1 View recent manual approval transactions
```sql
SELECT TOP 20 Id, CorrelationId, Data, Created
FROM Wallet.ManualApproveTransaction WITH (NOLOCK)
ORDER BY Id DESC
```

### 8.2 Find a manual approval entry by correlation ID
```sql
SELECT Id, CorrelationId, Data
FROM Wallet.ManualApproveTransaction WITH (NOLOCK)
WHERE CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.3 Check manual approval entries with their latest status
```sql
SELECT mat.Id, mat.CorrelationId, mats.ManualApproveTransactionStatusId, mats.Created AS StatusDate
FROM Wallet.ManualApproveTransaction mat WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 ManualApproveTransactionStatusId, Created
    FROM Wallet.ManualApproveTransactionStatuses WITH (NOLOCK)
    WHERE ManualApproveTransactionId = mat.Id
    ORDER BY Id DESC
) mats
ORDER BY mat.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddManualApproveTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddManualApproveTransaction.sql*
