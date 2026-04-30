# Billing.GetAllCurrencies

> Returns the list of currencies/instruments from the master instrument registry filtered by asset class type, used by billing to enumerate available currencies for deposit and withdrawal flows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CurrencyID (instrument/currency identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAllCurrencies` is a thin read-only wrapper over `Dictionary.Currency` that returns the subset of instruments (currencies/assets) belonging to a specific asset class (CurrencyType). Despite its name suggesting a fixed list of fiat currencies, it is a parameterized query over the platform's universal instrument registry, which holds 10,669 rows spanning forex pairs, stocks, ETFs, crypto, commodities, and indices.

In the billing context this procedure is used to populate currency selection lists for payment operations - for example, presenting supported transaction currencies to upstream systems or UI components. The default parameter (`@CurrencyTypeID = 1`, Forex) returns all 176 forex instruments/currency pairs, which includes individual fiat currencies (USD, EUR, GBP, JPY, AUD, CHF, etc.) as well as forex cross pairs.

The procedure was introduced in January 2022 by Inna Azimov. It has no callers within the current SSDT repository, suggesting it is consumed directly by application services or APIs outside the DB repo.

---

## 2. Business Logic

### 2.1 Asset Class Filtering via CurrencyTypeID

**What**: Filters the instrument registry by asset class, enabling callers to request only the category of instruments relevant to their context.

**Columns/Parameters Involved**: `@CurrencyTypeID`, `Dictionary.Currency.CurrencyTypeID`

**Rules**:
- Default value `1` (Forex) returns 176 instruments including individual fiat currencies and currency pairs
- Callers can override with any valid CurrencyTypeID to retrieve instruments from another asset class
- Passing `@CurrencyTypeID = 1` is the primary billing use case - fiat currencies for payment processing

**Asset class values (from Dictionary.Currency):**
```
CurrencyTypeID=1  -> Forex        (176 rows): individual fiat currencies + currency pairs
CurrencyTypeID=2  -> Commodity    (412 rows): Gold, Oil, Silver, etc.
CurrencyTypeID=4  -> Indices      (167 rows): S&P 500, NASDAQ, DJ30, etc.
CurrencyTypeID=5  -> Stocks       (8,632 rows): individual company shares
CurrencyTypeID=6  -> ETF          (652 rows): exchange-traded funds
CurrencyTypeID=10 -> Crypto       (630 rows): Bitcoin, Ethereum, etc.
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyTypeID | INT | - | 1 | CODE-BACKED | Asset class filter applied to Dictionary.Currency. 1=Forex (default, returns fiat currencies and pairs for billing use). See asset class values in Section 2.1. |

**Return Columns** (from SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | INT | NO | - | VERIFIED | Unique identifier for the currency/instrument. FK to Dictionary.Currency.CurrencyID. Referenced by virtually all billing and trading tables as the instrument/currency key (e.g., Billing.Deposit, Billing.Cashout, Trade.PositionTbl). |
| 2 | Name | NVARCHAR | NO | - | VERIFIED | Full descriptive name of the currency or instrument (e.g., "United States of America, US Dollar", "European Economic and Monetary Union (EMU), Euro"). Sourced from Dictionary.Currency. |
| 3 | Abbreviation | VARCHAR | NO | - | VERIFIED | Short ticker/ISO code for the currency (e.g., "USD", "EUR", "GBP", "JPY"). Used in UI labels, reports, and API responses to display the human-readable currency code. |
| 4 | CurrencySymbol | NCHAR | YES | - | VERIFIED | Typographic symbol for the currency (e.g., "$", "EUR", "GBP", "JPY"). May be NULL for instruments without a standard symbol. Used for display formatting in payment UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CurrencyTypeID filter | Dictionary.Currency | Lookup | Reads from the universal instrument registry, filtering by CurrencyTypeID. Returns CurrencyID, Name, Abbreviation, CurrencySymbol for matching instruments. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in the SSDT repository; consumed by application services outside the repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAllCurrencies (procedure)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FROM clause with WHERE CurrencyTypeID = @CurrencyTypeID. Returns CurrencyID, Name, Abbreviation, CurrencySymbol. |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Consumed externally by application services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all fiat currencies (default - Forex asset class)
```sql
EXEC Billing.GetAllCurrencies
-- or equivalently:
EXEC Billing.GetAllCurrencies @CurrencyTypeID = 1
```

### 8.2 Get all crypto assets available in billing
```sql
EXEC Billing.GetAllCurrencies @CurrencyTypeID = 10
-- Returns 630 crypto instruments (Bitcoin, Ethereum, etc.)
```

### 8.3 Direct query of underlying data (bypasses SP, allows additional filtering)
```sql
SELECT c.CurrencyID, c.Name, c.Abbreviation, c.CurrencySymbol
FROM Dictionary.Currency c WITH (NOLOCK)
WHERE c.CurrencyTypeID = 1
  AND c.CurrencyID > 0  -- exclude NULL/special rows (CurrencyID=0 is a NULL placeholder)
ORDER BY c.Abbreviation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED (return cols), 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAllCurrencies | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAllCurrencies.sql*
