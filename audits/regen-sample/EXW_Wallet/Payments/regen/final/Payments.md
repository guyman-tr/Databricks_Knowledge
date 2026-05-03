# EXW_Wallet.Payments

> 113,579-row frozen table of Simplex fiat-to-crypto payment requests for eToro Wallet users, covering 2019-01-29 to 2022-09-20. One row per payment request. Sourced via Generic Pipeline (Append) from WalletDB.Wallet.Payments. Table is frozen — Simplex was decommissioned in September 2022; no new data is being ingested.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Payments (Generic Pipeline, Append) |
| **Refresh** | Frozen — last data 2022-09-20 (Simplex decommissioned); Generic Pipeline schedule was daily (1440 min) |
| **Synapse Distribution** | HASH(Id) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_payments` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze landing (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.Payments is a raw bronze landing table capturing every Simplex fiat-to-crypto payment request made on the eToro Wallet (eToroX) platform. Each row represents a single payment initiated by a wallet user to purchase cryptocurrency using a fiat currency (EUR or GBP) via the Simplex payment provider.

The table contains 113,579 rows spanning 2019-01-29 to 2022-09-20. The data is frozen because Simplex was decommissioned as a payment provider in September 2022. No stored procedure populates this table — it was loaded directly via the Generic Pipeline (Append strategy) from the production WalletDB.Wallet.Payments table on a daily schedule.

Fiat currency breakdown: EUR (70%, FiatId=2) and GBP (30%, FiatId=3). Cryptocurrency breakdown: BTC (71%, CryptoId=1), ETH (15%, CryptoId=2), LTC (5%, CryptoId=6), XLM (4%, CryptoId=21), XRP (3%, CryptoId=4), BCH (2%, CryptoId=3).

The table serves as a source for the downstream EXW_dbo.EXW_FactPayments table and is joined in EXW_Wallet.EXW_TransactionsView (payment_transactions CTE) via CorrelationId to SentTransactions and Payments.Id to PaymentTransactions.PaymentId.

---

## 2. Business Logic

### 2.1 Payment-to-Transaction Linkage

**What**: Each payment request links to blockchain sent transactions via CorrelationId and to detailed payment transaction records via Id.
**Columns Involved**: Id, CorrelationId
**Rules**:
- CorrelationId links Payments to EXW_Wallet.SentTransactions (WHERE TransactionTypeId = 7 — Payment)
- Id links Payments to EXW_Wallet.PaymentTransactions (PaymentTransactions.PaymentId = Payments.Id)
- Id also links to EXW_Wallet.PaymentStatuses for lifecycle tracking

### 2.2 Wallet Identification

**What**: WalletId identifies the crypto wallet that initiated the payment.
**Columns Involved**: WalletId
**Rules**:
- WalletId is a GUID string (varchar(4000)) referencing the wallet in EXW_Wallet.Wallets
- Through the Wallets table, WalletId resolves to a GCID (global customer ID)

### 2.3 Fiat-Crypto Pairing

**What**: Each payment specifies the fiat currency used and the cryptocurrency purchased.
**Columns Involved**: FiatId, CryptoId, Amount
**Rules**:
- FiatId resolves via EXW_Wallet.FiatTypes: 2=EUR, 3=GBP (only two fiat currencies supported)
- CryptoId resolves via EXW_Wallet.CryptoTypes: 1=BTC, 2=ETH, 3=BCH, 4=XRP, 6=LTC, 21=XLM
- Amount is the fiat amount of the payment request (numeric(36,18), always positive)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distribution: HASH(Id) — queries filtering or joining on Id are collocated
- Index: HEAP — no clustered index; full scans on non-Id predicates
- For payment lifecycle queries, join to PaymentStatuses on PaymentId = Id

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total payments by fiat currency | `SELECT FiatId, COUNT(*) FROM EXW_Wallet.Payments GROUP BY FiatId` |
| Daily payment volume | `SELECT CAST(Occurred AS DATE), COUNT(*), SUM(Amount) FROM EXW_Wallet.Payments GROUP BY CAST(Occurred AS DATE)` |
| Payments for a specific wallet | `SELECT * FROM EXW_Wallet.Payments WHERE WalletId = '<guid>'` |
| Payment details with crypto name | `JOIN EXW_Wallet.CryptoTypes ct ON ct.CryptoID = p.CryptoId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.PaymentTransactions | PaymentTransactions.PaymentId = Payments.Id | Get exchange rate, crypto amount, fees, destination address |
| EXW_Wallet.PaymentStatuses | PaymentStatuses.PaymentId = Payments.Id | Get payment lifecycle status history |
| EXW_Wallet.SentTransactions | SentTransactions.CorrelationId = Payments.CorrelationId | Link to blockchain sent transaction |
| EXW_Wallet.Wallets | Wallets.WalletId = Payments.WalletId | Resolve wallet to GCID (customer) |
| EXW_Wallet.FiatTypes | FiatTypes.FiatId = Payments.FiatId | Resolve fiat currency name |
| EXW_Wallet.CryptoTypes | CryptoTypes.CryptoID = Payments.CryptoId | Resolve cryptocurrency name |

### 3.4 Gotchas

- **Frozen table**: No new data since 2022-09-20 — Simplex was decommissioned. Do not expect recent rows.
- **Amount is fiat, not crypto**: The Amount column is the fiat payment amount. Crypto amount is in PaymentTransactions.Amount.
- **WalletId is varchar(4000)**: Despite being a GUID, it is stored as a wide varchar — use exact string matching, not GUID casting.
- **ProviderPaymentId**: This is a uniqueidentifier from the Simplex provider, not an internal eToro ID.
- **No direct customer ID**: To get customer identity, join through EXW_Wallet.Wallets on WalletId to obtain GCID.
- **etr_y/etr_ym/etr_ymd**: ETL partition columns from the Generic Pipeline — partition by ingestion date, not business date.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP logic with stated transform |
| Tier 3 | Grounded in DDL, sample data, and related object context; no upstream wiki available |
| Tier 4 | Inferred from column name only (banned in this wiki) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key of the payment request. Auto-incremented identifier from the production WalletDB.Wallet.Payments table. Used as FK in PaymentTransactions and PaymentStatuses. Distribution key for this table. No NULLs observed in 113,579 rows. (Tier 3 — WalletDB.Wallet.Payments) |
| 2 | WalletId | varchar(4000) | YES | GUID identifying the crypto wallet that initiated the payment. Resolves to GCID (global customer ID) via EXW_Wallet.Wallets. No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 3 | ProviderPaymentId | uniqueidentifier | YES | Unique identifier assigned by the Simplex payment provider for this payment request. Used for reconciliation with the external provider. No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 4 | Amount | numeric(36,18) | YES | Fiat currency amount of the payment request (in the currency specified by FiatId). Always positive. Represents the amount the user is paying, not the crypto received. No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 5 | FiatId | int | YES | FK to EXW_Wallet.FiatTypes. Identifies the fiat currency used for the payment. 2=EUR (70%), 3=GBP (30%). No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 6 | CorrelationId | uniqueidentifier | YES | Correlation identifier linking this payment to the corresponding blockchain sent transaction in EXW_Wallet.SentTransactions (WHERE TransactionTypeId=7). Used in EXW_TransactionsView to join payment data to transaction outputs. No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 7 | Occurred | datetime2(7) | YES | Timestamp when the payment request was created. Range: 2019-01-29 to 2022-09-20. No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 8 | CryptoId | int | YES | FK to EXW_Wallet.CryptoTypes. Identifies the cryptocurrency being purchased. 1=BTC (71%), 2=ETH (15%), 6=LTC (5%), 21=XLM (4%), 4=XRP (3%), 3=BCH (2%). No NULLs observed. (Tier 3 — WalletDB.Wallet.Payments) |
| 9 | etr_y | varchar(max) | YES | ETL partition column: year of the ingestion date, added by the Generic Pipeline during data loading. Format: 'YYYY'. (Tier 2 — Generic Pipeline) |
| 10 | etr_ym | varchar(max) | YES | ETL partition column: year-month of the ingestion date, added by the Generic Pipeline during data loading. Format: 'YYYY-MM'. (Tier 2 — Generic Pipeline) |
| 11 | etr_ymd | varchar(max) | YES | ETL partition column: year-month-day of the ingestion date, added by the Generic Pipeline during data loading. Format: 'YYYY-MM-DD'. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| Id | WalletDB.Wallet.Payments | Id | Passthrough |
| WalletId | WalletDB.Wallet.Payments | WalletId | Passthrough |
| ProviderPaymentId | WalletDB.Wallet.Payments | ProviderPaymentId | Passthrough |
| Amount | WalletDB.Wallet.Payments | Amount | Passthrough |
| FiatId | WalletDB.Wallet.Payments | FiatId | Passthrough |
| CorrelationId | WalletDB.Wallet.Payments | CorrelationId | Passthrough |
| Occurred | WalletDB.Wallet.Payments | Occurred | Passthrough |
| CryptoId | WalletDB.Wallet.Payments | CryptoId | Passthrough |
| etr_y | Generic Pipeline | — | ETL-generated partition (year) |
| etr_ym | Generic Pipeline | — | ETL-generated partition (year-month) |
| etr_ymd | Generic Pipeline | — | ETL-generated partition (year-month-day) |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Payments (production, WalletDB server)
  |-- Generic Pipeline (Append, daily 1440 min, parquet) ---|
  v
Bronze/WalletDB/Wallet/Payments/ (Data Lake)
  |-- Generic Pipeline landing ---|
  v
EXW_Wallet.Payments (113,579 rows, frozen since 2022-09-20)
  |-- Downstream: EXW_dbo.EXW_FactPayments (SP joins Payments + PaymentTransactions + PaymentStatuses)
  |-- Downstream: EXW_Wallet.EXW_TransactionsView (payment_transactions CTE)
  |
  v
wallet.bronze_walletdb_wallet_payments (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| FiatId | EXW_Wallet.FiatTypes | Resolves fiat currency ID to name (2=EUR, 3=GBP) |
| CryptoId | EXW_Wallet.CryptoTypes | Resolves crypto currency ID to name (1=BTC, 2=ETH, etc.) |
| WalletId | EXW_Wallet.Wallets | Resolves wallet GUID to GCID (customer identity) |
| CorrelationId | EXW_Wallet.SentTransactions | Links to blockchain sent transaction (TransactionTypeId=7) |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Id | EXW_Wallet.PaymentTransactions | PaymentTransactions.PaymentId → Payments.Id; exchange rate, crypto amount, fees |
| Id | EXW_Wallet.PaymentStatuses | PaymentStatuses.PaymentId → Payments.Id; payment lifecycle status history |
| CorrelationId | EXW_Wallet.EXW_TransactionsView | payment_transactions CTE joins via SentTransactions.CorrelationId |
| (multiple) | EXW_dbo.EXW_FactPayments | Downstream fact table joining Payments + PaymentTransactions + PaymentStatuses |

---

## 7. Sample Queries

### 7.1 Payment Volume by Month and Fiat Currency

```sql
SELECT
    FORMAT(p.Occurred, 'yyyy-MM') AS PaymentMonth,
    ft.FiatName,
    COUNT(*) AS PaymentCount,
    SUM(p.Amount) AS TotalFiatAmount
FROM EXW_Wallet.Payments p
JOIN EXW_Wallet.FiatTypes ft ON ft.FiatId = p.FiatId
GROUP BY FORMAT(p.Occurred, 'yyyy-MM'), ft.FiatName
ORDER BY PaymentMonth DESC;
```

### 7.2 Payment Count by Cryptocurrency

```sql
SELECT
    ct.Name AS CryptoName,
    COUNT(*) AS PaymentCount,
    SUM(p.Amount) AS TotalFiatAmount,
    AVG(p.Amount) AS AvgFiatAmount
FROM EXW_Wallet.Payments p
JOIN EXW_Wallet.CryptoTypes ct ON ct.CryptoID = p.CryptoId
GROUP BY ct.Name
ORDER BY PaymentCount DESC;
```

### 7.3 Full Payment Details with Status and Transaction Info

```sql
SELECT
    p.Id AS PaymentId,
    w.Gcid AS GCID,
    ft.FiatName,
    p.Amount AS FiatAmount,
    ct.Name AS CryptoName,
    pt.Amount AS CryptoAmount,
    pt.ExchangeRate,
    pt.EtoroFeeCalculated,
    pt.ProviderFeeCalculated,
    ps.PaymentStatusId,
    p.Occurred AS PaymentDate
FROM EXW_Wallet.Payments p
JOIN EXW_Wallet.Wallets w ON w.WalletId = p.WalletId
JOIN EXW_Wallet.FiatTypes ft ON ft.FiatId = p.FiatId
JOIN EXW_Wallet.CryptoTypes ct ON ct.CryptoID = p.CryptoId
LEFT JOIN EXW_Wallet.PaymentTransactions pt ON pt.PaymentId = p.Id
LEFT JOIN (
    SELECT PaymentId, MAX(Id) AS LatestStatusId
    FROM EXW_Wallet.PaymentStatuses
    GROUP BY PaymentId
) latest ON latest.PaymentId = p.Id
LEFT JOIN EXW_Wallet.PaymentStatuses ps ON ps.Id = latest.LatestStatusId
WHERE p.Id = 123487;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 12/14*
*Tiers: 0 T1, 3 T2, 8 T3, 0 T4, 0 T5 | Elements: 11/11, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.Payments | Type: Table | Production Source: WalletDB.Wallet.Payments (Generic Pipeline)*
