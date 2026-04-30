# dbo.ReplCheck_UserApiDB_Settings

> Replication health check table for the Settings data path - identical structure to ReplCheck_UserApiDB_Compliance.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.ReplCheck_UserApiDB_Settings is a sentinel table for monitoring replication health on the Settings data path. Same pattern as ReplCheck_UserApiDB_Compliance - single row updated periodically, timestamps compared across replicas.

---

## 2. Business Logic

No complex business logic. Replication sentinel.

---

## 3. Data Overview

Typically 1 row with periodically updated timestamp.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Typically value 1. |
| 2 | LastUpdated | datetime | NO | - | CODE-BACKED | Last replication check timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DBA_ReplCheck_Update | ID | SP writes | Updates timestamp |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DBA_ReplCheck_Update | Stored Procedure | Updates LastUpdated |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReplCheck_UserApiDB_Settings | CLUSTERED PK | ID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check status
```sql
SELECT ID, LastUpdated, DATEDIFF(SECOND, LastUpdated, GETUTCDATE()) AS Lag FROM dbo.ReplCheck_UserApiDB_Settings WITH (NOLOCK)
```

### 8.2 Compare both repl checks
```sql
SELECT 'Compliance' AS Path, LastUpdated FROM dbo.ReplCheck_UserApiDB_Compliance WITH (NOLOCK)
UNION ALL SELECT 'Settings', LastUpdated FROM dbo.ReplCheck_UserApiDB_Settings WITH (NOLOCK)
```

### 8.3 Alert query
```sql
SELECT CASE WHEN DATEDIFF(MINUTE, LastUpdated, GETUTCDATE()) > 5 THEN 'STALE' ELSE 'OK' END FROM dbo.ReplCheck_UserApiDB_Settings WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.ReplCheck_UserApiDB_Settings | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.ReplCheck_UserApiDB_Settings.sql*
