# dbo.FiatCardStatuses_backup31_03_2025

> Backup table storing a snapshot of dbo.FiatCardStatuses from 2025-03-31, created for data recovery before a migration or schema change.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap with IDENTITY column) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

FiatCardStatuses_backup31_03_2025 is a dated backup of the dbo.FiatCardStatuses table taken on 2025-03-31. It preserves card status records before a migration operation, likely the addition or backfill of the CardInstanceId column (matching the purpose of the Bck_FiatStatusesCardInstance backup tables).

This is a static backup table. No procedures reference it in normal operations. It was created as a one-time data safety measure and is retained for historical reference and potential rollback needs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a flat backup snapshot of dbo.FiatCardStatuses.

---

## 3. Data Overview

N/A - backup table, data is a point-in-time snapshot from 2025-03-31.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Original PK from dbo.FiatCardStatuses. |
| 2 | CardId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCards.Id at time of backup. Identifies which card this status record belongs to. |
| 3 | CardStatusId | int | NO | - | CODE-BACKED | Status value at time of backup. Maps to Dictionary.CardStatuses: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. See [Card Status](../../_glossary.md#card-status). |
| 4 | ExpirationDate | datetime2(7) | NO | - | CODE-BACKED | Card expiration date at time of backup. |
| 5 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the status change event occurred in the source system. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | When this status record was created in the database. |
| 7 | CardInstanceId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCardInstances.Id at time of backup. Links the card status to a specific physical/virtual card instance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardId | dbo.FiatCards | Implicit | Backed-up card reference |
| CardStatusId | Dictionary.CardStatuses | Implicit | Card status value at time of backup |
| CardInstanceId | dbo.FiatCardInstances | Implicit | Backed-up card instance reference |

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

No indexes (heap table - no PK constraint despite IDENTITY column).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check backup row count
```sql
SELECT COUNT(*) AS BackupRowCount FROM dbo.FiatCardStatuses_backup31_03_2025 WITH (NOLOCK);
```

### 8.2 Compare backup with current card statuses
```sql
SELECT b.Id, b.CardId, b.CardStatusId, b.CardInstanceId,
       c.CardStatusId AS Current_StatusId, c.CardInstanceId AS Current_InstanceId
FROM dbo.FiatCardStatuses_backup31_03_2025 b WITH (NOLOCK)
JOIN dbo.FiatCardStatuses c WITH (NOLOCK) ON c.Id = b.Id;
```

### 8.3 Find status distribution in backup
```sql
SELECT CardStatusId, COUNT(*) AS RecordCount
FROM dbo.FiatCardStatuses_backup31_03_2025 WITH (NOLOCK)
GROUP BY CardStatusId ORDER BY CardStatusId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatCardStatuses_backup31_03_2025 | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatCardStatuses_backup31_03_2025.sql*
