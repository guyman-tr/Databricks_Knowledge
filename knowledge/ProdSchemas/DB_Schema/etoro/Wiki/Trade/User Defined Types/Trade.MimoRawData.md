# Trade.MimoRawData

> A memory-optimized table-valued parameter type for raw MIMO (memory-in-memory-out) data carrying position-level PnL, equity, and rate snapshots for batch calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (indexed) |
| **Partition** | N/A |
| **Indexes** | ix nonclustered on CID |

---

## 1. Business Meaning

Trade.MimoRawData is a memory-optimized table-valued parameter (TVP) type that carries raw position and equity data for MIMO-style processing. Each row holds CID, PositionID, current/conversion rates, bonus credit, realized equity, BSL real funds, and PnL - the raw inputs needed for margin or equity calculations.

This type exists for high-throughput in-memory aggregation where procedures process many position-level rows without disk I/O. Memory optimization reduces locking. No stored procedure consumers were found in the Trade Stored Procedures folder; it may be used by natively compiled procedures or application-tier flows.

The type flows as a TVP: callers populate it with raw position/equity snapshots and pass it to procedures that aggregate by CID or process PnL/equity logic. The index on CID supports customer-level lookups.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. CID + PositionID + rate/equity columns form raw input for margin or PnL aggregation by customer.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID - account identifier. Primary grouping key. |
| 2 | PositionID | bigint | YES | - | CODE-BACKED | Position identifier. Links to position entity. |
| 3 | CurrentRate | decimal(16,8) | YES | - | NAME-INFERRED | Current instrument price rate. |
| 4 | PriceRateID | bigint | YES | - | CODE-BACKED | Reference to price rate snapshot. |
| 5 | ConversionRate | decimal(16,8) | YES | - | NAME-INFERRED | Rate for converting values to account currency. |
| 6 | BonusCredit | money | YES | - | NAME-INFERRED | Bonus credit amount for the position/account. |
| 7 | RealizedEquity | money | YES | - | NAME-INFERRED | Realized equity component. |
| 8 | BSLRealFunds | money | YES | - | NAME-INFERRED | BSL (balance?) real funds amount. |
| 9 | PnLInDollars | decimal(38,6) | YES | - | NAME-INFERRED | Profit or loss in dollars. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID and PositionID semantically reference customer and position entities; no declared FKs on the type.

### 5.2 Referenced By (other objects point to this)

No consumers found in Trade.Stored Procedures. May be used by natively compiled procedures or application-tier code.

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

Memory-optimized type with one nonclustered index: ix on CID. WITH (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate from positions

```sql
DECLARE @Mimo Trade.MimoRawData;
INSERT INTO @Mimo (CID, PositionID, CurrentRate, PriceRateID, ConversionRate, BonusCredit, RealizedEquity, BSLRealFunds, PnLInDollars)
SELECT CID, PositionID, LastOpPriceRate, LastOpPriceRateID, InitConversionRate, 0, 0, 0, NetProfit
FROM Trade.PositionTbl WHERE IsOpen = 1;
```

### 8.2 Single position raw data

```sql
DECLARE @Mimo Trade.MimoRawData;
INSERT INTO @Mimo (CID, PositionID, CurrentRate, PriceRateID, ConversionRate, BonusCredit, RealizedEquity, BSLRealFunds, PnLInDollars)
VALUES (9999, 123456, 1.2345, 987654, 1.0, 0, 1000, 500, 50.25);
```

### 8.3 Filter by CID for customer batch

```sql
DECLARE @Mimo Trade.MimoRawData;
INSERT INTO @Mimo (CID, PositionID, CurrentRate, PriceRateID, ConversionRate, BonusCredit, RealizedEquity, BSLRealFunds, PnLInDollars)
SELECT CID, PositionID, CurrentRate, PriceRateID, ConversionRate, BonusCredit, RealizedEquity, BSLRealFunds, PnLInDollars
FROM @InputMimo WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 7/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.MimoRawData | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.MimoRawData.sql*
