# fix.PositionReconciliationLogs

> Junction table linking fix operations (fix.Logs) to the position reconciliation records (recon.PositionReconciliation) that were corrected.

| Property | Value |
|----------|-------|
| **Schema** | fix |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 2 NC) |

---

## 1. Business Meaning

This junction table connects fix audit log entries to the specific position reconciliation break records that were corrected. When a user resolves a position break via the UI, the system records which reconciliation row was fixed.

---

## 2. Business Logic

No complex logic. Junction table linking fix.Logs to recon.PositionReconciliation.

---

## 3. Data Overview

N/A - junction/audit table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. |
| 2 | PositionReconciliationId | uniqueidentifier | NO | - | VERIFIED | FK to recon.PositionReconciliation.Id. The reconciliation break being fixed. CASCADE DELETE. |
| 3 | LogId | uniqueidentifier | NO | - | VERIFIED | FK to fix.Logs.Id. The audit log entry. CASCADE DELETE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionReconciliationId | recon.PositionReconciliation | FK (CASCADE DELETE) | The position break being fixed |
| LogId | fix.Logs | FK (CASCADE DELETE) | Parent fix audit log |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fix.PositionReconciliationLogs (table)
├── recon.PositionReconciliation (table)
└── fix.Logs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| recon.PositionReconciliation | Table | FK from PositionReconciliationId (CASCADE) |
| fix.Logs | Table | FK from LogId (CASCADE) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionReconciliationLogs | CLUSTERED PK | Id | - | - | Active |
| IX_PositionReconciliationLogs_PositionReconciliationId | NC | PositionReconciliationId | - | - | Active |
| IX_PositionReconciliationLogs_LogId | NC | LogId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PositionReconciliationLogs_PositionReconciliation_PositionReconciliationId | FOREIGN KEY | CASCADE DELETE |
| FK_PositionReconciliationLogs_Logs_LogId | FOREIGN KEY | CASCADE DELETE |

---

## 8. Sample Queries

### 8.1 Find fixes for position breaks

```sql
SELECT l.FixDate, l.[User], l.Note, prl.PositionReconciliationId
FROM fix.PositionReconciliationLogs prl WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON prl.LogId = l.Id
ORDER BY l.FixDate DESC;
```

### 8.2 Join to break details

```sql
SELECT l.FixDate, l.[User], pr.AccountNumber, pr.Symbol, pr.BreakValue
FROM fix.PositionReconciliationLogs prl WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON prl.LogId = l.Id
JOIN recon.PositionReconciliation pr WITH (NOLOCK) ON prl.PositionReconciliationId = pr.Id
ORDER BY l.FixDate DESC;
```

### 8.3 Count position fixes per user

```sql
SELECT l.[User], COUNT(*) AS FixCount
FROM fix.PositionReconciliationLogs prl WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON prl.LogId = l.Id
GROUP BY l.[User];
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Fix tables track UI corrections |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fix.PositionReconciliationLogs | Type: Table | Source: Sodreconciliation/Sodreconciliation/fix/Tables/fix.PositionReconciliationLogs.sql*
