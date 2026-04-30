# Trade.UpdateRolloverFeeThresholdTbl

> TVP for bulk updates of rollover fee thresholds per instrument type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentTypeID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UpdateRolloverFeeThresholdTbl carries instrument-type-level rollover fee threshold data. Each row has InstrumentTypeID and RolloverFeeThreshold - the decimal threshold above which rollover fees apply or are calculated differently.

This type exists to support batch updates of rollover fee threshold configuration. Admin or sync services populate the TVP and pass it to Trade.UpdateRolloverFeeThreshold.

The type flows from config services into Trade.UpdateRolloverFeeThreshold. The procedure JOINs the TVP against the interest rate or instrument-type config table and updates the rollover fee thresholds.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. InstrumentTypeID + RolloverFeeThreshold pair per row.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | CODE-BACKED | Instrument type identifier |
| 2 | RolloverFeeThreshold | decimal(16,8) | NO | - | CODE-BACKED | Threshold value for rollover fee calculation or application |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentTypeID semantically references Trade.InstrumentType but no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateRolloverFeeThreshold | @UpdateRolloverFeeThresholdTbl | Parameter (TVP) | Bulk update of rollover fee thresholds per instrument type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateRolloverFeeThreshold | Stored Procedure | READONLY parameter for bulk rollover fee threshold updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Single instrument type update
```sql
DECLARE @UpdateRolloverFeeThresholdTbl Trade.UpdateRolloverFeeThresholdTbl;
INSERT INTO @UpdateRolloverFeeThresholdTbl (InstrumentTypeID, RolloverFeeThreshold)
VALUES (1, 0.001);
EXEC Trade.UpdateRolloverFeeThreshold @UpdateRolloverFeeThresholdTbl = @UpdateRolloverFeeThresholdTbl;
```

### 8.2 Multi-row batch update
```sql
DECLARE @UpdateRolloverFeeThresholdTbl Trade.UpdateRolloverFeeThresholdTbl;
INSERT INTO @UpdateRolloverFeeThresholdTbl (InstrumentTypeID, RolloverFeeThreshold)
VALUES (1, 0.001), (2, 0.002), (3, 0.0015);
EXEC Trade.UpdateRolloverFeeThreshold @UpdateRolloverFeeThresholdTbl = @UpdateRolloverFeeThresholdTbl;
```

### 8.3 Build from table
```sql
DECLARE @UpdateRolloverFeeThresholdTbl Trade.UpdateRolloverFeeThresholdTbl;
INSERT INTO @UpdateRolloverFeeThresholdTbl (InstrumentTypeID, RolloverFeeThreshold)
SELECT InstrumentTypeID, 0.002 FROM Trade.InstrumentType WHERE InstrumentTypeID IN (1,2,3);
EXEC Trade.UpdateRolloverFeeThreshold @UpdateRolloverFeeThresholdTbl = @UpdateRolloverFeeThresholdTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateRolloverFeeThresholdTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UpdateRolloverFeeThresholdTbl.sql*
