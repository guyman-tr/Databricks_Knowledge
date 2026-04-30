# dbo.Bck_FiatStatusesCardInstance2025_05_28

> Dated backup table storing a snapshot of card status-to-card instance mapping data from 2025-05-28, used for data recovery and migration verification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap table) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

Bck_FiatStatusesCardInstance2025_05_28 is a dated backup table that stores a point-in-time snapshot from 2025-05-28 of the relationship between card statuses and card instances. It has the identical structure to dbo.Bck_FiatStatusesCardInstance and serves the same data recovery purpose, but is explicitly dated for auditability.

This table exists as a second backup snapshot taken during a specific migration or correction operation on 2025-05-28. Having a dated backup alongside the undated one suggests a multi-step migration where each step needed its own recovery point.

This is a static backup table - no procedures write to or read from it in normal operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a flat backup snapshot.

---

## 3. Data Overview

| Id | CardInstanceId | fcs_Id | CardId | fcs_CardId | Meaning |
|---|---|---|---|---|---|
| N/A | N/A | N/A | N/A | N/A | Snapshot rows from 2025-05-28 capturing card status-to-instance mapping |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | nvarchar(4000) | YES | - | NAME-INFERRED | Identifier from the source query, likely FiatCardInstances.Id stored as string for flexible export. |
| 2 | CardInstanceId | bigint | NO | - | CODE-BACKED | FK value pointing to dbo.FiatCardInstances.Id. The card instance associated with this card status record at the time of backup. |
| 3 | fcs_Id | bigint | NO | - | CODE-BACKED | The FiatCardStatuses.Id value at time of backup. Prefixed with "fcs_" to distinguish from the card instance Id. |
| 4 | CardId | nvarchar(4000) | YES | - | NAME-INFERRED | Card identifier from the source query, stored as string. |
| 5 | fcs_CardId | bigint | NO | - | CODE-BACKED | The FiatCardStatuses.CardId value at time of backup. FK to dbo.FiatCards.Id. |

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
SELECT COUNT(*) AS BackupRowCount FROM dbo.Bck_FiatStatusesCardInstance2025_05_28 WITH (NOLOCK);
```

### 8.2 Compare dated vs undated backup
```sql
SELECT COUNT(*) AS DatedCount FROM dbo.Bck_FiatStatusesCardInstance2025_05_28 WITH (NOLOCK);
SELECT COUNT(*) AS UndatedCount FROM dbo.Bck_FiatStatusesCardInstance WITH (NOLOCK);
```

### 8.3 Find records only in this dated backup
```sql
SELECT d.fcs_Id, d.CardInstanceId, d.fcs_CardId
FROM dbo.Bck_FiatStatusesCardInstance2025_05_28 d WITH (NOLOCK)
LEFT JOIN dbo.Bck_FiatStatusesCardInstance u WITH (NOLOCK) ON u.fcs_Id = d.fcs_Id
WHERE u.fcs_Id IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.2/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Bck_FiatStatusesCardInstance2025_05_28 | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.Bck_FiatStatusesCardInstance2025_05_28.sql*
