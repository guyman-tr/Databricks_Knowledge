# Trade.OutputCustomer_ClosePosition_MOT

> A memory-optimized table-valued type used to capture customer-level OUTPUT data when closing positions - balances, commissions, hedge results, and position metadata for billing and mirror equity updates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (semantic - no PK) |
| **Partition** | N/A |
| **Indexes** | IX_CID (NONCLUSTERED on CID) |

---

## 1. Business Meaning

Trade.OutputCustomer_ClosePosition_MOT is a memory-optimized TVP type that holds customer-level data captured via OUTPUT clauses during position close operations. When Trade.PositionClose updates or closes positions, it uses OUTPUT INTO to populate this type with one row per affected customer - including amounts, commission, forex results, hedge trade metadata (Tr* columns), mirror/parent IDs, and settlement fields.

This type exists to support the close-position billing and mirror-equity flow. PositionClose populates @OutputCustomer from UPDATE/INSERT OUTPUT clauses, then aggregates or iterates over it to call Customer.SetBalanceClosePosition and update mirror equity. The memory-optimized design enables high-throughput close processing without disk I/O for the intermediate result set.

The type flows internally: Trade.PositionClose declares @OutputCustomer, populates it from OUTPUT, and uses it to drive balance updates. It is not passed as a parameter to other procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The Tr* columns (TrHedgeID, TrPositionID, TrCommission, etc.) group hedge/trade metadata; CID, MirrorID, ParentPositionID group customer and hierarchy context.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID - account receiving the balance impact from the close. |
| 2 | ForexResultID | bigint | YES | - | CODE-BACKED | Forex result record ID for the close. |
| 3 | Amount | money | YES | - | CODE-BACKED | Position amount in dollars for billing. |
| 4 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units (lots/shares). |
| 5 | ProviderID | int | YES | - | CODE-BACKED | Trade provider (hedge) identifier. |
| 6 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count for the closed position. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier. |
| 8 | TrHedgeID | int | YES | - | CODE-BACKED | Hedge trade ID for the close. |
| 9 | TrPositionID | bigint | YES | - | CODE-BACKED | Hedge position ID for the close. |
| 10 | TrCommission | money | YES | - | CODE-BACKED | Commission on the hedge trade. |
| 11 | TrNetProfit | int | YES | - | CODE-BACKED | Net profit in cents for the hedge trade. |
| 12 | TrLotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count for the hedge trade. |
| 13 | TrProviderID | int | YES | - | CODE-BACKED | Provider ID for the hedge trade. |
| 14 | TrInstrumentID | int | YES | - | CODE-BACKED | Instrument ID for the hedge trade. |
| 15 | TrCID | int | YES | - | CODE-BACKED | Customer ID on the hedge side. |
| 16 | TrForexResultID | bigint | YES | - | CODE-BACKED | Forex result ID for the hedge trade. |
| 17 | TrHedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID for the trade. |
| 18 | TrCommissionOnClose | money | YES | - | CODE-BACKED | Commission charged on close. |
| 19 | TrOpenOccurred | datetime | YES | - | CODE-BACKED | When the hedge position was opened. |
| 20 | TrCloseOccurred | datetime | YES | - | CODE-BACKED | When the hedge position was closed. |
| 21 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID if position was copied. |
| 22 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position ID in copy hierarchy. |
| 23 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before any detachment. |
| 24 | IsBuy | bit | YES | - | CODE-BACKED | 1=buy, 0=sell. |
| 25 | EndOfWeekFee | money | YES | - | CODE-BACKED | Overnight/weekend fee for the position. |
| 26 | OrderID | int | YES | - | CODE-BACKED | Order that opened the position. |
| 27 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Whether position was closed at end-of-week. |
| 28 | LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit rate if set. |
| 29 | StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss rate if set. |
| 30 | TradeRange | int | YES | - | CODE-BACKED | Trade range indicator. |
| 31 | RedeemStatus | int | YES | - | CODE-BACKED | Redeem status if position was redeemed. |
| 32 | RedeemID | int | YES | - | CODE-BACKED | Redeem record ID. |
| 33 | UnitsBaseValueInCents | int | YES | - | CODE-BACKED | Units base value in cents for PnL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID, InstrumentID, MirrorID, ParentPositionID, ProviderID, etc. semantically reference other tables; no FKs on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionClose | @OutputCustomer | Local variable (OUTPUT target) | Declares, populates via OUTPUT INTO, uses for SetBalanceClosePosition and mirror equity |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionClose | Stored Procedure | Local OUTPUT target for close-position billing flow |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns |
|-----------|------|-------------|
| IX_CID | NONCLUSTERED | CID ASC |

Memory-optimized (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and use as OUTPUT target (conceptual)

```sql
-- Inside Trade.PositionClose:
DECLARE @OutputCustomer Trade.OutputCustomer_ClosePosition_MOT;
-- Populated via OUTPUT INTO from UPDATE/INSERT; used to drive balance updates
```

### 8.2 Inspect structure for debugging

```sql
SELECT c.name, t.name AS type_name
FROM   sys.table_types tt
       JOIN sys.columns c ON c.object_id = tt.type_table_object_id
       JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE  tt.name = 'OutputCustomer_ClosePosition_MOT';
```

### 8.3 Join pattern used in PositionClose

```sql
-- PositionClose aggregates from @OutputCustomer to call SetBalanceClosePosition per CID/PositionID
SELECT  OC.CID, OC.Amount, ...
FROM    @OutputCustomer OC
WHERE   ...
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OutputCustomer_ClosePosition_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OutputCustomer_ClosePosition_MOT.sql*
