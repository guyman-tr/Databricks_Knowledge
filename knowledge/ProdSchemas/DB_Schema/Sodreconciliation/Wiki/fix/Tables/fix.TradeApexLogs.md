# fix.TradeApexLogs

> Junction table linking fix operations (fix.Logs) to the Apex trade records (apex.EXT872_TradeActivity) that were involved in each trade correction.

| Property | Value |
|----------|-------|
| **Schema** | fix |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 2 NC) |

---

## 1. Business Meaning

This junction table connects fix audit log entries to the specific Apex trade records that were part of a correction. When a user fixes a trade reconciliation break via the UI, the system records which Apex trade row (from EXT872_TradeActivity) was involved.

---

## 2. Business Logic

No complex logic. Junction table linking fix.Logs to apex.EXT872_TradeActivity.

---

## 3. Data Overview

N/A - junction/audit table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. |
| 2 | ApexTradeId | uniqueidentifier | NO | - | VERIFIED | FK to apex.EXT872_TradeActivity.Id. The Apex trade row involved in this fix. CASCADE DELETE. |
| 3 | LogId | uniqueidentifier | NO | - | VERIFIED | FK to fix.Logs.Id. The audit log entry. CASCADE DELETE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ApexTradeId | apex.EXT872_TradeActivity | FK (CASCADE DELETE) | Apex trade involved in fix |
| LogId | fix.Logs | FK (CASCADE DELETE) | Parent fix audit log |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fix.TradeApexLogs (table)
├── apex.EXT872_TradeActivity (table)
└── fix.Logs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.EXT872_TradeActivity | Table | FK from ApexTradeId (CASCADE) |
| fix.Logs | Table | FK from LogId (CASCADE) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeApexLogs | CLUSTERED PK | Id | - | - | Active |
| IX_TradeApexLogs_ApexTradeId | NC | ApexTradeId | - | - | Active |
| IX_TradeApexLogs_LogId | NC | LogId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TradeApexLogs_EXT872_TradeActivity_ApexTradeId | FOREIGN KEY | CASCADE DELETE |
| FK_TradeApexLogs_Logs_LogId | FOREIGN KEY | CASCADE DELETE |

---

## 8. Sample Queries

### 8.1 Find Apex trades involved in fixes

```sql
SELECT l.FixDate, l.[User], l.Method, tal.ApexTradeId
FROM fix.TradeApexLogs tal WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON tal.LogId = l.Id
ORDER BY l.FixDate DESC;
```

### 8.2 Join to trade details

```sql
SELECT l.FixDate, l.[User], t.AccountNumber, t.Symbol, t.Quantity, t.Price
FROM fix.TradeApexLogs tal WITH (NOLOCK)
JOIN fix.Logs l WITH (NOLOCK) ON tal.LogId = l.Id
JOIN apex.EXT872_TradeActivity t WITH (NOLOCK) ON tal.ApexTradeId = t.Id
ORDER BY l.FixDate DESC;
```

### 8.3 Count trade fixes

```sql
SELECT COUNT(*) AS TotalTradeFixes FROM fix.TradeApexLogs WITH (NOLOCK);
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
*Object: fix.TradeApexLogs | Type: Table | Source: Sodreconciliation/Sodreconciliation/fix/Tables/fix.TradeApexLogs.sql*
