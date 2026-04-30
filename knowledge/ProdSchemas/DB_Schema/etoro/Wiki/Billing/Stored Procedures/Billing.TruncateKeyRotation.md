# Billing.TruncateKeyRotation

> Clears the PCI DSS key rotation staging table (Billing.KeyRotation) after a successful encryption key rotation, resetting the system to accept a new key via Billing.AddEncryptionKey.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; operates on Billing.KeyRotation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.TruncateKeyRotation` is the final cleanup step in the PCI DSS credit card encryption key rotation lifecycle. After all records in `Billing.KeyRotation` have been re-encrypted (IsProcessed=1) and the rotation is confirmed complete, this procedure truncates the staging table, releasing its disk space and signaling that the system is ready for the next key rotation cycle.

This procedure exists because `Billing.AddEncryptionKey` enforces a guard: it refuses to register a new encryption key as long as `Billing.KeyRotation` contains any rows. The explicit error message in `AddEncryptionKey` instructs operators: *"In order to truncate the table run the SP Billing.TruncateKeyRotation"*. This design prevents starting a new key rotation while a prior one is incomplete or unconfirmed.

The typical rotation lifecycle is: stage records (GetKeyRotationFundings) -> re-encrypt (application) -> verify completion -> call `TruncateKeyRotation` -> call `AddEncryptionKey` to register the new key. `TruncateKeyRotation` is a DBA-initiated step, executed only after the rotation has been fully validated.

---

## 2. Business Logic

### 2.1 Key Rotation Lifecycle Gate

**What**: TruncateKeyRotation is the prerequisite gate that must be executed before a new encryption key can be registered, enforcing serial (never concurrent) key rotations.

**Columns/Parameters Involved**: All rows in `Billing.KeyRotation`

**Rules**:
- `TRUNCATE TABLE` removes ALL rows from Billing.KeyRotation unconditionally - including any unprocessed (IsProcessed=0) rows
- After truncation, `Billing.AddEncryptionKey` will pass its `NOT EXISTS (SELECT TOP(1) * FROM Billing.KeyRotation)` guard
- IMPORTANT: This should only be called after confirming all records are fully processed (IsProcessed=1) - running it prematurely on an active rotation destroys the in-progress work
- If called during an active rotation (IsProcessed=0 rows present), the data is unrecoverable (no undo for TRUNCATE)

**Diagram**:
```
PCI Key Rotation Lifecycle:
  1. GetKeyRotationFundings -> stages credit card records into Billing.KeyRotation (IsProcessed=0)
  2. Application re-encrypts each record -> Billing.RotateEncryptionKey -> IsProcessed=1
  3. DBA verifies: SELECT * FROM Billing.KeyRotation WHERE IsProcessed=0  (should return 0 rows)
  4. EXEC Billing.TruncateKeyRotation  <- THIS PROCEDURE (clears staging table)
  5. EXEC Billing.AddEncryptionKey @KeyID=... (registers new key - now permitted)

Emergency rollback path (BEFORE TruncateKeyRotation):
  -> EXEC Billing.RollbackPCIRotation (restores Billing.Funding from backup in KeyRotation)
  -> THEN TruncateKeyRotation
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no input parameters. It operates solely on Billing.KeyRotation via TRUNCATE TABLE, removing all rows regardless of their IsProcessed state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (implicit) | Billing.KeyRotation | TRUNCATE | Removes all rows from the key rotation staging table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddEncryptionKey | Error message | Referenced procedurally | AddEncryptionKey raises an error directing the operator to run TruncateKeyRotation when KeyRotation is non-empty |
| DBA operators | - | Manual EXEC | Executed manually by DBAs after confirming key rotation is complete |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.TruncateKeyRotation (procedure)
└── Billing.KeyRotation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.KeyRotation | Table | TRUNCATE TABLE - removes all rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddEncryptionKey | Procedure | Checks KeyRotation is empty before adding a new key; instructs operators to run TruncateKeyRotation if not empty |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Critical operational note: TRUNCATE is not transactionally recoverable. Call only after full rotation verification.

---

## 8. Sample Queries

### 8.1 Verify rotation is complete before truncating
```sql
-- Confirm all records have been processed before calling TruncateKeyRotation
SELECT COUNT(*) AS UnprocessedCount
FROM Billing.KeyRotation WITH (NOLOCK)
WHERE IsProcessed = 0;
-- Should return 0 before proceeding
```

### 8.2 Check table state and then execute cleanup
```sql
-- Full pre-truncate check
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN IsProcessed = 1 THEN 1 ELSE 0 END) AS ProcessedRows,
    SUM(CASE WHEN IsProcessed = 0 THEN 1 ELSE 0 END) AS UnprocessedRows
FROM Billing.KeyRotation WITH (NOLOCK);

-- Only proceed if UnprocessedRows = 0
-- EXEC Billing.TruncateKeyRotation
```

### 8.3 Verify current encryption key after truncate and key registration
```sql
SELECT KeyID, KeyStatusID, CreatedDate
FROM Billing.EncryptionKeyManagement WITH (NOLOCK)
ORDER BY CreatedDate DESC;
-- KeyStatusID=1 = Active, KeyStatusID=2 = New/Pending
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Billing.AddEncryptionKey) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.TruncateKeyRotation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.TruncateKeyRotation.sql*
