# Trade.Rebalance

> A minimal table-valued parameter type for manual rebalance operations: pairs position IDs with their price rate IDs for rebalancing exposure or margin.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint), PriceRateID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.Rebalance is a lightweight table-valued parameter (TVP) type that carries PositionID and PriceRateID pairs. It models the set of positions to rebalance along with the price rate snapshot to use for the rebalance calculation.

This type exists to support manual rebalance workflows where a user (typically via Trade.ManualRenlance) specifies which positions to rebalance and at which price. Rebalancing adjusts exposure or margin to align with target levels. The minimal schema keeps the type simple for admin-driven operations.

The application or back-office tool populates this type from user selection and pricing lookups, passes it to Trade.ManualRenlance, which performs the rebalance using the supplied positions and rates.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Each row is an independent position-to-rate mapping.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | Position identifier. Links to Trade.PositionTbl. Each row specifies one position to rebalance. |
| 2 | PriceRateID | bigint | YES | - | CODE-BACKED | Price rate identifier. Identifies the rate snapshot to use for rebalance calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID references Trade.PositionTbl, PriceRateID references the pricing feed; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManualRenlance | @i | Parameter (TVP) | Performs manual rebalance on the specified positions using the given price rates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManualRenlance | Stored Procedure | READONLY parameter for manual rebalance |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for manual rebalance

```sql
DECLARE @i Trade.Rebalance;
INSERT INTO @i (PositionID, PriceRateID)
SELECT  PositionID, @CurrentPriceRateID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   InstrumentID = 42 AND IsOpen = 1;

EXEC Trade.ManualRenlance @username = 'admin', @i = @i;
```

### 8.2 Single position rebalance

```sql
DECLARE @One Trade.Rebalance;
INSERT INTO @One (PositionID, PriceRateID) VALUES (900000001, 12345678);
EXEC Trade.ManualRenlance @username = 'admin', @i = @One;
```

### 8.3 Batch from exposure report

```sql
DECLARE @Rebalance Trade.Rebalance;
INSERT INTO @Rebalance (PositionID, PriceRateID)
SELECT  PositionID, PriceRateID
FROM    SomeExposureView
WHERE   ExposureDelta > @Threshold;
EXEC Trade.ManualRenlance @username = 'ops', @i = @Rebalance;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Rebalance | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Rebalance.sql*
