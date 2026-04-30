# Wallet.SetProcessLastActivity

> Records a heartbeat activity timestamp for a named background process by appending a new record to ProcesseActivities, enabling health monitoring and dead-process detection.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into ProcesseActivities by process name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a background process's heartbeat. Each registered process (in Wallet.Processes) periodically calls this to report it's still alive. The back-office API and balance service call this. The activity log in ProcesseActivities enables monitoring to detect processes that have stopped reporting - indicating a stuck or crashed service.

Counterpart to GetProcessLastActivity which reads the latest heartbeat.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Resolves ProcessId from Processes.Name, then INSERTs into ProcesseActivities with the specified Occurred timestamp.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessName | varchar(100) | NO | - | VERIFIED | Name of the background process reporting activity (e.g., 'HandlePendingRedemptions'). |
| 2 | @Occurred | datetime | NO | - | CODE-BACKED | Timestamp of the activity heartbeat. Typically GETUTCDATE() from the calling service. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessName | Wallet.Processes.Name | Lookup | Resolves ProcessId |
| - | Wallet.ProcesseActivities | INSERT | Heartbeat record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Process heartbeat |
| BalanceUser | - | EXECUTE | Process heartbeat |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SetProcessLastActivity (procedure)
+-- Wallet.Processes (table)
+-- Wallet.ProcesseActivities (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Processes | Table | Name-to-Id lookup |
| Wallet.ProcesseActivities | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, BalanceUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a heartbeat
```sql
EXEC Wallet.SetProcessLastActivity @ProcessName = 'HandlePendingRedemptions', @Occurred = '2026-04-15 12:00:00';
```

### 8.2 Check last activity
```sql
EXEC Wallet.GetProcessLastActivity @ProcessName = 'HandlePendingRedemptions';
```

### 8.3 Direct equivalent
```sql
INSERT INTO Wallet.ProcesseActivities(ProcessId, Occurred) SELECT Id, GETUTCDATE() FROM Wallet.Processes WHERE Name = 'HandlePendingRedemptions';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SetProcessLastActivity | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.SetProcessLastActivity.sql*
