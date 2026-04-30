# Trade.InstrumentGroupNameAndIDTbl

> TVP for updating existing instrument group definitions. GroupID identifies the row; GroupName and Description are the new values.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | GroupID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.InstrumentGroupNameAndIDTbl is a table-valued parameter for updating existing instrument group definitions. GroupID identifies the row in Trade.InstrumentGroups. GroupName and Description are the new values to apply. Both strings use binary collation (Latin1_General_BIN) for case-sensitive matching. Used for admin configuration of instrument groupings such as "Crypto", "Indices", and "Commodities".

---

## 2. Business Logic

### 2.1 Bulk update of instrument group metadata

**What**: The TVP passes rows with GroupID and the new GroupName/Description. UpdateTradingInstrumentGroupName updates the matching rows in Trade.InstrumentGroups.

**Columns/Parameters Involved**: GroupID, GroupName, Description

**Rules**: GroupID must exist in Trade.InstrumentGroups. GroupName and Description use Latin1_General_BIN for case-sensitive comparison. One row per group to update.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | No | - | 10 | Instrument group identifier (Trade.InstrumentGroups) |
| 2 | GroupName | varchar(50) | No | - | 10 | Display name for the group (Latin1_General_BIN) |
| 3 | Description | varchar(200) | Yes | - | 10 | Optional group description (Latin1_General_BIN) |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.InstrumentGroups (GroupID) | Target table for update |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.UpdateTradingInstrumentGroupName | Parameter @UpdateInstrumentGroupsTable |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.UpdateTradingInstrumentGroupName

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update instrument group names and descriptions

```sql
DECLARE @UpdateInstrumentGroupsTable Trade.InstrumentGroupNameAndIDTbl;
INSERT INTO @UpdateInstrumentGroupsTable (GroupID, GroupName, Description)
VALUES (1, 'Crypto', 'Cryptocurrency instruments'),
       (2, 'Indices', 'Stock indices and ETFs');
EXEC Trade.UpdateTradingInstrumentGroupName @UpdateInstrumentGroupsTable = @UpdateInstrumentGroupsTable;
```

### 8.2 Build from InstrumentGroups

```sql
DECLARE @T Trade.InstrumentGroupNameAndIDTbl;
INSERT INTO @T (GroupID, GroupName, Description)
SELECT GroupID, GroupName + '_v2', Description
FROM Trade.InstrumentGroups
WHERE GroupID IN (1, 2, 3);
EXEC Trade.UpdateTradingInstrumentGroupName @UpdateInstrumentGroupsTable = @T;
```

### 8.3 Verify type columns

```sql
SELECT c.name, t.name AS type_name, c.max_length
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'InstrumentGroupNameAndIDTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.UpdateTradingInstrumentGroupName*
*Object: Trade.InstrumentGroupNameAndIDTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentGroupNameAndIDTbl.sql*
