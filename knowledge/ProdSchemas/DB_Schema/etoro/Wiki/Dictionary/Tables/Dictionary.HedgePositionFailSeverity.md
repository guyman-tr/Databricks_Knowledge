# Dictionary.HedgePositionFailSeverity

> Lookup table defining six severity tiers for hedge position failures — from "no problem" through "critical" to "unknown" — used to drive alerting thresholds and escalation paths in the hedge monitoring system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | HedgeSeverityTypeID (TINYINT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgePositionFailSeverity classifies the severity of hedge position failures into six tiers. When a hedge order fails (reasons cataloged in Dictionary.HedgePositionFailReason), the severity determines the operational response: informational logging, investigation requests, or immediate critical alerts to the hedge operations team.

This table exists because not all hedge failures are equal. A request deleted because it was netted away (Severity 1) requires no action. A trade not found during recovery (Severity 3) needs investigation within hours. An unknown error (Severity 6) or slippage breach (Severity 5) requires immediate human attention. Without severity classification, every failure would trigger the same response, overwhelming operators with noise and hiding real problems.

The HedgeSeverityTypeID is referenced by Dictionary.HedgePositionFailReason, which maps each specific failure reason to its severity level.

---

## 2. Business Logic

### 2.1 Severity Escalation Tiers

**What**: Six tiers from informational to critical drive different operational responses.

**Columns/Parameters Involved**: `HedgeSeverityTypeID`, `Name`

**Rules**:
- **Tier 1 — None_NoProblem**: No operational impact. The "failure" is actually a normal outcome (e.g., order absorbed by netting). Logged for audit but no action needed.
- **Tier 2 — Low_Warning**: Minor issue worth tracking in aggregate. Individual occurrences don't require action, but patterns may indicate emerging problems.
- **Tier 3 — Medium**: Requires investigation within business hours. Something unexpected happened but no immediate financial risk (e.g., trade not found during recovery).
- **Tier 4 — High**: Elevated risk. Multiple positions may be affected. Requires prompt response from the hedge operations team.
- **Tier 5 — Critical**: Immediate risk of unhedged exposure. Market-level failures (slippage, liquidity, margin), system failures (DB errors, API errors). Triggers real-time alerts.
- **Tier 6 — Unknown_TBD**: Unclassified error. Treated as potentially critical until investigated. Indicates a gap in failure classification.

**Diagram**:
```
Severity Escalation:
  6 Unknown_TBD  ████████████  → Treat as critical until classified
  5 Critical     ████████████  → Immediate alert, real-time response
  4 High         ██████████    → Prompt response required
  3 Medium       ████████      → Investigate within business hours
  2 Low_Warning  ██████        → Track in aggregate
  1 NoProblem    ████          → Log only, no action
```

---

## 3. Data Overview

| HedgeSeverityTypeID | Name | Meaning |
|---|---|---|
| 1 | None_NoProblem | The "failure" is actually a normal operational outcome — the hedge request was handled through an alternative path (netting, cancellation, provider closure). No action needed. |
| 3 | Medium | Something unexpected occurred but without immediate financial risk. Requires investigation within business hours. Typically: position reconciliation issues found during recovery scans. |
| 5 | Critical | Immediate unhedged exposure risk. Market-level failures (slippage, liquidity, margin) or system failures (DB errors, API errors). Triggers real-time alerts to the hedge operations team. |
| 6 | Unknown_TBD | Unclassified error that doesn't match any known failure pattern. Treated as potentially critical until a human investigates and either resolves it or adds a new classified failure reason. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeSeverityTypeID | tinyint | NO | - | VERIFIED | Primary key identifying the severity tier. 1=None/NoProblem (informational), 2=Low/Warning, 3=Medium (investigate), 4=High (prompt response), 5=Critical (immediate alert), 6=Unknown/TBD (treat as critical). Referenced by Dictionary.HedgePositionFailReason to classify each failure's severity. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Compound severity label using format "Level_Description". Used in monitoring dashboards and alert configurations. The underscore-separated format provides both the severity level and a brief description. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.HedgePositionFailReason | HedgePositionFailSeverity | Implicit FK | Each failure reason is classified with a severity level from this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgePositionFailReason | Table | References severity level for each failure reason classification |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | HedgeSeverityTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PRIMARY KEY | Unique severity type identifier |

---

## 8. Sample Queries

### 8.1 List all severity tiers
```sql
SELECT  HedgeSeverityTypeID,
        Name
FROM    [Dictionary].[HedgePositionFailSeverity] WITH (NOLOCK)
ORDER BY HedgeSeverityTypeID;
```

### 8.2 Join severity to failure reasons
```sql
SELECT  fr.HedgeFailID,
        fr.FailText,
        fs.HedgeSeverityTypeID,
        fs.Name AS SeverityLevel
FROM    [Dictionary].[HedgePositionFailReason] fr WITH (NOLOCK)
JOIN    [Dictionary].[HedgePositionFailSeverity] fs WITH (NOLOCK)
        ON fr.HedgePositionFailSeverity = fs.HedgeSeverityTypeID
ORDER BY fs.HedgeSeverityTypeID, fr.HedgeFailID;
```

### 8.3 Count failure reasons per severity tier
```sql
SELECT  fs.Name AS SeverityLevel,
        COUNT(fr.HedgeFailID) AS FailureReasonCount
FROM    [Dictionary].[HedgePositionFailSeverity] fs WITH (NOLOCK)
LEFT JOIN [Dictionary].[HedgePositionFailReason] fr WITH (NOLOCK)
        ON fr.HedgePositionFailSeverity = fs.HedgeSeverityTypeID
GROUP BY fs.Name, fs.HedgeSeverityTypeID
ORDER BY fs.HedgeSeverityTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgePositionFailSeverity | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgePositionFailSeverity.sql*
