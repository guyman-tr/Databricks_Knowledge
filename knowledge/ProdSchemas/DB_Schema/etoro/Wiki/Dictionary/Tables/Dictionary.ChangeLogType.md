# Dictionary.ChangeLogType

> Lookup table intended to classify change log types — currently empty in production but referenced by Trade.GetPositionsChangesForDataApi for position change event reporting.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ChangeLogTypeID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ChangeLogType was designed to classify the types of change log entries in the position change tracking system. Position changes (partial closes, amount modifications, leverage changes, etc.) are logged with a `ChangeTypeID` that corresponds to a row in this table, allowing downstream consumers to filter and categorize change events.

Although the table is currently empty in production (0 rows), the `Trade.GetPositionsChangesForDataApi` procedure selects a `ChangeTypeID AS ChangeLogTypeID` column in its output, indicating that the change type classification is still part of the position change data model. The actual change type values may be hardcoded in application logic or stored in a different location, with this table serving as a planned-but-unimplemented central registry.

Note: the `ChangeLogTypeName` column is typed as `int` (not varchar), which is unusual for a "name" column — this may be a DDL error or an intentional mapping to a numeric code in another system.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is empty and the `int` type for ChangeLogTypeName is unusual.

---

## 3. Data Overview

Table is empty (0 rows in production). No data to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChangeLogTypeID | int | NO | - | CODE-BACKED | Primary key identifying the change log type. Referenced as `ChangeTypeID AS ChangeLogTypeID` in `Trade.GetPositionsChangesForDataApi` output — classifies what kind of position change occurred (partial close, leverage change, etc.). |
| 2 | ChangeLogTypeName | int | NO | - | NAME-INFERRED | Name/code for the change log type. Unusually typed as `int` rather than `varchar` — may represent a numeric code mapping to an external system rather than a human-readable name. No production data exists to clarify the intended values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsChangesForDataApi | ChangeTypeID (aliased as ChangeLogTypeID) | Implicit | Procedure outputs ChangeTypeID from position change log records — the values correspond to types that would be defined in this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsChangesForDataApi | Procedure | Outputs ChangeTypeID aliased as ChangeLogTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ChangeLogType | CLUSTERED PK | ChangeLogTypeID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Check if table has any data
```sql
SELECT  COUNT(*) AS TotalRows
FROM    Dictionary.ChangeLogType WITH (NOLOCK);
```

### 8.2 List all change log types (if populated)
```sql
SELECT  ChangeLogTypeID,
        ChangeLogTypeName
FROM    Dictionary.ChangeLogType WITH (NOLOCK)
ORDER BY ChangeLogTypeID;
```

### 8.3 Find distinct change type IDs used in position changes
```sql
SELECT  DISTINCT ChangeTypeID
FROM    History.PositionChangeLog WITH (NOLOCK)
ORDER BY ChangeTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChangeLogType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ChangeLogType.sql*
