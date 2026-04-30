# Trade.GetInstrumentByIdSecurityOpsAPI

> Returns detailed instrument metadata for a single instrument ID - used by the SecurityOps API for compliance and regulatory data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (parameter and output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns comprehensive instrument metadata for a single instrument, tailored for the SecurityOps API. It provides regulatory identifiers (ISIN, CUSIP, SEDOL), exchange information, classification data, and display properties needed for compliance reporting and security operations.

The procedure exists to serve the SecurityOps API with a focused, single-instrument lookup that includes all fields needed for regulatory identification and instrument classification.

Data flow: caller passes @InstrumentID. The SP reads Trade.InstrumentMetaData and returns 20 columns including identifiers, classification, and display properties.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-row lookup by InstrumentID. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to look up. FK to Trade.Instrument. |
| 2 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Instrument identifier. |
| 3 | InstrumentDisplayName (output) | NVARCHAR | YES | - | CODE-BACKED | Human-readable instrument name (e.g., "Apple Inc"). |
| 4 | Exchange (output) | VARCHAR | YES | - | CODE-BACKED | Exchange name string. |
| 5 | Industry (output) | VARCHAR | YES | - | CODE-BACKED | Industry classification. |
| 6 | CompanyInfo (output) | NVARCHAR | YES | - | CODE-BACKED | Company description/info text. |
| 7 | InstrumentVisible (output) | BIT | - | - | CODE-BACKED | Whether the instrument is visible to end users. |
| 8 | Symbol (output) | VARCHAR | - | - | CODE-BACKED | Short ticker symbol. |
| 9 | CandleTimeframeGroup (output) | INT | YES | - | CODE-BACKED | Candle chart timeframe group. |
| 10 | SymbolFull (output) | VARCHAR | - | - | CODE-BACKED | Full ticker symbol including exchange prefix. |
| 11 | Tradable (output) | BIT | - | - | CODE-BACKED | Whether the instrument can be traded. |
| 12 | ExchangeID (output) | INT | YES | - | CODE-BACKED | Exchange identifier. FK to Dictionary.Exchange. |
| 13 | StocksIndustryID (output) | INT | YES | - | CODE-BACKED | Stock industry classification ID. |
| 14 | ISINCode (output) | VARCHAR | YES | - | CODE-BACKED | International Securities Identification Number - regulatory identifier. |
| 15 | ISINCountryCode (output) | CHAR(2) | YES | - | CODE-BACKED | Country code portion of ISIN. |
| 16 | ContractExpire (output) | DATETIME | YES | - | CODE-BACKED | Contract expiration date (for futures/options). |
| 17 | InstrumentTypeSubCategoryID (output) | INT | YES | - | CODE-BACKED | Sub-category classification within the instrument type. |
| 18 | InstrumentTypeID (output) | INT | - | - | CODE-BACKED | Asset class: 1=Indices, 2=Commodities, 4=Currencies, 5=Stocks, 6=ETFs, 10=Crypto, 11=Futures. |
| 19 | PriceSourceID (output) | INT | YES | - | CODE-BACKED | Price feed source identifier. |
| 20 | Cusip (output) | VARCHAR | YES | - | CODE-BACKED | CUSIP identifier (US/Canada securities). |
| 21 | UnderlyingExchangeID (output) | INT | YES | - | CODE-BACKED | Exchange ID of the underlying instrument (for derivatives). |
| 22 | SubCategory (output) | VARCHAR | YES | - | CODE-BACKED | Sub-category text classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | FROM | Source of all instrument metadata columns |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentByIdSecurityOpsAPI (procedure)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - single-row lookup by InstrumentID |

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

### 8.1 Look up a specific instrument

```sql
EXEC Trade.GetInstrumentByIdSecurityOpsAPI @InstrumentID = 1001;
```

### 8.2 Direct query with regulatory identifiers

```sql
SELECT  InstrumentID, InstrumentDisplayName, ISINCode, Cusip, SEDOL, ExchangeID
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

### 8.3 Find instruments by ISIN

```sql
SELECT  InstrumentID, InstrumentDisplayName, ISINCode, ISINCountryCode
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   ISINCode = 'US0378331005';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentByIdSecurityOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentByIdSecurityOpsAPI.sql*
