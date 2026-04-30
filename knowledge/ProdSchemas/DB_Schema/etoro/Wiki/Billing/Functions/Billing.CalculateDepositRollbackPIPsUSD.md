# Billing.CalculateDepositRollbackPIPsUSD

> Scalar function that computes the exchange spread (PIPs) to reverse when a deposit is rolled back, retrieving rollback-specific exchange data from Billing.DepositRollbackTracking and delegating to Billing.CalculateDepositRollbackPIPsUSD_Formula.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - rollback PIPs in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateDepositRollbackPIPsUSD is the **data-fetching wrapper** for the deposit rollback PIPs calculation. When a deposit is reversed (chargeback, refund, or regulatory reversal), the original PIPs revenue captured on that deposit must also be reversed. This function retrieves the rollback-specific financial data from `Billing.DepositRollbackTracking` and delegates to `CalculateDepositRollbackPIPsUSD_Formula` for the calculation.

The key difference from `CalculateDepositPIPsUSD` is that rollback uses the **rollback amount** (from DepositRollbackTracking.RollbackAmountInCurrency, taken as ABS) rather than the original deposit amount, and uses the **rollback's exchange fee** (from DRT.ExchangeFee) rather than the deposit's. This is because a partial rollback reverses only a fraction of the original deposit's PIPs.

Referenced in two BI contexts:
- **BI_DepositRollback_PIPS_Report**: Dedicated PIPs reversal report for rollback operations
- **BI_Deposit_State_Report**: Full deposit lifecycle report that tracks both forward and reversal PIPs

---

## 2. Business Logic

### 2.1 Rollback Data Retrieval + Formula Delegation

**What**: Fetches rollback exchange rates and amount from the deposit and rollback tracking records, then calls the formula function.

**Columns/Parameters Involved**: `@DepositID`, `@RollbackID`, Billing.Deposit, Billing.DepositRollbackTracking, Billing.CurrencySettings, Dictionary.FundingType

**Rules**:
- Joins 5 tables: Deposit -> Funding -> FundingType -> CurrencySettings + DepositRollbackTracking (filtered by both @DepositID and @RollbackID).
- Retrieves:
  - @FundingTypeID: from Dictionary.FundingType (legacy param - unused in formula)
  - @BaseExchangeRate: from Billing.Deposit.BaseExchangeRate (original deposit mid-market rate)
  - @ExchangeRate: from Billing.Deposit.ExchangeRate (original deposit applied rate)
  - @ExchangeFee: from **Billing.DepositRollbackTracking.ExchangeFee** (rollback's fee, NOT deposit's fee)
  - @CurrencyID: from Billing.Deposit.CurrencyID (for CurrencySettings join)
  - @CurrencyPrecision: from Billing.CurrencySettings.Precision (legacy param - unused in formula)
  - @RollbackAmountInCurrency: ABS(Billing.DepositRollbackTracking.RollbackAmountInCurrency) - absolute value of the rollback amount
- Calls: `[Billing].[CalculateDepositRollbackPIPsUSD_Formula](@FundingTypeID, @ExchangeRate, @BaseExchangeRate, @ExchangeFee, @CurrencyPrecision, @RollbackAmountInCurrency)`
- Effective formula: `ROUND((BaseExchangeRate - ExchangeRate) * RollbackAmountInCurrency, 2)`
- `@OfflinePayment INT = 2` declared but never used (same legacy dead code as CalculateDepositPIPsUSD).

**Diagram**:
```
@DepositID + @RollbackID
    |
Billing.Deposit -> Billing.Funding -> Dictionary.FundingType (FundingTypeID [legacy])
Billing.Deposit -> Billing.CurrencySettings (Precision [legacy])
Billing.Deposit (BaseExchangeRate, ExchangeRate, CurrencyID)
Billing.DepositRollbackTracking (ExchangeFee, RollbackAmountInCurrency -> ABS())
    |
CalculateDepositRollbackPIPsUSD_Formula(
    @FundingTypeID[legacy], @ExchangeRate, @BaseExchangeRate,
    @ExchangeFee[legacy], @CurrencyPrecision[legacy], @RollbackAmountInCurrency
)
    |
= ROUND((BaseExchangeRate - ExchangeRate) * ABS(RollbackAmountInCurrency), 2)  [MONEY]
```

---

## 3. Data Overview

N/A for Scalar Function. See Billing.CalculateDepositRollbackPIPsUSD_Formula for formula details.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | int | NO | - | VERIFIED | ID of the original deposit being rolled back. Used to retrieve the deposit's exchange rates (BaseExchangeRate, ExchangeRate) and join to Billing.DepositRollbackTracking. |
| 2 | @RollbackID | int | NO | - | VERIFIED | ID of the specific rollback event in Billing.DepositRollbackTracking. Identifies which rollback record to use for ExchangeFee and RollbackAmountInCurrency (supports partial rollbacks where multiple rollback events exist for one deposit). |
| RETURN | money | YES | - | VERIFIED | PIPs reversal amount in USD. Formula: ROUND((BaseExchangeRate - ExchangeRate) * ABS(RollbackAmountInCurrency), 2). Positive result = PIPs to reverse. NULL if @DepositID or @RollbackID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | Lookup (JOIN) | Reads BaseExchangeRate, ExchangeRate, CurrencyID. |
| Billing.Deposit.FundingID | Billing.Funding | Lookup (JOIN) | Navigates to get FundingTypeID (legacy param). |
| Billing.Funding.FundingTypeID | Dictionary.FundingType | Lookup (JOIN) | Resolves FundingTypeID (legacy param, unused in formula). |
| Billing.Deposit.CurrencyID | Billing.CurrencySettings | Lookup (JOIN) | Reads Precision (legacy param, unused in formula). |
| @DepositID + @RollbackID | Billing.DepositRollbackTracking | Lookup (JOIN) | Reads rollback ExchangeFee and RollbackAmountInCurrency. |
| (all params) | Billing.CalculateDepositRollbackPIPsUSD_Formula | Caller | Delegates PIPs calculation to the formula function. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_DepositRollback_PIPS_Report | DepositID, RollbackID | Caller | Dedicated rollback PIPs reversal BI report. |
| Billing.BI_Deposit_State_Report | DepositID, RollbackID | Caller | Full deposit lifecycle BI report (includes rollback PIPs column). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CalculateDepositRollbackPIPsUSD (function)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Billing.CurrencySettings (table)
├── Billing.DepositRollbackTracking (table)
└── Billing.CalculateDepositRollbackPIPsUSD_Formula (function)
    (pure formula - no table deps)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Reads original deposit exchange rates and currency. |
| Billing.Funding | Table | Navigation to FundingType (legacy). |
| Dictionary.FundingType | Table | Resolves FundingTypeID (legacy, unused in formula). |
| Billing.CurrencySettings | Table | Reads Precision (legacy, unused in formula). |
| Billing.DepositRollbackTracking | Table | Reads rollback-specific ExchangeFee and RollbackAmountInCurrency. |
| Billing.CalculateDepositRollbackPIPsUSD_Formula | Function | Performs the actual rollback PIPs calculation. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_DepositRollback_PIPS_Report | Stored Procedure | Rollback PIPs reversal BI reporting. |
| Billing.BI_Deposit_State_Report | Stored Procedure | Full deposit state BI report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| ABS() on rollback amount | Logic | `ABS(DRT.RollbackAmountInCurrency)` - rollback amounts may be stored as negative values. ABS ensures the PIPs calculation always works on a positive quantity. |
| ExchangeFee from DRT, not Deposit | Design | The rollback's ExchangeFee comes from DepositRollbackTracking, not Billing.Deposit. Rollback fees may differ from the original deposit fee. |
| Legacy unused params | Design | @FundingTypeID, @ExchangeFee, @CurrencyPrecision passed to formula but unused in current formula (see CalculateDepositRollbackPIPsUSD_Formula for details). |
| @OfflinePayment unused | Note | Same dead-code legacy variable as in CalculateDepositPIPsUSD. |
| ROUND vs MONEY | Design | The formula applies ROUND(..., 2) but this function returns MONEY (which truncates to 4 decimal places anyway). The explicit ROUND in the formula ensures 2-decimal cent precision. |

---

## 8. Sample Queries

### 8.1 Calculate rollback PIPs for a specific rollback event

```sql
SELECT Billing.CalculateDepositRollbackPIPsUSD(123456, 789) AS RollbackPIPsUSD;
-- @DepositID=123456, @RollbackID=789
```

### 8.2 Rollback PIPs alongside rollback details

```sql
SELECT
    drt.DepositID,
    drt.RollbackID,
    ABS(drt.RollbackAmountInCurrency) AS RollbackAmount,
    Billing.CalculateDepositRollbackPIPsUSD(drt.DepositID, drt.RollbackID) AS RollbackPIPs
FROM Billing.DepositRollbackTracking drt WITH (NOLOCK)
ORDER BY drt.RollbackID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 8.3 Compare original deposit PIPs vs rollback PIPs

```sql
SELECT
    d.DepositID,
    Billing.CalculateDepositPIPsUSD(d.DepositID) AS OriginalPIPs,
    Billing.CalculateDepositRollbackPIPsUSD(d.DepositID, drt.RollbackID) AS RollbackPIPs
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.DepositRollbackTracking drt WITH (NOLOCK) ON drt.DepositID = d.DepositID
WHERE d.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateDepositRollbackPIPsUSD | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateDepositRollbackPIPsUSD.sql*
