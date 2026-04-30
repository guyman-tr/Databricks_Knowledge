# Trade.PositionPriceRateIDTableType

> A table-valued parameter type for passing position IDs with their associated price rate IDs and bid/ask spreaded values, used when closing positions at a specific price rate.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint), PriceRateID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.PositionPriceRateIDTableType carries position-to-pricing data: PositionID, PriceRateID, BidSpreaded, and AskSpreaded. It models the set of positions to close along with the exact price snapshot (rate ID) and spread-adjusted bid/ask to use for the close calculation.

This type exists to support close-at-price workflows where the caller has already determined the price rate and spreaded bid/ask for each position. The procedure receives a batch of positions with their pricing instead of recalculating it. This enables dealer-initiated closes, scheduled closes, or any flow that pre-selects closing prices.

The application or close engine populates this type from position and pricing lookups, passes it to Trade.ClosePositionAtPriceRateID, which uses the provided rates for the close execution.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. BidSpreaded and AskSpreaded are used by the consuming procedure for close-rate selection (IsBuy uses Ask, IsSell uses Bid).

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | Position identifier. Links to Trade.PositionTbl. Each row specifies one position to close at the given price rate. |
| 2 | PriceRateID | bigint | YES | - | CODE-BACKED | Price rate identifier from the pricing feed. Identifies the exact rate snapshot used for the close. |
| 3 | BidSpreaded | decimal(16,8) | YES | - | CODE-BACKED | Bid price with spread applied. Used when closing sell positions. |
| 4 | AskSpreaded | decimal(16,8) | YES | - | CODE-BACKED | Ask price with spread applied. Used when closing buy positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID references Trade.PositionTbl, PriceRateID references the pricing rate table; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ClosePositionAtPriceRateID | @PositionPrice | Parameter (TVP) | Closes positions at the provided price rate and spreaded bid/ask |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ClosePositionAtPriceRateID | Stored Procedure | READONLY parameter for close at price rate |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for close at price rate

```sql
DECLARE @PositionPrice Trade.PositionPriceRateIDTableType;
INSERT INTO @PositionPrice (PositionID, PriceRateID, BidSpreaded, AskSpreaded)
SELECT  PositionID, @PriceRateID, @BidSpreaded, @AskSpreaded
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   PositionID = 900000001;

EXEC Trade.ClosePositionAtPriceRateID @PositionPrice = @PositionPrice;
```

### 8.2 Multiple positions with same price rate

```sql
DECLARE @Positions Trade.PositionPriceRateIDTableType;
INSERT INTO @Positions (PositionID, PriceRateID, BidSpreaded, AskSpreaded)
VALUES (900000001, 12345678, 1.0850, 1.0855),
       (900000002, 12345678, 1.0850, 1.0855);

EXEC Trade.ClosePositionAtPriceRateID @PositionPrice = @Positions;
```

### 8.3 Single position close

```sql
DECLARE @One Trade.PositionPriceRateIDTableType;
INSERT INTO @One (PositionID, PriceRateID, BidSpreaded, AskSpreaded)
VALUES (900000001, 12345678, 99.50, 99.55);
EXEC Trade.ClosePositionAtPriceRateID @PositionPrice = @One;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionPriceRateIDTableType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionPriceRateIDTableType.sql*
