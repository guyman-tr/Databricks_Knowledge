# Billing.UpdateEncryptionKey

> Updates the status of a PCI DSS encryption key in Billing.EncryptionKeyManagement - primarily used to deactivate a key (set status to Inactive=3, the default) outside the normal rotation cycle.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @KeyID (UNIQUEIDENTIFIER) - targets Billing.EncryptionKeyManagement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateEncryptionKey` is the manual key status override for the PCI DSS encryption key lifecycle. It allows the PCI rotation team to directly set the `KeyStatusID` of a specific encryption key by its GUID identifier - without going through the structured `Billing.RotateEncryptionKey` transaction (which atomically promotes New->Active while demoting Active->Inactive).

The default parameter `@KeyStatusID=3` (Inactive) signals the most common use case: deactivating a key that is no longer valid due to a compromise, emergency rotation, or lifecycle end, outside of the standard rotation process.

Called exclusively by the `PCI_Rotation` role - restricted to PCI DSS compliance operators who manage the credit card encryption key infrastructure. `Billing.EncryptionKeyManagement` stores 5 rows total (key history), with 1 currently Active key at any time.

**Key status values**:
- `1` = Active - the current encryption key used for new credit card data
- `2` = New - a key staged for the next rotation
- `3` = Inactive - a retired key, kept for decryption of historical data

---

## 2. Business Logic

### 2.1 Manual Key Status Override

**What**: Directly sets the status of a specific encryption key, enabling emergency deactivation, status corrections, or manual lifecycle management outside the structured rotation process.

**Columns/Parameters Involved**: `@KeyID`, `@KeyStatusID`, `Billing.EncryptionKeyManagement.KeyStatusID`

**Rules**:
- `UPDATE Billing.EncryptionKeyManagement SET KeyStatusID = @KeyStatusID WHERE KeyID = @KeyID`
- Default `@KeyStatusID = 3` (Inactive): the procedure defaults to deactivation if no status is specified
- No prior-state validation - unconditional assignment
- No FK constraint on KeyStatusID in the table - invalid values will not be caught by the database
- If `@KeyID` does not exist, the UPDATE silently affects 0 rows

**Key lifecycle context**:
```
Normal rotation path (structured):
  Billing.AddEncryptionKey -> inserts new key at status=2 (New)
  Billing.RotateEncryptionKey -> atomically: Active(1)->Inactive(3), New(2)->Active(1)
  Billing.TruncateKeyRotation -> clears staging table, enabling next rotation

Manual override path (this procedure):
  Billing.UpdateEncryptionKey @KeyID='...', @KeyStatusID=3
  -> Marks specific key as Inactive (e.g., emergency deactivation, compromise response)
  -> Does NOT trigger the full rotation transaction
  -> Caller must ensure exactly 1 Active key remains after the call
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @KeyID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | GUID identifier of the encryption key to update. Maps to `Billing.EncryptionKeyManagement.KeyID`. This is a reference identifier (not the cryptographic key material itself) used to locate the key in an external key management system. If @KeyID does not exist in the table, the UPDATE silently affects 0 rows. |
| 2 | @KeyStatusID | INT | YES | 3 | CODE-BACKED | Target status to assign. DEFAULT=3 (Inactive). Valid values: 1=Active (current key for new encryptions), 2=New (staged for next rotation), 3=Inactive (retired; retained for decrypting historical data). No FK constraint enforced - caller responsible for valid values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE KeyID | Billing.EncryptionKeyManagement | UPDATE | Sets KeyStatusID on the specified encryption key record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PCI Rotation operators | @KeyID, @KeyStatusID | EXEC (PCI_Rotation role) | Called manually for emergency deactivations or status corrections outside the normal rotation cycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateEncryptionKey (procedure)
`- Billing.EncryptionKeyManagement (table) - UPDATE target

PCI Key Rotation ecosystem:
  Billing.AddEncryptionKey (insert New key)
  Billing.RotateEncryptionKey (structured Active/New swap)
  Billing.UpdateEncryptionKey (manual status override)
  Billing.TruncateKeyRotation (cleanup after rotation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.EncryptionKeyManagement | Table | UPDATE - sets KeyStatusID WHERE KeyID=@KeyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called manually by PCI Rotation operators (PCI_Rotation role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. `Billing.EncryptionKeyManagement` is a tiny 5-row table; the WHERE clause on `KeyID` (UNIQUEIDENTIFIER) uses a table scan but this is negligible for a 5-row table.

### 7.2 Constraints

N/A for stored procedure. Critical operational note: This procedure does NOT enforce the "exactly 1 Active key" invariant. After calling this SP to deactivate a key, the PCI rotation team must verify that exactly 1 key remains in status=1 (Active). Use `Billing.RotateEncryptionKey` for the structured rotation that atomically maintains this invariant.

---

## 8. Sample Queries

### 8.1 Deactivate a specific key (emergency rotation or compromise)
```sql
-- Default: @KeyStatusID=3 (Inactive)
EXEC Billing.UpdateEncryptionKey @KeyID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
-- Equivalent explicit call:
EXEC Billing.UpdateEncryptionKey @KeyID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', @KeyStatusID = 3;
```

### 8.2 Verify key status after update
```sql
SELECT KeyID, KeyVersion, KeyStatusID, CreatedDate
FROM Billing.EncryptionKeyManagement WITH (NOLOCK)
ORDER BY CreatedDate DESC;
-- KeyStatusID: 1=Active, 2=New, 3=Inactive
-- Should always have exactly 1 row with KeyStatusID=1 (Active)
```

### 8.3 Stage a key as New (before rotation)
```sql
-- Mark a key as staged for the next rotation cycle
EXEC Billing.UpdateEncryptionKey @KeyID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', @KeyStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (AddEncryptionKey, RotateEncryptionKey, TruncateKeyRotation ecosystem) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateEncryptionKey | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateEncryptionKey.sql*
