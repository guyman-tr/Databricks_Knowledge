# Trade.UpdateFeatureThresholdValues

> Upserts per-instrument feature threshold values in bulk using a TVP MERGE: updates Value when the (InstrumentID, FeatureID, ThresholdID) key exists, inserts a new row when it does not.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Values (TVP - Trade.FeatureThresholdValuesType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateFeatureThresholdValues is the single write path for the feature threshold configuration system. `Trade.FeatureThresholdValues` stores per-instrument numeric thresholds that gate feature behavior - for example, the minimum equity level below which a BSL (Balance Stop Loss) liquidation triggers, or the minimum position size for a specific feature to activate on a given instrument.

When configuration teams need to update these thresholds (e.g., recalibrating BSL thresholds for a batch of instruments after volatility changes), they pass the new values as a TVP and this procedure applies them atomically. The MERGE semantics handle two cases in one operation: existing (InstrumentID, FeatureID, ThresholdID) combinations get their Value updated; new combinations that have never been configured get a fresh row inserted. This makes the procedure suitable for both incremental updates and initial onboarding of new instruments into the threshold system.

No callers were found in the SSDT repo - this is invoked by external configuration services or admin tooling (e.g., the trading configuration API).

---

## 2. Business Logic

### 2.1 MERGE Upsert on Composite Key

**What**: The MERGE targets Trade.FeatureThresholdValues using a three-column composite key: (InstrumentID, FeatureID, ThresholdID). Matching rows get their Value updated; missing rows get inserted.

**Columns/Parameters Involved**: `@Values.InstrumentID`, `@Values.FeatureID`, `@Values.ThresholdID`, `@Values.Value`, `Trade.FeatureThresholdValues.*`

**Rules**:
- MERGE match condition: `source.InstrumentID = target.InstrumentID AND source.FeatureID = target.FeatureID AND source.ThresholdID = target.ThresholdID`
- WHEN MATCHED -> UPDATE: `target.Value = source.Value`
- WHEN NOT MATCHED BY TARGET -> INSERT: `(InstrumentID, FeatureID, ThresholdID, Value)` with source values
- No WHEN NOT MATCHED BY SOURCE clause: rows in FeatureThresholdValues that are not in the TVP are left unchanged (no deletes)
- This is a pure upsert - existing configuration for instruments not in the TVP is preserved

**Diagram**:
```
TVP (@Values):
  InstrumentID=1001, FeatureID=5, ThresholdID=1, Value=500.00
  InstrumentID=1002, FeatureID=5, ThresholdID=1, Value=750.00  <- new
                    |
                    v
  MERGE Trade.FeatureThresholdValues ON (InstrumentID, FeatureID, ThresholdID)
    MATCHED     -> UPDATE Value=500.00
    NOT MATCHED -> INSERT row for 1002/5/1
  All other rows in FeatureThresholdValues: untouched
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Values | Trade.FeatureThresholdValuesType READONLY | NO | - | CODE-BACKED | TVP containing the batch of threshold values to upsert. Each row: InstrumentID (FK to Trade.Instrument), FeatureID (FK to Trade.ActiveFeatureThreshold), ThresholdID (FK to Trade.ActiveFeatureThreshold), Value (decimal(20,2) - the numeric threshold amount). Rows matching an existing (InstrumentID, FeatureID, ThresholdID) key update Value; rows not matching insert a new record. See Trade.FeatureThresholdValuesType for full column details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Values | Trade.FeatureThresholdValuesType | TVP | Input parameter type defining the batch structure (InstrumentID, FeatureID, ThresholdID, Value) |
| MERGE target | Trade.FeatureThresholdValues | Modifier | Upserts Value for matched (InstrumentID, FeatureID, ThresholdID) keys; inserts new rows when not matched |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Invoked by external configuration services or trading configuration API for bulk threshold updates.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFeatureThresholdValues (procedure)
+-- Trade.FeatureThresholdValuesType (TVP type)
+-- Trade.FeatureThresholdValues (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeatureThresholdValuesType | User Defined Type (TVP) | Input parameter type: batch of (InstrumentID, FeatureID, ThresholdID, Value) rows |
| Trade.FeatureThresholdValues | Table | MERGE target - Value updated or new row inserted per composite key match |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (external configuration services) | - | Called by trading configuration API or admin tooling for bulk threshold updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. The procedure uses SET NOCOUNT ON. No explicit transaction wrapping - MERGE is atomic by default per SQL Server semantics. No TRY/CATCH - errors propagate to caller.

---

## 8. Sample Queries

### 8.1 Upsert a batch of feature threshold values
```sql
DECLARE @Config Trade.FeatureThresholdValuesType;

INSERT INTO @Config (InstrumentID, FeatureID, ThresholdID, Value)
VALUES
  (1001, 5, 1, 500.00),
  (1002, 5, 1, 750.00),
  (1003, 5, 2, 250.00);

EXEC Trade.UpdateFeatureThresholdValues @Values = @Config;
```

### 8.2 Check current threshold values for a feature
```sql
SELECT ftv.InstrumentID,
       ftv.FeatureID,
       ftv.ThresholdID,
       ftv.Value
FROM   Trade.FeatureThresholdValues ftv WITH (NOLOCK)
WHERE  ftv.FeatureID = 5
ORDER  BY ftv.InstrumentID, ftv.ThresholdID;
```

### 8.3 Find instruments with a specific threshold above a value
```sql
SELECT ftv.InstrumentID,
       im.InstrumentDisplayName,
       ftv.FeatureID,
       ftv.ThresholdID,
       ftv.Value
FROM   Trade.FeatureThresholdValues ftv WITH (NOLOCK)
JOIN   Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = ftv.InstrumentID
WHERE  ftv.FeatureID = 5
  AND  ftv.Value > 500.00
ORDER  BY ftv.Value DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFeatureThresholdValues | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFeatureThresholdValues.sql*
