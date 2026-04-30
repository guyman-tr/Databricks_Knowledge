# Trade.GetInstrumentContracts

> View that exposes contract-to-liquidity-provider mapping per instrument by joining TradonomiContracts with LiquidityProviderContracts on InstrumentID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + LiquidityProviderID + ExchangeID (from LPC) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentContracts answers the question: "For each instrument, which liquidity provider contracts are available and what are their ticker symbols and validity windows?" It JOINs Trade.TradonomiContracts (eToro's internal contract periods) with Trade.LiquidityProviderContracts (provider-specific ticker mappings) on InstrumentID. Each row represents one instrument-to-LP contract combination: the instrument, the human-readable contract description, the liquidity provider type, the provider's ticker string, and the validity date range.

This view exists because price feeds and hedge routing need to resolve an eToro instrument to the correct external ticker per provider. Without it, consumers would need to JOIN both base tables manually. Trade.GetAvailableLiquidityProviderContracts and related functions use similar logic; this view provides a flattened, easy-to-query surface for "all LP contracts for all instruments."

Data flows: The view is read-only. It reflects the current state of TradonomiContracts and LiquidityProviderContracts. No direct writers; base tables are maintained by Trade.InsertTradonomyContract, Trade.InsertLiquidityProviderContract, Trade.SetTradonomiToLPContracts, and others.

---

## 2. Business Logic

### 2.1 Contract-to-LP Mapping by Instrument

**What**: One row per (InstrumentID, LiquidityProviderID, ExchangeID) from LiquidityProviderContracts, enriched with the Tradonomi contract Description for that instrument.

**Columns/Parameters Involved**: `InstrumentID`, `Description`, `LiquidityProviderID`, `Ticker`, `FromDate`, `ToDate`, `ExchangeID`, `RateConversionFactor`

**Rules**:
- JOIN on InstrumentID only. Each Tradonomi contract (one per instrument for active contracts) is paired with every LP contract for that instrument. Result set = all LP contracts for each instrument.
- Description comes from TradonomiContracts (e.g., EURUSD, GBP/USD). Ticker comes from LiquidityProviderContracts (provider-specific, e.g., EUR/USD at FXCM).
- FromDate/ToDate and RateConversionFactor are from LiquidityProviderContracts. ExchangeID identifies the exchange context for the ticker.

**Diagram**:
```
InstrumentID=1 (EUR/USD)
  |-- LP 0: Ticker=EURUSD, Exchange 1
  |-- LP 1: Ticker=EUR/USD, Exchange 1
  |-- LP 2: Ticker=EUR/USD, Exchange 1
  |-- LP 2: Ticker=elad, Exchange 5
  |-- LP 3: Ticker=EUR/USD, Exchange 1
```

---

## 3. Data Overview

| InstrumentID | Description | LiquidityProviderID | Ticker | FromDate | ToDate | ExchangeID | Meaning |
|--------------|-------------|---------------------|--------|----------|--------|------------|---------|
| 1 | EURUSD | 0 | EURUSD | 2024-06-06 | 2024-06-06 | 1 | eToro (LP 0) internal ticker for EUR/USD on exchange 1 |
| 1 | EURUSD | 1 | EUR/USD | 2024-05-30 | 2024-05-30 | 1 | BMFN (LP 1) mapping for EUR/USD |
| 1 | EURUSD | 2 | EUR/USD | 2010-04-01 | 2010-04-30 | 1 | FXCM (LP 2) historical contract |
| 1 | EURUSD | 2 | elad | 2025-08-07 | 2100-01-01 | 5 | FXCM (LP 2) alternate exchange (5) ticker, open-ended |
| 1 | EURUSD | 3 | EUR/USD | 2010-04-01 | 2010-04-30 | 1 | FD (LP 3) mapping for EUR/USD |

**Selection criteria for the 5 rows:** First 5 rows for InstrumentID=1 showing multiple providers (0, 1, 2, 3) and multiple exchanges (1, 5). Demonstrates variety of ticker and validity patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From Trade.TradonomiContracts. The eToro instrument this contract belongs to. FK to Trade.Instrument. |
| 2 | Description | varchar(150) | YES | - | CODE-BACKED | From Trade.TradonomiContracts. Human-readable contract identifier (e.g., EURUSD, GBP/USD). |
| 3 | LiquidityProviderID | int | NO | - | CODE-BACKED | From Trade.LiquidityProviderContracts. Provider type: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 5=XIGNITE, 8=BitStamp. FK to Trade.LiquidityProviderType. |
| 4 | Ticker | varchar(150) | YES | - | CODE-BACKED | From Trade.LiquidityProviderContracts. Provider-specific ticker (e.g., EUR/USD, EURUSD). |
| 5 | FromDate | datetime | NO | - | CODE-BACKED | From Trade.LiquidityProviderContracts. Start of contract validity window. |
| 6 | ToDate | datetime | NO | - | CODE-BACKED | From Trade.LiquidityProviderContracts. End of contract validity window. |
| 7 | ExchangeID | int | NO | 1 | CODE-BACKED | From Trade.LiquidityProviderContracts. FK to Price.Exchange. Exchange context for the ticker. Default 1. |
| 8 | RateConversionFactor | decimal(20,10) | YES | 1 | CODE-BACKED | From Trade.LiquidityProviderContracts. Multiplier to convert provider quote units to eToro units. Default 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The tradeable instrument |
| Description | Trade.TradonomiContracts | Implicit | Contract description |
| LiquidityProviderID | Trade.LiquidityProviderType | FK | Provider type |
| ExchangeID | Price.Exchange | FK | Exchange context |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentConfiguration | - | JOIN | Configuration view uses similar contract/LP structure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentContracts (view)
├── Trade.TradonomiContracts (table)
│     └── Trade.Instrument (table)
└── Trade.LiquidityProviderContracts (table)
      ├── Trade.LiquidityProviderType (table)
      ├── Trade.Instrument (table)
      └── Price.Exchange (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | FROM/JOIN - InstrumentID, Description |
| Trade.LiquidityProviderContracts | Table | JOIN on InstrumentID - LP contract data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentConfiguration | View | Related contract/LP structure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all LP contracts for EUR/USD (InstrumentID 1)

```sql
SELECT InstrumentID, Description, LiquidityProviderID, Ticker, FromDate, ToDate, ExchangeID
FROM Trade.GetInstrumentContracts WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY LiquidityProviderID, ExchangeID;
```

### 8.2 Active contracts (valid today) for major forex instruments

```sql
SELECT gc.InstrumentID, gc.Description, gc.LiquidityProviderID, gc.Ticker,
       gc.FromDate, gc.ToDate, gc.RateConversionFactor
FROM Trade.GetInstrumentContracts gc WITH (NOLOCK)
WHERE gc.FromDate <= CAST(GETUTCDATE() AS DATE)
  AND gc.ToDate >= CAST(GETUTCDATE() AS DATE)
  AND gc.InstrumentID IN (1, 2, 3, 4, 5)
ORDER BY gc.InstrumentID, gc.LiquidityProviderID;
```

### 8.3 Resolve provider names via LiquidityProviderType

```sql
SELECT gc.InstrumentID, gc.Description, lpt.Name AS ProviderName,
       gc.Ticker, gc.ExchangeID, gc.RateConversionFactor
FROM Trade.GetInstrumentContracts gc WITH (NOLOCK)
INNER JOIN Trade.LiquidityProviderType lpt WITH (NOLOCK)
  ON lpt.LiquidityProviderTypeID = gc.LiquidityProviderID
WHERE gc.InstrumentID <= 10
ORDER BY gc.InstrumentID, gc.LiquidityProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentContracts | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentContracts.sql*
