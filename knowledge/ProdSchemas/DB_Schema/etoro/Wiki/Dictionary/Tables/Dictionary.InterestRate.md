# Dictionary.InterestRate

> System-versioned configuration table storing overnight interest/swap rates per currency, instrument type, and settlement model — the core rate data driving daily position financing charges.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (System-Versioned / Temporal) |
| **Key Identifier** | InterestRateID + InstrumentTypeID + SettlementTypeID (composite PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **History Table** | History.InterestRate |
| **Indexes** | 1 active (composite PK only) |

---

## 1. Business Meaning

Dictionary.InterestRate stores the overnight interest (swap/rollover) rates used to calculate daily financing charges on open positions. Each row defines the buy and sell interest rates plus markup values for a specific combination of currency (InterestRateID), instrument type (e.g., CFD, real stock, crypto), and settlement model (CFD, real, TRS).

This is the primary rate table consumed by the overnight fee engine. Every night, `Trade.CalcOverNightFeeRates` reads these rates, applies the OverNightFeePatternID logic, and computes the daily charge for every open position. The split into buy vs. sell rates reflects that long (buy) and short (sell) positions typically have different financing costs. Markup values add the broker's margin on top of the base interest rate.

Being system-versioned, every rate change is automatically tracked in `History.InterestRate`. This is critical for regulatory audits and for recalculating historical fees — the temporal query `FOR SYSTEM_TIME AS OF` can retrieve the exact rate in effect on any past date.

---

## 2. Business Logic

### 2.1 Rate Structure

**What**: Each rate record provides separate buy/sell base rates and markups, enabling asymmetric financing charges for long and short positions.

**Columns/Parameters Involved**: `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`, `InterestRate`

**Rules**:
- **InterestRateBuy**: Base overnight rate for long (buy) positions. Positive = customer pays; negative = customer earns (swap credit).
- **InterestRateSell**: Base overnight rate for short (sell) positions.
- **MarkupBuy/MarkupSell**: Broker's margin added to the base rate. Total customer rate = base rate + markup.
- **InterestRate** (legacy): Historical single rate field, retained for backward compatibility. Set to 0 in current records.
- Rate interpretation depends on the FeeCalculationType of the instrument (see Dictionary.FeeCalculationTypes).

### 2.2 Multi-Dimensional Key

**What**: Rates are keyed by currency × instrument type × settlement type, enabling different rates for the same currency across different trading products.

**Columns/Parameters Involved**: `InterestRateID`, `InstrumentTypeID`, `SettlementTypeID`

**Rules**:
- Same currency (e.g., IR USD, ID=1) can have different rates for CFD (InstrumentTypeID=4), real stock (type=5), crypto (type=6)
- Same currency + instrument type can have different rates for CFD settlement (SettlementTypeID=0) vs. real settlement (type=4) vs. TRS (type=5)
- OverNightFeePatternID determines which calculation algorithm applies (Regular, WithNonLeverageFee, Manual)

**Diagram**:
```
Currency (InterestRateID=1, IR USD)
├── InstrumentType=4 (CFD), Settlement=0 → Rate: Buy=0.93, Sell=0.73, Pattern=WithNonLeverageFee
├── InstrumentType=4 (CFD), Settlement=4 → Rate: Buy=-0.81, Sell=0.12, Pattern=Manual
├── InstrumentType=5, Settlement=0 → Rate: Buy=0.10, Sell=0.10, Pattern=Regular
├── InstrumentType=5, Settlement=5 → Rate: Buy=0.04, Sell=0.01, Pattern=Regular
└── InstrumentType=6, Settlement=0 → Rate: Buy=9.00, Sell=0.00, Pattern=Regular
```

---

## 3. Data Overview

| InterestRateID | InterestRateName | InstrumentTypeID | SettlementTypeID | InterestRateBuy | InterestRateSell | OverNightFeePatternID | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | IR USD | 4 | 0 | 0.92563 | 0.73 | 1 | USD CFD rate with non-leverage fee pattern — buy positions pay ~0.93%/day, sell positions pay ~0.73%/day |
| 1 | IR USD | 4 | 4 | -0.805889 | 0.12 | 2 | USD CFD real-settlement rate with manual pattern — buy positions earn a swap credit (-0.81%) |
| 1 | IR USD | 5 | 0 | 0.1 | 0.1 | 0 | USD stock/real rate with regular pattern — symmetrical 0.1% rate |
| 1 | IR USD | 6 | 0 | 9.0 | 0.0 | 0 | USD crypto rate — high buy rate (9%/day equivalent), zero sell rate |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateID | int | NO | - | VERIFIED | Currency identifier for the rate. Maps to a currency: 1=USD, 2=EUR, 3=GBP, 4=CHF, 10=AUD, 12=JPY, etc. Part of composite PK. |
| 2 | InterestRateName | varchar(50) | NO | - | VERIFIED | Human-readable currency label: "IR USD", "IR EUR", "IR GBP", etc. |
| 3 | InterestRate | decimal(16,8) | NO | - | CODE-BACKED | Legacy single rate field, retained for backward compatibility. Set to 0 in current records — superseded by InterestRateBuy/Sell split. |
| 4 | UpdatedByUser | varchar(50) | NO | - | CODE-BACKED | Username of the person or service that last modified this rate. Audit trail for rate changes. |
| 5 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | Temporal row start — GENERATED ALWAYS AS ROW START. When this rate version became effective. |
| 6 | EndTime | datetime2(7) | NO | - | CODE-BACKED | Temporal row end — GENERATED ALWAYS AS ROW END. Active rates have 9999-12-31. |
| 7 | InstrumentTypeID | int | NO | - | VERIFIED | Instrument type this rate applies to: 4=CFD, 5=Stock/Real, 6=Crypto, etc. Part of composite PK. Same currency can have different rates per instrument type. |
| 8 | InterestRateBuy | decimal(16,8) | NO | - | VERIFIED | Base overnight rate for long (buy) positions. Positive=customer pays, negative=customer earns swap credit. Combined with MarkupBuy for total customer rate. |
| 9 | InterestRateSell | decimal(16,8) | NO | - | VERIFIED | Base overnight rate for short (sell) positions. |
| 10 | MarkupBuy | decimal(16,8) | NO | - | VERIFIED | Broker markup added to InterestRateBuy. Total buy rate = InterestRateBuy + MarkupBuy. |
| 11 | MarkupSell | decimal(16,8) | NO | - | VERIFIED | Broker markup added to InterestRateSell. Total sell rate = InterestRateSell + MarkupSell. |
| 12 | OverNightFeePatternID | tinyint | NO | (0) | VERIFIED | Fee calculation pattern: 0=Regular (leveraged-only), 1=WithNonLeverageFee (all positions), 2=Manual. References Dictionary.OverNightFeePattern. |
| 13 | SettlementTypeID | tinyint | NO | (0) | VERIFIED | Settlement model: 0=CFD, 1=Real Stock, 4=Real Settlement, 5=TRS. Part of composite PK. References Dictionary.SettlementTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OverNightFeePatternID | Dictionary.OverNightFeePattern | Implicit | Determines which fee calculation algorithm to use |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit | Settlement model dimension of the rate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CalcOverNightFeeRates | Direct query | Read | Core overnight fee calculation procedure |
| Trade.GetAllInterestRates | Direct query | Read | Returns all rates for trading engine cache |
| Trade.GetInstrumentInterestRates | Direct query | Read | Per-instrument rate lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.InterestRate (table)
```

This object has no code-level dependencies (FK targets are lookup references).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.InterestRate | Table | Temporal history of all rate changes |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reads rates for overnight fee computation |
| Trade.CalcOverNightFeeRates_TRDOPS | Stored Procedure | Trading Ops version |
| Trade.GetAllInterestRates | Stored Procedure | Full rate dump for engine cache |
| Trade.GetInstrumentInterestRates | Stored Procedure | Per-instrument lookup |
| Trade.UpdateInterestRates_TRDOPS | Stored Procedure | Updates rates from Trading Ops |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InterestRateID_InstrumentTypeID_SettlementTypeID | CLUSTERED PK | InterestRateID, InstrumentTypeID, SettlementTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK composite | PRIMARY KEY | Unique rate per currency × instrument type × settlement type |
| DEFAULT OverNightFeePatternID | DEFAULT | 0 (Regular pattern) |
| DEFAULT SettlementTypeID | DEFAULT | 0 (CFD settlement) |
| SYSTEM_TIME PERIOD | TEMPORAL | BeginTime to EndTime — automatic version history |

---

## 8. Sample Queries

### 8.1 Get current USD rates across all instrument types
```sql
SELECT  InterestRateID, InterestRateName, InstrumentTypeID, SettlementTypeID,
        InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell,
        OverNightFeePatternID
FROM    Dictionary.InterestRate WITH (NOLOCK)
WHERE   InterestRateID = 1
ORDER BY InstrumentTypeID, SettlementTypeID;
```

### 8.2 View rate change history for a specific currency
```sql
SELECT  InterestRateID, InterestRateName, InstrumentTypeID,
        InterestRateBuy, InterestRateSell, UpdatedByUser,
        BeginTime, EndTime
FROM    Dictionary.InterestRate
FOR SYSTEM_TIME ALL
WHERE   InterestRateID = 1 AND InstrumentTypeID = 4 AND SettlementTypeID = 0
ORDER BY BeginTime DESC;
```

### 8.3 Find rates using non-standard fee patterns
```sql
SELECT  ir.InterestRateName, ir.InstrumentTypeID, ir.SettlementTypeID,
        onfp.OverNightFeePatternName,
        ir.InterestRateBuy, ir.InterestRateSell
FROM    Dictionary.InterestRate ir WITH (NOLOCK)
JOIN    Dictionary.OverNightFeePattern onfp WITH (NOLOCK)
        ON ir.OverNightFeePatternID = onfp.OverNightFeePatternID
WHERE   ir.OverNightFeePatternID <> 0
ORDER BY ir.InterestRateID, ir.InstrumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InterestRate | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.InterestRate.sql*
