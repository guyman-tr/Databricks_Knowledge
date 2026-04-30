# dbo.ReplCheck_RiskClassification_etoro

> Replication health-check sentinel table used to verify that SQL Server transactional replication from the etoro source database to the RiskClassification database is functioning correctly.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table serves as a replication health-check sentinel for the SQL Server transactional replication link from the etoro source database to the RiskClassification database. It contains a single row that is periodically updated to verify that replication is active and functioning.

Without this table, the operations team would have no simple way to verify that replication between the etoro source and RiskClassification databases is current. If the `LastUpdated` timestamp falls behind, it signals a replication lag or failure that could cause the RiskClassification system to operate on stale data.

The single row (ID=1) is updated on the source (etoro) database by a monitoring job. The update flows through transactional replication to this table. The three auto-generated replication stored procedures (`sp_MSins_`, `sp_MSupd_`, `sp_MSdel_`) are the replication agent's mechanism for applying changes from the publication to this subscriber table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple sentinel with one row. The business logic resides in the monitoring process that compares `LastUpdated` against the current time to detect replication lag.

---

## 3. Data Overview

| ID | LastUpdated | Meaning |
|----|------------|---------|
| 1 | 2024-04-07 07:55:00 | The single sentinel row. LastUpdated reflects the most recent successful replication heartbeat from the etoro source database. If this timestamp is stale (significantly behind current time), replication is lagging or broken. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | CODE-BACKED | Sentinel row identifier. Always 1 in practice - the table holds exactly one row used as a replication heartbeat marker. PK with FILLFACTOR 95. |
| 2 | LastUpdated | DATETIME | NO | - | CODE-BACKED | Timestamp of the most recent replication heartbeat from the etoro source database. Updated periodically by a monitoring job on the source side. Comparing this value to the current time reveals replication lag. A stale value indicates replication failure or delay. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.sp_MSdel_dboReplCheck_RiskClassification_etoro | @pkc1 (ID) | Replication DELETE | Auto-generated replication procedure that deletes rows by PK when the source row is deleted |
| dbo.sp_MSins_dboReplCheck_RiskClassification_etoro | @c1 (ID), @c2 (LastUpdated) | Replication INSERT | Auto-generated replication procedure that inserts rows when new rows appear on the source |
| dbo.sp_MSupd_dboReplCheck_RiskClassification_etoro | @c1 (ID), @c2 (LastUpdated), @pkc1 (ID) | Replication UPDATE | Auto-generated replication procedure that applies column-level updates using bitmap-based change detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.sp_MSdel_dboReplCheck_RiskClassification_etoro | Stored Procedure | Replication DELETE agent |
| dbo.sp_MSins_dboReplCheck_RiskClassification_etoro | Stored Procedure | Replication INSERT agent |
| dbo.sp_MSupd_dboReplCheck_RiskClassification_etoro | Stored Procedure | Replication UPDATE agent |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReplCheck_RiskClassification_etoro | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Check current replication status
```sql
SELECT ID, LastUpdated, DATEDIFF(MINUTE, LastUpdated, GETUTCDATE()) AS MinutesBehind
FROM dbo.ReplCheck_RiskClassification_etoro WITH (NOLOCK)
```

### 8.2 Alert if replication is lagging more than 30 minutes
```sql
SELECT *
FROM dbo.ReplCheck_RiskClassification_etoro WITH (NOLOCK)
WHERE DATEDIFF(MINUTE, LastUpdated, GETUTCDATE()) > 30
```

### 8.3 Historical replication check (compare with other ReplCheck tables if they exist)
```sql
SELECT 'RiskClassification_etoro' AS ReplicationLink, LastUpdated
FROM dbo.ReplCheck_RiskClassification_etoro WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ReplCheck_RiskClassification_etoro | Type: Table | Source: RiskClassification/dbo/Tables/dbo.ReplCheck_RiskClassification_etoro.sql*
