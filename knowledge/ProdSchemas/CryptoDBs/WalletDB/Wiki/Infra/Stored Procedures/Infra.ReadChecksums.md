# Infra.ReadChecksums

> Batch-retrieves cryptographic checksum records for multiple entities using a table-valued parameter, returning stored signatures alongside requested keys (including NULLs for missing checksums).

| Property | Value |
|----------|-------|
| **Schema** | Infra |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch reads from Infra.Checksum via Infra.ChecksumKey TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Infra.ReadChecksums is the batch lookup procedure for the data integrity checksum system. It accepts multiple entity keys via the Infra.ChecksumKey table-valued parameter and returns the stored JWT signatures for all matching entities in a single result set.

This procedure exists to support efficient bulk integrity verification. When the application needs to verify data integrity across hundreds of wallet entities simultaneously - for example, during a scheduled audit sweep or after a batch operation - it populates a ChecksumKey TVP with the entity identifiers and retrieves all signatures in one database round-trip instead of calling ReadChecksum repeatedly.

The procedure uses a LEFT JOIN from the input keys to Infra.Checksum, which means the result set always contains one row per input key. For entities that have a checksum, the row includes the Id, Signature, and Created values. For entities that do not have a checksum, those columns are NULL - this allows the caller to identify both verified entities and gaps in coverage from a single query. The NOLOCK hint ensures non-blocking reads suitable for high-frequency verification operations.

---

## 2. Business Logic

### 2.1 Left-Join Preserving All Input Keys

**What**: Returns one row per input key regardless of whether a checksum exists, enabling gap detection in a single call.

**Columns/Parameters Involved**: `@ChecksumKeys` (Infra.ChecksumKey TVP)

**Rules**:
- LEFT JOIN from @ChecksumKeys to Infra.Checksum on ChecksumId + ChecksumType
- Every row in @ChecksumKeys appears in the output, even if no matching checksum exists
- For matched rows: Id, Signature, Created are populated from Infra.Checksum
- For unmatched rows: Id, Signature, Created are NULL - caller detects missing checksums by checking for NULL Id
- The output preserves the input ChecksumId and ChecksumType columns from the TVP for caller correlation
- Uses WITH (NOLOCK) for non-blocking reads during high-throughput verification

**Diagram**:
```
@ChecksumKeys TVP        Infra.Checksum
  (N keys)                 (3.95M rows)
       \                      /
        \--- LEFT JOIN ------/
             ON ChecksumId
             + ChecksumType
                  |
                  v
          Result Set (N rows)
          ┌──────────────────────────────┐
          | Key found:    Id, Sig, Created|
          | Key missing:  NULL, NULL, NULL|
          └──────────────────────────────┘
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ChecksumKeys | Infra.ChecksumKey (READONLY) | NO | - | VERIFIED | Table-valued parameter containing the batch of entity keys to look up. Each row provides ChecksumId (entity PK as string) and ChecksumType (entity category). Marked READONLY as required for TVP parameters. |

**Return Columns**:

| # | Element | Type | Source | Description |
|---|---------|------|--------|-------------|
| R1 | ChecksumId | nvarchar(64) | @ChecksumKeys (ck) | The entity identifier from the input TVP. Always populated. |
| R2 | ChecksumType | nvarchar(64) | @ChecksumKeys (ck) | The entity category from the input TVP. Always populated. |
| R3 | Id | bigint | Infra.Checksum (c) | Surrogate PK of the matching checksum record. NULL if no checksum exists for this key. |
| R4 | Signature | varchar(2048) | Infra.Checksum (c) | The stored RS256 JWT signature. NULL if no checksum exists for this key. Used by the caller for integrity comparison against a freshly computed signature. |
| R5 | Created | datetime2(7) | Infra.Checksum (c) | UTC timestamp of the stored checksum. NULL if no checksum exists. Useful for determining checksum age. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LEFT JOIN source | Infra.Checksum | Direct read | Reads checksum records matching the input keys |
| @ChecksumKeys type | Infra.ChecksumKey | Parameter type | Uses the ChecksumKey UDT to receive batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Infra.ReadChecksums (procedure)
├── Infra.ChecksumKey (type)
└── Infra.Checksum (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Infra.ChecksumKey | User Defined Type | TVP parameter type for @ChecksumKeys |
| Infra.Checksum | Table | LEFT JOIN read source for checksum records |

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

### 8.1 Batch-retrieve checksums for multiple wallets
```sql
DECLARE @Keys Infra.ChecksumKey
INSERT INTO @Keys (ChecksumId, ChecksumType)
VALUES ('1572641', 'Wallet'), ('1572640', 'Wallet'), ('1572639', 'Wallet')

EXEC Infra.ReadChecksums @ChecksumKeys = @Keys
```

### 8.2 Mixed-type batch lookup
```sql
DECLARE @Keys Infra.ChecksumKey
INSERT INTO @Keys (ChecksumId, ChecksumType)
VALUES ('100', 'Wallet'), ('500', 'WalletPool'), ('10', 'EtoroExternalAddress')

EXEC Infra.ReadChecksums @ChecksumKeys = @Keys
```

### 8.3 Detect entities with missing checksums from the result
```sql
DECLARE @Keys Infra.ChecksumKey
INSERT INTO @Keys (ChecksumId, ChecksumType)
VALUES ('1', 'Wallet'), ('999999', 'Wallet')

-- In the result, rows with NULL Id have no stored checksum
DECLARE @Results TABLE (ChecksumId nvarchar(64), ChecksumType nvarchar(64),
    Id bigint, Signature varchar(2048), Created datetime2(7))
INSERT INTO @Results EXEC Infra.ReadChecksums @ChecksumKeys = @Keys

SELECT ChecksumId, ChecksumType,
       CASE WHEN Id IS NOT NULL THEN 'Has Checksum' ELSE 'MISSING' END AS Status
FROM @Results
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Infra.ReadChecksums | Type: Stored Procedure | Source: WalletDB/Infra/Stored Procedures/Infra.ReadChecksums.sql*
