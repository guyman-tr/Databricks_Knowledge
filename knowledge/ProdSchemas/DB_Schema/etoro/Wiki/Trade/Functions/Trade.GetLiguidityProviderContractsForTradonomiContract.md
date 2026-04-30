# Trade.GetLiguidityProviderContractsForTradonomiContract

> Returns LP contracts already assigned to a Tradonomi contract via Trade.TradonomiToLiquidityProviderContracts, with provider names, tickers, validity dates, and instrument context. (Note: Function name spelling "Liguidity" is as in DDL.)

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline TVF |
| **Key Identifier** | Returns TABLE: Abbreviation, LiquidityProviderName, FromDate, ToDate, Ticker, ContractID, InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLiguidityProviderContractsForTradonomiContract returns the liquidity provider contracts that are already mapped to a given Tradonomi contract. It joins Trade.LiquidityProviderContracts, Trade.TradonomiToLiquidityProviderContracts, Trade.LiquidityProviders, Trade.TradonomiContracts, Trade.Instrument, and Dictionary.Currency to produce human-readable contract data: provider name, ticker, validity window (FromDate, ToDate), and currency abbreviation. Each row represents one LP contract assigned to the Tradonomi contract.

This function exists because instrument setup and hedge/price subsystems need to know which LP contracts serve a given Tradonomi contract. TradonomiToLiquidityProviderContracts holds the mapping; this function enriches it with display data. Used by Trade.GetLiguidityProviderContractData when FreeToUse=1.

Data flows: Called by Trade.GetLiguidityProviderContractData. Reads from Trade.LiquidityProviderContracts, Trade.TradonomiToLiquidityProviderContracts, Trade.LiquidityProviders, Trade.TradonomiContracts, Trade.Instrument, Dictionary.Currency.

---

## 2. Business Logic

### 2.1 Tradonomi-to-LP Mapping with Enrichment

**What**: Returns only LP contracts that are explicitly linked to the Tradonomi contract.

**Columns/Parameters Involved**: `@TradonomiContractID`, `TradonomiToLiquidityProviderContracts`, `LiquidityProviderContracts`

**Rules**:
- INNER JOIN TradonomiToLiquidityProviderContracts ensures only mapped LP contracts are returned
- TLPC.InstrumentID must match CD.InstrumentID (from TradonomiContracts for the given ContractID)
- CROSS JOIN ContractDet (InstrumentID, ToDate) provides instrument context; commented filter `TLPC.FromDate <= CD.ToDate` was historically considered
- Returns Abbreviation (currency), LiquidityProviderName, FromDate, ToDate, Ticker, ContractID, InstrumentID

**Diagram**:
```
Trade.TradonomiContracts (ContractID, InstrumentID, ToDate)
  |
  v  CROSS JOIN ContractDet
Trade.TradonomiToLiquidityProviderContracts (TradonomiContractID, LiquidityProviderContractID)
  |
  v  INNER JOIN
Trade.LiquidityProviderContracts (ContractID, InstrumentID, FromDate, ToDate, Ticker, LiquidityProviderID)
  |
  v  INNER JOIN Trade.LiquidityProviders, Trade.Instrument, Dictionary.Currency
  -> Abbreviation, LiquidityProviderName, FromDate, ToDate, Ticker, ContractID, InstrumentID
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TradonomiContractID | int | NO | - | CODE-BACKED | Trade.TradonomiContracts.ContractID. Identifies the Tradonomi contract. |
| 2 | Abbreviation | varchar | YES | - | CODE-BACKED | Currency abbreviation from Dictionary.Currency via Trade.Instrument.BuyCurrencyID. |
| 3 | LiquidityProviderName | varchar | YES | - | CODE-BACKED | Provider instance name from Trade.LiquidityProviders.LiquidityProviderName. |
| 4 | FromDate | datetime | NO | - | CODE-BACKED | LP contract validity start from Trade.LiquidityProviderContracts.FromDate. |
| 5 | ToDate | datetime | NO | - | CODE-BACKED | LP contract validity end from Trade.LiquidityProviderContracts.ToDate. |
| 6 | Ticker | varchar(150) | YES | - | CODE-BACKED | Provider-specific ticker (e.g., EUR/USD, EURUSD) from Trade.LiquidityProviderContracts. |
| 7 | ContractID | int | NO | - | CODE-BACKED | Trade.LiquidityProviderContracts.ContractID (LP contract surrogate key). |
| 8 | InstrumentID | int | NO | - | CODE-BACKED | From ContractDet (Trade.TradonomiContracts). The instrument this Tradonomi contract belongs to. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TradonomiContractID | Trade.TradonomiContracts | SELECT | ContractDet CTE |
| TradonomiToLiquidityProviderContracts | Trade.TradonomiToLiquidityProviderContracts | INNER JOIN | Mapping table |
| LiquidityProviderContractID | Trade.LiquidityProviderContracts | INNER JOIN | LP contract details |
| LiquidityProviderID | Trade.LiquidityProviders | INNER JOIN | Provider name |
| InstrumentID | Trade.Instrument | INNER JOIN | BuyCurrencyID for currency lookup |
| BuyCurrencyID | Dictionary.Currency | INNER JOIN | Abbreviation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetLiguidityProviderContractData | Call | Reader | When FreeToUse=1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLiguidityProviderContractsForTradonomiContract (function)
├── Trade.TradonomiContracts (table)
├── Trade.LiquidityProviderContracts (table)
├── Trade.TradonomiToLiquidityProviderContracts (table)
├── Trade.LiquidityProviders (table)
├── Trade.Instrument (table)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | FROM — ContractDet CTE; InstrumentID, ToDate |
| Trade.LiquidityProviderContracts | Table | INNER JOIN — FromDate, ToDate, Ticker, ContractID, InstrumentID, LiquidityProviderID |
| Trade.TradonomiToLiquidityProviderContracts | Table | INNER JOIN — maps TradonomiContractID to LiquidityProviderContractID |
| Trade.LiquidityProviders | Table | INNER JOIN — LiquidityProviderName |
| Trade.Instrument | Table | INNER JOIN — BuyCurrencyID |
| Dictionary.Currency | Table | INNER JOIN — Abbreviation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiguidityProviderContractData | Function | Called when @FreeToUse=1 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 LP contracts for Tradonomi contract 1
```sql
SELECT * FROM Trade.GetLiguidityProviderContractsForTradonomiContract(1);
```

### 8.2 Join to Tradonomi contract description
```sql
SELECT TC.ContractID, TC.Description, TC.InstrumentID,
       GLP.Abbreviation, GLP.LiquidityProviderName, GLP.Ticker, GLP.FromDate, GLP.ToDate
FROM Trade.TradonomiContracts TC WITH (NOLOCK)
CROSS APPLY Trade.GetLiguidityProviderContractsForTradonomiContract(TC.ContractID) GLP
WHERE TC.IsActive = 1;
```

### 8.3 Count LP contracts per Tradonomi contract
```sql
SELECT TC.ContractID, TC.InstrumentID, COUNT(GLP.ContractID) AS LPContractCount
FROM Trade.TradonomiContracts TC WITH (NOLOCK)
OUTER APPLY Trade.GetLiguidityProviderContractsForTradonomiContract(TC.ContractID) GLP
WHERE TC.IsActive = 1
GROUP BY TC.ContractID, TC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetLiguidityProviderContractsForTradonomiContract | Type: Inline TVF | Source: etoro/etoro/Trade/Functions/Trade.GetLiguidityProviderContractsForTradonomiContract.sql*
