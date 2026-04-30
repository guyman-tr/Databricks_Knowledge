# Billing.CalculateDepositPIPsUSD_Formula

> Pure arithmetic formula that computes the FX spread (PIPs) captured by eToro on a deposit currency conversion, as (BaseExchangeRate - ExchangeRate) * Amount in USD.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - PIPs amount in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateDepositPIPsUSD_Formula is the core formula component for measuring eToro's FX spread revenue on deposit currency conversions. When a customer deposits in a non-USD currency, eToro converts it using an ExchangeRate that includes a markup over the BaseExchangeRate (the interbank mid-market rate). This function computes the difference - the PIPs - representing how much eToro captured from the FX spread on that deposit.

This function exists as a pure formula primitive (no table access) so that it can be unit-tested in isolation and reused by `Billing.CalculateDepositPIPsUSD` (the full version that retrieves all inputs from tables). The separation of formula from data retrieval is deliberate - it allows the formula to be verified without needing a database connection.

Note: Several parameters (@FundingTypeID, @ExchangeFee, @CurrencyPrecision) are present in the signature but are not used in the current active formula. The commented-out code shows a previous alternative formula for FundingTypeID=2 that used these parameters. They are preserved in the signature for backwards compatibility.

---

## 2. Business Logic

### 2.1 PIPs Formula (Deposit)

**What**: Measures the FX spread captured on a deposit by comparing base (mid-market) rate against the customer-facing exchange rate.

**Columns/Parameters Involved**: `@BaseExchangeRate`, `@ExchangeRate`, `@Amount`

**Rules**:
- Formula: `PIPs = @BaseExchangeRate * @Amount - ISNULL(@ExchangeRate, 1) * @Amount`
- Simplified: `PIPs = (@BaseExchangeRate - @ExchangeRate) * @Amount`
- If BaseExchangeRate > ExchangeRate: positive PIPs (eToro captures spread - the common case where the customer's currency buys fewer USD at eToro's rate than at mid-market).
- If ExchangeRate is NULL: defaults to 1 (ISNULL safeguard), meaning no FX conversion.
- @FundingTypeID, @ExchangeFee, @CurrencyPrecision are accepted but NOT used in the current formula (legacy parameters from commented-out FundingTypeID=2 branch).

**Diagram**:
```
Customer deposits 100 EUR:
  BaseExchangeRate = 1.0800 (interbank mid-market USD/EUR)
  ExchangeRate     = 1.0720 (eToro's customer-facing rate, lower)
  Amount           = 100 EUR

PIPs = (1.0800 - 1.0720) * 100 = 0.80 USD captured by eToro
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | int | NO | - | CODE-BACKED | Payment method identifier. Present in signature for legacy reasons (used in the commented-out FundingTypeID=2 formula branch) but NOT used in the current active formula. |
| 2 | @ExchangeFee | dtPrice | NO | - | CODE-BACKED | Per-unit exchange fee. Present in signature for the commented-out formula but NOT used in the current implementation. dtPrice is a user-defined decimal type for exchange rate precision. |
| 3 | @CurrencyPrecision | int | NO | - | CODE-BACKED | Decimal precision of the currency (e.g., 2 for USD/EUR, 0 for JPY). Used in the commented-out formula but NOT used in the current implementation. |
| 4 | @Amount | money | NO | - | VERIFIED | The deposit amount in customer currency. The base quantity against which the rate spread is applied. |
| 5 | @ExchangeRate | dtPrice | NO | - | VERIFIED | The actual exchange rate applied to the customer's deposit (eToro's customer-facing rate, including markup). NULL treated as 1 via ISNULL safeguard. |
| 6 | @BaseExchangeRate | dtPrice | NO | - | VERIFIED | The base (interbank/mid-market) exchange rate without markup. The reference rate representing the true market cost. |
| RETURN | money | - | NO | - | VERIFIED | PIPs in USD: the FX spread captured by eToro = (BaseExchangeRate - ExchangeRate) * Amount. Positive = eToro revenue from spread. Negative = eToro subsidized the customer's rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure calculation - no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CalculateDepositPIPsUSD | (all params) | Caller | Full deposit PIPs function that retrieves rates from tables and calls this formula. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (pure formula function).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CalculateDepositPIPsUSD | Function | Calls this formula with rates retrieved from Billing.Deposit, Billing.Funding, and Billing.CurrencySettings. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Legacy params | Note | @FundingTypeID, @ExchangeFee, @CurrencyPrecision are accepted but unused - removing them would break callers. |

---

## 8. Sample Queries

### 8.1 Calculate PIPs for a sample deposit

```sql
SELECT Billing.CalculateDepositPIPsUSD_Formula(
    3,      -- FundingTypeID (unused)
    0,      -- ExchangeFee (unused)
    2,      -- CurrencyPrecision (unused)
    100,    -- Amount in customer currency
    1.0720, -- ExchangeRate (customer-facing)
    1.0800  -- BaseExchangeRate (mid-market)
) AS PIPsUSD;
-- Returns: 0.80 USD (eToro spread on 100 EUR deposit)
```

### 8.2 Test NULL ExchangeRate handling

```sql
SELECT Billing.CalculateDepositPIPsUSD_Formula(0, 0, 2, 500, NULL, 1.08) AS PIPsUSD;
-- ExchangeRate NULL treated as 1: PIPs = (1.08 - 1) * 500 = 40 USD
```

### 8.3 Verify deposit PIPs via the full function for comparison

```sql
-- Use CalculateDepositPIPsUSD (the table-backed version) for real deposits
-- This formula version is typically called internally by that function
SELECT Billing.CalculateDepositPIPsUSD(12345) AS DepositPIPsUSD; -- example deposit ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateDepositPIPsUSD_Formula | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateDepositPIPsUSD_Formula.sql*
