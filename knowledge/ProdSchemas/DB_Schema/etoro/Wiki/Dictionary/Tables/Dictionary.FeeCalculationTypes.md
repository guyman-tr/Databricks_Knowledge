# Dictionary.FeeCalculationTypes

> System-versioned lookup table defining the mathematical formulas used to calculate trading fees — exposure-based ($/unit) or loan-based (daily interest %).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (System-Versioned / Temporal) |
| **Key Identifier** | FeeCalculationTypeID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **History Table** | History.FeeCalculationTypes |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FeeCalculationTypes defines the two fundamental mathematical approaches the platform uses to calculate trading fees on instruments. Every instrument's fee configuration includes a calculation type that determines whether the fee is computed as a fixed amount per unit of exposure (like a spread markup per lot) or as a daily interest percentage on the loan portion of a leveraged position.

This distinction is fundamental to the platform's fee engine: exposure-based fees (type 0) are applied as a markup on the trade's notional value in dollars per unit, while loan-based fees (type 1) are applied as a daily interest rate on the borrowed portion of a leveraged position. The same instrument can have both types configured for different fee categories.

The table is consumed by `Trade.CalcOverNightFeeRates` (overnight fee computation), `Trade.GetCalculatedFeesConfig_TRDOPS` (fee configuration retrieval), `Trade.CalculatePositionOvernightFee` (position-level fee calc), and instrument setup procedures. Being system-versioned, all changes are audited via `History.FeeCalculationTypes`.

---

## 2. Business Logic

### 2.1 Fee Formula Selection

**What**: Each calculation type determines the mathematical formula used to compute the fee amount.

**Columns/Parameters Involved**: `FeeCalculationTypeID`, `FeeCalculationTypeName`, `Description`

**Rules**:
- **ExposureFormula (0)**: Fee = Units × Value ($/unit). The fee configuration stores a dollar-per-unit value. Fee is proportional to position size. Used for spread markups and commission-like charges.
- **LoanFormula (1)**: Fee = (Leveraged Amount × Daily Interest Rate). The fee configuration stores a daily interest percentage. Fee is proportional to the borrowed amount. Used for overnight financing/rollover fees.

### 2.2 Instrument-Level Fee Configuration

**What**: Each instrument is mapped to fee calculation types via Trade.InstrumentToFeeConfigV2.

**Columns/Parameters Involved**: `FeeCalculationTypeID`

**Rules**:
- An instrument can have multiple fee configurations with different calculation types
- The trading engine selects the appropriate formula based on the calculation type when computing fees
- Changes to calculation types are audited via temporal versioning — critical for reconciling historical fee amounts

**Diagram**:
```
Instrument Fee Configuration
        │
        ├── FeeCalculationTypeID = 0 (ExposureFormula)
        │   Fee = Units × $/unit
        │   Example: 100 units × $0.05/unit = $5.00 fee
        │
        └── FeeCalculationTypeID = 1 (LoanFormula)
            Fee = LeveragedAmount × DailyInterest%
            Example: $10,000 loan × 0.03% = $3.00/day
```

---

## 3. Data Overview

| FeeCalculationTypeID | FeeCalculationTypeName | Description | Meaning |
|---|---|---|---|
| 0 | ExposureFormula | Exposure calculation. Values are $/unit | Fee computed as a fixed dollar amount per unit of the instrument traded. Applied to the position's notional exposure. Typical for spread-based charges and per-lot commissions. |
| 1 | LoanFormula | Loan calculation. Values are dailyInterest (%) | Fee computed as a daily interest rate on the leveraged (borrowed) portion of the position. Applied nightly for overnight financing charges. Typical for swap/rollover fees. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeeCalculationTypeID | tinyint | NO | - | VERIFIED | Fee formula identifier: **0**=ExposureFormula ($/unit — fee proportional to position size), **1**=LoanFormula (daily interest % — fee proportional to borrowed amount). Referenced by Trade.InstrumentToFeeConfigV2, Trade.CalcOverNightFeeRates, and fee configuration procedures. |
| 2 | FeeCalculationTypeName | varchar(50) | NO | - | VERIFIED | Machine-readable formula name: "ExposureFormula", "LoanFormula". Used in trading engine configuration. |
| 3 | Description | varchar(max) | NO | - | VERIFIED | Human-readable explanation of the formula and the unit of the fee values: "Values are $/unit" or "Values are dailyInterest (%)". |
| 4 | DbLoginName | computed | NO | - | CODE-BACKED | Computed: `suser_name()`. SQL Server login that last modified the row. Audit trail. |
| 5 | AppLoginName | computed | NO | - | CODE-BACKED | Computed: `CONVERT(varchar(500), context_info())`. Application-level identity from session CONTEXT_INFO. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | Temporal row start — when this version became active. GENERATED ALWAYS AS ROW START. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | Temporal row end — when superseded. Active rows: 9999-12-31. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentToFeeConfigV2 | FeeCalculationTypeID | Implicit | Maps instruments to fee calculation formulas |
| Trade.CalcOverNightFeeRates | FeeCalculationTypeID | Read | Selects formula for overnight fee computation |
| Trade.CalcOverNightFeeRates_TRDOPS | FeeCalculationTypeID | Read | Trading Ops version |
| Trade.CalculatePositionOvernightFee | FeeCalculationTypeID | Read | Position-level overnight fee calculation function |
| Trade.GetCalculatedFeesConfig_TRDOPS | FeeCalculationTypeID | Read | Returns fee configs with formula type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.FeeCalculationTypes (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | References FeeCalculationTypeID |
| History.FeeCalculationTypes | Table | Temporal history table |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reads calculation type for fee formula selection |
| Trade.CalculatePositionOvernightFee | Function | Uses calculation type in overnight fee computation |
| Trade.GetCalculatedFeesConfig_TRDOPS | Stored Procedure | Returns fee configs with formula type |
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | Stored Procedure | Writes fee calculation type for instruments |
| Trade.InsertInstrumentRealTable | Stored Procedure | Sets initial fee calculation type for new instruments |
| Trade.CheckValidInstruments | Stored Procedure | Validates instrument fee configuration |
| Trade.SplitHoldingFees | Stored Procedure | Reads calculation type during fee splitting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_FeeCalculationTypes | CLUSTERED PK | FeeCalculationTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_FeeCalculationTypes | PRIMARY KEY | Unique fee calculation type, DICTIONARY filegroup |
| SYSTEM_TIME PERIOD | TEMPORAL | SysStartTime to SysEndTime — automatic version tracking |

---

## 8. Sample Queries

### 8.1 List all fee calculation formulas
```sql
SELECT  FeeCalculationTypeID,
        FeeCalculationTypeName,
        Description
FROM    Dictionary.FeeCalculationTypes WITH (NOLOCK)
ORDER BY FeeCalculationTypeID;
```

### 8.2 Count instruments by fee calculation type
```sql
SELECT  fct.FeeCalculationTypeName,
        COUNT(DISTINCT itfc.InstrumentID) AS InstrumentCount
FROM    Trade.InstrumentToFeeConfigV2 itfc WITH (NOLOCK)
JOIN    Dictionary.FeeCalculationTypes fct WITH (NOLOCK)
        ON itfc.FeeCalculationTypeID = fct.FeeCalculationTypeID
GROUP BY fct.FeeCalculationTypeName;
```

### 8.3 View fee calculation type change history
```sql
SELECT  FeeCalculationTypeID,
        FeeCalculationTypeName,
        Description,
        SysStartTime,
        SysEndTime
FROM    Dictionary.FeeCalculationTypes
FOR SYSTEM_TIME ALL
ORDER BY FeeCalculationTypeID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FeeCalculationTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FeeCalculationTypes.sql*
