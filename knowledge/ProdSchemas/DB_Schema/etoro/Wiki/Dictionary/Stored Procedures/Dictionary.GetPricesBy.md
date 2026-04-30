# Dictionary.GetPricesBy

> Stored procedure returning all price source definitions with aliased output columns from Dictionary.PriceSourceName.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Id + Name from PriceSourceName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetPricesBy returns the complete list of price data sources used across the eToro platform for instrument pricing. Different instruments receive real-time price feeds from different market data providers and exchanges — this procedure provides the reference data that maps PriceSourceID values to human-readable names.

The 27 price sources span major global exchanges and data providers: eToro (internal pricing engine), Xignite (market data aggregator), CME (Chicago futures), NASDAQ, Chi-Ex (European equities), LSE PLC (London Stock Exchange), Xetra (Deutsche Börse), Euronext, HKEX (Hong Kong), and many more including Blue Ocean (off-hours trading venue).

The procedure uses SET NOCOUNT ON for clean API output and aliases the columns as 'Id' and 'Name' (instead of PriceSourceID and Name) for standardized API consumption where the caller expects a generic ID/Name pair format.

---

## 2. Business Logic

### 2.1 Price Source Registry

**What**: Maps numeric price source identifiers to exchange/provider names for instrument configuration and reporting.

**Columns/Parameters Involved**: `Id` (aliased from PriceSourceID), `Name`

**Rules**:
- PriceSourceID=0 (eToro): Internal pricing engine — used for instruments where eToro generates its own prices
- PriceSourceID=1 (Xignite): Third-party market data aggregation service
- PriceSourceID=2-22: Major global exchanges (CME, NASDAQ, LSE, Xetra, Euronext, HKEX, etc.)
- PriceSourceID=27-30: Additional exchanges added later (NSE, Nasdaq Baltic, KRX, Blue Ocean)
- Gap in IDs (23-26): No assigned price sources — likely reserved or removed
- Each instrument in Dictionary.Currency has a PriceSourceID that references one of these 27 sources
- Country table also references PriceSourceID for country-level default pricing

**Diagram**:
```
Dictionary.GetPricesBy Output (aliased as Id/Name)
│
│ Id │ Name           │ Coverage
│ ───┼────────────────┼────────────────────────
│  0 │ eToro          │ Internal prices (CFDs, crypto)
│  1 │ Xignite        │ Multi-market data aggregator
│  2 │ CME            │ US futures (Oil, Gold, indices)
│  3 │ NASDAQ         │ US equities + options
│  4 │ Chi-Ex         │ European equities
│  5 │ LSE PLC        │ UK equities
│  6 │ Xetra          │ German equities
│  7 │ Euronext       │ French/Dutch/Belgian equities
│  8 │ DFM            │ Dubai Financial Market
│  9 │ HKEX           │ Hong Kong equities
│ 10 │ TMX            │ Canadian equities
│ .. │ ...            │ ...
│ 30 │ Blue Ocean     │ Off-hours US trading venue
│
└── Referenced by: Dictionary.Currency.PriceSourceID (8+ consumers)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure takes no input parameters |
| R1 | Id | int | NO | - | VERIFIED | Output (aliased from PriceSourceID): Numeric identifier for the price data source/exchange. FK referenced by Dictionary.Currency.PriceSourceID and Dictionary.Country.PriceSourceID. Values: 0=eToro, 1=Xignite, 2=CME, 3=NASDAQ, 4=Chi-Ex, 5=LSE PLC, 6=Xetra, 7=Euronext, 8=DFM, 9=HKEX, 10=TMX, 11=ADX, 12=BME, 13=Nasdaq Nordic, 14=CBOE Japan, 15=SGX, 16=TWSE, 17=CBOE EU, 18=CBOE AUS, 19=Wiener Borse, 20=Prague SE, 21=Warsaw SE, 22=Budapest SE, 27=NSE, 28=Nasdaq Baltic, 29=KRX, 30=Blue Ocean. (Dictionary.PriceSourceName) |
| R2 | Name | varchar | NO | - | VERIFIED | Output (aliased from PriceSourceName.Name): Human-readable exchange/provider name displayed in instrument configuration and reporting UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (result set) | Dictionary.PriceSourceName | SELECT | Full table read with aliased column names |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PSConfigurations user | - | EXECUTE permission | Price/configuration service has execute rights |
| (Application layer) | - | API call | Called by trading configuration services to populate price source selectors |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetPricesBy (procedure)
└── Dictionary.PriceSourceName (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PriceSourceName | Table | SELECT PriceSourceID AS 'Id', Name AS 'Name' — full table read with aliases |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Application services) | External | API-level consumer for price source reference data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. PriceSourceName has a clustered PK on PriceSourceID.

### 7.2 Constraints

None. The procedure uses SET NOCOUNT ON to suppress row count messages, which is standard for API-consumed procedures. Column aliasing (PriceSourceID→Id, Name→Name) provides a standardized ID/Name output contract.

---

## 8. Sample Queries

### 8.1 Get all price sources (equivalent to procedure output)
```sql
SELECT  PriceSourceID AS Id, [Name] AS [Name]
FROM    Dictionary.PriceSourceName WITH (NOLOCK)
```

### 8.2 Find instruments using a specific price source
```sql
SELECT  c.CurrencyID, c.Name AS Instrument, c.Abbreviation, psn.Name AS PriceSource
FROM    Dictionary.Currency c WITH (NOLOCK)
JOIN    Dictionary.PriceSourceName psn WITH (NOLOCK) ON psn.PriceSourceID = c.PriceSourceID
WHERE   psn.Name = 'NASDAQ'
ORDER BY c.Name
```

### 8.3 Count instruments per price source
```sql
SELECT  psn.PriceSourceID, psn.Name AS PriceSource, COUNT(c.CurrencyID) AS InstrumentCount
FROM    Dictionary.PriceSourceName psn WITH (NOLOCK)
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.PriceSourceID = psn.PriceSourceID
GROUP BY psn.PriceSourceID, psn.Name
ORDER BY InstrumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetPricesBy | Type: Stored Procedure | Source: etoro/etoro/Dictionary/Stored Procedures/Dictionary.GetPricesBy.sql*
