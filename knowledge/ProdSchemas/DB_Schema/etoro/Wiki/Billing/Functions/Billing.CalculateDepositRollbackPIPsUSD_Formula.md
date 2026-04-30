# Billing.CalculateDepositRollbackPIPsUSD_Formula

> Pure arithmetic formula that computes the FX spread (PIPs) on a deposit rollback amount, as Round((BaseExchangeRate - ExchangeRate) * RollbackAmountInCurrency, 2) in USD.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - PIPs amount in USD for the rollback |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateDepositRollbackPIPsUSD_Formula computes the FX spread component for a deposit rollback event (chargeback, refund, or reversal). When eToro reverses a deposit, it must also account for the FX spread that was originally captured - this function calculates the PIPs on the rollback amount using the same rate comparison as the deposit formula but applied to the amount being reversed.

This formula function exists as a pure primitive (no table access) called by `Billing.CalculateDepositRollbackPIPsUSD`, which retrieves the actual rates and amounts from `Billing.DepositRollbackTracking`, `Billing.Deposit`, `Billing.Funding`, and `Billing.CurrencySettings`. The result is rounded to 2 decimal places (unlike the deposit formula which does not round), matching financial precision requirements for reversal accounting.

Parameters @FundingTypeID, @ExchangeFee, and @CurrencyPrecision are accepted but unused in the current formula (legacy signature, preserved for backwards compatibility).

---

## 2. Business Logic

### 2.1 PIPs Formula (Deposit Rollback)

**What**: Same rate-spread calculation as the deposit formula, applied to the rollback amount, with rounding to 2dp.

**Columns/Parameters Involved**: `@BaseExchangeRate`, `@ExchangeRate`, `@RollbackAmountInCurrency`

**Rules**:
- Formula: `PIPs = ROUND(@BaseExchangeRate * @RollbackAmountInCurrency - ISNULL(@ExchangeRate, 1) * @RollbackAmountInCurrency, 2)`
- Simplified: `PIPs = ROUND((@BaseExchangeRate - @ExchangeRate) * @RollbackAmountInCurrency, 2)`
- The ROUND(..., 2) distinguishes this from `CalculateDepositPIPsUSD_Formula` (which does not round).
- @RollbackAmountInCurrency is the amount being reversed (may be less than the full deposit for partial chargebacks/refunds).
- NULL @ExchangeRate defaults to 1 via ISNULL.

**Diagram**:
```
Chargeback: 80 EUR reversed (original deposit was 100 EUR):
  BaseExchangeRate     = 1.0800 (original mid-market rate)
  ExchangeRate         = 1.0720 (original customer-facing rate)
  RollbackAmountInCurrency = 80 EUR

PIPs = ROUND((1.0800 - 1.0720) * 80, 2) = ROUND(0.64, 2) = 0.64 USD
(eToro must reverse 0.64 USD of the spread originally captured)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | int | NO | - | CODE-BACKED | Payment method identifier. Present in signature for legacy compatibility but NOT used in the current formula. |
| 2 | @ExchangeRate | dtPrice | NO | - | VERIFIED | Customer-facing exchange rate (with eToro's markup) from the original deposit transaction. NULL treated as 1 via ISNULL. |
| 3 | @BaseExchangeRate | dtPrice | NO | - | VERIFIED | Interbank/mid-market rate from the original deposit transaction. Reference rate for spread calculation. |
| 4 | @ExchangeFee | dtPrice | NO | - | CODE-BACKED | Per-unit exchange fee. Present in signature but NOT used in the current formula. |
| 5 | @CurrencyPrecision | int | NO | - | CODE-BACKED | Currency decimal precision. Present in signature but NOT used in the current formula. |
| 6 | @RollbackAmountInCurrency | money | NO | - | VERIFIED | The amount being reversed in the customer's currency. For full chargebacks this equals the original deposit amount; for partial reversal it is a subset. |
| RETURN | money | - | NO | - | VERIFIED | PIPs on the rollback amount in USD, rounded to 2 decimal places. Represents the FX spread component of the reversal: positive = eToro reclaims previously captured spread. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure calculation - no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CalculateDepositRollbackPIPsUSD | (all params) | Caller | Full rollback PIPs function that retrieves rates from tables and calls this formula. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (pure formula function).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CalculateDepositRollbackPIPsUSD | Function | Calls this formula with rates from Billing.DepositRollbackTracking, Billing.Deposit, Billing.Funding, Billing.CurrencySettings. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Rounding | Note | Rounds to 2 decimal places unlike `CalculateDepositPIPsUSD_Formula`. This is intentional for reversal accounting precision. |

---

## 8. Sample Queries

### 8.1 Calculate rollback PIPs for a sample reversal

```sql
SELECT Billing.CalculateDepositRollbackPIPsUSD_Formula(
    3,      -- FundingTypeID (unused)
    1.0720, -- ExchangeRate
    1.0800, -- BaseExchangeRate
    0,      -- ExchangeFee (unused)
    2,      -- CurrencyPrecision (unused)
    80      -- RollbackAmountInCurrency (EUR)
) AS RollbackPIPsUSD;
-- Returns: 0.64 USD
```

### 8.2 Compare deposit vs rollback PIPs formula behavior

```sql
-- Deposit formula (no rounding)
SELECT Billing.CalculateDepositPIPsUSD_Formula(0, 0, 2, 100, 1.0720, 1.0800) AS DepositPIPs,
-- Rollback formula (with rounding)
       Billing.CalculateDepositRollbackPIPsUSD_Formula(0, 1.0720, 1.0800, 0, 2, 80) AS RollbackPIPs;
```

### 8.3 NULL exchange rate handling

```sql
SELECT Billing.CalculateDepositRollbackPIPsUSD_Formula(0, NULL, 1.08, 0, 2, 100) AS PIPs;
-- ExchangeRate NULL -> 1: PIPs = ROUND((1.08-1)*100, 2) = 8.00 USD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateDepositRollbackPIPsUSD_Formula | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateDepositRollbackPIPsUSD_Formula.sql*
