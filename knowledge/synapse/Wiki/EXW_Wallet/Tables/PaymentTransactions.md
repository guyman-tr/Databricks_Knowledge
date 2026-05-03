# EXW_Wallet.PaymentTransactions

> 24,181-row frozen bronze landing table storing crypto execution details for Simplex fiat-to-crypto payment transactions, covering 2019-02-01 to 2022-09-20. One row per payment transaction. Sourced via Generic Pipeline (Append) from WalletDB.Wallet.PaymentTransactions. Table is frozen — Simplex was decommissioned in September 2022; no new data is being ingested.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.PaymentTransactions (Generic Pipeline, Append) |
| **Refresh** | Frozen — last data 2022-09-20 (Simplex decommissioned); Generic Pipeline schedule was daily (1440 min) |
| **Synapse Distribution** | HASH(PaymentId) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_paymenttransactions` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze landing (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.PaymentTransactions is a raw bronze landing table capturing the crypto execution side of every Simplex fiat-to-crypto payment on the eToro Wallet (eToroX) platform. While the parent table EXW_Wallet.Payments records the fiat side (currency, amount, wallet), this table records the crypto execution parameters: exchange rate at execution time, blockchain destination address, crypto amount, and a full fee breakdown (eToro fee, provider fee, and estimated blockchain network fee).

The table contains 24,181 rows spanning 2019-02-01 to 2022-09-20. Yearly distribution: 2019 (2,232 rows), 2020 (6,135), 2021 (8,008), 2022 (7,806). The data is frozen because Simplex was decommissioned as a payment provider in September 2022. No stored procedure populates this table — it was loaded directly via the Generic Pipeline (Append strategy) from the production WalletDB.Wallet.PaymentTransactions table on a daily schedule.

There is a one-to-one relationship between PaymentTransactions and Payments (PaymentId is unique). The table is consumed by the EXW_Wallet.EXW_TransactionsView in the `payment_transactions` CTE, which joins SentTransactions → Payments (via CorrelationId) → PaymentTransactions (via PaymentId) to assemble the unified wallet transaction view for TransactionTypeId = 7 (Payment).

Fee structure is highly uniform: EtoroFeePercentage is 1.00% for 24,174 of 24,181 rows (7 rows at 0.01%), and ProviderFeePercentage is 4.00% for 24,174 rows (7 rows at 0.04%).

---

## 2. Business Logic

### 2.1 Payment-to-Transaction Linkage

**What**: Each payment transaction record links to exactly one parent payment request via PaymentId.
**Columns Involved**: Id, PaymentId
**Rules**:
- PaymentId is a unique FK to EXW_Wallet.Payments.Id — one transaction record per payment
- In the EXW_TransactionsView, the join path is: SentTransactions.CorrelationId → Payments.CorrelationId, then Payments.Id → PaymentTransactions.PaymentId

### 2.2 Fee Structure

**What**: Three-tier fee breakdown covering eToro service fee, payment provider (Simplex) fee, and blockchain network fee.
**Columns Involved**: EtoroFeePercentage, EtoroFeeCalculated, ProviderFeePercentage, ProviderFeeCalculated, EstimatedBlockChainFee
**Rules**:
- EtoroFeePercentage is almost universally 1.00% (99.97% of rows)
- ProviderFeePercentage is almost universally 4.00% (99.97% of rows)
- EtoroFeeCalculated and ProviderFeeCalculated are denominated in crypto units
- EstimatedBlockChainFee is the estimated blockchain network fee at transaction time
- In EXW_TransactionsView, FeeExchangeRate is computed as `1 / pt.ExchangeRate`

### 2.3 Exchange Rate Conversion

**What**: ExchangeRate captures the fiat-to-crypto rate at execution time.
**Columns Involved**: ExchangeRate, Amount
**Rules**:
- ExchangeRate is fiat-to-crypto (e.g., 6560.55 for BTC means 1 BTC = 6560.55 fiat units)
- Amount is the crypto quantity purchased (e.g., 0.0564 BTC)
- No NULL values in either column across all 24,181 rows

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(PaymentId) — optimized for joins on PaymentId (which is the primary join key to EXW_Wallet.Payments)
- **Index**: HEAP — no clustered index; suitable for append-only bronze landing tables
- Table is small (24K rows) — full scans are fast regardless of distribution

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Fee analysis for Simplex payments | `SELECT EtoroFeePercentage, ProviderFeePercentage, EstimatedBlockChainFee FROM EXW_Wallet.PaymentTransactions` |
| Payment details with fiat context | JOIN to EXW_Wallet.Payments ON PaymentId = Payments.Id for fiat currency and amount |
| Full transaction view | Query EXW_Wallet.EXW_TransactionsView which assembles the complete picture |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.Payments | PaymentTransactions.PaymentId = Payments.Id | Get fiat side (currency, wallet, fiat amount) |
| EXW_Wallet.SentTransactions | Via Payments.CorrelationId = SentTransactions.CorrelationId | Get blockchain transaction details |
| EXW_Wallet.EXW_TransactionsView | Used internally in the view | Unified wallet transaction view |

### 3.4 Gotchas

- Table is **frozen** since September 2022 — do not expect new data
- ExchangeRate is fiat-to-crypto (high values like 6560 for BTC), not crypto-to-fiat
- Fee columns are in **crypto units**, not fiat — multiply by ExchangeRate to get fiat equivalent
- 7 rows (0.03%) have anomalous fee percentages (0.01% eToro, 0.04% provider) instead of the standard 1%/4%
- ToAddress contains raw blockchain addresses — treat as PII-adjacent (can be used to trace on-chain activity)
- etr_y/etr_ym/etr_ymd are ETL partition columns derived from Occurred, not from production data

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki (Wallet.PaymentTransactions) — description copied verbatim |
| Tier 2 | ETL-computed or pipeline-added column with no production equivalent |
| Tier 3 | No upstream source traceable; described from DDL and data evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Auto-incrementing primary key. (Tier 1 — Wallet.PaymentTransactions) |
| 2 | PaymentId | bigint | YES | Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment. (Tier 1 — Wallet.PaymentTransactions) |
| 3 | ExchangeRate | numeric(36,18) | YES | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. (Tier 1 — Wallet.PaymentTransactions) |
| 4 | ToAddress | varchar(max) | YES | Blockchain destination address for the purchased crypto. (Tier 1 — Wallet.PaymentTransactions) |
| 5 | Amount | numeric(36,18) | YES | Amount of crypto being purchased/transferred. (Tier 1 — Wallet.PaymentTransactions) |
| 6 | EtoroFeePercentage | numeric(5,2) | YES | eToro service fee as a percentage. (Tier 1 — Wallet.PaymentTransactions) |
| 7 | EtoroFeeCalculated | numeric(36,18) | YES | Calculated eToro fee in crypto units. (Tier 1 — Wallet.PaymentTransactions) |
| 8 | ProviderFeePercentage | numeric(5,2) | YES | Payment provider's fee as a percentage. (Tier 1 — Wallet.PaymentTransactions) |
| 9 | ProviderFeeCalculated | numeric(36,18) | YES | Calculated provider fee in crypto units. (Tier 1 — Wallet.PaymentTransactions) |
| 10 | EstimatedBlockChainFee | numeric(36,18) | YES | Estimated blockchain network fee. (Tier 1 — Wallet.PaymentTransactions) |
| 11 | Occurred | datetime2(7) | YES | Timestamp of record creation. (Tier 1 — Wallet.PaymentTransactions) |
| 12 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition column: year extracted from Occurred (e.g., '2021'). (Tier 2 — Generic Pipeline) |
| 13 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition column: year-month extracted from Occurred (e.g., '2021-04'). (Tier 2 — Generic Pipeline) |
| 14 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition column: year-month-day extracted from Occurred (e.g., '2021-04-23'). (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Id | Wallet.PaymentTransactions | Id | Passthrough |
| PaymentId | Wallet.PaymentTransactions | PaymentId | Passthrough |
| ExchangeRate | Wallet.PaymentTransactions | ExchangeRate | Passthrough |
| ToAddress | Wallet.PaymentTransactions | ToAddress | Passthrough |
| Amount | Wallet.PaymentTransactions | Amount | Passthrough |
| EtoroFeePercentage | Wallet.PaymentTransactions | EtoroFeePercentage | Passthrough |
| EtoroFeeCalculated | Wallet.PaymentTransactions | EtoroFeeCalculated | Passthrough |
| ProviderFeePercentage | Wallet.PaymentTransactions | ProviderFeePercentage | Passthrough |
| ProviderFeeCalculated | Wallet.PaymentTransactions | ProviderFeeCalculated | Passthrough |
| EstimatedBlockChainFee | Wallet.PaymentTransactions | EstimatedBlockChainFee | Passthrough |
| Occurred | Wallet.PaymentTransactions | Occurred | Passthrough |
| etr_y | Generic Pipeline | Occurred | YEAR extraction |
| etr_ym | Generic Pipeline | Occurred | YEAR-MONTH extraction |
| etr_ymd | Generic Pipeline | Occurred | YEAR-MONTH-DAY extraction |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.PaymentTransactions (production, WalletDB server)
  |-- Generic Pipeline (Bronze export, Append, daily 1440 min) ---|
  v
Bronze/WalletDB/Wallet/PaymentTransactions/ (Data Lake, parquet)
  |-- Generic Pipeline (Bronze landing) ---|
  v
EXW_Wallet.PaymentTransactions (24,181 rows, frozen since 2022-09-20)
  |-- Generic Pipeline (Bronze export to UC) ---|
  v
wallet.bronze_walletdb_wallet_paymenttransactions (UC delta)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PaymentId | EXW_Wallet.Payments | FK to parent payment request (Payments.Id) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Element | Description |
|--------------|---------|-------------|
| EXW_Wallet.EXW_TransactionsView | PaymentId | Joined in payment_transactions CTE for TransactionTypeId = 7 (Payment) |

---

## 7. Sample Queries

### 7.1 Payment transaction details with fiat context

```sql
SELECT
    p.Amount AS FiatAmount,
    pt.ExchangeRate,
    pt.Amount AS CryptoAmount,
    pt.EtoroFeePercentage,
    pt.EtoroFeeCalculated,
    pt.ProviderFeePercentage,
    pt.ProviderFeeCalculated,
    pt.EstimatedBlockChainFee,
    pt.Occurred
FROM [EXW_Wallet].[PaymentTransactions] pt
JOIN [EXW_Wallet].[Payments] p ON pt.PaymentId = p.Id
ORDER BY pt.Occurred DESC
```

### 7.2 Monthly fee summary

```sql
SELECT
    etr_ym,
    COUNT(*) AS tx_count,
    AVG(EtoroFeePercentage) AS avg_etoro_fee_pct,
    AVG(ProviderFeePercentage) AS avg_provider_fee_pct,
    SUM(EtoroFeeCalculated) AS total_etoro_fee_crypto,
    SUM(ProviderFeeCalculated) AS total_provider_fee_crypto
FROM [EXW_Wallet].[PaymentTransactions]
GROUP BY etr_ym
ORDER BY etr_ym
```

### 7.3 Anomalous fee rows

```sql
SELECT *
FROM [EXW_Wallet].[PaymentTransactions]
WHERE EtoroFeePercentage <> 1.00
   OR ProviderFeePercentage <> 4.00
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Table is frozen (Simplex decommissioned September 2022).

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 11 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 6/10, Relationships: 6/10, Sources: 8/10*
*Object: EXW_Wallet.PaymentTransactions | Type: Table | Production Source: WalletDB.Wallet.PaymentTransactions*
