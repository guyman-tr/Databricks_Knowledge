# Billing.CalculateWithdrawRollbackPIPsUSD

> Scalar function that computes the exchange spread (PIPs) to reverse for a withdrawal rollback, retrieving rollback-specific exchange data from Billing.CashoutRollbackTracking and delegating to Billing.CalculateWithdrawRollbackPIPsUSD_Formula. Returns DECIMAL(16,2) - the only PIPs function that does not return MONEY.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(16,2) - rollback PIPs in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateWithdrawRollbackPIPsUSD is the **data-fetching wrapper** for the withdrawal rollback PIPs calculation. When a processed withdrawal is reversed (cashout rollback), the PIPs earned on the original conversion must also be reversed. This function retrieves the rollback-specific exchange rates and amount from `Billing.CashoutRollbackTracking` and delegates to `CalculateWithdrawRollbackPIPsUSD_Formula`.

A key structural note: unlike `CalculateDepositRollbackPIPsUSD` (which uses the original deposit's rates with the rollback amount), the withdrawal rollback function uses **the rollback's own exchange rates** (`CRT.BaseExchangeRate`, `CRT.ExchangeRate`) from `Billing.CashoutRollbackTracking`, not the original withdrawal's rates. This suggests that withdrawal rollbacks may apply different/updated exchange rates at the time of reversal, while deposit rollbacks always use the original deposit's rates.

The return type is `DECIMAL(16,2)` - explicitly two decimal places - unlike the deposit PIPs functions which return `MONEY`. This is notable as it enforces cent precision and differs from `CalculateCashoutRollbackPIPsUSD` (which returns DECIMAL(18,6)).

Referenced only by `BI_WithdrawRollback_PIPS_Report`.

---

## 2. Business Logic

### 2.1 Withdrawal Rollback Data Retrieval + Formula Delegation

**What**: Fetches exchange rates from the rollback record and the reciprocal flag from currency settings, then calls the formula function.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `@RollbackID`, Billing.WithdrawToFunding, Billing.CurrencySettings, Billing.CashoutRollbackTracking

**Rules**:
- Joins 3 tables: WithdrawToFunding -> CurrencySettings (on ProcessCurrencyID), LEFT JOIN CashoutRollbackTracking (on @RollbackID).
- Retrieves:
  - @ProcessCurrencyID: from Billing.WithdrawToFunding.ProcessCurrencyID (used only for CurrencySettings join)
  - @IsCurrencyReciprocal: from Billing.CurrencySettings.IsReciprocal (controls formula branch)
  - @BaseExchangeRate: from **Billing.CashoutRollbackTracking.BaseExchangeRate** (rollback-time rate, NOT original withdrawal rate)
  - @ExchangeRate: from **Billing.CashoutRollbackTracking.ExchangeRate** (rollback-time applied rate)
  - @RollbackAmountInCurrency: from Billing.CashoutRollbackTracking.RollbackAmountInCurrency
- LEFT JOIN CashoutRollbackTracking: if @RollbackID does not exist, all CRT values are NULL -> formula receives NULLs -> returns NULL.
- Calls: `[Billing].[CalculateWithdrawRollbackPIPsUSD_Formula](@RollbackAmountInCurrency, @BaseExchangeRate, @ExchangeRate, @IsCurrencyReciprocal)`
- Same formula branches as CalculateWithdrawPIPsUSD_Formula but using rollback amount and rollback-time rates.

**Diagram**:
```
@WithdrawToFundingID + @RollbackID
    |
Billing.WithdrawToFunding (ProcessCurrencyID)
JOIN Billing.CurrencySettings ON ProcessCurrencyID (reads IsReciprocal)
LEFT JOIN Billing.CashoutRollbackTracking ON RollbackID=@RollbackID:
    BaseExchangeRate (rollback-time mid-market)
    ExchangeRate     (rollback-time applied rate)
    RollbackAmountInCurrency
    |
CalculateWithdrawRollbackPIPsUSD_Formula(
    @RollbackAmountInCurrency, @BaseExchangeRate, @ExchangeRate, @IsCurrencyReciprocal
)
    |
= rollback PIPs  [DECIMAL(16,2)]
```

---

## 3. Data Overview

N/A for Scalar Function. See Billing.CalculateWithdrawRollbackPIPsUSD_Formula and Billing.CalculateWithdrawPIPsUSD_Formula for formula branch details.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | VERIFIED | ID of the Billing.WithdrawToFunding record. Used to retrieve ProcessCurrencyID, which is then used to look up IsReciprocal from Billing.CurrencySettings. |
| 2 | @RollbackID | int | NO | - | VERIFIED | ID of the rollback event in Billing.CashoutRollbackTracking. LEFT JOIN - if not found, all rollback values are NULL and function returns NULL. Identifies which rollback's exchange rates and amount to use. |
| RETURN | decimal(16,2) | YES | - | VERIFIED | Exchange spread PIPs reversal in USD for this withdrawal rollback. DECIMAL(16,2) - cent precision, 16 significant digits. NULL if @WithdrawToFundingID or @RollbackID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | Billing.WithdrawToFunding | Lookup (JOIN) | Reads ProcessCurrencyID for CurrencySettings lookup. |
| Billing.WithdrawToFunding.ProcessCurrencyID | Billing.CurrencySettings | Lookup (JOIN) | Reads IsReciprocal to determine formula branch. |
| @RollbackID | Billing.CashoutRollbackTracking | Lookup (LEFT JOIN) | Reads rollback-time BaseExchangeRate, ExchangeRate, and RollbackAmountInCurrency. |
| (all params) | Billing.CalculateWithdrawRollbackPIPsUSD_Formula | Caller | Delegates PIPs calculation to the formula function. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_WithdrawRollback_PIPS_Report | WithdrawToFundingID, RollbackID | Caller | Dedicated withdrawal rollback PIPs reversal BI report. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CalculateWithdrawRollbackPIPsUSD (function)
├── Billing.WithdrawToFunding (table)
├── Billing.CurrencySettings (table)
├── Billing.CashoutRollbackTracking (table)
└── Billing.CalculateWithdrawRollbackPIPsUSD_Formula (function)
    (pure formula - no table deps)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Reads ProcessCurrencyID for CurrencySettings join. |
| Billing.CurrencySettings | Table | Reads IsReciprocal to determine direct vs reciprocal formula branch. |
| Billing.CashoutRollbackTracking | Table | Reads rollback-time exchange rates and rollback amount. |
| Billing.CalculateWithdrawRollbackPIPsUSD_Formula | Function | Performs the actual rollback PIPs calculation. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_WithdrawRollback_PIPS_Report | Stored Procedure | Withdrawal rollback PIPs reversal BI reporting. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Returns DECIMAL(16,2) not MONEY | Design | The only PIPs data-fetching function returning DECIMAL instead of MONEY. Provides explicit 2-decimal cent precision and avoids MONEY's currency-specific rounding. Contrast: CalculateCashoutRollbackPIPsUSD returns DECIMAL(18,6). |
| Rollback rates, not original rates | Design | BaseExchangeRate and ExchangeRate come from CashoutRollbackTracking, not from the original WithdrawToFunding. Withdrawal rollbacks use the rates at rollback time. |
| LEFT JOIN on CashoutRollbackTracking | Behavior | If @RollbackID does not exist in CashoutRollbackTracking, all CRT values are NULL. Formula receives NULL parameters and returns NULL. |
| Two-table PIPs architecture | Design | This function parallels CalculateWithdrawPIPsUSD structurally: same source tables (WithdrawToFunding + CurrencySettings), same IsReciprocal routing, but reads from CashoutRollbackTracking for the rates and amount instead of WithdrawToFunding.BaseExchangeRate / Amount. |

---

## 8. Sample Queries

### 8.1 Calculate rollback PIPs for a specific withdrawal rollback

```sql
SELECT Billing.CalculateWithdrawRollbackPIPsUSD(98765, 123) AS RollbackPIPsUSD;
-- @WithdrawToFundingID=98765, @RollbackID=123
```

### 8.2 Rollback PIPs alongside rollback details

```sql
SELECT
    crt.RollbackID,
    crt.RollbackAmountInCurrency,
    crt.BaseExchangeRate,
    crt.ExchangeRate,
    Billing.CalculateWithdrawRollbackPIPsUSD(wtf.ID, crt.RollbackID) AS RollbackPIPs
FROM Billing.CashoutRollbackTracking crt WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.ID = crt.WithdrawToFundingID
ORDER BY crt.RollbackID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 8.3 Compare withdraw PIPs vs rollback PIPs for same withdrawal

```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    Billing.CalculateWithdrawPIPsUSD(wtf.ID) AS OriginalPIPs,
    Billing.CalculateWithdrawRollbackPIPsUSD(wtf.ID, crt.RollbackID) AS RollbackPIPs
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Billing.CashoutRollbackTracking crt WITH (NOLOCK) ON crt.WithdrawToFundingID = wtf.ID
ORDER BY wtf.ID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateWithdrawRollbackPIPsUSD | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateWithdrawRollbackPIPsUSD.sql*
