# Wallet.GetEtoroExternalAddressChecksums

> Retrieves paginated eToro external address records with their checksum data for integrity verification, using a temp table cache that refreshes daily for performance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns addresses + checksums from cached temp table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports the checksum validation process for eToro external addresses. It returns address records paired with their cryptographic checksums (if they exist) for a given secret version. To avoid expensive JOIN operations on every call, it caches the results in TempGetEtoroExternalAddressChecksums and refreshes the cache daily or when starting from the beginning (IdGreaterThan=0).

---

## 2. Business Logic

### 2.1 Daily Cache Refresh

**What**: Rebuilds the temp table cache once per day for performance.

**Columns/Parameters Involved**: TempGetEtoroExternalAddressChecksums, @IdGreaterThan

**Rules**:
- If @IdGreaterThan = 0 (first page) OR cache is older than today: TRUNCATE and rebuild
- Cache includes all EtoroExternalAddresses LEFT JOINed with Checksums for the specified SecretVersion
- Subsequent pages read from cache without rebuild
- OPTION (RECOMPILE) on the final SELECT for optimal plan with variable TOP

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) | NO | - | CODE-BACKED | The checksum secret/key version to match. Different versions coexist during key rotation. |
| 2 | @IdGreaterThan | bigint | NO | - | CODE-BACKED | Keyset pagination cursor. 0 = first page (triggers cache rebuild). |
| 3 | @MaxRecords | int | NO | - | CODE-BACKED | Maximum records per page. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.EtoroExternalAddresses | Reader | Source of addresses |
| - | Wallet.Checksums | Reader | Source of checksum data |
| - | Dictionary.ChecksumTypes | Reader | Resolves "EtoroExternalAddress" type name |
| - | TempGetEtoroExternalAddressChecksums | Reader/Writer | Cache table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroExternalAddressChecksums (procedure)
  ├── Wallet.EtoroExternalAddresses (table)
  ├── Wallet.Checksums (table)
  ├── Dictionary.ChecksumTypes (table)
  └── TempGetEtoroExternalAddressChecksums (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | Cache source |
| Wallet.Checksums | Table | LEFT JOIN for checksum data |
| Dictionary.ChecksumTypes | Table | Resolves checksum type name |
| TempGetEtoroExternalAddressChecksums | Table | Cache read/write |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- TRUNCATE TABLE for cache rebuild
- NOLOCK hints
- OPTION (RECOMPILE) on final SELECT
- PRINT statement for cache rebuild logging

---

## 8. Sample Queries

### 8.1 Get first page of checksums
```sql
EXEC Wallet.GetEtoroExternalAddressChecksums @SecretVersion = 'v1', @IdGreaterThan = 0, @MaxRecords = 100
```

### 8.2 Get next page
```sql
EXEC Wallet.GetEtoroExternalAddressChecksums @SecretVersion = 'v1', @IdGreaterThan = 500, @MaxRecords = 100
```

### 8.3 Check addresses missing checksums
```sql
SELECT eea.Id, eea.Address
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Name = 'EtoroExternalAddress'
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id AND c.RecordId = eea.Id
WHERE c.Id IS NULL AND eea.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddressChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddressChecksums.sql*
