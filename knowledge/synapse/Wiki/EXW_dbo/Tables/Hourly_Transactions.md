# EXW_dbo.Hourly_Transactions

> Hourly pre-aggregated rolling transaction log — one row per individual wallet transaction in the last 5 days, with an Activity label derived from TransactionTypeId. Rebuilt on every SP_EXW_Hourly run by TRUNCATE + INSERT. Serves Tableau KPI dashboards for near-real-time monitoring of wallet transaction flows (redemptions, funding, conversions, AML cashbacks). USD value is computed using per-hour crypto prices.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.External_WalletDB_Wallet_TransactionsView (live external view on WalletDB) |
| **Writer SP** | EXW_dbo.SP_EXW_Hourly |
| **Refresh** | Hourly — TRUNCATE + INSERT on each run; rolling 5-day window |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only Tableau feed |

---

## 1. Business Meaning

Hourly_Transactions is a near-real-time transaction monitoring table for the eToro Wallet, covering all completed wallet transactions from the last 5 days. It is rebuilt from scratch on every hourly SP_EXW_Hourly run. Each row corresponds to one transaction from the WalletDB transaction view, enriched with a human-readable Activity label and USD valuation at the per-hour price.

The table is designed for Tableau KPI operations dashboards — enabling the team to monitor real-time flows of redemptions, money-out, AML cashbacks, funding, and conversions. It does not replace the EXW_FactTransactions table (which is the permanent historical record) but provides a lower-latency snapshot with hourly price granularity.

---

## 2. Business Logic

### 2.1 Activity Classification

**What**: Transactions are classified into 7 activity categories based on TransactionTypeId.

**Columns Involved**: Activity, TransactionTypeId

**Rules**:
- `TransactionTypeId = 0` → 'Redeem Sent' (customer crypto withdrawal/redemption)
- `TransactionTypeId = 1` → 'Customer Money Out'
- `TransactionTypeId = 2` → 'AmlMoneyBack' (AML-related crypto return)
- `TransactionTypeId = 4` → 'Funding Sent' (crypto funding to customer wallet)
- `TransactionTypeId = 5` → 'Conversion Sent From Customer' (conversion outflow from customer wallet)
- `TransactionTypeId = 6` → 'Conversion Sent From Omnibus' (conversion outflow from omnibus wallet)
- All other TransactionTypeId values → 'Other'

### 2.2 Rolling 5-Day Window

**What**: Only transactions from the last 5 days are included; older data is dropped on each TRUNCATE.

**Columns Involved**: TransDate

**Rules**:
- Filter: `TransDate >= CAST(GETDATE()-5 AS DATE)` applied in each UNION ALL member of #txprep
- After TRUNCATE, only the rolling 5-day window is present
- Each hourly run shifts the window forward by the SP run frequency

### 2.3 Per-Hour USD Valuation

**What**: USD column uses hourly price granularity (unlike Hourly_CustomerBalances which uses daily prices).

**Columns Involved**: USD, Amount, TransDate

**Rules**:
- Price source: `#PerHourPrices` = UNION of:
  - EXW_Wallet.EXW_Price for the last 7 days (most recent per date), AND
  - Hourly rates from EXW_Currency.vInstrumentRatesForWeek (today and yesterday), with OUTER APPLY forward-fill for missing hours
- Join: `tv.CryptoId = PE.CryptoID AND tv.TransDate BETWEEN PE.DateFrom AND PE.DateTo`
- `USD = Amount × PE.AvgPrice` — NULL if no matching price bracket found (LEFT JOIN)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) — co-located with EXW_DimUser (HASH(GCID)), EXW_FactTransactions (HASH(GCID)) for JOIN performance. HEAP — no index; full table scan on date range filters. Given rolling 5-day window, table size is bounded.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All redemptions in last 5 days | `WHERE Activity = 'Redeem Sent'` |
| Transaction volume by type today | `WHERE CAST(TransDate AS DATE) = CAST(GETDATE() AS DATE) GROUP BY Activity` |
| USD value by crypto and activity | `GROUP BY Crypto, Activity, CAST(TransDate AS DATE) \| SUM(USD)` |
| AML money-back events | `WHERE Activity = 'AmlMoneyBack'` |
| Exclude failed transactions | `WHERE TransStatusId = 2` (check TransStatus values for your environment) |

### 3.3 Gotchas

- **`ReciverAddress` is a typo**: The column is spelled "Reciver" (one 'e') in both DDL and SP — this is a known defect inherited from the source view; use `[ReciverAddress]` when querying
- **TRUNCATE on each hourly run**: No data older than ~5 days is retained. For historical transaction data, use EXW_dbo.EXW_FactTransactions
- **'Other' catch-all**: Any TransactionTypeId not in (0,1,2,4,5,6) is classified as 'Other' — this includes new transaction types that may be added to the Wallet without a corresponding update to the SP classification CASE
- **USD can be NULL**: LEFT JOIN on per-hour price; transactions for cryptos without a matching price bracket will have NULL USD
- **TransDate filter, not Occurred**: The rolling window is based on TransDate (the transaction execution time), not Occurred (the settlement/block time). These may differ for blockchain transactions
- **Not de-duplicated**: All rows from the external view are inserted; if the view contains duplicates, they appear here

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — passthrough from external view or SP-computed |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Activity | nvarchar(1000) | NULL | Human-readable transaction category derived from TransactionTypeId: 'Redeem Sent' (0), 'Customer Money Out' (1), 'AmlMoneyBack' (2), 'Funding Sent' (4), 'Conversion Sent From Customer' (5), 'Conversion Sent From Omnibus' (6), 'Other' (all remaining IDs). (Tier 2 — SP_EXW_Hourly) |
| 2 | GCID | int | NULL | Wallet customer identifier from External_WalletDB_Wallet_TransactionsView.gcid. Distribution key. (Tier 2 — SP_EXW_Hourly) |
| 3 | CryptoId | int | NULL | Cryptocurrency identifier. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 4 | WalletId | nvarchar(max) | NULL | Customer wallet GUID. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 5 | TranID | int | NULL | Transaction identifier from WalletDB. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 6 | TransStatusId | int | NULL | Transaction status code. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 7 | TransStatus | varchar(54) | NULL | Transaction status label. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 8 | TransDate | datetime | NULL | Transaction execution datetime. Filter: >= CAST(GETDATE()-5 AS DATE) (rolling 5-day window). (Tier 2 — SP_EXW_Hourly) |
| 9 | Amount | decimal(38,8) | NULL | Transaction amount in native crypto units. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 10 | USD | decimal(38,8) | NULL | USD value of transaction: Amount × #PerHourPrices.AvgPrice for the CryptoId at TransDate hour. NULL if no per-hour price found. (Tier 2 — SP_EXW_Hourly) |
| 11 | ActionTypeName | varchar(128) | NULL | Action type label from WalletDB. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 12 | SenderAddress | nvarchar(max) | NULL | Blockchain sender address. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 13 | ReciverAddress | nvarchar(max) | NULL | Blockchain receiver address. Note: column name is a persistent typo ('Reciver' not 'Receiver') inherited from source view — always use bracket-quoting. (Tier 2 — SP_EXW_Hourly) |
| 14 | BlockchainTransactionId | nvarchar(max) | NULL | On-chain transaction hash. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 15 | TransactionTypeId | int | NULL | Numeric transaction type code used to derive Activity. Values: 0=Redeem, 1=MoneyOut, 2=AmlBack, 4=Funding, 5=ConvFromCustomer, 6=ConvFromOmnibus; other IDs classified as 'Other'. (Tier 2 — SP_EXW_Hourly) |
| 16 | TransactionType | varchar(256) | NULL | Transaction type label from WalletDB. Passthrough from External_WalletDB_Wallet_TransactionsView. (Tier 2 — SP_EXW_Hourly) |
| 17 | Occurred | datetime | NULL | Settlement/confirmation datetime from WalletDB (distinct from TransDate — may differ for blockchain transactions). Passthrough. (Tier 2 — SP_EXW_Hourly) |
| 18 | Crypto | varchar(256) | NULL | Cryptocurrency short name from EXW_Wallet.CryptoTypes.Name, joined on CryptoId (e.g., BTC, ETH). (Tier 2 — SP_EXW_Hourly) |
| 19 | DisplayName | varchar(256) | NULL | Cryptocurrency display name from EXW_Wallet.CryptoTypes.DisplayName. (Tier 2 — SP_EXW_Hourly) |
| 20 | CryptoCategoryName | varchar(256) | NULL | Cryptocurrency category from EXW_Wallet.CryptoTypes.CryptoCategoryName (e.g., Layer1, DeFi, Stablecoin). (Tier 2 — SP_EXW_Hourly) |
| 21 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the specific hourly SP run that produced this row. (Tier 2 — SP_EXW_Hourly) |

---

## 5. Lineage

See [Hourly_Transactions.lineage.md](Hourly_Transactions.lineage.md) for full column-level lineage.

---

## 6. Data Quality Notes

- `ReciverAddress` typo is baked into DDL and SP — cannot be corrected without ALTER TABLE + SP change
- Rolling window means no data retention beyond ~5 days; use EXW_FactTransactions for historical queries
- 'Other' category may grow over time as new TransactionTypeId values are added to WalletDB without SP updates

---

## 7. Open Questions / Review Needed

See [Hourly_Transactions.review-needed.md](Hourly_Transactions.review-needed.md).

---

## 8. Tier Footer

| Tier | Count | Columns |
|---|---|---|
| Tier 2 | 21 | All columns — passthrough from external WalletDB view or SP-computed |
