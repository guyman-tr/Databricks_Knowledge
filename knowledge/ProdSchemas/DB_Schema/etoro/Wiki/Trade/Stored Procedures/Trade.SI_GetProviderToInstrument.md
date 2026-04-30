# Trade.SI_GetProviderToInstrument

> System Integration query that returns all provider-to-instrument configuration records, exposing key trading parameters for each instrument-provider pairing, ordered by InstrumentID descending.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no filter parameters - returns all records) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a System Integration (SI_) endpoint that returns the full provider-to-instrument configuration table for consumption by external systems. The `Trade.GetProviderToInstrument` view (and underlying `Trade.ProviderToInstrument` table) defines how each trading instrument is configured for execution: what leverage and lot sizes are available, what the unit size and margin requirements are, what fees and spread parameters apply.

Integration consumers (trading engines, risk systems, display services) use this to load or refresh their in-memory copy of instrument configuration. The descending order by InstrumentID means the most recently added instruments appear first, which is useful for incremental sync patterns where consumers process new instruments first.

---

## 2. Business Logic

### 2.1 Full-Table Read with Descending Order

**What**: Returns all provider-instrument pairs ordered by InstrumentID DESC, with no filtering.

**Columns/Parameters Involved**: `Trade.GetProviderToInstrument` (all columns)

**Rules**:
- No WHERE clause - returns all rows (full config snapshot)
- ORDER BY InstrumentID DESC - newest instruments first
- NOLOCK - non-blocking read, acceptable for configuration sync use cases

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | - | This procedure has no input parameters. |
| Output: ProviderID | int | - | - | CODE-BACKED | Liquidity provider ID. Part of the composite key for provider-instrument configuration. |
| Output: InstrumentID | int | - | - | CODE-BACKED | Trading instrument identifier. FK to instrument master. |
| Output: InstrumentTypeID | int | - | - | CODE-BACKED | Type of instrument: CFD, stock, crypto, forex, etc. |
| Output: Precision | int | - | - | CODE-BACKED | Decimal precision for price display and rate calculations for this instrument. |
| Output: PresentationCode | varchar | - | - | CODE-BACKED | Display code/ticker symbol for the instrument (e.g., "AAPL", "BTC"). |
| Output: EndOfWeekFee | money | - | - | CODE-BACKED | Fee charged for holding a leveraged position over the weekend. |
| Output: DisplayOrder | int | - | - | CODE-BACKED | Sort order for UI display of instruments. |
| Output: Unit | decimal | - | - | CODE-BACKED | Lot size / unit size for this instrument (e.g., 1.0 for stocks, 1000 for forex pairs). |
| Output: LeverageList | varchar | - | - | CODE-BACKED | Comma-separated list of available leverage values for this instrument (e.g., "1,2,5,10"). |
| Output: LotCountList | varchar | - | - | CODE-BACKED | Comma-separated list of available lot count values. |
| Output: LiquidityLotSize | decimal | - | - | CODE-BACKED | Standard lot size used for liquidity provider hedging. |
| Output: Benchmark | varchar | - | - | CODE-BACKED | Benchmark index or reference rate for this instrument. |
| Output: UnitMargin | decimal | - | - | CODE-BACKED | Margin amount required per unit held (in USD). |
| Output: WeekendPips | decimal | - | - | CODE-BACKED | Additional pip spread charged on positions held over the weekend. |
| Output: OrdersSpread | decimal | - | - | CODE-BACKED | Default spread applied to order execution for this instrument. |
| Output: MarketRange | decimal | - | - | CODE-BACKED | Acceptable price deviation range for market order execution. |
| Output: OrdersSpreadMax | decimal | - | - | CODE-BACKED | Maximum allowed orders spread value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Trade.GetProviderToInstrument | Reader | Reads all rows from the provider-instrument config view with NOLOCK |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SI_GetProviderToInstrument (procedure)
└── Trade.GetProviderToInstrument (view) [SELECT all columns ORDER BY InstrumentID DESC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetProviderToInstrument | View | Read with NOLOCK for all rows; provides provider-instrument configuration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by external integration systems (SI_ prefix convention) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all provider-to-instrument configurations

```sql
EXEC Trade.SI_GetProviderToInstrument;
```

### 8.2 Direct equivalent query

```sql
SELECT ProviderID, InstrumentID, InstrumentTypeID, [Precision], PresentationCode,
       EndOfWeekFee, DisplayOrder, Unit, LeverageList, LotCountList, LiquidityLotSize,
       Benchmark, UnitMargin, WeekendPips, OrdersSpread, MarketRange, OrdersSpreadMax
FROM Trade.GetProviderToInstrument WITH (NOLOCK)
ORDER BY InstrumentID DESC;
```

### 8.3 Find all instruments with leverage > 1 available

```sql
SELECT InstrumentID, PresentationCode, LeverageList
FROM Trade.GetProviderToInstrument WITH (NOLOCK)
WHERE LeverageList LIKE '%,%'  -- has multiple leverage options
ORDER BY InstrumentID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SI_GetProviderToInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SI_GetProviderToInstrument.sql*
