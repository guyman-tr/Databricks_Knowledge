# dbo.Bck_FiatStatusesCardInstance

> Backup table storing a snapshot of card status-to-card instance mapping data, used for data recovery and migration verification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap table) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

Bck_FiatStatusesCardInstance is a backup table that stores a point-in-time snapshot of the relationship between card statuses (from dbo.FiatCardStatuses) and card instances (from dbo.FiatCardInstances). It captures the Id and CardId from both tables to allow reconciliation and recovery after data migrations or corrections.

This table exists as a safety net for data migration operations. When the CardInstanceId column was added or backfilled on dbo.FiatCardStatuses, this backup preserved the pre-migration state so that any issues could be identified and rolled back. Without this backup, incorrect card-to-instance mappings would be irrecoverable.

This is a static backup table - no procedures write to or read from it in normal operations. It was created as a one-time operation and is retained for historical reference.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a flat backup snapshot.

---

## 3. Data Overview

| Id | CardInstanceId | fcs_Id | CardId | fcs_CardId | Meaning |
|---|---|---|---|---|---|
| N/A - backup data | N/A | N/A | N/A | N/A | Snapshot rows capturing the card status-to-instance mapping before a migration |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | nvarchar(4000) | YES | - | NAME-INFERRED | Identifier from the source query, likely the FiatCardInstances.Id stored as string for flexible export. |
| 2 | CardInstanceId | bigint | NO | - | CODE-BACKED | FK value pointing to dbo.FiatCardInstances.Id. The card instance associated with this card status record. |
| 3 | fcs_Id | bigint | NO | - | CODE-BACKED | The FiatCardStatuses.Id value. Prefixed with "fcs_" to distinguish from the card instance Id column. |
| 4 | CardId | nvarchar(4000) | YES | - | NAME-INFERRED | Card identifier from the source query, likely FiatCardInstances card reference stored as string. |
| 5 | fcs_CardId | bigint | NO | - | CODE-BACKED | The FiatCardStatuses.CardId value. FK to dbo.FiatCards.Id. Prefixed with "fcs_" to distinguish from other CardId columns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardInstanceId | dbo.FiatCardInstances | Implicit | Backed-up card instance reference |
| fcs_Id | dbo.FiatCardStatuses | Implicit | Backed-up card status record identifier |
| fcs_CardId | dbo.FiatCards | Implicit | Backed-up card reference from card statuses |

### 5.2 Referenced By (other objects point to this)

No objects reference this backup table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table).

### 7.2 Constraints

None (no PK, no FKs, no check constraints).

---

## 8. Sample Queries

### 8.1 Check backup row count
```sql
SELECT COUNT(*) AS BackupRowCount FROM dbo.Bck_FiatStatusesCardInstance WITH (NOLOCK);
```

### 8.2 Verify card instance mapping consistency
```sql
SELECT b.fcs_Id, b.CardInstanceId, b.fcs_CardId
FROM dbo.Bck_FiatStatusesCardInstance b WITH (NOLOCK)
WHERE b.CardInstanceId NOT IN (SELECT Id FROM dbo.FiatCardInstances WITH (NOLOCK));
```

### 8.3 Compare backup with current card statuses
```sql
SELECT b.fcs_Id, b.fcs_CardId, b.CardInstanceId,
       fcs.CardId AS Current_CardId, fcs.CardInstanceId AS Current_CardInstanceId
FROM dbo.Bck_FiatStatusesCardInstance b WITH (NOLOCK)
JOIN dbo.FiatCardStatuses fcs WITH (NOLOCK) ON fcs.Id = b.fcs_Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.2/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Bck_FiatStatusesCardInstance | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.Bck_FiatStatusesCardInstance.sql*
