# Trade.GetMirrorValidationRules

> Scalar function that returns the mirror validation rules XML from Maintenance.Feature (FeatureID=23). Used by CopyTrading validation logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns XML |
| **Partition** | N/A |
| **Indexes** | N/A for function |

---

## 1. Business Meaning

Trade.GetMirrorValidationRules returns the XML configuration for mirror (CopyTrading) validation rules. The system stores this configuration in Maintenance.Feature with FeatureID = 23. The function reads XMLValue from that row and returns it. This is a thin wrapper — TradingSettingsAPI and Dealing roles execute it; the actual XML defines validation rules (e.g., min/max allocation, instrument restrictions) used when users configure CopyTrading relationships.

This function exists to provide a single, consistent way for applications to retrieve mirror validation rules without hard-coding FeatureID 23. The procedure Trade.GetMirrorValidationRulesXML performs a similar query (SELECT XMLValue FROM Maintenance.Feature WHERE FeatureID = 23) but as a procedure; the function form allows embedding in expressions.

Data flows: The function is called with no parameters. It selects XMLValue from Maintenance.Feature WHERE FeatureID = 23 and returns it. If no row exists, the function returns NULL.

---

## 2. Business Logic

### 2.1 FeatureID 23 — Mirror Validation Rules

**What**: A single feature row in Maintenance.Feature holds the mirror validation rules XML. FeatureID 23 is the reserved identifier.

**Columns/Parameters Involved**: `FeatureID`, `XMLValue`

**Rules**:
- Maintenance.Feature stores feature configuration keyed by FeatureID.
- FeatureID = 23 is reserved for mirror validation rules. No parameters are passed; the function always reads this row.
- The returned XML defines validation constraints for CopyTrading (e.g., allowed instruments, min/max allocation). Interpretation is done by application code.

**Diagram**:
```
Trade.GetMirrorValidationRules()
        |
        v
SELECT XMLValue FROM Maintenance.Feature WHERE FeatureID = 23
        |
        v
RETURN @XML (or NULL if no row)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return value) | xml | YES | - | CODE-BACKED | XMLValue from Maintenance.Feature where FeatureID = 23. Contains mirror validation rules for CopyTrading. NULL if the row does not exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | Maintenance.Feature | Implicit | Feature configuration table. Reads XMLValue where FeatureID = 23. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dealing | GRANT EXECUTE | Permission | Role can execute the function. |
| TradingSettingsAPI | GRANT EXECUTE | Permission | Role can execute the function. |
| TAPIUser | GRANT EXECUTE | Permission | Role can execute the function. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorValidationRules (function)
└── Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FROM — reads XMLValue WHERE FeatureID = 23 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Application/Trading API) | - | Called via EXECUTE by Dealing, TradingSettingsAPI, TAPIUser roles. No SQL callers found in repo. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get mirror validation rules
```sql
SELECT Trade.GetMirrorValidationRules() AS MirrorValidationRules;
```

### 8.2 Check if rules exist
```sql
SELECT CASE WHEN Trade.GetMirrorValidationRules() IS NOT NULL
            THEN 'Rules configured'
            ELSE 'No rules'
       END AS RulesStatus;
```

### 8.3 Compare with direct Maintenance.Feature query
```sql
SELECT Trade.GetMirrorValidationRules() AS ViaFunction,
       F.XMLValue AS ViaDirect
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.0/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorValidationRules | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetMirrorValidationRules.sql*
