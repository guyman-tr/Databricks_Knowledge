# Trade.CurrencyPrice_SnapShot

> Point-in-time snapshot of CurrencyPrice used for manual position close (crisis/casing flow). Captures Bid/Ask at snapshot moment for consistent close pricing when live prices may have moved.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID (implicit composite) |
| **Partition** | No |
| **Indexes** | 0 (no PK or indexes in DDL) |

---

## 1. Business Meaning

Trade.CurrencyPrice_SnapShot holds a frozen copy of price data (Bid, Ask, ProviderID, InstrumentID, Occurred, PriceRateID, UnitMargin) used when closing positions under manual/crisis scenarios. Trade.ManualPositionClose_Casing reads from this table to obtain Bid and Ask for a given instrument, then passes them to Trade.ManualPositionClose_Crisis for execution. This ensures that during a manual close, the system uses a stable snapshot rather than live moving prices.

This table exists because in crisis or casing workflows, the dealer needs predictable, point-in-time prices rather than real-time ticks that could change between decision and execution. The snapshot is populated by an external process (e.g., snapshot job or trigger referenced in Trade.InsertBSLMInstruction / Trade.CurrencyPrice doc) before manual close operations. Data flows: Snapshot process populates rows; Trade.ManualPositionClose_Casing SELECTs Bid and Ask by InstrumentID (via PositionTbl JOIN) and passes to ManualPositionClose_Crisis.

---

## 2. Business Logic

### 2.1 Snapshot for Manual Close

**What**: Bid and Ask at a fixed moment in time, keyed by (ProviderID, InstrumentID), used for manual position close pricing.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Bid`, `Ask`, `Occurred`, `PriceRateID`, `UnitMargin`

**Rules**:
- Trade.ManualPositionClose_Casing joins CurrencyPrice_SnapShot to PositionTbl on InstrumentID to get the position's instrument.
- It selects Bid and Ask as @BidSpread and @AskSpread and passes them to ManualPositionClose_Crisis.
- Snapshot must be refreshed periodically by a separate process (not visible in Trade procedures).

### 2.2 Reduced Column Set vs CurrencyPrice

**What**: SnapShot has fewer columns than live Trade.CurrencyPrice (no BidDiscounted, AskDiscounted, SkewValue*, USDConversion*).

**Rules**: Manual close uses raw Bid/Ask; discounted and conversion columns are not needed for this flow. Structure aligns with legacy/simplified price snapshot.

---

## 3. Data Overview

| ProviderID | InstrumentID | Bid | Ask | Occurred | PriceRateID | UnitMargin | Meaning |
|------------|--------------|-----|-----|----------|-------------|------------|---------|
| (No live data sampled) | - | - | - | - | - | - | Snapshot table; MCP query returned empty. Populated by snapshot job before manual close. |

**Selection criteria**: Table may be populated on demand or in specific environments. Structure from DDL; usage from Trade.ManualPositionClose_Casing.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Provider identifier. Implicit FK to Trade.Provider. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. Implicit FK to Trade.Instrument. |
| 3 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Snapshot bid rate. ManualPositionClose_Casing reads as @BidSpread. |
| 4 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Snapshot ask rate. ManualPositionClose_Casing reads as @AskSpread. |
| 5 | Occurred | datetime | NO | - | CODE-BACKED | When snapshot was taken. |
| 6 | OccurredOnServer | datetime | NO | - | CODE-BACKED | Server timestamp of price reception. |
| 7 | PriceRateID | bigint | NO | - | CODE-BACKED | Tick/rate identifier. |
| 8 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | When price server received the tick. |
| 9 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market rate ID. |
| 10 | LastPrice | dbo.dtPrice | NO | - | CODE-BACKED | Last traded/reference price. |
| 11 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for bid source. |
| 12 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for ask source. |
| 13 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Markup in pips. |
| 14 | UnitMargin | decimal(12,5) | YES | - | CODE-BACKED | Margin per unit for P&L. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Trade.Provider | Implicit | Provider lookup. |
| InstrumentID | Trade.Instrument | Implicit | Instrument lookup. |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManualPositionClose_Casing | FROM | Reader | SELECTs Bid, Ask by InstrumentID for manual close. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CurrencyPrice_SnapShot (table)
└── Trade.Provider (implicit)
└── Trade.Instrument (implicit)
     └── Trade.PositionTbl (ManualPositionClose_Casing joins Position.InstrumentID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | Implicit ProviderID lookup |
| Trade.Instrument | Table | Implicit InstrumentID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManualPositionClose_Casing | Procedure | SELECT Bid, Ask for manual close |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (None) | - | - | - | - | No indexes in DDL |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| (None) | - | No PK, FK, or check constraints in DDL |

---

## 8. Sample Queries

### 8.1 Get snapshot price for an instrument
```sql
SELECT ProviderID, InstrumentID, Bid, Ask, Occurred, UnitMargin
  FROM Trade.CurrencyPrice_SnapShot CPS WITH (NOLOCK)
 WHERE InstrumentID = 1
```

### 8.2 Resolve snapshot with instrument and position
```sql
SELECT TISR.PositionID, TISR.InstrumentID, CPS.Bid, CPS.Ask
  FROM Trade.PositionTbl TISR WITH (NOLOCK)
  JOIN Trade.CurrencyPrice_SnapShot CPS WITH (NOLOCK)
    ON CPS.InstrumentID = TISR.InstrumentID
 WHERE TISR.PositionID = @PositionID
```

### 8.3 Compare snapshot vs live price
```sql
SELECT CPS.InstrumentID, CPS.Bid AS SnapshotBid, CP.Bid AS LiveBid,
       CPS.Ask AS SnapshotAsk, CP.Ask AS LiveAsk
  FROM Trade.CurrencyPrice_SnapShot CPS WITH (NOLOCK)
  JOIN Trade.CurrencyPrice CP WITH (NOLOCK)
    ON CP.ProviderID = CPS.ProviderID AND CP.InstrumentID = CPS.InstrumentID
 WHERE CPS.InstrumentID IN (1, 5, 10)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: SSDT DDL, Trade.ManualPositionClose_Casing, Trade.CurrencyPrice doc | Procedures: 1 | Corrections: 0 applied*
*Object: Trade.CurrencyPrice_SnapShot | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CurrencyPrice_SnapShot.sql*
