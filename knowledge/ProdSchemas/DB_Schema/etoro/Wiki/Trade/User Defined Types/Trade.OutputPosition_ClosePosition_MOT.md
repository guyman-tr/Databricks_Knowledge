# Trade.OutputPosition_ClosePosition_MOT

> A memory-optimized table-valued type used to capture position-level OUTPUT data when closing positions - before/after amounts, units, lot counts, and base values for partial-close and PnL calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | AmountInUnits (indexed - no PK) |
| **Partition** | N/A |
| **Indexes** | IX_AmountInUnits (NONCLUSTERED on AmountInUnits) |

---

## 1. Business Meaning

Trade.OutputPosition_ClosePosition_MOT is a memory-optimized TVP type that holds position-level "before and after" data captured via OUTPUT clauses during close operations. It stores PreviousAmountInUnits vs AmountInUnits, PreviousUnitsBaseValueInCents vs UnitsBaseValueInCents, and PreviousLotCountDecimal vs LotCountDecimal - enabling partial-close and PnL calculations.

This type exists to support partial close and balance updates. When a position is partially closed, Trade.PositionClose populates @OutputPosition via OUTPUT INTO to track the delta in units and base value. The procedure then uses this data to update Trade.Position and drive billing. Memory-optimized design supports high-volume close processing.

The type flows internally: Trade.PositionClose declares @OutputPosition, populates it from OUTPUT, and uses it with @OutputCustomer to drive updates. It is not passed as a parameter to other procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The Previous* / current column pairs model before/after state for partial-close deltas.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PreviousAmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in units before the close (or partial close). |
| 2 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in units after the close (remaining open units). |
| 3 | PreviousUnitsBaseValueInCents | int | YES | - | CODE-BACKED | Units base value in cents before close. |
| 4 | UnitsBaseValueInCents | int | YES | - | CODE-BACKED | Units base value in cents after close. |
| 5 | PreviousLotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count before close. |
| 6 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count after close. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionClose | @OutputPosition | Local variable (OUTPUT target) | Declares, populates via OUTPUT INTO, uses with @OutputCustomer for updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionClose | Stored Procedure | Local OUTPUT target for position-level close data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns |
|-----------|------|-------------|
| IX_AmountInUnits | NONCLUSTERED | AmountInUnits ASC |

Memory-optimized (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and use as OUTPUT target (conceptual)

```sql
-- Inside Trade.PositionClose:
DECLARE @OutputPosition Trade.OutputPosition_ClosePosition_MOT;
-- Populated via OUTPUT INTO from UPDATE; used for partial-close and PnL logic
```

### 8.2 Inspect structure

```sql
SELECT c.name, t.name AS type_name
FROM   sys.table_types tt
       JOIN sys.columns c ON c.object_id = tt.type_table_object_id
       JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE  tt.name = 'OutputPosition_ClosePosition_MOT';
```

### 8.3 Join pattern in PositionClose

```sql
-- PositionClose joins @OutputPosition with @OutputCustomer
FROM    @OutputPosition OP
        JOIN @OutputCustomer OC ON ...
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OutputPosition_ClosePosition_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OutputPosition_ClosePosition_MOT.sql*
