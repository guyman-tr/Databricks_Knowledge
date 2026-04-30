# Infra.ChecksumKey

> Table-valued parameter type used for batch lookup of checksum records by their composite key (ChecksumId + ChecksumType).

| Property | Value |
|----------|-------|
| **Schema** | Infra |
| **Object Type** | User Defined Type |
| **Key Identifier** | Composite: ChecksumId + ChecksumType |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Infra.ChecksumKey is a table-valued parameter (TVP) type that enables batch lookup of cryptographic checksum records from the Infra.Checksum table. It defines the composite key structure (ChecksumId + ChecksumType) that uniquely identifies a checksum record.

This type exists to support efficient bulk read operations against the checksum store. Without it, callers would need to issue individual queries for each checksum lookup, which would be prohibitively slow when verifying data integrity across hundreds or thousands of wallet entities in a single operation.

The type is used exclusively by the Infra.ReadChecksums stored procedure, which accepts a populated @ChecksumKeys parameter of this type and performs a single LEFT JOIN against Infra.Checksum to return all matching signatures in one round-trip.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type is a simple key container with two string fields forming a composite lookup key.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChecksumId | nvarchar(64) | YES | - | CODE-BACKED | The unique identifier of the entity being checksummed. In production, this holds the numeric entity ID as a string (e.g., wallet ID, pool ID). Combined with ChecksumType to form the composite lookup key against Infra.Checksum. |
| 2 | ChecksumType | nvarchar(64) | YES | - | CODE-BACKED | The category of the checksummed entity. Known values in production: "Wallet" (individual wallet records), "WalletPool" (wallet pool aggregations), "EtoroExternalAddress" (external crypto addresses). Combined with ChecksumId to form the composite lookup key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Infra.ReadChecksums](../Stored Procedures/Infra.ReadChecksums.md) | @ChecksumKeys | Parameter Type | Used as the input parameter type for batch checksum lookups |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Infra.ReadChecksums | Stored Procedure | Accepts @ChecksumKeys parameter of this type for batch lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. Both columns are nullable with no CHECK constraints.

---

## 8. Sample Queries

### 8.1 Declare and populate a ChecksumKey variable for batch lookup
```sql
DECLARE @Keys Infra.ChecksumKey
INSERT INTO @Keys (ChecksumId, ChecksumType)
VALUES ('12345', 'Wallet'), ('67890', 'WalletPool')

EXEC Infra.ReadChecksums @ChecksumKeys = @Keys
```

### 8.2 Populate from an existing result set
```sql
DECLARE @Keys Infra.ChecksumKey
INSERT INTO @Keys (ChecksumId, ChecksumType)
SELECT CAST(WalletId AS nvarchar(64)), 'Wallet'
FROM Wallet.Wallets WITH (NOLOCK)
WHERE WalletId IN (100, 200, 300)

EXEC Infra.ReadChecksums @ChecksumKeys = @Keys
```

### 8.3 Verify which keys have existing checksums
```sql
DECLARE @Keys Infra.ChecksumKey
INSERT INTO @Keys (ChecksumId, ChecksumType)
VALUES ('12345', 'Wallet'), ('99999', 'Wallet')

SELECT ck.ChecksumId, ck.ChecksumType,
       CASE WHEN c.Id IS NOT NULL THEN 'Exists' ELSE 'Missing' END AS Status
FROM @Keys ck
    LEFT JOIN Infra.Checksum c WITH (NOLOCK)
        ON c.ChecksumId = ck.ChecksumId AND c.ChecksumType = ck.ChecksumType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Infra.ChecksumKey | Type: User Defined Type | Source: WalletDB/Infra/User Defined Types/Infra.ChecksumKey.sql*
