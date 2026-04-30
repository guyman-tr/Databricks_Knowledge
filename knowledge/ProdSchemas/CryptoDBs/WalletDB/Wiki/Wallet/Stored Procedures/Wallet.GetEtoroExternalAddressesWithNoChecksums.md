# Wallet.GetEtoroExternalAddressesWithNoChecksums

> Returns eToro external addresses that have no checksum records in the Infra.Checksum table, identifying addresses that need initial checksum generation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns addresses missing Infra.Checksum records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies eToro external addresses that have never had a checksum generated. These are addresses that need initial checksum computation for data integrity protection. It uses the Infra.Checksum table (different from Wallet.Checksums used by other checksum procedures), suggesting this is part of an older or alternative checksum system.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. LEFT JOIN anti-pattern to find missing records.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxRecords | int | NO | - | CODE-BACKED | Maximum number of addresses to return. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.EtoroExternalAddresses | Reader | Source of addresses |
| - | Infra.Checksum | Reader | LEFT JOIN to find missing checksums |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroExternalAddressesWithNoChecksums (procedure)
  ├── Wallet.EtoroExternalAddresses (table)
  └── Infra.Checksum (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | SELECT source |
| Infra.Checksum | Table | LEFT JOIN anti-pattern |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints, SET NOCOUNT ON
- TOP(@MaxRecords) ORDER BY Id
- Uses Infra.Checksum (not Wallet.Checksums) with ChecksumType = 'EtoroExternalAddress'

---

## 8. Sample Queries

### 8.1 Find addresses without checksums
```sql
EXEC Wallet.GetEtoroExternalAddressesWithNoChecksums @MaxRecords = 100
```

### 8.2 Count addresses missing checksums
```sql
SELECT COUNT(*)
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = eea.Id AND c.ChecksumType = 'EtoroExternalAddress'
WHERE c.Id IS NULL
```

### 8.3 Compare checksum coverage
```sql
SELECT 'Has Checksum' AS Status, COUNT(*) AS Cnt
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = eea.Id AND c.ChecksumType = 'EtoroExternalAddress'
UNION ALL
SELECT 'Missing', COUNT(*)
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = eea.Id AND c.ChecksumType = 'EtoroExternalAddress'
WHERE c.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddressesWithNoChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddressesWithNoChecksums.sql*
