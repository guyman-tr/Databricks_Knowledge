# Trade.MimoPosition

> A memory-optimized table-valued parameter type for MIMO (memory-in-memory-out) position data carrying PnL and rate info per position, used in high-throughput in-memory processing flows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (indexed) |
| **Partition** | N/A |
| **Indexes** | ix1 nonclustered on PositionID, ix2 nonclustered on CID |

---

## 1. Business Meaning

Trade.MimoPosition is a memory-optimized table-valued parameter (TVP) type for MIMO-style position processing. It carries a slim subset of position attributes - PositionID, CID, PnL, rates, and PriceRateID - suitable for in-memory aggregation or PnL calculations where full position rows are not needed.

This type exists for high-throughput scenarios where procedures operate on many positions in memory. Memory optimization reduces locking and log contention. No stored procedure consumers were found in the Trade Stored Procedures folder; it may be used by application-level or natively compiled procedures, or reserved for future MIMO flows.

The type flows as a TVP: callers populate it with position snapshots and pass it to procedures that JOIN or aggregate on PositionID or CID. Indexes support lookups by either key.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. PositionID + CID + PnL/rate columns form a slim position snapshot for in-memory processing.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | Position identifier. Primary key for position lookup. |
| 2 | PnLInDollars | decimal(38,6) | YES | - | NAME-INFERRED | Profit or loss in dollars for the position. |
| 3 | CID | int | YES | - | CODE-BACKED | Customer ID - the account owning the position. |
| 4 | ConversionRate | decimal(16,8) | YES | - | NAME-INFERRED | Rate for converting PnL to account currency. |
| 5 | CurrentRate | decimal(16,8) | YES | - | NAME-INFERRED | Current instrument price rate. |
| 6 | PriceRateID | bigint | YES | - | CODE-BACKED | Reference to price rate snapshot. Links to price history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID, CID, and PriceRateID semantically reference position, customer, and price rate entities; no declared FKs on the type.

### 5.2 Referenced By (other objects point to this)

No consumers found in Trade.Stored Procedures. May be used by natively compiled procedures, CLR, or application-tier code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No consumers found in the searched scope.

---

## 7. Technical Details

### 7.1 Indexes

Memory-optimized type with two nonclustered indexes: ix1 on PositionID, ix2 on CID. WITH (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for position PnL batch

```sql
DECLARE @Mimo Trade.MimoPosition;
INSERT INTO @Mimo (PositionID, PnLInDollars, CID, ConversionRate, CurrentRate, PriceRateID)
SELECT PositionID, NetProfit, CID, InitConversionRate, LastOpPriceRate, LastOpPriceRateID
FROM Trade.PositionTbl WHERE IsOpen = 1;
-- Pass to MIMO-aware procedure
```

### 8.2 Single position snapshot

```sql
DECLARE @Mimo Trade.MimoPosition;
INSERT INTO @Mimo (PositionID, PnLInDollars, CID, ConversionRate, CurrentRate, PriceRateID)
VALUES (123456, 150.50, 9999, 1.0, 1.2345, 987654);
```

### 8.3 Filter by CID for customer-level aggregation

```sql
DECLARE @Mimo Trade.MimoPosition;
INSERT INTO @Mimo (PositionID, PnLInDollars, CID, ConversionRate, CurrentRate, PriceRateID)
SELECT PositionID, PnLInDollars, CID, ConversionRate, CurrentRate, PriceRateID
FROM @InputMimo WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 8/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.MimoPosition | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.MimoPosition.sql*
