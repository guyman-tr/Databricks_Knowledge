# Trade.ReverseSplitType

> A table-valued parameter type for instrument reverse-split mappings - before/after stop-loss rates per instrument, used when applying reverse split adjustments to positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (semantic - no PK) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.ReverseSplitType is a table-valued parameter (TVP) type for reverse-split operations on instruments. A reverse split (e.g., 1-for-4) reduces the number of shares and increases the price proportionally. This type maps each InstrumentID to SlBefore (stop-loss rate before the split) and SlAfter (stop-loss rate after the split), enabling procedures to adjust existing stop-loss orders when a reverse split is applied.

This type exists to support Trade.ReverseSplit, which applies reverse-split adjustments to instruments and their positions. When an instrument undergoes a reverse split, stop-loss and take-profit rates must be recalculated; this TVP carries the mapping so the procedure can update positions and orders accordingly.

The application or a corporate-action job builds the type from split metadata and passes it to Trade.ReverseSplit. The procedure JOINs against the TVP to apply the SlAfter values.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The three columns form an InstrumentID -> (SlBefore, SlAfter) mapping for split adjustment.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Instrument affected by the reverse split. |
| 2 | SlBefore | decimal(8,4) | YES | - | CODE-BACKED | Stop-loss rate before the reverse split. |
| 3 | SlAfter | decimal(8,4) | YES | - | CODE-BACKED | Stop-loss rate after the reverse split (adjusted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. InstrumentID semantically references Trade.Instrument; no declared FK.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ReverseSplit | @RS | Parameter (TVP) | Applies reverse-split adjustments to instruments and positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReverseSplit | Stored Procedure | READONLY parameter for reverse-split processing |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for single-instrument reverse split

```sql
DECLARE @RS Trade.ReverseSplitType;
INSERT INTO @RS (InstrumentID, SlBefore, SlAfter)
VALUES (12345, 50.0000, 200.0000);  -- 1:4 reverse split

EXEC Trade.ReverseSplit @RS = @RS;
```

### 8.2 Build from corporate action data

```sql
DECLARE @Splits Trade.ReverseSplitType;
INSERT INTO @Splits (InstrumentID, SlBefore, SlAfter)
SELECT  InstrumentID, OldSL, OldSL * @SplitRatio
FROM    #CorporateActionData;
```

### 8.3 Multiple instruments

```sql
DECLARE @RS Trade.ReverseSplitType;
INSERT INTO @RS (InstrumentID, SlBefore, SlAfter)
VALUES (100, 10.50, 42.00), (101, 5.25, 21.00);

EXEC Trade.ReverseSplit @RS = @RS;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReverseSplitType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.ReverseSplitType.sql*
