# Dictionary.Currency

> Master reference table defining all 10,669 tradeable instruments (stocks, ETFs, forex pairs, commodities, indices, crypto) on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CurrencyID (INT, CLUSTERED PK) |
| **Row Count** | 10,669 rows across 6 asset classes |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 4 active (PK clustered + unique on Abbreviation + NC on CurrencyTypeID, Name) — all PAGE compressed |
| **Audit Triggers** | 3 (INSERT, UPDATE, DELETE → History.AuditHistory) |

---

## 1. Business Meaning

Dictionary.Currency is one of the most critical tables in the entire eToro database. Despite its name suggesting only currencies, it is the **universal instrument registry** — every tradeable asset on the platform is a row in this table, from EUR/USD forex pairs to Apple stock to Bitcoin.

The legacy naming (Currency/CurrencyID) reflects eToro's origins as a forex-only platform. As the platform expanded to stocks (8,632 instruments), ETFs (652), crypto (630), commodities (412), and indices (167), the table retained its original name while becoming the master instrument table.

CurrencyID is referenced by virtually every trading table: `Trade.PositionTbl.CurrencyID` stores which instrument a position is on, `Trade.DelayedOrderForOpen.CurrencyID` stores which instrument a pending order targets, and instrument configuration tables link features, fees, and restrictions to CurrencyID.

Every DML operation on this table (INSERT, UPDATE, DELETE) is captured column-by-column to `History.AuditHistory` via three ASM-generated audit triggers. This ensures full traceability of instrument configuration changes.

---

## 2. Business Logic

### 2.1 Instrument Classification by Asset Class

**What**: Each instrument belongs to exactly one asset class (CurrencyType), which determines trading rules, margin requirements, and settlement behavior.

**Columns/Parameters Involved**: `CurrencyTypeID`

**Rules**:
- **Stocks** (CurrencyTypeID=5): 8,632 instruments — largest category. Individual company shares. Can be REAL (1x leverage) or CFD.
- **ETF** (CurrencyTypeID=6): 652 instruments — exchange-traded funds. Similar trading rules to stocks.
- **Crypto** (CurrencyTypeID=10): 630 instruments — Bitcoin, Ethereum, etc. ESMA caps retail leverage at 2x. Can be REAL at 1x.
- **Commodity** (CurrencyTypeID=2): 412 instruments — Gold, Oil, Silver, etc. Always CFD. ESMA caps retail at 10x.
- **Forex** (CurrencyTypeID=1): 176 instruments — currency pairs. Always CFD. ESMA caps retail at 30x (majors) / 20x (minors).
- **Indices** (CurrencyTypeID=4): 167 instruments — S&P 500, NASDAQ, DJ30, etc. Always CFD. ESMA caps retail at 20x.

### 2.2 Bitmask System (Legacy)

**What**: The Mask column encodes each instrument's identity as a power-of-2 bitmask for legacy systems.

**Columns/Parameters Involved**: `Mask`

**Rules**:
- USD=1 (2^0), EUR=2 (2^1), GBP=4 (2^2), JPY=8 (2^3), AUD=16 (2^4), CHF=32 (2^5), CAD=64 (2^6), NZD=128 (2^7)
- The ForexType in views like Dictionary.GetCurrency is computed as: `LOG(Mask)/LOG(2) + 1`
- Many newer instruments (stocks, crypto) have Mask=0 or NULL — bitmask is only meaningful for legacy forex instruments
- This system has a hard ceiling of 31 instruments (INT has 31 usable bits) — now exceeded, hence only used for original forex pairs

### 2.3 EEA Stock Exchange Compliance

**What**: Flags whether a stock is listed on a European Economic Area exchange, which triggers MiFID II PRIIPs regulations.

**Columns/Parameters Involved**: `EEAStockExchange`

**Rules**:
- EEAStockExchange=1 for 216 instruments listed on EU/EEA exchanges (London, Frankfurt, Paris, Amsterdam, etc.)
- These instruments require KID (Key Information Document) availability under PRIIPs regulation
- Affects which instruments are available to retail EU clients without professional classification

### 2.4 ISIN and ISO Identification

**What**: International securities identification codes for regulatory reporting and cross-system integration.

**Columns/Parameters Involved**: `ISINCode`, `ISOCode`, `ISOName`

**Rules**:
- ISINCode: 12-character International Securities Identification Number (for stocks, ETFs, bonds). NULL for forex/commodities.
- ISOCode: ISO 4217 currency code number (for forex base currencies). "840"=USD, "978"=EUR, "826"=GBP. NULL for stocks.
- ISOName: ISO 4217 three-letter currency code. Same as Abbreviation for forex, NULL for stocks.

---

## 3. Data Overview

| CurrencyID | Asset Class | Abbreviation | Name | CurrencySymbol | ISIN | Meaning |
|---|---|---|---|---|---|---|
| 0 | Forex | 000 | NULL | - | - | Placeholder/null instrument. Used as default/unknown. |
| 1 | Forex | USD | United States Dollar | $ | - | The US Dollar — the platform's base settlement currency. All PnL ultimately converts to USD. Mask=1 (first bit). |
| 2 | Forex | EUR | Euro | € | - | The Euro — second most traded currency on the platform. Default currency for European users. Mask=2. |
| 3 | Forex | GBP | Pound Sterling | £ | - | British Pound. Default currency for UK users. Mask=4. |
| 1001 | Stocks | AAPL.US | Apple Inc | - | US0378331005 | Apple stock — one of the most traded instruments. EEAStockExchange=0 (US-listed). CurrencyTypeID=5. |
| 100001 | Crypto | BTC | Bitcoin | ₿ | - | Bitcoin — first and most traded cryptocurrency. CurrencyTypeID=10. Available REAL at 1x or CFD at 2x. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | VERIFIED | Primary key identifying the instrument. 0=NULL placeholder, 1-8=major forex currencies, 1000+=stocks, 100000+=crypto. Referenced by Trade.PositionTbl.CurrencyID, Trade.DelayedOrderForOpen.CurrencyID, and virtually all trading tables. |
| 2 | CurrencyTypeID | int | NO | - | VERIFIED | FK to Dictionary.CurrencyType. Asset class: 1=Forex (176), 2=Commodity (412), 4=Indices (167), 5=Stocks (8,632), 6=ETF (652), 10=Crypto (630). Determines trading rules, leverage limits, and settlement eligibility. |
| 3 | Name | varchar(50) | NO | - | VERIFIED | Full instrument name. "United States of America, US Dollar" for forex, company name for stocks, coin name for crypto. Padded with spaces (legacy). |
| 4 | Abbreviation | varchar(20) | NO | - | VERIFIED | Trading symbol / ticker. "USD", "AAPL.US", "BTC", "GOLD". UNIQUE constraint. The primary identifier used in UIs and APIs. |
| 5 | Mask | int | YES | - | VERIFIED | Legacy bitmask value — power of 2 for original forex instruments. Used by Dictionary.GetCurrency/GetCommodity/GetIndices views to compute ForexType. 0 or NULL for newer instruments (stocks, crypto). |
| 6 | EEAStockExchange | bit | NO | (0) | VERIFIED | Whether listed on a European Economic Area stock exchange. 216 instruments flagged. Triggers MiFID II PRIIPs KID requirements. Default=0. |
| 7 | ISINCode | varchar(25) | YES | - | VERIFIED | International Securities Identification Number. 12-character code for stocks/ETFs (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for regulatory reporting and cross-system matching. |
| 8 | CurrencySymbol | nchar(5) | YES | - | VERIFIED | Display symbol for the currency/instrument. "$" for USD, "€" for EUR, "£" for GBP. NULL for stocks and many instruments that use Abbreviation instead. |
| 9 | InterestRateID | int | YES | (NULL) | VERIFIED | FK to Dictionary.InterestRateOld. Links to interest/swap rate configuration for overnight fee calculations. Only applicable to forex/commodity instruments with overnight rollover. NULL for stocks, ETFs, crypto. |
| 10 | ISOCode | varchar(10) | YES | - | VERIFIED | ISO 4217 numeric currency code. "840"=USD, "978"=EUR, "826"=GBP. Used for international financial reporting. NULL for non-currency instruments. |
| 11 | DisplayName | varchar(50) | YES | - | VERIFIED | Alternative display name for UI purposes. Currently NULL for most instruments — the platform uses Name or Abbreviation instead. |
| 12 | ISOName | varchar(10) | YES | - | VERIFIED | ISO 4217 alphabetic currency code. Same as Abbreviation for currencies ("USD", "EUR"). NULL for stocks and non-currency instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Verified |
|---------|---------------|-------------------|----------|
| CurrencyTypeID | Dictionary.CurrencyType | FK (explicit) | Yes — FK_DCUT_DCUR |
| InterestRateID | Dictionary.InterestRateOld | FK (explicit) | Yes — FK_Currency_InterestRateID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Country | DefaultCurrencyID | FK (explicit) | Default trading currency per country |
| Trade.PositionTbl | CurrencyID | Implicit Lookup | Which instrument every position is on |
| Trade.DelayedOrderForOpen | CurrencyID | Implicit Lookup | Pending order instrument |
| Dictionary.GetCurrency | CurrencyID | View | Forex instruments (CurrencyTypeID=1) |
| Dictionary.GetCommodity | CurrencyID | View | Commodity instruments (CurrencyTypeID=2) |
| Dictionary.GetIndices | CurrencyID | View | Index instruments (CurrencyTypeID=3/4) |
| Dictionary.CurrencyTypeSafty | - | View (schema-bound) | CurrencyType stable access |
| Trade.UpdateInstrumentsSymbolFull | CurrencyID | Write | Instrument metadata updates |
| Trade.GetAllInstrumentCategoriesForAPI | CurrencyID | Read | API instrument catalog |
| SalesForce.GetInstruments | CurrencyID | Read | CRM instrument sync |
| History.GetOnePipValueDollarHedge | CurrencyID | Read | PnL/pip calculations |
| Hedge.GetUnrealizedCustomersData | CurrencyID | Read | Hedge exposure |
| 25+ additional procedures | CurrencyID | Read | BackOffice, Billing, Trade, MIMOAlerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Currency
 ├── Dictionary.CurrencyType (FK: CurrencyTypeID)
 └── Dictionary.InterestRateOld (FK: InterestRateID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | FK: Asset class classification |
| Dictionary.InterestRateOld | Table | FK: Overnight interest/swap rate config |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: Default currency per country |
| Trade.PositionTbl | Table | Every position references an instrument |
| Trade.DelayedOrderForOpen | Table | Every pending order references an instrument |
| Dictionary.GetCurrency/GetCommodity/GetIndices | Views | Asset-class filtered instrument lists |
| History.AuditHistory | Table | Audit trail via triggers |
| 25+ stored procedures | Procs | Instrument lookups across all schemas |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| PK_DCUR | CLUSTERED PK | CurrencyID ASC | - | - | PAGE | Active |
| DCUR_ABBR | NC UNIQUE | Abbreviation ASC | - | - | PAGE | Active |
| DCUR_CURRENCYTYPE | NC | CurrencyTypeID ASC | - | - | PAGE | Active |
| DCUR_NAME | NC | Name ASC | - | - | PAGE | Active |

### 7.2 Audit Triggers

| Trigger | Event | Target | Description |
|---------|-------|--------|-------------|
| AuditDelete_Dictionary_Currency | DELETE | History.AuditHistory | Logs old values for every column when an instrument is deleted |
| AuditInsert_Dictionary_Currency | INSERT | History.AuditHistory | Logs new values for every column when an instrument is added |
| AuditUpdate_Dictionary_Currency | UPDATE | History.AuditHistory | Logs old→new value pairs for each changed column per instrument |

All triggers are ASM-generated (Automated Schema Management). They call `Internal.GetUserAndAppName` to capture the user/application performing the change.

### 7.3 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCUR | PRIMARY KEY | Unique instrument identifier |
| DCUR_ABBR | UNIQUE | No duplicate trading symbols |
| FK_DCUT_DCUR | FOREIGN KEY | CurrencyTypeID → Dictionary.CurrencyType |
| FK_Currency_InterestRateID | FOREIGN KEY | InterestRateID → Dictionary.InterestRateOld |
| Def_DictionaryCurrency_EEAStockExchange | DEFAULT | EEAStockExchange defaults to 0 |

---

## 8. Sample Queries

### 8.1 Count instruments by asset class
```sql
SELECT  ct.Name AS AssetClass, COUNT(*) AS InstrumentCount
FROM    [Dictionary].[Currency] c WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] ct WITH (NOLOCK) ON c.CurrencyTypeID = ct.CurrencyTypeID
GROUP BY ct.Name
ORDER BY InstrumentCount DESC;
```

### 8.2 Find instrument by ticker
```sql
SELECT  CurrencyID, Name, Abbreviation, ct.Name AS AssetClass,
        ISINCode, CurrencySymbol, EEAStockExchange
FROM    [Dictionary].[Currency] c WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] ct WITH (NOLOCK) ON c.CurrencyTypeID = ct.CurrencyTypeID
WHERE   c.Abbreviation = 'AAPL.US';
```

### 8.3 List all EEA-listed stocks
```sql
SELECT  CurrencyID, Abbreviation, Name, ISINCode
FROM    [Dictionary].[Currency] WITH (NOLOCK)
WHERE   EEAStockExchange = 1
ORDER BY Abbreviation;
```

### 8.4 Find forex instruments with interest rates
```sql
SELECT  c.CurrencyID, c.Abbreviation, c.CurrencySymbol,
        ir.InterestRateID, ir.Description AS InterestRateDesc
FROM    [Dictionary].[Currency] c WITH (NOLOCK)
LEFT JOIN [Dictionary].[InterestRateOld] ir WITH (NOLOCK) ON c.InterestRateID = ir.InterestRateID
WHERE   c.CurrencyTypeID = 1
ORDER BY c.CurrencyID;
```

### 8.5 Audit trail — recent instrument changes
```sql
SELECT TOP 20 AuditDate, UserName, AppName, ColumnName, OldValue, NewValue, Operation
FROM   [History].[AuditHistory] WITH (NOLOCK)
WHERE  SchemaName = 'Dictionary' AND TableName = 'Currency'
ORDER BY AuditDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Currency.

---

*Generated: 2026-03-13 | Enriched: MCP live data | Quality: 9.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 12 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 25+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Currency | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Currency.sql*
