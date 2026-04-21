# EXW_dbo.EXW_EthFeeSent_Blockchain

> ETH blockchain fee attribution table — 338,404 rows (2021-01-01 to 2026-03-09) linking each Ethereum on-chain transaction to the responsible eToro wallet user, transaction type, and country/regulation context. Each row represents one ETH blockchain transaction where a gas fee was incurred, enriched with wallet-side classification (Activity) and user identity from EXW_FactTransactions.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.EXW_ETH_FeeData_Blockchain (Etherscan import) + EXW_dbo.EXW_FactTransactions |
| **Refresh** | Daily — SP_EXW_EthFeeSent_Blockchain(@d date); missing-date detection strategy (fills gaps beyond @d) |
| **Row Count** | 338,404 (2021-01-01 to 2026-03-09) |
| **Data Coverage** | ETH blockchain transactions from Jan 2021 to present |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only operational table |

---

## 1. Business Meaning

EXW_EthFeeSent_Blockchain attributes each Ethereum blockchain gas fee transaction to a specific wallet user and transaction type. It joins Etherscan-sourced fee data (EXW_ETH_FeeData_Blockchain) with wallet transactions (EXW_FactTransactions) using the blockchain transaction hash (txhash = BlockchainTransactionId) to produce an analyst-friendly view of who paid ETH gas fees, for what purpose, and at what cost.

Activity distribution (338,404 rows total): User Send Out=134,697 (39.8%), Coin Transfer=131,642 (38.9%), Wallet Creation=25,713 (7.6%), Conversion In=11,977 (3.5%), Conversion Out=9,351 (2.8%), Not Exist on Wallet=8,978 (2.7%), ManualUserMoneyOut=6,467 (1.9%), ConversionToFiat=5,464 (1.6%), Staking=2,140 (0.6%), Payment=1,832 (0.5%), AML Money Back=119, Other=24.

The "Not Exist on Wallet" category (8,978 rows) represents Etherscan-logged transactions where no matching record was found in EXW_FactTransactions — likely due to timing gaps, orphaned blockchain transactions, or pre-wallet-system transactions.

**GCIDUnion** is a critical derived column: when the on-chain sender is the omnibus wallet (GCID=0 in EXW_FactTransactions), it resolves to the receiver's GCID via address matching in EXW_Wallet.CustomerWalletsView. This ensures country/regulation enrichment is still possible for omnibus-sent transactions.

---

## 2. Business Logic

### 2.1 Missing Date Detection and Backfill

**What**: The SP does not blindly reload @d — it detects which dates in EXW_ETH_FeeData_Blockchain are not yet represented in EXW_EthFeeSent_Blockchain (including @d if already partially loaded).

**Columns Involved**: Date, txhash

**Rules**:
- Build #missingdates: dates in ETH_FeeData_Blockchain after 2020-12-31 with no corresponding date in EthFeeSent, OR where date = @d
- @TXBeginDate = MIN(#missingdates) - 5 days — extended lookback for wallet transactions to handle late-arriving blockchain fee data
- DELETE existing rows for #missingdates, then INSERT #temp

### 2.2 GCIDUnion Omnibus Resolution

**What**: Resolves the true user GCID when the sender is the eToro omnibus wallet.

**Columns Involved**: GCID, GCIDUnion

**Rules**:
- CASE WHEN GCID > 0 THEN GCID (real user sender)
- WHEN GCID = 0 THEN CustomerWalletsView.Gcid WHERE Address = ReciverAddress (receiver = the actual end-user for omnibus-sent transactions such as conversions)
- GCIDUnion is used for all country/regulation JOINs downstream

### 2.3 Country/Regulation Snapshot Enrichment

**What**: Country and regulation are resolved at the transaction date, not current state.

**Columns Involved**: CountryID, Country, RegulationID, Regulation

**Rules**:
- JOIN EXW_DimUser ON GCIDUnion → get RealCID
- LEFT JOIN Fact_SnapshotCustomer ON RealCID
- JOIN Dim_Range ON DateRangeID AND TranDateID BETWEEN FromDateID AND ToDateID
- JOIN Dim_Country ON CountryID; JOIN Dim_Regulation ON RegulationID
- Country/Regulation reflect the user's regulatory state at TranDate (SCD Type 2 snapshot)

### 2.4 Activity Classification

**What**: Classifies each ETH fee transaction into a human-readable activity type.

**Columns Involved**: Activity, TransactionTypeID, contract_address, method

**Rules**:
- 0 → 'Coin Transfer'
- 1 → 'User Send Out' (excludes omnibus)
- 2 → 'AML Money Back'
- 4 → 'Funding'
- 5 → 'Conversion In -Customer Send To Omnibus'
- 6 → 'Conversion Out -Omnibus send to Customer'
- 7 → 'Payment'
- 9 → 'Staking'
- contract_address IS NOT NULL OR method='Create Wallet' → 'Wallet Creation'
- BlockchainTransactionId IS NULL → 'Not Exist on Wallet'
- Else → TransactionType (raw string)

### 2.5 Fee Cast Fix (2024-08)

**What**: Prevents type conversion failures when Etherscan imports txn_fee_eth as varchar.

**Columns Involved**: txn_fee_eth

**Rules**:
- CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY) — two-step cast handles scientific notation and edge values that cannot be cast directly to MONEY

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID), HEAP. Joins to EXW_DimUser (HASH(GCID)) and EXW_FactTransactions (HASH(GCID)) are colocation-eligible. No CCI — full scans for large date ranges will be slow. Always filter on Date or TranDate.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| ETH gas fees paid by users in a period | `WHERE Date BETWEEN @start AND @end AND Activity != 'Not Exist on Wallet'` |
| Wallet creation gas costs | `WHERE Activity = 'Wallet Creation' AND Date >= @start` |
| Gas fees by country | `GROUP BY Country, Regulation ORDER BY SUM(txn_fee_eth*historical_price_eth) DESC` |
| Omnibus-resolved vs direct user fees | `WHERE GCIDUnion != GCID` for omnibus-resolved rows |

### 3.3 Gotchas

- **GCID vs GCIDUnion**: Use GCIDUnion for user identification and country/regulation JOINs. GCID=0 for omnibus-sender rows; GCIDUnion is always the attributable user.
- **date_time is nvarchar**: Do not cast directly to DATETIME — use Date (pre-cast) or TranDate for filtering.
- **TranDate/TranDateID are NULL** when the blockchain tx is not in EXW_FactTransactions ('Not Exist on Wallet' rows). Filter these out if joining to wallet tables.
- **historical_price_eth is Etherscan-sourced**: Not from EXW_Wallet.EXW_Price. Do not cross-reference with internal price tables.
- **5-day lookback**: SP_EXW_EthFeeSent_Blockchain starts @TXBeginDate = MIN(missing date) - 5 days for wallet transactions. This means a row's TranDate may predate Date by up to 5 days.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | txhash | nvarchar(512) | YES | Ethereum blockchain transaction hash from Etherscan. Primary JOIN key to EXW_FactTransactions.BlockchainTransactionId. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 2 | date_time | nvarchar(256) | YES | Raw timestamp string as imported from Etherscan — stored as nvarchar, not cast to datetime. Use Date or TranDate for time-based filtering. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 3 | Date | date | YES | Blockchain confirmation date: CAST(date_time AS DATE). Represents when Etherscan recorded the transaction. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 4 | TranDate | date | YES | Wallet transaction date from EXW_FactTransactions.TranDate. May differ from Date by up to 5 days due to SP lookback window. NULL for 'Not Exist on Wallet' rows. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 5 | TranDateID | bigint | YES | YYYYMMDD integer form of TranDate. NULL if TranDate is NULL. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 6 | txn_fee_eth | money(19,4) | YES | ETH gas fee amount as reported by Etherscan. CAST(CAST(source AS FLOAT) AS MONEY) to handle varchar imports. Multiply by historical_price_eth to get USD cost. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 7 | historical_price_eth | money(19,4) | YES | ETH/USD price at time of transaction from Etherscan. Etherscan-sourced; not from internal EXW_Wallet.EXW_Price table. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 8 | GCID | int | YES | Wallet user's GCID from EXW_FactTransactions. 0 for omnibus-sender transactions. Use GCIDUnion for user attribution. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 9 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Enriched by JOIN to EXW_DimUser on GCID. Source: EXW_DimUser.RealCID via GCIDUnion. (Tier 1 — Customer.CustomerStatic) |
| 10 | BlockchainFees | numeric(38,8) | YES | On-chain blockchain fee in native crypto units from EXW_FactTransactions. Distinct from txn_fee_eth (Etherscan-reported ETH amount). (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 11 | contract_address | nvarchar(512) | YES | Ethereum smart contract address if the transaction created a wallet. Non-NULL indicates a Wallet Creation transaction. NULL for regular transfers. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 12 | GCIDUnion | bigint | YES | Resolved GCID for user attribution. CASE: GCID>0→GCID (real sender); GCID=0→receiver's GCID via CustomerWalletsView.Address lookup (omnibus resolution). Use this for all user-level analysis. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 13 | CountryID | int | YES | Country ID from DWH_dbo.Dim_Country, resolved at TranDate via date-range snapshot (Fact_SnapshotCustomer + Dim_Range). (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 14 | Country | varchar(50) | YES | Country name from DWH_dbo.Dim_Country.Name, resolved at TranDate. Reflects user's country at time of transaction (not current). (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 15 | RegulationID | int | YES | Regulation ID from DWH_dbo.Dim_Regulation, resolved at TranDate. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 16 | Regulation | varchar(50) | YES | Regulation entity name from DWH_dbo.Dim_Regulation.Name, resolved at TranDate. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 17 | Activity | varchar(256) | NO | Transaction type classification. Values: 'User Send Out', 'Coin Transfer', 'Wallet Creation', 'Conversion In -Customer Send To Omnibus', 'Conversion Out -Omnibus send to Customer', 'Not Exist on Wallet', 'ManualUserMoneyOut', 'ConversionToFiat', 'Staking', 'Payment', 'AML Money Back', 'Other'. NOT NULL. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 18 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at SP run time. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |
| 19 | method | varchar(128) | YES | Ethereum transaction method from Etherscan (e.g., 'Create Wallet' for wallet creation transactions). NULL for standard ETH transfers. Used in Activity CASE for Wallet Creation detection. (Tier 2 — SP_EXW_EthFeeSent_Blockchain) |

---

## 5. Lineage

### 5.1 Production Sources

| Table Column | Source Object | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| txhash | EXW_dbo.EXW_ETH_FeeData_Blockchain | txhash | Passthrough |
| date_time | EXW_dbo.EXW_ETH_FeeData_Blockchain | date_time | Passthrough |
| Date | EXW_dbo.EXW_ETH_FeeData_Blockchain | date_time | CAST AS DATE |
| TranDate | EXW_dbo.EXW_FactTransactions | TranDate | JOIN on txhash=BlockchainTransactionId |
| TranDateID | EXW_dbo.EXW_FactTransactions | TranDateID | JOIN |
| txn_fee_eth | EXW_dbo.EXW_ETH_FeeData_Blockchain | txn_fee_eth | CAST(CAST(…AS FLOAT) AS MONEY) |
| historical_price_eth | EXW_dbo.EXW_ETH_FeeData_Blockchain | historical_price_eth | CAST AS MONEY |
| GCID | EXW_dbo.EXW_FactTransactions | GCID | Passthrough |
| RealCID | EXW_dbo.EXW_DimUser | RealCID | JOIN via GCIDUnion |
| BlockchainFees | EXW_dbo.EXW_FactTransactions | BlockchainFees | Passthrough |
| contract_address | EXW_dbo.EXW_ETH_FeeData_Blockchain | contract_address | Passthrough |
| GCIDUnion | EXW_FactTransactions / CustomerWalletsView | GCID / Gcid | CASE omnibus resolution |
| CountryID | DWH_dbo.Dim_Country | CountryID | Via snapshot |
| Country | DWH_dbo.Dim_Country | Name | Via snapshot |
| RegulationID | DWH_dbo.Dim_Regulation | DWHRegulationID | Via snapshot |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via snapshot |
| Activity | EXW_dbo.EXW_FactTransactions | TransactionTypeID + contract_address + method | CASE classification |
| UpdateDate | (computed) | — | GETDATE() |
| method | EXW_dbo.EXW_ETH_FeeData_Blockchain | method | Passthrough |

### 5.2 ETL Flow Diagram

```
EXW_dbo.EXW_ETH_FeeData_Blockchain (Etherscan import)
  |-- txhash, date_time, txn_fee_eth, historical_price_eth, contract_address, method
  |
  LEFT JOIN EXW_dbo.EXW_FactTransactions (ActionTypeID=1, BlockchainCryptoId=2, BlockchainFees>0)
  |  ON txhash = BlockchainTransactionId
  |  |-- GCID, TranDate, TranDateID, TransactionTypeID, BlockchainFees
  |  |-- GCIDUnion: CASE WHEN GCID>0 THEN GCID
  |               ELSE CustomerWalletsView.Gcid (receiver address match)
  |
  JOIN EXW_dbo.EXW_DimUser ON GCIDUnion → RealCID
  LEFT JOIN DWH_dbo.Fact_SnapshotCustomer + Dim_Range → snapshot at TranDate
       → Dim_Country (Country, CountryID)
       → Dim_Regulation (Regulation, RegulationID)
  v
EXW_dbo.EXW_EthFeeSent_Blockchain (19 columns, 338,404 rows)
  |-- Finance/AML analyst ETH fee attribution queries
  |-- No SSDT-tracked downstream consumers
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| txhash | EXW_dbo.EXW_ETH_FeeData_Blockchain | Etherscan blockchain fee source |
| GCID / BlockchainFees | EXW_dbo.EXW_FactTransactions | Wallet transaction enrichment |
| GCIDUnion (omnibus) | EXW_Wallet.CustomerWalletsView | Receiver GCID resolution |
| RealCID | EXW_dbo.EXW_DimUser | Customer ID bridge |
| Country/Regulation | DWH_dbo.Fact_SnapshotCustomer + Dim_Range | Date-range snapshot |
| Country | DWH_dbo.Dim_Country | Country name |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| Direct analyst queries | ETH fee attribution, gas cost analysis, wallet creation fee tracking |
| No SSDT-tracked SP consumers | Leaf node in the EXW_dbo dependency graph |

---

## 7. Sample Queries

### ETH gas cost by activity type for a date range

```sql
SELECT
    Activity,
    COUNT(*) AS Transactions,
    SUM(txn_fee_eth) AS TotalFeeETH,
    SUM(txn_fee_eth * historical_price_eth) AS TotalFeeUSD
FROM EXW_dbo.EXW_EthFeeSent_Blockchain
WHERE Date BETWEEN '2025-01-01' AND '2025-12-31'
  AND Activity != 'Not Exist on Wallet'
GROUP BY Activity
ORDER BY TotalFeeUSD DESC;
```

### Wallet creation gas fees by country

```sql
SELECT
    Country,
    COUNT(*) AS WalletCreations,
    SUM(txn_fee_eth * historical_price_eth) AS TotalCreationFeeUSD
FROM EXW_dbo.EXW_EthFeeSent_Blockchain
WHERE Activity = 'Wallet Creation'
  AND Date >= '2024-01-01'
GROUP BY Country
ORDER BY WalletCreations DESC;
```

### Unmatched blockchain transactions (gap analysis)

```sql
SELECT Date, COUNT(*) AS UnmatchedTxns
FROM EXW_dbo.EXW_EthFeeSent_Blockchain
WHERE Activity = 'Not Exist on Wallet'
GROUP BY Date
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. SP header (Inessa K, 2021-01-09) documents key logic changes: removed @d date condition for fee source (2022-01-24), added method field (2022-03-22), added 5-day lookback for transaction data (2023-01-17), added additional TransactionTypeIDs (2023-05-08), CAST fix for varchar fee values (2024-08-08).

---

*Generated: 2026-04-20 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 1 T1, 18 T2, 0 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 9/10, Sources: 8/10*
*Object: EXW_dbo.EXW_EthFeeSent_Blockchain | Type: Table | Production Source: EXW_ETH_FeeData_Blockchain (Etherscan) + EXW_FactTransactions*
