# Hedge.UpdateLastHedgeDiscrepencyAlertTime

> Updates the timestamp of the last hedge discrepancy alert in Maintenance.Feature (FeatureID=43), allowing the hedge monitoring system to track when it last sent a discrepancy notification and avoid duplicate alerts.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | FeatureID=43 (hardcoded, single-row update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.UpdateLastHedgeDiscrepencyAlertTime` records the timestamp of the most recent hedge discrepancy alert by writing to the `Maintenance.Feature` table. The `Maintenance.Feature` table acts as a key-value store for system feature flags and configuration values; FeatureID=43 specifically holds the timestamp of the last time the hedge monitoring system detected and reported a discrepancy between the expected and actual hedge positions.

This procedure exists to prevent duplicate alerts: before sending a new discrepancy alert, the hedge monitor reads the stored timestamp (via `Maintenance.Feature WHERE FeatureID = 43`) and compares it with the time of the current discrepancy. If the current discrepancy occurred after the stored timestamp, a new alert is sent and this procedure is called to advance the timestamp. If not, no new alert is sent.

Data flows as follows: the hedge monitoring component detects a position discrepancy, determines the max discrepancy time, calls this procedure with that time, and the stored "last alert" watermark is advanced. The procedure is a single-row UPDATE with no transaction wrapper.

Note: The procedure name contains a typo - "Discrepency" instead of "Discrepancy". This is preserved from the original DDL.

---

## 2. Business Logic

### 2.1 Watermark Update for Duplicate Alert Prevention

**What**: FeatureID=43 in Maintenance.Feature serves as a timestamp watermark to track when the hedge system last alerted on a discrepancy.

**Columns/Parameters Involved**: `@MaxTime`, `Maintenance.Feature.Value` (FeatureID=43)

**Rules**:
- `@MaxTime` is the timestamp of the most recent discrepancy event (the "max time" across all current discrepancies).
- The update sets `Value = @MaxTime` without any conditional logic - the caller is responsible for ensuring @MaxTime is newer than the current stored value.
- The feature row (FeatureID=43) must already exist in `Maintenance.Feature` for the UPDATE to take effect; if it does not exist, the UPDATE silently affects 0 rows.
- No return value - callers cannot tell from this SP whether the update succeeded; they should verify `@@ROWCOUNT` if needed.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxTime | DATETIME | NO | - | CODE-BACKED | The timestamp to record as the last hedge discrepancy alert time. Set to the maximum discrepancy timestamp found in the current monitoring cycle. Written to Maintenance.Feature.Value WHERE FeatureID = 43. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE target) | Maintenance.Feature | MODIFIER (cross-schema) | Updates Value column for the single row with FeatureID=43 (last hedge discrepancy alert time) |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by the hedge monitoring component.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.UpdateLastHedgeDiscrepencyAlertTime (procedure)
+-- Maintenance.Feature (table) [MODIFIER - cross-schema, FeatureID=43]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | Target of UPDATE - sets Value = @MaxTime for the row where FeatureID = 43 |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FeatureID = 43 (hardcoded) | Design | The procedure targets a specific feature row; no parameterization. If the row does not exist, the UPDATE silently updates 0 rows. |
| No transaction | Atomicity | Single-statement UPDATE; implicitly transactional. |
| Name typo | Documentation | "Discrepency" in the procedure name is a typo for "Discrepancy" - retained from original DDL. |

---

## 8. Sample Queries

### 8.1 Read the current last-alert timestamp
```sql
SELECT FeatureID, Value AS LastHedgeDiscrepancyAlertTime
FROM   [Maintenance].[Feature] WITH (NOLOCK)
WHERE  FeatureID = 43;
```

### 8.2 Update the timestamp to now
```sql
EXEC [Hedge].[UpdateLastHedgeDiscrepencyAlertTime]
    @MaxTime = '2026-03-19 08:30:00';
```

### 8.3 Simulate the alert-suppression pattern used by the hedge monitor
```sql
DECLARE @LastAlertTime DATETIME, @DiscrepancyMaxTime DATETIME;

SELECT @LastAlertTime = CAST(Value AS DATETIME)
FROM   [Maintenance].[Feature] WITH (NOLOCK)
WHERE  FeatureID = 43;

SET @DiscrepancyMaxTime = '2026-03-19 09:00:00'; -- computed by hedge monitor

IF @DiscrepancyMaxTime > ISNULL(@LastAlertTime, '1900-01-01')
BEGIN
    -- Send alert (external step), then record the time
    EXEC [Hedge].[UpdateLastHedgeDiscrepencyAlertTime] @MaxTime = @DiscrepancyMaxTime;
END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.UpdateLastHedgeDiscrepencyAlertTime | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.UpdateLastHedgeDiscrepencyAlertTime.sql*
