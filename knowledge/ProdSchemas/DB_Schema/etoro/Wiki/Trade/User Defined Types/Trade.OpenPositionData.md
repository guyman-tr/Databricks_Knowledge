# Trade.OpenPositionData

> A table-valued parameter type carrying full position snapshot data used as a local variable buffer when retrieving and processing open position details for single-position lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (semantic) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.OpenPositionData is a table-valued parameter type that holds a comprehensive snapshot of a single open position. It mirrors the structure expected from position retrieval - including customer, instrument, pricing, forex, mirror, hedge, commission, and settlement attributes. It represents the full in-memory shape of position data used by procedures that fetch, transform, or pass position details.

This type exists to support GetOpenPositionData, which populates a local variable of this type with position data for a given PositionID. The procedure uses the TVP as a buffer to hold the result of its position lookup before returning or further processing.

The procedure declares a local variable of type Trade.OpenPositionData, populates it via internal logic or INSERT...SELECT, and uses it for calculations or as an intermediate result set. Callers invoke GetOpenPositionData with a PositionID; the procedure fills and uses this type internally.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type is a structural container for position attributes; business rules are implemented in the consuming procedure.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID - the account that owns the position. |
| 2 | PositionID | bigint | YES | - | CODE-BACKED | Primary identifier for the position. |
| 3 | ForexResultID | bigint | YES | - | NAME-INFERRED | Links to forex conversion result. |
| 4 | IsOpened | int | YES | - | NAME-INFERRED | Indicates whether the position is open. |
| 5 | Currency | int | YES | - | CODE-BACKED | Currency ID of the position. |
| 6 | ProviderID | int | YES | - | CODE-BACKED | Liquidity provider ID. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Instrument (symbol) ID. |
| 8 | PositionHedgeServerID | int | YES | - | NAME-INFERRED | Hedge server for the position. |
| 9 | Leverage | int | YES | - | CODE-BACKED | Leverage applied to the position. |
| 10 | ForexBuy | int | YES | - | NAME-INFERRED | Forex buy-side reference. |
| 11 | ForexSell | int | YES | - | NAME-INFERRED | Forex sell-side reference. |
| 12 | InitForexRate | decimal(16,8) | YES | - | NAME-INFERRED | Initial forex conversion rate at open. |
| 13 | EndForexRate | int | YES | - | NAME-INFERRED | Ending forex rate (possibly stored as ID). |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | Position open timestamp. |
| 15 | EndDateTime | int | YES | - | NAME-INFERRED | Close timestamp (possibly stored as ID). |
| 16 | ActionType | int | YES | - | CODE-BACKED | Type of trading action. |
| 17 | NetProfit | int | YES | - | CODE-BACKED | Net profit value (may be cents). |
| 18 | LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit level. |
| 19 | StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss level. |
| 20 | Amount | money | YES | - | CODE-BACKED | Position amount. |
| 21 | AmountInUnitsDecimal | decimal(16,6) | YES | - | NAME-INFERRED | Position size in units. |
| 22 | Commission | money | YES | - | CODE-BACKED | Commission charged. |
| 23 | SpreadedCommission | int | YES | - | NAME-INFERRED | Spread-related commission. |
| 24 | IsBuy | varchar(5) | YES | - | CODE-BACKED | Direction: buy vs sell. |
| 25 | CloseOnEndOfWeek | varchar(5) | YES | - | NAME-INFERRED | Weekend rollover flag. |
| 26 | EndOfWeekFee | money | YES | - | NAME-INFERRED | Weekend rollover fee. |
| 27 | LotCountDecimal | decimal(16,6) | YES | - | NAME-INFERRED | Lot count. |
| 28 | AdditionalParam | sql_variant | YES | - | NAME-INFERRED | Additional parameters. |
| 29 | OpenOccurred | datetime | YES | - | NAME-INFERRED | Actual open time. |
| 30 | CloseOccurred | int | YES | - | NAME-INFERRED | Actual close time. |
| 31 | OrderID | int | YES | - | CODE-BACKED | Order that opened the position. |
| 32 | TradeRange | int | YES | - | NAME-INFERRED | Trading range/session. |
| 33 | InitForexPriceRateID | bigint | YES | - | NAME-INFERRED | Price rate ID at open. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in aggregate/tree. |
| 35 | OrigParentPositionID | bigint | YES | - | NAME-INFERRED | Original parent position. |
| 36 | LastOpPriceRate | decimal(16,8) | YES | - | NAME-INFERRED | Last operation price. |
| 37 | LastOpPriceRateID | bigint | YES | - | NAME-INFERRED | Last operation price rate ID. |
| 38 | LastOpConversionRate | decimal(16,8) | YES | - | NAME-INFERRED | Last operation forex rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | NAME-INFERRED | Last operation forex rate ID. |
| 40 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit. |
| 41 | Units | int | YES | - | CODE-BACKED | Position units. |
| 42 | InstrumentPrecision | tinyint | YES | - | CODE-BACKED | Instrument decimal precision. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. |
| 44 | PositionRatio | decimal(7,6) | YES | - | CODE-BACKED | Ratio in mirror/aggregate. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | NAME-INFERRED | Direct aggregate lot count. |
| 46 | SpreadGroupID | int | YES | - | NAME-INFERRED | Spread group. |
| 47 | InitialAmountCents | money | YES | - | NAME-INFERRED | Initial amount in cents. |
| 48 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID. |
| 49 | InitExecutionID | bigint | YES | - | NAME-INFERRED | Initial execution ID. |
| 50 | EndExecutionID | bigint | YES | - | NAME-INFERRED | Closing execution ID. |
| 51 | RootHedgeServerID | int | YES | - | NAME-INFERRED | Root hedge server in tree. |
| 52 | IsOpenOpen | bit | YES | - | NAME-INFERRED | Open-open flag. |
| 53 | TreeID | bigint | YES | - | CODE-BACKED | Position tree identifier. |
| 54 | IsComputeForHedge | smallint | YES | - | NAME-INFERRED | Compute-for-hedge flag. |
| 55 | ExitOrderID | int | YES | - | NAME-INFERRED | Order for exit. |
| 56 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop loss enabled. |
| 57 | IsMirrorActive | tinyint | YES | - | CODE-BACKED | Mirror active flag. |
| 58 | SLManualVer | smallint | YES | - | NAME-INFERRED | Stop-loss manual version. |
| 59 | FullCommission | money | YES | - | NAME-INFERRED | Full commission. |
| 60 | FullCommissionOnClose | int | YES | - | NAME-INFERRED | Commission on close. |
| 61 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redeem/bonus status. |
| 62 | IsSettled | bit | YES | - | CODE-BACKED | Settlement status. |
| 63 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type. |
| 64 | UnitsBaseValueCents | int | YES | - | NAME-INFERRED | Base value in cents. |
| 65 | IsDiscounted | bit | YES | - | NAME-INFERRED | Discount applied. |
| 66 | InitConversionRate | decimal(16,8) | YES | - | NAME-INFERRED | Initial forex conversion rate. |
| 67 | RedeemID | int | YES | - | CODE-BACKED | Redeem identifier. |
| 68 | PnLVersion | tinyint | YES | - | NAME-INFERRED | PnL calculation version. |
| 69 | IsNoStopLoss | bit | YES | - | CODE-BACKED | No stop-loss flag. |
| 70 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | No take-profit flag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID, InstrumentID, MirrorID, and other IDs semantically reference Customer, Instrument, Mirror, and related tables; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOpenPositionData | @PositionData | Local variable | Holds position snapshot for single PositionID lookup |
| Trade.GetUserAndPositionData | (via GetOpenPositionData) | Indirect | Calls GetOpenPositionData which uses this type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOpenPositionData | Stored Procedure | Local variable buffer for position data retrieval |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and use OpenPositionData in a procedure

```sql
DECLARE @PositionData Trade.OpenPositionData;
INSERT INTO @PositionData (PositionID, CID, InstrumentID, Amount, ...)
SELECT PositionID, CID, InstrumentID, Amount, ...
FROM Trade.PositionTbl
WHERE PositionID = @PositionID AND IsOpen = 1;
```

### 8.2 Call GetOpenPositionData (internal use of type)

```sql
EXEC Trade.GetOpenPositionData @PositionID = 123456789, @LockPosition = 0;
```

### 8.3 Get user and position data via wrapper

```sql
EXEC Trade.GetUserAndPositionData @PositionID = 123456789, @LockPosition = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 6.5/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 45 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionData | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OpenPositionData.sql*
