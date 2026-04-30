# Hedge.GetProviderUnitConversion

> Returns LP-specific unit conversion parameters (ratio, lot size, rate conversion factor) for all LP-instrument contract combinations, enabling the hedge engine to translate eToro internal units into LP-denominated order quantities and rate units.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full conversion table for all LP-instrument combinations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetProviderUnitConversion` solves a core unit translation problem: eToro tracks customer positions in its own internal unit denomination, but each LP's FIX trading system expects order quantities in that LP's specific denomination (lots, shares, contracts). Without this conversion, a hedge order sized in "eToro units" would arrive at the LP with the wrong quantity.

The procedure joins three sources to produce the complete conversion table:
1. `Trade.LiquidityProviderContracts` - the set of all (LP, instrument) pairs eToro can trade
2. `Hedge.ProviderUnitConversionRatio` - LP-specific override values for UnitConversionRatio and LotSize
3. `Trade.GetInstrumentDataDealing` - instrument type metadata needed to determine the default LotSize when no LP-specific override exists

The ISNULL logic encodes the fallback hierarchy:
- **UnitConversionRatio**: if LP-specific override exists, use it; otherwise default to 1 (1:1 ratio)
- **LotSize**: if LP-specific override exists, use it; otherwise default to 1000 for Forex instruments, 1 for all others (e.g., equities, commodities, crypto)

Data flows as follows: on startup, the hedge engine calls this procedure and loads the result into a cache keyed by (LiquidityProviderID, InstrumentID). When sizing a hedge order, the engine applies: `LP_Order_Quantity = eToro_Units * UnitConversionRatio / LotSize`. The `RateConversionFactor` from LiquidityProviderContracts is also included for price unit translation between eToro's internal rate and the LP's rate format.

---

## 2. Business Logic

### 2.1 Three-Way JOIN with ISNULL Default Fallback

**What**: Joins all LP-instrument contract pairs with their optional unit conversion overrides and instrument type metadata. ISNULL provides defaults where LP-specific values are not configured.

**Columns/Parameters Involved**: `LiquidityProviderID`, `InstrumentID`, `UnitConversionRatio`, `LotSize`, `RateConversionFactor`, `InstrumentType`

**Rules**:
- Base table: `Trade.LiquidityProviderContracts` (LPC) - provides all valid LP-instrument pairs
- LEFT JOIN `Hedge.ProviderUnitConversionRatio` (PCR): ON LiquidityProviderID AND InstrumentID match. LEFT ensures all LP contracts are returned even if no override exists.
- JOIN `Trade.GetInstrumentDataDealing` (IDD): ON InstrumentID to get InstrumentType (Forex vs other)
- `ISNULL(PCR.UnitConversionRatio, 1)`: if no LP override, ratio = 1 (no adjustment)
- `ISNULL(PCR.LotSize, CASE WHEN IDD.InstrumentType='Forex' THEN 1000 ELSE 1 END)`: if no LP override, Forex uses 1000-unit lots, all others use 1-unit contracts
- SET TRAN ISOLATION LEVEL READ UNCOMMITTED: avoids blocking during the conversion table load

**Diagram**:
```
LP contract pair: LiquidityProviderID=69 (ZBFX), InstrumentID=1 (EUR/USD)
  PCR row exists: UnitConversionRatio=1.0, LotSize=100000
  -> Output: LiquidityProviderID=69, InstrumentID=1, UnitConversionRatio=1.0, LotSize=100000

LP contract pair: LiquidityProviderID=5, InstrumentID=200 (some stock)
  No PCR row: UnitConversionRatio=NULL, LotSize=NULL
  InstrumentType='Equity'
  -> Output: LiquidityProviderID=5, InstrumentID=200, UnitConversionRatio=1, LotSize=1

LP contract pair: LiquidityProviderID=5, InstrumentID=1 (EUR/USD)
  No PCR row, InstrumentType='Forex'
  -> Output: LiquidityProviderID=5, InstrumentID=1, UnitConversionRatio=1, LotSize=1000

Hedge order sizing:
  eToro exposure: 500,000 EUR/USD units (internal)
  LP expects lots: 500,000 / 100,000 = 5 lots to ZBFX
```

### 2.2 RateConversionFactor Pass-Through

**What**: The `RateConversionFactor` from `Trade.LiquidityProviderContracts` is returned as-is. It handles rate unit translation between eToro's internal price format and the LP's price format.

**Columns/Parameters Involved**: `LPC.RateConversionFactor`

**Rules**:
- Taken directly from Trade.LiquidityProviderContracts without modification
- Used when the LP quotes prices in different units than eToro's internal format (e.g., pips vs decimal, or different base currency)
- The hedge engine multiplies or divides by this factor when converting between eToro rates and LP order prices

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NO | - | VERIFIED | The LP identifier. Combined with InstrumentID as the effective key for the conversion cache. FK to Trade.LiquidityProvider (via LiquidityProviderContracts). Dominant values: provider 69 (ZBFX) covers 5,213 of 5,739 ProviderUnitConversionRatio rows. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The financial instrument. Combined with LiquidityProviderID as the effective key. One row per LP-instrument contract pair. |
| 3 | UnitConversionRatio | decimal | NO | 1 | VERIFIED | Multiplier to convert eToro internal units to LP order quantity units. ISNULL(PCR.UnitConversionRatio, 1): LP-specific value if configured, otherwise 1. Applied as: LP_quantity = eToro_units * UnitConversionRatio. |
| 4 | LotSize | decimal | NO | Forex:1000, Other:1 | VERIFIED | The standard lot size for this LP-instrument combination in LP denomination. ISNULL(PCR.LotSize, Forex?1000:1): LP-specific value if configured, otherwise 1000 for Forex, 1 for equities/commodities/crypto. Applied as: LP_lots = eToro_units * UnitConversionRatio / LotSize. |
| 5 | RateConversionFactor | decimal | YES | - | VERIFIED | Price unit conversion factor from eToro internal rate format to LP rate format. Taken directly from Trade.LiquidityProviderContracts. Multiply or divide the eToro price by this factor before placing the LP order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LPC.* | Trade.LiquidityProviderContracts | SELECT (base) | Provides all LP-instrument contract pairs. Used with READ UNCOMMITTED isolation. |
| PCR.UnitConversionRatio, PCR.LotSize | Hedge.ProviderUnitConversionRatio | LEFT JOIN | LP-specific conversion overrides. LEFT JOIN ensures all contracts are returned even without an override. |
| IDD.InstrumentType | Trade.GetInstrumentDataDealing | JOIN | Instrument type metadata for Forex vs non-Forex LotSize default selection. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load the LP-instrument unit conversion cache for order sizing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetProviderUnitConversion (procedure)
├── Trade.LiquidityProviderContracts (table) [cross-schema]
├── Hedge.ProviderUnitConversionRatio (table) [LEFT JOIN override]
└── Trade.GetInstrumentDataDealing (view/function) [cross-schema, InstrumentType lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | Base join - source of all LP-instrument trading pairs and RateConversionFactor |
| Hedge.ProviderUnitConversionRatio | Table | LEFT JOIN - provides LP-specific UnitConversionRatio and LotSize overrides (5,739 rows, dominant: ZBFX with 5,213) |
| Trade.GetInstrumentDataDealing | View/Function | JOIN - provides InstrumentType for Forex vs non-Forex LotSize default logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - loads at startup to build LP-instrument order sizing conversion cache |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. SET TRAN ISOLATION LEVEL READ UNCOMMITTED is set session-wide. Trade.LiquidityProviderContracts and Hedge.ProviderUnitConversionRatio both have (LiquidityProviderID, InstrumentID) composite PKs, enabling efficient join on those columns. The LEFT JOIN on ProviderUnitConversionRatio means all contracts are returned; rows without a matching PCR row use the ISNULL defaults.

### 7.2 Constraints

N/A for Stored Procedure. The Forex/non-Forex branching in the LotSize default (`CASE WHEN IDD.InstrumentType='Forex' THEN 1000 ELSE 1 END`) is a hardcoded business rule: standard forex lots are 1000-unit micro-lots (eToro's internal forex denomination), while all other asset classes use a 1-unit default. LP-specific configurations in ProviderUnitConversionRatio override this default for all providers that don't conform to the standard.

---

## 8. Sample Queries

### 8.1 Load all provider unit conversion configurations
```sql
EXEC [Hedge].[GetProviderUnitConversion];
```

### 8.2 Direct equivalent query
```sql
SELECT  LPC.LiquidityProviderID,
        LPC.InstrumentID,
        ISNULL(PCR.UnitConversionRatio, 1) AS UnitConversionRatio,
        ISNULL(PCR.LotSize,
               CASE WHEN IDD.InstrumentType = 'Forex' THEN 1000 ELSE 1 END) AS LotSize,
        LPC.RateConversionFactor
FROM    [Trade].[LiquidityProviderContracts] LPC
LEFT JOIN [Hedge].[ProviderUnitConversionRatio] PCR
        ON PCR.LiquidityProviderID = LPC.LiquidityProviderID
       AND PCR.InstrumentID = LPC.InstrumentID
JOIN    [Trade].[GetInstrumentDataDealing] IDD
        ON LPC.InstrumentID = IDD.InstrumentID;
```

### 8.3 Check which LP-instrument pairs use the default (no override configured)
```sql
SELECT  LPC.LiquidityProviderID,
        LPC.InstrumentID,
        IDD.InstrumentType
FROM    [Trade].[LiquidityProviderContracts] LPC WITH (NOLOCK)
LEFT JOIN [Hedge].[ProviderUnitConversionRatio] PCR WITH (NOLOCK)
        ON PCR.LiquidityProviderID = LPC.LiquidityProviderID
       AND PCR.InstrumentID = LPC.InstrumentID
JOIN    [Trade].[GetInstrumentDataDealing] IDD
        ON LPC.InstrumentID = IDD.InstrumentID
WHERE   PCR.LiquidityProviderID IS NULL -- no override = using defaults
ORDER BY LPC.LiquidityProviderID, LPC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetProviderUnitConversion | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetProviderUnitConversion.sql*
