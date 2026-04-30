# Trade.GetInterestRateOverrides

> Returns overnight interest rate overrides from Dictionary.InterestRateOverride with optional filtering by instrument, type, exchange, or override ID, enriched with symbol names and currency descriptions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads Dictionary.InterestRateOverride with multi-dimensional filtering |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInterestRateOverrides retrieves overnight interest rate (swap/rollover fee) overrides configured for specific instruments, instrument types, or exchanges. These overrides allow the business to manually adjust the buy/sell interest rates and markups that are applied when positions are held overnight.

The procedure enriches the raw override data with human-readable names by joining to instrument (symbol), currency, currency type, and exchange reference tables. All joins are LEFT JOINs, so overrides at the type or exchange level (without a specific InstrumentID) still return rows. All four filter parameters are optional -- when all are NULL, returns all overrides.

---

## 2. Business Logic

### 2.1 Multi-Dimensional Filtering (Catch-All Query Pattern)

**What**: All WHERE conditions are optional, using the `@Param IS NULL OR column = @Param` pattern.

**Rules**:
- @InterestRateOverrideID: filter to specific override record
- @InstrumentID: filter to specific instrument
- @InstrumentTypeID: filter to asset class (maps to CurrencyType via LEFT JOIN)
- @ExchangeID: filter to exchange
- When all NULL, returns all override records

### 2.2 Override Hierarchy

**What**: Overrides can be set at different granularity levels.

**Rules**:
- Instrument-level: IOR.InstrumentID is populated → resolved via Trade.GetInstrument
- Type-level: IOR.InstrumentTypeID is populated → resolved via Dictionary.CurrencyType
- Exchange-level: IOR.ExchangeID is populated → resolved via Dictionary.ExchangeInfo
- Combined: an override can specify multiple dimensions simultaneously

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | YES | NULL | CODE-BACKED | Filter by specific instrument. |
| 2 | @InterestRateOverrideID | int | YES | NULL | CODE-BACKED | Filter by specific override record ID. |
| 3 | @InstrumentTypeID | int | YES | NULL | CODE-BACKED | Filter by asset class / instrument type. |
| 4 | @ExchangeID | int | YES | NULL | CODE-BACKED | Filter by exchange. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InterestRateOverrideID | int | Dictionary.InterestRateOverride | CODE-BACKED | PK of the override record. |
| R2 | InstrumentID | int | Dictionary.InterestRateOverride | CODE-BACKED | Target instrument (NULL for type/exchange-level overrides). |
| R3 | ExchangeID | int | Dictionary.InterestRateOverride | CODE-BACKED | Target exchange (NULL for instrument-level overrides). |
| R4 | InstrumentTypeID | int | Dictionary.InterestRateOverride | CODE-BACKED | Target asset class. |
| R5 | InterestRateID | int | Dictionary.Currency.InterestRateID | CODE-BACKED | Base interest rate reference from the instrument's sell currency. |
| R6 | Symbol | nvarchar | Trade.GetInstrument.Name | CODE-BACKED | Instrument display name (NULL if no instrument match). |
| R7 | CurrencyType | nvarchar | Dictionary.CurrencyType.Name | CODE-BACKED | Asset class description (e.g., "Currencies", "Stocks"). |
| R8 | ExchangeDescription | nvarchar | Dictionary.ExchangeInfo.ExchangeDescription | CODE-BACKED | Exchange display name. |
| R9 | UpdatedByUser | nvarchar | Dictionary.InterestRateOverride | CODE-BACKED | Username who last modified the override. |
| R10 | InterestRateBuy | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Overridden buy-side overnight interest rate. |
| R11 | InterestRateSell | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Overridden sell-side overnight interest rate. |
| R12 | MarkupBuy | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Buy-side markup added to base rate. |
| R13 | MarkupSell | decimal | Dictionary.InterestRateOverride | CODE-BACKED | Sell-side markup added to base rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.InterestRateOverride | Read (SELECT) | Primary data source for override configurations |
| LEFT JOIN | Trade.GetInstrument | Read | Instrument name resolution (ON InstrumentID = ISNULL(IOR.InstrumentID, -1)) |
| LEFT JOIN | Dictionary.Currency | Read | InterestRateID from sell currency |
| LEFT JOIN | Dictionary.CurrencyType | Read | Asset class name (ON CurrencyTypeID = InstrumentTypeID) |
| LEFT JOIN | Dictionary.ExchangeInfo | Read | Exchange description |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ops tools / admin UI | - | EXEC | Interest rate override management interface |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInterestRateOverrides (procedure)
+-- Dictionary.InterestRateOverride (table)
+-- Trade.GetInstrument (view)
+-- Dictionary.Currency (table)
+-- Dictionary.CurrencyType (table)
+-- Dictionary.ExchangeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRateOverride | Table | FROM - primary data source |
| Trade.GetInstrument | View | LEFT JOIN - symbol name resolution |
| Dictionary.Currency | Table | LEFT JOIN - InterestRateID from SellCurrencyID |
| Dictionary.CurrencyType | Table | LEFT JOIN - asset class name by InstrumentTypeID |
| Dictionary.ExchangeInfo | Table | LEFT JOIN - exchange description |

---

## 7. Technical Details

### 7.1 Performance Notes

- Uses catch-all query pattern (`@Param IS NULL OR ...`) which may cause suboptimal plans without OPTION (RECOMPILE)
- All LEFT JOINs ensure type/exchange-level overrides (no specific instrument) still appear

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all overrides

```sql
EXEC Trade.GetInterestRateOverrides;
```

### 8.2 Get overrides for a specific instrument

```sql
EXEC Trade.GetInterestRateOverrides @InstrumentID = 1001;
```

### 8.3 Get overrides by exchange

```sql
EXEC Trade.GetInterestRateOverrides @ExchangeID = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInterestRateOverrides | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInterestRateOverrides.sql*
