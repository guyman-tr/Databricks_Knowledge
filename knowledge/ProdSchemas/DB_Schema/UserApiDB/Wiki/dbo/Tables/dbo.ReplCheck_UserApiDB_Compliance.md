# dbo.ReplCheck_UserApiDB_Compliance

> Replication health check table for the Compliance data path - updated periodically to verify replication is functioning.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.ReplCheck_UserApiDB_Compliance is a sentinel table used to verify that SQL Server replication for the compliance data path is functioning correctly. The DBA_ReplCheck_Update procedure periodically updates the LastUpdated timestamp. Monitoring systems compare timestamps between publisher and subscriber to detect replication lag.

---

## 2. Business Logic

No complex business logic. Single-row sentinel table for replication monitoring.

---

## 3. Data Overview

Typically 1 row with a periodically updated timestamp.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Typically value 1 (single-row table). |
| 2 | LastUpdated | datetime | NO | - | CODE-BACKED | Timestamp of last replication check update. Compared across replicas to detect lag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DBA_ReplCheck_Update | ID | SP writes | Updates LastUpdated timestamp |

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
| PK_ReplCheck_UserApiDB_Compliance | CLUSTERED PK | ID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check replication status
```sql
SELECT ID, LastUpdated, DATEDIFF(SECOND, LastUpdated, GETUTCDATE()) AS SecondsSinceUpdate FROM dbo.ReplCheck_UserApiDB_Compliance WITH (NOLOCK)
```

### 8.2 Alert if stale
```sql
SELECT CASE WHEN DATEDIFF(MINUTE, LastUpdated, GETUTCDATE()) > 5 THEN 'STALE' ELSE 'OK' END AS Status FROM dbo.ReplCheck_UserApiDB_Compliance WITH (NOLOCK)
```

### 8.3 History of updates
```sql
SELECT * FROM dbo.ReplCheck_UserApiDB_Compliance WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.ReplCheck_UserApiDB_Compliance | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.ReplCheck_UserApiDB_Compliance.sql*
