# BackOffice.CalculateWithdrawPIPsUSD

> Calculates the USD cost of currency exchange on a customer withdrawal, quantifying the FX conversion loss when USD funds are converted back to the customer's local currency.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns [Value] DECIMAL(16,2) - withdrawal FX cost in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CalculateWithdrawPIPsUSD computes the USD-equivalent FX conversion cost incurred when eToro processes a customer withdrawal in a non-USD currency. Customer accounts are held in USD; when a withdrawal is requested in EUR, GBP, or another local currency, eToro converts USD to that currency at an exchange rate. The difference between converting at the base (reference) rate versus the actual applied rate - expressed in USD - is the FX cost captured by this function.

This function exists to provide consistent FX cost calculation across withdrawal reporting procedures. It is the withdrawal-side counterpart to CalculateDepositPIPsUSD. Both serve the same business need: quantifying the "PIPs in USD" metric used by the BackOffice operations and risk teams to monitor currency conversion profitability and regulatory reporting (PCI-compliant withdrawal data exports).

The function is called via OUTER APPLY in withdrawal reporting procedures (GetProcessedWithdrawPCIVersion, GetPaymentOrders, GetPaymentOrders_Withdraw), receiving the withdrawal's process currency, exchange rates, and amount, and returning the USD cost as a single value. Created November 2021 (OPSE-236) with extension in March 2023 (MIMOPSA-9406) to include additional local currencies in the "local currency" formula branch.

---

## 2. Business Logic

### 2.1 Dual-Formula Withdrawal FX Cost (Local vs Other Currencies)

**What**: The withdrawal FX cost calculation uses two different formula paths based on the withdrawal currency, reflecting how exchange rates are quoted differently for different currency pairs.

**Parameters Involved**: `@ProcessCurrencyID`, `@ExchangeRate`, `@BaseExchangeRate`, `@Amount`

**Rules**:
- **Local Currency Group (ProcessCurrencyID IN (5, 2, 3, 88, 90, 346, 347, 349))**: Uses a direct division formula. These are currencies where eToro quotes the exchange rate as "local currency per USD" (i.e., how many EUR/GBP per 1 USD). Formula: `((-Amount / BaseExchangeRate) + (Amount / ExchangeRate)) * BaseExchangeRate`. This converts the USD amount to local currency at both rates and computes the difference back to USD.
- **Other Currencies**: Uses an inverse formula with 1/BaseExchangeRate, for currencies quoted as "USD per local currency unit." Formula: `((-Amount / (1/BaseExchangeRate)) + (Amount / ExchangeRate)) * (1/BaseExchangeRate)`.
- **NULL protection**: `ISNULL(@Amount, 0)` and `NULLIF(rate, 0)` guards prevent divide-by-zero errors.
- **Currency group extended**: MIMOPSA-9406 (March 2023) added CurrencyIDs 88, 90, 346, 347 (additional local currencies) to the first formula branch.
- **Sign interpretation**: [Value] is positive when the customer receives less USD-equivalent than the base rate would give (eToro retains the spread). Negative values indicate unusual rate scenarios.

**Diagram**:
```
ProcessCurrencyID IN (5, 2, 3, 88, 90, 346, 347, 349)?
            YES                        NO
             |                          |
Local currency formula:       Inverse formula:
((-Amount/BaseExchangeRate)   ((-Amount/(1/BaseExchangeRate))
 + (Amount/ExchangeRate))      + (Amount/ExchangeRate))
 * BaseExchangeRate             * (1/BaseExchangeRate)

          Result: [Value] DECIMAL(16,2) = USD FX cost
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessCurrencyID | INT | NO | - | CODE-BACKED | The currency in which the withdrawal is processed. Determines which formula branch applies. Local currencies (EUR, GBP, etc.) use the direct formula; others use the inverse formula. FK to Dictionary.Currency. Known local currency IDs: 2=?, 3=?, 5=?, 88=?, 90=?, 346=?, 347=?, 349=AED. |
| 2 | @ExchangeRate | dtPrice (decimal(16,8)) | YES | - | CODE-BACKED | The actual exchange rate applied to the withdrawal. NULLIF(...,0) guard prevents division by zero. ISNULL defaults to 1.0 when NULL. |
| 3 | @BaseExchangeRate | dtPrice (decimal(16,8)) | YES | - | CODE-BACKED | The mid-market reference exchange rate at time of withdrawal processing. Used as the "fair" baseline for comparison. NULLIF(...,0) guard applied. |
| 4 | @Amount | MONEY | YES | - | CODE-BACKED | The withdrawal amount in USD (account currency). ISNULL(@Amount, 0) guard applied. Sourced from Billing.WithdrawToFunding.Amount in calling procedures. |
| 5 | [Value] (return) | DECIMAL(16,2) | - | - | CODE-BACKED | The USD cost of the FX conversion on the withdrawal. Represents the spread between reference rate and applied rate, expressed in USD. Exposed as "ConversionCost" or "CalculatePIPsUSD" alias in calling procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessCurrencyID | Dictionary.Currency | Lookup | Currency determines formula branch. 349=AED and specific IDs use local currency formula. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetProcessedWithdrawPCIVersion | OUTER APPLY | Function call | Processed withdrawal PCI report - computes FX cost per withdrawal, aliased as "CalculatePIPsUSD" |
| BackOffice.GetProcessedWithdrawPCIVersion_Old | OUTER APPLY | Function call | Legacy processed withdrawal report - same usage |
| BackOffice.GetPaymentOrders | OUTER APPLY | Function call | Payment orders list - KateM added this in Sept 2023 (MIMOPSA context) |
| BackOffice.GetPaymentOrders_Withdraw | OUTER APPLY | Function call | Withdrawal-specific payment orders - uses result as ConversionCost |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CalculateWithdrawPIPsUSD (inline TVF)
- No table or function dependencies (pure calculation)
- Input values sourced by callers from Billing.WithdrawToFunding
```

### 6.1 Objects This Depends On

No dependencies. Pure arithmetic function with no table access.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetProcessedWithdrawPCIVersion | Stored Procedure | OUTER APPLY - computes withdrawal FX cost per row in processed withdrawals report |
| BackOffice.GetProcessedWithdrawPCIVersion_Old | Stored Procedure | OUTER APPLY - legacy version of the above |
| BackOffice.GetPaymentOrders | Stored Procedure | OUTER APPLY - adds FX cost to payment order details |
| BackOffice.GetPaymentOrders_Withdraw | Stored Procedure | OUTER APPLY - adds FX cost to withdrawal-specific payment order details |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Calculate withdrawal FX cost for a EUR withdrawal
```sql
SELECT Value AS WithdrawFXCostUSD
FROM BackOffice.CalculateWithdrawPIPsUSD(
    4,       -- ProcessCurrencyID: 4=EUR (local currency group)
    1.0850,  -- ExchangeRate: actual rate applied
    1.0920,  -- BaseExchangeRate: mid-market reference
    500.00   -- Amount in USD
)
```

### 8.2 Compare FX cost for local vs non-local currency withdrawals
```sql
SELECT
    eur.Value AS EUR_FXCost,
    other.Value AS OtherCcy_FXCost
FROM BackOffice.CalculateWithdrawPIPsUSD(5, 1.0850, 1.0920, 1000.00) eur
CROSS JOIN BackOffice.CalculateWithdrawPIPsUSD(99, 1.0850, 1.0920, 1000.00) other
-- Shows difference between local-currency and other-currency formula results
```

### 8.3 View FX costs on recent processed withdrawals
```sql
SELECT
    bwtf.WithdrawID,
    bwtf.ProcessCurrencyID,
    bwtf.Amount AS AmountUSD,
    bwtf.ExchangeRate,
    bwtf.BaseExchangeRate,
    fx.Value AS FXCostUSD
FROM Billing.WithdrawToFunding bwtf WITH (NOLOCK)
OUTER APPLY BackOffice.CalculateWithdrawPIPsUSD(
    bwtf.ProcessCurrencyID, bwtf.ExchangeRate, bwtf.BaseExchangeRate, bwtf.Amount
) fx
WHERE bwtf.CashoutStatusID = 3  -- Processed/approved
  AND bwtf.CreationDate >= DATEADD(day, -7, GETDATE())
ORDER BY ABS(fx.Value) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CalculateWithdrawPIPsUSD | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.CalculateWithdrawPIPsUSD.sql*
