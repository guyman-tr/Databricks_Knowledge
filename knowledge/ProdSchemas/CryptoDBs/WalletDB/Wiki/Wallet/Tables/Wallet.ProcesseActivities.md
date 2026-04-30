# Wallet.ProcesseActivities

> Activity heartbeat log for background processes, recording each time a registered process reports its last activity for health monitoring and dead process detection.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores heartbeat records for each background process registered in `Wallet.Processes`. Every time a process reports activity via `Wallet.SetProcessLastActivity`, a new row is appended here. With ~1.21M rows, it provides a detailed history of process health over time. The most frequent reporter is ProcessId=1 (UpdateWalletBalances), which logs activity every ~1-3 minutes.

Without this table, operations could not monitor whether background processes are running, detect stuck processes, or audit historical process activity patterns.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple append-only heartbeat log.

---

## 3. Data Overview

| Id | ProcessId | Occurred | Meaning |
|---|---|---|---|
| 1214131 | 1 (UpdateWalletBalances) | 2026-04-14 16:44 | Balance update process heartbeat - running normally with ~1 min intervals |
| 1214130 | 1 (UpdateWalletBalances) | 2026-04-14 16:43 | Previous heartbeat from the same process |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | ProcessId | int | NO | - | VERIFIED | The background process reporting activity. FK to Wallet.Processes.Id. Values: 1=UpdateWalletBalances, 2=HandlePendingRedemptions, etc. |
| 3 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of the activity heartbeat. Used to calculate time since last activity for monitoring alerts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProcessId | Wallet.Processes | FK | Links to the registered process |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SetProcessLastActivity | - | Writer | Appends heartbeat records |
| Wallet.GetProcessLastActivity | - | Reader | Reads latest heartbeat for a process |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ProcesseActivities (table)
└── Wallet.Processes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Processes | Table | FK target for ProcessId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SetProcessLastActivity | Stored Procedure | Appends activity records |
| Wallet.GetProcessLastActivity | Stored Procedure | Reads latest activity |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProcesseActivities | CLUSTERED PK | Id ASC | - | - | Active |
| IX_ProcesseActivities_Occurred | NC | Occurred | - | - | Active |
| IX_ProcesseActivities_ProcessId_inc | NC | ProcessId | Occurred | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ProcesseActivities_Occurred | DEFAULT | getutcdate() |
| FK_...ProcessId__Processes_Id | FK | ProcessId -> Wallet.Processes.Id |

---

## 8. Sample Queries

### 8.1 Latest activity for each process
```sql
SELECT p.Name, MAX(pa.Occurred) AS LastActivity,
    DATEDIFF(MINUTE, MAX(pa.Occurred), GETUTCDATE()) AS MinutesSinceActivity
FROM Wallet.ProcesseActivities pa WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON pa.ProcessId = p.Id
GROUP BY p.Name
ORDER BY LastActivity DESC
```

### 8.2 Activity frequency for a process
```sql
SELECT TOP 20 Occurred FROM Wallet.ProcesseActivities WITH (NOLOCK)
WHERE ProcessId = 1
ORDER BY Occurred DESC
```

### 8.3 Detect processes with no recent activity
```sql
SELECT p.Name, MAX(pa.Occurred) AS LastActivity
FROM Wallet.Processes p WITH (NOLOCK)
LEFT JOIN Wallet.ProcesseActivities pa WITH (NOLOCK) ON p.Id = pa.ProcessId
GROUP BY p.Name
HAVING MAX(pa.Occurred) < DATEADD(HOUR, -1, GETUTCDATE()) OR MAX(pa.Occurred) IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ProcesseActivities | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ProcesseActivities.sql*
