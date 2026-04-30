# Trade.InstrumentsTradingConfigTblTmp

> TVP type for bulk updates of instrument trading configuration (subset of InstrumentsTradingConfigTbl) used by temporary or staging update procedures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries a reduced set of instrument trading configuration fields for bulk updates. It models the same domain concept as InstrumentsTradingConfigTbl but omits several columns (e.g. MarketRange, DesignatedExecutionSystem, Precision, Redeem-related columns, and some leveraged/non-leveraged overrides). It is used where a smaller footprint is sufficient or where the full config set is not needed.

The type exists to support Trade.UpdateInstrumentsTradingConfigurationsTmp, which applies trading config updates from a streamlined payload. This allows staging or temporary update workflows that do not require the full configuration surface.

Services or batch jobs populate the TVP with instrument IDs and the configuration values to apply, pass it to the procedure, and the procedure JOINs it against provider-instrument tables to apply updates.

---

## 2. Business Logic

InstrumentID + configuration column group pattern. Each row represents one instrument with its trading-related settings (SL/TP limits, order flags, trailing stop, leveraged vs non-leveraged overrides). The procedure applies these values in bulk to the target tables.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier; references Trade.Instrument |
| 2 | MaxStopLossPercentage | decimal(18,4) | YES | - | CODE-BACKED | Maximum allowed stop-loss percentage |
| 3 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Maximum position size in units |
| 4 | MinPositionAmount | decimal(18,4) | YES | - | CODE-BACKED | Minimum position amount |
| 5 | MaxRateDiffPercentage | decimal(18,4) | YES | - | CODE-BACKED | Maximum allowed rate difference percentage |
| 6 | AllowBuy | bit | YES | - | CODE-BACKED | Whether buy orders are allowed |
| 7 | AllowSell | bit | YES | - | CODE-BACKED | Whether sell orders are allowed |
| 8 | AllowPendingOrders | bit | YES | - | CODE-BACKED | Whether pending orders are allowed |
| 9 | AllowEntryOrders | bit | YES | - | CODE-BACKED | Whether entry orders are allowed |
| 10 | VisibleInternallyOnly | bit | YES | - | CODE-BACKED | Visibility restricted to internal use |
| 11 | AllowClosePosition | bit | YES | - | CODE-BACKED | Whether closing positions is allowed |
| 12 | AllowExitOrder | bit | YES | - | CODE-BACKED | Whether exit orders are allowed |
| 13 | GuaranteeSLTP | bit | YES | - | CODE-BACKED | Whether SL/TP is guaranteed |
| 14 | AllowEditSLTP | bit | YES | - | CODE-BACKED | Whether SL/TP can be edited |
| 15 | MaxTakeProfitPercentage | decimal(18,4) | YES | - | CODE-BACKED | Maximum take-profit percentage |
| 16 | MinStopLossPercentage | decimal(18,4) | YES | - | CODE-BACKED | Minimum stop-loss percentage |
| 17 | MinTakeProfitPercentage | decimal(18,4) | YES | - | CODE-BACKED | Minimum take-profit percentage |
| 18 | DefaultStopLossPercentage | decimal(18,4) | YES | - | CODE-BACKED | Default stop-loss percentage |
| 19 | DefaultTakeProfitPercentage | decimal(18,4) | YES | - | CODE-BACKED | Default take-profit percentage |
| 20 | AllowTrailingStopLoss | bit | YES | - | CODE-BACKED | Whether trailing stop-loss is allowed |
| 21 | DefaultTrailingStopLoss | bit | YES | - | CODE-BACKED | Default trailing stop-loss setting |
| 22 | AllowEditStopLoss | bit | YES | - | CODE-BACKED | Whether stop-loss can be edited |
| 23 | AllowEditTakeProfit | bit | YES | - | CODE-BACKED | Whether take-profit can be edited |
| 24 | AllowLeveragedLongSL | bit | YES | - | CODE-BACKED | Long SL allowed for leveraged |
| 25 | AllowNonLeveragedLongSL | bit | YES | - | CODE-BACKED | Long SL allowed for non-leveraged |
| 26 | AllowLeveragedShortSL | bit | YES | - | CODE-BACKED | Short SL allowed for leveraged |
| 27 | AllowNonLeveragedShortSL | bit | YES | - | CODE-BACKED | Short SL allowed for non-leveraged |
| 28 | AllowLeveragedLongTP | bit | YES | - | CODE-BACKED | Long TP allowed for leveraged |
| 29 | AllowNonLeveragedLongTP | bit | YES | - | CODE-BACKED | Long TP allowed for non-leveraged |
| 30 | AllowLeveragedShortTP | bit | YES | - | CODE-BACKED | Short TP allowed for leveraged |
| 31 | AllowNonLeveragedShortTP | bit | YES | - | CODE-BACKED | Short TP allowed for non-leveraged |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsTradingConfigurationsTmp | @InstrumentNewConfigTbl | Parameter (TVP) | Bulk update of instrument trading configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsTradingConfigurationsTmp | Stored Procedure | READONLY parameter for bulk trading config updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to update procedure
```sql
DECLARE @Config Trade.InstrumentsTradingConfigTblTmp;
INSERT INTO @Config (InstrumentID, MaxStopLossPercentage, AllowBuy, AllowSell)
VALUES (12345, 50.0, 1, 1);
EXEC Trade.UpdateInstrumentsTradingConfigurationsTmp @InstrumentNewConfigTbl = @Config;
```

### 8.2 Bulk update from source table
```sql
DECLARE @Config Trade.InstrumentsTradingConfigTblTmp;
INSERT INTO @Config (InstrumentID, MaxStopLossPercentage, MinPositionAmount)
SELECT InstrumentID, 40.0, 0.01 FROM Trade.Instrument WHERE IndustryID = 1;
EXEC Trade.UpdateInstrumentsTradingConfigurationsTmp @InstrumentNewConfigTbl = @Config;
```

### 8.3 Minimal config override
```sql
DECLARE @Config Trade.InstrumentsTradingConfigTblTmp;
INSERT INTO @Config (InstrumentID, AllowBuy, AllowSell)
VALUES (999, 1, 1);
EXEC Trade.UpdateInstrumentsTradingConfigurationsTmp @InstrumentNewConfigTbl = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsTradingConfigTblTmp | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsTradingConfigTblTmp.sql*
