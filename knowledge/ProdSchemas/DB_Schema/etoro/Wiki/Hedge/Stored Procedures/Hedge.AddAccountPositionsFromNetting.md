# Hedge.AddAccountPositionsFromNetting

> Computes and inserts open hedge position records for all accounts of a given hedge server by calculating unrealized P&L and hedged units directly from the live Netting table and current market prices.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.AccountOpenPositions; reads Hedge.Netting + Trade.CurrencyPrice |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddAccountPositionsFromNetting` populates the open hedge position store by deriving position values computationally from raw netting data. It is the alternative to `Hedge.AddAccountOpenPositions` (which receives pre-computed values) - here, all values are calculated on the fly by joining the Netting table against live market prices.

The procedure answers: "given the current netting positions and market rates, what is each liquidity account's open hedge position right now?" It calculates unrealized P&L (PNL = (Bid - AvgRate) * Units for buys, (AvgRate - Ask) * Units for sells), applies currency conversion to USD, and determines the hedged unit count.

This procedure exists to allow the system to reconstruct the open position snapshot from first principles (the netting book + market prices), rather than relying on values passed by the hedge engine. This makes it useful for reconciliation, recovery, and scenarios where the hedge engine's pre-computed values are unavailable. The comment "Retrieving data (with zeros) even if there is no data from the required hedge server" clarifies that the LEFT JOIN to the netting subquery deliberately returns zero-valued rows for all accounts of the hedge server even when no positions exist - ensuring completeness.

Change history: NoLock hints added 25/05/2016 (issue 36740). `GetNetOpenInUSD` removed 2020-01-30 (replaced with `NetHedgedInUSD = 0` constant).

---

## 2. Business Logic

### 2.1 P&L Calculation from Netting + Market Prices

**What**: Unrealized P&L is computed per-instrument from the netting position's average rate vs the current bid/ask.

**Columns/Parameters Involved**: `IsBuy`, `AvgRate`, `Units`, `Bid`, `Ask`

**Rules**:
- Buy positions (IsBuy=1): PNL = (Bid - AvgRate) * Units
- Sell positions (IsBuy=0): PNL = (AvgRate - Ask) * Units
- Converted to USD: PNL is multiplied by conversionRate (if reciprocal=0) or divided (if reciprocal=1)
- Wrapped in ISNULL(..., 0) so null prices result in zero rather than NULL P&L

**Diagram**:
```
Hedge.Netting (IsBuy, AvgRate, Units)
      |
      JOIN Trade.CurrencyPrice (Bid, Ask, PriceRateID)
      |
      +--IsBuy=1--> PNL = (Bid - AvgRate) * Units
      +--IsBuy=0--> PNL = (AvgRate - Ask) * Units
      |
      JOIN Trade.InstrumentConversion (reciprocal, ConversionInstrumentID)
      |
      +--reciprocal=0--> UnrealizedNetPL = PNL * conversionRate
      +--reciprocal=1--> UnrealizedNetPL = PNL / conversionRate
```

### 2.2 Zero-Row Guarantee for All Accounts

**What**: Every account linked to the hedge server gets a row, even if it has no netting positions.

**Columns/Parameters Involved**: `@HedgeServerID`

**Rules**:
- Outer loop is `Hedge.HedgeServerToLiquidityAccount` (all accounts for this server)
- LEFT JOIN to netting subquery - unmatched accounts get NULL, converted to 0 via ISNULL
- `InstrumentID` defaults to 1 when NULL: `ISNULL(InstrumentID, 1)`
- `NetHedgedInUSD` is always 0 (GetNetOpenInUSD was removed 2020)
- `AmountInUnitsDecimal` defaults to 0 when NULL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | Int | NO | - | CODE-BACKED | Hedge server whose open positions are being computed and inserted. Drives the filter on Hedge.Netting (HN.HedgeServerID=@HedgeServerID) and the account enumeration from Hedge.HedgeServerToLiquidityAccount. FK to Trade.HedgeServer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.Netting | JOIN | Source of net position data (AvgRate, Units, IsBuy) per instrument and account |
| (reads) | Hedge.HedgeServerToLiquidityAccount | JOIN | Enumerates all liquidity accounts for the given hedge server |
| (reads) | Trade.CurrencyPrice | JOIN | Provides current Bid/Ask prices and PriceRateID for P&L calculation |
| (reads) | Trade.ProviderToInstrument | LEFT JOIN | Provides Unit (lot size) for LotCountDecimal calculation |
| (reads) | Trade.GetInstrument | LEFT JOIN | Provides SellCurrencyID for finding the conversion instrument |
| (reads) | Trade.InstrumentConversion | LEFT JOIN | Provides the USD conversion rate and reciprocal flag |
| (writes) | Hedge.AccountOpenPositions | INSERT | Target table receiving the computed open position records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called externally (hedge server or reconciliation jobs).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddAccountPositionsFromNetting (procedure)
├── Hedge.HedgeServerToLiquidityAccount (table)
├── Hedge.Netting (table)
├── Trade.CurrencyPrice (table)
├── Trade.ProviderToInstrument (table)
├── Trade.GetInstrument (table/view)
├── Trade.InstrumentConversion (table)
└── Hedge.AccountOpenPositions (table - not in SSDT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | Outer loop: enumerates all accounts for the hedge server |
| Hedge.Netting | Table | Source of aggregate hedge positions (AvgRate, Units, IsBuy, LiquidityAccountID) |
| Trade.CurrencyPrice | Table | Current market prices (Bid, Ask, PriceRateID) for P&L computation |
| Trade.ProviderToInstrument | Table | Lot size (Unit) for LotCountDecimal |
| Trade.GetInstrument | Table/View | SellCurrencyID for identifying conversion instrument |
| Trade.InstrumentConversion | Table | USD conversion rate and reciprocal flag |
| Hedge.AccountOpenPositions | Table | INSERT target (not in SSDT project) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (External hedge reconciliation jobs) | External | Calls to regenerate open position data from netting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. All null-safety handled via ISNULL wrappers on computed fields.

---

## 8. Sample Queries

### 8.1 Execute: Compute and insert open positions from netting for hedge server 1

```sql
EXEC Hedge.AddAccountPositionsFromNetting @HedgeServerID = 1
```

### 8.2 Preview: Simulate the P&L calculation without inserting

```sql
SELECT
    H.HedgeServerID,
    H.LiquidityAccountID,
    ISNULL(HN.InstrumentID, 1) AS InstrumentID,
    ISNULL(
        CASE WHEN HN.IsBuy = 1 THEN (TCP.Bid - HN.AvgRate) * HN.Units
             ELSE (HN.AvgRate - TCP.Ask) * HN.Units END,
        0) AS UnrealizedNetPL_Raw
FROM Hedge.HedgeServerToLiquidityAccount H WITH (NOLOCK)
LEFT JOIN Hedge.Netting HN WITH (NOLOCK) ON HN.HedgeServerID = H.HedgeServerID AND HN.LiquidityAccountID = H.LiquidityAccountID
LEFT JOIN Trade.CurrencyPrice TCP WITH (NOLOCK) ON HN.InstrumentID = TCP.InstrumentID
WHERE H.HedgeServerID = 1
```

### 8.3 Compare computed open positions against the stored netting book

```sql
SELECT
    HN.HedgeServerID,
    HN.LiquidityAccountID,
    HN.InstrumentID,
    HN.Units,
    HN.IsBuy,
    HN.AvgRate,
    TCP.Bid,
    (CASE WHEN HN.IsBuy = 1 THEN (TCP.Bid - HN.AvgRate) ELSE (HN.AvgRate - TCP.Ask) END) * HN.Units AS EstimatedPnL
FROM Hedge.Netting HN WITH (NOLOCK)
JOIN Trade.CurrencyPrice TCP WITH (NOLOCK) ON HN.InstrumentID = TCP.InstrumentID
WHERE HN.HedgeServerID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddAccountPositionsFromNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddAccountPositionsFromNetting.sql*
