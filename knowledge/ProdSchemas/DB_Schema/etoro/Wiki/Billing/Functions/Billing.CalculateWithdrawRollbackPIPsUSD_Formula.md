# Billing.CalculateWithdrawRollbackPIPsUSD_Formula

> Pure arithmetic formula that computes the FX spread (PIPs) on a withdrawal rollback amount, using identical logic to CalculateWithdrawPIPsUSD_Formula but applied to the reversed amount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - rollback PIPs amount in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateWithdrawRollbackPIPsUSD_Formula computes the FX spread component (PIPs) for a cashout rollback event - when a previously processed withdrawal is reversed. It applies the same two-branch formula as `Billing.CalculateWithdrawPIPsUSD_Formula` but operates on `@RollbackAmountInCurrency` (the reversed amount) rather than the original withdrawal amount.

This function exists as the formula primitive for `Billing.CalculateWithdrawRollbackPIPsUSD`, which retrieves actual rollback rates and amounts from `Billing.WithdrawToFunding`, `Billing.CurrencySettings`, and `Billing.CashoutRollbackTracking`. The separation allows the formula to be unit-tested independently.

The formula is structurally identical to `CalculateWithdrawPIPsUSD_Formula` - both branches, both division-by-zero protections, and the @IsCurrencyReciprocal flag behave identically. The only difference is the parameter name (@RollbackAmountInCurrency vs @Amount) and semantic context (reversal amount vs original amount).

---

## 2. Business Logic

### 2.1 PIPs Formula (Withdrawal Rollback)

**What**: Computes the spread on the reversed withdrawal amount using the same rate-difference logic as the forward withdrawal formula.

**Columns/Parameters Involved**: `@RollbackAmountInCurrency`, `@BaseExchangeRate`, `@ExchangeRate`, `@IsCurrencyReciprocal`

**Rules**:
- IsCurrencyReciprocal=0 (direct): `((-RollbackAmt / BaseRate) + (RollbackAmt / ExchangeRate)) * BaseRate`
- IsCurrencyReciprocal=1 (reciprocal): `((-RollbackAmt / (1/BaseRate)) + (RollbackAmt / ExchangeRate)) * (1/BaseRate)`
- Both branches use ISNULL(NULLIF(rate, 0), 1) for division-by-zero protection.
- The original withdrawal rates (BaseExchangeRate, ExchangeRate) should be passed - the same rates that were used when the withdrawal was processed - to correctly reverse the spread that was originally captured.

**Diagram**:
```
Withdrawal Rollback:
  Original withdrawal: 200 USD -> EUR at ExchangeRate=1.07, BaseRate=1.08
  Rollback amount: 200 USD (full reversal)

  PIPs on rollback = same formula as forward withdrawal
  = ((-200/1.08) + (200/1.07)) * 1.08
  = (-185.19 + 186.92) * 1.08 = 1.73 * 1.08 = 1.87 USD
  (eToro returns the 1.87 USD spread it originally captured)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RollbackAmountInCurrency | money | NO | - | VERIFIED | The rollback amount in customer currency (the amount being reversed). NULL treated as 0 via ISNULL. From Billing.CashoutRollbackTracking. |
| 2 | @BaseExchangeRate | dtPrice | NO | - | VERIFIED | The interbank mid-market exchange rate from the original withdrawal transaction. NULL treated as 1 via ISNULL+NULLIF. |
| 3 | @ExchangeRate | dtPrice | NO | - | VERIFIED | eToro's customer-facing exchange rate from the original withdrawal. NULL treated as 1 via ISNULL+NULLIF. |
| 4 | @IsCurrencyReciprocal | int | NO | - | VERIFIED | Currency quotation convention: 0=direct (USD per foreign unit), 1=reciprocal (foreign units per USD). Source: Billing.CurrencySettings. Identical semantics to CalculateWithdrawPIPsUSD_Formula. |
| RETURN | money | - | NO | - | VERIFIED | PIPs on the rollback amount in USD. Represents the FX spread component being reversed in the cashout rollback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure calculation - no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CalculateWithdrawRollbackPIPsUSD | (all params) | Caller | Full rollback PIPs function that retrieves rates from Billing.WithdrawToFunding, Billing.CurrencySettings, Billing.CashoutRollbackTracking. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (pure formula function).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CalculateWithdrawRollbackPIPsUSD | Function | Calls this formula with rates from Billing.WithdrawToFunding, Billing.CurrencySettings, Billing.CashoutRollbackTracking. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Formula parity | Note | Formula is identical to CalculateWithdrawPIPsUSD_Formula - only parameter name differs (@RollbackAmountInCurrency vs @Amount). |

---

## 8. Sample Queries

### 8.1 Calculate withdrawal rollback PIPs (direct quote)

```sql
SELECT Billing.CalculateWithdrawRollbackPIPsUSD_Formula(
    200,    -- RollbackAmountInCurrency
    1.0800, -- BaseExchangeRate
    1.0700, -- ExchangeRate
    0       -- IsCurrencyReciprocal = 0 (direct)
) AS RollbackPIPsUSD;
```

### 8.2 Compare forward vs rollback formula (should produce identical results)

```sql
SELECT
    Billing.CalculateWithdrawPIPsUSD_Formula(0, 200, 1.08, 1.07) AS ForwardPIPs,
    Billing.CalculateWithdrawRollbackPIPsUSD_Formula(200, 1.08, 1.07, 0) AS RollbackPIPs;
-- Both should return the same value - formulas are equivalent
```

### 8.3 Reciprocal currency rollback PIPs

```sql
SELECT Billing.CalculateWithdrawRollbackPIPsUSD_Formula(
    150,    -- RollbackAmountInCurrency
    0.9259, -- BaseExchangeRate (reciprocal: EUR/USD)
    0.9174, -- ExchangeRate
    1       -- IsCurrencyReciprocal = 1
) AS RollbackPIPsUSD;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateWithdrawRollbackPIPsUSD_Formula | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateWithdrawRollbackPIPsUSD_Formula.sql*
