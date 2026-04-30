# Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection

> Returns the net dollar value of a customer's open positions for a specific instrument and direction, optionally including the value of a hypothetical additional position, used for exposure and margin calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @InstrumentID + @IsBuy - identifies the exposure slice to calculate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection` calculates the total dollar value of a customer's open exposure for a specific instrument in a specific direction (long or short). It uses the instrument's current unit margin price (`UnitMargin` from `Trade.CurrencyPrice`) multiplied by the total open units for that CID/Instrument/Direction combination.

The optional `@PositionUnits` parameter allows the caller to include a hypothetical additional position - passing the units of a new order being evaluated lets the procedure return what the total exposure would be if that order were opened. This is used in pre-trade margin/exposure checks to determine whether opening a new position would breach limits.

If the customer has no existing open positions in that instrument/direction, the result is simply `@Price * @PositionUnits` (the value of the hypothetical position alone).

Data flows: Called during pre-trade validation. Returns a single scalar row: `NetOpenPositionDollarValue` as MONEY.

---

## 2. Business Logic

### 2.1 Unit Margin Price Lookup

**What**: Gets the per-unit margin requirement price for the instrument.

**Columns/Parameters Involved**: `@Price`, `@InstrumentID`, `Trade.CurrencyPrice.UnitMargin`

**Rules**:
- `SELECT @Price = ISNULL(UnitMargin, 1) FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID`: Reads the unit margin. If no entry exists (new or unmapped instrument), defaults to 1.
- `UnitMargin`: The dollar value per unit of the instrument, used to convert position size (in units) to dollar exposure.

### 2.2 Net Open Dollar Value Calculation

**What**: Sums all open units for the CID/Instrument/Direction and multiplies by unit margin price.

**Columns/Parameters Involved**: `@NetOpenPositionDollarValue`, `AmountInUnitsDecimal`, `StatusID`

**Rules**:
- `StatusID = 1`: Open positions only.
- `SUM(ISNULL(AmountInUnitsDecimal, 0))`: Totals all open unit quantities. NULL units treated as 0.
- `@Price * SUM(units) AS @NetOpenPositionDollarValue`: Total dollar value of current open exposure for this CID/Instrument/Direction.
- Separate queries for each parameter combination (`CID`, `InstrumentID`, `IsBuy`) - no cross-direction aggregation.

### 2.3 Optional Hypothetical Position Inclusion

**What**: Adds value of a new position being evaluated to the existing net open value.

**Columns/Parameters Involved**: `@PositionUnits`, `NetOpenPositionDollarValue`

**Rules**:
- `@PositionUnits DECIMAL(18,4) = 0`: Default is 0 (no hypothetical position - returns current exposure only).
- If existing open exposure != 0: `NetOpenPositionDollarValue = @NetOpenPositionDollarValue + @Price * @PositionUnits`
- If no existing open exposure: `NetOpenPositionDollarValue = @Price * @PositionUnits`
- Both branches produce the same mathematical result, but the branching avoids a NULL addition issue when `@NetOpenPositionDollarValue` is NULL (no positions found = NULL aggregate).
- The result represents: "if I open a new position of @PositionUnits, what would my total exposure be?"

### 2.4 Error Handling

**What**: TRY/CATCH with THROW re-raises any exceptions to the caller.

**Rules**:
- `BEGIN TRY ... END TRY BEGIN CATCH THROW END CATCH`: Any error during price lookup or unit aggregation is propagated to the caller unchanged.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose open positions to aggregate. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to calculate net open dollar value for. |
| 3 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction filter: 1=long positions, 0=short positions. Calculated separately per direction. |
| 4 | @PositionUnits | DECIMAL(18,4) | YES | 0 | CODE-BACKED | Optional hypothetical additional units to include in calculation. Used for pre-trade exposure checks. Default 0 = return current exposure only. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | NetOpenPositionDollarValue | Total dollar value of the customer's open exposure for the given instrument+direction, plus the optional hypothetical @PositionUnits. MONEY type. Formula: UnitMargin * (SUM of existing open units + @PositionUnits). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.CurrencyPrice | Lookup | Reads UnitMargin for the instrument to convert units to dollar value. |
| @CID, @InstrumentID, @IsBuy | Trade.PositionTbl | Primary read | Aggregates AmountInUnitsDecimal for open positions (StatusID=1) matching CID + InstrumentID + IsBuy. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection (procedure)
├── Trade.CurrencyPrice (table)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | SELECT UnitMargin WHERE InstrumentID=@InstrumentID - unit margin price for dollar conversion |
| Trade.PositionTbl | Table | SELECT SUM(AmountInUnitsDecimal) WHERE CID=@CID AND InstrumentID=@InstrumentID AND IsBuy=@IsBuy AND StatusID=1 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get current long exposure for a customer on a specific instrument

```sql
EXEC Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection
    @CID = 12345,
    @InstrumentID = 1000,
    @IsBuy = 1;
```

### 8.2 Pre-trade check: what would exposure be if opening 100 units?

```sql
EXEC Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection
    @CID = 12345,
    @InstrumentID = 1000,
    @IsBuy = 1,
    @PositionUnits = 100.0;
```

### 8.3 Get both long and short exposure for net position

```sql
DECLARE @LongValue MONEY, @ShortValue MONEY;

EXEC Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection
    @CID = 12345, @InstrumentID = 1000, @IsBuy = 1;
-- Capture result as @LongValue

EXEC Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection
    @CID = 12345, @InstrumentID = 1000, @IsBuy = 0;
-- Capture result as @ShortValue
-- Net = @LongValue - @ShortValue
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection.sql*
