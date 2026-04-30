# Infra.ReadChecksum

> Retrieves the most recent cryptographic checksum record for a single entity identified by its ChecksumId and ChecksumType.

| Property | Value |
|----------|-------|
| **Schema** | Infra |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads from Infra.Checksum by composite key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Infra.ReadChecksum is the single-record lookup procedure for the data integrity checksum system. Given an entity identifier and its type, it returns the most recently stored JWT signature for that entity from Infra.Checksum.

This procedure exists to support real-time data integrity verification. When the application needs to verify that a wallet, wallet pool, or external address has not been tampered with, it calls this procedure to retrieve the stored signature, then compares it against a freshly computed signature for the entity's current state. A mismatch indicates data modification since the last checksum was recorded.

The procedure uses TOP 1 with ORDER BY Id DESC to return the latest checksum for the given entity. Although the current system design produces at most one checksum per ChecksumId + ChecksumType combination (enforced by the unique index and idempotent inserts), the ORDER BY Id DESC pattern provides a safety net should future schema changes allow multiple versions.

---

## 2. Business Logic

### 2.1 Latest-Record Retrieval

**What**: Returns the most recent checksum for a given entity, using the surrogate Id as the recency indicator.

**Columns/Parameters Involved**: `@ChecksumId`, `@ChecksumType`

**Rules**:
- Filters by exact match on both ChecksumId AND ChecksumType
- ORDER BY Id DESC ensures the newest record is returned (higher Id = more recent)
- TOP 1 limits to a single result row
- Returns all 5 columns: Id, ChecksumId, ChecksumType, Signature, Created
- If no matching record exists, returns an empty result set (no error)
- SET NOCOUNT ON suppresses row-count messages for cleaner client consumption

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ChecksumId | nvarchar(64) | NO | - | VERIFIED | The unique identifier of the entity whose checksum to retrieve. Holds the entity's primary key as a string: WalletRecordId for "Wallet" type, WalletPool.Id for "WalletPool" type, EtoroExternalAddresses.Id for "EtoroExternalAddress" type. |
| 2 | @ChecksumType | nvarchar(64) | NO | - | VERIFIED | The category of entity to look up. Known values: "Wallet", "WalletPool", "EtoroExternalAddress". Combined with @ChecksumId to target the exact checksum record. |

**Return Columns**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| R1 | Id | bigint | Surrogate PK of the checksum record |
| R2 | ChecksumId | nvarchar(64) | Echo of the input entity identifier |
| R3 | ChecksumType | varchar(64) | Echo of the input entity category |
| R4 | Signature | varchar(2048) | The stored RS256 JWT signature for integrity verification |
| R5 | Created | datetime2(7) | UTC timestamp when the checksum was originally generated |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Infra.Checksum | Direct read | Reads a single checksum record by composite key |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Infra.ReadChecksum (procedure)
└── Infra.Checksum (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Infra.Checksum | Table | SELECT source filtered by ChecksumId + ChecksumType |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Retrieve checksum for a specific wallet
```sql
EXEC Infra.ReadChecksum
    @ChecksumId = '1572641',
    @ChecksumType = 'Wallet'
```

### 8.2 Retrieve checksum for a wallet pool
```sql
EXEC Infra.ReadChecksum
    @ChecksumId = '45678',
    @ChecksumType = 'WalletPool'
```

### 8.3 Check if a checksum exists (empty result = no checksum)
```sql
EXEC Infra.ReadChecksum
    @ChecksumId = '999999',
    @ChecksumType = 'EtoroExternalAddress'
-- Empty result means this external address has never been checksummed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Infra.ReadChecksum | Type: Stored Procedure | Source: WalletDB/Infra/Stored Procedures/Infra.ReadChecksum.sql*
