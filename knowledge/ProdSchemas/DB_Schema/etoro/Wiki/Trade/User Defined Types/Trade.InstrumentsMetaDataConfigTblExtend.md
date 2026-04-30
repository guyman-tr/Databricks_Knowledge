# Trade.InstrumentsMetaDataConfigTblExtend

> TVP for bulk metadata and exchange-configuration updates per instrument, including display name, visibility, ISIN, symbol, and exchange/price-source references.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries extended instrument metadata per row: display name, tradability, visibility, industry, ISIN codes, contract expiration flag, symbol variants, plus exchange and price-source identifiers. It models the metadata config used in extended update flows (symbol full, meta data config extend).

The type exists to support UpdateInstrumentsMetaDataConfigurationsExtend and UpdateInstrumentsSymbolFullExtend. Admin or data services populate the TVP when pushing extended metadata (including exchange and price source) to Trade tables.

Services build the table, pass it as READONLY, and procedures JOIN or merge the values into instrument metadata tables.

---

## 2. Business Logic

InstrumentID + multi-column metadata group for bulk instrument metadata updates. Each row carries display, ISIN, symbol, and exchange/price-source config; procedures apply only non-null columns. Differs from InstrumentsMetaDataConfigTbl by adding ExchangeID, UnderlyingExchangeID, PriceSourceID and omitting SubCategory/ClearSubCategory.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the metadata. |
| 2 | InstrumentDisplayName | varchar(100) | YES | - | CODE-BACKED | Display name shown in UI. |
| 3 | IsTradable | bit | YES | - | CODE-BACKED | Whether the instrument is tradable. |
| 4 | IsVisible | bit | YES | - | CODE-BACKED | Whether the instrument is visible in listings. |
| 5 | IndustryID | int | YES | - | CODE-BACKED | References industry/sector classification. |
| 6 | ISINCode | varchar(100) | YES | - | CODE-BACKED | ISIN identifier. |
| 7 | ISINCountryCode | varchar(100) | YES | - | CODE-BACKED | Country code component of ISIN. |
| 8 | ContractHasExpiration | bit | YES | - | CODE-BACKED | Whether the contract has an expiration date. |
| 9 | Symbol | varchar(100) | YES | - | CODE-BACKED | Short symbol (e.g. AAPL). |
| 10 | SymbolFull | varchar(100) | YES | - | CODE-BACKED | Full symbol including suffix or exchange. |
| 11 | ExchangeID | int | YES | - | CODE-BACKED | References the primary exchange. |
| 12 | UnderlyingExchangeID | int | YES | - | CODE-BACKED | References underlying exchange for derivatives. |
| 13 | PriceSourceID | int | YES | - | CODE-BACKED | References the price feed/source. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument. ExchangeID, UnderlyingExchangeID, and PriceSourceID reference exchange and price-source entities; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | @InstrumentMetaDataConfigTbl | Parameter (TVP) | Bulk extended metadata config updates |
| Trade.UpdateInstrumentsSymbolFullExtend | @InstrumentMetaDataConfigTbl | Parameter (TVP) | Symbol full updates with exchange/price-source context |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Stored Procedure | READONLY parameter for extended metadata updates |
| Trade.UpdateInstrumentsSymbolFullExtend | Stored Procedure | READONLY parameter for symbol full updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to extend procedure
```sql
DECLARE @Config Trade.InstrumentsMetaDataConfigTblExtend;
INSERT INTO @Config (InstrumentID, InstrumentDisplayName, Symbol, SymbolFull, ExchangeID)
VALUES (12345, 'Apple Inc', 'AAPL', 'AAPL.US', 1);
EXEC Trade.UpdateInstrumentsMetaDataConfigurationsExtend @InstrumentMetaDataConfigTbl = @Config;
```

### 8.2 Symbol full update with exchange
```sql
DECLARE @Config Trade.InstrumentsMetaDataConfigTblExtend;
INSERT INTO @Config (InstrumentID, SymbolFull, PriceSourceID)
SELECT InstrumentID, Symbol + '.US', 1 FROM Trade.Instrument WHERE Symbol = 'AAPL';
EXEC Trade.UpdateInstrumentsSymbolFullExtend @InstrumentMetaDataConfigTbl = @Config;
```

### 8.3 Bulk metadata from staging
```sql
DECLARE @Config Trade.InstrumentsMetaDataConfigTblExtend;
INSERT INTO @Config (InstrumentID, InstrumentDisplayName, IsTradable, IsVisible, ExchangeID)
SELECT InstrumentID, DisplayName, 1, 1, ExchangeID FROM Staging.InstrumentMetadata;
EXEC Trade.UpdateInstrumentsMetaDataConfigurationsExtend @InstrumentMetaDataConfigTbl = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsMetaDataConfigTblExtend | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsMetaDataConfigTblExtend.sql*
