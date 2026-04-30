# Trade.RebalanceTbl

> A table-valued parameter type for submitting rebalance requests - position close data with pricing and error info, used when inserting rebalance requests for manual or automated rebalancing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (clustered PK) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on PositionID |

---

## 1. Business Meaning

Trade.RebalanceTbl is a table-valued parameter (TVP) type for submitting rebalance requests. Each row represents one position to be closed as part of a rebalance, with CID, IsBuy, pricing (Bid, Ask, CloseRate), PriceRateID, and optional Error text. The type uses [dbo].[dtPrice] for bid/ask/close rates - the custom scalar type for decimal pricing.

This type exists to support the rebalance workflow. Trade.InsertRebalanceRequests accepts this TVP and INSERTs into Trade.RebalanceRequests. Rebalancing adjusts portfolio allocation by closing selected positions; the caller provides the positions and their close prices. The Error column allows the caller to report validation or pricing issues per row.

Application or back-office tools build a RebalanceTbl from positions and pricing data, then pass it to InsertRebalanceRequests. The procedure bulk-inserts into Trade.RebalanceRequests.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type groups position identifier (PositionID, CID), direction (IsBuy), discount flag (IsDiscounted), pricing (Bid, Ask, CloseRate, PriceRateID), and error feedback (Error).

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position ID - identifies the position to rebalance (close). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID - account owning the position. |
| 3 | IsBuy | bit | NO | - | CODE-BACKED | 1=buy, 0=sell - direction of the position. |
| 4 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether discounted pricing applies. |
| 5 | PriceRateID | bigint | NO | - | CODE-BACKED | Price rate snapshot ID for the close. |
| 6 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Bid price for close calculation. |
| 7 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Ask price for close calculation. |
| 8 | CloseRate | dbo.dtPrice | NO | - | CODE-BACKED | Rate used for the close execution. |
| 9 | Error | varchar(500) | YES | - | CODE-BACKED | Error or validation message for this row, if any. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID, CID, PriceRateID semantically reference Trade.PositionTbl, Customer, and pricing tables; no declared FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertRebalanceRequests | @RebalanceTbl | Parameter (TVP) | Bulk-inserts rebalance requests from the TVP |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. Uses [dbo].[dtPrice] - a scalar type alias.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertRebalanceRequests | Stored Procedure | READONLY parameter for bulk rebalance request insert |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns |
|-----------|------|-------------|
| (PK) | CLUSTERED | PositionID ASC |

IGNORE_DUP_KEY = OFF - duplicates raise an error.

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Declare and populate for rebalance insert

```sql
DECLARE @Rebalance Trade.RebalanceTbl;
INSERT INTO @Rebalance (PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, Error)
VALUES (900000001, 12345, 1, 0, 1000001, 150.50, 150.55, 150.52, NULL);

EXEC Trade.InsertRebalanceRequests @RebalanceTbl = @Rebalance;
```

### 8.2 Build from positions with pricing

```sql
DECLARE @Tbl Trade.RebalanceTbl;
INSERT INTO @Tbl (PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, Error)
SELECT  p.PositionID, p.CID, p.IsBuy, p.IsDiscounted, @PriceRateID, @Bid, @Ask, @CloseRate, NULL
FROM    Trade.PositionTbl p WITH (NOLOCK)
WHERE   p.InstrumentID = @InstrumentID AND p.IsOpen = 1;
```

### 8.3 Include error for failed validation

```sql
INSERT INTO @Rebalance (PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, Error)
VALUES (900000002, 12345, 0, 0, 1000002, 45.00, 45.02, 45.01, 'Spread too wide');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RebalanceTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.RebalanceTbl.sql*
