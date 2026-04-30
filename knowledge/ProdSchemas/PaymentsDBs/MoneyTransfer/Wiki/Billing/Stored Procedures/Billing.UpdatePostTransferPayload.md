# Billing.UpdatePostTransferPayload

> Updates the payload content of a post-transfer action, replacing the masked operational data with updated provider response or processing details.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.UpdatePostTransferPayload updates the Payload field on a post-transfer action. The payload contains the operational details of the follow-up operation - provider responses, processing metadata, or updated fund movement details - and may need to be updated as the action progresses through its lifecycle.

This procedure is called when the payment provider returns additional data about the post-transfer action, or when processing steps need to append or replace the original payload content. Unlike PostTransferStatusID (updated by UpdatePostTransferStatus), the payload is the data content rather than the lifecycle state.

---

## 2. Business Logic

No complex business logic. Single-column UPDATE of Payload by ReferenceID. No status validation. The PostTransferActions table has no modification timestamp trigger, so the update time is not tracked.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Payload | VARCHAR(MAX) | NO | - | CODE-BACKED | Updated payload content. Replaces the existing Payload in Billing.PostTransferActions. Contains provider-specific operational data (PII-protected by Dynamic Data Masking). |
| 2 | @RefID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Business reference GUID. Maps to Billing.PostTransferActions.ReferenceID (indexed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.PostTransferActions | Write (UPDATE) | Sets Payload WHERE ReferenceID = @RefID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdatePostTransferPayload (procedure)
  └── Billing.PostTransferActions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PostTransferActions | Table | UPDATE target - sets Payload WHERE ReferenceID = @RefID |

### 6.2 Objects That Depend On This

No dependents found in the database.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update action payload
```sql
EXEC Billing.UpdatePostTransferPayload
    @Payload = '{"status":"completed","providerRef":"ABC123"}',
    @RefID = '7418D7FB-CBFD-4288-A1CD-7B0C033E910D'
```

### 8.2 Check current payload (privileged user only - masked otherwise)
```sql
SELECT PostTransferActionID, ReferenceID, Payload, PostTransferStatusID
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE ReferenceID = '7418D7FB-CBFD-4288-A1CD-7B0C033E910D'
```

### 8.3 Find actions with NULL payload
```sql
SELECT TOP 10 PostTransferActionID, TransferID, PostTransferStatusID, CreateDate
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE Payload IS NULL
ORDER BY PostTransferActionID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.UpdatePostTransferPayload | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.UpdatePostTransferPayload.sql*
