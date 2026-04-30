# C2P.InsertPosition

> Creates a conversion-to-position link record with parameter validation and deduplication, implementing an upsert pattern that returns the Id whether newly inserted or already existing.

| Property | Value |
|----------|-------|
| **Schema** | C2P |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Id (bigint) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertPosition records the link between a crypto-to-fiat conversion and the trading position opened with the converted fiat proceeds. It is called when the position-open step completes in the CryptoToFiatSaga pipeline (for conversions with TargetPlatformId=3).

The procedure implements an upsert pattern: if the (ConversionId, PositionId) combination already exists, it returns the existing Id rather than raising an error. This makes the procedure idempotent - safe to retry during saga recovery.

---

## 2. Business Logic

### 2.1 Validated Upsert Pattern

**What**: Validates inputs, checks for existing record, inserts if new, returns Id in all cases.

**Columns/Parameters Involved**: `@ConversionId`, `@PositionId`

**Rules**:
1. Validate @ConversionId IS NOT NULL (RAISERROR + RETURN if null)
2. Validate @PositionId IS NOT NULL and not empty/whitespace (RAISERROR + RETURN)
3. IF NOT EXISTS (ConversionId + PositionId combination): INSERT with GETUTCDATE(), get SCOPE_IDENTITY()
4. ELSE: SELECT existing Id
5. Return @InsertedId AS Id in all success paths
- This is safer than the INSERT-or-error pattern used in C2F.InsertConversion - allows idempotent retries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConversionId | bigint | NO | - | VERIFIED | References C2F.Conversions.Id. Identifies which conversion funded this position. Validated NOT NULL. |
| 2 | @PositionId | nvarchar(255) | NO | - | VERIFIED | Trading platform position identifier (GUID format). Validated NOT NULL and not empty/whitespace. |

**Return:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Id | bigint | VERIFIED | The C2P.Positions.Id - either newly inserted or existing (upsert semantics) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2P.Positions | INSERT target + SELECT (upsert) | Creates or retrieves position link rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2P.InsertPosition (procedure)
└── C2P.Positions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2P.Positions | Table | INSERT target + EXISTS check + SELECT for existing |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Parameter validation | RAISERROR | ConversionId NOT NULL, PositionId NOT NULL/empty |
| Dedup guard | NOT EXISTS | Checks (ConversionId, PositionId) before INSERT |

---

## 8. Sample Queries

### 8.1 Insert a new position link
```sql
EXEC C2P.InsertPosition @ConversionId = 17039, @PositionId = 'bd637018-99fc-40ad-a466-773d7274f16c'
```

### 8.2 Idempotent retry (same params, returns existing Id)
```sql
EXEC C2P.InsertPosition @ConversionId = 17039, @PositionId = 'bd637018-99fc-40ad-a466-773d7274f16c'
-- Returns same Id as first call
```

### 8.3 Verify the link
```sql
SELECT p.Id, p.ConversionId, p.PositionId, p.Occurred
FROM C2P.Positions p WITH (NOLOCK)
WHERE p.ConversionId = 17039
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2P.InsertPosition | Type: Stored Procedure | Source: WalletConversionDB/C2P/Stored Procedures/C2P.InsertPosition.sql*
