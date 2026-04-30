# Trade.UpdateInstrumentsMetaDataConfigurationsExtend

> Extended variant of UpdateInstrumentsMetaDataConfigurations that uses the InstrumentsMetaDataConfigTblExtend TVP to additionally update ExchangeID, UnderlyingExchangeID, and PriceSourceID on Trade.InstrumentMetaData, and delegates to Trade.UpdateInstrumentsSymbolFullExtend for downstream propagation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentMetaDataConfigTbl.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the extended version of Trade.UpdateInstrumentsMetaDataConfigurations. It performs the same core metadata update (display name, tradability, visibility, industry, ISIN, contract expiration, symbol, SymbolFull) but adds three additional fields that identify exchange and pricing data sources for the instrument:

- **ExchangeID**: The primary exchange on which the instrument trades (e.g., NASDAQ, NYSE, London Stock Exchange)
- **UnderlyingExchangeID**: The exchange of the underlying asset (relevant for derivatives and ETFs where the instrument trades on one exchange but tracks an asset on another)
- **PriceSourceID**: Identifies the data feed or pricing service that provides market prices for this instrument

The extend version also delegates to Trade.UpdateInstrumentsSymbolFullExtend (instead of UpdateInstrumentsSymbolFull), which handles the extended TVP including ExchangeID, UnderlyingExchangeID, and PriceSourceID for downstream propagation to Price.DictionaryCurrency and related tables.

The SubCategory clear-on-demand behavior from the base version is NOT present here (no ClearSubCategory field in the extended TVP type).

---

## 2. Business Logic

### 2.1 Extended Null-Safe Partial Update (10 base + 3 extended fields)

**What**: Same null-safe IIF pattern as the base version, plus three additional columns.

**Columns/Parameters Involved**: ExchangeID, UnderlyingExchangeID, PriceSourceID in addition to the 10 base fields

**Rules**:
- ExchangeID: `IIF(IMDCT.ExchangeID IS NULL, TIMD.ExchangeID, IMDCT.ExchangeID)`
- UnderlyingExchangeID: `IIF(IMDCT.UnderlyingExchangeID IS NULL, TIMD.UnderlyingExchangeID, IMDCT.UnderlyingExchangeID)`
- PriceSourceID: `IIF(IMDCT.PriceSourceID IS NULL, TIMD.PriceSourceID, IMDCT.PriceSourceID)`
- All base fields use same null-safe IIF pattern as UpdateInstrumentsMetaDataConfigurations
- IndustryID=0 treated as NULL (same rule)
- Note: SubCategory and ClearSubCategory are NOT in this version's TVP type

### 2.2 Delegation to UpdateInstrumentsSymbolFullExtend

**What**: After the InstrumentMetaData update, delegates to the extended symbol propagation procedure.

**Rules**:
- `EXEC Trade.UpdateInstrumentsSymbolFullExtend @InstrumentMetaDataConfigTbl = @InstrumentMetaDataConfigTbl`
- Same extended TVP passed through; UpdateInstrumentsSymbolFullExtend handles Price.DictionaryCurrency updates in addition to the ProviderToInstrument and TradonomiContracts updates done by the base version (see Trade.UpdateInstrumentsSymbolFullExtend.md for details)

### 2.3 SyncConfiguration Events

**What**: Same as base version - rows from @InstrumentSyncConfigurationAddTable inserted verbatim into Trade.SyncConfiguration.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentMetaDataConfigTbl | Trade.InstrumentsMetaDataConfigTblExtend (TVP, READONLY) | NO | - | CODE-BACKED | Extended metadata update batch. All base InstrumentsMetaDataConfigTbl fields plus: ExchangeID (int NULL - primary exchange for the instrument), UnderlyingExchangeID (int NULL - underlying asset's exchange for derivatives/ETFs), PriceSourceID (int NULL - pricing data feed identifier). No ClearSubCategory field (SubCategory is not updateable via this TVP). |
| 2 | @InstrumentSyncConfigurationAddTable | Trade.SyncConfigurationAdd (TVP, READONLY) | NO | - | CODE-BACKED | Sync events inserted verbatim into Trade.SyncConfiguration (InstrumentID, ConfigurationUpdateTypeID, Value). Can be empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | UPDATE | 13 metadata fields (10 base + ExchangeID + UnderlyingExchangeID + PriceSourceID) with null-safe IIF |
| IndustryID | Trade.GetDictionaryStocksIndustry | Lookup JOIN | Resolves IndustryID to IndustryName for Industry text column |
| Sync events | Trade.SyncConfiguration | INSERT | Configuration change events for downstream sync |
| @InstrumentMetaDataConfigTbl | Trade.UpdateInstrumentsSymbolFullExtend | EXEC call | Extended symbol + exchange + pricing propagation to downstream tables |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External configuration tooling | Application call | Caller | No internal SP callers found; called from instrument management tooling when exchange or pricing source fields need updating alongside standard metadata |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMetaDataConfigurationsExtend (procedure)
|- Trade.InstrumentMetaData (table) [UPDATE - 13 fields including ExchangeID, UnderlyingExchangeID, PriceSourceID]
|- Trade.GetDictionaryStocksIndustry (function/view) [Lookup JOIN - IndustryID to IndustryName]
|- Trade.SyncConfiguration (table) [INSERT - sync events]
+-- Trade.UpdateInstrumentsSymbolFullExtend (procedure) [EXEC - extended symbol + exchange propagation]
      +-- [see Trade.UpdateInstrumentsSymbolFullExtend.md for full chain]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | UPDATEd: 13 metadata columns (10 base + ExchangeID + UnderlyingExchangeID + PriceSourceID) with null-safe IIF |
| Trade.GetDictionaryStocksIndustry | View/Function | LEFT JOIN: resolves IndustryID to IndustryName for Industry column |
| Trade.SyncConfiguration | Table | INSERTed: sync events from @InstrumentSyncConfigurationAddTable |
| Trade.UpdateInstrumentsSymbolFullExtend | Procedure | EXECuted: propagates symbol and exchange/pricing fields to downstream tables |
| Trade.InstrumentsMetaDataConfigTblExtend | User Defined Type | Extended TVP type for @InstrumentMetaDataConfigTbl; adds ExchangeID, UnderlyingExchangeID, PriceSourceID |
| Trade.SyncConfigurationAdd | User Defined Type | TVP type for @InstrumentSyncConfigurationAddTable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument management tooling | Application | Calls when exchange or pricing source fields need updating alongside standard metadata |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Null-safe partial update | Logic | IIF pattern for all 13 fields; NULL input = preserve current value |
| IndustryID=0 treated as NULL | Business rule | `IIF(IndustryID IS NULL OR IndustryID = 0, ...)` |
| No ClearSubCategory | Design | SubCategory is not in the Extend TVP; cannot be cleared or updated via this procedure |
| Atomic transaction | TRY/CATCH | All three operations share one transaction; THROW re-raises on error |

---

## 8. Sample Queries

### 8.1 Update exchange and price source for an instrument

```sql
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTblExtend]
INSERT INTO @Config (InstrumentID, ExchangeID, PriceSourceID)
VALUES (1234, 5, 3)  -- ExchangeID=5, PriceSourceID=3

DECLARE @Sync [Trade].[SyncConfigurationAdd]

EXEC Trade.UpdateInstrumentsMetaDataConfigurationsExtend
    @InstrumentMetaDataConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.2 Full extended update including underlying exchange

```sql
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTblExtend]
INSERT INTO @Config (InstrumentID, Symbol, SymbolFull, ExchangeID, UnderlyingExchangeID, PriceSourceID, IsTradable)
VALUES (1234, N'AAPL', N'AAPL.US.ETORO', 5, 5, 3, 1)

DECLARE @Sync [Trade].[SyncConfigurationAdd]
INSERT INTO @Sync (InstrumentID, ConfigurationUpdateTypeID, Value)
VALUES (1234, 1, 'ExchangeID=5')

EXEC Trade.UpdateInstrumentsMetaDataConfigurationsExtend
    @InstrumentMetaDataConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.3 Check current exchange and pricing configuration

```sql
SELECT
    imd.InstrumentID,
    imd.Symbol,
    imd.ExchangeID,
    imd.Exchange,
    imd.UnderlyingExchangeID,
    imd.PriceSourceID
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE imd.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMetaDataConfigurationsExtend.sql*
