# Trade.UpdateBslLastExecute

> Records a heartbeat timestamp in Maintenance.Feature to signal that the BSL (Balance Stop Loss) process last executed successfully; called by Trade.InsertBSLMessagesIntoQueue via the RW replication synonym.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - single-row update to Maintenance.Feature (FeatureID=125) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateBslLastExecute is a single-statement heartbeat procedure for the BSL (Balance Stop Loss) system. Every time the BSL process completes a cycle, this procedure stamps `Maintenance.Feature` row 125 ("Bsl Last Execute") with the current UTC timestamp. This timestamp serves as an operational health indicator - monitoring tools can query `Maintenance.Feature WHERE FeatureID = 125` to confirm the BSL is running on schedule and detect stalls or failures.

Without this heartbeat, operations teams would have no passive indicator of BSL liveness. A stale `Value` in FeatureID 125 (e.g., hours old) signals that the BSL job has stopped, which is a critical trading risk because the BSL is responsible for liquidating positions when customer balances fall below their stop-loss level.

The procedure is called by `Trade.InsertBSLMessagesIntoQueue` - the main BSL orchestrator. Because BSL operates across database servers, the call is routed through `dbo.RW_UpdateBslLastExecute`, which is a synonym pointing to `[AO-REAL-DB].[etoro].[Trade].[UpdateBslLastExecute]`. This is the standard eToro RW-synonym pattern: read replicas use `RW_` synonyms to route write operations back to the authoritative read-write database. All changes to `Maintenance.Feature` are versioned to `History.Feature` via trigger.

---

## 2. Business Logic

### 2.1 BSL Heartbeat via Feature Flag

**What**: Records the UTC timestamp of the most recent BSL process execution into the Maintenance.Feature configuration table as a monitoring heartbeat.

**Columns/Parameters Involved**: `Maintenance.Feature.Value` (FeatureID = 125)

**Rules**:
- Updates exactly one row: FeatureID = 125 ("Bsl Last Execute")
- Sets `Value = GETUTCDATE()` - UTC timestamp of the BSL cycle completion
- `Value` column is `sql_variant` type - stores the datetime2 as a variant value
- The Maintenance.FeatureUpdate trigger automatically versions the old value into History.Feature before the update, providing a complete change history of BSL execution times
- Called at two points in Trade.InsertBSLMessagesIntoQueue: once early (before the BSL data check) and once at the end of the TRY block - both serve as progress checkpoints

**Diagram**:
```
Trade.InsertBSLMessagesIntoQueue
  |
  +--> exec [dbo].[RW_UpdateBslLastExecute]
         |
         v (synonym)
       [AO-REAL-DB].[etoro].[Trade].[UpdateBslLastExecute]
         |
         v
       UPDATE Maintenance.Feature
       SET Value = GETUTCDATE()
       WHERE FeatureID = 125  -- "Bsl Last Execute"
         |
         v (trigger)
       History.Feature (versions previous timestamp)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no declared parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | Trade.UpdateBslLastExecute takes no input parameters. It performs a fixed UPDATE to Maintenance.Feature FeatureID=125, setting Value to the current UTC time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Maintenance.Feature | Modifier | Updates Value = GETUTCDATE() for FeatureID = 125 ("Bsl Last Execute") |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertBSLMessagesIntoQueue | EXEC call | Caller (via synonym) | The BSL orchestrator calls this via dbo.RW_UpdateBslLastExecute synonym at two checkpoints during its execution cycle |
| dbo.RW_UpdateBslLastExecute | Synonym target | Synonym | Routes to [AO-REAL-DB].[etoro].[Trade].[UpdateBslLastExecute] - enables read replicas to invoke this write operation on the main DB |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateBslLastExecute (procedure)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | UPDATE target - sets Value = GETUTCDATE() for FeatureID = 125 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertBSLMessagesIntoQueue | Stored Procedure | Calls this (via dbo.RW_UpdateBslLastExecute) as a BSL heartbeat at two points during execution |
| dbo.RW_UpdateBslLastExecute | Synonym | Synonym routing [AO-REAL-DB].[etoro].[Trade].[UpdateBslLastExecute] |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check the BSL heartbeat (last execution time)
```sql
SELECT FeatureID,
       CAST(Value AS DATETIME) AS BslLastExecute,
       DATEDIFF(MINUTE, CAST(Value AS DATETIME), GETUTCDATE()) AS MinutesSinceLastRun,
       Description
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID = 125;
```

### 8.2 Alert if BSL has not run in over 30 minutes
```sql
SELECT FeatureID,
       CAST(Value AS DATETIME) AS BslLastExecute,
       CASE WHEN DATEDIFF(MINUTE, CAST(Value AS DATETIME), GETUTCDATE()) > 30
            THEN 'STALE - BSL may have stopped'
            ELSE 'OK'
       END AS BslStatus
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID = 125;
```

### 8.3 View BSL execution history
```sql
SELECT FeatureID,
       CAST(Value AS DATETIME) AS BslExecuteTimestamp,
       ValidFrom,
       ValidTo
FROM   History.Feature WITH (NOLOCK)
WHERE  FeatureID = 125
ORDER  BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateBslLastExecute | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateBslLastExecute.sql*
