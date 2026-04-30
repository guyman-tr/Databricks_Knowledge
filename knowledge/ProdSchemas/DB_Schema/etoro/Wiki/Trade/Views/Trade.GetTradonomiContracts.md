# Trade.GetTradonomiContracts

> Denormalized view exposing Tradonomi contracts with instrument abbreviation - single-currency shows as-is, forex pairs show Buy/Sell (e.g., EUR\USD).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ContractID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetTradonomiContracts joins Trade.TradonomiContracts with Trade.Instrument and Dictionary.Currency (Buy and Sell) to expose each contract with a human-readable Abbreviation. For forex pairs (BuyCurrencyID and SellCurrencyID both represent currencies), Abbreviation is "BUY\SELL" (e.g., EUR\USD). For single-currency instruments (BuyCurrencyID = InstrumentID in Dictionary.Currency, CurrencyTypeID=1), Abbreviation is just the asset symbol (e.g., NBN, IMNM). The view answers: "What is the display symbol for ContractID X?"

This view exists because liquidity provider routing and back-office UIs need contract identifiers paired with instrument symbols. Trade.TradonomiContracts stores ContractID, InstrumentID, IsActive, FromDate, ToDate, Description - but not the currency pair display. The view enriches this for GetInstrumentContracts, configuration views, and LP contract resolution.

---

## 2. Business Logic

### 2.1 Abbreviation Computation

**What**: Abbreviation is computed: when Buy currency is NOT type 1 (forex), use Buy.Abbreviation only; otherwise use Buy.Abbreviation + '\' + Sell.Abbreviation.

**Columns/Parameters Involved**: `Abbreviation`, `BuyCurrencyID`, `SellCurrencyID`, `CurrencyTypeID`

**Rules**:
- CASE WHEN BUY.CurrencyTypeID <> 1 THEN BUY.Abbreviation
- ELSE BUY.Abbreviation + '\' + SELL.Abbreviation END
- CurrencyTypeID=1 typically indicates forex/currency; non-1 indicates stocks, indices, crypto
- For stocks: BuyCurrencyID points to the asset (CurrencyTypeID often non-1), so Abbreviation = e.g., "NBN"
- For forex: Both are currencies, so Abbreviation = "EUR\USD"

**Diagram**:
```
Trade.TradonomiContracts (ContractID, InstrumentID, IsActive, FromDate, ToDate, Description)
       | JOIN InstrumentID
       v
Trade.Instrument (BuyCurrencyID, SellCurrencyID)
       | JOIN BuyCurrencyID, SellCurrencyID
       v
Dictionary.Currency BUY, SELL
       |
       v
Abbreviation = BUY.CurrencyTypeID<>1 ? BUY.Abbreviation : BUY.Abbreviation + '\' + SELL.Abbreviation
```

### 2.2 DISTINCT Output

**What**: The view uses SELECT DISTINCT - deduplication in case of multiple currency mappings. Typically not needed for 1:1 joins but guards against data anomalies.

---

## 3. Data Overview

| ContractID | InstrumentID | IsActive | FromDate | ToDate | Description | Abbreviation | Meaning |
|------------|--------------|----------|----------|--------|-------------|--------------|---------|
| 5552 | 10215 | 1 | 2010-04-01 | 2010-04-30 | NBN | NBN | Stock/crypto NBN - single symbol. Active contract. |
| 5553 | 10216 | 1 | 2010-04-01 | 2010-04-30 | IMNM | IMNM | Stock IMNM. Same pattern. |
| 5554 | 10217 | 1 | 2010-04-01 | 2010-04-30 | CCNE | CCNE | Stock CCNE. |
| 5555 | 10218 | 1 | 2010-04-01 | 2010-04-30 | MOND | MOND | Stock MOND. |
| 5556 | 10219 | 1 | 2010-04-01 | 2010-04-30 | ESQ | ESQ | Stock ESQ. |

**Live sampling**: All 5 rows show single-symbol Abbreviation (CurrencyTypeID<>1). No forex pairs in top 5. IsActive=1 for all. FromDate/ToDate are contract validity window.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Source Table | Description |
|---|---------|------|----------|---------|------------|--------------|-------------|
| 1 | ContractID | int | NO | - | CODE-BACKED | Trade.TradonomiContracts | Primary key. Unique contract identifier. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Trade.TradonomiContracts | FK to Trade.Instrument. The tradeable instrument. |
| 3 | IsActive | tinyint | NO | - | CODE-BACKED | Trade.TradonomiContracts | 1=active contract for this instrument; 0=historical. |
| 4 | FromDate | datetime | NO | - | CODE-BACKED | Trade.TradonomiContracts | Contract validity start. |
| 5 | ToDate | datetime | NO | - | CODE-BACKED | Trade.TradonomiContracts | Contract validity end. |
| 6 | Description | varchar(150) | YES | - | CODE-BACKED | Trade.TradonomiContracts | Human-readable contract label (e.g., EURUSD, NBN). |
| 7 | Abbreviation | varchar | - | - | CODE-BACKED | Computed | CASE: CurrencyTypeID<>1 then Buy abbrev, else Buy\Sell. Display symbol for UI and LP routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Base Table | Join Condition | Relationship Type | Description |
|------------|----------------|-------------------|-------------|
| Trade.TradonomiContracts | FROM | Source | Contract definitions. |
| Trade.Instrument | TradonomiContracts.InstrumentID = Instrument.InstrumentID | INNER JOIN | Resolve BuyCurrencyID, SellCurrencyID. |
| Dictionary.Currency (BUY) | Instrument.BuyCurrencyID = BUY.CurrencyID | INNER JOIN | Buy-side abbreviation. |
| Dictionary.Currency (SELL) | Instrument.SellCurrencyID = SELL.CurrencyID | INNER JOIN | Sell-side abbreviation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Type | Role | Description |
|--------------|------|------|-------------|
| Trade.TradonomiContracts (table doc) | Reference | - | View consumes table; table doc lists view as consumer. |
| Trade.GetInstrumentContracts | View | READER | Likely consumes or mirrors this view for instrument config. |
| Trade.GetInstrumentConfiguration | View | READER | Configuration view referencing contract data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTradonomiContracts (view)
├── Trade.TradonomiContracts (table)
├── Trade.Instrument (table)
│     ├── Dictionary.Currency (BuyCurrencyID)
│     └── Dictionary.Currency (SellCurrencyID)
└── Dictionary.Currency x2 (BUY, SELL)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | FROM - contract rows. |
| Trade.Instrument | Table | INNER JOIN - BuyCurrencyID, SellCurrencyID. |
| Dictionary.Currency | Table | INNER JOIN x2 - BUY and SELL abbreviations. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentContracts | View | References contract + abbreviation for LP routing. |
| Trade.GetInstrumentConfiguration | View | Configuration display. |
| Trade.TradonomiContracts (table doc) | Doc | Documents view as consumer. |

---

## 7. Technical Details

### 7.1 DDL Summary

- No SCHEMABINDING
- SELECT DISTINCT for output deduplication
- CASE expression for Abbreviation: BUY.CurrencyTypeID <> 1 ? BUY.Abbreviation : BUY.Abbreviation + '\' + SELL.Abbreviation

### 7.2 Column Mapping

| Output Column | Source |
|--------------|--------|
| ContractID | TradonomiContracts.ContractID |
| InstrumentID | TradonomiContracts.InstrumentID |
| IsActive | TradonomiContracts.IsActive |
| FromDate | TradonomiContracts.FromDate |
| ToDate | TradonomiContracts.ToDate |
| Description | TradonomiContracts.Description |
| Abbreviation | CASE WHEN BUY.CurrencyTypeID <> 1 THEN BUY.Abbreviation ELSE BUY.Abbreviation + '\' + SELL.Abbreviation END |

---

## 8. Sample Queries

### 8.1 Active contracts with abbreviation for major instruments

```sql
SELECT ContractID,
       InstrumentID,
       Description,
       Abbreviation,
       FromDate,
       ToDate
  FROM Trade.GetTradonomiContracts WITH (NOLOCK)
 WHERE IsActive = 1
   AND InstrumentID <= 100
 ORDER BY InstrumentID
```

### 8.2 Find contract by description

```sql
SELECT ContractID,
       InstrumentID,
       Abbreviation,
       FromDate,
       ToDate
  FROM Trade.GetTradonomiContracts WITH (NOLOCK)
 WHERE Description = 'NBN'
   AND IsActive = 1
```

### 8.3 Forex pairs (abbreviation contains backslash)

```sql
SELECT ContractID,
       InstrumentID,
       Abbreviation,
       Description
  FROM Trade.GetTradonomiContracts WITH (NOLOCK)
 WHERE Abbreviation LIKE '%\%'
   AND IsActive = 1
 ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.3/10 (Elements: 7/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTradonomiContracts | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetTradonomiContracts.sql*
