# Billing.GetEncryptionKeys

> Returns the full encryption key registry (KeyID, KeyVersion, KeyStatusID) from Billing.EncryptionKeyManagement - used by the key rotation service, PCI rotation process, and funding service to discover available encryption keys.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Billing.EncryptionKeyManagement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetEncryptionKeys` is the key registry reader for eToro's payment card encryption infrastructure. It returns the full list of encryption keys (by ID, version, and status) stored in `Billing.EncryptionKeyManagement`.

This SP is called by three services:
- **KeyRotationServiceUser** - the key rotation automation service that periodically rotates encryption keys for PCI compliance
- **PCI_Rotation** - the PCI key rotation process account
- **FundingUser** - the funding/payment instrument service, which needs to know which keys are active for encrypting card data

The SP returns key metadata only (KeyID, KeyVersion, KeyStatusID) - not the actual cryptographic key material. The actual keys are stored in the table but not exposed here, maintaining separation of concerns: this SP provides the key catalog, not the key values.

---

## 2. Business Logic

### 2.1 Full Key Registry Retrieval

**What**: Returns all encryption keys with their version and status - no filtering.

**Rules**:
- `SELECT KeyID, KeyVersion, KeyStatusID FROM Billing.EncryptionKeyManagement` - no WHERE clause; returns ALL keys
- Callers filter by KeyStatusID to find active keys
- KeyStatusID values: likely 1=Active, 2=Retired/Expired, etc. (from Billing.EncryptionKeyManagement design)
- No NOLOCK - committed reads for security-sensitive key metadata

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | KeyID (output) | INT | NO | - | CODE-BACKED | Primary key of the encryption key record. |
| 2 | KeyVersion (output) | INT/VARCHAR | NO | - | CODE-BACKED | Version number of the encryption key. Used for key versioning in PCI key rotation workflows. |
| 3 | KeyStatusID (output) | INT | NO | - | CODE-BACKED | Status of the encryption key. Callers use this to identify active vs. retired keys. Active keys are used for new encryption; retired keys may still be needed for decrypting old data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Billing.EncryptionKeyManagement | Read | Returns full key registry metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KeyRotationServiceUser | GRANT EXECUTE | Permission | Key rotation automation service reads registry during rotation workflow |
| PCI_Rotation | GRANT EXECUTE | Permission | PCI key rotation process reads registry |
| FundingUser | GRANT EXECUTE | Permission | Funding service reads active keys for card data encryption |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetEncryptionKeys (procedure)
└── Billing.EncryptionKeyManagement (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.EncryptionKeyManagement | Table | Read - returns all key records (KeyID, KeyVersion, KeyStatusID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KeyRotationServiceUser (key rotation service) | DB User | Reads key registry during PCI rotation |
| PCI_Rotation | DB User | PCI key rotation process |
| FundingUser (funding service) | DB User | Reads active keys for card encryption |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Security | Committed reads for key management data; avoids reading partially-updated key state during rotation |
| Key material not exposed | Security | Only KeyID, KeyVersion, KeyStatusID returned - not the actual cryptographic key material stored in the table |

---

## 8. Sample Queries

### 8.1 Get all encryption keys

```sql
EXEC Billing.GetEncryptionKeys;
```

### 8.2 Inline equivalent to find active keys

```sql
SELECT KeyID, KeyVersion, KeyStatusID
FROM Billing.EncryptionKeyManagement
WHERE KeyStatusID = 1;  -- 1 = Active (caller-side filter)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.5/10 (Elements: 7/10, Logic: 5/10, Relationships: 7/10, Sources: 0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (KeyRotationServiceUser, PCI_Rotation, FundingUser) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetEncryptionKeys | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetEncryptionKeys.sql*
