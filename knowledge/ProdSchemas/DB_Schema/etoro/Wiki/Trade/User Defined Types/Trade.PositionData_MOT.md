# Trade.PositionData_MOT

> A memory-optimized table-valued type carrying position snapshots for mirror/API data retrieval, used when fetching position data by CID or CID+MirrorID for external consumers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (semantic - no PK) |
| **Partition** | N/A |
| **Indexes** | IX_PositionID, IX_ParentPositionID_MirrorID (NONCLUSTERED) |

---

## 1. Business Meaning

Trade.PositionData_MOT is a memory-optimized TVP type that carries position snapshot data - a wide row per position with fields mirroring Trade.Position. It is used as a local table variable in procedures that fetch position data for APIs (GetMirrorDataWithCIDForAPI, GetMirrorDataWithCIDAndMirrorIdForAPI). The procedure SELECTs from Trade.Position into this type, then returns or processes the result set.

This type exists to support the mirror data API flow, which needs to return position details to external systems. The memory-optimized design allows high-throughput reads without disk I/O for the intermediate result. The indexes on PositionID and (ParentPositionID, MirrorID) support JOINs and lookups when the data is used within the procedure.

The type flows internally: procedures declare @PositionData, populate it from SELECT INTO, and use it for API output or further processing. It is not passed as a parameter between procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. PositionID, CID, MirrorID, ParentPositionID, InstrumentID group core identifiers; IsBuy, Amount, LotCountDecimal, StopRate, LimitRate group trading attributes; OpenTotalTaxes, OpenTotalFees, EndOfWeekFee group fee/tax fields.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | Position identifier. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID. |
| 3 | IsBuy | bit | YES | - | CODE-BACKED | 1=buy, 0=sell. |
| 4 | Amount | money | YES | - | CODE-BACKED | Position amount. |
| 5 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 6 | InitForexRate | decimal(16,8) | YES | - | CODE-BACKED | Opening forex rate. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier. |
| 8 | Leverage | int | YES | - | CODE-BACKED | Leverage applied. |
| 9 | LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit rate. |
| 10 | StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss rate. |
| 11 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. |
| 12 | OrderID | int | YES | - | CODE-BACKED | Opening order ID. |
| 13 | OrderType | int | YES | - | CODE-BACKED | Order type. |
| 14 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in copy hierarchy. |
| 15 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Size in units. |
| 16 | EndOfWeekFee | money | YES | - | CODE-BACKED | Overnight/weekend fee. |
| 17 | InitialAmountInDollars | decimal(16,8) | YES | - | CODE-BACKED | Initial dollar amount. |
| 18 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop enabled. |
| 19 | StopLossVersion | smallint | YES | - | CODE-BACKED | SL version for TSL. |
| 20 | TreeID | bigint | YES | - | CODE-BACKED | Tree identifier for copy hierarchy. |
| 21 | IsSettled | bit | YES | - | CODE-BACKED | Settlement status. |
| 22 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type. |
| 23 | RedeemStatus | int | YES | - | CODE-BACKED | Redeem status. |
| 24 | InitialUnits | decimal(16,8) | YES | - | CODE-BACKED | Initial unit count. |
| 25 | UnitsBaseValueDollars | decimal(16,8) | YES | - | CODE-BACKED | Units base value in dollars. |
| 26 | IsDiscounted | bit | YES | - | CODE-BACKED | Discount applied. |
| 27 | OpenActionType | int | YES | - | CODE-BACKED | Open action type. |
| 28 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before detachment. |
| 29 | InitConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Opening conversion rate. |
| 30 | PnLVersion | tinyint | YES | - | CODE-BACKED | PnL calculation version. |
| 31 | OpenTotalTaxes | money | NO | - | CODE-BACKED | Taxes on open. |
| 32 | OpenTotalFees | money | NO | - | CODE-BACKED | Fees on open. |
| 33 | IsNoStopLoss | bit | YES | - | CODE-BACKED | No SL set. |
| 34 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | No TP set. |
| 35 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Columns semantically reference Trade.Position, Customer, Instrument; no declared FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMirrorDataWithCIDForAPI | @PositionData | Local variable | Fetches mirror positions for API by CID |
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | @PositionData | Local variable | Fetches mirror positions for API by CID and MirrorID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMirrorDataWithCIDForAPI | Stored Procedure | Local table variable for mirror data fetch |
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Stored Procedure | Local table variable for mirror data fetch |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns |
|-----------|------|-------------|
| IX_PositionID | NONCLUSTERED | PositionID ASC |
| IX_ParentPositionID_MirrorID | NONCLUSTERED | ParentPositionID ASC, MirrorID ASC |

Memory-optimized (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate from Position (conceptual)

```sql
DECLARE @PositionData Trade.PositionData_MOT;
INSERT INTO @PositionData
SELECT PositionID, CID, IsBuy, Amount, InitDateTime, InitForexRate, InstrumentID, Leverage, ...
FROM   Trade.Position WITH (NOLOCK)
WHERE  CID = @CID AND MirrorID = @MirrorID;
```

### 8.2 Inspect type structure

```sql
SELECT c.name, t.name FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'PositionData_MOT';
```

### 8.3 Join by ParentPositionID and MirrorID

```sql
SELECT * FROM @PositionData pd
WHERE pd.ParentPositionID = @ParentID AND pd.MirrorID = @MirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionData_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionData_MOT.sql*
