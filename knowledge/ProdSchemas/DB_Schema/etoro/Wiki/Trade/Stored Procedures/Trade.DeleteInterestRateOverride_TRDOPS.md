# Trade.DeleteInterestRateOverride_TRDOPS

> TRDOPS bulk variant for deleting interest rate overrides via TVP, with existence validation, overnight fee pattern guard, row count verification, and full transactional safety.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InterestRateOverrideIDs (TVP of override IDs to delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteInterestRateOverride_TRDOPS is the Trading Operations bulk variant of Trade.DeleteInterestRateOverride. It accepts a TVP of override IDs and deletes them all within a single transaction, with comprehensive validation: existence check, overnight fee pattern guard, and post-delete row count verification. This procedure is used by the TRDOPS admin interface for batch override management.

This procedure exists because operations staff often need to remove multiple overrides at once (e.g., cleaning up overrides for a deprecated instrument type). The transactional design ensures all-or-nothing semantics - if any validation fails, no rows are deleted.

Data flow: (1) Validate TVP is non-empty. (2) Verify all IDs exist in Dictionary.InterestRateOverride. (3) Check overnight fee pattern guard. (4) DELETE matching rows. (5) Verify deleted count matches input count. (6) COMMIT or ROLLBACK on any mismatch.

---

## 2. Business Logic

### 2.1 Comprehensive Validation Pipeline

**What**: Three validation steps before deletion, plus post-delete verification.

**Columns/Parameters Involved**: `@InterestRateOverrideIDs`, `@AllowRegardlessOverNightFeePattern`, `@DeletedRowCount`

**Rules**:
- Check 1: TVP must not be empty (RAISERROR if no IDs provided)
- Check 2: All IDs must exist in Dictionary.InterestRateOverride (LEFT JOIN check for NULLs)
- Check 3: If @AllowRegardlessOverNightFeePattern = 0, no target rows may have OverNightFeePatternID <> 0
- Post-delete: @DeletedRowCount must equal COUNT from TVP (RAISERROR if mismatch)

### 2.2 Transactional All-or-Nothing Semantics

**What**: Entire operation wrapped in explicit BEGIN TRAN / COMMIT TRAN.

**Columns/Parameters Involved**: All

**Rules**:
- Any RAISERROR inside TRY triggers CATCH which re-raises the error
- Implicit ROLLBACK on error (transaction not committed)
- @DeletedRowCount OUTPUT parameter reports how many rows were actually removed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InterestRateOverrideIDs | Trade.InterestRateOverrideIDsTbl_TRDOPS (READONLY) | NO | - | CODE-BACKED | TVP containing the override IDs to delete. Each row has an Id column. |
| 2 | @AppLoginName | NVARCHAR(100) | NO | - | CODE-BACKED | Operator login name for audit trail (parameter present but CONTEXT_INFO not explicitly set in this variant). |
| 3 | @AllowRegardlessOverNightFeePattern | BIT | YES | 0 | CODE-BACKED | Safety bypass flag. 0 = block deletion of rows with OverNightFeePatternID <> 0 (default). 1 = allow deletion regardless. |
| 4 | @DeletedRowCount | INT | NO | OUTPUT | CODE-BACKED | OUTPUT parameter returning the actual number of rows deleted. Used by the caller to verify the operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InterestRateOverrideIDs | Dictionary.InterestRateOverride | DELETER | Validates existence and deletes matching override rows |
| (@InterestRateOverrideIDs) | Trade.InterestRateOverrideIDsTbl_TRDOPS | Type Reference | TRDOPS-specific TVP type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteInterestRateOverride_TRDOPS (procedure)
+-- Dictionary.InterestRateOverride (table, cross-schema)
+-- Trade.InterestRateOverrideIDsTbl_TRDOPS (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRateOverride | Table | Validation SELECTs + DELETE target |
| Trade.InterestRateOverrideIDsTbl_TRDOPS | User Defined Type | Input parameter type |

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

### 8.1 Bulk delete interest rate overrides

```sql
DECLARE @IDs Trade.InterestRateOverrideIDsTbl_TRDOPS
DECLARE @Deleted INT
INSERT INTO @IDs (Id) VALUES (10), (11), (12)
EXEC Trade.DeleteInterestRateOverride_TRDOPS
    @InterestRateOverrideIDs = @IDs,
    @AppLoginName = N'admin@etoro.com',
    @DeletedRowCount = @Deleted OUTPUT
SELECT @Deleted AS RowsDeleted
```

### 8.2 Preview overrides before bulk deletion

```sql
SELECT  InterestRateOverrideID, OverNightFeePatternID
FROM    Dictionary.InterestRateOverride WITH (NOLOCK)
WHERE   InterestRateOverrideID IN (10, 11, 12)
```

### 8.3 Check overrides with fee patterns that would block deletion

```sql
SELECT  InterestRateOverrideID, ISNULL(OverNightFeePatternID, 0) AS PatternID
FROM    Dictionary.InterestRateOverride WITH (NOLOCK)
WHERE   ISNULL(OverNightFeePatternID, 0) <> 0
ORDER BY InterestRateOverrideID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteInterestRateOverride_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteInterestRateOverride_TRDOPS.sql*
