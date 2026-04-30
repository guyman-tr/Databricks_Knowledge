# Trade.UpdateInstrumentsMetaDataConfigurations

> Orchestrates a null-safe partial update of 10 metadata fields on Trade.InstrumentMetaData (display name, tradability, visibility, industry, ISIN, contract expiration, symbol, SubCategory), writes SyncConfiguration events, and delegates to Trade.UpdateInstrumentsSymbolFull for ProviderToInstrument and symbol propagation - all within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentMetaDataConfigTbl.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the standard entry point for updating instrument metadata configuration from the operations tooling layer. It covers the core set of instrument presentation and trading eligibility attributes: display name, tradability, visibility, industry classification, ISIN codes, contract expiration flag, ticker symbol, and subcategory.

The null-safe pattern (IIF(field IS NULL, current, new)) allows callers to update only the fields they care about in a single call, without needing to first read the current values. This procedure is used for the base InstrumentsMetaDataConfigTbl TVP type.

After updating InstrumentMetaData, it also calls Trade.UpdateInstrumentsSymbolFull to propagate symbol and SymbolFull changes to ProviderToInstrument and TradonomiContracts (see that procedure's documentation for full detail). All three operations - InstrumentMetaData update, SyncConfiguration insert, and UpdateInstrumentsSymbolFull - are committed in one transaction.

The SubCategory field has a special clear-on-demand behavior: if ClearSubCategory = 0 (normal), the null-safe pattern applies; if ClearSubCategory = 1, SubCategory is explicitly set to NULL (force-clear regardless of SubCategory value).

---

## 2. Business Logic

### 2.1 Null-Safe Partial Update with Industry Name Resolution

**What**: 10 fields updated with null-safe semantics; IndustryID additionally resolved to Industry name via GetDictionaryStocksIndustry.

**Columns/Parameters Involved**: All 10 metadata fields in TVP; `Trade.GetDictionaryStocksIndustry.IndustryName`

**Rules**:
- `IIF(IMDCT.Field IS NULL, TIMD.Field, IMDCT.Field)` for: InstrumentDisplayName, IsTradable->Tradable, IsVisible->InstrumentVisible, ISINCode, ISINCountryCode, ContractHasExpiration->ContractExpire, Symbol, SymbolFull
- Industry + StocksIndustryID: `IIF(IndustryID IS NULL OR IndustryID = 0, current, new)` - zero treated same as NULL
  - Industry (text) = TGDSI.IndustryName from GetDictionaryStocksIndustry when IndustryID provided
  - StocksIndustryID = IMDCT.IndustryID when provided
- SubCategory: `IIF(ClearSubCategory = 0, IIF(SubCategory IS NULL, current, IMDCT.SubCategory), NULL)` - ClearSubCategory=1 forces NULL regardless of SubCategory value

### 2.2 SyncConfiguration Events

**What**: All rows from @InstrumentSyncConfigurationAddTable are inserted verbatim into Trade.SyncConfiguration.

**Rules**:
- `INSERT INTO Trade.SyncConfiguration SELECT InstrumentID, ConfigurationUpdateTypeID, Value FROM @InstrumentSyncConfigurationAddTable`
- Can be empty (no effect)

### 2.3 Symbol Propagation via UpdateInstrumentsSymbolFull

**What**: After the InstrumentMetaData update, delegates to Trade.UpdateInstrumentsSymbolFull to propagate symbol changes downstream.

**Rules**:
- `EXEC Trade.UpdateInstrumentsSymbolFull @InstrumentMetaDataConfigTbl = @InstrumentMetaDataConfigTbl`
- Same TVP passed through; UpdateInstrumentsSymbolFull handles ProviderToInstrument and TradonomiContracts updates (see its documentation for full detail)
- Runs within the same transaction

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentMetaDataConfigTbl | Trade.InstrumentsMetaDataConfigTbl (TVP, READONLY) | NO | - | CODE-BACKED | Metadata update batch. InstrumentID (int NOT NULL) is the join key. Nullable fields (NULL = keep current): InstrumentDisplayName (nvarchar), IsTradable (bit), IsVisible (bit), IndustryID (int - 0 treated as NULL), ISINCode (nvarchar), ISINCountryCode (nvarchar), ContractHasExpiration (bit), Symbol (nvarchar), SymbolFull (nvarchar). Special field: ClearSubCategory (bit NOT NULL DEFAULT 0 - set to 1 to force SubCategory to NULL), SubCategory (nullable). |
| 2 | @InstrumentSyncConfigurationAddTable | Trade.SyncConfigurationAdd (TVP, READONLY) | NO | - | CODE-BACKED | Sync events inserted verbatim into Trade.SyncConfiguration. Contains InstrumentID, ConfigurationUpdateTypeID, Value. Can be empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | UPDATE | 10 metadata fields updated with null-safe IIF pattern |
| IndustryID | Trade.GetDictionaryStocksIndustry | Lookup JOIN | Resolves IndustryID to IndustryName for the Industry text column |
| Sync events | Trade.SyncConfiguration | INSERT | Configuration change events for downstream sync |
| @InstrumentMetaDataConfigTbl | Trade.UpdateInstrumentsSymbolFull | EXEC call | Symbol/SymbolFull propagation to ProviderToInstrument and TradonomiContracts |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External configuration tooling | Application call | Caller | No internal SP callers found; called from instrument management tooling (Opstool or similar) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsMetaDataConfigurations (procedure)
|- Trade.InstrumentMetaData (table) [UPDATE - 10 metadata fields, null-safe]
|- Trade.GetDictionaryStocksIndustry (function/view) [Lookup JOIN - IndustryID to IndustryName]
|- Trade.SyncConfiguration (table) [INSERT - sync events]
+-- Trade.UpdateInstrumentsSymbolFull (procedure) [EXEC - symbol propagation]
      +-- [see Trade.UpdateInstrumentsSymbolFull.md for full chain]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | UPDATEd: 10 metadata columns with null-safe IIF pattern |
| Trade.GetDictionaryStocksIndustry | View/Function | LEFT JOIN: resolves IndustryID to IndustryName text for Industry column |
| Trade.SyncConfiguration | Table | INSERTed: sync events from @InstrumentSyncConfigurationAddTable |
| Trade.UpdateInstrumentsSymbolFull | Procedure | EXECuted: propagates Symbol/SymbolFull to ProviderToInstrument and TradonomiContracts |
| Trade.InstrumentsMetaDataConfigTbl | User Defined Type | TVP type for @InstrumentMetaDataConfigTbl |
| Trade.SyncConfigurationAdd | User Defined Type | TVP type for @InstrumentSyncConfigurationAddTable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument management tooling | Application | Calls for instrument metadata configuration updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Null-safe partial update | Logic | IIF pattern for all 10 fields; NULL input = preserve current value |
| IndustryID=0 treated as NULL | Business rule | `IIF(IndustryID IS NULL OR IndustryID = 0, ...)` - zero is not a valid IndustryID |
| ClearSubCategory | Design | ClearSubCategory=1 overrides null-safe pattern and forces SubCategory to NULL |
| Atomic transaction | TRY/CATCH | InstrumentMetaData UPDATE + SyncConfiguration INSERT + UpdateInstrumentsSymbolFull EXEC in one transaction |

---

## 8. Sample Queries

### 8.1 Update display name and tradability

```sql
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTbl]
INSERT INTO @Config (InstrumentID, InstrumentDisplayName, IsTradable)
VALUES (1234, N'Apple Inc', 1)

DECLARE @Sync [Trade].[SyncConfigurationAdd]

EXEC Trade.UpdateInstrumentsMetaDataConfigurations
    @InstrumentMetaDataConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.2 Clear subcategory for an instrument

```sql
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTbl]
INSERT INTO @Config (InstrumentID, ClearSubCategory)
VALUES (1234, 1)  -- ClearSubCategory=1 sets SubCategory to NULL

DECLARE @Sync [Trade].[SyncConfigurationAdd]

EXEC Trade.UpdateInstrumentsMetaDataConfigurations
    @InstrumentMetaDataConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.3 Check current metadata for an instrument

```sql
SELECT
    imd.InstrumentID,
    imd.InstrumentDisplayName,
    imd.Tradable,
    imd.InstrumentVisible,
    imd.StocksIndustryID,
    imd.Industry,
    imd.Symbol,
    imd.SymbolFull,
    imd.ISINCode,
    imd.SubCategory
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
*Object: Trade.UpdateInstrumentsMetaDataConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsMetaDataConfigurations.sql*
