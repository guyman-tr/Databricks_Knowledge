# Dictionary.UnitsQuantityType

> Lookup table defining whether a traded instrument allows fractional unit quantities (e.g., 0.5 shares) or requires whole-number units only, controlling position size granularity at the instrument level.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | UnitsQuantityTypeID (TINYINT, manually assigned) |
| **Partition** | DICTIONARY filegroup (heap — no PK constraint) |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.UnitsQuantityType classifies instruments into two categories based on how position sizes are measured: fractional (allowing decimal quantities like 0.001 BTC or 0.5 shares) or whole-number only (requiring integer quantities like 1 share, 2 lots). This controls the minimum position increment and UI input validation for trade sizing.

Without this table, the system would either have to allow fractional quantities for everything (incorrect for some instruments) or forbid them everywhere (preventing fractional share trading). Modern brokerages need this distinction because CFD positions and crypto trades commonly use fractional units, while some traditional instruments may require whole units.

The table is heavily referenced by instrument configuration procedures: Trade.InsertInstrumentTradingData, Trade.InsertInstrumentRealTable, Trade.GetInstrumentDataForAPI, Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage, and Trade.CheckValidInstruments. It is stored per instrument in Trade.ProviderToInstrument and its UDT Trade.InstrumentsIDListSetSlippageTbl.

---

## 2. Business Logic

### 2.1 Fractional vs Whole Unit Trading

**What**: Instruments are classified by whether they support decimal-precision quantities or whole-number-only quantities.

**Columns/Parameters Involved**: `UnitsQuantityTypeID`, `UnitsQuantityTypeName`

**Rules**:
- ID 0 (Fractional) — the instrument allows decimal position sizes (e.g., 0.5 shares, 0.001 BTC). Most common for CFDs, crypto, and fractional share trading
- ID 1 (Whole) — the instrument requires integer position sizes (e.g., 1 share, 10 lots). Used for instruments where fractional ownership is not supported
- The type is assigned per instrument during configuration and stored in Trade.ProviderToInstrument
- Trade.GetInstrumentDataForAPI returns this value to client applications so they can enforce appropriate input validation (decimal vs integer pickers)
- Trade.SetInstrumentSlippage and Trade.GetInstrumentSlippage use this when calculating slippage parameters, as fractional instruments may need different precision

**Diagram**:
```
Unit Quantity Type Impact:
  ┌────────────────────┐     ┌─────────────────────────┐
  │  0 = Fractional    │     │  UI: decimal input OK    │
  │  (CFDs, Crypto,    │────►│  Validation: 0.001 min   │
  │   Fractional Shares)│     │  Display: "0.5 shares"   │
  └────────────────────┘     └─────────────────────────┘

  ┌────────────────────┐     ┌─────────────────────────┐
  │  1 = Whole         │     │  UI: integer input only  │
  │  (Traditional      │────►│  Validation: 1 minimum   │
  │   instruments)     │     │  Display: "10 shares"    │
  └────────────────────┘     └─────────────────────────┘
```

---

## 3. Data Overview

| UnitsQuantityTypeID | UnitsQuantityTypeName | Meaning |
|---|---|---|
| 0 | Fractional | Instrument supports decimal quantities — customers can open positions with fractional units (e.g., 0.5 shares, 0.001 BTC). Enables dollar-amount investing where the system calculates fractional units from an investment amount. |
| 1 | Whole | Instrument requires whole-number units — position sizes must be integers. Applied to instruments where fractional ownership is not technically or legally supported. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UnitsQuantityTypeID | tinyint | NO | - | CODE-BACKED | Unique identifier for the quantity type: 0=Fractional (decimal positions allowed), 1=Whole (integer positions only). Referenced by Trade.ProviderToInstrument per instrument and consumed by 7+ trading procedures for validation and slippage calculation. |
| 2 | UnitsQuantityTypeName | char(50) | NO | - | CODE-BACKED | Display name of the quantity type. Fixed-width CHAR(50) with trailing spaces (legacy format). Values: "Fractional" or "Whole". Used in instrument configuration displays and API responses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | UnitsQuantityTypeID | Implicit | Stores the quantity type per instrument-provider combination |
| History.TradeProviderToInstrument | UnitsQuantityTypeID | Implicit | Historical archive of instrument quantity type assignments |
| Trade.InsertInstrumentTradingData | UnitsQuantityTypeID | Reader | Sets the quantity type during instrument trading data configuration |
| Trade.InsertInstrumentRealTable | UnitsQuantityTypeID | Reader | Reads quantity type during real instrument table population |
| Trade.GetInstrumentDataForAPI | UnitsQuantityTypeID | Reader | Returns quantity type to client applications for UI validation |
| Trade.GetInstrumentSlippage | UnitsQuantityTypeID | Reader | Uses quantity type in slippage parameter calculations |
| Trade.SetInstrumentSlippage | UnitsQuantityTypeID | Reader | Stores quantity type alongside slippage configuration |
| Trade.CheckValidInstruments | UnitsQuantityTypeID | Reader | Validates quantity type during instrument configuration checks |
| Trade.InstrumentsIDListSetSlippageTbl | UnitsQuantityTypeID | UDT | User-defined table type includes this column for bulk slippage operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.UnitsQuantityType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Stores UnitsQuantityTypeID per instrument |
| Trade.InsertInstrumentTradingData | Stored Procedure | Configures instrument quantity type |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Returns quantity type to clients |
| Trade.GetInstrumentSlippage | Stored Procedure | Reads for slippage calculations |
| Trade.SetInstrumentSlippage | Stored Procedure | Stores alongside slippage config |
| Trade.CheckValidInstruments | Stored Procedure | Validates instrument configuration |

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table). Note: the table has no PK constraint defined in DDL, despite having a logical key (UnitsQuantityTypeID). The live data contains duplicate rows (4 copies of each value), likely due to cross-server replication or re-seeding.

### 7.2 Constraints

None — no PK, no FK, no CHECK constraints.

---

## 8. Sample Queries

### 8.1 List all quantity types (deduplicated)
```sql
SELECT DISTINCT
        UnitsQuantityTypeID,
        RTRIM(UnitsQuantityTypeName) AS UnitsQuantityTypeName
FROM    [Dictionary].[UnitsQuantityType] WITH (NOLOCK)
ORDER BY UnitsQuantityTypeID;
```

### 8.2 Find instruments by quantity type
```sql
SELECT  p.InstrumentID,
        RTRIM(uq.UnitsQuantityTypeName) AS QuantityType
FROM    [Trade].[ProviderToInstrument] p WITH (NOLOCK)
JOIN    [Dictionary].[UnitsQuantityType] uq WITH (NOLOCK)
        ON uq.UnitsQuantityTypeID = p.UnitsQuantityTypeID
WHERE   RTRIM(uq.UnitsQuantityTypeName) = 'Fractional';
```

### 8.3 Count instruments by quantity type
```sql
SELECT  RTRIM(uq.UnitsQuantityTypeName) AS QuantityType,
        COUNT(DISTINCT p.InstrumentID) AS InstrumentCount
FROM    [Trade].[ProviderToInstrument] p WITH (NOLOCK)
JOIN    (SELECT DISTINCT UnitsQuantityTypeID, UnitsQuantityTypeName
         FROM [Dictionary].[UnitsQuantityType] WITH (NOLOCK)) uq
        ON uq.UnitsQuantityTypeID = p.UnitsQuantityTypeID
GROUP BY RTRIM(uq.UnitsQuantityTypeName);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.UnitsQuantityType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.UnitsQuantityType.sql*
