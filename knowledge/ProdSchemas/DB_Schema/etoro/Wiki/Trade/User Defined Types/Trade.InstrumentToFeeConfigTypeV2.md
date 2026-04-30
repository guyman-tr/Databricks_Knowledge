# Trade.InstrumentToFeeConfigTypeV2

> TVP for bulk updates and internal use of instrument fee configurations with SettlementTypeID and FeeCalculationTypeID, used by fee calculation and update procedures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type extends the original InstrumentToFeeConfigType with SettlementTypeID and FeeCalculationTypeID. It carries end-of-week and overnight fees for leveraged and non-leveraged positions per instrument per settlement type. It models the full fee rule set needed for fee calculations and config updates.

The type exists to support Trade.UpdateInstrumentToFeeConfigTableV2 (TVP parameter), Trade.UpdateInstrumentToFeeConfigTable (internal variable), Trade.CalcOverNightFeeRates, Trade.CalcOverNightFeeRates_TRDOPS, Trade.SplitHoldingFees, and Trade.Elad111. Services or procedures populate it for bulk fee config updates or as an intermediate table for fee calculations.

Services pass it as READONLY to update procedures, or procedures declare it as a variable and populate it from queries before passing to fee calculation logic.

---

## 2. Business Logic

InstrumentID + SettlementTypeID + FeeCalculationTypeID + fee columns. Each row represents one fee rule per instrument per settlement type; procedures use it for upserts or join-based fee calculations.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument. |
| 2 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for non-leveraged sell positions. |
| 3 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for non-leveraged buy positions. |
| 4 | NonLeveragedBuyOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee rate for non-leveraged buy positions. |
| 5 | NonLeveragedSellOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee rate for non-leveraged sell positions. |
| 6 | LeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for leveraged sell positions. |
| 7 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for leveraged buy positions. |
| 8 | LeveragedBuyOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee rate for leveraged buy positions. |
| 9 | LeveragedSellOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee rate for leveraged sell positions. |
| 10 | SettlementTypeID | tinyint | NO | 0 | CODE-BACKED | Identifies settlement type (e.g. cash, physical). |
| 11 | FeeCalculationTypeID | tinyint | NO | 0 | CODE-BACKED | Identifies how fees are calculated for this rule. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument. SettlementTypeID and FeeCalculationTypeID semantically reference lookup tables but there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentToFeeConfigTableV2 | @FeeValuesTbl | Parameter (TVP) | Receives bulk fee config and applies to InstrumentToFeeConfig |
| Trade.UpdateInstrumentToFeeConfigTable | @FeeValuesTblV2 | Variable | Internal variable; converts from v1 type and applies |
| Trade.CalcOverNightFeeRates | @FeeValuesTbl | Variable | Holds fee data for overnight fee calculation |
| Trade.CalcOverNightFeeRates_TRDOPS | @FeeValuesTbl | Variable | Holds fee data for TRDOPS overnight fee calculation |
| Trade.SplitHoldingFees | @FeeValuesTbl | Variable | Holds fee data for fee split logic |
| Trade.Elad111 | @FeeValuesTbl | Variable | Internal/test procedure using fee data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentToFeeConfigTableV2 | Stored Procedure | READONLY parameter for bulk fee config updates |
| Trade.UpdateInstrumentToFeeConfigTable | Stored Procedure | Internal variable for fee conversion and update |
| Trade.CalcOverNightFeeRates | Stored Procedure | Internal variable for overnight fee calculation |
| Trade.CalcOverNightFeeRates_TRDOPS | Stored Procedure | Internal variable for TRDOPS overnight fee calculation |
| Trade.SplitHoldingFees | Stored Procedure | Internal variable for fee split logic |
| Trade.Elad111 | Stored Procedure | Internal variable for fee data processing |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to V2 update procedure
```sql
DECLARE @Fee Trade.InstrumentToFeeConfigTypeV2;
INSERT INTO @Fee (InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee, SettlementTypeID)
VALUES (12345, 0.0001, 0.0002, 0), (12346, 0.00015, 0.00025, 0);
EXEC Trade.UpdateInstrumentToFeeConfigTableV2 @FeeValuesTbl = @Fee;
```

### 8.2 Use as variable in fee calculation
```sql
DECLARE @FeeValuesTbl Trade.InstrumentToFeeConfigTypeV2;
INSERT INTO @FeeValuesTbl (InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee,
  NonLeveragedSellOverNightFee, LeveragedSellOverNightFee, NonLeveragedBuyEndOfWeekFee,
  NonLeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee,
  SettlementTypeID, FeeCalculationTypeID)
SELECT InstrumentID, BuyOverNightFee, BuyOverNightFee, SellOverNightFee, SellOverNightFee,
  BuyEOWFee, SellEOWFee, BuyEOWFee, SellEOWFee, 0, 0
FROM Trade.InstrumentToFeeConfig WHERE SettlementTypeID = 0;
-- Pass to procedure that consumes @FeeValuesTbl
```

### 8.3 Bulk update from config table
```sql
DECLARE @Fee Trade.InstrumentToFeeConfigTypeV2;
INSERT INTO @Fee (InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee,
  NonLeveragedSellOverNightFee, LeveragedSellOverNightFee, NonLeveragedBuyEndOfWeekFee,
  NonLeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee,
  SettlementTypeID, FeeCalculationTypeID)
SELECT InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee,
  NonLeveragedSellOverNightFee, LeveragedSellOverNightFee, NonLeveragedBuyEndOfWeekFee,
  NonLeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee,
  SettlementTypeID, FeeCalculationTypeID
FROM Staging.InstrumentFeeUpdates;
EXEC Trade.UpdateInstrumentToFeeConfigTableV2 @FeeValuesTbl = @Fee;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentToFeeConfigTypeV2 | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentToFeeConfigTypeV2.sql*
