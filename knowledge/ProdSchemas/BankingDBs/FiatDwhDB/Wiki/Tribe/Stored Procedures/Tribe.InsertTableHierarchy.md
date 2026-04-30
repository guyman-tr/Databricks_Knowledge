# Tribe.InsertTableHierarchy

> Idempotent procedure that inserts a table hierarchy record if it doesn't already exist (check by TableName).

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Conditional INSERT into TablesHierarchy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertTableHierarchy registers a Tribe table's position in the JSON hierarchy. Checks if the TableName already exists (WITH NOLOCK); if not, inserts the table name and full hierarchy path. Idempotent - safe to call repeatedly for the same table.

---

## 2. Business Logic

### 2.1 Idempotent Insert

**Rules**:
- IF NOT EXISTS (SELECT WHERE TableName = @tableName) -> INSERT
- Uses WITH(NOLOCK) for the existence check
- No return value

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tableName | nvarchar(max) | NO | - | CODE-BACKED | SQL table name to register. |
| 2 | @hierarchy | nvarchar(max) | NO | - | CODE-BACKED | Full JSON hierarchy path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | Tribe.TablesHierarchy | Read/Write | Idempotent insert |

### 5.2 Referenced By (other objects point to this)

Not analyzed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.InsertTableHierarchy (procedure)
└── Tribe.TablesHierarchy (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.TablesHierarchy | Table | Conditional INSERT target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Register a table hierarchy
```sql
EXEC Tribe.InsertTableHierarchy @tableName = 'AccountsActivities_AccountActivity-833937',
    @hierarchy = 'AccountsActivities -> AccountActivity';
```

### 8.2 Verify
```sql
SELECT * FROM Tribe.TablesHierarchy WITH (NOLOCK)
WHERE TableName = 'AccountsActivities_AccountActivity-833937';
```

### 8.3 Test idempotency
```sql
-- Second call should not insert
EXEC Tribe.InsertTableHierarchy @tableName = 'AccountsActivities_AccountActivity-833937',
    @hierarchy = 'AccountsActivities -> AccountActivity';
SELECT COUNT(*) FROM Tribe.TablesHierarchy WITH (NOLOCK)
WHERE TableName = 'AccountsActivities_AccountActivity-833937';
-- Should return 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Object: Tribe.InsertTableHierarchy | Type: Stored Procedure | Source: FiatDwhDB/Tribe/Stored Procedures/Tribe.InsertTableHierarchy.sql*
