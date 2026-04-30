# Trade.UpdateRolloverFeeThreshold

> Simple batch update of the rollover fee alert threshold per instrument type in Trade.RolloverFeeAlertThreshold, joined on InstrumentTypeID; used by fee management tooling to adjust the threshold at which RolloverFeesAlertIfNeeded triggers downstream notifications.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateRolloverFeeThresholdTbl.InstrumentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RolloverFeeAlertThreshold stores per-instrument-type threshold values that control when Trade.RolloverFeesAlertIfNeeded sends fee change alerts to operations teams. When rollover fees are updated, if the change exceeds the threshold, an alert is triggered. This procedure allows adjusting those thresholds by instrument type.

For example, if stock instruments (InstrumentTypeID = 1) have a threshold of 0.001 (0.1%), any fee update larger than 0.1% will trigger an alert. If the threshold is raised to 0.005, smaller changes won't generate alert noise.

The procedure is a minimal set-based UPDATE with no transaction, no audit trail beyond UpdatedByUser, and no return value. No internal callers found.

---

## 2. Business Logic

### 2.1 Threshold Update by InstrumentTypeID

**What**: Sets RolloverFeeThreshold and UpdatedByUser for each InstrumentTypeID provided in the TVP.

**Columns/Parameters Involved**: `InstrumentTypeID`, `RolloverFeeThreshold`, `UpdatedByUser`

**Rules**:
- JOIN: `IR.InstrumentTypeID = UIR.InstrumentTypeID`
- No INSERT: rows must already exist in Trade.RolloverFeeAlertThreshold
- Auto-commit (no explicit transaction)
- No change detection: always updates even if value is unchanged

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateRolloverFeeThresholdTbl | Trade.UpdateRolloverFeeThresholdTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of threshold updates. InstrumentTypeID (int NOT NULL) is the join key to Trade.RolloverFeeAlertThreshold. RolloverFeeThreshold (decimal(16,8) NOT NULL) is the new threshold value. Rows with InstrumentTypeIDs not in Trade.RolloverFeeAlertThreshold are silently skipped. |
| 2 | @UserName | nvarchar(50) | NO | - | CODE-BACKED | Username written to Trade.RolloverFeeAlertThreshold.UpdatedByUser for audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Trade.RolloverFeeAlertThreshold | UPDATE | Sets RolloverFeeThreshold and UpdatedByUser for matching instrument types |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External fee configuration tooling | Application call | Caller | No internal SP callers found; called from rollover fee management system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateRolloverFeeThreshold (procedure)
+-- Trade.RolloverFeeAlertThreshold (table) [UPDATE - RolloverFeeThreshold per InstrumentTypeID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloverFeeAlertThreshold | Table | UPDATEd: RolloverFeeThreshold and UpdatedByUser |
| Trade.UpdateRolloverFeeThresholdTbl | User Defined Type | TVP type for @UpdateRolloverFeeThresholdTbl |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee management tooling | Application | Adjusts per-instrument-type alert thresholds for rollover fee change notifications |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No INSERT | Design | UPDATE only; InstrumentTypeIDs not in RolloverFeeAlertThreshold are silently ignored |
| No transaction | Design | Auto-commit; no explicit BEGIN TRAN |
| No change detection | Design | Always updates even if new threshold equals current threshold |
| SET ANSI_NULLS ON | Session | Standard null comparison behavior |

---

## 8. Sample Queries

### 8.1 Update alert threshold for stock instruments

```sql
DECLARE @Thresholds [Trade].[UpdateRolloverFeeThresholdTbl]
INSERT INTO @Thresholds (InstrumentTypeID, RolloverFeeThreshold)
VALUES (1, 0.00500000)  -- Raise threshold for InstrumentTypeID=1

EXEC Trade.UpdateRolloverFeeThreshold
    @UpdateRolloverFeeThresholdTbl = @Thresholds,
    @UserName = 'fee_admin'
```

### 8.2 Batch update thresholds for multiple instrument types

```sql
DECLARE @Thresholds [Trade].[UpdateRolloverFeeThresholdTbl]
INSERT INTO @Thresholds (InstrumentTypeID, RolloverFeeThreshold)
VALUES
    (1, 0.00500000),   -- Stocks
    (5, 0.01000000),   -- Crypto
    (6, 0.00200000)    -- Commodities

EXEC Trade.UpdateRolloverFeeThreshold
    @UpdateRolloverFeeThresholdTbl = @Thresholds,
    @UserName = 'fee_admin'
```

### 8.3 Check current thresholds

```sql
SELECT
    rft.InstrumentTypeID,
    rft.RolloverFeeThreshold,
    rft.UpdatedByUser
FROM Trade.RolloverFeeAlertThreshold rft WITH (NOLOCK)
ORDER BY rft.InstrumentTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateRolloverFeeThreshold | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateRolloverFeeThreshold.sql*
