# History.ProviderToInstrument

> High-volume versioned log of complete provider-instrument trading parameter snapshots, capturing the full configuration state (spreads, fees, lot sizes, limits) each time a provider's instrument parameters are updated.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ProviderToInstrumentVersionID (INT IDENTITY, clustered PK) |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 3 (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

`History.ProviderToInstrument` is a high-volume versioned audit log that captures complete snapshots of trading parameters for each provider-instrument pair (`ProviderID`, `InstrumentID`). Unlike SQL Server temporal tables (which are automatically maintained), this table uses application-managed `ValidFrom`/`ValidTo` intervals - each time a parameter changes, a new row is inserted with the new values and the previous row's `ValidTo` is set to the change timestamp.

The live configuration lives in `Trade.ProviderToInstrument` (enforced via FK `FK_TPVI_HPVI`). Each history row is a complete snapshot of all 21+ trading parameters at a point in time: spreads (`PaymentBid`/`PaymentAsk`), fees (`EndOfWeekFee`, `BuyEOWFee`, `SellEOWFee`, `BuyOverNightFee`, `SellOverNightFee`), position sizing (`Unit`, `UnitMargin`, `LiquidityLotSize`, `LiquidityLotCost`), risk limits (`StopLossPercentage`, `MaxStopLossPercentage`, `MarketRange`), display settings (`PresentationCode`, `DisplayOrder`), and instrument state (`Enabled`).

With 22,457,194 rows, this is one of the largest tables in the History schema - reflecting very high-frequency parameter updates (pricing parameters for thousands of instruments change continuously). The sentinel `ValidTo = '3000-01-01'` identifies currently-active configurations.

---

## 2. Business Logic

### 2.1 Application-Managed Versioning Pattern

**What**: Application inserts new rows and closes old rows via ValidFrom/ValidTo. NOT a SQL Server temporal table.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `ProviderToInstrumentVersionID`

**Rules**:
- `ValidTo = '3000-01-01 00:00:00.000'` sentinel = this version is currently active
- When parameters change: set old row's ValidTo = change_time, insert new row with ValidFrom = change_time, ValidTo = '3000-01-01'
- Multiple rows per (ProviderID, InstrumentID): all past versions plus exactly one current version
- `ProviderToInstrumentVersionID` IDENTITY is NOT FOR REPLICATION (prevents identity gaps on replication)
- FK `FK_TPVI_HPVI` references `Trade.ProviderToInstrument(ProviderID, InstrumentID)` - ensures only valid provider-instrument pairs get history rows

### 2.2 Payment Bid/Ask Spread

**What**: PaymentBid and PaymentAsk define the spread charged when customers buy/sell this instrument through this provider.

**Columns/Parameters Involved**: `PaymentBid`, `PaymentAsk`, `Precision`

**Rules**:
- Values stored as integer pip increments (scaled by 10^Precision)
- Negative PaymentBid = the bid side of the spread subtracts from the price (e.g., -250 at Precision=3 = -0.250 price units)
- Positive PaymentAsk = the ask side adds to the price (e.g., +250 at Precision=3 = +0.250 price units)
- Together, PaymentBid + |PaymentAsk| defines the total spread width
- `Precision` (tinyint): decimal precision of the price representation (e.g., 3 = xxx.xxx, 5 = xxx.xxxxx)
- `MinimumSpread` (dtPrice): minimum enforced spread, regardless of PaymentBid/Ask settings

### 2.3 Fee Structure

**What**: Multiple fee types govern end-of-week and overnight holding costs.

**Columns/Parameters Involved**: `EndOfWeekFee`, `WeekendPips`, `BuyEOWFee`, `SellEOWFee`, `BuyOverNightFee`, `SellOverNightFee`, `EtoroHoldingFeeSpreadFactor`

**Rules**:
- `EndOfWeekFee` (money): legacy end-of-week fee
- `BuyEOWFee`/`SellEOWFee`: separate buy/sell direction end-of-week fees (supersede EndOfWeekFee for directional differentiation)
- `BuyOverNightFee`/`SellOverNightFee`: overnight (swap/rollover) fees per direction
- `EtoroHoldingFeeSpreadFactor` DEFAULT 1: multiplier applied to holding fees; 1 = standard rate
- `WeekendPips` (nullable): additional pips charged over the weekend for CFD positions

### 2.4 Position Sizing and Liquidity

**What**: Lot size and cost parameters define how positions are sized and hedged in the market.

**Columns/Parameters Involved**: `Unit`, `UnitMargin`, `LiquidityLotSize`, `LiquidityLotCost`

**Rules**:
- `Unit`: base trading unit size for customer positions
- `UnitMargin`: margin required per unit
- `LiquidityLotSize`: lot size used when hedging in the external market
- `LiquidityLotCost`: cost per liquidity lot (for cost-of-carry calculations)

---

## 3. Data Overview

22,457,194 rows. Very high volume - parameters updated continuously. Most recent rows from 2026-03-20.

| ProviderID | InstrumentID | Precision | PaymentBid | PaymentAsk | ValidFrom | ValidTo | Enabled |
|---|---|---|---|---|---|---|---|
| 1 | 1 | 3 | -250 | 250 | 2026-03-20 19:36:38 | 3000-01-01 (active) | 1 |
| 1 | 2 | 5 | -50 | 50 | 2026-03-20 19:36:38 | 3000-01-01 (active) | 1 |
| 1 | 3 | 5 | 0 | 0 | 2026-03-20 19:36:38 | 3000-01-01 (active) | 1 |

*All currently-active rows updated on 2026-03-20 (likely a batch recalculation event). PaymentBid/Ask of 0 on InstrumentID=3 suggests zero-spread or market-price instrument.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderToInstrumentVersionID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | auto | VERIFIED | Auto-incrementing version row ID. Clustered PK. NOT FOR REPLICATION prevents identity gaps on replication targets. |
| 2 | ValidFrom | datetime | NO | - | VERIFIED | Application-set timestamp when this configuration version became active. |
| 3 | ValidTo | datetime | NO | - | VERIFIED | Application-set timestamp when this version was superseded. Sentinel '3000-01-01' = currently active. |
| 4 | ProviderID | int | NO | - | VERIFIED | Price/execution provider. Part of FK to Trade.ProviderToInstrument. HPVI_PROVIDER index covers (ProviderID, InstrumentID) lookups. |
| 5 | InstrumentID | int | NO | - | VERIFIED | Financial instrument. Part of FK to Trade.ProviderToInstrument. HPVI_INSTRUMENT index covers per-instrument queries. |
| 6 | Precision | tinyint | NO | - | VERIFIED | Decimal precision of the price for this instrument (number of decimal places). Used to scale PaymentBid/Ask integer values to price units. |
| 7 | PaymentBid | int | NO | - | VERIFIED | Bid-side spread adjustment in pip units (scaled by Precision). Typically negative (subtracts from mid-price). PaymentBid = -250 at Precision=3 means bid is 0.250 below mid. |
| 8 | PaymentAsk | int | NO | - | VERIFIED | Ask-side spread adjustment in pip units. Typically positive (adds to mid-price). PaymentAsk = 250 at Precision=3 means ask is 0.250 above mid. Total spread = ABS(PaymentBid) + PaymentAsk in pip units. |
| 9 | PresentationCode | varchar(20) | NO | - | VERIFIED | The display code/ticker used to present this instrument to customers (e.g., "AAPL", "EUR/USD"). May differ from internal instrument identifiers. |
| 10 | StopLossPercentage | int | NO | - | VERIFIED | Default stop loss percentage offered for this instrument. Represents the maximum allowed stop loss distance as a percentage of position value. |
| 11 | EndOfWeekFee | money | NO | - | VERIFIED | Legacy end-of-week fee charged for holding positions over the weekend. Superseded by BuyEOWFee/SellEOWFee for directional differentiation but maintained for compatibility. |
| 12 | Unit | int | NO | - | VERIFIED | Base trading unit size. Determines minimum position granularity for customer trades. |
| 13 | UnitMargin | int | NO | - | VERIFIED | Margin required per unit of this instrument when traded through this provider. |
| 14 | Benchmark | int | YES | - | CODE-BACKED | Reference benchmark value for this instrument. Nullable - not all instruments have a defined benchmark. Used for performance attribution or spread calculations. |
| 15 | LiquidityLotSize | int | NO | - | VERIFIED | Standard lot size used when eToro hedges customer positions in the external liquidity market. |
| 16 | LiquidityLotCost | money | NO | - | VERIFIED | Cost of one liquidity lot. Used for calculating hedging costs and P&L impact. |
| 17 | DisplayOrder | int | NO | - | VERIFIED | Sort order for presenting this instrument in lists/menus to customers. Lower = appears earlier. |
| 18 | WeekendPips | int | YES | - | CODE-BACKED | Additional pip charge applied to CFD positions held over the weekend. Nullable - not applied to all instruments. |
| 19 | MinimumSpread | dbo.dtPrice | YES | - | CODE-BACKED | Minimum enforced spread (using the dtPrice user-defined type). Prevents the effective spread from going below this floor regardless of PaymentBid/Ask settings. |
| 20 | MarketRange | int | YES | - | CODE-BACKED | Maximum allowable price movement (in pips) from the quoted price for order acceptance. Orders outside this range are rejected. Nullable - not all instruments have market range limits. |
| 21 | EtoroHoldingFeeSpreadFactor | money | NO | DEFAULT 1 | VERIFIED | Multiplier applied to eToro's holding/financing fees. DEFAULT 1 = standard rate. Values > 1 increase fees; < 1 reduce them. |
| 22 | BuyEOWFee | money | YES | - | VERIFIED | End-of-week fee for long (buy) positions. Directional version of EndOfWeekFee. Nullable for instruments without separate buy/sell fee differentiation. |
| 23 | SellEOWFee | money | YES | - | VERIFIED | End-of-week fee for short (sell) positions. Directional counterpart to BuyEOWFee. |
| 24 | BuyOverNightFee | money | YES | - | VERIFIED | Overnight (swap/rollover) fee for long positions. Charged daily for leveraged CFD positions held overnight. |
| 25 | SellOverNightFee | money | YES | - | VERIFIED | Overnight fee for short positions. Together with BuyOverNightFee forms the complete overnight cost structure. |
| 26 | MaxStopLossPercentage | decimal(5,2) | YES | - | CODE-BACKED | Maximum allowed stop loss percentage for this instrument. Upper bound on how far a stop loss can be placed from the entry price. |
| 27 | Enabled | tinyint | YES | - | VERIFIED | Whether this provider-instrument pair is currently active for trading. 1 = enabled (active), 0 or NULL = disabled. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (ProviderID, InstrumentID) | Trade.ProviderToInstrument | FK (FK_TPVI_HPVI) | The live provider-instrument configuration this history row belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer / Trade procedures) | INSERT/UPDATE | WRITER | Application-managed versioning - new rows inserted when parameters change |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderToInstrument (table)
    |
    +-> Trade.ProviderToInstrument (FK: FK_TPVI_HPVI on ProviderID, InstrumentID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK parent - ensures only valid provider-instrument pairs get history rows |
| dbo.dtPrice | User Defined Type | Used for MinimumSpread column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Trade platform) | External | READER/WRITER - queries this table to reconstruct historical instrument parameters |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPVI | CLUSTERED PK | ProviderToInstrumentVersionID ASC | - | - | Active |
| HPVI_INSTRUMENT | NONCLUSTERED | InstrumentID ASC | - | - | Active |
| HPVI_PROVIDER | NONCLUSTERED | ProviderID ASC, InstrumentID ASC | - | - | Active |

*ON [HISTORY] filegroup, FILLFACTOR=90. The HPVI_PROVIDER (ProviderID, InstrumentID) composite index supports the primary access pattern: "find all versions for this provider/instrument pair".*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPVI | PK | ProviderToInstrumentVersionID clustered PK |
| FK_TPVI_HPVI | FK | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument(ProviderID, InstrumentID) |
| DF_HistoryProviderToInstrument_EtoroHoldingFeeSpreadFactor | DEFAULT | `1` on EtoroHoldingFeeSpreadFactor |

---

## 8. Sample Queries

### 8.1 Current active parameters for a specific instrument

```sql
SELECT ProviderID, InstrumentID, Precision, PaymentBid, PaymentAsk,
    StopLossPercentage, EndOfWeekFee, Enabled, ValidFrom
FROM History.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND ValidTo = '3000-01-01 00:00:00.000'
ORDER BY ProviderID
```

### 8.2 Full parameter history for a provider-instrument pair

```sql
SELECT ProviderToInstrumentVersionID, PaymentBid, PaymentAsk,
    EndOfWeekFee, BuyOverNightFee, SellOverNightFee,
    Enabled, ValidFrom, ValidTo
FROM History.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = @ProviderID AND InstrumentID = @InstrumentID
ORDER BY ValidFrom ASC
```

### 8.3 Parameter state at a specific point in time

```sql
SELECT ProviderID, InstrumentID, Precision, PaymentBid, PaymentAsk,
    EndOfWeekFee, BuyOverNightFee, ValidFrom, ValidTo
FROM History.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = @ProviderID AND InstrumentID = @InstrumentID
  AND ValidFrom <= @AsOfDate
  AND (ValidTo > @AsOfDate OR ValidTo = '3000-01-01')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderToInstrument | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderToInstrument.sql*
