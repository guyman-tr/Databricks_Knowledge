# C2F.GenerateUniqueClientLoadReferenceId

> Generates a unique "C2F" + 8-digit reference ID for fiat transactions by checking against existing FiatTransactions.Details values, with retry logic for collision handling.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT: @ReferenceId VARCHAR(11) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GenerateUniqueClientLoadReferenceId creates a unique external reference ID for fiat payment transactions. The format "C2F" + 8 random digits (e.g., "C2F42756316") serves as the client-load reference in the external fiat payment system. The procedure ensures uniqueness by checking against existing FiatTransactions.Details values and retrying up to 100 times if a collision occurs.

Called before InsertFiatTransaction to generate the Details value that will be stored with the fiat transaction record.

---

## 2. Business Logic

### 2.1 Collision-Resistant ID Generation

**What**: Generates random IDs and retries on collision, up to 100 attempts.

**Columns/Parameters Involved**: `@ReferenceId`, `@MaxAttempts`

**Rules**:
- Format: "C2F" + 8-digit random number (range 10000000-99999999)
- Uses ABS(CHECKSUM(NEWID())) for randomness
- Checks uniqueness: NOT EXISTS (SELECT 1 FROM FiatTransactions WHERE Details = @Candidate)
- Max 100 attempts before raising error
- With ~13K existing references in a 90M ID space, collision probability is negligible

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceId | varchar(11) OUTPUT | NO | - | VERIFIED | The generated unique reference ID in format "C2F" + 8 digits. Returned as OUTPUT parameter. Used as FiatTransactions.Details value. |

**Return:** 0 on success, 1 on failure (exhausted max attempts).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.FiatTransactions | SELECT (EXISTS check) | Checks Details column for uniqueness |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.GenerateUniqueClientLoadReferenceId (procedure)
└── C2F.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.FiatTransactions | Table | SELECT - uniqueness check against Details column |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Generate a unique reference ID
```sql
DECLARE @RefId VARCHAR(11)
EXEC C2F.GenerateUniqueClientLoadReferenceId @ReferenceId = @RefId OUTPUT
SELECT @RefId AS GeneratedReferenceId
```

### 8.2 Check existing reference IDs
```sql
SELECT TOP 10 Details FROM C2F.FiatTransactions WITH (NOLOCK) ORDER BY Id DESC
```

### 8.3 Count existing references
```sql
SELECT COUNT(DISTINCT Details) AS UniqueReferences FROM C2F.FiatTransactions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.GenerateUniqueClientLoadReferenceId | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.GenerateUniqueClientLoadReferenceId.sql*
