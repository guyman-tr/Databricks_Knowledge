# Billing.RotateEncryptionKey

> Promotes the pending "New" encryption key to Active status and demotes the current Active key to Inactive, completing the PCI key rotation lifecycle transition in Billing.EncryptionKeyManagement.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; operates on KeyStatusID values |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PCI DSS compliance requires that encryption keys protecting cardholder data be rotated periodically. `Billing.RotateEncryptionKey` is the final step in the key rotation process: it atomically transitions the `Billing.EncryptionKeyManagement` table by demoting the current Active key (KeyStatusID=1) to Inactive (KeyStatusID=3) and promoting the prepared New key (KeyStatusID=2) to Active (KeyStatusID=1).

This procedure enforces a strict precondition: exactly one Active key (KeyStatusID=1) AND exactly one New key (KeyStatusID=2) must exist. If this condition is not met (e.g., two active keys, or no new key prepared), the procedure raises an error and does nothing. This prevents accidental double-rotation or rotation without a prepared key.

After this procedure runs, the new key is Active and all subsequent encrypt/decrypt operations use it. The rollback procedure `Billing.RollbackPCIRotation` can reverse the FundingData re-encryption if needed.

---

## 2. Business Logic

### 2.1 Key State Promotion

**What**: Atomic two-step key status transition from New -> Active and Active -> Inactive.

**Columns/Parameters Involved**: `KeyStatusID`

**Rules**:
- Precondition: exactly 1 key with KeyStatusID=1 (Active) AND exactly 1 key with KeyStatusID=2 (New).
- If NOT met: RAISERROR "There is more than one new key or more than one active key."
- If met: BEGIN TRAN:
  - UPDATE EncryptionKeyManagement SET KeyStatusID=3 WHERE KeyStatusID=1 (Active -> Inactive).
  - UPDATE EncryptionKeyManagement SET KeyStatusID=1 WHERE KeyStatusID=2 (New -> Active).
  - COMMIT.
- KeyStatusID values: 1=Active, 2=New (prepared, not yet active), 3=Inactive (retired).

**Diagram**:
```
KeyStatusID Lifecycle:
  2 (New/Prepared)
    |
    v [EXEC Billing.RotateEncryptionKey]
    1 (Active) <-- promoted

  1 (Active, old)
    |
    v [same execution]
    3 (Inactive) <-- demoted

Precondition: Count(KeyStatusID=1) = 1 AND Count(KeyStatusID=2) = 1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | No input parameters. Automatically promotes KeyStatusID=2 to 1 and demotes KeyStatusID=1 to 3. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Key status changes | Billing.EncryptionKeyManagement | UPDATE | Promotes New key to Active; demotes Active to Inactive |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RollbackPCIRotation | KeyStatusID=1 lookup | Reads (not calls) | Uses the Active key version determined after rotation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RotateEncryptionKey (procedure)
└── Billing.EncryptionKeyManagement (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.EncryptionKeyManagement | Table | Status counts check + key status UPDATE |

### 6.2 Objects That Depend On This

No SQL procedure callers. Called by the DBA/key management process as part of the scheduled key rotation workflow.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Precondition check | Business rule | Exactly 1 Active + 1 New key required. Prevents rotation in invalid states. |
| XACT_ABORT ON | Safety | Any error aborts transaction immediately. |
| Atomic transaction | Integrity | Both key status changes are in a single BEGIN/COMMIT TRAN - never partial rotation. |

---

## 8. Sample Queries

### 8.1 Check current key state before rotation

```sql
SELECT KeyVersion, KeyStatusID,
       CASE KeyStatusID WHEN 1 THEN 'Active' WHEN 2 THEN 'New' WHEN 3 THEN 'Inactive' END AS Status
FROM Billing.EncryptionKeyManagement WITH (NOLOCK)
ORDER BY KeyStatusID
```

### 8.2 Execute key rotation (DBA-controlled)

```sql
-- Precondition: exactly 1 Active + 1 New key must exist
EXEC Billing.RotateEncryptionKey
```

### 8.3 Verify rotation completed

```sql
SELECT KeyVersion, KeyStatusID,
       CASE KeyStatusID WHEN 1 THEN 'Active (new)' WHEN 3 THEN 'Inactive (old)' END AS Status,
       ModificationDate
FROM Billing.EncryptionKeyManagement WITH (NOLOCK)
WHERE KeyStatusID IN (1, 3)
ORDER BY ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 7/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related analyzed (RollbackPCIRotation) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RotateEncryptionKey | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RotateEncryptionKey.sql*
