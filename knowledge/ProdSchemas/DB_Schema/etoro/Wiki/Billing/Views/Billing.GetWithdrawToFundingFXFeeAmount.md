# Billing.GetWithdrawToFundingFXFeeAmount

> Computes FX markup fees for processed (CashoutStatusID=3) withdrawal payment legs, deriving BaseExchangeRate from currency conversion instrument data and presenting three fee metrics: fee in withdrawal currency, fee in USD, and amount after fee.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | ID (WithdrawToFunding.ID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetWithdrawToFundingFXFeeAmount` is the withdrawal-side counterpart to `Billing.GetDepositFXFeeAmount`. It answers "how much FX fee was charged on each processed withdrawal leg?" but with significantly more complexity: the BaseExchangeRate must be derived dynamically from `Trade.GetCurrencyConversionsView` and `Trade.ProviderToInstrument` because withdrawals can involve reciprocal (inverted) exchange rates and per-currency ExchangeFeeMultiplier adjustments.

The view uses a CTE to compute `BaseExchangeRate` (the standard market rate) and then the outer SELECT derives three fee metrics:
- `FXFeeAmountCurrency`: fee in the withdrawal's process currency (local currency fee)
- `FXFeeAmountUSD`: fee in USD (calculated using RefundAmountInDepositCurrency as the USD reference)
- `AmountAfterFee`: the net withdrawal amount after subtracting the FX fee

**BaseExchangeRate derivation** handles two cases:
1. **Non-WireTransfer (FundingTypeID != 2)**: Uses `Trade.GetCurrencyConversionsView.IsReciprocal` to determine if the rate should be inverted (1/BaseExchangeRate when reciprocal). Falls back to ExchangeRate if BaseExchangeRate is NULL.
2. **WireTransfer (FundingTypeID = 2)**: Computes BaseExchangeRate as `ExchangeRate - (ExchangeFee / 10^ExchangeFeeMultiplier)`, where ExchangeFeeMultiplier from `Trade.ProviderToInstrument` determines the decimal precision of the fee.

The view is consumed by account statement procedures (`dbo.AccountStatement_GetTransactionsReport_v8/v9/v10`, `dbo.AccountStatement_GetUserStatementSummary`) to include withdrawal FX fee line items (CreditTypeID=9) in customer account statements.

**338,096 rows** - processed withdrawal legs only (CashoutStatusID=3).

---

## 2. Business Logic

### 2.1 Processed Withdrawals Only (CashoutStatusID=3)

**What**: Only withdrawal payment legs that have been successfully processed are included.

**Columns/Parameters Involved**: `CashoutStatusID`

**Rules**:
- CTE WHERE: `wtf.CashoutStatusID = 3` (Processed)
- Other statuses (1=Pending, 4=Canceled, 7=Rejected, etc.) are excluded
- `CashoutStatusID=3` is passed through to the outer SELECT for caller confirmation
- Ensures only settled withdrawals contribute to fee calculations

### 2.2 BaseExchangeRate Derivation - Three-Branch CASE

**What**: Computes the theoretical market (base) exchange rate from currency conversion instrument data, handling reciprocal rates and WireTransfer's fee-embedded rate.

**Columns/Parameters Involved**: `BaseExchangeRate`, `IsReciprocal`, `ExchangeFee`, `ExchangeFeeMultiplier`, `FundingTypeID`

**Rules**:

**Branch 1** - Non-WireTransfer + Reciprocal rate (IsReciprocal=1 AND FundingTypeID != 2):
- `BaseExchangeRate = ISNULL(1 / wtf.BaseExchangeRate, wtf.ExchangeRate)`
- The stored BaseExchangeRate is in the "wrong direction" so it must be inverted
- Falls back to ExchangeRate if BaseExchangeRate is NULL

**Branch 2** - Non-WireTransfer + Non-reciprocal (IsReciprocal != 1 AND FundingTypeID != 2):
- `BaseExchangeRate = ISNULL(wtf.BaseExchangeRate, wtf.ExchangeRate)`
- Uses stored BaseExchangeRate directly
- Falls back to ExchangeRate if NULL

**Branch 3** - WireTransfer (FundingTypeID = 2, any IsReciprocal):
- `BaseExchangeRate = ExchangeRate - (ExchangeFee / POWER(10, ExchangeFeeMultiplier))`
- For WireTransfer, the ExchangeRate already embeds the fee - subtract the per-instrument fee to get the base rate
- ExchangeFeeMultiplier defines the decimal precision (e.g., multiplier=2 means ExchangeFee/100)
- COALESCE(ExchangeFee, 0) handles NULL ExchangeFee

**NULL result**: When no matching Trade.GetCurrencyConversionsView record exists (USD withdrawals where no conversion needed), BaseExchangeRate = NULL, causing FXFeeAmountCurrency and FXFeeAmountUSD to be NULL.

### 2.3 Three Fee Metrics

**What**: The outer SELECT derives three fee representations from the computed BaseExchangeRate.

**Columns/Parameters Involved**: `FXFeeAmountCurrency`, `FXFeeAmountUSD`, `AmountAfterFee`

**Rules**:
- `FXFeeAmountCurrency = (Amount * ExchangeRate) - (Amount * BaseExchangeRate)`: fee in the withdrawal's ProcessCurrency. Positive = eToro charged more than base rate.
- `FXFeeAmountUSD = (ExchangeRate * RefundAmountInDepositCurrency) - (BaseExchangeRate * RefundAmountInDepositCurrency)`: fee in USD. Uses RefundAmountInDepositCurrency (the USD equivalent of the withdrawal) as the base amount.
- `AmountAfterFee = Amount - FXFeeAmountUSD`: the net withdrawal amount after the FX fee is deducted in USD terms.
- All three are NULL when BaseExchangeRate is NULL (e.g., USD-to-USD withdrawals with no FX conversion).

---

## 3. Data Overview

| CID | ID | WithdrawID | Amount | ProcessCurrencyID | ExchangeRate | BaseExchangeRate | FXFeeAmountCurrency | FXFeeAmountUSD | AmountAfterFee | FundingTypeID |
|-----|----|------------|--------|------------------|--------------|-----------------|---------------------|----------------|----------------|--------------|
| 25465164 | 1370781 | 1735124 | 30 | 3 (GBP) | 1.34785 | 1.33785 | 0.30 | 0.2226 | 29.7774 | 33 |
| 25465141 | 1370776 | 1735114 | 30 | 3 (GBP) | 1.34785 | 1.33785 | 0.30 | 0.2226 | 29.7774 | 33 |
| 25465146 | 1370774 | 1735106 | 25 | 1 (USD) | 1.00 | NULL | NULL | NULL | NULL | 1 (CreditCard) |

**Row count**: 338,096 (processed withdrawal legs only - CashoutStatusID=3)

**FXFeeAmountCurrency distribution**:
- Zero fee: 35,346 rows (10%)
- Positive fee (FX markup revenue): 145,069 rows (43%)
- Negative fee (favorable rate): 6,544 rows (2%)
- NULL (no FX conversion): ~151,137 rows (45%) - USD withdrawals or missing base rate

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. From Billing.Withdraw (joined via WithdrawID). The customer who made the withdrawal request. |
| 2 | ID | int | NO | - | CODE-BACKED | WithdrawToFunding.ID - the unique identifier for this withdrawal payment leg. PK of Billing.WithdrawToFunding. Used as the join key by callers. |
| 3 | WithdrawID | int | NO | - | CODE-BACKED | Withdrawal request identifier. FK to Billing.Withdraw. One withdraw can have multiple payment legs (multiple WithdrawToFunding rows). Callers join ON WF.WithdrawID = HCRD.WithdrawID. |
| 4 | CashoutStatusID | int | NO | - | CODE-BACKED | Always 3 (Processed) - the CTE WHERE filter ensures only processed legs are returned. Included for caller confirmation. |
| 5 | Amount | money | NO | - | CODE-BACKED | Withdrawal amount in ProcessCurrency. From Billing.WithdrawToFunding. The gross amount before FX fee deduction. |
| 6 | ProcessCurrencyID | int | YES | - | CODE-BACKED | Currency in which the withdrawal was processed. From Billing.WithdrawToFunding. References Dictionary.Currency. 1=USD (no FX fee), 3=GBP, 2=EUR, etc. When ProcessCurrencyID=1 (USD), BaseExchangeRate is often NULL (no conversion needed). |
| 7 | RefundAmountInDepositCurrency | money | YES | - | CODE-BACKED | The USD-equivalent amount of the withdrawal. From Billing.WithdrawToFunding. Used to compute FXFeeAmountUSD: `(ExchangeRate - BaseExchangeRate) * RefundAmountInDepositCurrency`. Represents the refund amount expressed in the original deposit currency (USD). |
| 8 | ExchangeRate | decimal | YES | - | CODE-BACKED | The actual exchange rate applied to this withdrawal. From Billing.WithdrawToFunding. The customer-facing rate including FX markup. |
| 9 | BaseExchangeRate | decimal(18,8) | YES | - | CODE-BACKED | The theoretical market rate without FX markup. Computed in the CTE: derived from Trade.GetCurrencyConversionsView (with IsReciprocal handling) for non-WireTransfer, or from ExchangeRate - ExchangeFee/10^Multiplier for WireTransfer. NULL when no currency conversion data is available (e.g., USD withdrawals). |
| 10 | FXFeeAmountCurrency | decimal (computed) | YES | - | CODE-BACKED | FX markup fee in the withdrawal's ProcessCurrency. `(Amount * ExchangeRate) - (Amount * BaseExchangeRate)`. Positive = eToro FX revenue. Negative = favorable rate. NULL when BaseExchangeRate is NULL. |
| 11 | FXFeeAmountUSD | decimal (computed) | YES | - | CODE-BACKED | FX markup fee in USD. `(ExchangeRate - BaseExchangeRate) * RefundAmountInDepositCurrency`. Used in account statements as the fee line item amount. NULL when BaseExchangeRate is NULL. |
| 12 | AmountAfterFee | decimal (computed) | YES | - | CODE-BACKED | Net withdrawal amount after FX fee deduction. `Amount - FXFeeAmountUSD`. The effective amount the customer receives after the FX markup is subtracted. NULL when FXFeeAmountUSD is NULL. |
| 13 | FundingTypeID | int | YES | - | CODE-BACKED | Payment method type of the withdrawal. From Billing.Withdraw. Used in the CTE BaseExchangeRate CASE to branch on WireTransfer (FundingTypeID=2) vs other methods. |
| 14 | ModificationDate | datetime | YES | - | CODE-BACKED | Last modification timestamp of the WithdrawToFunding record. From Billing.WithdrawToFunding. Useful for auditing and ordering. |
| 15 | FXFeeCurrency | int (literal) | NO | 1 | CODE-BACKED | Always 1 (USD). Hardcoded constant indicating FX fees are denominated in USD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID, WithdrawID, Amount, ProcessCurrencyID, ExchangeRate, BaseExchangeRate, ExchangeFee, CashoutStatusID, DepotID | Billing.WithdrawToFunding | Source (FROM anchor, CashoutStatusID=3 filter) | Processed withdrawal payment legs |
| CID, FundingTypeID | Billing.Withdraw | Source (INNER JOIN on WithdrawID) | Withdrawal request context (CID, payment method) |
| IsReciprocal, CurrencyID, ConversionInstrumentID | Trade.GetCurrencyConversionsView | Source (LEFT JOIN on ProcessCurrencyID) | Currency conversion direction for BaseExchangeRate derivation |
| InstrumentID, ExchangeFeeMultiplier | Trade.ProviderToInstrument | Source (LEFT JOIN on ConversionInstrumentID) | Exchange fee precision multiplier for WireTransfer fee calculation |
| DepotID, FundingTypeID | Billing.Depot | Source (LEFT JOIN on DepotID) | Depot funding type to branch WireTransfer logic |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AccountStatement_GetTransactionsReport_v8 | FXFeeAmountUSD | Reference (JOIN on WithdrawID) | Adds withdrawal FX fee line items to account statement |
| dbo.AccountStatement_GetTransactionsReport_v9 | FXFeeAmountUSD | Reference (JOIN on WithdrawID) | Same - v9 variant |
| dbo.AccountStatement_GetTransactionsReport_v10 | FXFeeAmountUSD | Reference (JOIN on WithdrawID, WHERE CreditTypeID=9) | Latest version - withdrawal FX fee entries (CreditTypeID=9) |
| dbo.AccountStatement_GetUserStatementSummary | FXFeeAmountUSD | Reference (JOIN on WithdrawID) | Summarised account statement FX fee totals |
| dbo.AccountStatement_GetUserStatementSummary_v2 | FXFeeAmountUSD | Reference (JOIN on WithdrawID) | v2 variant of statement summary |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawToFundingFXFeeAmount (view)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Depot (table)
├── Trade.GetCurrencyConversionsView (view, cross-schema)
└── Trade.ProviderToInstrument (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM anchor in CTE: withdrawal leg data, filtered to CashoutStatusID=3 |
| Billing.Withdraw | Table | INNER JOIN: CID and FundingTypeID from the parent withdrawal request |
| Billing.Depot | Table | LEFT JOIN on DepotID: FundingTypeID to branch WireTransfer BaseExchangeRate logic |
| Trade.GetCurrencyConversionsView | View (cross-schema) | LEFT JOIN on ProcessCurrencyID: IsReciprocal flag for non-WireTransfer rate inversion |
| Trade.ProviderToInstrument | Table (cross-schema) | LEFT JOIN on ConversionInstrumentID: ExchangeFeeMultiplier for WireTransfer fee precision |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetTransactionsReport_v8 | Stored Procedure | JOIN on WithdrawID for withdrawal FX fee line items |
| dbo.AccountStatement_GetTransactionsReport_v9 | Stored Procedure | JOIN on WithdrawID; same purpose |
| dbo.AccountStatement_GetTransactionsReport_v10 | Stored Procedure | JOIN on WithdrawID; latest version |
| dbo.AccountStatement_GetUserStatementSummary | Stored Procedure | JOIN on WithdrawID for summary FX fee totals |
| dbo.AccountStatement_GetUserStatementSummary_v2 | Stored Procedure | JOIN on WithdrawID; v2 summary variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. 338,096 rows. CTE uses CashoutStatusID=3 filter on Billing.WithdrawToFunding (which has a CashoutStatusID index). Callers typically join on WithdrawID. The CTE with three LEFT JOINs (Trade schema cross-schema) adds complexity but is manageable at this row count.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-schema to Trade). FXFeeAmountCurrency, FXFeeAmountUSD, AmountAfterFee are NULL when BaseExchangeRate is NULL (USD withdrawals or missing conversion data). The three-branch CASE in the CTE returns NULL as a fourth implicit branch (when none of the three conditions match - e.g., IsReciprocal IS NULL and FundingTypeID IS NULL from missing LEFT JOINs). `AccountStatement_GetTransactionsReport_v10` uses `CreditTypeID=9` (withdrawal fee credit type) to identify the relevant rows.

---

## 8. Sample Queries

### 8.1 Get FX fee for a specific customer's withdrawals

```sql
SELECT WithdrawID, Amount, ProcessCurrencyID, FXFeeAmountCurrency, FXFeeAmountUSD, AmountAfterFee
FROM Billing.GetWithdrawToFundingFXFeeAmount WITH (NOLOCK)
WHERE CID = @CustomerID
ORDER BY ID DESC
```

### 8.2 Total FX revenue from withdrawal fees

```sql
SELECT SUM(FXFeeAmountUSD) AS TotalWithdrawFXRevenue, COUNT(*) AS FeeCount
FROM Billing.GetWithdrawToFundingFXFeeAmount WITH (NOLOCK)
WHERE FXFeeAmountUSD IS NOT NULL AND FXFeeAmountUSD <> 0
```

### 8.3 Account statement usage pattern (withdrawal FX fee line items)

```sql
SELECT WF.CID, WF.WithdrawID, WF.FXFeeAmountUSD, WF.ProcessCurrencyID
FROM Billing.GetWithdrawToFundingFXFeeAmount AS WF WITH (NOLOCK)
JOIN #Credits AS HCRD ON WF.WithdrawID = HCRD.WithdrawID
WHERE HCRD.CreditTypeID = 9
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetWithdrawToFundingFXFeeAmount | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetWithdrawToFundingFXFeeAmount.sql*
