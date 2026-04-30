# Trade.AlertSplitPositionEndedWithError

> Sends an email alert listing positions that failed during a stock split operation, identified by SplitID. Called by the split execution pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is called after a stock split operation to alert the team about positions that failed to split correctly. Stock splits (e.g., a 4:1 split) require updating position units and rates for every affected position. If any position fails during this process, the error is logged in `History.PositionSplitError` and this procedure emails a summary.

Without this alert, split failures would go unnoticed, leaving customers with incorrect position sizes or rates that don't reflect the corporate action. These errors require manual intervention.

The procedure reads all errors for the given SplitID from `History.PositionSplitError`, formats them as an HTML table (PositionID, SplitID, InsertDate, ErrorMessage), and emails to the address configured in `Maintenance.Feature` (FeatureID=116). It uses the default database mail profile.

---

## 2. Business Logic

### 2.1 Split Error Notification

**What**: Reports all positions that failed during a specific stock split execution.

**Rules**:
- Reads from History.PositionSplitError WHERE SplitID = @SplitID with OPTION(RECOMPILE)
- Email is only sent if the HTML content differs from an empty-table template (non-empty check)
- Email recipient comes from Maintenance.Feature FeatureID=116
- Uses the default mail profile from msdb.dbo.sysmail_profile

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | Identifies which stock split operation to report on. Maps to History.PositionSplitError.SplitID. Passed by the SplitOpenPositions orchestrator after split execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.PositionSplitError | READER | Split error log for the given SplitID |
| SELECT | Maintenance.Feature | READER | Email address (FeatureID=116) |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitOpenPositions (or similar) | - | Caller | Called after split execution to report failures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertSplitPositionEndedWithError (procedure)
+-- History.PositionSplitError (table)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSplitError | Table | READER - split error records |
| Maintenance.Feature | Table | READER - email configuration |

### 6.2 Objects That Depend On This

Called by stock split orchestration procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check recent split errors

```sql
SELECT  SplitID, PositionID, InsertDate, ErrorMessage
FROM    History.PositionSplitError WITH (NOLOCK)
ORDER BY InsertDate DESC;
```

### 8.2 Run the alert for a specific split

```sql
EXEC Trade.AlertSplitPositionEndedWithError @SplitID = 42;
```

### 8.3 Find which split IDs had errors

```sql
SELECT  SplitID, COUNT(*) AS ErrorCount, MIN(InsertDate) AS FirstError, MAX(InsertDate) AS LastError
FROM    History.PositionSplitError WITH (NOLOCK)
GROUP BY SplitID
ORDER BY SplitID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertSplitPositionEndedWithError | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertSplitPositionEndedWithError.sql*
