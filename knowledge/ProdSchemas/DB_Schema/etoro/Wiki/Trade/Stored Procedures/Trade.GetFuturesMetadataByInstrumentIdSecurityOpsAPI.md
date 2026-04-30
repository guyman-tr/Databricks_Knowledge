# Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI

> Returns combined instrument and futures metadata for the SecurityOps API. Joins Trade.FuturesMetaData with Trade.InstrumentMetaData for a single InstrumentID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a unified view of instrument and futures metadata for the SecurityOps API. It combines Trade.FuturesMetaData (futures-specific fields like ContractExpire, Multiplier, MinimalTick, LastTradingDateTime) with Trade.InstrumentMetaData (general instrument fields like Symbol, ExchangeID, Industry). The result supports security operations, compliance, and trading system integrations.

The procedure exists to serve the SecurityOps API with a single call instead of multiple lookups across tables. Futures have additional attributes beyond base instruments; this procedure assembles them into one result set.

Data flow: @InstrumentID filters both Trade.FuturesMetaData and Trade.InstrumentMetaData. The procedure joins these tables and returns a wide result set including InstrumentID, InstrumentDisplayName, Exchange, Industry, CompanyInfo, Symbol, CandleTimeframeGroup, SymbolFull, Tradable, ExchangeID, StocksIndustryID, ISINCode, ISINCountryCode, ContractExpire, InstrumentTypeSubCategoryID, InstrumentTypeID, PriceSourceID, Cusip, UnderlyingExchangeID, SubCategory, Multiplier, MinimalTick, LastTradingDateTime, ExpirationDateTime, SettlementTime, IndexPointValue, SettlementMethod.

---

## 2. Business Logic

### 2.1 Futures-Specific Metadata Enrichment

**What**: Futures instruments get additional attributes (expiration, multiplier, tick size, settlement) from FuturesMetaData.

**Columns/Parameters Involved**: `ContractExpire`, `Multiplier`, `MinimalTick`, `LastTradingDateTime`, `ExpirationDateTime`, `SettlementTime`, `IndexPointValue`, `SettlementMethod`

**Rules**:
- Trade.FuturesMetaData holds futures-only fields
- JOIN on InstrumentID ensures 1:1 relationship with base instrument
- Output includes both base instrument columns and futures-specific columns

### 2.2 Single-Instrument Lookup by InstrumentID

**What**: Exactly one InstrumentID is queried. Returns one row when the futures instrument exists.

**Columns/Parameters Involved**: `@InstrumentID`

**Rules**:
- @InstrumentID is the sole filter
- No rows returned if instrument is not a futures type or does not exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. Filters to this futures instrument. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Output. Instrument identifier. PK. |
| 3 | InstrumentDisplayName | VARCHAR | NO | - | CODE-BACKED | Display name for UI. |
| 4 | Exchange | VARCHAR | NO | - | CODE-BACKED | Exchange name. |
| 5 | Industry | VARCHAR | YES | - | CODE-BACKED | Industry sector. |
| 6 | CompanyInfo | VARCHAR | YES | - | CODE-BACKED | Company or underlying info. |
| 7 | InstrumentVisible | BIT | NO | - | CODE-BACKED | 1 = visible in UI; 0 = hidden. |
| 8 | Symbol | VARCHAR | NO | - | CODE-BACKED | Trading symbol. |
| 9 | CandleTimeframeGroup | INT | YES | - | CODE-BACKED | Candle/timeframe grouping for charts. |
| 10 | SymbolFull | VARCHAR | YES | - | CODE-BACKED | Full symbol including suffix. |
| 11 | Tradable | BIT | NO | - | CODE-BACKED | 1 = tradable; 0 = not tradable. |
| 12 | ExchangeID | INT | NO | - | CODE-BACKED | Exchange identifier. FK to exchange lookup. |
| 13 | StocksIndustryID | INT | YES | - | CODE-BACKED | Industry ID for stocks classification. |
| 14 | ISINCode | VARCHAR | YES | - | CODE-BACKED | ISIN identifier. |
| 15 | ISINCountryCode | VARCHAR | YES | - | CODE-BACKED | Country of ISIN registration. |
| 16 | ContractExpire | DATE | YES | - | CODE-BACKED | Contract expiration date. Futures-specific. |
| 17 | InstrumentTypeSubCategoryID | INT | YES | - | CODE-BACKED | Sub-category of instrument type. |
| 18 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type. FK to instrument type lookup. |
| 19 | PriceSourceID | INT | YES | - | CODE-BACKED | Price feed source. |
| 20 | Cusip | VARCHAR | YES | - | CODE-BACKED | CUSIP identifier. |
| 21 | UnderlyingExchangeID | INT | YES | - | CODE-BACKED | Exchange of the underlying asset. |
| 22 | SubCategory | VARCHAR | YES | - | CODE-BACKED | Sub-category name. |
| 23 | Multiplier | DECIMAL | YES | - | CODE-BACKED | Contract multiplier. Futures-specific. |
| 24 | MinimalTick | DECIMAL | YES | - | CODE-BACKED | Minimum price increment. |
| 25 | LastTradingDateTime | DATETIME | YES | - | CODE-BACKED | Last trading date/time. Futures-specific. |
| 26 | ExpirationDateTime | DATETIME | YES | - | CODE-BACKED | Expiration date/time. |
| 27 | SettlementTime | DATETIME | YES | - | CODE-BACKED | Settlement time. |
| 28 | IndexPointValue | DECIMAL | YES | - | CODE-BACKED | Point value for index futures. |
| 29 | SettlementMethod | VARCHAR | YES | - | CODE-BACKED | Cash or physical settlement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.FuturesMetaData | JOIN | Futures-specific metadata |
| (body) | Trade.InstrumentMetaData | JOIN | Base instrument metadata |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI (procedure)
+-- Trade.FuturesMetaData (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesMetaData | Table | JOIN - futures-specific columns |
| Trade.InstrumentMetaData | Table | JOIN - base instrument columns |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a futures instrument

```sql
EXEC Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI @InstrumentID = 12345;
```

### 8.2 Batch lookup for multiple futures

```sql
DECLARE @ids TABLE (InstrumentID INT);
INSERT INTO @ids VALUES (12345), (12346), (12347);

DECLARE @id INT;
DECLARE c CURSOR FOR SELECT InstrumentID FROM @ids;
OPEN c;
FETCH NEXT FROM c INTO @id;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI @InstrumentID = @id;
    FETCH NEXT FROM c INTO @id;
END;
CLOSE c; DEALLOCATE c;
```

### 8.3 Join output to get human-readable instrument type

```sql
-- After calling the procedure into a table variable or temp table
SELECT  fm.*, it.Name AS InstrumentTypeName
FROM    #FuturesMeta fm
        LEFT JOIN Dictionary.InstrumentType it WITH (NOLOCK) ON it.InstrumentTypeID = fm.InstrumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI.sql*
