# Trade.DeleteInterestRateOverride

> Deletes a single interest rate override from Dictionary.InterestRateOverride, with a safety guard preventing deletion of rows linked to overnight fee patterns.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InterestRateOverrideID (identifies the override to delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteInterestRateOverride removes a single interest rate override record from Dictionary.InterestRateOverride. Interest rate overrides allow the system to apply custom overnight fee rates to specific instruments, instrument types, or settlement types instead of the default rates. This procedure is used by administrators to remove overrides that are no longer needed.

This procedure exists to provide a safe delete with a business rule guard: overrides linked to an OverNightFeePattern cannot be deleted by default, because those patterns are complex configurations that may affect multiple instruments. The @AllowRegardlessOverNightFeePattern flag allows bypassing this guard for exceptional cases.

Data flow: The caller provides an InterestRateOverrideID and optionally the bypass flag. If the flag is 0 (default) and the row has OverNightFeePatternID <> 0, a THROW error blocks deletion. Otherwise, the row is deleted from Dictionary.InterestRateOverride.

---

## 2. Business Logic

### 2.1 Overnight Fee Pattern Safety Guard

**What**: Prevents accidental deletion of overrides that are part of an overnight fee pattern.

**Columns/Parameters Involved**: `@InterestRateOverrideID`, `@AllowRegardlessOverNightFeePattern`, `OverNightFeePatternID`

**Rules**:
- If @AllowRegardlessOverNightFeePattern = 0 (default) AND the row has OverNightFeePatternID <> 0: THROW 50001 blocks the deletion
- If @AllowRegardlessOverNightFeePattern = 1: the guard is bypassed, deletion proceeds regardless
- Rows with OverNightFeePatternID = 0 (or NULL after ISNULL) are simple overrides and can always be deleted

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InterestRateOverrideID | INT | NO | - | CODE-BACKED | Unique identifier of the interest rate override record to delete from Dictionary.InterestRateOverride. |
| 2 | @AllowRegardlessOverNightFeePattern | BIT | YES | 0 | CODE-BACKED | Safety bypass flag. 0 = block deletion of rows with OverNightFeePatternID <> 0 (default). 1 = allow deletion regardless of pattern association. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InterestRateOverrideID | Dictionary.InterestRateOverride | DELETER | Removes the interest rate override row by ID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteInterestRateOverride (procedure)
+-- Dictionary.InterestRateOverride (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRateOverride | Table | SELECT for pattern guard validation + DELETE target |

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

### 8.1 Delete a simple interest rate override

```sql
EXEC Trade.DeleteInterestRateOverride @InterestRateOverrideID = 42
```

### 8.2 Force-delete an override with overnight fee pattern

```sql
EXEC Trade.DeleteInterestRateOverride @InterestRateOverrideID = 42, @AllowRegardlessOverNightFeePattern = 1
```

### 8.3 Check overrides with fee patterns before deletion

```sql
SELECT  InterestRateOverrideID, OverNightFeePatternID
FROM    Dictionary.InterestRateOverride WITH (NOLOCK)
WHERE   OverNightFeePatternID <> 0
ORDER BY InterestRateOverrideID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteInterestRateOverride | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteInterestRateOverride.sql*
