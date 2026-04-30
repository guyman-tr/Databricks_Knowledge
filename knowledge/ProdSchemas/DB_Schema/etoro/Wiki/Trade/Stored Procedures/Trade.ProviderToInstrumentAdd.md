# Trade.ProviderToInstrumentAdd

> Creates a new provider-instrument configuration row in Trade.ProviderToInstrument, establishing the trading parameters for an instrument offered through a specific execution provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID (composite PK of the created row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderToInstrumentAdd is the INSERT writer for Trade.ProviderToInstrument. It creates a new provider-instrument pair row, defining how a specific instrument will be traded through a specific execution provider - covering pricing precision, fees, spread parameters, position size limits, and display order.

This procedure exists to provide a controlled, single-point INSERT path for ProviderToInstrument rows. The table's INSERT trigger (`InstrumentProviderInsert`) also fires on creation, seeding Trade.CurrencyPrice with zero bid/ask and Trade.ProviderToInstrument is system-versioned, so INSERT has side effects beyond the row itself. Centralizing the INSERT here ensures those side effects are predictable.

Data flow: Called by operations/ops tools when onboarding a new instrument to a provider, or when adding a provider route for an existing instrument. After creation, the row is typically populated with additional config via Trade.ProviderToInstrumentEdit. The procedure returns @@ERROR (0 on success, SQL error number on failure).

---

## 2. Business Logic

### 2.1 Core Field Coverage - Insert Only a Subset of Columns

**What**: The procedure inserts only 16 of the 90 columns in Trade.ProviderToInstrument. Remaining columns receive their DEFAULT values from the table definition (AllowBuy=1, AllowSell=1, Enabled=0, etc.).

**Columns/Parameters Involved**: All 16 input parameters

**Rules**:
- Columns NOT provided at creation get table defaults: AllowBuy=1, AllowSell=1, AllowPendingOrders=1, Enabled=0 (note: Enabled defaults to 0, so the instrument is disabled at creation and must be explicitly enabled later).
- @MarketRange defaults to 10 if not supplied.
- @WeekendPips defaults to NULL if not supplied.
- RETURN @@ERROR: returns 0 on success, the SQL error number on failure.

**Diagram**:
```
Caller -> Trade.ProviderToInstrumentAdd(@ProviderID, @InstrumentID, ...)
    |
    v
INSERT Trade.ProviderToInstrument (16 columns; remaining 74 get table defaults)
    |
    +-- INSERT trigger fires: seeds Trade.CurrencyPrice (zero bid/ask for new instrument-provider)
    +-- System versioning: History.TradeProviderToInstrument row created
    +-- RETURN @@ERROR
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Identifies the execution provider. Part of the composite PK (ProviderID, InstrumentID). FK to Trade.Provider. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Identifies the tradeable instrument. Part of the composite PK. FK to Trade.Instrument. |
| 3 | @Precision | TINYINT | NO | - | CODE-BACKED | Decimal places for price display and rounding. Written to Trade.ProviderToInstrument.Precision. |
| 4 | @PaymentBid | INTEGER | NO | - | CODE-BACKED | Bid-side payment adjustment (basis points or similar). Written to Trade.ProviderToInstrument.PaymentBid. |
| 5 | @PaymentAsk | INTEGER | NO | - | CODE-BACKED | Ask-side payment adjustment. Written to Trade.ProviderToInstrument.PaymentAsk. |
| 6 | @PresentationCode | VARCHAR(20) | NO | - | CODE-BACKED | Display code for the instrument (e.g., EURUSD=, JPY=). Written to Trade.ProviderToInstrument.PresentationCode. |
| 7 | @StopLossPercentage | INTEGER | NO | - | CODE-BACKED | Legacy SL percentage field. Written to Trade.ProviderToInstrument.StopLossPercentage. |
| 8 | @EndOfWeekFee | MONEY | NO | - | CODE-BACKED | End-of-week holding fee. Written to Trade.ProviderToInstrument.EndOfWeekFee. |
| 9 | @Unit | INTEGER | NO | - | CODE-BACKED | Base unit size for the instrument (e.g., 1000 for forex). Written to Trade.ProviderToInstrument.Unit. |
| 10 | @UnitMargin | INTEGER | NO | - | CODE-BACKED | Margin factor per unit. Written to Trade.ProviderToInstrument.UnitMargin. |
| 11 | @Benchmark | INTEGER | NO | - | CODE-BACKED | Reference value for pricing (e.g., 10000 for forex). Written to Trade.ProviderToInstrument.Benchmark. |
| 12 | @LiquidityLotSize | INTEGER | NO | - | CODE-BACKED | Lot size for liquidity provider orders. Written to Trade.ProviderToInstrument.LiquidityLotSize. |
| 13 | @LiquidityLotCost | MONEY | NO | - | CODE-BACKED | Cost per liquidity lot. Written to Trade.ProviderToInstrument.LiquidityLotCost. |
| 14 | @DisplayOrder | INTEGER | NO | - | CODE-BACKED | Sort order for UI display. Written to Trade.ProviderToInstrument.DisplayOrder. |
| 15 | @MarketRange | INTEGER | NO | 10 | CODE-BACKED | Market range validation limit. Defaults to 10 if not supplied. Written to Trade.ProviderToInstrument.MarketRange. |
| 16 | @WeekendPips | INTEGER | YES | NULL | CODE-BACKED | Weekend spread or fee in pips. Defaults to NULL if not supplied. Written to Trade.ProviderToInstrument.WeekendPips. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID | Trade.Provider | Implicit | Provider must exist; FK enforced by Trade.ProviderToInstrument.FK_TSPRV_TSPTI. |
| @InstrumentID | Trade.Instrument | Implicit | Instrument must exist; FK enforced by Trade.ProviderToInstrument.FK_TSISR_TSPTI. |
| (procedure) | Trade.ProviderToInstrument | Writer (INSERT) | Creates a new provider-instrument config row. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by ops/admin tools directly; no stored procedure callers discovered in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrumentAdd (procedure)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | INSERT - creates a new provider-instrument config row. |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called directly by ops/admin application tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Add a new provider-instrument config

```sql
EXEC Trade.ProviderToInstrumentAdd
    @ProviderID = 1,
    @InstrumentID = 1234,
    @Precision = 5,
    @PaymentBid = -250,
    @PaymentAsk = 250,
    @PresentationCode = 'NEWPAIR=',
    @StopLossPercentage = 0,
    @EndOfWeekFee = 0.00,
    @Unit = 1000,
    @UnitMargin = 1000,
    @Benchmark = 10000,
    @LiquidityLotSize = 100000,
    @LiquidityLotCost = 0.00,
    @DisplayOrder = 999,
    @MarketRange = 10,
    @WeekendPips = NULL;
```

### 8.2 Verify the created row

```sql
SELECT ProviderID, InstrumentID, PresentationCode, Precision, Unit, Enabled
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 1234;
```

### 8.3 Check what defaults were applied post-creation

```sql
SELECT ProviderID, InstrumentID, Enabled, AllowBuy, AllowSell, AllowPendingOrders,
       MinPositionAmount, MaxPositionUnits, DefaultStopLossPercentage
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 1234;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrumentAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderToInstrumentAdd.sql*
