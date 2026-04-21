# EXW_dbo.EXW_ETH_FeeData_Blockchain

> 402,288-row staging table of raw Ethereum blockchain transaction fee records for the eToro hot wallet (`0x8c4b7870fc7dff2cb1e854858533ceddaf3eebf4`), sourced from an Etherscan export maintained in a Fivetran-connected Google Sheet. Each row represents one blockchain transaction that the eToro smart-contract wallet participated in, covering 2022-01-01 through 2024-09-09. All 18 columns are nvarchar/varchar — numeric values are stored as strings and require explicit CAST before arithmetic. Loaded via delta UPSERT (INSERT new txhash + UPDATE existing) by SP_EXW_ETH_FeeData_Blockchain. Primary consumer: SP_EXW_EthFeeSent_Blockchain for ETH fee analytics.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Etherscan ETH blockchain export → Google Sheets → Fivetran → BI_DB_dbo.External_Fivetran_google_sheets_eth_fee_data_blockchain |
| **Refresh** | Delta UPSERT via SP_EXW_ETH_FeeData_Blockchain — INSERT new txhash + UPDATE changed rows (no date parameter) |
| **Synapse Distribution** | HASH(txhash) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_ETH_FeeData_Blockchain is the raw Ethereum blockchain fee ledger for eToro's ETH hot wallet. It tracks every on-chain ETH transaction in which the eToro multi-sig wallet (`from = 0x8c4b7870fc7dff2cb1e854858533ceddaf3eebf4`) participated — including wallet creations, user send-outs, multi-sig token transfers, and forwarder flushes. The data is manually exported from Etherscan and loaded into Synapse via a Google Sheet maintained by the analytics team (Fivetran-synced).

The table has 402,288 rows covering 2022-01-01 to 2024-09-09. Key characteristics:
- **All fee and value columns are nvarchar** — Etherscan exports numeric data as strings, which persists through the Fivetran → Google Sheet pipeline. SP_EXW_EthFeeSent_Blockchain applies a 2-step `CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY)` to convert fees for use.
- The `method` field (added 2022-03-22) is NULL for 191,869 rows (47%) — transactions predating the method tracking update have no function signature recorded.
- 5 distinct transaction types are recorded in `method` — dominated by "Send Multi Sig" (81%).
- `status` is mostly blank (success), with 2,090 "Error(0)" rows representing failed or zero-fee transactions.

---

## 2. Business Logic

### 2.1 Delta UPSERT Load Pattern

**What**: The SP loads new blockchain transactions by txhash and updates changed records.

**Columns Involved**: `txhash`, `UpdateDate`

**Rules**:
- INSERT step: SELECT FROM Fivetran external table LEFT JOIN EXW_ETH_FeeData_Blockchain WHERE existing txhash IS NULL → adds net-new transactions only.
- UPDATE step: JOIN ON txhash → overwrites all columns for existing rows (in case Etherscan data corrections propagate through the Sheet).
- `txhash` uses `COLLATE SQL_Latin1_General_CP1_CI_AS` in JOIN conditions to handle encoding mismatches between the nvarchar Fivetran source and the target nvarchar(1200) column.
- No date parameter — runs as a perpetual delta; older rows retain their original `UpdateDate` from the time of first insert.

### 2.2 Transaction Method Classification

**What**: The `method` column identifies the Ethereum function signature for each transaction.

**Columns Involved**: `method`, `contract_address`

**Rules**:
- "Send Multi Sig": 170,330 rows (81% of non-NULL) — ETH-native transfers from the eToro multi-sig wallet.
- "Create Wallet": 25,261 rows (12%) — contract deployment (smart wallet creation) — `contract_address` is populated for these rows.
- "Send Multi Sig Token": 14,756 rows (7%) — ERC-20 token transfers.
- "Transfer": 70 rows (<0.1%) — direct ETH transfer.
- "Flush Forwarder Tokens": 2 rows — routing tokens from forwarding contracts back to the main wallet.
- NULL: 191,869 rows — predates method tracking (2022-03-22 addition). SP_EXW_EthFeeSent_Blockchain uses `contract_address IS NOT NULL OR method = 'Create Wallet'` to detect wallet creation for both old and new records.

### 2.3 String-Numeric Encoding (All Fee/Value Columns)

**What**: All Etherscan numeric exports remain as nvarchar — downstream consumers must CAST before arithmetic.

**Columns Involved**: `txn_fee_eth`, `historical_price_eth`, `txn_fee_usd`, `value_in_eth`, `value_out_eth`, `current_value_eth`

**Rules**:
- Correct cast pattern (used by SP_EXW_EthFeeSent_Blockchain): `CAST(CAST(col AS FLOAT) AS MONEY)` — direct CAST to MONEY fails due to scientific notation (e.g., `2.87154e-005`).
- `value_in_eth`, `value_out_eth`, `current_value_eth` = `0` for nearly all rows in the sample — these columns track ETH value transferred, not fees. For eToro's smart-contract wallet operations, the ETH value is typically 0 (fees are the only cost).
- Source column `current_value_411_37_eth` was renamed to `current_value_eth` — the original name was a snapshot-specific ETH/USD rate label from Etherscan export naming conventions.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(txhash) with HEAP. The txhash is a 66-character hex string — good for uniqueness but queries filtering on date, method, or address require full distribution scans. For analytic queries over time ranges, SP_EXW_EthFeeSent_Blockchain (which pre-aggregates by date and GCID) is the recommended analytical layer.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| ETH fee analytics by date | Use EXW_dbo.EXW_EthFeeSent_Blockchain (pre-aggregated, documented) |
| Total fees for a specific txhash | `SELECT txhash, CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY) AS fee FROM EXW_ETH_FeeData_Blockchain WHERE txhash = '0x...'` |
| Wallet creation count by month | `SELECT YEAR(TRY_CAST(date_time AS datetime)) AS yr, MONTH(TRY_CAST(date_time AS datetime)) AS mo, COUNT(*) FROM EXW_ETH_FeeData_Blockchain WHERE method = 'Create Wallet' OR contract_address IS NOT NULL GROUP BY YEAR(TRY_CAST(date_time AS datetime)), MONTH(TRY_CAST(date_time AS datetime))` |
| Failed transactions | `SELECT * FROM EXW_ETH_FeeData_Blockchain WHERE status = 'Error(0)'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.EXW_EthFeeSent_Blockchain | `txhash = BlockchainTransactionID` | Match raw fee record to enriched analytics record |
| EXW_dbo.EXW_FactTransactions | `txhash = BlockchainTransactionId` | Link blockchain record to internal wallet transaction |

### 3.4 Gotchas

- **All numeric columns are nvarchar** — always CAST through FLOAT before MONEY/DECIMAL. `CAST(col AS DECIMAL)` fails on scientific notation like `2.87154e-005`.
- **`date_time` is nvarchar(256)** — use `TRY_CAST(date_time AS datetime)` for date filtering; direct WHERE date_time > '2023-01-01' is a string comparison.
- **`method` NULL ≠ "no method"** — NULL means the record predates 2022-03-22 method tracking, not that the transaction had no function. Use `contract_address IS NOT NULL OR method = 'Create Wallet'` to detect wallet creation across all periods.
- **`from` is a reserved SQL keyword** — always quote with brackets: `[from]`.
- **`status` is not properly normalized**: blank string vs NULL — both mean success. `WHERE status != 'Error(0)'` captures all non-error rows but includes both blank and NULL status.
- **Data is manual/semi-automated** — the Etherscan → Google Sheet → Fivetran pipeline is not fully automated. Date coverage (2022–2024) may have gaps if the Google Sheet was not updated regularly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream wiki (WalletDB, DB_Schema) |
| Tier 2 | Sourced from SP code / DWH computation / external source without wiki |
| Tier 3 | Inferred from column name + context |
| Tier 4 | Best available (limited confidence) |
| Tier 5 | Glossary / domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | txhash | nvarchar(1200) | YES | Ethereum transaction hash — 66-character hex string (0x-prefixed). Unique identifier for each blockchain transaction. Primary key for UPSERT operations; HASH distribution key. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 2 | date_time | nvarchar(256) | YES | Blockchain transaction timestamp as a string. Covers 2022-01-01 to 2024-09-09. Stored as nvarchar — use TRY_CAST to datetime for date arithmetic. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 3 | unix_timestamp | nvarchar(256) | YES | Unix epoch timestamp of the blockchain transaction (seconds since 1970-01-01). Stored as nvarchar. Alternative to date_time for precise timestamp comparisons. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 4 | blockno | nvarchar(256) | YES | Ethereum block number in which the transaction was confirmed. Stored as nvarchar. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 5 | txn_fee_eth | nvarchar(256) | YES | Transaction fee paid in ETH (gas cost). Stored as nvarchar — may use scientific notation (e.g., '2.87154e-005'). Cast pattern: CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY). Source column: txn_fee_eth_ (trailing underscore stripped in DWH). (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 6 | historical_price_eth | nvarchar(256) | YES | USD price of ETH at the time of the transaction (Etherscan historical price). Stored as nvarchar. Used with txn_fee_eth to compute txn_fee_usd. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 7 | txn_fee_usd | nvarchar(256) | YES | Transaction fee in USD (txn_fee_eth × historical_price_eth). Stored as nvarchar — apply same CAST-through-FLOAT pattern before arithmetic. Source column: txn_fee_usd_ (trailing underscore stripped). (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 8 | value_in_eth | nvarchar(256) | YES | ETH value received by the eToro wallet in this transaction. Stored as nvarchar. Near-zero for fee-only operations. Source column: value_in_eth_ (trailing underscore stripped). (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 9 | value_out_eth | nvarchar(256) | YES | ETH value sent from the eToro wallet in this transaction. Stored as nvarchar. Near-zero for fee-only smart-contract operations. Source column: value_out_eth_ (trailing underscore stripped). (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 10 | current_value_eth | nvarchar(256) | YES | ETH/USD rate at the time of the Etherscan export snapshot (not at transaction time). Column was originally named current_value_411_37_eth in the Google Sheet (snapshot-specific naming). Use historical_price_eth for the transaction-time price. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 11 | from | nvarchar(max) | YES | Ethereum address of the transaction sender. For all rows in this dataset: the eToro hot wallet address (0x8c4b7870fc7dff2cb1e854858533ceddaf3eebf4). SQL reserved word — must be quoted as [from] in all queries. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 12 | to | nvarchar(max) | YES | Ethereum address of the transaction recipient. Each unique 'to' address is a user wallet (contract address). SQL reserved word — must be quoted as [to] in all queries. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 13 | contract_address | nvarchar(max) | YES | Deployed contract address when the transaction creates a new smart wallet. Non-NULL only for 'Create Wallet' transactions; NULL for transfers and other operations. Used with method to detect wallet creation events (method='Create Wallet' OR contract_address IS NOT NULL). (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 14 | err_code | nvarchar(256) | YES | Etherscan error code if the transaction reverted. NULL for successful transactions. Rarely populated — most error information is captured via the status column. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 15 | fivetran_synced | datetime | YES | Fivetran sync timestamp — when this row was last written to the Google Sheet-backed staging layer. Source column: _fivetran_synced (leading underscore stripped). Useful for identifying freshness of individual records. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 16 | status | nvarchar(256) | YES | Transaction status from Etherscan. Blank string = success; 'Error(0)' = failed/zero-fee transaction (2,090 rows, 0.5%). May also contain NULL. Do not use IS NULL as the only success filter — include blank string check: WHERE ISNULL(status,'') != 'Error(0)'. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 17 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at time of SP execution for newly inserted rows. Retained as-is for updated rows. Older rows may have UpdateDate from 2020 (initial loads). (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |
| 18 | method | varchar(256) | YES | Ethereum function signature identifying the transaction type. Values: 'Send Multi Sig'=bulk ETH transfer from multi-sig wallet, 'Create Wallet'=smart-contract wallet deployment (contract_address populated), 'Send Multi Sig Token'=ERC-20 token transfer, 'Transfer'=direct ETH transfer, 'Flush Forwarder Tokens'=route tokens back to main wallet. NULL for rows predating 2022-03-22 method field addition — use contract_address IS NOT NULL as fallback for wallet creation detection. (Tier 2 — SP_EXW_ETH_FeeData_Blockchain) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| txhash | Etherscan blockchain (eToro hot wallet) | Transaction Hash | Passthrough via Google Sheets → Fivetran |
| date_time | Etherscan blockchain | DateTime | Passthrough |
| unix_timestamp | Etherscan blockchain | UnixTimestamp | Passthrough |
| blockno | Etherscan blockchain | Blockno | Passthrough |
| txn_fee_eth | Etherscan blockchain | Txn Fee (ETH) | Rename from txn_fee_eth_ |
| txn_fee_usd | Etherscan blockchain | Txn Fee (USD) | Rename from txn_fee_usd_ |
| historical_price_eth | Etherscan blockchain | Historical $Price/ETH | Passthrough |
| current_value_eth | Etherscan blockchain | Current Value @ $411.37/Eth | Rename from current_value_411_37_eth |
| method | Etherscan blockchain | Method | Added 2022-03-22; NULL for older rows |
| fivetran_synced | Fivetran | _fivetran_synced | Rename (_ prefix stripped) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
Etherscan ETH Blockchain (eToro hot wallet: 0x8c4b7870fc7dff2cb1e854858533ceddaf3eebf4)
  |-- Manual export to Google Sheets ---|
  v
Google Sheets (Etherscan fee data)
  |-- Fivetran sync ---|
  v
BI_DB_dbo.External_Fivetran_google_sheets_eth_fee_data_blockchain
  |-- SP_EXW_ETH_FeeData_Blockchain
  |   UPSERT: INSERT new txhash + UPDATE existing
  |   6 column renames + UpdateDate = GETDATE() ---|
  v
EXW_dbo.EXW_ETH_FeeData_Blockchain (402,288 rows, 2022–2024)
  |-- SP_EXW_EthFeeSent_Blockchain (@d DATE, CAST-through-FLOAT for fees) ---|
  v
EXW_dbo.EXW_EthFeeSent_Blockchain (documented, Batch 5)
  |-- (no UC migration) ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| txhash | Ethereum blockchain | On-chain reference to raw ETH transaction |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|---|---|
| EXW_dbo.EXW_EthFeeSent_Blockchain | SP_EXW_EthFeeSent_Blockchain reads txhash, date_time, contract_address, method, txn_fee_eth, txn_fee_usd to produce ETH fee analytics with GCID enrichment |

---

## 7. Sample Queries

### Total ETH fees for wallet creation transactions

```sql
SELECT
    YEAR(TRY_CAST(date_time AS datetime))  AS yr,
    MONTH(TRY_CAST(date_time AS datetime)) AS mo,
    COUNT(*)                                AS WalletCreations,
    SUM(CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY)) AS TotalFeeETH,
    SUM(CAST(CAST(txn_fee_usd AS FLOAT) AS MONEY)) AS TotalFeeUSD
FROM [EXW_dbo].[EXW_ETH_FeeData_Blockchain]
WHERE method = 'Create Wallet' OR contract_address IS NOT NULL
GROUP BY
    YEAR(TRY_CAST(date_time AS datetime)),
    MONTH(TRY_CAST(date_time AS datetime))
ORDER BY yr, mo;
```

### Lookup a specific transaction by hash

```sql
SELECT
    txhash,
    date_time,
    blockno,
    CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY)   AS fee_eth,
    CAST(CAST(txn_fee_usd AS FLOAT) AS MONEY)   AS fee_usd,
    [from],
    [to],
    method,
    status
FROM [EXW_dbo].[EXW_ETH_FeeData_Blockchain]
WHERE txhash = '0xabc123...';
```

### Failed transactions summary

```sql
SELECT
    status,
    COUNT(*) AS cnt,
    SUM(CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY)) AS TotalFeeETH
FROM [EXW_dbo].[EXW_ETH_FeeData_Blockchain]
WHERE status = 'Error(0)'
GROUP BY status;
```

---

## 8. Atlassian Knowledge Sources

No Jira issues or Confluence pages identified for this table. SP header: Author Inessa Kontorovich, original 2020-04-12 (description says inventory but code confirms ETH fee data), `method` field added 2022-03-22, Synapse migration 2024-03-14.

---

*Generated: 2026-04-20 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 0 T5 | Elements: 18/18, Logic: 8/10, Lineage: full*
*Object: EXW_dbo.EXW_ETH_FeeData_Blockchain | Type: Table | Production Source: Etherscan → Google Sheets → Fivetran → BI_DB_dbo.External_Fivetran*
