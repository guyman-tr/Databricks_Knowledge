# Trade.ValidateMinMirrorAmountAbsolute

> Validates that a CopyTrader allocation amount meets the minimum dollar threshold configured per mirror type, preventing trivially small copy relationships.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (validation result code) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ValidateMinMirrorAmountAbsolute enforces a minimum dollar floor on CopyTrader allocations. It prevents users from creating copy relationships with trivially small amounts (e.g., $1) that would be impractical to trade and generate unnecessary system overhead. Each mirror type has its own minimum configured in Maintenance.Feature (FeatureID=23).

This is the floor counterpart to ValidateMaxMirrorActionAmountAbsolute. Together they define the valid dollar range for CopyTrader allocations: [MinAbsolute, MaxAbsolute].

---

## 2. Business Logic

### 2.1 Minimum Amount Floor Validation

**What**: Ensures copy amount meets the configured minimum for the mirror type.

**Columns/Parameters Involved**: `@AmountInDollars`, `@MirrorTypeID`, `MinMirrorAmountAbsolute` (from XML)

**Rules**:
- Reads FeatureID=23 XML: `MirrorValidationInfo/MirrorType[@ID=@MirrorTypeID]/@MinMirrorAmountAbsolute`
- If @AmountInDollars < MinMirrorAmountAbsolute: returns 60069
- If @AmountInDollars >= minimum: returns 1 (success)
- Error 60069: "Minimum amount to copy a trader is $X"

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Included for signature consistency with sibling validation functions but not used in this function's logic. |
| 2 | @AmountInDollars | dtPrice | NO | - | CODE-BACKED | The dollar amount to validate against the minimum threshold. Must meet or exceed MinMirrorAmountAbsolute. |
| 3 | @MirrorTypeID | INT | NO | - | CODE-BACKED | Mirror type identifier selecting the correct minimum from XML config. |
| 4 | Return value | INT | NO | - | CODE-BACKED | Validation result: 1 = valid (meets minimum), 60069 = error (below minimum). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | SELECT (WHERE) | Reads mirror validation XML for MinMirrorAmountAbsolute |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeMirrorAmount_testJunk | Function call | Called | Test procedure for mirror amount changes |
| Dealing (permission script) | Function call | GRANT EXECUTE | Granted to Dealing role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateMinMirrorAmountAbsolute (function)
  +-- Maintenance.Feature (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT XMLValue WHERE FeatureID = 23 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeMirrorAmount_testJunk | Stored Procedure | Calls during mirror amount validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate minimum amount for a copy
```sql
SELECT Trade.ValidateMinMirrorAmountAbsolute(12345, 200.00, 1) AS ValidationResult
```

### 8.2 Check configured minimum thresholds
```sql
SELECT F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MinMirrorAmountAbsolute)[1]', 'DECIMAL(10,2)') AS MinAbsolute
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23
```

### 8.3 Test boundary amounts
```sql
SELECT Amount,
       Trade.ValidateMinMirrorAmountAbsolute(12345, Amount, 1) AS Result
FROM   (VALUES (50.00), (100.00), (200.00), (500.00)) AS T(Amount)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [EtoroOps Flows - Screen List Documentation](https://etoro.atlassian.net) | Confluence | CopyTrader minimum investment rules |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateMinMirrorAmountAbsolute | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateMinMirrorAmountAbsolute.sql*
