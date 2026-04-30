# Trade.PositionsForDividendPaymentTbl

> A table-valued parameter type for passing positions eligible for dividend payment along with their fee and tax values, used when paying dividends to position holders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint), ParentPositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.PositionsForDividendPaymentTbl carries the set of positions that are eligible for dividend payment, plus their fee (FeeInDollars), buy tax (BuyTax), and sell tax (SellTax). It models the input batch for the dividend payment workflow, including parent-child position relationships and whether the position is still open.

This type exists to support dividend distribution: when an instrument pays a dividend, the system must identify which positions qualify, calculate fees and taxes, and credit accounts. This type aggregates that pre-calculated data per position so Trade.PayDividendsForPositions can process the batch.

The dividend engine or job populates this type from position and tax calculations, passes it to Trade.PayDividendsForPositions. Uses [dbo].[dtPrice] for FeeInDollars.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. FeeInDollars, BuyTax, and SellTax are independent per-position values computed upstream; the procedure applies them during payment.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier. Links to Trade.PositionTbl. Each row represents one position eligible for dividend payment. |
| 2 | ParentPositionID | bigint | NO | - | CODE-BACKED | Parent position ID for copy-trade or split positions. Tracks hierarchy for dividend allocation. |
| 3 | IsOpen | bit | NO | - | CODE-BACKED | Whether the position is still open at payment time. Affects dividend treatment. |
| 4 | FeeInDollars | dbo.dtPrice | NO | - | CODE-BACKED | Fee amount in dollars for this position. Uses custom scalar type dtPrice. |
| 5 | BuyTax | decimal(16,8) | NO | - | CODE-BACKED | Buy-side tax amount for this position. |
| 6 | SellTax | decimal(16,8) | NO | - | CODE-BACKED | Sell-side tax amount for this position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID and ParentPositionID reference Trade.PositionTbl; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PayDividendsForPositions | @positionsTable | Parameter (TVP) | Processes dividend payments for the specified positions with fees and taxes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies. Uses [dbo].[dtPrice] for FeeInDollars.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PayDividendsForPositions | Stored Procedure | READONLY parameter for dividend payment |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for dividend payment

```sql
DECLARE @positions Trade.PositionsForDividendPaymentTbl;
INSERT INTO @positions (PositionID, ParentPositionID, IsOpen, FeeInDollars, BuyTax, SellTax)
SELECT  PositionID, ParentPositionID, IsOpen, @FeePerPosition, 0, 0
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   InstrumentID = @DividendInstrumentID AND IsOpen = 1;

EXEC Trade.PayDividendsForPositions @positionsTable = @positions;
```

### 8.2 Single position dividend

```sql
DECLARE @One Trade.PositionsForDividendPaymentTbl;
INSERT INTO @One (PositionID, ParentPositionID, IsOpen, FeeInDollars, BuyTax, SellTax)
VALUES (900000001, 900000000, 1, 0.50, 0.10, 0.10);
EXEC Trade.PayDividendsForPositions @positionsTable = @One;
```

### 8.3 Batch with varying taxes

```sql
DECLARE @Batch Trade.PositionsForDividendPaymentTbl;
INSERT INTO @Batch (PositionID, ParentPositionID, IsOpen, FeeInDollars, BuyTax, SellTax)
VALUES (900000001, 900000000, 1, 1.00, 0.15, 0.15),
       (900000002, 900000000, 1, 0.50, 0.08, 0.08);
EXEC Trade.PayDividendsForPositions @positionsTable = @Batch;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsForDividendPaymentTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionsForDividendPaymentTbl.sql*
