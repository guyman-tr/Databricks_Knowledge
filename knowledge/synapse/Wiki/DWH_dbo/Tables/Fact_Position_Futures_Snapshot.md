# DWH_dbo.Fact_Position_Futures_Snapshot

> Daily settlement-time snapshot of all futures positions — captures the position state (lots, invested amount, margins) and mark-to-market PnL at the futures settlement price for each trading day.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact — periodic snapshot) |
| **Row Count** | Millions (one row per position per settlement date) |
| **Production Source** | DWH-computed from Dim_Position, Dim_Instrument_Snapshot, Fact_Settlement_Prices, Dim_PositionChangeLog |
| **Refresh** | Daily — DELETE for date + INSERT from computed temp tables |
| | |
| **Synapse Distribution** | HASH(PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Fact_Position_Futures_Snapshot` is a daily point-in-time record of every futures position at settlement time. Unlike CFDs which are marked-to-market continuously, futures positions settle at a specific daily settlement price. This table reconstructs what each position looked like at the settlement moment — accounting for partial closes, lot changes, and margin adjustments.

Two categories of positions are captured:
- **OpenAtSettlement**: Positions that were still open at the settlement time
- **ClosedBeforeSettlement**: Positions that closed between the previous settlement and current settlement

The table answers:
- "What was this position worth at settlement?" (mark-to-market PnL using settlement price)
- "What were the original vs. residual metrics after partial closes?"
- "What margin did eToro and the provider require for this position?"

### Key Business Concepts

- **Settlement Price**: Official end-of-day price from `Fact_Settlement_Prices`. The latest available price within 14 days is used (not every instrument has daily settlement prices)
- **Initial Full vs Residual**: For partially closed positions, "Full" = the original position size at open, "Residual" = the remaining position after partial closes
- **ProviderMargin/eToroMargin**: Margin required by the liquidity provider and by eToro, computed as `LotCount × MarginPerLot`
- **Mark-to-Market PnL** (open positions): `LotCountDecimal × Multiplier × SettlementPrice - LotCountDecimal × Multiplier × InitForexRate`

Created: 2024-11-11 by Guy Manova.

---

## 2. Business Logic

### 2.1 Position Categories

**OpenAtSettlement**: From `Dim_Position` where `CloseOccurred > SettlementTime OR CloseOccurred = 0` AND `OpenOccurred <= SettlementTime`. Excludes partial close children (`IsPartialCloseChild = 0`).

**ClosedBeforeSettlement**: From `Dim_Position` where `CloseOccurred` is between previous settlement time and current settlement time.

### 2.2 Changelog Reconstruction

Position metrics (LotCountDecimal, InvestedAmount, margins) change over time via partial closes and adjustments. The SP uses `Dim_PositionChangeLog` (ChangeTypeID: 0=Open, 1=AmountChange, 11=PartialCloseChild, 12=PartialClose) to reconstruct the position state at the exact settlement time.

### 2.3 Open Position PnL

```
PnL = (LotCountDecimal × Multiplier × SettlementPrice) 
    - (LotCountDecimal × Multiplier × InitForexRate)
```

Closed position PnL uses `Dim_Position.NetProfit` directly.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(PositionID) enables co-located JOINs with other position-level tables. CLUSTERED COLUMNSTORE provides good compression for date-range analytical scans. Always filter on DateID.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer details |
| DWH_dbo.Dim_Instrument | ON InstrumentID = InstrumentID | Instrument name/asset class |
| DWH_dbo.Dim_Position | ON PositionID = PositionID | Full position details |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes |

### 3.3 Gotchas

- **OpenAtSettlement PnL**: Mark-to-market using settlement price, NOT the live market price. This is the official valuation
- **CloseOccurred = '1900-01-01'**: For open positions, CloseOccurred is set to a sentinel date, not NULL
- **Settlement price gaps**: LEFT JOINed to `Fact_Settlement_Prices` — if no settlement price exists within 14 days, SettlementPrice will be NULL
- **Partial close complexity**: LotCountDecimal on open positions is adjusted to reflect the residual lots at settlement time, not the original lot count

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Settlement date. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 2 | DateID | int | NO | Settlement date in YYYYMMDD format. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 3 | SettlementCategory | varchar(100) | NO | 'OpenAtSettlement' = position still open at settlement time. 'ClosedBeforeSettlement' = position closed between prev and current settlement. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 4 | CID | int | NO | Customer ID (Real account). (Tier 2 — Dim_Position) |
| 5 | PositionID | bigint | NO | Unique position identifier. Distribution key. (Tier 2 — Dim_Position) |
| 6 | OriginalPositionID | bigint | YES | Parent position ID for partial-close child positions. Equals PositionID for non-partial positions. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 7 | InstrumentID | int | NO | Futures instrument traded. JOINs to Dim_Instrument. Only IsFuture=1 instruments included. (Tier 2 — Dim_Instrument_Snapshot) |
| 8 | LotCountDecimal | decimal(38,18) | YES | Number of lots at settlement time. Adjusted for partial closes via changelog reconstruction. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 9 | SettlementTime | datetime2(7) | YES | Exact settlement time from Dim_Instrument_Snapshot. Varies by instrument. (Tier 2 — Dim_Instrument_Snapshot) |
| 10 | SettlementPrice | decimal(38,18) | YES | Official settlement price from Fact_Settlement_Prices. Latest available within 14-day lookback. NULL if no settlement price found. (Tier 2 — Fact_Settlement_Prices) |
| 11 | InvestedAmount | money | YES | Cash invested in the position at settlement time. Mapped from Dim_Position.Amount, adjusted for changelog changes. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 12 | OpenOccurred | datetime | NO | When the position was originally opened. (Tier 2 — Dim_Position) |
| 13 | CloseOccurred | datetime | NO | When the position was closed. '1900-01-01' for open positions. (Tier 2 — Dim_Position / SP sentinel) |
| 14 | InitForexRate | decimal(16,8) | YES | Opening price / forex rate at position open. Used in mark-to-market PnL calculation. (Tier 2 — Dim_Position) |
| 15 | EndForexRate | decimal(16,8) | YES | Closing price / forex rate at position close. NULL for open positions. (Tier 2 — Dim_Position) |
| 16 | IsPartialCloseParent | int | YES | 1 = position has been partially closed (some lots removed). 0 = full position. Reconstructed from changelog. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 17 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Fact_Position_Futures_Snapshot) |
| 18 | IsBuy | bit | YES | Direction: 1 = long (buy), 0 = short (sell). (Tier 2 — Dim_Position) |
| 19 | ProviderID | int | YES | Liquidity provider for this futures instrument. From Dim_Instrument_Snapshot. (Tier 2 — Dim_Instrument_Snapshot) |
| 20 | Multiplier | decimal(38,18) | YES | Contract size multiplier. From Dim_Instrument_Snapshot. Used in PnL: LotCount × Multiplier × Price. (Tier 2 — Dim_Instrument_Snapshot) |
| 21 | ProviderMargin | int | YES | Margin required by the liquidity provider: LotCountDecimal × ProviderMarginPerLot. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 22 | eToroMargin | int | YES | Margin required by eToro: LotCountDecimal × eToroMarginPerLot. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 23 | PnL | money | YES | Mark-to-market PnL. Open: `LotCount × Multiplier × (SettlementPrice - InitForexRate)`. Closed: Dim_Position.NetProfit. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 24 | InitialLotCountDecimalFull | decimal(38,18) | YES | Original lot count at position open (before any partial closes). (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 25 | InitialInvestedAmountFull | money | YES | Original invested amount at position open (before any partial closes). (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 26 | InitialProviderMarginFull | decimal(38,18) | YES | Original provider margin at position open: InitialLotCount × ProviderMarginPerLot. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 27 | InitialeToroMarginFull | decimal(38,18) | YES | Original eToro margin at position open: InitialLotCount × eToroMarginPerLot. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 28 | InitialLotCountDecimalResidual | decimal(18,6) | YES | Residual lot count at settlement (after partial closes). Equals LotCountDecimal. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 29 | InitialInvestedAmountResidual | money | YES | Pro-rated invested amount based on residual lot ratio: InitialInvestedAmount × (ResidualLots / FullLots). (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 30 | InitialProviderMarginResidual | decimal(18,6) | YES | Residual provider margin: ProviderMarginPerLot × ResidualLotCount. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 31 | InitialeToroMarginResidual | decimal(18,6) | YES | Residual eToro margin: eToroMarginPerLot × ResidualLotCount. (Tier 2 — SP_Fact_Position_Futures_Snapshot) |
| 32 | UpdateDate | datetime | NO | ETL load timestamp — GETDATE(). (Tier 2 — SP_Fact_Position_Futures_Snapshot) |

---

## 5. Lineage

### 5.1 Pipeline

```
Dim_Position + Dim_Instrument_Snapshot (IsFuture=1) + Fact_Settlement_Prices + Dim_PositionChangeLog
    │
    └─ SP_Fact_Position_Futures_Snapshot(@dt)
        ├─ #Fact_Settlement_Prices_LastPrices (latest settlement price per instrument)
        ├─ #openAtSettlement (positions open at settlement)
        ├─ #ClosedInSettlement (positions closed before settlement)
        ├─ #changelog (position change events)
        ├─ #originMetrics (original position state at open)
        ├─ #firstPartial (first partial close event)
        ├─ UPDATE: adjust lot counts, invested amounts, margins
        ├─ UPDATE: mark-to-market PnL for open positions
        ├─ #prepOpens, #prepClosed (add initial full/residual metrics)
        └─ INSERT INTO Fact_Position_Futures_Snapshot
```

### 5.2 Key Source Tables

| Source | Columns Used |
|--------|-------------|
| Dim_Position | CID, PositionID, InstrumentID, LotCountDecimal, Amount, OpenOccurred, CloseOccurred, InitForexRate, EndForexRate, IsBuy, NetProfit |
| Dim_Instrument_Snapshot | SettlementTime, ProviderID, Multiplier, ProviderMarginPerLot, eToroMarginPerLot, IsFuture |
| Fact_Settlement_Prices | SettlementPrice (latest within 14 days) |
| Dim_PositionChangeLog | LotCountDecimal changes, InvestedAmount changes, partial close events |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer |
| PositionID | DWH_dbo.Dim_Position | Position details |
| InstrumentID | DWH_dbo.Dim_Instrument | Futures instrument |
| DateID | DWH_dbo.Dim_Date | Settlement date |
| ProviderID | DWH_dbo.Dim_Provider | Liquidity provider |

---

## 7. Sample Queries

### 7.1 Daily futures exposure by instrument

```sql
SELECT
    f.DateID,
    i.InstrumentName,
    COUNT(DISTINCT f.CID) AS UniqueCustomers,
    SUM(f.InvestedAmount) AS TotalInvested,
    SUM(f.PnL) AS TotalPnL
FROM DWH_dbo.Fact_Position_Futures_Snapshot f
JOIN DWH_dbo.Dim_Instrument i ON f.InstrumentID = i.InstrumentID
WHERE f.DateID >= 20260301
  AND f.SettlementCategory = 'OpenAtSettlement'
GROUP BY f.DateID, i.InstrumentName
ORDER BY f.DateID DESC, TotalInvested DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian search performed — DWH-internal computation. SP authored by Guy Manova (2024-11), modified by Inbal BML and Guy M through 2025.

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped, DWH-internal computation)*
*Tiers: 0 T1, 32 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Fact_Position_Futures_Snapshot | Type: Table | Production Source: DWH-computed (Dim_Position + settlement prices)*
