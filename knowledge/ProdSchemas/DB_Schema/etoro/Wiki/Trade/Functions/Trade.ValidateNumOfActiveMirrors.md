# Trade.ValidateNumOfActiveMirrors

> Validates that a customer has not exceeded the maximum number of active CopyTrader relationships allowed per mirror type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (validation result code) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ValidateNumOfActiveMirrors enforces a count limit on how many active CopyTrader (mirror) relationships a customer can maintain simultaneously. This prevents users from creating an excessive number of copy relationships which would fragment their capital and increase system complexity.

The function counts the customer's active mirrors from Trade.Mirror and compares against the configured maximum per mirror type in Maintenance.Feature (FeatureID=23). It is called when a user attempts to initiate a new copy relationship.

---

## 2. Business Logic

### 2.1 Active Mirror Count Validation

**What**: Ensures the customer's active mirror count is below the configured maximum.

**Columns/Parameters Involved**: `@CID`, `@MirrorTypeID`, `MaxNumOfActiveMirrors` (from XML), `Trade.Mirror`

**Rules**:
- Reads FeatureID=23 XML: `MirrorValidationInfo/MirrorType[@ID=@MirrorTypeID]/@MaxNumOfActiveMirrors`
- Counts active mirrors: `SELECT COUNT(*) FROM Trade.Mirror WHERE CID = @CID`
- If @NumOfActiveMirrors >= @MaxNumOfActiveMirrors: returns 60068
- If under limit: returns 1 (success)
- Uses >= comparison (not >), so reaching the limit exactly also blocks new mirrors
- Error 60068: shared with ValidateMaxMirrorActionAmountAbsolute (generic CopyTrader limit error)

**Diagram**:
```
  Trade.Mirror (WHERE CID = @CID)
       |
       v
  COUNT(*) = NumOfActiveMirrors
       |
       v
  NumOfActiveMirrors >= MaxNumOfActiveMirrors?
       YES --> RETURN 60068 (at or over limit)
       NO  --> RETURN 1 (OK, can add new mirror)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to count active mirrors in Trade.Mirror and validate against the limit. |
| 2 | @MirrorTypeID | INT | NO | - | CODE-BACKED | Mirror type identifier. Selects the MaxNumOfActiveMirrors limit from XML config for this mirror type. |
| 3 | Return value | INT | NO | - | CODE-BACKED | Validation result: 1 = valid (under limit), 60068 = error (at or over maximum active mirror count). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | SELECT (WHERE) | Reads mirror validation XML for MaxNumOfActiveMirrors |
| @CID | Trade.Mirror | SELECT COUNT (WHERE) | Counts the customer's currently active mirror relationships |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dealing (permission script) | Function call | GRANT EXECUTE | Granted to Dealing role for application-level calls |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateNumOfActiveMirrors (function)
  +-- Maintenance.Feature (table)
  +-- Trade.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT XMLValue WHERE FeatureID = 23 |
| Trade.Mirror | Table | SELECT COUNT(*) WHERE CID = @CID to count active mirrors |

### 6.2 Objects That Depend On This

No direct procedure consumers found in SSDT (granted to Dealing role for application calls).

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate if customer can add another mirror
```sql
SELECT Trade.ValidateNumOfActiveMirrors(12345, 1) AS ValidationResult
```

### 8.2 Check configured mirror count limits
```sql
SELECT F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MaxNumOfActiveMirrors)[1]', 'SMALLINT') AS MaxMirrors_Type1
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23
```

### 8.3 Check current mirror counts for customers
```sql
SELECT CID, COUNT(*) AS ActiveMirrors,
       Trade.ValidateNumOfActiveMirrors(CID, 1) AS CanAddMore
FROM   Trade.Mirror WITH (NOLOCK)
GROUP BY CID
HAVING COUNT(*) > 5
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [New Copy Trader Function: Stop Copy and Keep](https://etoro.atlassian.net) | Confluence | CopyTrader lifecycle including mirror count management |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateNumOfActiveMirrors | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateNumOfActiveMirrors.sql*
