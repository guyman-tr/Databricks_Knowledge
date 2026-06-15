# BI_DB_dbo.BI_DB_Local_Currencies_MIMO

> 2.22M-row finance FX revenue tracking table for local currency deposits and withdrawals (excluding USD/EUR/GBP/AUD). Each row is a single deposit or withdrawal transaction in a non-major currency, with FX income, cost, revenue, and fee percentage. 89% deposits, 11% cashouts. Date range: Jan 2023 -- Apr 2026. Daily DELETE+INSERT by DateID via SP_Local_Currencies_MIMO.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Finance -- FX Revenue Tracking, Local Currencies) |
| **Production Source** | Fact_BillingDeposit + Fact_BillingWithdraw + BI_DB_DepositWithdrawFee by SP_Local_Currencies_MIMO |
| **Refresh** | Daily DELETE+INSERT by DateID (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_Local_Currencies_MIMO` tracks **FX revenue from local currency Money-In / Money-Out (MIMO)** transactions. The platform earns FX income on the spread between the mid-market exchange rate (Base Exchange Rate) and the eToro exchange rate (Exchange Rate) when customers deposit or withdraw in non-major currencies.

The table holds 2.22M rows (1.98M deposits, 244K cashouts) from January 2023 to April 2026. Two source streams are UNION'd:

1. **Deposits**: From Fact_BillingDeposit where FundingTypeID=1 and CurrencyID NOT IN (1=USD, 2=EUR, 3=GBP, 5=AUD). FX Income = (Amount * BaseExchangeRate) - (Amount * ExchangeRate).
2. **Cashouts**: From Fact_BillingWithdraw with same currency filter. FX Income = PIPsCalculation * ExchangeRate (from BI_DB_DepositWithdrawFee).

FX Cost is computed as 0.8% of the base USD amount, except for certain currencies (CHF, NOK, SEK, PLN, HUF, DKK, CZK, RON) where FX Cost is 0. FX Revenue = FX Income - FX Cost.

### Author and History
Created by Adi Meidan. Country/currency definition updated 2024-09-25. Deposit FX income calculation changed 2025-05-15 by Markos Chris.

---

## 2. Business Logic

### 2.1 Currency Exclusion

**What**: Only local/exotic currencies are tracked.
**Columns Involved**: Country and Currency
**Rules**:
- Excluded: CurrencyID 1 (USD), 2 (EUR), 3 (GBP), 5 (AUD)
- Included: Singapore Dollar, UAE Dirham, USD/CZK, Polish Zloty, Malaysian Ringgit, etc.

### 2.2 FX Revenue Calculation

**What**: FX revenue = spread income minus cost.
**Columns Involved**: FX Income, FX Cost, FX Revenue
**Rules**:
- Deposits: FX Income = (Amount * BaseExchangeRate) - (Amount * ExchangeRate)
- Cashouts: FX Income = PIPsCalculation * ExchangeRate (from BI_DB_DepositWithdrawFee)
- FX Cost = Amount * BaseExchangeRate * 0.008 (0.8% cost) for most currencies
- FX Cost = 0 for CHF, NOK, SEK, PLN, HUF, DKK, CZK, RON (CurrencyID 521,6,39,40,44,45,46,82)
- FX Revenue = FX Income - FX Cost

### 2.3 Fee Percentage

**What**: Markup percentage charged to the customer.
**Columns Involved**: Fee Percentage
**Rules**:
- 1 - (ExchangeRate / BaseExchangeRate)
- NULL if BaseExchangeRate = 0

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Medium table (2.22M rows). Filter on DateID for date-specific analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily FX revenue by currency | `GROUP BY DateID, [Country and Currency]` |
| Deposit vs cashout FX revenue | `GROUP BY IND` |
| Provider performance | `GROUP BY Provider` |
| Average fee percentage by currency | `AVG([Fee Percentage]) GROUP BY [Country and Currency]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit | Deposit/WD_ID = DepositID (WHERE IND='Deposits') | Full deposit details |
| DWH_dbo.Fact_BillingWithdraw | Deposit/WD_ID = WithdrawID (WHERE IND='Cashout') | Full withdrawal details |

### 3.4 Gotchas

- **Column names with spaces**: Most columns use spaces (e.g., `[Country and Currency]`, `[FX Income]`). Always use square brackets
- **IND values**: 'Deposits' (plural) and 'Cashout' (singular) -- inconsistent pluralization
- **FX Cost = 0 for some currencies**: CHF, NOK, SEK, PLN, HUF, DKK, CZK, RON have zero FX cost. FX Revenue = FX Income for these
- **Deposit/WD_ID is overloaded**: Contains DepositID for deposits and WithdrawID for cashouts. Must filter by IND before joining
- **USD Amount**: For deposits = Amount * ExchangeRate. For cashouts = raw currency amount (not converted). Naming is misleading for cashouts

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Modification date in YYYYMMDD format. Used for DELETE+INSERT partitioning. (Tier 2 -SP_Local_Currencies_MIMO) |
| 2 | Deposit/WD_ID | int | YES | Deposit ID (when IND='Deposits') or Withdraw ID (when IND='Cashout'). Overloaded key -- filter by IND before joining. (Tier 2 -SP_Local_Currencies_MIMO) |
| 3 | Country and Currency | varchar(100) | YES | Currency name from Dim_Currency. Examples: 'Singapore Dollar', 'UAE Dirham', 'USD/CZK', 'Polish Zloty'. Excludes USD/EUR/GBP/AUD. (Tier 2 -SP_Local_Currencies_MIMO) |
| 4 | Currency Amount | money | YES | Transaction amount in the local currency. Deposits: Fact_BillingDeposit.Amount. Cashouts: ISNULL(Amount_WithdrawToFunding, Amount_Withdraw). (Tier 2 -SP_Local_Currencies_MIMO) |
| 5 | FX Income | float | YES | Foreign exchange income from the spread. Deposits: (Amount * BaseExchangeRate) - (Amount * ExchangeRate). Cashouts: PIPsCalculation * ExchangeRate. In USD. (Tier 2 -SP_Local_Currencies_MIMO) |
| 6 | FX Cost | float | YES | Foreign exchange cost (provider/hedging). Amount * BaseExchangeRate * 0.008 for most currencies. 0 for CHF, NOK, SEK, PLN, HUF, DKK, CZK, RON. In USD. (Tier 2 -SP_Local_Currencies_MIMO) |
| 7 | Fee Percentage | float | YES | FX markup percentage: 1 - (ExchangeRate / BaseExchangeRate). NULL if BaseExchangeRate = 0. Typically 2-3%. (Tier 2 -SP_Local_Currencies_MIMO) |
| 8 | Exchange Rate | float | YES | eToro exchange rate with FX markup applied. Local currency to USD. (Tier 2 -SP_Local_Currencies_MIMO) |
| 9 | Base Exchange Rate | float | YES | Mid-market exchange rate (no markup). Local currency to USD. The difference between Exchange Rate and Base Exchange Rate represents the FX spread. (Tier 2 -SP_Local_Currencies_MIMO) |
| 10 | Payment Status | varchar(50) | YES | Payment/cashout status name. Deposits: from Dim_PaymentStatus. Cashouts: from Dim_CashoutStatus. Examples: 'Approved', 'Decline', 'Processed'. (Tier 2 -SP_Local_Currencies_MIMO) |
| 11 | Payment Date | date | YES | Transaction date. Deposits: PaymentDate. Cashouts: RequestDate. CAST to DATE. (Tier 2 -SP_Local_Currencies_MIMO) |
| 12 | USD Amount | money | YES | USD-equivalent amount. Deposits: Amount * ExchangeRate. Cashouts: raw currency amount (naming misleading). (Tier 2 -SP_Local_Currencies_MIMO) |
| 13 | FX Revenue | float | YES | Net FX revenue = FX Income - FX Cost. In USD. The primary metric for FX profitability analysis. (Tier 2 -SP_Local_Currencies_MIMO) |
| 14 | IND | varchar(50) | YES | Transaction type indicator: 'Deposits' or 'Cashout'. Note: inconsistent pluralization. (Tier 2 -SP_Local_Currencies_MIMO) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted. Set to GETDATE(). (Tier 5 -SP_Local_Currencies_MIMO) |
| 16 | Date | date | YES | Business date (same as DateID but as date type). SP parameter @Date. (Tier 2 -SP_Local_Currencies_MIMO) |
| 17 | Provider | varchar(50) | YES | Payment provider name from Dim_BillingDepot.Name. Examples: 'Checkout', 'IXOPAY-Nuvei'. (Tier 2 -SP_Local_Currencies_MIMO) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| DateID, Date | SP parameter | @Date | Integer conversion |
| Deposit/WD_ID | Fact_BillingDeposit / Fact_BillingWithdraw | DepositID / WithdrawID | UNION |
| Country and Currency | Dim_Currency | Name | JOIN on CurrencyID |
| Currency Amount | Fact_BillingDeposit / Fact_BillingWithdraw | Amount | Passthrough / ISNULL |
| FX Income | Computed | Amount, ExchangeRate, BaseExchangeRate | Spread calculation |
| FX Cost | Computed | Amount, BaseExchangeRate | 0.8% of base USD |
| FX Revenue | Computed | FX Income, FX Cost | Difference |
| Exchange Rate, Base Exchange Rate | Fact_BillingDeposit / BI_DB_DepositWithdrawFee | ExchangeRate, BaseExchangeRate | Passthrough |
| Payment Status | Dim_PaymentStatus / Dim_CashoutStatus | Name | JOIN lookup |
| Provider | Dim_BillingDepot | Name | JOIN on DepotID |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingDeposit (FundingTypeID=1, CurrencyID NOT IN 1,2,3,5)
  + DWH_dbo.Dim_Currency, Dim_PaymentStatus, Dim_BillingDepot
    |-- #deposit = FX Income/Cost/Revenue calculation --|
    v
DWH_dbo.Fact_BillingWithdraw (same filters)
  + BI_DB_dbo.BI_DB_DepositWithdrawFee (PIPsCalculation)
  + DWH_dbo.Dim_CashoutStatus, Dim_BillingDepot
    |-- #co = FX Income/Cost/Revenue calculation -------|
    v
UNION ALL → #co_dep_union (IND = Deposits/Cashout)
  |-- SP_Local_Currencies_MIMO @Date (daily, DELETE+INSERT by DateID) --|
  v
BI_DB_dbo.BI_DB_Local_Currencies_MIMO (2.22M rows)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Deposit/WD_ID (IND='Deposits') | DWH_dbo.Fact_BillingDeposit (DepositID) | Full deposit record |
| Deposit/WD_ID (IND='Cashout') | DWH_dbo.Fact_BillingWithdraw (WithdrawID) | Full withdrawal record |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Daily FX Revenue by Currency

```sql
SELECT DateID,
       [Country and Currency],
       SUM([FX Revenue]) AS total_fx_revenue,
       COUNT(*) AS transactions
FROM [BI_DB_dbo].[BI_DB_Local_Currencies_MIMO]
WHERE DateID >= 20260401
GROUP BY DateID, [Country and Currency]
ORDER BY total_fx_revenue DESC
```

### 7.2 Deposit vs Cashout FX Revenue

```sql
SELECT IND,
       SUM([FX Revenue]) AS total_revenue,
       SUM([FX Income]) AS total_income,
       SUM([FX Cost]) AS total_cost,
       AVG([Fee Percentage]) AS avg_fee_pct
FROM [BI_DB_dbo].[BI_DB_Local_Currencies_MIMO]
WHERE DateID >= 20260101
GROUP BY IND
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 16 T2, 0 T3, 0 T4, 1 T5 | Elements: 17/17, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Local_Currencies_MIMO | Type: Table | Production Source: Fact_BillingDeposit + Fact_BillingWithdraw*
