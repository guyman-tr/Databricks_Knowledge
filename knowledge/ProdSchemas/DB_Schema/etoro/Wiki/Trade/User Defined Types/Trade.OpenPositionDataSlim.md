# Trade.OpenPositionDataSlim

> Memory-optimized table-valued parameter type carrying a reduced set of position attributes for bulk open-position retrieval, used when full OpenPositionData columns are not needed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (indexed) |
| **Partition** | N/A |
| **Indexes** | 1 (IDX_PositionID HASH on PositionID, BUCKET_COUNT 512) |

---

## 1. Business Meaning

Trade.OpenPositionDataSlim is a memory-optimized table-valued parameter type that holds a subset of open position attributes - customer, instrument, rates, amounts, hedge/mirror metadata, and pending close order info. It is a slimmer alternative to OpenPositionData when the full 66-column snapshot is unnecessary.

This type exists for GetOpenPositionsData and similar bulk retrieval scenarios where many positions are loaded into memory. Memory optimization and fewer columns reduce I/O and lock contention. The procedure declares a local variable of this type and populates it with position data for further processing or return.

The procedure declares a local variable of type Trade.OpenPositionDataSlim, populates it via INSERT...SELECT from position sources, and uses it for API responses or downstream logic. Index on PositionID supports lookups when joining or filtering.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type is a structural container; business rules are in the consuming procedure.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID - account identifier. |
| 2 | PositionID | bigint | YES | - | CODE-BACKED | Position identifier; indexed for lookups. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. |
| 4 | PositionHedgeServerID | int | YES | - | NAME-INFERRED | Hedge server for this position leg. |
| 5 | Leverage | int | YES | - | CODE-BACKED | Leverage applied. |
| 6 | InitForexRate | decimal(16,8) | YES | - | CODE-BACKED | Initial forex rate at open. |
| 7 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 8 | LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit level. |
| 9 | StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss level. |
| 10 | Amount | money | YES | - | CODE-BACKED | Position amount. |
| 11 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Units in decimal. |
| 12 | IsBuy | tinyint | YES | - | CODE-BACKED | Buy (1) vs sell (0). |
| 13 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent in position tree. |
| 14 | UnitMargin | decimal(15,8) | YES | - | NAME-INFERRED | Margin per unit. |
| 15 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. |
| 16 | PositionRatio | decimal(7,6) | YES | - | NAME-INFERRED | Ratio for partial/aggregated positions. |
| 17 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server identifier. |
| 18 | RootHedgeServerID | int | YES | - | NAME-INFERRED | Root hedge server in tree. |
| 19 | TreeID | bigint | YES | - | CODE-BACKED | Position tree identifier. |
| 20 | IsComputeForHedge | smallint | YES | - | NAME-INFERRED | Flag for hedge computation. |
| 21 | IsTslEnabled | tinyint | YES | - | NAME-INFERRED | Trailing stop-loss enabled. |
| 22 | IsMirrorActive | tinyint | YES | - | NAME-INFERRED | Mirror copy-trade active. |
| 23 | RedeemStatus | tinyint | YES | - | NAME-INFERRED | Redemption status. |
| 24 | IsSettled | bit | YES | - | CODE-BACKED | Settlement complete. |
| 25 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type. |
| 26 | UnitsBaseValueCents | int | YES | - | NAME-INFERRED | Base value in cents. |
| 27 | IsDiscounted | bit | YES | - | NAME-INFERRED | Discount applied. |
| 28 | PendingOrderForClose | bigint | YES | - | NAME-INFERRED | Order ID for pending close. |
| 29 | MirrorStatusID | int | YES | - | NAME-INFERRED | Mirror status. |
| 30 | RedeemID | int | YES | - | CODE-BACKED | Redemption identifier. |
| 31 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Initial forex price rate reference. |
| 32 | PendingOrderForCloseStatus | tinyint | YES | - | NAME-INFERRED | Status of pending close order. |
| 33 | PendingOrderForCloseType | int | YES | - | NAME-INFERRED | Type of pending close order. |
| 34 | PendingOrderForCloseUnitsToDeduct | decimal(16,6) | YES | - | NAME-INFERRED | Units to deduct on close. |
| 35 | StopLossVersion | smallint | YES | - | NAME-INFERRED | Stop-loss version for concurrency. |
| 36 | IsNoStopLoss | bit | YES | - | CODE-BACKED | No stop-loss set. |
| 37 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | No take-profit set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID, PositionID, InstrumentID, MirrorID semantically reference Customer, Position, Instrument, and Mirror entities; no declared FKs on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOpenPositionsData | @PositionData | Local variable (TVP) | Holds bulk position data for API retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOpenPositionsData | Stored Procedure | Local table variable for bulk position retrieval |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| IDX_PositionID | NONCLUSTERED HASH | PositionID (BUCKET_COUNT 512) |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk position retrieval

```sql
DECLARE @PositionData Trade.OpenPositionDataSlim;
INSERT INTO @PositionData (CID, PositionID, InstrumentID, ...)
SELECT CID, PositionID, InstrumentID, ... FROM Trade.PositionTbl WHERE IsOpen = 1;
```

### 8.2 Populate from open positions for CID

```sql
DECLARE @Positions Trade.OpenPositionDataSlim;
INSERT INTO @Positions
SELECT p.CID, p.PositionID, p.InstrumentID, ...
FROM Trade.PositionTbl p
WHERE p.CID = @CID AND p.IsOpen = 1;
```

### 8.3 Join slim data for API response

```sql
DECLARE @Data Trade.OpenPositionDataSlim;
-- ... populate ...
SELECT * FROM @Data WHERE PositionID = @TargetPositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 12 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionDataSlim | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OpenPositionDataSlim.sql*
