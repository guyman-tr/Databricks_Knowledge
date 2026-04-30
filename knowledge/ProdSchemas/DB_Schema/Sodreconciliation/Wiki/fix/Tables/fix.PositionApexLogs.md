# fix.PositionApexLogs

> Junction table linking fix operations (fix.Logs) to the Apex position records (apex.EXT871_PositionActivity) that were involved in each position correction.

| Property | Value |
|----------|-------|
| **Schema** | fix |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 2 NC) |

---

## 1. Business Meaning

This junction table connects fix audit log entries to the specific Apex position records that were part of a correction. When a user fixes a position reconciliation break via the UI, the system records which Apex position row (from EXT871_PositionActivity) was involved alongside the fix log entry.

---

## 2. Business Logic

No complex logic. Junction table linking fix.Logs to apex.EXT871_PositionActivity.

---

## 3. Data Overview

N/A - junction/audit table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. |
| 2 | ApexPositionId | uniqueidentifier | NO | - | VERIFIED | FK to apex.EXT871_PositionActivity.Id. The Apex position row involved in this fix. CASCADE DELETE. |
| 3 | LogId | uniqueidentifier | NO | - | VERIFIED | FK to fix.Logs.Id. The audit log entry for this fix operation. CASCADE DELETE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ApexPositionId | apex.EXT871_PositionActivity | FK (CASCADE DELETE) | Apex position involved in fix |
| LogId | fix.Logs | FK (CASCADE DELETE) | Parent fix audit log entry |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fix.PositionApexLogs (table)
├── apex.EXT871_PositionActivity (table)
└── fix.Logs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.EXT871_PositionActivity | Table | FK from ApexPositionId (CASCADE) |
| fix.Logs | Table | FK from LogId (CASCADE) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionApexLogs | CLUSTERED PK | Id | - | - | Active |
| IX_PositionApexLogs_ApexPositionId | NC | ApexPositionId | - | - | Active |
| IX_PositionApexLogs_LogId | NC | LogId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PositionApexLogs_EXT871_PositionActivity_ApexPositionId | FOREIGN KEY | CASCADE DELETE |
| FK_PositionApexLogs_Logs_LogId | FOREIGN KEY | CASCADE DELETE |

---

## 8. Sample Queries

### 8.1 Find Apex positions involved in fixes

```sql
SELECT l.FixDate, l.[User], l.Method, pal.ApexPositionId
FROM fix.PositionApexLogs pal WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON pal.LogId = l.Id
ORDER BY l.FixDate DESC;
```

### 8.2 Count fixes per Apex position

```sql
SELECT ApexPositionId, COUNT(*) AS FixCount
FROM fix.PositionApexLogs WITH (NOLOCK)
GROUP BY ApexPositionId
HAVING COUNT(*) > 1;
```

### 8.3 Join to position details

```sql
SELECT l.FixDate, l.[User], p.AccountNumber, p.Symbol, p.TradeQuantity
FROM fix.PositionApexLogs pal WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON pal.LogId = l.Id
JOIN apex.EXT871_PositionActivity p WITH (NOLOCK) ON pal.ApexPositionId = p.Id
ORDER BY l.FixDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Fix tables track UI corrections to reconciliation data |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fix.PositionApexLogs | Type: Table | Source: Sodreconciliation/Sodreconciliation/fix/Tables/fix.PositionApexLogs.sql*
