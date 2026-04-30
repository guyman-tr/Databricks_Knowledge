# Trade.OMEMatchingTableType

> A table-valued parameter type for order matching by instrument and modulo configuration, used to filter which instruments and matching behaviors (SL/TP, orders) are processed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumetID (typo in DDL), ModDivider + ModResult |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.OMEMatchingTableType is a table-valued parameter (TVP) type used for OME (Order Matching Engine) operations. Each row specifies an instrument and associated flags for how to handle stop-loss/take-profit (HandleSlTp), orders (HandleOrders), and modulo-based bucketing (ModDivider, ModResult) for distributed matching.

This type exists to support GetOrderMatchingItemsByInstrumentIDAndModDIV, which receives a set of instruments and their matching configuration. The procedure uses the TVP to determine which order-matching items to retrieve and how to partition work by ModDivider/ModResult.

The application or orchestration layer builds an OMEMatchingTableType table with instrument IDs and matching config, then passes it to GetOrderMatchingItemsByInstrumentIDAndModDIV. The procedure JOINs or filters based on the TVP.

---

## 2. Business Logic

InstrumentID + HandleSlTp + HandleOrders + ModDivider + ModResult form a config group: each row defines one instrument's matching behavior and modulo bucket for parallelism.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumetID | int | YES | - | CODE-BACKED | Instrument ID (note: typo in DDL - InstrumetID). Identifies the instrument for order matching. |
| 2 | HandleSlTp | bit | YES | - | NAME-INFERRED | When 1, process stop-loss and take-profit for this instrument. |
| 3 | HandleOrders | bit | YES | - | NAME-INFERRED | When 1, process orders for this instrument. |
| 4 | ModDivider | int | YES | - | NAME-INFERRED | Modulo divisor for partitioning work (e.g. bucket count). |
| 5 | ModResult | int | YES | - | NAME-INFERRED | Modulo remainder - this instance processes items where ID % ModDivider = ModResult. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. InstrumetID semantically references Instrument entities.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV | @instrumentsTable | Parameter (TVP) | Retrieves order matching items filtered by instrument and modulo config |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV | Stored Procedure | READONLY parameter for instrument matching config |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for single instrument

```sql
DECLARE @Instruments Trade.OMEMatchingTableType;
INSERT INTO @Instruments (InstrumetID, HandleSlTp, HandleOrders, ModDivider, ModResult)
VALUES (1001, 1, 1, 4, 0);
EXEC Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV @instrumentsTable = @Instruments;
```

### 8.2 Multiple instruments with modulo partitioning

```sql
DECLARE @Instruments Trade.OMEMatchingTableType;
INSERT INTO @Instruments (InstrumetID, HandleSlTp, HandleOrders, ModDivider, ModResult)
SELECT InstrumentID, 1, 1, @BucketCount, @BucketIndex
FROM Staging.InstrumentsToMatch;
EXEC Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV @instrumentsTable = @Instruments;
```

### 8.3 SL/TP only for specific instrument

```sql
DECLARE @Instruments Trade.OMEMatchingTableType;
INSERT INTO @Instruments (InstrumetID, HandleSlTp, HandleOrders, ModDivider, ModResult)
VALUES (2001, 1, 0, 1, 0);
EXEC Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV @instrumentsTable = @Instruments;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OMEMatchingTableType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OMEMatchingTableType.sql*
