# Trade.InstrumentToFeeConfigType_TRDOPS

> TVP for bulk updates of instrument fee configurations in TRDOPS context, with SettlementTypeID and FeeCalculationTypeID for multi-settlement fee rules.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int), SettlementTypeID (tinyint) |
| **Partition** | N/A |
| **Indexes** | 1: PK on (InstrumentID, SettlementTypeID) |

---

## 1. Business Meaning

This type carries instrument fee configurations for the TRDOPS (trading operations) context: end-of-week and overnight fees for leveraged and non-leveraged positions, plus SettlementTypeID and FeeCalculationTypeID. It models the full fee rule set per instrument per settlement type, enabling different fee structures by settlement method.

The type exists to support Trade.UpdateInstrumentToFeeConfigurations_TRDOPS, which applies bulk fee config updates. Admin or config services populate the TVP when setting or changing fee rates for instruments across settlement types.

Services build the table, pass it as READONLY, and the procedure JOINs against it to apply fee config to Trade.InstrumentToFeeConfig or related tables. The clustered primary key enforces uniqueness per InstrumentID + SettlementTypeID.

---

## 2. Business Logic

InstrumentID + SettlementTypeID + FeeCalculationTypeID + fee columns. Each row represents one fee rule per instrument per settlement type; procedures merge or upsert based on the composite key.

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
| 10 | SettlementTypeID | tinyint | NO | 0 | CODE-BACKED | Identifies settlement type (e.g. cash, physical); part of composite key. |
| 11 | FeeCalculationTypeID | tinyint | NO | 0 | CODE-BACKED | Identifies how fees are calculated for this rule. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument. SettlementTypeID and FeeCalculationTypeID semantically reference lookup tables but there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | @InstrumentToFeeConfigUpdates | Parameter (TVP) | Receives bulk fee config and applies per instrument per settlement type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | Stored Procedure | READONLY parameter for bulk fee config updates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Description |
|------------|------|-------------|-------------|
| PK (clustered) | Clustered | InstrumentID, SettlementTypeID | Primary key; enforces uniqueness per instrument per settlement type |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Declare and pass to TRDOPS fee update procedure
```sql
DECLARE @Config Trade.InstrumentToFeeConfigType_TRDOPS;
INSERT INTO @Config (InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee, SettlementTypeID)
VALUES (12345, 0.0001, 0.0002, 0), (12345, 0.00015, 0.00025, 1);
EXEC Trade.UpdateInstrumentToFeeConfigurations_TRDOPS @InstrumentToFeeConfigUpdates = @Config;
```

### 8.2 Update all fee columns for one instrument
```sql
DECLARE @Config Trade.InstrumentToFeeConfigType_TRDOPS;
INSERT INTO @Config (InstrumentID, NonLeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee,
  NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee, LeveragedSellEndOfWeekFee,
  LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee, LeveragedSellOverNightFee,
  SettlementTypeID, FeeCalculationTypeID)
VALUES (99999, 0.001, 0.001, 0.0001, 0.0001, 0.002, 0.002, 0.0003, 0.0003, 0, 0);
EXEC Trade.UpdateInstrumentToFeeConfigurations_TRDOPS @InstrumentToFeeConfigUpdates = @Config;
```

### 8.3 Multi-settlement fee rules
```sql
DECLARE @Config Trade.InstrumentToFeeConfigType_TRDOPS;
INSERT INTO @Config (InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee, SettlementTypeID)
SELECT InstrumentID, 0.0001, 0.0002, 0 FROM Trade.Instrument WHERE Symbol IN ('AAPL','GOOGL');
EXEC Trade.UpdateInstrumentToFeeConfigurations_TRDOPS @InstrumentToFeeConfigUpdates = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentToFeeConfigType_TRDOPS | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentToFeeConfigType_TRDOPS.sql*
