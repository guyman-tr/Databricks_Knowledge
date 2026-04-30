# Trade.LiquidityProviderContracts

> Mapping table that links instruments to liquidity provider types with exchange-specific ticker symbols and validity windows for price feeds and hedging.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID, LiquidityProviderID, ExchangeID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (PK, IX_LiquidityProviderID, UQ_ContractID) |

---

## 1. Business Meaning

Trade.LiquidityProviderContracts maps each eToro instrument to one or more liquidity provider types with provider-specific ticker symbols, exchange context, and date validity. A row means "for Instrument X, liquidity provider type Y uses ticker Z on exchange E from date A to date B." This enables the price subsystem (PCS) and hedge subsystem to know which external ticker to subscribe to when fetching quotes or routing hedge orders for a given instrument.

This table exists because different providers use different ticker conventions (e.g., EUR/USD vs EURUSD) and the same instrument may be hedged across multiple providers (FXCM, FD, BMFN) with different tickers per provider. Without it, the system could not resolve "InstrumentID 1" to "EUR/USD at FXCM" vs "EURUSD at FD." The Add Price step in the DBA instrument insertion workflow populates this table when new instruments go live.

Data flows: Rows are created by Trade.InsertLiquidityProviderContract, Trade.InsertInstrumentDealing, Internal.Newcurrency, Stocks.AddNewStock, and Trade.InsertInstrumentMetadataSecurityOpsAPI. Trade.CheckValidInstruments and Internal.Newcurrency copy contract structures from a source instrument when @CopyTradeLiquidityProviderContracts is set. Price.GetTickerInfo, Hedge.GetLiquidityProviderContracts, Hedge.GetHedgeSupportedInstruments, and Price.SwapContracts read it. Trade.TradonomiToLiquidityProviderContracts links Tradonomi contract IDs to LiquidityProviderContract IDs. System versioning records changes to History.LiquidityProviderContracts.

---

## 2. Business Logic

### 2.1 Contract Validity Window (FromDate / ToDate)

**What**: Each contract row is valid only within a date range. Outside that window, the provider's ticker mapping does not apply.

**Columns/Parameters Involved**: `FromDate`, `ToDate`

**Rules**:
- FromDate and ToDate define when this provider-instrument-exchange combination is active
- Trade.GetAvailableLiquidityProviderContracts filters by `TLPC.ToDate >= CD.FromDate` to find available contracts overlapping the Tradonomi contract period
- Price.SwapContracts reads FromDate/ToDate to manage rollover timing for futures/spot mapping
- Typical pattern: FromDate = instrument go-live, ToDate = '9999-12-31' or '2100-01-01' for open-ended

**Diagram**:
```
InstrumentID 1 (EUR/USD)
  |-- LiquidityProviderID 2 (FXCM), Exchange 1: FromDate 2010-04-01, ToDate 2010-04-30 -> historical
  |-- LiquidityProviderID 2 (FXCM), Exchange 1: FromDate 2010-05-01, ToDate 9999-12-31 -> current
  |-- LiquidityProviderID 3 (FD),   Exchange 1: FromDate 2010-04-01, ToDate 9999-12-31 -> current
```

### 2.2 Provider-Instrument-Exchange Uniqueness

**What**: The composite PK (InstrumentID, LiquidityProviderID, ExchangeID) ensures at most one ticker mapping per provider-instrument-exchange combination.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityProviderID`, `ExchangeID`

**Rules**:
- Same instrument can have multiple rows for different LiquidityProviderIDs (e.g., FXCM and FD both hedge EUR/USD)
- Same instrument-provider can have multiple rows for different ExchangeIDs (multi-exchange instruments)
- RateConversionFactor defaults to 1; used when provider quotes in different units (e.g., pip vs point)

---

## 3. Data Overview

| InstrumentID | LiquidityProviderID | Ticker | ExchangeID | FromDate | ToDate | Meaning |
|--------------|---------------------|--------|------------|----------|-------|---------|
| 1 | 2 | EUR/USD | 1 | 2010-04-01 | 2010-04-30 | FXCM (2) uses ticker EUR/USD on exchange 1 for EUR/USD instrument. Date range may indicate a rolled contract or historical snapshot. |
| 2 | 2 | GBP/USD | 1 | 2010-04-01 | 2010-04-30 | FXCM mapping for GBP/USD. Same provider-exchange pattern as forex majors. |
| 1 | 3 | EUR/USD | 1 | 2010-04-01 | 2010-04-30 | FD (3) also maps EUR/USD. Multiple providers can hedge the same instrument with same or different ticker strings. |
| 5 | 2 | USD/JPY | 1 | 2010-04-01 | 2010-04-30 | USD/JPY at FXCM. RateConversionFactor=1 for standard forex. |
| 8 | 2 | EUR/GBP | 1 | 2010-04-01 | 2010-04-30 | Cross-pair EUR/GBP. Demonstrates variety across instrument types. |

**Selection criteria for the 5 rows:**
- Forex majors (EUR/USD, GBP/USD, USD/JPY) with LiquidityProviderID 2 (FXCM)
- Same instrument (1) with different providers (2 and 3) to show multi-provider mapping
- Cross-pair (EUR/GBP) for breadth

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ContractID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate key. Unique per row. Used by Trade.TradonomiToLiquidityProviderContracts as LiquidityProviderContractID. Internal.Newcurrency and Stocks.AddNewStock use IDENTITY_INSERT when copying from source instrument. |
| 2 | LiquidityProviderID | int | NO | - | CODE-BACKED | References Trade.LiquidityProviderType.LiquidityProviderTypeID (FK_LiquidityProviderContracts_LiquidityProviderType). Despite the name, stores provider TYPE not provider instance. Internal.Newcurrency comment: "[LiquidityProviderID] is actually from Trade.LiquidityProviderType." Hedge.GetHedgeSupportedInstruments joins HA.LiquidityProviderTypeID = LPC.LiquidityProviderID. Values: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 5=XIGNITE, 8=BitStamp (Trade.LiquidityProviderType). |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The eToro instrument (Trade.Instrument). FK to Trade.Instrument. Each row maps one instrument to one provider type. |
| 4 | FromDate | datetime | NO | - | CODE-BACKED | Start of validity window. Contract is active when query date is >= FromDate. Used in Trade.GetAvailableLiquidityProviderContracts and Price.SwapContracts for overlap checks. |
| 5 | ToDate | datetime | NO | - | CODE-BACKED | End of validity window. Contract is active when query date is <= ToDate. Price.SwapContracts reads ToDate for rollover logic. |
| 6 | Ticker | varchar(150) | YES | - | CODE-BACKED | Provider-specific ticker symbol (e.g., EUR/USD, EURUSD). Price.GetTickerInfo and Hedge.GetLiquidityProviderContracts return it for price/hedge resolution. Internal.Newcurrency can UPDATE Ticker from XML input. |
| 7 | ExchangeID | int | NO | 1 | CODE-BACKED | FK to Price.Exchange. Default 1. Identifies which exchange context this ticker applies to. Used when same instrument trades on multiple exchanges (e.g., stocks). |
| 8 | RateConversionFactor | decimal(20,10) | YES | 1 | CODE-BACKED | Multiplier to convert provider quote units to eToro units. Default 1. Used when provider uses different scale (e.g., pip vs point). |
| 9 | DbLoginName | varchar(128) | - | AS (suser_name()) | CODE-BACKED | Computed: current SQL login. Audit/debug only; not in PK or business logic. |
| 10 | AppLoginName | varchar(500) | - | AS (CONVERT(varchar(500),context_info())) | CODE-BACKED | Computed: application context. Audit/debug only. |
| 11 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning valid-from. GENERATED ALWAYS AS ROW START. History.LiquidityProviderContracts stores prior versions. |
| 12 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System-versioning valid-to. GENERATED ALWAYS AS ROW END. Current rows have max value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviderType | FK | Provider type (e.g., FXCM, FD). Column name suggests instance but FK is to type. |
| InstrumentID | Trade.Instrument | FK | eToro instrument being mapped. |
| ExchangeID | Price.Exchange | FK | Exchange context for multi-exchange instruments. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetLiquidityProviderContracts | view | JOIN | View enriches with LiquidityProviders, Instrument, Currency for display. |
| Trade.GetInstrumentContracts | view | JOIN | Exposes contract data for instruments. |
| Trade.GetProvidersTradonomiContracts | view | JOIN | Links to Tradonomi contracts. |
| Trade.GetAvailableLiquidityProviderContracts | function | JOIN | Returns available contracts for Tradonomi contract. |
| Trade.GetLiguidityProviderContractsForTradonomiContract | function | JOIN | Resolves LP contracts for Tradonomi. |
| Hedge.GetLiquidityProviderContracts | procedure | FROM | Returns contracts by LiquidityProviderID. |
| Hedge.GetHedgeSupportedInstruments | procedure | JOIN | Filters instruments supported for hedging by provider type. |
| Trade.InsertLiquidityProviderContract | procedure | INSERT | Single-row insert. |
| Trade.InsertInstrumentDealing | procedure | INSERT | Bulk insert from TVP. |
| Internal.Newcurrency | procedure | INSERT/UPDATE | Instrument creation; copies from source or XML. |
| Stocks.AddNewStock | procedure | INSERT | New stock instrument setup. |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | procedure | INSERT | Security ops API instrument creation. |
| Trade.CheckValidInstruments | procedure | READ | Validates instrument config; uses temp copy. |
| Trade.SetTradonomiToLPContracts | procedure | JOIN | Populates TradonomiToLiquidityProviderContracts. |
| Price.GetTickerInfo | procedure | JOIN | Resolves ticker for price lookups. |
| Price.SwapContracts | procedure | JOIN/UPDATE | Futures rollover; reads FromDate/ToDate. |
| Trade.TradonomiToLiquidityProviderContracts | table | FK | Links TradonomiContractID to LiquidityProviderContractID (ContractID). |
| dbo.Delete_Instrument | procedure | DELETE | Cascades delete when instrument removed. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a leaf table. CREATE TABLE has no FROM/JOIN/CROSS APPLY. FKs and trigger references belong in Section 5 (Relationships).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderType | Table | FK LiquidityProviderID -> LiquidityProviderTypeID |
| Trade.Instrument | Table | FK InstrumentID -> InstrumentID |
| Price.Exchange | Table | FK ExchangeID -> ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiquidityProviderContracts | View | FROM/JOIN |
| Trade.GetInstrumentContracts | View | JOIN |
| Trade.GetProvidersTradonomiContracts | View | JOIN |
| Trade.GetAvailableLiquidityProviderContracts | Function | FROM/JOIN |
| Trade.GetLiguidityProviderContractsForTradonomiContract | Function | FROM/JOIN |
| Hedge.GetLiquidityProviderContracts | Procedure | FROM |
| Hedge.GetHedgeSupportedInstruments | Procedure | JOIN |
| Trade.InsertLiquidityProviderContract | Procedure | INSERT |
| Trade.InsertInstrumentDealing | Procedure | INSERT |
| Internal.Newcurrency | Procedure | INSERT/UPDATE |
| Stocks.AddNewStock | Procedure | INSERT |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Procedure | INSERT |
| Trade.CheckValidInstruments | Procedure | READ |
| Price.GetTickerInfo | Procedure | JOIN |
| Price.SwapContracts | Procedure | JOIN/UPDATE |
| Trade.TradonomiToLiquidityProviderContracts | Table | FK LiquidityProviderContractID -> ContractID |
| History.LiquidityProviderContracts | Table | System versioning history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LiquidityProviderContracts | CLUSTERED | InstrumentID, LiquidityProviderID, ExchangeID | - | - | Active |
| IX_LiquidityProviderID | NC | LiquidityProviderID | Ticker | - | Active |
| UQ_TradeLiquidityProviderContracts_ContractID | NC UNIQUE | ContractID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_LiquidityProviderContracts | PRIMARY KEY | Unique (InstrumentID, LiquidityProviderID, ExchangeID) |
| FK_LiquidityProviderContracts_ExchangeID | FOREIGN KEY | ExchangeID -> Price.Exchange.ExchangeID |
| FK_LiquidityProviderContracts_LiquidityProviderType | FOREIGN KEY | LiquidityProviderID -> Trade.LiquidityProviderType.LiquidityProviderTypeID |
| FK_LiquidityProviderContracts__Instruments | FOREIGN KEY | InstrumentID -> Trade.Instrument.InstrumentID |
| DF_ExchangeID | DEFAULT | ExchangeID = 1 |
| DF_LiquidityProviderContracts_RateConversionFactor | DEFAULT | RateConversionFactor = 1 |
| DF_LiquidityProviderContracts_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_LiquidityProviderContracts_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |

---

## 8. Sample Queries

### 8.1 Contracts for a specific instrument with provider names
```sql
SELECT   LPC.ContractID,
         LPC.InstrumentID,
         LPC.LiquidityProviderID,
         LPT.Name AS ProviderTypeName,
         LPC.Ticker,
         LPC.FromDate,
         LPC.ToDate,
         LPC.ExchangeID,
         LPC.RateConversionFactor
FROM     Trade.LiquidityProviderContracts LPC WITH (NOLOCK)
INNER JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK)
         ON LPT.LiquidityProviderTypeID = LPC.LiquidityProviderID
WHERE    LPC.InstrumentID = 1
ORDER BY LPC.LiquidityProviderID, LPC.ExchangeID;
```

### 8.2 Active contracts (valid today) for FXCM
```sql
SELECT   LPC.ContractID,
         LPC.InstrumentID,
         LPC.Ticker,
         LPC.FromDate,
         LPC.ToDate
FROM     Trade.LiquidityProviderContracts LPC WITH (NOLOCK)
WHERE    LPC.LiquidityProviderID = 2
         AND LPC.FromDate <= CAST(GETUTCDATE() AS DATE)
         AND LPC.ToDate >= CAST(GETUTCDATE() AS DATE)
ORDER BY LPC.InstrumentID;
```

### 8.3 Instruments with multiple provider contracts
```sql
SELECT   LPC.InstrumentID,
         I.BuyCurrencyID,
         I.SellCurrencyID,
         COUNT(DISTINCT LPC.LiquidityProviderID) AS ProviderCount,
         STRING_AGG(LPT.Name, ', ') WITHIN GROUP (ORDER BY LPT.Name) AS Providers
FROM     Trade.LiquidityProviderContracts LPC WITH (NOLOCK)
INNER JOIN Trade.Instrument I WITH (NOLOCK) ON I.InstrumentID = LPC.InstrumentID
INNER JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK)
         ON LPT.LiquidityProviderTypeID = LPC.LiquidityProviderID
WHERE    LPC.ToDate >= GETUTCDATE()
GROUP BY LPC.InstrumentID, I.BuyCurrencyID, I.SellCurrencyID
HAVING   COUNT(DISTINCT LPC.LiquidityProviderID) > 1
ORDER BY ProviderCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [DBA : How To Article : Insert new Instruments](https://etoro.atlassian.net/wiki/spaces/DROD/pages/11765612545) | Confluence | LiquidityProviderContracts is populated in "Add Price" step after instrument insert. Sanity test: `SELECT * FROM Trade.LiquidityProviderContracts WHERE DATEDIFF(dd, SysStartTime, getdate()) = 0` confirms new rows. |
| [Instrument Insertion - new model](https://etoro.atlassian.net/wiki/spaces/DROD/pages/13308395583) | Confluence | May describe updated instrument/contract insertion workflow. |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.LiquidityProviderContracts | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.LiquidityProviderContracts.sql*
