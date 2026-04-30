# Hedge.GetMajorsUnits

> Decomposes a cross-currency or non-major instrument's hedge position into its constituent major-pair components with correctly converted unit sizes, enabling the hedge engine to place major-instrument orders instead of trading illiquid cross pairs directly.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CrossInstrumentId + @Units - input defines the cross-instrument and exposure size to decompose |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetMajorsUnits` solves a core forex hedging problem: cross-currency pairs (e.g., EUR/JPY, GBP/AUD) are far less liquid than major pairs (EUR/USD, USD/JPY, GBP/USD, AUD/USD). Rather than hedging a EUR/JPY position by trading EUR/JPY directly, eToro decomposes it into two major-pair trades: sell EUR/USD (to short EUR) and sell USD/JPY (to short JPY vs USD), achieving the same net EUR/JPY exposure through more liquid instruments.

This procedure encodes the decomposition logic for 9 specific cross pairs (InstrumentIDs 8-16). For each cross, it hardcodes which two major instruments to use, applies live market prices from `Trade.CurrencyPrice` to convert the cross-instrument unit size into the correct quantities for each major leg, and flags whether each leg is "virtual" (requiring price division instead of multiplication). The result is a two-row table: one row per major component with the correctly scaled unit count.

Data flows as follows: the hedge server detects exposure in a cross-currency instrument, calls `GetMajorsUnits` with the instrument ID and units, receives back 2 rows with (MajorInstrumentID, Units), then places two separate hedge orders - one per major. If the input instrument is already a major (IsMajor=1 in Trade.Instrument), the procedure returns the instrument unchanged with the original units and exits immediately.

---

## 2. Business Logic

### 2.1 Pass-Through for Major Instruments

**What**: If @CrossInstrumentId is already classified as a major instrument (Trade.Instrument.IsMajor=1), return it directly with its original units - no decomposition needed.

**Columns/Parameters Involved**: `@CrossInstrumentId`, `@Units`, `Trade.Instrument.IsMajor`

**Rules**:
- Checks: `SELECT * FROM Trade.Instrument WHERE IsMajor=1 AND InstrumentID = @CrossInstrumentId`
- If found: returns single row (MajorInstrumentID=@CrossInstrumentId, Units=@Units) and exits via RETURN(0)
- No further processing occurs for majors

### 2.2 Cross-Instrument Decomposition Map (Hardcoded)

**What**: 9 cross-currency instruments (IDs 8-16) are hardcoded to decompose into specific major-pair combinations. The decomposition table is embedded directly in the procedure logic.

**Columns/Parameters Involved**: `@CrossInstrumentId`, `MajorInstrumentID`, `Units`, `IsVirtual`, `OrderCol`

**Rules**:
- Each cross maps to exactly 2 major instruments (OrderCol=1 for primary leg, OrderCol=2 for secondary)
- `IsVirtual=1` indicates a "virtual leg" - one that requires division by price rather than multiplication (reflects how the cross rate is mathematically constructed)
- `IsVirtual=0` indicates a "direct leg" - straightforward price multiplication

Cross-instrument mapping:
```
InstrumentID=8:  Leg1->Major 1 (direct), Leg2->Major 2 (virtual, -Units)
InstrumentID=9:  Leg1->Major 1 (direct), Leg2->Major 6 (direct)
InstrumentID=10: Leg1->Major 1 (direct), Leg2->Major 5 (direct)
InstrumentID=11: Leg1->Major 2 (direct), Leg2->Major 5 (direct)
InstrumentID=12: Leg1->Major 1 (direct), Leg2->Major 7 (virtual, -Units)
InstrumentID=13: Leg1->Major 1 (direct), Leg2->Major 4 (direct)
InstrumentID=14: Leg1->Major 7 (direct), Leg2->Major 5 (direct)
InstrumentID=15: Leg1->Major 4 (virtual, -Units), Leg2->Major 5 (direct)
InstrumentID=16: Leg1->Major 6 (virtual, -Units), Leg2->Major 5 (direct)
```
Note: Negative initial units (0-@Units) signal a short direction for that leg.

### 2.3 Price-Based Unit Conversion

**What**: Live bid/ask prices from Trade.CurrencyPrice are used to convert the cross-instrument unit count into correctly scaled major-instrument unit counts.

**Columns/Parameters Involved**: `@Price`, `@Units`, `IsVirtual`, `OrderCol`

**Rules**:
- Price selection: `@Price = CASE WHEN @Units >= 0 THEN Ask ELSE Bid END` - positive units = long = use Ask; negative units = short = use Bid
- For OrderCol=1 (primary leg): if IsVirtual=1, divide ALL units by the primary leg's price (`Units = Units / @Price`)
- For OrderCol=2 (secondary leg): if IsVirtual=0, multiply by the primary leg's price (`Units = Units * @Price`); if IsVirtual=1, also fetch secondary price and divide
- This ensures both major legs have the correct USD-equivalent unit size matching the original cross position's exposure

**Diagram**:
```
Example: @CrossInstrumentId=9 (EUR/GBP cross), @Units=100,000

Decomposition: EUR/GBP -> Leg1: EUR/USD (ID=1, OrderCol=1, IsVirtual=0)
                          Leg2: GBP/USD (ID=6, OrderCol=2, IsVirtual=0)

Leg1 units: 100,000 (direct, no price adjustment needed for primary direct leg)
Leg2 units: 100,000 * Ask(EUR/USD) = e.g., 107,000 GBP/USD units
            (EUR/GBP = EUR/USD / GBP/USD, so GBP size = EUR * EUR/USD rate)

Result:
  MajorInstrumentID=1, Units=100,000  (buy 100k units EUR/USD)
  MajorInstrumentID=6, Units=107,000  (buy 107k units GBP/USD)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CrossInstrumentId | int | NO | - | CODE-BACKED | The instrument ID to decompose. If IsMajor=1 in Trade.Instrument, the procedure returns it unchanged. If it matches one of the 9 hardcoded cross IDs (8-16), it is decomposed into 2 major components. Other IDs with no mapping produce an empty result set. |
| 2 | @Units | int | NO | - | CODE-BACKED | The exposure size in eToro's internal unit denomination for the cross instrument. Sign is significant: positive = long (buy), negative = short (sell). Sign affects which price (Ask vs Bid) is used for conversion. |

**Output columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | MajorInstrumentID | int | NO | - | CODE-BACKED | The major-instrument InstrumentID for this decomposition leg. For pass-through majors: equals @CrossInstrumentId. For cross pairs: one of the 9 major currencies (IDs 1-7) that compose the cross. |
| 4 | Units | money | YES | - | CODE-BACKED | The correctly scaled unit count for this major leg, after price conversion. For pass-through: equals @Units. For cross decompositions: @Units scaled by the appropriate bid/ask price to achieve correct major-pair exposure equivalent to the original cross position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsMajor | Trade.Instrument | SELECT lookup | Checks whether @CrossInstrumentId is a major instrument. |
| Ask/Bid prices | Trade.CurrencyPrice | SELECT | Retrieves live bid/ask prices for the primary major leg to scale the secondary leg's units. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins.sql | - | Permission grant | BI admin role has EXECUTE permission. |
| Hedge server application | - | Caller | Called when the ConvertToMajors setting is active and a cross-currency instrument requires hedging. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetMajorsUnits (procedure)
├── Trade.Instrument (table) - IsMajor check
└── Trade.CurrencyPrice (table) - live Ask/Bid prices for unit conversion
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Checks IsMajor=1 flag to determine if decomposition is needed |
| Trade.CurrencyPrice | Table | Provides live Ask/Bid prices for converting cross-instrument units to major-instrument units |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | Called when ConvertToMajors=1 in Hedge.ServerConfiguration to decompose cross-pair exposure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. The cross-instrument decomposition map (InstrumentIDs 8-16) is hardcoded logic, not a configurable table. The 9 supported crosses are the only pairs eToro decomposes into majors. Any @CrossInstrumentId outside this list and not a major will return an empty result set.

---

## 8. Sample Queries

### 8.1 Decompose a cross-currency instrument into major legs
```sql
EXEC [Hedge].[GetMajorsUnits]
    @CrossInstrumentId = 9,   -- EUR/GBP cross
    @Units = 100000;          -- 100,000 units long
```

### 8.2 Decompose a short position in a cross pair
```sql
EXEC [Hedge].[GetMajorsUnits]
    @CrossInstrumentId = 11,  -- GBP/JPY cross
    @Units = -50000;          -- 50,000 units short (negative)
```

### 8.3 Verify that a major instrument is returned as-is
```sql
EXEC [Hedge].[GetMajorsUnits]
    @CrossInstrumentId = 1,   -- EUR/USD (IsMajor=1)
    @Units = 200000;          -- Returns single row: (1, 200000)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetMajorsUnits | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetMajorsUnits.sql*
