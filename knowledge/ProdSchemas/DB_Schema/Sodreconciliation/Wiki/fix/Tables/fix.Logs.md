# fix.Logs

> Central audit log for all reconciliation fix operations performed through the SOD Reconciliation UI, capturing the user, method, payload, and notes for each correction.

| Property | Value |
|----------|-------|
| **Schema** | fix |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This is the central audit log for the reconciliation fix system. When operations staff use the SOD Reconciliation UI to correct discrepancies (position breaks or trade breaks), the correction details are logged here. Each row captures who made the fix, when, what API method was called, the JSON payload sent, and any notes explaining the reason.

Per Confluence: "In case of a discrepancy there is a possibility to change it in the UI. Updated data is sent to eToro Gateway API. Data is not updated in actual reconciliation DB tables - there are dedicated tables that display the changes." This table is the parent of those dedicated tracking tables.

**Usage pattern from live data**: This is a lightly-used feature. All observed fix operations use a single method ("AdjustOne") for individual position/trade adjustments, performed by a single operations user. Fixes are infrequent - a handful per month. Notes are typically just "ADJUST" or "Adjust" with no detailed justification, suggesting the reasoning is communicated outside the system (e.g., via Jira/Slack).

The four child tables (PositionApexLogs, PositionReconciliationLogs, TradeApexLogs, TradeReconciliationLogs) link each log entry to the specific Apex and reconciliation records that were involved in the fix.

---

## 2. Business Logic

No complex multi-column logic. Central audit record with child junction tables.

---

## 3. Data Overview

Sample fix operations (all by the same user using "AdjustOne" method):

| FixDate | User | Method | Note | Meaning |
|---|---|---|---|---|
| 2026-04-01 14:40 | kennethro@etoro.com | AdjustOne | ADJUST | Most recent fix - single position/trade adjustment. |
| 2026-03-25 12:41 | kennethro@etoro.com | AdjustOne | ADJUST | Batch of adjustments on this date. |
| 2026-03-06 15:02 | kennethro@etoro.com | AdjustOne | Adjust | Earlier adjustment round. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Referenced by all four child log tables. |
| 2 | FixDate | datetime2(7) | NO | getdate() | CODE-BACKED | When the fix operation was performed. Auto-set to current time. |
| 3 | User | varchar(256) | YES | - | CODE-BACKED | Username/identity of the person who performed the fix via the UI. |
| 4 | Json | varchar(2048) | YES | - | CODE-BACKED | JSON payload sent to the eToro Gateway API for the correction. Contains the fix details (account, quantity adjustment, etc.). |
| 5 | Method | varchar(128) | YES | - | CODE-BACKED | API method/endpoint called on the Gateway API (e.g., position update, trade correction). |
| 6 | Note | varchar(2048) | YES | - | CODE-BACKED | Free-text notes/justification entered by the user explaining why the fix was needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fix.PositionApexLogs | LogId | FK (CASCADE DELETE) | Links log to Apex position records involved |
| fix.PositionReconciliationLogs | LogId | FK (CASCADE DELETE) | Links log to position reconciliation records |
| fix.TradeApexLogs | LogId | FK (CASCADE DELETE) | Links log to Apex trade records involved |
| fix.TradeReconciliationLogs | LogId | FK (CASCADE DELETE) | Links log to trade reconciliation records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fix.PositionApexLogs | Table | FK from LogId (CASCADE) |
| fix.PositionReconciliationLogs | Table | FK from LogId (CASCADE) |
| fix.TradeApexLogs | Table | FK from LogId (CASCADE) |
| fix.TradeReconciliationLogs | Table | FK from LogId (CASCADE) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Logs | CLUSTERED PK | Id | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | newsequentialid() for Id |
| (default) | DEFAULT | getdate() for FixDate |

---

## 8. Sample Queries

### 8.1 View recent fix operations

```sql
SELECT Id, FixDate, [User], Method, Note
FROM fix.Logs WITH (NOLOCK)
ORDER BY FixDate DESC;
```

### 8.2 Find fixes by a specific user

```sql
SELECT FixDate, Method, Note, Json
FROM fix.Logs WITH (NOLOCK)
WHERE [User] = 'admin@etoro.com'
ORDER BY FixDate DESC;
```

### 8.3 Count fixes by method

```sql
SELECT Method, COUNT(*) AS FixCount
FROM fix.Logs WITH (NOLOCK)
GROUP BY Method
ORDER BY FixCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | UI corrections sent to Gateway API; dedicated fix tables track changes (fix.PositionReconciliationLogs, fix.PositionApexLogs, fix.TradeReconciliationLogs, fix.TradeApexLogs, fix.Logs) |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fix.Logs | Type: Table | Source: Sodreconciliation/Sodreconciliation/fix/Tables/fix.Logs.sql*
