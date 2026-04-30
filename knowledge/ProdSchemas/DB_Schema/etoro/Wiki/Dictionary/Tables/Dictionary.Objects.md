# Dictionary.Objects

> Registry of application-level objects and operations that are subject to permission checks, mapping BackOffice tools (Configuration Manager, DealingReportGenerator, CEP UI) to their controllable operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ObjectID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.Objects is a permission-target registry that lists the specific application objects and operations that can be controlled through the platform's permission system. Each entry represents a distinct "thing" in an application (like "Spreads configuration" in Configuration Manager or "Hedge Cost Report" in DealingReportGenerator) that a user may or may not have permission to access.

Without this table, the Internal.CheckSinglePermission procedure could not validate whether a BackOffice user has access to a specific application feature. It is the foundation of the fine-grained authorization system for internal tools.

The 28 entries span Configuration Manager (instrument configs, bulk operations, contracts, spreads), DealingReportGenerator (cost/slippage/markup reports), and CEP UI (Complex Event Processing authorization). Each object belongs to an AppName (the parent application) and has a unique ObjectName.

---

## 2. Business Logic

### 2.1 Application Permission Domains

**What**: Three application domains with granular object-level permissions.

**Columns/Parameters Involved**: `ObjectID`, `AppName`, `ObjectName`, `Description`

**Rules**:
- Configuration Manager (IDs 1-5, 12-23, 25-28): Instrument configuration, contract management, bulk operations, trading system settings, special permissions
- DealingReportGenerator (IDs 8-11): Report access control for hedge cost, slippage, markup, and detailed cost reports
- ConfigurationManager (IDs 6-7, 14, 25-28): Alternate casing of same app — feature thresholds, spreads, contract rollout, copy restrictions
- CEP UI (ID 24): Complex Event Processing operations authorization
- Internal.CheckSinglePermission validates user access by matching (AppName + ObjectName) against user grants

**Diagram**:
```
Permission System:
  Configuration Manager ──> Contracts, Schedules, LP Contracts, Trading Configs
                        ──> Bulk Operations (Regular + Advanced + Allowed CIDs)
                        ──> Special Permissions, System Operations
  
  DealingReportGenerator ──> HedgeCost, Slippage, MarkUp, HedgeCostDetailed
  
  CEP UI ──────────────────> CEP Operations authorization
```

---

## 3. Data Overview

| ObjectID | AppName | ObjectName | Meaning |
|---|---|---|---|
| 1 | Configuration Manager | TradonomiContracts | Permission to modify instrument contract configurations — controls which users can change contract terms |
| 14 | ConfigurationManager | Spreads | Permission to modify Trade.Spread — controls who can change bid/ask spread configurations for instruments |
| 19 | Configuration Manager | RegularBulkOpenOrderOperation | Permission to execute bulk order operations for a limited set of whitelisted customer IDs |
| 22 | Configuration Manager | DealingSpecialPermissions | Permission to modify high-impact instrument configurations — restricted to senior dealing desk staff |
| 24 | CEP UI | CEPOperations | Permission to manage Complex Event Processing rules — controls automated trading and notification triggers |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ObjectID | int | NO | - | CODE-BACKED | Unique identifier for the permissioned object. Values 1-28. Referenced by Internal.CheckSinglePermission for authorization checks. |
| 2 | AppName | varchar(50) | NO | - | VERIFIED | Parent application name: "Configuration Manager", "ConfigurationManager" (alternate casing), "DealingReportGenerator", "CEP UI". Used with ObjectName as a composite key for permission lookups. |
| 3 | ObjectName | varchar(50) | NO | - | VERIFIED | Specific object/operation within the application (e.g., "Spreads", "HedgeCostReport", "CEPOperations"). Combined with AppName to uniquely identify a permission target. |
| 4 | Description | varchar(500) | YES | - | CODE-BACKED | Human-readable description of what the object controls. Some entries use the ObjectName as the description; others provide more detailed context like "Bulk open operation for all whitelisted cids". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.CheckSinglePermission | ObjectID/AppName+ObjectName | Implicit | Permission check procedure validates user access against this registry |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.CheckSinglePermission | Stored Procedure | Reads objects for permission validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_Objects | CLUSTERED PK | ObjectID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all permissioned objects
```sql
SELECT  ObjectID,
        AppName,
        ObjectName,
        Description
FROM    [Dictionary].[Objects] WITH (NOLOCK)
ORDER BY AppName, ObjectName;
```

### 8.2 Find objects for Configuration Manager
```sql
SELECT  *
FROM    [Dictionary].[Objects] WITH (NOLOCK)
WHERE   AppName LIKE '%Configuration%'
ORDER BY ObjectID;
```

### 8.3 Find all report-related permission objects
```sql
SELECT  *
FROM    [Dictionary].[Objects] WITH (NOLOCK)
WHERE   AppName = 'DealingReportGenerator'
ORDER BY ObjectID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Objects | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Objects.sql*
