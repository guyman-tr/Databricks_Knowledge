# Trade.ValidateMirrorStopLossPercentage

> Validates that a CopyTrader stop-loss percentage falls within the configured minimum and maximum bounds per mirror type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (validation result code) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ValidateMirrorStopLossPercentage validates that the stop-loss percentage set on a CopyTrader relationship falls within acceptable bounds. CopyTrader allows users to set a stop-loss as a percentage of their allocated amount - if losses reach that percentage, the copy relationship is automatically closed. This function ensures the user-specified percentage is neither too aggressive (below minimum) nor too conservative/disabled (above maximum).

This function exists because unreasonable stop-loss values could either prematurely terminate a copy relationship (too tight, e.g., 1%) or effectively disable loss protection (too loose, e.g., 100%). The allowed range is configured per mirror type in Maintenance.Feature (FeatureID=23).

Called by Trade.SetMirrorStopLossPercentage, which is the procedure that updates a mirror's stop-loss setting.

---

## 2. Business Logic

### 2.1 Stop-Loss Range Validation

**What**: Ensures the stop-loss percentage is within [MinMirrorSLPercentage, MaxMirrorSLPercentage] bounds.

**Columns/Parameters Involved**: `@MirrorTypeID`, `@Percentage`, `MaxMirrorSLPercentage`, `MinMirrorSLPercentage`

**Rules**:
- Reads FeatureID=23 XML for MaxMirrorSLPercentage and MinMirrorSLPercentage per MirrorType
- If @Percentage > MaxMirrorSLPercentage OR @Percentage < MinMirrorSLPercentage: returns -1
- If @Percentage is within range: returns 1
- Return -1 (generic failure) instead of a specific error code, unlike the amount validation functions

**Diagram**:
```
  MinSL% <----[valid range]----> MaxSL%
     |                              |
     v                              v
  @Percentage < MinSL% --> RETURN -1 (too tight)
  @Percentage > MaxSL% --> RETURN -1 (too loose)
  MinSL% <= @Percentage <= MaxSL% --> RETURN 1 (valid)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorTypeID | INT | NO | - | CODE-BACKED | Mirror type identifier. Determines which min/max SL percentage bounds to apply from the XML configuration. |
| 2 | @Percentage | TINYINT | NO | - | CODE-BACKED | The stop-loss percentage the user wants to set on their copy relationship. Represents the maximum loss percentage before auto-close (e.g., 40 means close if losses reach 40% of allocated amount). |
| 3 | Return value | INT | NO | - | CODE-BACKED | Validation result: 1 = valid (within allowed range), -1 = invalid (outside min/max bounds). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | SELECT (WHERE) | Reads mirror validation XML for SL percentage bounds |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetMirrorStopLossPercentage | Function call | Called | Validates the SL percentage before updating the mirror record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateMirrorStopLossPercentage (function)
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
| Trade.SetMirrorStopLossPercentage | Stored Procedure | Calls to validate SL percentage before saving |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate a stop-loss percentage
```sql
SELECT Trade.ValidateMirrorStopLossPercentage(1, 40) AS ValidationResult
```

### 8.2 Check configured SL bounds
```sql
SELECT F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MinMirrorSLPercentage)[1]', 'MONEY') AS MinSL,
       F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MaxMirrorSLPercentage)[1]', 'MONEY') AS MaxSL
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23
```

### 8.3 Test boundary percentages
```sql
SELECT Pct,
       Trade.ValidateMirrorStopLossPercentage(1, Pct) AS Result
FROM   (VALUES (5), (10), (40), (60), (95)) AS T(Pct)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Stop copying](https://etoro.atlassian.net) | Confluence | CopyTrader stop-loss lifecycle and auto-close behavior |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateMirrorStopLossPercentage | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateMirrorStopLossPercentage.sql*
