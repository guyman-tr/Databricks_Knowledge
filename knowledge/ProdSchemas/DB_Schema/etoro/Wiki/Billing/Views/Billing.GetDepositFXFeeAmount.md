# Billing.GetDepositFXFeeAmount

> Computes the FX markup fee charged on each completed deposit by taking the difference between the base (interbank) exchange rate and the actual applied exchange rate, expressed in USD.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | DepositID |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetDepositFXFeeAmount` answers the question "how much FX fee did we charge on each completed deposit?" by computing `(Amount * BaseExchangeRate) - (Amount * ExchangeRate)` for every deposit with PaymentStatusID=2 (Completed).

The formula derives the FX markup fee: `BaseExchangeRate` is the standard interbank mid-market rate, and `ExchangeRate` is the rate actually applied to the customer's deposit. The difference, multiplied by the deposit amount, is the fee collected by eToro for providing currency conversion. A positive FXFeeAmount means the customer paid more than interbank (eToro earned an FX margin). A negative FXFeeAmount occurs when the applied rate was more favorable than interbank (e.g., promotional rates, corrections, or rate timing). Zero means no FX fee was charged (typically USD deposits where no conversion was needed, or where BaseExchangeRate = ExchangeRate).

`FXFeeCurrency` is hardcoded to 1 (USD) because both exchange rates convert the deposit currency to USD - the fee result is always expressed in USD regardless of the original deposit currency.

The view is consumed by account statement procedures (`dbo.AccountStatement_GetTransactionsReport_v8/v9/v10`, `dbo.AccountStatement_GetUserStatementSummary`) to include FX fee line items in customer account statements and transaction reports, filtered to rows where the fee is non-zero.

---

## 2. Business Logic

### 2.1 Completed Deposits Only (PaymentStatusID=2)

**What**: Only deposits that have been successfully processed are included.

**Columns/Parameters Involved**: `PaymentStatusID` (from Billing.Deposit)

**Rules**:
- WHERE PaymentStatusID = 2 (Completed)
- Pending (1), Failed (3), Chargeback, and other statuses are excluded
- Prevents FX fee calculation on deposits that never settled
- Aligns with the billing system's practice of only recognising revenue from completed transactions

### 2.2 FX Fee Formula: Base vs Applied Exchange Rate Spread

**What**: The FX fee is the dollar value of the spread between the interbank rate and the customer's applied rate.

**Columns/Parameters Involved**: `Amount`, `BaseExchangeRate`, `ExchangeRate`, `FXFeeAmount`

**Rules**:
- `FXFeeAmount = (Amount * BaseExchangeRate) - (Amount * ExchangeRate)`
- Equivalently: `Amount * (BaseExchangeRate - ExchangeRate)`
- Positive result: eToro applied a rate less favorable than interbank (standard FX markup, revenue)
- Zero result: No conversion markup (USD deposits, or rates identical)
- Negative result: Applied rate was more favorable than interbank (promotional or correction)
- The result is in USD since exchange rates convert the deposit currency to USD

### 2.3 FXFeeCurrency Always USD

**What**: The fee currency is hardcoded to 1 (USD) in the SELECT.

**Columns/Parameters Involved**: `FXFeeCurrency`

**Rules**:
- `SELECT ... 1 AS FXFeeCurrency` - literal constant, not derived from data
- Always 1 = USD
- Both `BaseExchangeRate` and `ExchangeRate` produce USD-denominated results when multiplied by the original currency `Amount`
- Callers do not need to look up the fee currency - it is always USD

---

## 3. Data Overview

| CID | DepositID | Amount | CurrencyID | FXFeeAmount | FXFeeCurrency | Meaning |
|-----|-----------|--------|------------|-------------|---------------|---------|
| 25465118 | 10781089 | 100 | 1 (USD) | 0 | 1 | USD deposit - no FX conversion needed, fee = 0 |
| 25465117 | 10781088 | 100 | 1 (USD) | 0 | 1 | USD deposit - no FX conversion needed, fee = 0 |

**Row count**: 5,609,253 (completed deposits only - PaymentStatusID=2)

**FXFeeAmount distribution**:
- Zero FX fee: 3,717,030 rows (66%) - no conversion markup applied
- Positive FX fee: 1,750,081 rows (31%) - standard FX markup revenue
- Negative FX fee: 129,946 rows (2%) - favorable rate applied (corrections/promotions)
- Min: -100,800 | Max: ~19,663,421,269 | Avg: ~107,872

**Currency breakdown** (top 5):
- CurrencyID=1 (USD): 3,701,892 rows (66%)
- CurrencyID=3 (GBP): 744,256 rows (13%)
- CurrencyID=2 (EUR): 732,456 rows (13%)
- CurrencyID=5 (CHF/other): 213,290 rows (4%)
- CurrencyID=44: 37,874 rows (1%)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. From Billing.Deposit. The customer who made the deposit. Used by account statement procedures to join with customer-level data. |
| 2 | DepositID | int | NO | - | CODE-BACKED | Unique deposit identifier. PK of Billing.Deposit. Used as JOIN key by callers (e.g., AccountStatement procedures join ON DF.DepositID = HCRD.DepositID to match FX fees to credit history records). |
| 3 | Amount | money | NO | - | CODE-BACKED | Original deposit amount in the deposit's native currency (CurrencyID). From Billing.Deposit. This is the pre-conversion amount that was multiplied by the exchange rates to compute the FX fee. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the original deposit. From Billing.Deposit. References Dictionary.Currency. 1=USD (66% of rows), 3=GBP (13%), 2=EUR (13%). Informs the denomination of Amount. The FX fee result is always in USD regardless of CurrencyID. |
| 5 | FXFeeAmount | money (computed) | YES | - | CODE-BACKED | The FX markup fee in USD. Computed as `(Amount * BaseExchangeRate) - (Amount * ExchangeRate)`. Positive=eToro earned FX spread revenue. Zero=no FX conversion (USD deposits or same rate). Negative=customer received a rate more favorable than interbank. NULL if BaseExchangeRate or ExchangeRate is NULL. 66% of rows are zero. |
| 6 | FXFeeCurrency | int (literal) | NO | 1 | CODE-BACKED | Always 1 (USD). Hardcoded constant indicating the denomination of FXFeeAmount. Both exchange rates convert to USD, so the computed fee is always in USD. Included to make the fee amount self-describing for callers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, DepositID, Amount, CurrencyID, BaseExchangeRate, ExchangeRate | Billing.Deposit | Source (FROM + WHERE PaymentStatusID=2) | Completed deposit records with exchange rate data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AccountStatement_GetTransactionsReport_v8 | FXFeeAmount | Reference (JOIN on DepositID) | Adds FX fee line items to customer transaction report |
| dbo.AccountStatement_GetTransactionsReport_v9 | FXFeeAmount | Reference (JOIN on DepositID) | Same - v9 variant |
| dbo.AccountStatement_GetTransactionsReport_v10 | FXFeeAmount | Reference (JOIN on DepositID, WHERE FXFeeAmount != 0) | Latest version - adds only non-zero FX fee entries |
| dbo.AccountStatement_GetUserStatementSummary | FXFeeAmount | Reference (JOIN on DepositID) | Summarized account statement FX fee totals |
| dbo.AccountStatement_GetUserStatementSummary_v2 | FXFeeAmount | Reference (JOIN on DepositID) | v2 variant of statement summary |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositFXFeeAmount (view)
└── Billing.Deposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM source: CID, DepositID, Amount, CurrencyID, BaseExchangeRate, ExchangeRate; filtered to PaymentStatusID=2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetTransactionsReport_v8 | Stored Procedure | JOIN on DepositID to get FX fee for account statement line items |
| dbo.AccountStatement_GetTransactionsReport_v9 | Stored Procedure | JOIN on DepositID; same purpose |
| dbo.AccountStatement_GetTransactionsReport_v10 | Stored Procedure | JOIN on DepositID; latest account statement version |
| dbo.AccountStatement_GetUserStatementSummary | Stored Procedure | JOIN on DepositID for statement summary FX totals |
| dbo.AccountStatement_GetUserStatementSummary_v2 | Stored Procedure | JOIN on DepositID; v2 summary variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Performance relies on Billing.Deposit indexes. The PaymentStatusID=2 filter reduces the 5.6M result set from the full Deposit table. Callers should join on DepositID (PK of Billing.Deposit, clustered index) for optimal performance.

### 7.2 Constraints

N/A for view. FXFeeAmount may be NULL if BaseExchangeRate or ExchangeRate is NULL in Billing.Deposit (money arithmetic returns NULL on NULL operand). `AccountStatement_GetTransactionsReport_v10` guards against this: `ISNULL(CAST(DF.FXFeeAmount AS DECIMAL(16,2)), 0) <> 0`. FXFeeCurrency is always 1 - a hardcoded literal, not driven by data.

---

## 8. Sample Queries

### 8.1 Get FX fees for a specific customer's deposits

```sql
SELECT DepositID, Amount, CurrencyID, FXFeeAmount, FXFeeCurrency
FROM Billing.GetDepositFXFeeAmount WITH (NOLOCK)
WHERE CID = @CustomerID
ORDER BY DepositID DESC
```

### 8.2 Total FX revenue from non-zero FX fees

```sql
SELECT SUM(FXFeeAmount) AS TotalFXRevenue, COUNT(*) AS FXFeeDeposits
FROM Billing.GetDepositFXFeeAmount WITH (NOLOCK)
WHERE FXFeeAmount <> 0
```

### 8.3 FX fee for a specific deposit (used by account statement)

```sql
SELECT CID, DepositID, FXFeeAmount, FXFeeCurrency
FROM Billing.GetDepositFXFeeAmount WITH (NOLOCK)
WHERE DepositID = @DepositID
  AND ISNULL(CAST(FXFeeAmount AS DECIMAL(16,2)), 0) <> 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetDepositFXFeeAmount | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetDepositFXFeeAmount.sql*
