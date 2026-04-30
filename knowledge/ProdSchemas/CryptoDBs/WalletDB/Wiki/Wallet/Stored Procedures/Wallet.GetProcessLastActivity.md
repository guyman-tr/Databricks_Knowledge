# Wallet.GetProcessLastActivity

> Retrieves the most recent activity timestamp for a named background process, used for health monitoring and throttle checks.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns last activity timestamp for a process |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns when a named background process last reported activity. It is the read counterpart to `Wallet.SetProcessLastActivity` and is used by monitoring systems and other procedures to check whether a background process is still running or has stalled.

Without this procedure, the system could not detect stuck or crashed background processes. If the last activity timestamp for a process like "HandlePendingRedemptions" is more than N minutes old, the monitoring system can raise an alert or restart the process.

Data comes from `Wallet.Processes` (process registry) joined to `Wallet.ProcesseActivities` (activity log), returning only the most recent activity entry. The procedure uses NOLOCK hints for non-blocking reads.

---

## 2. Business Logic

### 2.1 Process Health Check Pattern

**What**: Returns the most recent activity timestamp for health monitoring and throttle decisions.

**Columns/Parameters Involved**: `@ProcessName`, `Processes.Name`, `ProcesseActivities.Occurred`

**Rules**:
- Looks up the process by name in Wallet.Processes
- Returns TOP 1 activity record ordered by Occurred DESC (most recent)
- If the process has no activity records, returns empty result set
- Common usage: compare returned Occurred against GETUTCDATE() to determine if the process is active

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessName | varchar(100) | NO | - | CODE-BACKED | Name of the background process to check. Must match a Name value in Wallet.Processes (e.g., 'HandlePendingRedemptions', 'ExecuterSendTransaction', 'HandleUserManualOutTransactions'). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent activity reported by the named process. Used for health monitoring - stale timestamps indicate a stuck or crashed process. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessName | Wallet.Processes | Lookup | Process registry - resolves name to ID |
| Occurred | Wallet.ProcesseActivities | JOIN | Activity log - provides timestamp data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Monitoring systems) | - | External | Called to check process health |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetProcessLastActivity (procedure)
├── Wallet.Processes (table)
└── Wallet.ProcesseActivities (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Processes | Table | Lookup process ID by name |
| Wallet.ProcesseActivities | Table | Read latest activity timestamp |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SQL dependents found) | - | Called from monitoring/application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hints | Read isolation | Both tables read with NOLOCK for non-blocking monitoring queries |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Check when HandlePendingRedemptions last ran
```sql
EXEC Wallet.GetProcessLastActivity @ProcessName = 'HandlePendingRedemptions';
```

### 8.2 Check all processes and their last activity
```sql
SELECT p.Name, pa.Occurred,
    DATEDIFF(MINUTE, pa.Occurred, GETUTCDATE()) AS MinutesAgo
FROM Wallet.Processes p WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 pa.Occurred
        FROM Wallet.ProcesseActivities pa WITH (NOLOCK)
        WHERE pa.ProcessId = p.Id
        ORDER BY pa.Occurred DESC
    ) pa
ORDER BY pa.Occurred ASC;
```

### 8.3 Find processes that have not reported activity in over 30 minutes
```sql
SELECT p.Name, pa.Occurred,
    DATEDIFF(MINUTE, pa.Occurred, GETUTCDATE()) AS MinutesSinceLastActivity
FROM Wallet.Processes p WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 pa.Occurred
        FROM Wallet.ProcesseActivities pa WITH (NOLOCK)
        WHERE pa.ProcessId = p.Id
        ORDER BY pa.Occurred DESC
    ) pa
WHERE DATEDIFF(MINUTE, pa.Occurred, GETUTCDATE()) > 30;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetProcessLastActivity | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetProcessLastActivity.sql*
