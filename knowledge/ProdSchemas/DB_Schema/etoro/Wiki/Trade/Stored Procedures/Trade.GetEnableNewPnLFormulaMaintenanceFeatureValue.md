# Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue

> Retrieves the feature flag that controls whether the new P&L calculation formula is active for Execution Services.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single BIT value (1 = enabled, 0 = disabled) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a configuration lookup that determines which P&L (Profit and Loss) calculation formula the Execution Services use at runtime. It reads a single feature flag from the central `Maintenance.Feature` configuration table and returns it as a boolean.

The new P&L formula was introduced to improve accuracy in spread calculations, markup handling, and conversion rate precision. Without this feature flag, the system would have no way to toggle between the legacy and new formula, making gradual rollout and emergency rollback impossible.

Data flow: The procedure is called by the `EnableNewPnLFormulaRepository` in the trading Execution Services application. Both the PreExecution and PostExecution service bootstraps register this repository, meaning the flag is checked during position open and close flows. The result determines which P&L calculation path the application takes - legacy (value 0) or new formula (value 1).

---

## 2. Business Logic

### 2.1 Feature Flag Pattern

**What**: Binary configuration switch stored in the central Maintenance.Feature table.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Maintenance.Feature.Value`

**Rules**:
- FeatureID 120 is the designated key for "EnableNewPnLFormula"
- Value is stored as `sql_variant` and cast to BIT on retrieval: 0 = use legacy P&L formula, 1 = use new P&L formula
- Changes to this feature flag are audited via history triggers on `Maintenance.Feature` (INSERT/UPDATE/DELETE triggers write to `History.Feature`)

**Diagram**:
```
Maintenance.Feature (FeatureID=120)
        |
        v
  CAST(Value AS BIT)
        |
        v
  EnableNewPnLFormulaRepository.GetEnableNewPnLFormulaAsync()
        |
        +---> PreExecution Service (position open P&L setup)
        +---> PostExecution Service (position close P&L calculation)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Return Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Value | BIT | YES | - | VERIFIED | New P&L formula toggle: 1 = new formula enabled (more accurate spread calculations, improved markup handling, better conversion rate precision), 0 = legacy formula active. Cast from `sql_variant` in `Maintenance.Feature`. Currently set to 1 (enabled). (Source: DB live data + Confluence + App code) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID = 120 | Maintenance.Feature | Lookup | Reads the feature flag row for EnableNewPnLFormula configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EnableNewPnLFormulaRepository (App) | GetEnableNewPnLFormulaAsync() | SP Call | C# repository in trading-execution-services calls this procedure to retrieve the flag value |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue (procedure)
  └── Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT with WHERE FeatureID = 120 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EnableNewPnLFormulaRepository (App) | Application Repository | Calls this SP to read the P&L formula toggle (Source: trading-execution-services) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure directly
```sql
EXEC Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue;
```

### 8.2 Check feature flag with description context
```sql
SELECT  FeatureID,
        CAST(Value AS BIT) AS IsEnabled,
        Description
FROM    Maintenance.Feature WITH (NOLOCK)
WHERE   FeatureID = 120;
```

### 8.3 View change history for this feature flag
```sql
SELECT  FeatureID,
        CAST(Value AS BIT) AS IsEnabled,
        ValidFrom,
        ValidTo
FROM    History.Feature WITH (NOLOCK)
WHERE   FeatureID = 120
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795721233) | Confluence | Business purpose: new P&L formula improves spread calculations, markup handling, and conversion rate precision. Called by Execution Services and P&L calculation services. Feature flag allows gradual rollout and rollback. |

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 10.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repos / 3 files | Corrections: 0 applied*
*Object: Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue.sql*
