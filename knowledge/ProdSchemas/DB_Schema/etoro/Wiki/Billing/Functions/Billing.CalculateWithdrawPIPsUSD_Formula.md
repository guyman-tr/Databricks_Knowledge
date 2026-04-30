# Billing.CalculateWithdrawPIPsUSD_Formula

> Pure arithmetic formula that computes the FX spread (PIPs) captured by eToro on a withdrawal currency conversion, handling both direct and reciprocal currency quotation conventions via @IsCurrencyReciprocal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - PIPs amount in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateWithdrawPIPsUSD_Formula computes the FX spread revenue (PIPs) captured by eToro when converting a withdrawal amount from USD to the customer's target currency. Unlike the deposit formula (which is a simple rate-difference multiplication), withdrawal PIPs require handling two currency quotation conventions: direct (amount/rate) and reciprocal (amount * rate), controlled by the @IsCurrencyReciprocal flag.

This function exists as a pure calculation primitive called by `Billing.CalculateWithdrawPIPsUSD`, which retrieves rates and amounts from `Billing.WithdrawToFunding` and `Billing.CurrencySettings`. The formula separates the "what to calculate" from the "where to get the data", enabling isolated testing of the spread logic.

The @IsCurrencyReciprocal parameter reflects how the currency is quoted in the system: for most currencies (direct quote, IsCurrencyReciprocal=0), the rate is expressed as USD per foreign unit (e.g., 1.08 USD/EUR). For reciprocal currencies (IsCurrencyReciprocal=1), the rate is expressed as foreign units per USD (e.g., 0.925 EUR/USD).

---

## 2. Business Logic

### 2.1 PIPs Formula - Direct Quote (IsCurrencyReciprocal=0)

**What**: For direct-quoted currencies, computes the spread by dividing the withdrawal amount by both rates and measuring the difference.

**Columns/Parameters Involved**: `@IsCurrencyReciprocal`, `@Amount`, `@BaseExchangeRate`, `@ExchangeRate`

**Rules**:
- Formula: `((-Amount / BaseRate) + (Amount / ExchangeRate)) * BaseRate`
- Expanded: `Amount * (BaseRate/ExchangeRate - 1)`
- Interpretation: how much USD does eToro capture by giving the customer a slightly worse rate (lower ExchangeRate) than mid-market (BaseRate)?
- Positive PIPs when ExchangeRate < BaseRate (customer gets fewer foreign units per USD than at mid-market).
- NULLIF safeguards prevent division by zero on both rates.

### 2.2 PIPs Formula - Reciprocal Quote (IsCurrencyReciprocal=1)

**What**: For reciprocal-quoted currencies, applies the reciprocal convention to the rate arithmetic.

**Columns/Parameters Involved**: `@IsCurrencyReciprocal`, `@Amount`, `@BaseExchangeRate`, `@ExchangeRate`

**Rules**:
- Formula: `((-Amount / (1/BaseRate)) + (Amount / ExchangeRate)) * (1/BaseRate)`
- Simplified: `((-Amount * BaseRate) + (Amount / ExchangeRate)) / BaseRate`
- Reciprocal currencies have rates quoted as "foreign units per USD" - the formula inverts the base rate to convert between the two conventions before computing the spread.

**Diagram**:
```
Direct Quote (IsCurrencyReciprocal=0) - e.g., EUR withdrawal:
  Amount = 100 USD, BaseRate = 1.08, ExchangeRate = 1.07 (customer gets less EUR)
  PIPs = ((-100/1.08) + (100/1.07)) * 1.08
       = (-92.59 + 93.46) * 1.08 = 0.87 * 1.08 = 0.94 USD

Reciprocal Quote (IsCurrencyReciprocal=1) - e.g., JPY withdrawal:
  Rates expressed as JPY/USD. Different arithmetic path for same economic meaning.
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsCurrencyReciprocal | int | NO | - | VERIFIED | Controls which formula branch executes. 0=direct quote (rate = USD per foreign unit, e.g., 1.08 USD/EUR); 1=reciprocal quote (rate = foreign units per USD, e.g., 0.925 EUR/USD). Source: Billing.CurrencySettings. |
| 2 | @Amount | money | NO | - | VERIFIED | The withdrawal amount in USD. The notional base for the PIPs calculation. NULL treated as 0 via ISNULL. |
| 3 | @BaseExchangeRate | dtPrice | NO | - | VERIFIED | The interbank mid-market exchange rate without eToro's markup. Reference rate representing the true market cost. NULL treated as 1 via ISNULL+NULLIF (division-by-zero protection). |
| 4 | @ExchangeRate | dtPrice | NO | - | VERIFIED | eToro's customer-facing exchange rate (includes markup/spread). NULL treated as 1 via ISNULL+NULLIF. The difference between this and @BaseExchangeRate is the source of PIPs. |
| RETURN | money | - | NO | - | VERIFIED | PIPs in USD captured by eToro on this withdrawal's FX conversion. Positive = eToro earned spread. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure calculation - no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CalculateWithdrawPIPsUSD | (all params) | Caller | Full withdrawal PIPs function that retrieves rates from Billing.WithdrawToFunding and Billing.CurrencySettings. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (pure formula function).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CalculateWithdrawPIPsUSD | Function | Calls this formula with rates from Billing.WithdrawToFunding and Billing.CurrencySettings. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Divide-by-zero protection | Note | Both @BaseExchangeRate and @ExchangeRate use ISNULL(NULLIF(rate, 0), 1) to prevent division by zero. |

---

## 8. Sample Queries

### 8.1 Calculate withdrawal PIPs for direct-quoted currency

```sql
SELECT Billing.CalculateWithdrawPIPsUSD_Formula(
    0,      -- IsCurrencyReciprocal = 0 (direct quote)
    100,    -- Amount USD
    1.0800, -- BaseExchangeRate (mid-market)
    1.0700  -- ExchangeRate (customer-facing, worse for customer)
) AS WithdrawPIPsUSD;
```

### 8.2 Calculate withdrawal PIPs for reciprocal-quoted currency

```sql
SELECT Billing.CalculateWithdrawPIPsUSD_Formula(
    1,      -- IsCurrencyReciprocal = 1 (reciprocal quote)
    100,    -- Amount USD
    0.9259, -- BaseExchangeRate (EUR/USD, reciprocal)
    0.9174  -- ExchangeRate (worse for customer)
) AS WithdrawPIPsUSD;
```

### 8.3 Test NULL rate handling

```sql
SELECT Billing.CalculateWithdrawPIPsUSD_Formula(0, 100, NULL, NULL) AS PIPs;
-- Both NULL -> both default to 1: PIPs = ((-100/1) + (100/1)) * 1 = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateWithdrawPIPsUSD_Formula | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateWithdrawPIPsUSD_Formula.sql*
