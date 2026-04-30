# History.ConfigurationLogs

> Temporal HISTORY_TABLE for CEP.ConfigurationLogs - stores 37 versioned snapshots of CEP configuration change audit events; data originates from staging (stg-hdge-we01).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for CEP.ConfigurationLogs |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.ConfigurationLogs is the SQL Server temporal HISTORY_TABLE for CEP.ConfigurationLogs. It stores prior row versions when CEP configuration change log entries are modified or deleted.

CEP.ConfigurationLogs is an audit table recording configuration changes made by operators to the CEP/hedge system, with ChangedBy (operator username), ChangeTimeStamp, and HostName. It tracks "who changed what, when, from which server."

37 rows, all originating from hostname "stg-hdge-we01" (staging hedge server). This suggests this History table tracks configuration changes made in a staging environment. The most recent entry is from September 2025 (dotanva) and July 2025 (rivkaya).

All archived rows have SysStartTime = SysEndTime (identical timestamps), indicating the base table rows were inserted and immediately deleted (zero dwell time), or were subject to rapid successive modifications. This pattern suggests CEP.ConfigurationLogs entries are processed and removed quickly.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: Every change (UPDATE or DELETE) to a row in CEP.ConfigurationLogs writes the prior version here.

**Rules**:
- Never written to directly
- 37 rows = 37 configuration log entries have been versioned out
- SysStartTime = SysEndTime for all rows: rows in the base table had zero or sub-millisecond dwell time before deletion/update
- ChangedBy values are operator usernames (dotanva, rivkaya, moshezo) - human-initiated changes from the staging hedge server

### 2.2 Audit Trail for Configuration Changes

**What**: Provides a complete audit trail of CEP system configuration changes even after entries are removed from the base CEP.ConfigurationLogs table.

**Operators observed**: dotanva, rivkaya, moshezo (staging environment operators)
**HostName**: stg-hdge-we01 (staging hedge server)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 37 |
| **Last Change** | 2025-09-14 (LogID=37, ChangedBy=dotanva) |
| **Environment** | Staging (stg-hdge-we01) |

Sample:

| LogID | ChangedBy | ChangeTimeStamp | HostName | SysStartTime | SysEndTime |
|-------|----------|----------------|----------|-------------|------------|
| 37 | dotanva | 2025-09-14 09:02 | stg-hdge-we01 | 2025-09-14 09:02 | 2025-09-14 09:02 |
| 36 | rivkaya | 2025-07-09 08:30 | stg-hdge-we01 | 2025-07-09 08:30 | 2025-07-09 08:30 |
| 35 | moshezo | 2024-12-19 10:05 | stg-hdge-we01 | 2024-12-19 10:05 | 2024-12-19 10:05 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogID | int | NO | - | VERIFIED | Sequential log entry ID. Auto-incremented in CEP.ConfigurationLogs. |
| 2 | ChangedBy | varchar(50) | NO | - | VERIFIED | Username of the operator who made the configuration change. E.g., "dotanva", "rivkaya", "moshezo". |
| 3 | ChangeTimeStamp | datetime | NO | - | VERIFIED | Wall-clock time when the configuration change was made. Set by the application layer (different from SysStartTime which is SQL Server temporal). |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login at time of change. Audit column. |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info(). Audit column. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | When this version became current in CEP.ConfigurationLogs. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded (= SysStartTime for all current rows, indicating immediate deletion). |
| 8 | HostName | nvarchar(128) | YES | - | VERIFIED | Server hostname that performed the change. All observed: "stg-hdge-we01" (staging hedge server). |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | CEP.ConfigurationLogs | HISTORY_TABLE (temporal) | Auto-managed history table for CEP.ConfigurationLogs. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_ConfigurationLogs | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

## 8. Sample Queries

```sql
-- All CEP configuration changes (current + history)
SELECT LogID, ChangedBy, ChangeTimeStamp, HostName, SysStartTime, SysEndTime
FROM CEP.ConfigurationLogs
FOR SYSTEM_TIME ALL
ORDER BY ChangeTimeStamp DESC;
```

---

*Generated: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.ConfigurationLogs | Type: Table | Source: etoro/etoro/History/Tables/History.ConfigurationLogs.sql*
