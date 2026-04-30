# Wallet.GetEtoroExternalAddressWithoutChecksum

> Returns active eToro external addresses that are missing checksums for a specific secret version, using paginated keyset access for batch checksum generation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns active addresses without checksums for a secret version |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies active eToro external addresses that do not yet have a checksum for the specified secret version. During key rotation, a new secret version is introduced and all existing addresses need new checksums generated. This procedure returns the addresses that still need processing, enabling incremental batch checksum generation. Unlike GetEtoroExternalAddressesWithNoChecksums (which uses Infra.Checksum), this uses Wallet.Checksums with a specific SecretVersion and only returns active addresses.

---

## 2. Business Logic

### 2.1 Version-Specific Checksum Gap Detection

**What**: Finds addresses missing checksums for a SPECIFIC secret version.

**Columns/Parameters Involved**: `@SecretVersion`, Wallet.Checksums, Dictionary.ChecksumTypes

**Rules**:
- Resolves ChecksumTypeId via Dictionary.ChecksumTypes WHERE Name = 'EtoroExternalAddress'
- LEFT JOINs to Wallet.Checksums matching the type, record, AND secret version
- Only returns rows where checksum is NULL (c.Id IS NULL)
- Only active addresses (IsActive = 1)
- Uses temp table for intermediate results

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) | NO | - | CODE-BACKED | The checksum secret/key version to check for. Addresses missing checksums for THIS version are returned. |
| 2 | @IdGreaterThan | bigint | NO | - | CODE-BACKED | Keyset pagination cursor. |
| 3 | @MaxRecords | int | NO | - | CODE-BACKED | Maximum records per page. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.EtoroExternalAddresses | Reader | Source of addresses |
| - | Wallet.Checksums | Reader | LEFT JOIN for checksum gap detection |
| - | Dictionary.ChecksumTypes | Reader | Resolves type name to ID |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroExternalAddressWithoutChecksum (procedure)
  ├── Wallet.EtoroExternalAddresses (table)
  ├── Wallet.Checksums (table)
  └── Dictionary.ChecksumTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | SELECT source |
| Wallet.Checksums | Table | LEFT JOIN anti-pattern |
| Dictionary.ChecksumTypes | Table | Type name resolution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints, SET NOCOUNT ON
- DROP TABLE IF EXISTS for temp table cleanup
- Uses temp table #GetEtoroExternalAddressWithoutChecksum
- TOP(@MaxRecords) ORDER BY Id on temp table

---

## 8. Sample Queries

### 8.1 Find addresses missing v2 checksums
```sql
EXEC Wallet.GetEtoroExternalAddressWithoutChecksum @SecretVersion = 'v2', @IdGreaterThan = 0, @MaxRecords = 100
```

### 8.2 Count missing checksums per version
```sql
SELECT c.SecretVersion, COUNT(*) AS HasChecksum
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Name = 'EtoroExternalAddress'
JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id AND c.RecordId = eea.Id
WHERE eea.IsActive = 1
GROUP BY c.SecretVersion
```

### 8.3 Total active addresses
```sql
SELECT COUNT(*) FROM Wallet.EtoroExternalAddresses WITH (NOLOCK) WHERE IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddressWithoutChecksum | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddressWithoutChecksum.sql*
