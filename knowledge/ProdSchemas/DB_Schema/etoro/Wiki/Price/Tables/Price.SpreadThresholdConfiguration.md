# Price.SpreadThresholdConfiguration

> Per-instrument stepped spread markup configuration that applies additional bid or ask markup amounts when the instrument's price crosses defined threshold levels, supporting tiered spread adjustments based on direction (buy/sell) and price movement type.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, IsBuy, ThresholdAmount, IsIncrease) - 4-column composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

SpreadThresholdConfiguration defines conditional spread markup rules for instruments. When an instrument's price changes, this table provides rules of the form: "IF the price changes by at least ThresholdAmount in the direction indicated by IsIncrease, AND the change is in the buy (IsBuy=1) or sell (IsBuy=0) direction, THEN apply an additional Markup to the bid or ask."

This creates a tiered or stepped spread model where larger price movements attract wider spreads - a risk management mechanism that widens the bid/ask spread automatically during volatile price action. The `SpreadThresholdTypeID` classifies the spread adjustment type: 1=NOP (Net Open Position-based spread, default) or 2=NOE (Net Open Exposure-based spread).

The table has three ASM-generated audit triggers (Delete/Insert/Update) writing to `History.AuditHistory` - all DML is fully audited. No temporal versioning is used (unlike most Price tables), but audit history is preserved via the trigger mechanism.

The table is currently empty (0 rows). No conditional spread configurations are active.

---

## 2. Business Logic

### 2.1 Directional Stepped Spread Markup

**What**: Each row defines a threshold condition for applying an additional price markup, varying by instrument, trade direction, threshold level, and movement direction.

**Columns/Parameters Involved**: `InstrumentID`, `IsBuy`, `ThresholdAmount`, `IsIncrease`, `Markup`, `SpreadThresholdTypeID`

**Rules**:
- 4-column composite PK: (InstrumentID, IsBuy, ThresholdAmount, IsIncrease) - multiple rows per instrument create a stepped function
- IsBuy=1: markup applies to ask price (buy orders); IsBuy=0: markup applies to bid price (sell orders)
- IsIncrease=1 (default): threshold applies when the price is increasing; IsIncrease=0: when decreasing
- ThresholdAmount: the minimum price change magnitude to trigger this markup rule
- Markup: the additional spread amount to add when the threshold is triggered. decimal(8,4) - supports precision down to 0.0001 pips
- SpreadThresholdTypeID FK -> Dictionary.SpreadThresholdType: 1=NOP (Net Open Position), 2=NOE (Net Open Exposure). Default=1 (NOP)

### 2.2 Threshold Evaluation Pattern

**Diagram**:
```
Price movement of ThresholdAmount in IsIncrease direction
    |
    v
IsBuy=1 (ask affected): Apply additional Markup to ask price -> wider ask for buyers during volatility
IsBuy=0 (bid affected): Apply additional Markup to bid price -> wider bid for sellers during volatility

Multiple thresholds per instrument form a stepped function:
ThresholdAmount=1.0 -> Markup=0.0010
ThresholdAmount=5.0 -> Markup=0.0025 (larger move = wider extra spread)
ThresholdAmount=10.0 -> Markup=0.0050
```

---

## 3. Data Overview

The table is currently empty (0 rows). No spread threshold configurations are active.

*When populated, rows would appear as:*

| InstrumentID | IsBuy | ThresholdAmount | Markup | IsIncrease | SpreadThresholdTypeID | Meaning |
|---|---|---|---|---|---|---|
| 1 (EUR/USD) | 1 (ask) | 1.0000 | 0.0001 | 1 (rising) | 1 (NOP) | When EUR/USD rises 1 pip, add 0.1 pip to ask |
| 1 (EUR/USD) | 1 (ask) | 5.0000 | 0.0003 | 1 (rising) | 1 (NOP) | When EUR/USD rises 5 pips, add 0.3 pip to ask (escalating) |
| 1 (EUR/USD) | 0 (bid) | 1.0000 | 0.0001 | 0 (falling) | 1 (NOP) | When EUR/USD falls 1 pip, add 0.1 pip to bid |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. FK to Trade.Instrument. The instrument to which this spread markup rule applies. (Trade.Instrument) |
| 2 | IsBuy | bit | NOT NULL | - | VERIFIED | Part 2 of composite PK. Determines which side of the spread is affected: 1=buy side (ask price), 0=sell side (bid price). Allows separate configurations for bid and ask spread widening. |
| 3 | ThresholdAmount | decimal(14,4) | NOT NULL | - | VERIFIED | Part 3 of composite PK. The minimum price movement magnitude (in instrument price units, e.g., pips) required to trigger this markup rule. Multiple rows with different ThresholdAmounts create a stepped spread function. |
| 4 | IsIncrease | bit | NOT NULL | 1 | VERIFIED | Part 4 of composite PK. Direction of price movement that triggers this rule: 1=price increasing (default), 0=price decreasing. Allows directionally asymmetric spread adjustment. Default=1. |
| 5 | Markup | decimal(8,4) | NOT NULL | - | VERIFIED | The additional spread markup amount to apply when this threshold condition is met. In instrument price units (pips for FX). Added to bid or ask depending on IsBuy. |
| 6 | SpreadThresholdTypeID | int | NOT NULL | 1 | VERIFIED | FK to Dictionary.SpreadThresholdType. The type of spread threshold calculation: 1=NOP (Net Open Position - based on aggregate client position), 2=NOE (Net Open Exposure - based on total exposure value). Default=1. (Dictionary.SpreadThresholdType) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_SpreadConfiguration_InstrumentID) | The instrument for which spread thresholds are configured |
| SpreadThresholdTypeID | Dictionary.SpreadThresholdType | FK (FK_SpreadThresholdConfiguration_SpreadThresholdTypeID) | The threshold calculation type: 1=NOP, 2=NOE |

### 5.2 Referenced By (other objects point to this)

No dependents found. The table is currently not referenced by any stored procedures or views in the Price schema SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SpreadThresholdConfiguration (table)
|- Trade.Instrument (table, FK target - leaf)
|- Dictionary.SpreadThresholdType (table, FK target: 1=NOP, 2=NOE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Dictionary.SpreadThresholdType | Table | FK target - SpreadThresholdTypeID must be 1 (NOP) or 2 (NOE) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SpreadConfiguration | CLUSTERED PK | InstrumentID ASC, IsBuy ASC, ThresholdAmount ASC, IsIncrease ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SpreadConfiguration | PRIMARY KEY | Composite 4-column PK: one markup per (instrument, buy/sell, threshold level, direction) |
| FK_SpreadConfiguration_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_SpreadThresholdConfiguration_SpreadThresholdTypeID | FK | SpreadThresholdTypeID -> Dictionary.SpreadThresholdType(SpreadThresholdTypeID) |
| Default_SpreadThresholdConfiguration_IsIncrease | DEFAULT | IsIncrease = 1 |
| DF_SpreadThresholdConfiguration_SpreadThresholdTypeID | DEFAULT | SpreadThresholdTypeID = 1 (NOP) |
| AuditDelete_Price_SpreadThresholdConfiguration | TRIGGER (DELETE) | ASM audit: writes deleted rows to History.AuditHistory |
| AuditInsert_Price_SpreadThresholdConfiguration | TRIGGER (INSERT) | ASM audit: writes inserted rows to History.AuditHistory |
| AuditUpdate_Price_SpreadThresholdConfiguration | TRIGGER (UPDATE) | ASM audit: writes updated values to History.AuditHistory |

---

## 8. Sample Queries

### 8.1 View all spread threshold rules per instrument

```sql
SELECT
    STC.InstrumentID,
    STC.IsBuy,
    CASE STC.IsBuy WHEN 1 THEN 'Ask (Buy)' ELSE 'Bid (Sell)' END AS Side,
    STC.ThresholdAmount,
    STC.Markup,
    CASE STC.IsIncrease WHEN 1 THEN 'Price Rising' ELSE 'Price Falling' END AS TriggerDirection,
    STT.Name AS SpreadType
FROM Price.SpreadThresholdConfiguration STC WITH (NOLOCK)
JOIN Dictionary.SpreadThresholdType STT WITH (NOLOCK)
    ON STT.SpreadThresholdTypeID = STC.SpreadThresholdTypeID
ORDER BY STC.InstrumentID, STC.IsBuy, STC.ThresholdAmount;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 6, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SpreadThresholdConfiguration | Type: Table | Source: etoro/etoro/Price/Tables/Price.SpreadThresholdConfiguration.sql*
