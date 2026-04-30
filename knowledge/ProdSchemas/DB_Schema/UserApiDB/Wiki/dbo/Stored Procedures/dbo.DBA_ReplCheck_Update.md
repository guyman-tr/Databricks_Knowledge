# dbo.DBA_ReplCheck_Update

> DBA procedure that updates all ReplCheck_* sentinel tables to verify replication health by dynamically finding and updating each published table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.DBA_ReplCheck_Update dynamically finds all tables matching 'ReplCheck%' that are published (replicated), and updates their LastUpdated timestamp. If the row doesn't exist, it inserts one. This drives replication lag monitoring - subscribers compare their LastUpdated with the publisher's.

---

## 2. Business Logic

### 2.1 Dynamic Update Pattern

**What**: Dynamically generates and executes UPDATE/INSERT for each ReplCheck table.

**Rules**:
- Queries sys.tables for tables named 'ReplCheck%' with is_published=1
- For each: UPDATE LastUpdated = GETDATE(); if no rows affected, INSERT
- Uses dynamic SQL (EXEC(@SQL))

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Updates ReplCheck_UserApiDB_Compliance and ReplCheck_UserApiDB_Settings.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.ReplCheck_UserApiDB_Compliance | UPDATE/INSERT | Updates timestamp |
| - | dbo.ReplCheck_UserApiDB_Settings | UPDATE/INSERT | Updates timestamp |

### 5.2 Referenced By (other objects point to this)

DBA SQL Agent job (scheduled).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DBA_ReplCheck_Update (procedure)
  +-- dbo.ReplCheck_UserApiDB_Compliance (table) [done]
  +-- dbo.ReplCheck_UserApiDB_Settings (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ReplCheck_* tables | Tables | Dynamic UPDATE/INSERT |

### 6.2 Objects That Depend On This

DBA scheduled job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run replication check update
```sql
EXEC dbo.DBA_ReplCheck_Update
```

### 8.2 Verify timestamps were updated
```sql
SELECT 'Compliance' AS Path, LastUpdated FROM dbo.ReplCheck_UserApiDB_Compliance WITH (NOLOCK)
UNION ALL SELECT 'Settings', LastUpdated FROM dbo.ReplCheck_UserApiDB_Settings WITH (NOLOCK)
```

### 8.3 Check replication lag
```sql
SELECT 'Compliance' AS Path, DATEDIFF(SECOND, LastUpdated, GETUTCDATE()) AS LagSeconds FROM dbo.ReplCheck_UserApiDB_Compliance WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.DBA_ReplCheck_Update | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.DBA_ReplCheck_Update.sql*
