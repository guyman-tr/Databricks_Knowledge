# Trade.GetMirrorValidation

> Reads mirror stop-loss validation rules from the XML config (Maintenance.Feature FeatureID=23) for a specific mirror type and returns Max, Min, and Default SL percentage as OUTPUT parameters, used by the trading layer before setting or validating a mirror stop-loss.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorTypeID - selects the mirror type's SL validation rules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorValidation` retrieves the Mirror Stop-Loss (MSL) validation boundaries for a specific mirror type from the XML configuration stored in `Maintenance.Feature` (FeatureID=23). Rather than returning a result set, it populates three OUTPUT parameters with the maximum allowed MSL, minimum allowed MSL, and default MSL percentage for the given mirror type.

This procedure is the single-type counterpart to `GetMirrorTypesValidationsDefaults` (which returns all types). It exists to support MSL validation: before accepting a new MSL value from a user, the trading layer calls this procedure to get the allowed range for the mirror type, then validates the requested value is within bounds.

Data flows: Called when validating or setting a Mirror Stop-Loss percentage. The caller passes `@MirrorTypeID` and receives back the three boundary values as OUTPUT parameters - no result set is returned.

---

## 2. Business Logic

### 2.1 XQuery-Based XML Attribute Extraction

**What**: Mirror type validation rules are parsed from XML config using XQuery with a SQL variable predicate.

**Columns/Parameters Involved**: `@MirrorTypeID`, `@MaxMirrorSLPercentage`, `@MinMirrorSLPercentage`, `@DeafultMirrorSLPercentage`

**Rules**:
- Source: `Maintenance.Feature WHERE FeatureID = 23` -> `XMLValue` XML document.
- XQuery: `(MirrorValidationInfo/MirrorType[@ID=sql:variable("@MirrorTypeID")]/@AttributeName)[1]`
- `sql:variable()` injects the T-SQL variable into the XQuery predicate for parameterized attribute selection.
- Returns NULL if `@MirrorTypeID` is not found in the XML.
- Values returned as MONEY type (e.g., 40.00 = 40%).
- Note: "DeafultMirrorSLPercentage" is a typo in the original XML and SP definition - means "Default".

### 2.2 OUTPUT Parameters (No Result Set)

**What**: All values are returned via OUTPUT parameters, not as a SELECT result.

**Rules**:
- Caller must declare MONEY variables and pass them with OUTPUT keyword.
- If the mirror type is not found, all three OUTPUT parameters are NULL.
- No NOCOUNT set explicitly, but SET NOCOUNT ON is present.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorTypeID | INT | NO | - | CODE-BACKED | The mirror type identifier. Used as XQuery predicate to select the matching MirrorType element from the XML config. |
| 2 | @MaxMirrorSLPercentage | MONEY OUTPUT | YES | - | CODE-BACKED | OUTPUT: Maximum allowed Mirror Stop-Loss percentage for this mirror type (e.g., 40.00 = 40%). Returns NULL if type not found. |
| 3 | @MinMirrorSLPercentage | MONEY OUTPUT | YES | - | CODE-BACKED | OUTPUT: Minimum allowed Mirror Stop-Loss percentage. Values below this are rejected by the validation layer. Returns NULL if type not found. |
| 4 | @DeafultMirrorSLPercentage | MONEY OUTPUT | YES | - | CODE-BACKED | OUTPUT: Default Mirror Stop-Loss percentage applied when no MSL is specified. (Parameter name has a typo: "Deafult" = "Default"). Returns NULL if type not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | Lookup | Reads the XMLValue containing mirror type validation configuration. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorValidation (procedure)
└── Maintenance.Feature (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table (cross-schema) | SELECT XMLValue WHERE FeatureID = 23; XML attribute extraction via XQuery with sql:variable() predicate |

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

### 8.1 Get SL validation rules for mirror type 1

```sql
DECLARE @MaxSL MONEY, @MinSL MONEY, @DefaultSL MONEY;
EXEC Trade.GetMirrorValidation
    @MirrorTypeID = 1,
    @MaxMirrorSLPercentage = @MaxSL OUTPUT,
    @MinMirrorSLPercentage = @MinSL OUTPUT,
    @DeafultMirrorSLPercentage = @DefaultSL OUTPUT;
SELECT @MaxSL AS MaxSLPct, @MinSL AS MinSLPct, @DefaultSL AS DefaultSLPct;
```

### 8.2 Validate a proposed SL value before applying

```sql
DECLARE @MaxSL MONEY, @MinSL MONEY, @DefaultSL MONEY;
DECLARE @ProposedSL MONEY = 35.0;
EXEC Trade.GetMirrorValidation
    @MirrorTypeID = 1,
    @MaxMirrorSLPercentage = @MaxSL OUTPUT,
    @MinMirrorSLPercentage = @MinSL OUTPUT,
    @DeafultMirrorSLPercentage = @DefaultSL OUTPUT;
SELECT
    @ProposedSL AS ProposedSL,
    CASE WHEN @ProposedSL BETWEEN @MinSL AND @MaxSL THEN 'Valid' ELSE 'Out of range' END AS ValidationResult;
```

### 8.3 Compare all mirror types using GetMirrorTypesValidationsDefaults

```sql
EXEC Trade.GetMirrorTypesValidationsDefaults;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Moe - Mirror Operation Engine](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12857836033/Moe+-+Mirror+Operation+Engine) | Confluence | Mirror SL percentage validation is enforced by MOE service during mirror registration and edit-stop-loss flows |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorValidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorValidation.sql*
