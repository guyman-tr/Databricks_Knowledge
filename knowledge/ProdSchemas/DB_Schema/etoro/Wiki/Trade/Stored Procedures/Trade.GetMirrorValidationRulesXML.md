# Trade.GetMirrorValidationRulesXML

> Returns the raw XML configuration for mirror validation rules from Maintenance.Feature (FeatureID=23), providing the full XML document that defines per-type stop-loss ranges, amount limits, and copy constraints.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns single XML value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorValidationRulesXML` returns the complete mirror validation XML configuration from `Maintenance.Feature` FeatureID=23. This is the raw source XML that the related procedures `GetMirrorTypesValidationsDefaults` and `GetMirrorValidation` both parse for specific values.

The procedure exists to provide direct access to the full XML document for cases where the caller needs the raw config - for example, to display the full validation rule set in an admin interface, for debugging, or for caching the entire config on the application side to avoid repeated per-type calls.

Data flows: The XML document is structured as `<MirrorValidationInfo><MirrorType ID="N" attr1="..." .../></MirrorValidationInfo>` and contains one element per mirror type with all validation thresholds. Used by the MOE service and validation layer.

---

## 2. Business Logic

### 2.1 Mirror Validation XML Config (FeatureID=23)

**What**: A single XML document configures all mirror type validation rules.

**Rules**:
- `Maintenance.Feature WHERE FeatureID = 23`: The single row containing the XML.
- The XML document is returned as-is (single column `XMLValue`, single row).
- XML structure: `/MirrorValidationInfo/MirrorType[@ID]` - one per mirror type.
- Attributes per type: `@MaxMirrorActionAmountPercentage`, `@MaxMirrorActionAmountAbsolute`, `@MinMirrorAmountAbsolute`, `@MaxNumOfActiveMirrors`, `@SmallAmountsRangePercentage`, `@MaxMirrorSLPercentage`, `@MinMirrorSLPercentage`, `@DeafultMirrorSLPercentage`.
- This same FeatureID is also parsed by `GetMirrorTypesValidationsDefaults` (all types as table) and `GetMirrorValidation` (single type as OUTPUT params).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | XMLValue | Maintenance.Feature | The full XML document containing mirror validation rules for all mirror types. XML data type. Structure: `<MirrorValidationInfo><MirrorType ID="N" MaxMirrorSLPercentage="..." MinMirrorSLPercentage="..." DeafultMirrorSLPercentage="..." .../></MirrorValidationInfo>`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | Lookup | Reads the XMLValue column for the mirror validation rules feature. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorValidationRulesXML (procedure)
└── Maintenance.Feature (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table (cross-schema) | SELECT XMLValue WHERE FeatureID = 23 - returns the full mirror validation XML config |

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

### 8.1 Get the raw mirror validation XML

```sql
EXEC Trade.GetMirrorValidationRulesXML;
```

### 8.2 Query Maintenance.Feature directly

```sql
SELECT FeatureID, FeatureName, XMLValue
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 23;
```

### 8.3 Compare raw XML vs parsed tabular view

```sql
-- Raw XML
EXEC Trade.GetMirrorValidationRulesXML;
-- Parsed tabular
EXEC Trade.GetMirrorTypesValidationsDefaults;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Moe - Mirror Operation Engine](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12857836033/Moe+-+Mirror+Operation+Engine) | Confluence | Mirror validation rules XML (FeatureID=23) is used by MOE service for SL percentage validation in mirror registration and edit flows |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorValidationRulesXML | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorValidationRulesXML.sql*
