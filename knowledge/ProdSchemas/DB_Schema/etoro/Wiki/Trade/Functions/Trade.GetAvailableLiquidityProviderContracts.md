# Trade.GetAvailableLiquidityProviderContracts

> Returns liquidity provider contracts available for a given Tradonomi contract, excluding those already linked to that Tradonomi contract.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns table with Abbreviation, LiquidityProviderName, FromDate, ToDate, Ticker, ContractID, InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetAvailableLiquidityProviderContracts returns LP (liquidity provider) contracts that match a given Tradonomi contract by instrument and validity overlap, minus any LP contracts already mapped to that Tradonomi contract via Trade.TradonomiToLiquidityProviderContracts. It answers: "Which LP contracts can still be linked to this Tradonomi contract?"

This function exists because when adding or updating instrument hedge/price mappings, operations need to see which LP contracts are available to link — i.e., same instrument, overlapping validity, and not already assigned. Without it, duplicate or invalid links could be created.

Data flows: Trade.GetLiguidityProviderContractData calls this function with a TradonomiContractID to obtain contract choices. The EXCEPT clause removes already-linked contracts, so the result set is strictly available (unlinked) options.

---

## 2. Business Logic

### 2.1 Available vs Linked LP Contracts

**What**: Available = LP contracts for the same instrument and validity window, minus those already in TradonomiToLiquidityProviderContracts for this Tradonomi contract.

**Columns/Parameters Involved**: `@TradonomiContractID`, `TLPC.ContractID`, `TTLPC.LiquidityProviderContractID`

**Rules**:
- First SELECT: LP contracts where InstrumentID matches and LP.ToDate >= Tradonomi.FromDate (date overlap)
- EXCEPT: removes LP contracts that have a row in TradonomiToLiquidityProviderContracts for this TradonomiContractID
- Result: only LP contracts that can be newly linked

**Diagram**:
```
@TradonomiContractID=1 (EUR/USD, FromDate=2020-01-01, ToDate=9999-12-31)
  LP contracts: FXCM EUR/USD (ToDate>=2020-01-01) ✓
  LP contracts: FD EUR/USD (ToDate>=2020-01-01) ✓
  EXCEPT: FXCM already in TTLPC for Contract 1 → removed
  Result: FD EUR/USD only (available)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TradonomiContractID | int | NO | - | CODE-BACKED | IN: Tradonomi contract ID from Trade.TradonomiContracts. Determines instrument and validity window for matching LP contracts. |
| 2 | Abbreviation | varchar | YES | - | CODE-BACKED | Return: Instrument abbreviation from Trade.Instrument (via Currency or similar). Human-readable symbol. |
| 3 | LiquidityProviderName | varchar | YES | - | CODE-BACKED | Return: Provider name from Trade.LiquidityProviders. |
| 4 | FromDate | datetime | NO | - | CODE-BACKED | Return: LP contract validity start from Trade.LiquidityProviderContracts. |
| 5 | ToDate | datetime | NO | - | CODE-BACKED | Return: LP contract validity end. Used for overlap check (ToDate >= Tradonomi.FromDate). |
| 6 | Ticker | varchar(150) | YES | - | CODE-BACKED | Return: Provider-specific ticker from Trade.LiquidityProviderContracts. |
| 7 | ContractID | int | NO | - | CODE-BACKED | Return: Trade.LiquidityProviderContracts.ContractID (LP contract PK). |
| 8 | InstrumentID | int | NO | - | CODE-BACKED | Return: eToro instrument ID. Inherited from base tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TradonomiContractID | Trade.TradonomiContracts | Lookup | Tradonomi contract driving instrument and dates |
| InstrumentID | Trade.Instrument | Implicit | Instrument metadata |
| LiquidityProviderID | Trade.LiquidityProviders | FK | Provider names |
| ContractID | Trade.LiquidityProviderContracts | PK | LP contract identity |
| BuyCurrencyID | Dictionary.Currency | FK | Currency for instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetLiguidityProviderContractData | FROM | Call | Calls this function to get available LP contracts for a Tradonomi contract |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAvailableLiquidityProviderContracts (function)
├── Trade.TradonomiContracts (table)
├── Trade.LiquidityProviderContracts (table)
├── Trade.LiquidityProviders (table)
├── Trade.Instrument (table)
├── Dictionary.Currency (table)
└── Trade.TradonomiToLiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | FROM — ContractID lookup for instrument and FromDate/ToDate |
| Trade.LiquidityProviderContracts | Table | FROM/JOIN — LP contracts, validity, ticker |
| Trade.LiquidityProviders | Table | JOIN — LiquidityProviderName |
| Trade.Instrument | Table | JOIN — InstrumentID, Abbreviation |
| Dictionary.Currency | Table | JOIN — BuyCurrencyID resolution |
| Trade.TradonomiToLiquidityProviderContracts | Table | JOIN in EXCEPT — already-linked contracts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiguidityProviderContractData | Function | FROM — calls with @TradonomiContractID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get available LP contracts for a Tradonomi contract
```sql
SELECT *
FROM Trade.GetAvailableLiquidityProviderContracts(1) WITH (NOLOCK);
```

### 8.2 Available LP contracts with provider and instrument details
```sql
SELECT   g.*,
         i.InstrumentID,
         i.BuyCurrencyID,
         i.SellCurrencyID
FROM     Trade.GetAvailableLiquidityProviderContracts(10) g WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = g.InstrumentID;
```

### 8.3 Compare available vs already-linked for a contract
```sql
SELECT 'Available' AS Source, * FROM Trade.GetAvailableLiquidityProviderContracts(5) WITH (NOLOCK)
UNION ALL
SELECT 'Linked', TLPC.Abbreviation, TLPR.Name, TLPC.FromDate, TLPC.ToDate, TLPC.Ticker, TLPC.ContractID, TLPC.InstrumentID
FROM Trade.TradonomiToLiquidityProviderContracts TTLPC WITH (NOLOCK)
JOIN Trade.LiquidityProviderContracts TLPC WITH (NOLOCK) ON TLPC.ContractID = TTLPC.LiquidityProviderContractID
JOIN Trade.LiquidityProviders TLPR WITH (NOLOCK) ON TLPR.LiquidityProviderID = TLPC.LiquidityProviderID
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = TLPC.InstrumentID
WHERE TTLPC.TradonomiContractID = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAvailableLiquidityProviderContracts | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetAvailableLiquidityProviderContracts.sql*
