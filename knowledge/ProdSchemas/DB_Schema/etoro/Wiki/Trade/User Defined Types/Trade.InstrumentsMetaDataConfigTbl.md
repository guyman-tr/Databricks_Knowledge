# Trade.InstrumentsMetaDataConfigTbl

> TVP for bulk updates of instrument metadata - display names, visibility, tradability, ISIN codes, symbols, and category flags.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries per-instrument metadata configuration - display names, tradability and visibility flags, ISIN and symbol information, industry, and category data. It models the client-facing and operational metadata for each tradable instrument.

The type exists to support bulk metadata updates when instruments are added or revised, when display names or symbols change, when instruments are enabled/disabled for trading or visibility, or when regulatory data (ISIN) is updated. UpdateInstrumentsMetaDataConfigurations and UpdateInstrumentsSymbolFull consume this TVP.

Services populate the TVP from external data feeds or admin UIs, pass it to procedures that MERGE or UPDATE the instrument metadata tables.

---

## 2. Business Logic

InstrumentID + metadata column group. Each row represents a full metadata snapshot for one instrument. Multiple columns (IsTradable, IsVisible, IndustryID, ISINCode, Symbol, etc.) together define the instrument's market presentation and classification.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument. Identifies the instrument whose metadata is being updated |
| 2 | InstrumentDisplayName | varchar(100) | YES | - | NAME-INFERRED | Human-readable name shown to users in the trading UI |
| 3 | IsTradable | bit | YES | - | CODE-BACKED | Whether the instrument is open for trading (1) or suspended (0) |
| 4 | IsVisible | bit | YES | - | CODE-BACKED | Whether the instrument is shown in instrument lists/search (1) or hidden (0) |
| 5 | IndustryID | int | YES | - | CODE-BACKED | References industry/sector classification (e.g., stocks, commodities, crypto) |
| 6 | ISINCode | varchar(100) | YES | - | NAME-INFERRED | International Securities Identification Number for regulatory/reporting |
| 7 | ISINCountryCode | varchar(100) | YES | - | NAME-INFERRED | Country code associated with the ISIN |
| 8 | ContractHasExpiration | bit | YES | - | NAME-INFERRED | Whether the instrument has an expiration date (e.g., futures, options) |
| 9 | Symbol | varchar(100) | YES | - | CODE-BACKED | Short trading symbol (e.g., AAPL, BTC) |
| 10 | SymbolFull | varchar(100) | YES | - | CODE-BACKED | Full symbol including exchange or qualifiers |
| 11 | SubCategory | varchar(255) | YES | - | NAME-INFERRED | Sub-classification within industry (e.g., Tech, Healthcare) |
| 12 | ClearSubCategory | bit | NO | 0 | NAME-INFERRED | Flag to clear/reset SubCategory when updating |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument. IndustryID may reference an industry dictionary but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMetaDataConfigurations | @InstrumentMetaDataConfigTbl | Parameter (TVP) | Bulk metadata configuration updates |
| Trade.UpdateInstrumentsSymbolFull | @InstrumentMetaDataConfigTbl | Parameter (TVP) | Updates SymbolFull for listed instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMetaDataConfigurations | Stored Procedure | READONLY parameter for metadata updates |
| Trade.UpdateInstrumentsSymbolFull | Stored Procedure | READONLY parameter for symbol updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk metadata update
```sql
DECLARE @InstrumentMetaDataConfigTbl Trade.InstrumentsMetaDataConfigTbl;
INSERT INTO @InstrumentMetaDataConfigTbl (InstrumentID, InstrumentDisplayName, IsTradable, IsVisible, IndustryID, Symbol, SymbolFull, SubCategory, ClearSubCategory)
VALUES (1, 'Apple Inc', 1, 1, 1, 'AAPL', 'AAPL.NASDAQ', 'Technology', 0);
EXEC Trade.UpdateInstrumentsMetaDataConfigurations @InstrumentMetaDataConfigTbl = @InstrumentMetaDataConfigTbl;
```

### 8.2 Symbol full update only
```sql
DECLARE @InstrumentMetaDataConfigTbl Trade.InstrumentsMetaDataConfigTbl;
INSERT INTO @InstrumentMetaDataConfigTbl (InstrumentID, InstrumentDisplayName, IsTradable, IsVisible, IndustryID, ISINCode, ISINCountryCode, ContractHasExpiration, Symbol, SymbolFull, SubCategory, ClearSubCategory)
SELECT InstrumentID, InstrumentDisplayName, IsTradable, IsVisible, IndustryID, ISINCode, ISINCountryCode, ContractHasExpiration, Symbol, Symbol + '.LSE', SubCategory, 0
FROM Trade.InstrumentMetaData WHERE InstrumentID IN (1,2,3);
EXEC Trade.UpdateInstrumentsSymbolFull @InstrumentMetaDataConfigTbl = @InstrumentMetaDataConfigTbl;
```

### 8.3 Visibility and tradability toggle
```sql
DECLARE @InstrumentMetaDataConfigTbl Trade.InstrumentsMetaDataConfigTbl;
INSERT INTO @InstrumentMetaDataConfigTbl (InstrumentID, InstrumentDisplayName, IsTradable, IsVisible, IndustryID, ISINCode, ISINCountryCode, ContractHasExpiration, Symbol, SymbolFull, SubCategory, ClearSubCategory)
SELECT InstrumentID, InstrumentDisplayName, 0, 0, IndustryID, ISINCode, ISINCountryCode, ContractHasExpiration, Symbol, SymbolFull, SubCategory, 0
FROM Trade.InstrumentMetaData WHERE IndustryID = 5;
EXEC Trade.UpdateInstrumentsMetaDataConfigurations @InstrumentMetaDataConfigTbl = @InstrumentMetaDataConfigTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsMetaDataConfigTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsMetaDataConfigTbl.sql*
