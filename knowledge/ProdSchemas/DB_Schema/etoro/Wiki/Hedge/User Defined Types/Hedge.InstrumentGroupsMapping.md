# Hedge.InstrumentGroupsMapping

> Table-valued parameter type carrying a set of instrument group IDs with their active/inactive state for group-based configuration queries and updates.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | GroupID (PRIMARY KEY CLUSTERED) |
| **Partition** | N/A |
| **Indexes** | 1 (PK CLUSTERED on GroupID) |

---

## 1. Business Meaning

`Hedge.InstrumentGroupsMapping` is a Table-Valued Parameter (TVP) type that carries a batch of instrument group IDs together with their activation state. It is structurally analogous to `Hedge.ActiveAccountMapping` but operates on instrument groups rather than liquidity accounts.

Instrument groups in the Hedge schema (see `Hedge.InstrumentGroups`) are logical groupings of trading instruments used to apply shared configuration, execution strategy, and order type rules. This TVP allows callers to pass a filtered set of groups - with their active/inactive flags - so stored procedures can return or update configuration only for the specified groups.

Both consumers (`Hedge.GetInstrumentGroupsMapping` and `Hedge.GetOrderTypeConfiguration`) are reader procedures that use the TVP as a filter to scope their result sets to only the groups the caller cares about.

---

## 2. Business Logic

### 2.1 Group-Scoped Configuration Filtering

**What**: The TVP acts as a filter and state directive - which instrument groups to include, and what active state to consider.

**Columns/Parameters Involved**: `GroupID`, `IsActive`

**Rules**:
- `IsActive = 1`: include only active groups in the configuration query result.
- `IsActive = 0`: include inactive groups (used for audit/admin queries).
- `GroupID` is the PK of `Hedge.InstrumentGroups` - the TVP values must correspond to valid group IDs.
- The CLUSTERED PK with `IGNORE_DUP_KEY = OFF` means duplicate GroupIDs in the TVP batch are rejected immediately.
- Callers typically populate this TVP with the specific groups a hedge server instance is responsible for managing.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | CODE-BACKED | Instrument group identifier. PK of Hedge.InstrumentGroups. Used to scope configuration queries to specific groups. PK of this TVP - duplicate GroupIDs in the same batch are rejected (IGNORE_DUP_KEY = OFF). |
| 2 | IsActive | bit | NO | - | CODE-BACKED | Active state filter for the group: 1 = include only active groups in query results, 0 = include inactive groups. Used by consumer SPs to filter Hedge.InstrumentGroupsMapping rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Hedge.InstrumentGroups | Implicit | Values correspond to group IDs in the instrument groups table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetInstrumentGroupsMapping | @Groups parameter | TVP parameter | Filters instrument group mapping results to the caller-specified groups |
| Hedge.GetOrderTypeConfiguration | @Groups parameter | TVP parameter | Scopes order type configuration retrieval to the specified instrument groups |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetInstrumentGroupsMapping | Stored Procedure | Filters instrument group mapping by caller-provided groups |
| Hedge.GetOrderTypeConfiguration | Stored Procedure | Filters order type config by caller-provided instrument groups |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (inline) | CLUSTERED | GroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (inline) | PRIMARY KEY | IGNORE_DUP_KEY = OFF - duplicate GroupID values in the batch cause an error |

---

## 8. Sample Queries

### 8.1 Declare and use to query instrument group configuration
```sql
DECLARE @Groups [Hedge].[InstrumentGroupsMapping]
INSERT INTO @Groups (GroupID, IsActive) VALUES (1, 1), (2, 1), (3, 1)

EXEC [Hedge].[GetInstrumentGroupsMapping] @Groups = @Groups
```

### 8.2 View instrument groups and their configurations
```sql
SELECT IG.GroupID, IG.GroupName, IGM.InstrumentID
FROM [Hedge].[InstrumentGroups] IG WITH (NOLOCK)
JOIN [Hedge].[InstrumentGroupsMapping] IGM WITH (NOLOCK)
  ON IG.GroupID = IGM.GroupID
WHERE IG.IsActive = 1
ORDER BY IG.GroupID
```

### 8.3 Find order type configuration for active groups
```sql
SELECT OTC.GroupID, OTC.OrderTypeID, OTC.IsActive
FROM [Hedge].[OrderTypeConfiguration] OTC WITH (NOLOCK)
WHERE OTC.IsActive = 1
ORDER BY OTC.GroupID, OTC.OrderTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InstrumentGroupsMapping | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.InstrumentGroupsMapping.sql*
