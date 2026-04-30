# Dictionary.SyncStatus

> Lookup table defining the status of data synchronization operations between systems.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (SMALLINT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.SyncStatus tracks whether a data synchronization operation has been completed. When user data changes and needs to be propagated to downstream systems, a sync record is created as Pending and transitions to Done upon successful completion. This simple two-state model provides operational visibility into sync pipeline health.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Binary state: Pending -> Done.

---

## 3. Data Overview

| StatusID | Name | Meaning |
|---|---|---|
| 1 | Pending | Sync operation queued but not yet executed - awaiting processing by sync service |
| 2 | Done | Sync operation completed successfully - data propagated to downstream systems |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | smallint | NO | - | CODE-BACKED | Primary key. Sync state: 1=Pending, 2=Done. See [Sync Status](_glossary.md#sync-status). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Status label used in sync monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Sync queue tables | StatusID | Lookup | Tracks current state of each sync operation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SyncStatus | CLUSTERED PK | StatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List sync statuses
```sql
SELECT StatusID, Name FROM Dictionary.SyncStatus WITH (NOLOCK) ORDER BY StatusID
```

### 8.2 Count pending vs done
```sql
SELECT ss.Name, COUNT(*) AS SyncCount FROM Sync.SyncQueue sq WITH (NOLOCK)
JOIN Dictionary.SyncStatus ss WITH (NOLOCK) ON sq.StatusID = ss.StatusID GROUP BY ss.Name
```

### 8.3 Find stale pending syncs
```sql
SELECT sq.CustomerID, sq.CreatedDate, ss.Name FROM Sync.SyncQueue sq WITH (NOLOCK)
JOIN Dictionary.SyncStatus ss WITH (NOLOCK) ON sq.StatusID = ss.StatusID
WHERE ss.StatusID = 1 AND sq.CreatedDate < DATEADD(HOUR, -1, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.SyncStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.SyncStatus.sql*
