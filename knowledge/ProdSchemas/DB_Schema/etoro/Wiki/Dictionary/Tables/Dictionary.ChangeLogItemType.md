# Dictionary.ChangeLogItemType

> Self-referencing lookup table intended to classify change log item types — currently empty in production with no known consumers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ChangeItemTypeID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ChangeLogItemType was designed to classify the types of individual items within a change log entry — for example, distinguishing between a price change, a leverage change, or a position size change within a single change event. Each change log entry could contain multiple items of different types.

The table is currently empty in production (0 rows) and has no consumers in the SSDT project other than its own DDL. The self-referencing FK (`FK_ChangeLogItemType_ChangeLogItemType` where `ChangeItemTypeID` references itself) is an unusual pattern that may have been intended for a hierarchical item type structure (parent-child type categories) but was never implemented.

This table appears to be an unused artifact from a feature that was either never completed or was replaced by a different change tracking mechanism.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The self-referencing FK suggests a planned hierarchy of change item types, but with 0 rows in production, no business logic is active.

---

## 3. Data Overview

Table is empty (0 rows in production). No data to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChangeItemTypeID | int | NO | - | CODE-BACKED | Primary key identifying the change item type. Also has a self-referencing FK (`FK_ChangeLogItemType_ChangeLogItemType`), suggesting a planned hierarchical type structure where child types would reference parent types. Currently 0 rows in production. |
| 2 | ChangeItemTypeName | nvarchar(50) | NO | - | NAME-INFERRED | Name/label for the change item type. No production data or codebase references exist to determine the intended values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChangeItemTypeID | Dictionary.ChangeLogItemType (self) | FK (FK_ChangeLogItemType_ChangeLogItemType) | Self-referencing FK — would allow hierarchical parent/child type relationships if populated |

### 5.2 Referenced By (other objects point to this)

No references found in the SSDT project. Table appears unused.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (self-reference only).

### 6.1 Objects This Depends On

No dependencies (the self-FK is circular, not an external dependency).

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ChangeLogItemType_1 | CLUSTERED PK | ChangeItemTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_ChangeLogItemType_ChangeLogItemType | FK (self-reference) | ChangeItemTypeID references Dictionary.ChangeLogItemType(ChangeItemTypeID) — enables hierarchical type tree |

---

## 8. Sample Queries

### 8.1 Check if table has any data
```sql
SELECT  COUNT(*) AS TotalRows
FROM    Dictionary.ChangeLogItemType WITH (NOLOCK);
```

### 8.2 List all change item types (if populated)
```sql
SELECT  ChangeItemTypeID,
        ChangeItemTypeName
FROM    Dictionary.ChangeLogItemType WITH (NOLOCK)
ORDER BY ChangeItemTypeID;
```

### 8.3 Find root-level types (no parent)
```sql
SELECT  ChangeItemTypeID,
        ChangeItemTypeName
FROM    Dictionary.ChangeLogItemType WITH (NOLOCK)
WHERE   ChangeItemTypeID NOT IN (
            SELECT  ChangeItemTypeID
            FROM    Dictionary.ChangeLogItemType WITH (NOLOCK)
        )
ORDER BY ChangeItemTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChangeLogItemType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ChangeLogItemType.sql*
