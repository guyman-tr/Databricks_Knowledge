# Billing.CurrencySettings

> Currency-to-instrument mapping table used by PIP calculation functions - defines which trading instrument provides the FX rate for each currency, and how to apply that rate (direct or reciprocal) with what decimal precision.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.CurrencySettings` is a reference configuration table that provides the parameters needed to convert non-USD billing amounts into USD PIPs (price increments) for financial reporting and fee calculations. Each row maps a currency (CurrencyID) to the trading instrument that carries its exchange rate against USD (InstrumentID), along with how to read that rate (IsReciprocal) and how many decimal places the currency uses (Precision).

This table exists because different currency pairs quote differently: EUR/USD is quoted as "how many USD per 1 EUR" (direct), but USD/JPY is quoted as "how many JPY per 1 USD" (reciprocal from the EUR's perspective). The `IsReciprocal` flag tells the calculation functions whether to use the rate directly or invert it. The `Precision` field sets the currency-specific number of decimal places for rounding in the PIP formula.

Five functions read this table - all variants of the same PIP calculation pattern for different transaction types: `Billing.CalculateDepositPIPsUSD`, `CalculateDepositRollbackPIPsUSD`, `CalculateCashoutRollbackPIPsUSD`, `CalculateWithdrawPIPsUSD`, `CalculateWithdrawRollbackPIPsUSD`. Each joins on `CurrencyID = BD.CurrencyID` to fetch the precision for the specific deposit/cashout currency.

31 currencies are configured (last updated 2024-05-06), covering major FX pairs, emerging market currencies, and crypto-adjacent instruments.

---

## 2. Business Logic

### 2.1 PIP Calculation Support

**What**: Each currency row provides the three parameters needed to convert that currency's exchange rate into USD PIPs.

**Columns/Parameters Involved**: `CurrencyID`, `InstrumentID`, `IsReciprocal`, `Precision`

**Rules**:
- The PIP calculation functions join on `CurrencyID` to get `Precision`, then pass it to `Billing.CalculateDepositPIPsUSD_Formula` alongside the exchange rate and amount.
- `IsReciprocal = 0` (direct quote): rate is already in USD terms (e.g., EUR/USD rate 1.08 = 1 EUR costs 1.08 USD). Use as-is.
- `IsReciprocal = 1` (reciprocal quote): rate is USD-as-base (e.g., USD/JPY 150 = 1 USD costs 150 JPY). Must invert: actual EUR-equivalent rate = 1/rate.
- Distribution: IsReciprocal=0 (9 rows - EUR, GBP, AUD, CAD, some crypto), IsReciprocal=1 (22 rows - JPY, CHF, CNY, and most other currencies).
- `Precision` ranges: 0 (JPY - no decimal places), 2 (many currencies), 4 (EUR, GBP, AUD, CAD), 5 (crypto and exotic instruments).

**Diagram**:
```
CalculateDepositPIPsUSD(@DepositID)
        |
        v
JOIN Billing.CurrencySettings ON CurrencyID = Deposit.CurrencyID
        |
        v
Get: InstrumentID, IsReciprocal, Precision
        |
        v
Call CalculateDepositPIPsUSD_Formula(
  FundingTypeID, ExchangeFee, Precision, Amount, ExchangeRate, BaseExchangeRate)
        |
        v
Returns: PIP value in USD
```

### 2.2 IsReciprocal Rate Direction

**What**: Controls whether the exchange rate needs to be inverted before use.

**Columns/Parameters Involved**: `IsReciprocal`, `InstrumentID`

**Rules**:
- IsReciprocal=0: EUR, GBP, AUD, CAD (currency is BASE in the pair, quoted per USD) - 9 currencies.
- IsReciprocal=1: JPY, CHF, CNY, NOK, SEK, and most others (USD is BASE) - 22 currencies.
- The linked InstrumentID provides the live exchange rate from the Trade system.

---

## 3. Data Overview

| ID | CurrencyID | Currency | InstrumentID | IsReciprocal | Precision | Meaning |
|----|-----------|----------|-------------|-------------|-----------|---------|
| 1 | 2 | EUR (Euro) | 1 | 0 | 4 | EUR/USD pair, direct quote, 4 decimal places. Rate used directly: 1 EUR = Rate USD. |
| 3 | 4 | JPY (Yen) | 5 | 1 | 2 | USD/JPY pair, reciprocal. Rate inverted: 1 EUR-equiv = 1/Rate USD. JPY uses 2 decimal places. |
| 18 | 79 | - | 79 | 1 | 0 | Currency with 0 decimal places (like JPY). |
| 22 | 83 | - | 83 | 1 | 5 | Crypto or exotic currency with 5 decimal places (highest precision). |
| 25 | 346 | - | 346 | 0 | 5 | CurrencyID=InstrumentID pattern (346) - crypto-linked currency. Direct quote, 5-decimal precision. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. No business significance - internal row identifier. |
| 2 | CurrencyID | int | YES | - | CODE-BACKED | Currency being configured. Implicit FK to Dictionary.Currency. The lookup key used by PIP calculation functions: `JOIN Billing.CurrencySettings ON CurrencyID = BD.CurrencyID`. Covers 31 currencies including EUR (2), GBP (3), JPY (4), AUD (5), CHF (6), CAD (7), and others. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument that provides the exchange rate for this currency. Implicit FK to the Trade instrument table. For major currencies, typically the standard forex pair (e.g., EUR->InstrumentID=1 is EUR/USD). For some currencies, CurrencyID=InstrumentID (e.g., 79, 80, 81 where currency and instrument share the same ID - likely non-USD instruments referenced directly). |
| 4 | IsReciprocal | int | YES | - | CODE-BACKED | Rate direction flag: 0=direct quote (currency is base, e.g., EUR/USD), 1=reciprocal quote (USD is base, e.g., USD/JPY, must invert rate). Used by PIP formula to determine whether to apply rate directly or as 1/rate. 0 for 9 currencies (EUR, GBP, AUD, CAD, and some crypto), 1 for 22 currencies (most others including JPY, CHF, CNY). |
| 5 | Precision | int | YES | - | CODE-BACKED | Decimal places used for this currency in PIP calculations. Determines rounding precision in the PIP formula. Values: 0=JPY-class (no decimal), 2=most standard currencies, 4=major FX pairs (EUR, GBP, AUD, CAD), 5=crypto/exotic instruments. |
| 6 | ModificationDate | datetime | YES | - | CODE-BACKED | Timestamp of last configuration update. All 31 rows show 2024-05-06 - a bulk update/refresh event. Used for change tracking by the admin tool. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Implicit FK | Identifies the currency being configured. |
| InstrumentID | Trade instrument table | Implicit FK | The FX instrument whose live rate is used for conversion. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CalculateDepositPIPsUSD | CurrencyID | READER | Retrieves Precision for deposit PIP calculation. |
| Billing.CalculateDepositRollbackPIPsUSD | CurrencyID | READER | Retrieves Precision for deposit rollback PIP calculation. |
| Billing.CalculateCashoutRollbackPIPsUSD | CurrencyID | READER | Retrieves Precision for cashout rollback PIP calculation. |
| Billing.CalculateWithdrawPIPsUSD | CurrencyID | READER | Retrieves Precision for withdrawal PIP calculation. |
| Billing.CalculateWithdrawRollbackPIPsUSD | CurrencyID | READER | Retrieves Precision for withdrawal rollback PIP calculation. |
| Billing.BI_Cashout_State_Report | CurrencyID | READER | Uses currency settings in cashout state BI reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CalculateDepositPIPsUSD | Function | READER - joins on CurrencyID to get Precision |
| Billing.CalculateDepositRollbackPIPsUSD | Function | READER - joins on CurrencyID to get Precision |
| Billing.CalculateCashoutRollbackPIPsUSD | Function | READER - joins on CurrencyID to get Precision |
| Billing.CalculateWithdrawPIPsUSD | Function | READER - joins on CurrencyID to get Precision |
| Billing.CalculateWithdrawRollbackPIPsUSD | Function | READER - joins on CurrencyID to get Precision |
| Billing.BI_Cashout_State_Report | Stored Procedure | READER - uses in BI reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | ID ASC | - | - | Active |

DICTIONARY filegroup (stored with other lookup/reference tables).

### 7.2 Constraints

None beyond the unnamed primary key.

---

## 8. Sample Queries

### 8.1 View all configured currencies with names

```sql
SELECT cs.ID, cs.CurrencyID, c.Name AS CurrencyName, cs.InstrumentID,
       cs.IsReciprocal, cs.Precision, cs.ModificationDate
FROM [Billing].[CurrencySettings] cs WITH (NOLOCK)
LEFT JOIN [Dictionary].[Currency] c WITH (NOLOCK) ON cs.CurrencyID = c.CurrencyID
ORDER BY cs.CurrencyID;
```

### 8.2 Find currencies without settings (not covered in PIP calculation)

```sql
SELECT d.CurrencyID, d.Name
FROM [Dictionary].[Currency] d WITH (NOLOCK)
WHERE d.CurrencyID NOT IN (
    SELECT CurrencyID FROM [Billing].[CurrencySettings] WITH (NOLOCK)
    WHERE CurrencyID IS NOT NULL
)
ORDER BY d.CurrencyID;
```

### 8.3 View currencies by precision tier

```sql
SELECT cs.Precision, COUNT(*) AS CurrencyCount, STRING_AGG(c.Name, ', ') AS Currencies
FROM [Billing].[CurrencySettings] cs WITH (NOLOCK)
LEFT JOIN [Dictionary].[Currency] c WITH (NOLOCK) ON cs.CurrencyID = c.CurrencyID
GROUP BY cs.Precision
ORDER BY cs.Precision;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CurrencySettings | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CurrencySettings.sql*
