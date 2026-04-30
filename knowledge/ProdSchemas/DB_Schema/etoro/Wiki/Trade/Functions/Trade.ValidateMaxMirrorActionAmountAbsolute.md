# Trade.ValidateMaxMirrorActionAmountAbsolute

> Validates that a CopyTrader (mirror) allocation amount does not exceed the absolute maximum dollar limit configured per mirror type in Maintenance.Feature (FeatureID=23).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (validation result code) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ValidateMaxMirrorActionAmountAbsolute enforces an absolute dollar cap on the amount a user can allocate to a CopyTrader (mirror) relationship. When a user attempts to copy a trader, the system validates that the copy amount does not exceed a hard ceiling configured in the platform's feature management system.

This function is part of a family of mirror validation functions that collectively enforce CopyTrader business rules. These rules prevent users from over-concentrating funds into a single copy relationship, which could lead to excessive risk exposure. Each mirror type (identified by @MirrorTypeID) can have different limits configured in the XML validation rules.

The function reads validation rules from Maintenance.Feature (FeatureID=23), which stores mirror/CopyTrader configuration as XML. It extracts the MaxMirrorActionAmountAbsolute attribute for the specific mirror type from the XML and compares it against the requested amount.

---

## 2. Business Logic

### 2.1 Absolute Amount Cap Validation

**What**: Enforces a hard dollar ceiling on CopyTrader allocation amounts per mirror type.

**Columns/Parameters Involved**: `@AmountInDollars`, `@MirrorTypeID`, `MaxMirrorActionAmountAbsolute` (from XML)

**Rules**:
- Reads FeatureID=23 XML from Maintenance.Feature
- Extracts MaxMirrorActionAmountAbsolute for the specific MirrorType ID from XML path: `MirrorValidationInfo/MirrorType[@ID=@MirrorTypeID]/@MaxMirrorActionAmountAbsolute`
- If @AmountInDollars > MaxMirrorActionAmountAbsolute: returns error code 60068
- If @AmountInDollars <= limit: returns 1 (success)
- Error code 60068 maps to a user-facing message like "You cannot copy this trader with more than $X"

**Diagram**:
```
  Maintenance.Feature (FeatureID=23)
       |
       v
  XML: <MirrorValidationInfo>
         <MirrorType ID="1" MaxMirrorActionAmountAbsolute="50000" .../>
         <MirrorType ID="2" MaxMirrorActionAmountAbsolute="100000" .../>
       </MirrorValidationInfo>
       |
       v
  @AmountInDollars > Limit? --> YES --> RETURN 60068 (error)
                             --> NO  --> RETURN 1 (OK)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Included in the signature for consistency with other validation functions in the family, but not used in this specific function's logic. |
| 2 | @AmountInDollars | dtPrice | NO | - | CODE-BACKED | The dollar amount the customer wants to allocate to the CopyTrader relationship. Validated against the absolute maximum. |
| 3 | @MirrorTypeID | INT | NO | - | CODE-BACKED | The type of mirror/copy relationship being created. Different mirror types (e.g., standard copy, portfolio copy) have different configured limits. Used to select the correct XML MirrorType node. |
| 4 | Return value | INT | NO | - | CODE-BACKED | Validation result: 1 = valid (amount within limit), 60068 = error (amount exceeds absolute maximum). Error code 60068 triggers a user-facing rejection message. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | SELECT (WHERE) | Reads the XML validation rules for mirror/CopyTrader configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeMirrorAmount_testJunk | Function call | Called | Test procedure for mirror amount changes |
| Dealing (permission script) | Function call | GRANT EXECUTE | Granted execute permission to Dealing role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateMaxMirrorActionAmountAbsolute (function)
  +-- Maintenance.Feature (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT XMLValue WHERE FeatureID = 23 to retrieve mirror validation rules XML |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeMirrorAmount_testJunk | Stored Procedure | Calls this function during mirror amount change validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate a copy amount for mirror type 1
```sql
SELECT Trade.ValidateMaxMirrorActionAmountAbsolute(12345, 50000.00, 1) AS ValidationResult
```

### 8.2 Check the configured limits from Feature XML
```sql
SELECT F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MaxMirrorActionAmountAbsolute)[1]', 'DECIMAL(10,2)') AS MaxAbsolute_Type1,
       F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="2"]/@MaxMirrorActionAmountAbsolute)[1]', 'DECIMAL(10,2)') AS MaxAbsolute_Type2
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23
```

### 8.3 Test multiple amounts against the limit
```sql
SELECT Amount,
       Trade.ValidateMaxMirrorActionAmountAbsolute(12345, Amount, 1) AS Result
FROM   (VALUES (1000.00), (10000.00), (50000.00), (100000.00)) AS T(Amount)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [EtoroOps Flows - Screen List Documentation](https://etoro.atlassian.net) | Confluence | CopyTrader flow documentation including validation steps |
| [Stop copying](https://etoro.atlassian.net) | Confluence | Mirror lifecycle including validation on copy initiation |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateMaxMirrorActionAmountAbsolute | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateMaxMirrorActionAmountAbsolute.sql*
