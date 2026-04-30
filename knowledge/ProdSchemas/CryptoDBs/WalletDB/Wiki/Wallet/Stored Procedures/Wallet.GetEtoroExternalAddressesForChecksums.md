# Wallet.GetEtoroExternalAddressesForChecksums

> Returns a paginated batch of eToro external address records (using OFFSET/FETCH) for checksum generation, providing the raw address data needed to compute checksums.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated EtoroExternalAddresses rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports batch checksum generation for eToro external addresses. It returns address records in pages for a checksum computation process to iterate through, generating cryptographic checksums for each record. Unlike GetEtoroExternalAddressChecksums, this returns the raw records WITHOUT checksum data - it is the input for checksum GENERATION, not validation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple paginated SELECT using OFFSET/FETCH.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SkipRecords | int | NO | - | CODE-BACKED | Number of records to skip (OFFSET). |
| 2 | @MaxRecords | int | NO | - | CODE-BACKED | Number of records to return (FETCH NEXT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.EtoroExternalAddresses | Reader | Source of address data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroExternalAddressesForChecksums (procedure)
  └── Wallet.EtoroExternalAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON
- OFFSET @SkipRecords ROWS FETCH NEXT @MaxRecords ROWS ONLY
- ORDER BY Id

---

## 8. Sample Queries

### 8.1 Get first page
```sql
EXEC Wallet.GetEtoroExternalAddressesForChecksums @SkipRecords = 0, @MaxRecords = 100
```

### 8.2 Get second page
```sql
EXEC Wallet.GetEtoroExternalAddressesForChecksums @SkipRecords = 100, @MaxRecords = 100
```

### 8.3 Count total addresses
```sql
SELECT COUNT(*) FROM Wallet.EtoroExternalAddresses WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddressesForChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddressesForChecksums.sql*
