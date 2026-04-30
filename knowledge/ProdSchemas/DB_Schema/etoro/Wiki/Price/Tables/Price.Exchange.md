# Price.Exchange

> Master registry of 93 stock exchanges and trading venues used across eToro's pricing and instrument infrastructure - each row maps an internal ExchangeID to the exchange's standard identifiers (ISO MIC code, Reuters RIC suffix) and country, enabling feed routing, ticker resolution, and instrument display across all data providers.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | ExchangeID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Price.Exchange is the canonical lookup table for stock exchanges and trading venues in eToro's pricing system. Each row represents a distinct exchange, marketplace, or data-provider-specific venue identifier, providing the human-readable name, ISO MIC code, Reuters RIC suffix, and country for that venue.

This table serves several purposes:
1. **Instrument display**: exchange name and MIC are shown to clients when displaying stock information
2. **Feed routing**: data provider integrations (Xignite, IB/Interactive Brokers, J.P. Morgan, OMS) use ExchangeID to route price requests to the correct venue
3. **Ticker resolution**: the `Price.GetTickerInfo` SP joins this table to produce ticker+exchange+RIC combinations for liquidity provider contracts
4. **OMPD threshold filtering**: `Price.GetInstrumentsOMPDThresholdByExchangeIds` filters OMPD thresholds by exchange set, using the ExchangeIDList TVP

The 93 rows cover a wide range of venues organized by data provider context:
- **IDs 1-2**: Xignite virtual exchanges (DEFAULT_EXCHANGE, GLOBAL_EXCHANGE) - fallback venues for Xignite-sourced instruments
- **IDs 3-47**: Standard global exchanges (NYSE, NASDAQ, LSE, XETRA, Euronext, CME, etc.) with proper ISO MIC codes
- **IDs 48-67**: J.P. Morgan stock feed identifiers (2-letter country codes used by JPM data format)
- **IDs 68-93**: Additional exchanges including regional venues, OTC markets, ETF venues, and Middle Eastern exchanges

Data lifecycle: rows are inserted when new exchanges or data-provider venue mappings are added. Managed manually or via tooling. All versions tracked via SQL Server temporal (system versioning into History.Exchange).

---

## 2. Business Logic

### 2.1 Exchange Identification via MIC and RIC

**What**: Each exchange carries two industry-standard identifiers used by different data providers.

**Columns/Parameters Involved**: `Mic`, `Ric`

**Rules**:
- Mic (ISO 10383 Market Identifier Code): 4-character standardized exchange code used by Bloomberg, ICE, and regulatory systems (e.g., XNYS=NYSE, XNAS=NASDAQ, XLON=LSE, XETR=XETRA)
- Ric (Reuters/Refinitiv exchange suffix): 1-2 character code appended to Reuters tickers (e.g., N=NYSE: "AAPL.N", L=LSE: "HSBA.L", OQ=NASDAQ: "MSFT.OQ")
- Ric is nullable: exchanges without Refinitiv data (IB-specific venues, JPM codes, newer exchanges) have NULL
- Some exchanges share a MIC but have different ExchangeIDs (e.g., ExchangeID 3 NYSE and 11 ISLAND both use XNYS) - this reflects data-provider-level venue distinctions within the same exchange

### 2.2 J.P. Morgan Exchange Code Pattern

**What**: ExchangeIDs 48-67 (and 77, 92) follow a distinct pattern: 2-letter codes (US, HK, GR, FP, etc.) mapping to JPM-specific venue identifiers.

**Rules**:
- JPM uses 2-letter country/region codes rather than ISO MIC codes for their equity feeds
- Most JPM entries have CountryID=0 (not resolved to a specific Dictionary.Country entry)
- These are internal feed identifiers, not ISO-standard exchange codes
- Used specifically when Trade.LiquidityProviderContracts routes through a JPM liquidity provider

### 2.3 Xignite Virtual Exchanges

**What**: IDs 1 (DEFAULT_EXCHANGE) and 2 (GLOBAL_EXCHANGE) are virtual constructs for Xignite data feed routing.

**Rules**:
- CountryID=0: not tied to any specific country
- MIC values "DEFEXC" and "GLBEXC" are not ISO standard - internal Xignite routing identifiers
- Instruments assigned to these exchanges get prices from Xignite's default or global quote feeds

---

## 3. Data Overview

*93 rows total. Key exchanges enumerated:*

| ExchangeID | Name | MIC | Country | Ric | Category |
|---|---|---|---|---|---|
| 1 | DEFAULT_EXCHANGE | DEFEXC | - | - | Xignite virtual |
| 2 | GLOBAL_EXCHANGE | GLBEXC | - | - | Xignite virtual |
| 3 | NYSE | XNYS | US (219) | N | US equities |
| 4 | NASDAQ | XNAS | US (219) | OQ | US equities |
| 5 | XETRA | XETR | Germany (79) | DE | German equities |
| 6 | LSE | XLON | UK (218) | L | UK equities |
| 8 | BATS | BCXE | US (219) | Z | US ATS |
| 12 | SFB | XOME | Sweden (196) | ST | Nordic equities |
| 16 | ARCA | ARCX | US (219) | P | NYSE Arca ETFs |
| 17 | XMIL | XMIL | Italy (102) | MI | Italian equities |
| 20 | SBF | XPAR | France (74) | PA | Euronext Paris |
| 22 | TSE | XTSE | Canada (38) | - | Canadian equities |
| 24 | BM | XMCE | Spain (191) | MC | Madrid |
| 25 | VIRTX | XVTX | Switzerland (197) | - | SIX Swiss |
| 27 | PINK | PINK | US (219) | PK | OTC Pink |
| 28 | BRU | XBRU | Belgium (19) | BR | Euronext Brussels |
| 30 | AEB | XAMS | Netherlands (0) | AS | Euronext Amsterdam |
| 35 | SWS | XSWX | Switzerland (197) | S | Swiss Exchange |
| 37 | NYMEX | XCME | US (219) | - | CME commodities |
| 43 | ASX | XASX | Australia (12) | AX | Australian equities |
| 48-67 | US/HK/GR/... | (2-letter) | varies | - | JPM feed codes |
| 68 | TYO | XTKS | - | - | Tokyo |
| 81 | DFM | XDFM | UAE (217) | DU | Dubai |
| 86 | Tadawul | XSAU | Saudi Arabia (179) | - | Saudi exchange |
| 91 | LSE_AIM | XLON | UK (218) | - | London AIM |
| 93 | Abu_Dhabi | XADS | UAE (217) | AD | Abu Dhabi |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NOT NULL | - | VERIFIED | Primary key. Integer identifier assigned manually (not IDENTITY). Organizes by data-provider context: 1-2 = Xignite virtual; 3-47 = standard exchanges; 48-67 = JPM codes; 68+ = additional venues. Referenced by Trade.LiquidityProviderContracts.ExchangeID and Trade.InstrumentMetaData.ExchangeID. |
| 2 | Name | varchar(16) | NOT NULL | - | VERIFIED | Short exchange code name (up to 16 chars). Used in operations tooling and GetTickerInfo output. Not always an ISO standard code - some are IB-specific (IDEALPRO, ISLAND, SMART) or vendor-specific (DEFAULT_EXCHANGE). |
| 3 | Description | varchar(150) | NOT NULL | - | VERIFIED | Human-readable full exchange name. Some have minor typos from original data entry (e.g., "Eurpoe CHIX", "Exchnage"). Displayed in internal tooling and monitoring dashboards. |
| 4 | Mic | varchar(16) | NOT NULL | - | VERIFIED | Market Identifier Code (ISO 10383). Standard 4-character exchange identifier used by Bloomberg, regulatory reporting, and feed routing. Some non-standard values exist for virtual venues (DEFEXC, GLBEXC) and broker-specific identifiers (SMRT, IDLP, JPM 2-letter codes). |
| 5 | CountryID | int | NOT NULL | - | CODE-BACKED | FK to Dictionary.Country. Geographic country of the exchange. CountryID=0 for exchanges without a resolved country mapping (JPM codes, some virtual venues). Key country IDs: 219=USA, 218=UK, 79=Germany, 74=France, 102=Italy, 196=Sweden, 197=Switzerland. |
| 6 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on every DML. |
| 7 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). Populated when the calling service sets context_info before DML. |
| 8 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start. Auto-managed by SQL Server system versioning. |
| 9 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31...' | CODE-BACKED | Temporal row validity end. Historical versions in History.Exchange. |
| 10 | Ric | varchar(16) | YES | - | VERIFIED | Reuters/Refinitiv exchange suffix appended to RIC tickers (e.g., AAPL.N where N = NYSE). NULL for exchanges not available on Reuters/Refinitiv or where RIC routing is not used. Used by GetTickerInfo to build complete Reuters ticker strings for liquidity provider feeds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | FK (FK_PRICE_EXCHANGE_COUNTRY) | Links exchange to its geographic country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviderContracts | ExchangeID | Implicit/FK | Links trading contracts to their exchange venue |
| Trade.InstrumentMetaData | ExchangeID | Implicit | Associates instrument metadata with primary listing exchange |
| Price.GetTickerInfo | ExchangeID | JOIN (via LiquidityProviderContracts) | Returns exchange Name, MIC, and RIC in ticker lookup output |
| Price.GetInstrumentsOMPDThresholdByExchangeIds | ExchangeID | JOIN (via InstrumentMetaData) | Filters OMPD thresholds by exchange set |
| Price.GetInstrumentDisplayData | ExchangeID | JOIN | Includes exchange data in instrument display output |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.Exchange (table)
  |-- FK -> Dictionary.Country
  ^-- Referenced by: Trade.LiquidityProviderContracts, Trade.InstrumentMetaData
  ^-- Read by: Price.GetTickerInfo, Price.GetInstrumentsOMPDThresholdByExchangeIds, Price.GetInstrumentDisplayData
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK - exchange country must exist in country lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetTickerInfo | Stored Procedure | JOINs to get exchange Name, Mic, Ric for ticker output |
| Price.GetInstrumentsOMPDThresholdByExchangeIds | Stored Procedure | Filters OMPD thresholds by exchange ID set (via InstrumentMetaData.ExchangeID) |
| Price.GetInstrumentDisplayData | View | Includes exchange data in instrument display information |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PRICE_EXCHANGE | CLUSTERED PK | ExchangeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PRICE_EXCHANGE_COUNTRY | FK | CountryID -> Dictionary.Country(CountryID) |
| DF_Exchange_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_Exchange_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.Exchange |
| TRG_T_Exchange | TRIGGER (INSERT) | ASM no-op placeholder: self-update on ExchangeID |

---

## 8. Sample Queries

### 8.1 List all exchanges with country names

```sql
SELECT E.ExchangeID, E.Name, E.Description, E.Mic, E.Ric,
       C.Name AS CountryName
FROM Price.Exchange E WITH (NOLOCK)
LEFT JOIN Dictionary.Country C WITH (NOLOCK) ON E.CountryID = C.CountryID
ORDER BY E.ExchangeID;
```

### 8.2 Find exchange by MIC code

```sql
SELECT ExchangeID, Name, Description, Mic, Ric
FROM Price.Exchange WITH (NOLOCK)
WHERE Mic = 'XNAS';  -- NASDAQ
```

### 8.3 View exchange change history (temporal)

```sql
SELECT ExchangeID, Name, Mic, Ric, DbLoginName, SysStartTime, SysEndTime
FROM Price.Exchange
FOR SYSTEM_TIME ALL
WHERE ExchangeID = 3
ORDER BY SysStartTime;
```

### 8.4 Find exchanges for a specific country

```sql
SELECT E.ExchangeID, E.Name, E.Mic, E.Ric
FROM Price.Exchange E WITH (NOLOCK)
WHERE E.CountryID = 219  -- United States
ORDER BY E.ExchangeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.Exchange | Type: Table | Source: etoro/etoro/Price/Tables/Price.Exchange.sql*
