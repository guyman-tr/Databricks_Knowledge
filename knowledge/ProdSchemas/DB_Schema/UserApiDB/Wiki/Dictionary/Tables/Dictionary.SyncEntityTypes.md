# Dictionary.SyncEntityTypes

> Lookup table defining types of user data entities that can be synchronized between systems.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EntityTypeId (SMALLINT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.SyncEntityTypes defines the categories of user data that can be synchronized between UserApiDB and other services. When user data changes, the system needs to propagate updates to downstream consumers. This table defines the granularity of those sync operations - rather than syncing the entire user profile, only the changed data category is queued.

The five entity types represent logical groupings: BasicInfo (name, DOB), ContactInfo (email, phone, address), AccountInfo (regulation, label, status), RiskInfo (KYC, MiFID), and User settings (preferences). This enables efficient, targeted synchronization.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| EntityTypeId | Name | Meaning |
|---|---|---|
| 1 | BasicInfo | Core identity data: name, date of birth, gender |
| 2 | ContactInfo | Contact details: email, phone number, mailing address |
| 3 | AccountInfo | Account configuration: regulation, label, player status, level |
| 4 | RiskInfo | Risk profile: KYC answers, MiFID/ASIC classification, experience |
| 5 | User settings | UI preferences and notification settings |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntityTypeId | smallint | NO | - | CODE-BACKED | Primary key. Data category: 1=BasicInfo, 2=ContactInfo, 3=AccountInfo, 4=RiskInfo, 5=User settings. See [Sync Entity Types](_glossary.md#sync-entity-types). |
| 2 | Name | nvarchar(50) | NO | - | CODE-BACKED | Entity type label used in sync queue management and monitoring. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Sync queue tables | EntityTypeId | Lookup | Identifies which data category needs syncing |

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
| PK_SyncEntityTypes | CLUSTERED PK | EntityTypeId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all entity types
```sql
SELECT EntityTypeId, Name FROM Dictionary.SyncEntityTypes WITH (NOLOCK) ORDER BY EntityTypeId
```

### 8.2 Pending sync items by entity type
```sql
SELECT et.Name, COUNT(*) AS PendingCount
FROM Sync.SyncQueue sq WITH (NOLOCK)
JOIN Dictionary.SyncEntityTypes et WITH (NOLOCK) ON sq.EntityTypeId = et.EntityTypeId
JOIN Dictionary.SyncStatus ss WITH (NOLOCK) ON sq.StatusID = ss.StatusID
WHERE ss.Name = 'Pending' GROUP BY et.Name ORDER BY PendingCount DESC
```

### 8.3 Recent sync completions
```sql
SELECT et.Name, sq.CompletedDate FROM Sync.SyncQueue sq WITH (NOLOCK)
JOIN Dictionary.SyncEntityTypes et WITH (NOLOCK) ON sq.EntityTypeId = et.EntityTypeId
WHERE sq.StatusID = 2 ORDER BY sq.CompletedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.SyncEntityTypes | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.SyncEntityTypes.sql*
