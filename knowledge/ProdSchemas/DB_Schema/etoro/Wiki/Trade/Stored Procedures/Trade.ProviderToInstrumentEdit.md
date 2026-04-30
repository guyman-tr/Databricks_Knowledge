# Trade.ProviderToInstrumentEdit

> Updates the core trading configuration parameters (precision, fees, spread, size limits, display) for an existing provider-instrument pair in Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID (composite PK lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderToInstrumentEdit is the UPDATE writer for the core configuration columns of Trade.ProviderToInstrument. It modifies the same 14 fields (minus the PK columns) that Trade.ProviderToInstrumentAdd inserts, allowing ops/admin to revise pricing precision, fees, unit sizes, spread, and display order for an existing provider-instrument pair.

This procedure exists to provide a controlled, single-point UPDATE path for the fundamental ProviderToInstrument configuration fields. The table is system-versioned (History.TradeProviderToInstrument), so every UPDATE is automatically captured as a history entry. More specialized configuration fields (AllowBuy, AllowSell, MinPositionAmount, etc.) are updated by other dedicated procedures.

Data flow: Called by ops/admin tools when reconfiguring an instrument's trading parameters (e.g., adjusting spread, changing lot sizes, updating end-of-week fees). The procedure applies a full overwrite of all 14 fields - callers must supply all values even if only one is changing. Returns @@ERROR (0 on success).

---

## 2. Business Logic

### 2.1 Full-Overwrite Pattern on Core Fields

**What**: All 14 non-PK fields are overwritten in every call. There is no partial-update logic.

**Columns/Parameters Involved**: All 14 non-PK parameters

**Rules**:
- UPDATE targets the row WHERE ProviderID = @ProviderID AND InstrumentID = @InstrumentID (composite PK).
- If no matching row exists, the UPDATE is a no-op (0 rows affected), @@ERROR = 0.
- All 14 columns are SET regardless of whether their values changed - callers must send the full current state.
- System versioning captures the pre-update row in History.TradeProviderToInstrument.
- AllowBuy, AllowSell, Enabled, and dozens of other Allow* columns are NOT updated here - they are managed by separate procedures.
- @MarketRange defaults to 10 if not supplied; @WeekendPips defaults to NULL.
- RETURN @@ERROR: returns 0 on success.

**Diagram**:
```
Caller -> Trade.ProviderToInstrumentEdit(@ProviderID, @InstrumentID, @Precision, ...)
    |
    v
UPDATE Trade.ProviderToInstrument SET Precision=@Precision, PaymentBid=@PaymentBid, ...
WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID
    |
    +-- System versioning: old row captured in History.TradeProviderToInstrument
    +-- RETURN @@ERROR
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Identifies the execution provider. Part of the composite PK WHERE filter. FK to Trade.Provider. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Identifies the tradeable instrument. Part of the composite PK WHERE filter. FK to Trade.Instrument. |
| 3 | @Precision | TINYINT | NO | - | CODE-BACKED | New decimal places for price display. Overwrites Trade.ProviderToInstrument.Precision. |
| 4 | @PaymentBid | INTEGER | NO | - | CODE-BACKED | New bid-side payment adjustment. Overwrites Trade.ProviderToInstrument.PaymentBid. |
| 5 | @PaymentAsk | INTEGER | NO | - | CODE-BACKED | New ask-side payment adjustment. Overwrites Trade.ProviderToInstrument.PaymentAsk. |
| 6 | @PresentationCode | VARCHAR(20) | NO | - | CODE-BACKED | New display code for the instrument (e.g., EURUSD=). Overwrites Trade.ProviderToInstrument.PresentationCode. |
| 7 | @StopLossPercentage | INTEGER | NO | - | CODE-BACKED | New legacy SL percentage. Overwrites Trade.ProviderToInstrument.StopLossPercentage. |
| 8 | @EndOfWeekFee | MONEY | NO | - | CODE-BACKED | New end-of-week holding fee. Overwrites Trade.ProviderToInstrument.EndOfWeekFee. |
| 9 | @Unit | INTEGER | NO | - | CODE-BACKED | New base unit size (e.g., 1000 for forex). Overwrites Trade.ProviderToInstrument.Unit. |
| 10 | @UnitMargin | INTEGER | NO | - | CODE-BACKED | New margin factor per unit. Overwrites Trade.ProviderToInstrument.UnitMargin. |
| 11 | @Benchmark | INTEGER | NO | - | CODE-BACKED | New reference value for pricing. Overwrites Trade.ProviderToInstrument.Benchmark. |
| 12 | @LiquidityLotSize | INTEGER | NO | - | CODE-BACKED | New lot size for liquidity provider orders. Overwrites Trade.ProviderToInstrument.LiquidityLotSize. |
| 13 | @LiquidityLotCost | MONEY | NO | - | CODE-BACKED | New cost per liquidity lot. Overwrites Trade.ProviderToInstrument.LiquidityLotCost. |
| 14 | @DisplayOrder | INTEGER | NO | - | CODE-BACKED | New sort order for UI display. Overwrites Trade.ProviderToInstrument.DisplayOrder. |
| 15 | @MarketRange | INTEGER | NO | 10 | CODE-BACKED | New market range validation limit. Defaults to 10 if not supplied. Overwrites Trade.ProviderToInstrument.MarketRange. |
| 16 | @WeekendPips | INTEGER | YES | NULL | CODE-BACKED | New weekend spread in pips. Defaults to NULL if not supplied. Overwrites Trade.ProviderToInstrument.WeekendPips. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID | Trade.ProviderToInstrument | Modifier (UPDATE) | Updates the row with this composite key. |
| @ProviderID | Trade.Provider | Implicit | Provider must exist to have a row to update. |
| @InstrumentID | Trade.Instrument | Implicit | Instrument must exist to have a row to update. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by ops/admin tools directly; no stored procedure callers discovered in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrumentEdit (procedure)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATE - overwrites core config fields for the specified provider-instrument pair. |

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

### 8.1 Update a provider-instrument configuration

```sql
EXEC Trade.ProviderToInstrumentEdit
    @ProviderID = 1,
    @InstrumentID = 1234,
    @Precision = 5,
    @PaymentBid = -300,
    @PaymentAsk = 300,
    @PresentationCode = 'NEWPAIR=',
    @StopLossPercentage = 0,
    @EndOfWeekFee = 0.00,
    @Unit = 1000,
    @UnitMargin = 1000,
    @Benchmark = 10000,
    @LiquidityLotSize = 100000,
    @LiquidityLotCost = 0.00,
    @DisplayOrder = 100,
    @MarketRange = 10,
    @WeekendPips = NULL;
```

### 8.2 Verify updated fields

```sql
SELECT ProviderID, InstrumentID, PresentationCode, Precision, PaymentBid, PaymentAsk,
       Unit, UnitMargin, EndOfWeekFee, MarketRange
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 1234;
```

### 8.3 View edit history via system versioning

```sql
SELECT ProviderID, InstrumentID, Precision, Unit, UnitMargin, SysStartTime, SysEndTime
FROM History.TradeProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 1234
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrumentEdit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderToInstrumentEdit.sql*
