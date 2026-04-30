# Wallet.StoreChecksum

> Stores a cryptographic integrity checksum for a wallet or pool wallet record with idempotency protection, preventing duplicate checksums for the same record+type+version combination.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Checksums with idempotency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure stores a computed integrity checksum for a wallet or pool wallet. The executer service calls this after computing a checksum (hash + salt + signature) for a record. Idempotent: if a checksum already exists for the same ChecksumTypeId + RecordId + SecretVersion, the INSERT is silently skipped. This ensures checksum computation is safe to retry.

---

## 2. Business Logic

### 2.1 Idempotent Checksum Storage

**What**: Only inserts if no checksum exists for this combination.

**Rules**:
- WHERE NOT EXISTS (Checksums WHERE ChecksumTypeId + RecordId + SecretVersion match)
- Silent skip on duplicate (no error)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ChecksumTypeId | tinyint | NO | - | VERIFIED | Type of record: wallet or pool wallet. FK to Dictionary.ChecksumTypes. |
| 2 | @RecordId | varchar(128) | NO | - | VERIFIED | ID of the record being checksummed (WalletRecordId or WalletPoolId). |
| 3 | @SecretVersion | varchar(255) | NO | - | VERIFIED | Checksum secret version (rotated periodically). |
| 4 | @Salt | nvarchar(255) | NO | - | CODE-BACKED | Cryptographic salt used in computation. |
| 5 | @Checksum | varbinary(max) | NO | - | CODE-BACKED | Computed checksum hash. |
| 6 | @Signature | varbinary(max) | NO | - | CODE-BACKED | Digital signature of the checksum. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Checksums | INSERT | Checksum storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Checksum computation storage |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreChecksum (procedure)
+-- Wallet.Checksums (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Checksums | Table | INSERT with idempotency |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Store a checksum
```sql
EXEC Wallet.StoreChecksum @ChecksumTypeId=1, @RecordId='12345', @SecretVersion='v2.0', @Salt='salt-value', @Checksum=0xABCD, @Signature=0xEF01;
```

### 8.2 Check if checksum exists
```sql
SELECT * FROM Wallet.Checksums WITH (NOLOCK) WHERE ChecksumTypeId = 1 AND RecordId = '12345' AND SecretVersion = 'v2.0';
```

### 8.3 Count checksums by type and version
```sql
SELECT ct.Name, c.SecretVersion, COUNT(*) FROM Wallet.Checksums c WITH (NOLOCK) JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Id = c.ChecksumTypeId GROUP BY ct.Name, c.SecretVersion;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreChecksum | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreChecksum.sql*
