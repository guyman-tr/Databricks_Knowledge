# Trade.GetMirrorTypesValidationsDefaults

> Returns the mirror validation defaults and limits for ALL mirror types by parsing the XML configuration stored in Maintenance.Feature (FeatureID=23), providing per-type min/max/default stop-loss and amount constraints.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all mirror type configurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorTypesValidationsDefaults` reads the XML configuration from `Maintenance.Feature` (FeatureID=23) and parses it to return a tabular result with validation defaults and limits for every mirror type. Each row in the result represents one mirror type with its configured min/max/default stop-loss percentage, min/max copy amount, maximum number of active mirrors, and small-amounts range.

This procedure exists because mirror validation rules are stored as an XML configuration (rather than a relational table), allowing the business to update validation thresholds without schema changes. The XML is shredded using `nodes()` and `value()` XQuery functions into a relational format.

Data flows: Called by services (including the MOE service, which reads similar data for mirror registration validation) to retrieve the full set of mirror type constraints for display, validation, or configuration inspection.

---

## 2. Business Logic

### 2.1 XML Config Parsing (Maintenance.Feature FeatureID=23)

**What**: Mirror validation rules are stored as XML in Maintenance.Feature and shredded into a tabular result.

**Columns/Parameters Involved**: All output columns

**Rules**:
- Source: `Maintenance.Feature WHERE FeatureID = 23` -> `XMLValue` column contains an XML document.
- XML path: `/MirrorValidationInfo/MirrorType` - each `<MirrorType>` element becomes one row.
- Attributes parsed: `@ID`, `@MaxMirrorActionAmountPercentage`, `@MaxMirrorActionAmountAbsolute`, `@MinMirrorAmountAbsolute`, `@MaxNumOfActiveMirrors`, `@SmallAmountsRangePercentage`, `@MaxMirrorSLPercentage`, `@MinMirrorSLPercentage`, `@DeafultMirrorSLPercentage` (note: "Deafult" is a typo in the original - means "Default").
- TRY/CATCH: If XML parsing fails (malformed config), the exception is re-thrown via `THROW`.

**Diagram**:
```
Maintenance.Feature (FeatureID=23)
  XMLValue = '<MirrorValidationInfo>
                <MirrorType ID="1" MaxMirrorSLPercentage="..." MinMirrorSLPercentage="..." ... />
                <MirrorType ID="2" ... />
                ...
              </MirrorValidationInfo>'
              |
              v (XML shredding via nodes() + value())
              |
One row per MirrorType -> tabular result
```

### 2.2 Related Procedures for the Same XML Config

**What**: Three procedures share FeatureID=23 as their data source.

**Rules**:
- `GetMirrorValidationRulesXML`: Returns the raw XML string (FeatureID=23 XMLValue).
- `GetMirrorTypesValidationsDefaults` (this): Parses XML -> all mirror types as tabular result.
- `GetMirrorValidation`: Parses XML for a SPECIFIC MirrorTypeID -> OUTPUT parameters for SL range.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output columns** (result set - parsed from XML):

| # | Column | Description |
|---|--------|-------------|
| 1 | MirrorTypeID | The mirror type identifier (`@ID` attribute from XML). Corresponds to Trade.Mirror.MirrorCalculationType or mirror type classification. |
| 2 | MaxMirrorActionAmountPercentage | Maximum percentage of the mirror amount that can be added/removed in a single action. |
| 3 | MaxMirrorActionAmountAbsolute | Maximum absolute dollar amount for a single mirror action (add/remove funds). |
| 4 | MinMirrorAmountAbsolute | Minimum dollar amount required to maintain the mirror. |
| 5 | MaxNumOfActiveMirrors | Maximum number of active mirrors allowed for this mirror type. |
| 6 | SmallAmountsRangePercentage | Percentage range defining "small amounts" for special handling. |
| 7 | MaxMirrorSLPercentage | Maximum allowed Mirror Stop-Loss percentage for this type. |
| 8 | MinMirrorSLPercentage | Minimum allowed Mirror Stop-Loss percentage for this type. |
| 9 | DeafultMirrorSLPercentage | Default Mirror Stop-Loss percentage applied when a user doesn't set one (note: "DeafultMirrorSLPercentage" is the original column name with typo). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | Lookup | Reads the XMLValue for mirror validation rules configuration. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorTypesValidationsDefaults (procedure)
└── Maintenance.Feature (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table (cross-schema) | SELECT XMLValue WHERE FeatureID = 23; XML is shredded via nodes()/value() |

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

### 8.1 Get all mirror type validation defaults

```sql
EXEC Trade.GetMirrorTypesValidationsDefaults;
```

### 8.2 Read raw XML config directly

```sql
SELECT XMLValue
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 23;
```

### 8.3 Get SL range for a specific mirror type using GetMirrorValidation

```sql
DECLARE @MaxSL MONEY, @MinSL MONEY, @DefaultSL MONEY;
EXEC Trade.GetMirrorValidation
    @MirrorTypeID = 1,
    @MaxMirrorSLPercentage = @MaxSL OUTPUT,
    @MinMirrorSLPercentage = @MinSL OUTPUT,
    @DeafultMirrorSLPercentage = @DefaultSL OUTPUT;
SELECT @MaxSL AS MaxSL, @MinSL AS MinSL, @DefaultSL AS DefaultSL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Moe - Mirror Operation Engine](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12857836033/Moe+-+Mirror+Operation+Engine) | Confluence | Mirror validation and SL percentage rules are consumed by MOE service for mirror registration/edit validation |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorTypesValidationsDefaults | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorTypesValidationsDefaults.sql*
