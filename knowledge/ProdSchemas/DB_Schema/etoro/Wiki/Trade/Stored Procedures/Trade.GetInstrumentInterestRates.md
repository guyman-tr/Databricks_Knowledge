# Trade.GetInstrumentInterestRates

> Returns overnight/weekend fee (interest rate) configuration for a single instrument by resolving its sell currency to the applicable interest rate definition.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InterestRateID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the interest rate configuration that applies to a specific instrument's overnight/weekend fees. Interest rates (used for swap/rollover fees) are determined by the instrument's asset type AND the currency of the sell side. For example, a stock CFD priced in GBP will use the GBP interest rate for its instrument type.

The procedure exists to provide the trading engine and admin tools with the interest rate parameters (base rate, buy/sell rates, markups) for a given instrument. These values are used to calculate the daily/weekend holding fees charged to positions.

Data flow: caller passes @InstrumentID. The SP creates a #GetInstrument temp table from Trade.GetInstrument (view), then LEFT JOINs to Dictionary.Currency (to get the InterestRateID for the sell currency) and Dictionary.InterestRate (to get the rate definition matching the instrument type and interest rate ID).

---

## 2. Business Logic

### 2.1 Interest Rate Resolution Chain

**What**: Maps instrument to interest rate via sell currency and instrument type.

**Columns/Parameters Involved**: `@InstrumentID`, `SellCurrencyID`, `InstrumentTypeID`, `InterestRateID`

**Rules**:
- Step 1: Get instrument's SellCurrencyID and InstrumentTypeID from Trade.GetInstrument
- Step 2: Look up the InterestRateID from Dictionary.Currency for this SellCurrencyID
- Step 3: Find the rate in Dictionary.InterestRate matching both InstrumentTypeID AND InterestRateID
- LEFT JOINs used so instruments without matching rates return NULLs (with InterestRateID defaulting to -1)

**Diagram**:
```
@InstrumentID --> Trade.GetInstrument --> SellCurrencyID + InstrumentTypeID
                                              |
                        Dictionary.Currency --+--> InterestRateID
                                              |
                  Dictionary.InterestRate ----+--> Full rate definition
                    (InstrumentTypeID + InterestRateID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to resolve interest rates for. FK to Trade.Instrument. |
| 2 | InterestRateID (output) | INT | NO | -1 | CODE-BACKED | Interest rate definition ID. Defaults to -1 via ISNULL when no matching rate exists. FK to Dictionary.InterestRate. |
| 3 | InterestRateName (output) | VARCHAR | YES | - | CODE-BACKED | Human-readable name of the interest rate (e.g., "USD Stocks", "EUR Forex"). |
| 4 | InterestRate (output) | DECIMAL | YES | - | CODE-BACKED | Base interest rate value. |
| 5 | UpdatedByUser (output) | VARCHAR | YES | - | CODE-BACKED | Last user who updated this rate configuration. |
| 6 | InstrumentTypeID (output) | INT | NO | - | CODE-BACKED | Asset class of the instrument. |
| 7 | InterestRateBuy (output) | DECIMAL | YES | - | CODE-BACKED | Interest rate applied to Buy/Long positions (overnight fee rate). |
| 8 | InterestRateSell (output) | DECIMAL | YES | - | CODE-BACKED | Interest rate applied to Sell/Short positions. |
| 9 | MarkupBuy (output) | DECIMAL | YES | - | CODE-BACKED | eToro's markup on the buy interest rate. |
| 10 | MarkupSell (output) | DECIMAL | YES | - | CODE-BACKED | eToro's markup on the sell interest rate. |
| 11 | OverNightFeePatternID (output) | INT | YES | - | CODE-BACKED | Pattern for overnight fee calculation (e.g., triple Wednesday for forex). |
| 12 | SettlementTypeID (output) | TINYINT | YES | - | CODE-BACKED | Settlement type this rate applies to. See [Settlement Type](../../_glossary.md#settlement-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.GetInstrument | SELECT INTO | Temp table from view, filtered by InstrumentID |
| (body) | Dictionary.Currency | LEFT JOIN | Maps SellCurrencyID to InterestRateID |
| (body) | Dictionary.InterestRate | LEFT JOIN | Rate definition matching InstrumentTypeID + InterestRateID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentInterestRates (procedure)
+-- Trade.GetInstrument (view)
+-- Dictionary.Currency (table)
+-- Dictionary.InterestRate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | SELECT INTO #GetInstrument - provides instrument type and currencies |
| Dictionary.Currency | Table | LEFT JOIN - resolves SellCurrencyID to InterestRateID |
| Dictionary.InterestRate | Table | LEFT JOIN - provides rate definition |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses DROP TABLE IF EXISTS for #GetInstrument cleanup.

---

## 8. Sample Queries

### 8.1 Execute for a specific instrument

```sql
EXEC Trade.GetInstrumentInterestRates @InstrumentID = 1001;
```

### 8.2 Query interest rates directly

```sql
SELECT  ir.InterestRateID, ir.InterestRateName, ir.InterestRateBuy, ir.InterestRateSell,
        ir.MarkupBuy, ir.MarkupSell, ir.OverNightFeePatternID
FROM    Dictionary.InterestRate ir WITH (NOLOCK)
WHERE   ir.InstrumentTypeID = 5;
```

### 8.3 Resolve rate for an instrument manually

```sql
SELECT  gi.InstrumentID, gi.InstrumentTypeID,
        c.CurrencyName AS SellCurrency,
        ir.InterestRateName, ir.InterestRateBuy, ir.InterestRateSell
FROM    Trade.GetInstrument gi WITH (NOLOCK)
JOIN    Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = gi.SellCurrencyID
JOIN    Dictionary.InterestRate ir WITH (NOLOCK)
        ON ir.InstrumentTypeID = gi.InstrumentTypeID
        AND ir.InterestRateID = c.InterestRateID
WHERE   gi.InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentInterestRates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentInterestRates.sql*
