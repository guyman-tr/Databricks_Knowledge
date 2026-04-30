# Dictionary.GetCurrencyType

> Stored procedure returning all asset class types (currency types) ordered by ID from Dictionary.CurrencyType.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: CurrencyTypeID + Name from CurrencyType |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetCurrencyType returns the complete list of asset class types from Dictionary.CurrencyType, ordered by CurrencyTypeID. These 10 types form the fundamental instrument taxonomy that classifies every tradable instrument on the eToro platform — from the original Forex pairs to the newest Crypto assets.

Application services call this procedure to populate asset class dropdowns, validate instrument categorization, and cache the reference data for the trading platform. The CurrencyType table is one of the most heavily referenced lookup tables in the system, with Dictionary.Currency's 10,669 instruments each classified by one of these 10 types.

The procedure returns exactly two columns (CurrencyTypeID and Name) rather than SELECT *, providing a clean, stable API contract that doesn't change when new columns are added to the base table.

---

## 2. Business Logic

### 2.1 Asset Class Taxonomy

**What**: The 10 asset classes that classify every tradable instrument on the platform.

**Columns/Parameters Involved**: `CurrencyTypeID`, `Name`

**Rules**:
- CurrencyTypeID=1 (Forex): Currency pairs — eToro's original asset class
- CurrencyTypeID=2 (Commodity): Physical resources — Gold, Oil, Silver, etc.
- CurrencyTypeID=3 (CFD): Generic CFD contracts (currently empty — indices moved to type 4)
- CurrencyTypeID=4 (Indices): Market indices — S&P 500, NASDAQ, etc.
- CurrencyTypeID=5 (Stocks): Individual equities — largest category by instrument count
- CurrencyTypeID=6 (ETF): Exchange-Traded Funds
- CurrencyTypeID=7 (Bonds): Fixed income instruments
- CurrencyTypeID=8 (TrustFunds): CopyFund/SmartPortfolio strategies
- CurrencyTypeID=9 (Options): Options contracts
- CurrencyTypeID=10 (Crypto): Cryptocurrency assets — newest class

**Diagram**:
```
Dictionary.GetCurrencyType Output (ordered by CurrencyTypeID)
│
│  ID │ Name        │ Role in Platform
│  ───┼─────────────┼──────────────────────────────
│   1 │ Forex       │ Currency pairs (EUR/USD, GBP/JPY)
│   2 │ Commodity   │ Physical resources (Gold, Oil)
│   3 │ CFD         │ Generic CFDs (currently empty)
│   4 │ Indices     │ Market indices (SPX500, NSDQ)
│   5 │ Stocks      │ Equities (AAPL, TSLA, MSFT)
│   6 │ ETF         │ Fund baskets (SPY, QQQ)
│   7 │ Bonds       │ Fixed income (TLT, IEF)
│   8 │ TrustFunds  │ CopyFunds/SmartPortfolios
│   9 │ Options     │ Options contracts
│  10 │ Crypto      │ Cryptocurrency (BTC, ETH)
│
└── Used by: Dictionary.Currency.CurrencyTypeID (10,669 instruments)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure takes no input parameters |
| R1 | CurrencyTypeID | int | NO | - | VERIFIED | Asset class identifier. PK from Dictionary.CurrencyType: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Every instrument in Dictionary.Currency references one of these values. |
| R2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable asset class name. Used in trading UI asset class selectors, instrument configuration screens, and regulatory reporting. Ordered ascending by CurrencyTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (result set) | Dictionary.CurrencyType | SELECT | Full table read with explicit column list, ordered by CurrencyTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | API call | Called by trading services to cache/populate asset class reference data |
| PSConfigurations user | - | EXECUTE permission | Configuration service has execute rights on this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetCurrencyType (procedure)
└── Dictionary.CurrencyType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | SELECT CurrencyTypeID, Name — ordered read of all rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Application services) | External | API-level consumer for asset class reference data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. CurrencyType has a clustered PK on CurrencyTypeID which supports the ORDER BY.

### 7.2 Constraints

None. The procedure explicitly selects CurrencyTypeID and Name (not SELECT *), providing a stable output contract independent of table schema changes.

---

## 8. Sample Queries

### 8.1 Get all asset class types (equivalent to procedure output)
```sql
SELECT  CurrencyTypeID, Name
FROM    Dictionary.CurrencyType WITH (NOLOCK)
ORDER BY CurrencyTypeID
```

### 8.2 Count instruments per asset class
```sql
SELECT  ct.CurrencyTypeID, ct.Name, COUNT(c.CurrencyID) AS InstrumentCount
FROM    Dictionary.CurrencyType ct WITH (NOLOCK)
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyTypeID = ct.CurrencyTypeID
GROUP BY ct.CurrencyTypeID, ct.Name
ORDER BY ct.CurrencyTypeID
```

### 8.3 Find the asset class for a specific instrument
```sql
SELECT  c.CurrencyID, c.Name AS Instrument, ct.Name AS AssetClass
FROM    Dictionary.Currency c WITH (NOLOCK)
JOIN    Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = c.CurrencyTypeID
WHERE   c.Abbreviation = 'BTC'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetCurrencyType | Type: Stored Procedure | Source: etoro/etoro/Dictionary/Stored Procedures/Dictionary.GetCurrencyType.sql*
