# Billing.CalculateDepositPIPsUSD

> Scalar function that computes the exchange fee revenue (PIPs in USD) for a deposit by retrieving exchange rate and amount data from Billing.Deposit/Funding and delegating to Billing.CalculateDepositPIPsUSD_Formula, returning the result as MONEY.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - PIPs/exchange spread revenue in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CalculateDepositPIPsUSD is the **data-fetching wrapper** in the deposit PIPs calculation chain. It accepts a single DepositID, retrieves all financial data needed for the PIPs formula (exchange rates, amount, currency precision), and delegates to `Billing.CalculateDepositPIPsUSD_Formula` for the actual math.

The two-function split separates concerns: this function owns data retrieval (which tables to join, which columns to read), while the Formula function owns the pure calculation logic. This allows reports to test the formula independently and simplifies unit testing of the math.

The PIPs represent eToro's spread revenue captured on the currency conversion during deposit processing. When a customer deposits in a non-USD currency, the difference between the base (mid-market) exchange rate and the actual applied exchange rate generates PIPs. A zero PIPs result indicates the deposit used a 1:1 rate (no currency conversion) or rates were identical.

Referenced in four reporting/query contexts:
- **BI_Deposit_PIPS_Report**: Dedicated PIPs revenue report for deposit operations
- **BI_Deposit_State_Report**: Full deposit lifecycle BI report (includes PIPs as one metric)
- **GetMoneyInTransactionsByCID**: Customer money-in history query
- **UserMoneyInTransactionsGet**: User-facing transaction history query

---

## 2. Business Logic

### 2.1 Deposit Data Retrieval + Formula Delegation

**What**: Fetches exchange rates, amount, and currency precision for a deposit, then calls the formula function.

**Columns/Parameters Involved**: `@DepositID`, Billing.Deposit, Billing.Funding, Dictionary.FundingType, Billing.CurrencySettings

**Rules**:
- Retrieves from 4-table JOIN (Deposit -> Funding -> FundingType, Deposit -> CurrencySettings):
  - @FundingTypeID: from Dictionary.FundingType (for Formula, but unused in current formula - legacy param)
  - @BaseExchangeRate: from Billing.Deposit.BaseExchangeRate (mid-market rate at deposit time)
  - @ExchangeRate: from Billing.Deposit.ExchangeRate (actual applied rate)
  - @ExchangeFee: from Billing.Deposit.ExchangeFee (for Formula, but unused in current formula - legacy param)
  - @Amount: from Billing.Deposit.Amount (deposit amount in non-USD currency)
  - @CurrencyID: from Billing.Deposit.CurrencyID (deposit currency)
  - @CurrencyPrecision: from Billing.CurrencySettings.Precision (for Formula, but unused - legacy param)
- Calls: `[Billing].[CalculateDepositPIPsUSD_Formula](@FundingTypeID, @ExchangeFee, @CurrencyPrecision, @Amount, @ExchangeRate, @BaseExchangeRate)`
- Effective formula: `(BaseExchangeRate - ExchangeRate) * Amount`
- `@OfflinePayment INT = 2` is declared but never used (legacy variable from a prior branching logic that was removed).
- Returns NULL if @DepositID does not exist (no JOIN result -> @PIPSInUSD remains unset -> returns NULL).

**Diagram**:
```
@DepositID
    |
Billing.Deposit (BaseExchangeRate, ExchangeRate, ExchangeFee, Amount, CurrencyID)
JOIN Billing.Funding (FundingID -> FundingTypeID via DFT)
JOIN Dictionary.FundingType (FundingTypeID)
JOIN Billing.CurrencySettings (Precision for CurrencyID)
    |
CalculateDepositPIPsUSD_Formula(
    @FundingTypeID[legacy], @ExchangeFee[legacy], @CurrencyPrecision[legacy],
    @Amount, @ExchangeRate, @BaseExchangeRate
)
    |
= (BaseExchangeRate - ExchangeRate) * Amount  [MONEY]
```

---

## 3. Data Overview

N/A for Scalar Function. See Billing.CalculateDepositPIPsUSD_Formula for formula details.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | int | NO | - | VERIFIED | Deposit record ID from Billing.Deposit.DepositID. Uniquely identifies the deposit to calculate PIPs for. Drives the 4-table JOIN to retrieve all financial context. |
| RETURN | money | YES | - | VERIFIED | Exchange spread PIPs in USD for the deposit. Formula: (BaseExchangeRate - ExchangeRate) * Amount. Positive = eToro earned PIPs on this deposit. Zero = no currency conversion or mid-market rate was applied. NULL if @DepositID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | Lookup (JOIN) | Reads BaseExchangeRate, ExchangeRate, ExchangeFee, Amount, CurrencyID for the deposit. |
| Billing.Deposit.FundingID | Billing.Funding | Lookup (JOIN) | Navigates from Deposit to Funding to get FundingTypeID. |
| Billing.Funding.FundingTypeID | Dictionary.FundingType | Lookup (JOIN) | Resolves FundingTypeID for formula param (legacy, unused in formula). |
| Billing.Deposit.CurrencyID | Billing.CurrencySettings | Lookup (JOIN) | Reads currency Precision for formula param (legacy, unused in formula). |
| (all params) | Billing.CalculateDepositPIPsUSD_Formula | Caller | Delegates calculation to the formula function with all retrieved values. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_PIPS_Report | DepositID | Caller | Dedicated PIPs revenue report for deposit operations. |
| Billing.BI_Deposit_State_Report | DepositID | Caller | Full deposit lifecycle BI report includes PIPs column. |
| Billing.GetMoneyInTransactionsByCID | DepositID | Caller | Customer money-in transaction history query. |
| Billing.UserMoneyInTransactionsGet | DepositID | Caller | User-facing money-in transaction history. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CalculateDepositPIPsUSD (function)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Billing.CurrencySettings (table)
└── Billing.CalculateDepositPIPsUSD_Formula (function)
    (pure formula - no table deps)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source - exchange rates, amount, currency. |
| Billing.Funding | Table | Navigation from Deposit to FundingType. |
| Dictionary.FundingType | Table | Resolves FundingTypeID (legacy param, unused in formula). |
| Billing.CurrencySettings | Table | Reads currency Precision (legacy param, unused in formula). |
| Billing.CalculateDepositPIPsUSD_Formula | Function | Performs the actual PIPs calculation. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_PIPS_Report | Stored Procedure | PIPs revenue reporting. |
| Billing.BI_Deposit_State_Report | Stored Procedure | Full deposit state BI report. |
| Billing.GetMoneyInTransactionsByCID | Stored Procedure | Customer money-in history. |
| Billing.UserMoneyInTransactionsGet | Stored Procedure | User transaction history. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Legacy unused params | Design | @FundingTypeID, @ExchangeFee, @CurrencyPrecision are retrieved and passed to the formula function but are NOT used in the current formula implementation. They persist for interface backward compatibility. |
| @OfflinePayment unused | Note | `DECLARE @OfflinePayment INT = 2` is dead code - was used when FundingTypeID=2 had a separate calculation branch that was subsequently removed. |
| NULL on missing deposit | Behavior | If @DepositID is not found, the JOIN returns no rows, @PIPSInUSD is never SET, and the function returns NULL (SQL Server default for uninitialized MONEY variable). |

---

## 8. Sample Queries

### 8.1 Calculate PIPs for a specific deposit

```sql
SELECT Billing.CalculateDepositPIPsUSD(123456) AS DepositPIPsUSD;
-- Positive result = eToro earned PIPs on this deposit
-- NULL = DepositID not found
```

### 8.2 PIPs alongside deposit details

```sql
SELECT
    d.DepositID,
    d.CurrencyID,
    d.Amount,
    d.BaseExchangeRate,
    d.ExchangeRate,
    Billing.CalculateDepositPIPsUSD(d.DepositID) AS PIPs
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.CID = 12345
  AND d.PaymentStatusID = 2  -- Approved
ORDER BY d.DepositID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 8.3 Aggregate PIPs by funding type for a date range

```sql
SELECT
    ft.Name AS FundingType,
    SUM(Billing.CalculateDepositPIPsUSD(d.DepositID)) AS TotalPIPs
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = d.FundingID
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = f.FundingTypeID
WHERE d.PaymentStatusID = 2
  AND d.CreateDate >= '2026-01-01'
GROUP BY ft.Name
ORDER BY TotalPIPs DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CalculateDepositPIPsUSD | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.CalculateDepositPIPsUSD.sql*
