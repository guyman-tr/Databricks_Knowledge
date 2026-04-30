# Trade.GetTradeActivityActionTypes

> Returns the combined trade activity action type mapping: open position types with 'PositionOpenNotification', and close position types with both 'PositionCloseNotification' and 'PartialPositionCloseNotification'. No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the configuration table used by the **Trade Activity** notification system to map internal action type IDs to notification type names. The Trade Activity system raises events (notifications) when positions are opened, closed, or partially closed; each notification type has a corresponding set of action type IDs.

The output is a three-way UNION ALL:
1. **PositionOpenNotification**: Maps each OpenPositionActionTypeID + ExecutionActionTypeID pair to the "position open" notification event
2. **PositionCloseNotification**: Maps each ClosePositionActionTypeID + ExecutionActionTypeID pair to the "position close" notification event
3. **PartialPositionCloseNotification**: Maps the **same** ClosePositionActionTypeID + ExecutionActionTypeID pairs to the "partial position close" notification event

The fact that ClosePositionActionTypes appear twice (for both full close and partial close notifications) is intentional: the same close action types can trigger either a full or partial close notification depending on the context. The calling service uses the ActionTypeName to route to the correct notification handler.

`ExecutionActionTypeID` is the action type as seen by the execution system; `ActionTypeID` (open or close) is the trade activity system's own identifier. This cross-reference allows the trade activity service to correlate execution events with trade activity notifications.

---

## 2. Business Logic

### 2.1 Three-Part Notification Type Mapping

**What**: A UNION ALL produces three logical groups of action type mappings, each with a fixed notification type name.

**Columns/Parameters Involved**: `OpenPositionActionTypeID`, `ClosePositionActionTypeID`, `ExecutionActionTypeID`, `ActionTypeName`

**Rules**:
- Part 1: SELECT from Dictionary.TradeActivity_OpenPositionActionTypes -> ActionTypeName = 'PositionOpenNotification'
- Part 2: SELECT from Dictionary.TradeActivity_ClosePositionActionTypes -> ActionTypeName = 'PositionCloseNotification'
- Part 3: SELECT from Dictionary.TradeActivity_ClosePositionActionTypes (same rows) -> ActionTypeName = 'PartialPositionCloseNotification'
- UNION ALL (not UNION): duplicates are preserved, and all three groups are required even if they overlap
- Column alias: `OpenPositionActionTypeID AS ActionTypeID` and `ClosePositionActionTypeID AS ActionTypeID` -> both normalize to `ActionTypeID`

**Diagram**:
```
Dictionary.TradeActivity_OpenPositionActionTypes:
  (OpenPositionActionTypeID=1, ExecutionActionTypeID=101) -> ('PositionOpenNotification')
  (OpenPositionActionTypeID=2, ExecutionActionTypeID=102) -> ('PositionOpenNotification')
  ...

Dictionary.TradeActivity_ClosePositionActionTypes:
  (ClosePositionActionTypeID=10, ExecutionActionTypeID=201) -> ('PositionCloseNotification')
  (ClosePositionActionTypeID=10, ExecutionActionTypeID=201) -> ('PartialPositionCloseNotification')
  (ClosePositionActionTypeID=11, ExecutionActionTypeID=202) -> ('PositionCloseNotification')
  (ClosePositionActionTypeID=11, ExecutionActionTypeID=202) -> ('PartialPositionCloseNotification')

Application use: lookup (ActionTypeID, ExecutionActionTypeID) -> ActionTypeName
  -> Route to appropriate notification handler
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | INT | NO | - | CODE-BACKED | Trade activity action type ID. For open rows: from Dictionary.TradeActivity_OpenPositionActionTypes.OpenPositionActionTypeID. For close rows: from Dictionary.TradeActivity_ClosePositionActionTypes.ClosePositionActionTypeID. |
| 2 | ExecutionActionTypeID | INT | NO | - | CODE-BACKED | Execution system action type ID. Cross-reference between trade activity and execution subsystems. Present in both source tables. |
| 3 | ActionTypeName | VARCHAR(40) | NO | - | CODE-BACKED | Constant notification type string: 'PositionOpenNotification' (from open table), 'PositionCloseNotification' (from close table, first pass), or 'PartialPositionCloseNotification' (from close table, second pass). Used by the trade activity service to select the notification handler. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OpenPositionActionTypeID, ExecutionActionTypeID | Dictionary.TradeActivity_OpenPositionActionTypes | Reader (cross-schema) | Source of open action type mappings (Part 1 of UNION) |
| ClosePositionActionTypeID, ExecutionActionTypeID | Dictionary.TradeActivity_ClosePositionActionTypes | Reader (cross-schema, twice) | Source of close action type mappings (Parts 2 and 3 of UNION) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade activity service | (none) | Application call | Loads action type -> notification type mapping at startup or cache refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTradeActivityActionTypes (procedure)
+-- Dictionary.TradeActivity_OpenPositionActionTypes (table - cross-schema)
+-- Dictionary.TradeActivity_ClosePositionActionTypes (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TradeActivity_OpenPositionActionTypes | Table (Dictionary schema) | SELECT OpenPositionActionTypeID, ExecutionActionTypeID for Part 1 |
| Dictionary.TradeActivity_ClosePositionActionTypes | Table (Dictionary schema) | SELECT ClosePositionActionTypeID, ExecutionActionTypeID for Parts 2 and 3 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade activity notification service | External application | Loads action type -> notification type routing map |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| UNION ALL (not UNION) | Design | Preserves all rows; close types appear twice (once per notification type) |
| Constant ActionTypeName | Design | 'PositionOpenNotification', 'PositionCloseNotification', 'PartialPositionCloseNotification' are hardcoded strings, not from a lookup |

---

## 8. Sample Queries

### 8.1 Get all trade activity action type mappings

```sql
EXEC Trade.GetTradeActivityActionTypes;
```

### 8.2 Count mappings per notification type

```sql
-- Shows how many action types map to each notification
SELECT ActionTypeName, COUNT(*) AS MappingCount
FROM (
    SELECT OpenPositionActionTypeID AS ActionTypeID, ExecutionActionTypeID, 'PositionOpenNotification' AS ActionTypeName
    FROM Dictionary.TradeActivity_OpenPositionActionTypes
    UNION ALL
    SELECT ClosePositionActionTypeID, ExecutionActionTypeID, 'PositionCloseNotification'
    FROM Dictionary.TradeActivity_ClosePositionActionTypes
    UNION ALL
    SELECT ClosePositionActionTypeID, ExecutionActionTypeID, 'PartialPositionCloseNotification'
    FROM Dictionary.TradeActivity_ClosePositionActionTypes
) t
GROUP BY ActionTypeName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTradeActivityActionTypes | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTradeActivityActionTypes.sql*
