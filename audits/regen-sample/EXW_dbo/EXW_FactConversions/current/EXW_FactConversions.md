# EXW_dbo.EXW_FactConversions

> 50,298-row historical snapshot of crypto-to-crypto swap operations executed within the eToro Wallet from October 2018 to June 2023, sourced from WalletDB.Wallet.Conversions + ConversionTransactions. Each row fully denormalizes both legs of a swap — FROM side (crypto sold) and TO side (crypto purchased) — including blockchain transaction IDs, fees, addresses, and settlement timestamps. 97% of swaps completed successfully. Last loaded 2024-04-09; no ongoing ETL exists.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Conversions + Wallet.ConversionTransactions |
| **Refresh** | Historical one-time load (2024-04-09); no active SP writer found in SSDT |
| **Synapse Distribution** | HASH(SendingGCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_FactConversions records every crypto-to-crypto swap executed in the eToro Wallet platform from October 2018 through June 2023. Each row represents a single conversion where a wallet user exchanged one cryptocurrency for another within their own wallet — for example, selling 0.01 BTC to receive 3,022 XLM. The table denormalizes data from five sources into a flat analytical record per conversion: the core swap intent (WalletDB.Wallet.Conversions), the per-leg transaction details (Wallet.ConversionTransactions), the final settlement status (Wallet.ConversionStatuses), crypto names (CryptoTypes), and the user's GCID (CustomerWalletsView).

The 50,298 conversions involve 19,722 distinct GCIDs. Cryptos used as "FROM" side are dominated by ETH (34%), BTC (15%), and XRP (15%). Target cryptos ("TO" side) are led by BTC (36%), ETH (17%), and XRP (11%). Tokenized fiat assets (USDEX=102, EURX=101, GBPX=126, etc.) participate as both source and target, enabling users to swap between crypto and stable-value tokens.

**Status distribution**: 3=Completed (48,738, 97%), 2=Failed (1,555, 3%), 1=Pending (5, <0.01%).

**Key structural observations**:
- `SendingGCID` = `RecievingGCID` in all 50,298 rows — both wallets belong to the same user; no cross-user transfers exist in this table.
- `ConversionID2` = `ConversionID` in all rows — this column is a duplicate and carries no additional information.
- `ToEtoroEstimatedBCFee` is NULL in all rows — not populated during the historical load.
- The conversion feature appears to have been deprecated or replaced after June 2023 (last `RequestTime` = 2023-06-14).
- This table is consumed by `BI_DB_dbo.SP_US_Daily_Crypto` via JOIN on `ToEtoroSentTXID = EXW_FactTransactions.TranID WHERE ActionTypeID=1 AND IsConversion=1`.

---

## 2. Business Logic

### 2.1 Dual-Leg Swap Architecture

**What**: Every conversion has two sides: a FROM leg (selling crypto) and a TO leg (buying crypto). Both legs belong to the same GCID.

**Columns Involved**: `FromWalletId`, `ToWalletId`, `FromCryptoID`, `ToCryptoID`, `FromAmount`, `ToAmount`, `SendingGCID`, `RecievingGCID`

**Rules**:
- `SendingGCID` = `RecievingGCID` in all rows — the same user owns both wallets
- FROM leg: `FromWalletId`/`FromCryptoID`/`FromAmount` describe the crypto being sold
- TO leg: `ToWalletId`/`ToCryptoID`/`ToAmount` describe the crypto being bought
- `RequestedFromAmount` vs `FromAmount`: requested vs. actual executed amount (may differ due to slippage or fee deduction)
- `RequestedToAmount` vs `ToAmount`: same for the buy side

### 2.2 Conversion Status Lifecycle

**What**: Three-state lifecycle: Pending → Completed or Failed.

**Columns Involved**: `ConversionStatus`

**Rules**:
- `ConversionStatus` stores integer codes (type is varchar(500) but values are numeric strings)
- 1 = Pending (5 rows) — initiated but not yet settled
- 2 = Failed (1,555 rows, 3%) — failed during execution; source crypto returned to user
- 3 = Completed (48,738 rows, 97%) — both legs settled; source debited, target credited

### 2.3 Blockchain Transaction Tracking

**What**: Each completed leg has a separate sent and received transaction tracked at the blockchain level.

**Columns Involved**: `ToEtoroSentTXID`, `ToEtoroSentBlockchainTXID`, `FromEtoroSentTXID`, `FromEtoroSentBlockchainTXID`, `ToEtoroReceivedTXID`, `FromEtoroReceivedTXID`

**Rules**:
- `*SentTXID` (bigint): internal EXW transaction ID from EXW_Wallet.SentTransactions
- `*SentBlockchainTXID` (nvarchar): actual on-chain hash (e.g., `cc591ac7922b...` for Bitcoin, `0x...` for Ethereum, uppercase hex for Ripple)
- `*ReceivedTXID` / `*ReceivedAmount`: corresponding receipt records from EXW_Wallet.ReceivedTransactions
- `ToEtoroSentTXID` is NULL for 542 rows (1%) — failed conversions where the TO-leg transaction never reached blockchain

### 2.4 Redundant and Empty Columns

**What**: Two columns carry no analytical value and should be handled carefully.

**Columns Involved**: `ConversionID2`, `ToEtoroEstimatedBCFee`

**Rules**:
- `ConversionID2` = `ConversionID` in 100% of rows — this is a duplicate column, possibly a loading artifact
- `ToEtoroEstimatedBCFee` = NULL in 100% of rows — the TO-leg estimated blockchain fee was never populated during the historical load

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is HASH-distributed on `SendingGCID` and uses HEAP (no CCI). With only 50,298 rows this is very small by Synapse standards — full scans are acceptable. The HASH distribution optimizes for GCID-scoped queries (which is the primary analyst pattern). JOINs to EXW_DimUser on GCID will benefit from co-location.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Swap volume by crypto pair | `GROUP BY FromCryptoID, ToCryptoID, FromCrypto, ToCrypto` — crypto names denormalized |
| User's swap history | `WHERE SendingGCID = @GCID ORDER BY RequestTime DESC` |
| Completed conversions only | `WHERE ConversionStatus = '3'` (note: varchar column storing integer) |
| JOIN with BI_DB_dbo reports | `JOIN EXW_FactTransactions ON ToEtoroSentTXID = EXW_FactTransactions.TranID` |
| Fee analysis | Use `SentToEtoroWalletEtoroFees` + `SentFromEtoroWalletEtoroFees` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `ON EXW_FactConversions.SendingGCID = EXW_DimUser.GCID` | Enrich with user demographics |
| EXW_dbo.EXW_FactTransactions | `ON EXW_FactConversions.ToEtoroSentTXID = EXW_FactTransactions.TranID` | Link swaps to transaction log |

### 3.4 Gotchas

- **ConversionStatus is varchar, not int**: Filter as `WHERE ConversionStatus = '3'` not `= 3`
- **ConversionID2 is always = ConversionID**: Don't use ConversionID2 for any grouping or filtering; it adds no information
- **ToEtoroEstimatedBCFee is always NULL**: Skip this column — it was never populated
- **Historical snapshot only**: No new data after 2023-06-14; do not rely on this table for current swap activity
- **Same-user swaps only**: `SendingGCID` = `RecievingGCID` always; this is not a peer-to-peer transfer table
- **UpdateDate is uniform**: All rows have `UpdateDate = 2024-04-09` — this reflects the load date, not the conversion date

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (WalletDB.Wallet.Conversions or ConversionTransactions) |
| Tier 2 | Derived from SP code analysis, JOIN patterns, or live data sampling |
| Tier 4 | Best available knowledge — limited confidence; inferred from naming patterns or data observation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ConversionID | bigint | YES | Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Passthrough from WalletDB. (Tier 1 — WalletDB.Wallet.Conversions) |
| 2 | CorrelationID | uniqueidentifier | YES | Links to the parent request in Wallet.Requests.CorrelationId. Used by the orchestration saga to deduplicate retries. (Tier 1 — WalletDB.Wallet.Conversions) |
| 3 | RequestTime | datetime | YES | Timestamp when the conversion was initiated. Passthrough from Wallet.Conversions.Occurred. (Tier 1 — WalletDB.Wallet.Conversions) |
| 4 | FromWalletId | uniqueidentifier | YES | The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId. (Tier 1 — WalletDB.Wallet.Conversions) |
| 5 | FromAddress | nvarchar(512) | YES | Destination blockchain address for this conversion leg. NULL when the transfer is internal. FROM-leg outgoing address. (Tier 1 — WalletDB.Wallet.ConversionTransactions) |
| 6 | SendingGCID | bigint | YES | Group Customer ID of the wallet owner initiating the conversion. Derived by joining FromWalletId to CustomerWalletsView. Always equal to RecievingGCID (same user controls both wallets). (Tier 2 — EXW_Wallet.CustomerWalletsView) |
| 7 | RequestedFromAmount | numeric(38,8) | YES | Amount of source crypto being sold. In native units of FromCryptoId. This is the original requested amount before execution. (Tier 1 — WalletDB.Wallet.Conversions) |
| 8 | FromCryptoID | int | YES | Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 — WalletDB.Wallet.Conversions) |
| 9 | FromCrypto | nvarchar(500) | YES | Human-readable name of the source cryptocurrency. Denormalized from EXW_Wallet.CryptoTypes by name. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 10 | ConversionStatus | varchar(500) | YES | Lifecycle status of the conversion stored as a numeric string. 1=Pending, 2=Failed, 3=Completed (Dictionary.ConversionStatuses). (Tier 2 — WalletDB.Wallet.ConversionStatuses) |
| 11 | ModificationTime | datetime | YES | Timestamp of the latest status change for this conversion record. Sourced from ConversionStatuses modification timestamp. (Tier 2 — WalletDB.Wallet.ConversionStatuses) |
| 12 | FromAmount | numeric(38,8) | YES | Amount of crypto for this conversion leg in native units. FROM-leg actual executed amount (may differ from RequestedFromAmount due to slippage/fees). (Tier 1 — WalletDB.Wallet.ConversionTransactions) |
| 13 | ToEtoroEstimatedBCFee | numeric(38,8) | YES | Estimated blockchain network fee for this leg. TO-leg estimated fee — always NULL; was not populated during the historical load. (Tier 2 — WalletDB.Wallet.ConversionTransactions) |
| 14 | ToEtoroDate | datetime | YES | Timestamp of the TO-leg conversion transaction creation. Sourced from ConversionTransactions.Occurred for the TO leg. (Tier 2 — WalletDB.Wallet.ConversionTransactions) |
| 15 | ConversionID2 | bigint | YES | Duplicate of ConversionID. Always equals ConversionID (confirmed in 100% of rows). Loading artifact — carries no additional information. Do not use for filtering or grouping. (Tier 4 — data observation) |
| 16 | ToWalletId | uniqueidentifier | YES | The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId. (Tier 1 — WalletDB.Wallet.Conversions) |
| 17 | ToAddress | nvarchar(512) | YES | Destination blockchain address for this conversion leg. NULL when the transfer is internal. TO-leg receiving address. (Tier 1 — WalletDB.Wallet.ConversionTransactions) |
| 18 | RecievingGCID | bigint | YES | Group Customer ID of the wallet owner receiving the conversion. Derived by joining ToWalletId to CustomerWalletsView. Always equal to SendingGCID — same user owns both wallets in a self-swap. (Tier 2 — EXW_Wallet.CustomerWalletsView) |
| 19 | RequestedToAmount | numeric(38,8) | YES | Amount of destination crypto being purchased. In native units of ToCryptoId. This is the original requested amount before execution. (Tier 1 — WalletDB.Wallet.Conversions) |
| 20 | ToCryptoID | int | YES | Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 — WalletDB.Wallet.Conversions) |
| 21 | ToCrypto | nvarchar(500) | YES | Human-readable name of the destination cryptocurrency. Denormalized from EXW_Wallet.CryptoTypes by name. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 22 | ToAmount | numeric(38,8) | YES | Amount of crypto for this conversion leg in native units. TO-leg actual executed amount received in the destination wallet. (Tier 1 — WalletDB.Wallet.ConversionTransactions) |
| 23 | FromEtoroEstimatedBCFee | numeric(38,8) | YES | Estimated blockchain network fee for this leg. FROM-leg estimated blockchain fee in native crypto units. NULL when blockchain fee was not available at load time. (Tier 1 — WalletDB.Wallet.ConversionTransactions) |
| 24 | FromEtoroDate | datetime | YES | Timestamp of the FROM-leg conversion transaction creation. Sourced from ConversionTransactions.Occurred for the FROM leg. (Tier 2 — WalletDB.Wallet.ConversionTransactions) |
| 25 | ToEtoroSentTXID | bigint | YES | Internal EXW platform transaction ID for the TO-leg sent transaction. From EXW_Wallet.SentTransactions. NULL when the TO-leg sent transaction was not found (failed or pending conversions). (Tier 2 — EXW_Wallet.SentTransactions) |
| 26 | ToEtoroSentBlockchainTXID | nvarchar(max) | YES | On-chain blockchain hash for the TO-leg sent transaction. Format varies by chain: Ethereum "0x"+64 hex, Ripple uppercase hex, etc. (Tier 2 — EXW_Wallet.SentTransactions) |
| 27 | FromEtoroSentTXID | bigint | YES | Internal EXW platform transaction ID for the FROM-leg sent transaction. From EXW_Wallet.SentTransactions. (Tier 2 — EXW_Wallet.SentTransactions) |
| 28 | FromEtoroSentBlockchainTXID | nvarchar(max) | YES | On-chain blockchain hash for the FROM-leg sent transaction. (Tier 2 — EXW_Wallet.SentTransactions) |
| 29 | SentToEtoroWalletAmount | numeric(38,8) | YES | Gross amount of TO-leg crypto sent from eToro's omnibus wallet to the destination address. (Tier 2 — EXW_Wallet.SentTransactions) |
| 30 | SentToEtoroWalletEtoroFees | numeric(38,8) | YES | eToro fee charged on the TO-leg sent transaction in native crypto units. (Tier 2 — EXW_Wallet.SentTransactions) |
| 31 | SentToEtoroBlockchainFees | numeric(38,8) | YES | Blockchain network fee charged on the TO-leg sent transaction in native crypto units. (Tier 2 — EXW_Wallet.SentTransactions) |
| 32 | SentFromEtoroWalletAmount | numeric(38,8) | YES | Gross amount of FROM-leg crypto sent from the user's wallet. (Tier 2 — EXW_Wallet.SentTransactions) |
| 33 | SentFromEtoroWalletEtoroFees | numeric(38,8) | YES | eToro fee charged on the FROM-leg sent transaction in native crypto units. (Tier 2 — EXW_Wallet.SentTransactions) |
| 34 | SentFromEtoroBlockchainFees | numeric(38,8) | YES | Blockchain network fee charged on the FROM-leg sent transaction in native crypto units. (Tier 2 — EXW_Wallet.SentTransactions) |
| 35 | ToEtoroReceivedTXID | bigint | YES | Internal EXW platform transaction ID for the TO-leg received transaction. From EXW_Wallet.ReceivedTransactions. (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 36 | ToEtoroReceivedAmount | numeric(38,8) | YES | Amount of TO-leg crypto received in the destination wallet after blockchain settlement. (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 37 | ToEtoroReceiveBlockchainFee | numeric(38,8) | YES | Blockchain fee deducted on receipt for the TO-leg transaction. (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 38 | FromEtoroReceivedTXID | bigint | YES | Internal EXW platform transaction ID for the FROM-leg received transaction. (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 39 | FromEtoroReceivedAmount | numeric(38,8) | YES | Amount of FROM-leg crypto received back (e.g., after failed leg). (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 40 | FromEtoroReceiveBlockchainFee | numeric(38,8) | YES | Blockchain fee on the FROM-leg received transaction. (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 41 | ReceivedTime | datetime | YES | Timestamp when both legs received final settlement confirmation. (Tier 2 — EXW_Wallet.ReceivedTransactions) |
| 42 | UpdateDate | datetime | YES | Timestamp of the last ETL data load. Uniform value 2024-04-09 across all rows — reflects the one-time historical load date, not the conversion date. (Tier 2 — ETL load process) |
| 43 | FromBlockchainCryptoId | int | YES | Blockchain-layer cryptocurrency identifier for the FROM side. May differ from FromCryptoID (which is the Wallet platform ID). From EXW_Wallet.BlockchainCryptos. (Tier 2 — EXW_Wallet.BlockchainCryptos) |
| 44 | FromBlockchainCryptoName | nvarchar(500) | YES | Blockchain-layer cryptocurrency name for the FROM side. (Tier 2 — EXW_Wallet.BlockchainCryptos) |
| 45 | ToBlockchainCryptoId | int | YES | Blockchain-layer cryptocurrency identifier for the TO side. (Tier 2 — EXW_Wallet.BlockchainCryptos) |
| 46 | ToBlockchainCryptoName | nvarchar(500) | YES | Blockchain-layer cryptocurrency name for the TO side. (Tier 2 — EXW_Wallet.BlockchainCryptos) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| ConversionID | WalletDB.Wallet.Conversions | Id | Passthrough rename |
| CorrelationID | WalletDB.Wallet.Conversions | CorrelationId | Passthrough rename |
| RequestTime | WalletDB.Wallet.Conversions | Occurred | Passthrough rename |
| FromWalletId | WalletDB.Wallet.Conversions | FromWalletId | Passthrough |
| ToWalletId | WalletDB.Wallet.Conversions | ToWalletId | Passthrough |
| FromCryptoID | WalletDB.Wallet.Conversions | FromCryptoId | Passthrough rename |
| ToCryptoID | WalletDB.Wallet.Conversions | ToCryptoId | Passthrough rename |
| RequestedFromAmount | WalletDB.Wallet.Conversions | FromAmount | Passthrough rename (requested amount) |
| RequestedToAmount | WalletDB.Wallet.Conversions | ToAmount | Passthrough rename (requested amount) |
| FromAddress, ToAddress | WalletDB.Wallet.ConversionTransactions | ToAddress | Per-leg address |
| FromAmount, ToAmount | WalletDB.Wallet.ConversionTransactions | Amount | Per-leg executed amount |
| FromEtoroEstimatedBCFee | WalletDB.Wallet.ConversionTransactions | EstimatedBlockChainFee | FROM-leg only |
| ConversionStatus | WalletDB.Wallet.ConversionStatuses | ConversionStatusId | Status as numeric string |
| SendingGCID, RecievingGCID | EXW_Wallet.CustomerWalletsView | GCID | JOIN on wallet ID |
| FromCrypto, ToCrypto | EXW_Wallet.CryptoTypes | Name | JOIN on CryptoID |
| Sent/Received TXIDs, amounts, fees | EXW_Wallet.SentTransactions / ReceivedTransactions | Various | Per-leg transaction details |
| BlockchainCrypto* | EXW_Wallet.BlockchainCryptos | Id, Name | Blockchain-layer metadata |

### 5.2 ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
├── Wallet.Conversions (ConversionID, CorrelationID, WalletIds, Amounts, RequestTime)
│     |-- Generic Pipeline (Bronze export, daily) --|
│     v  CopyFromLake (Bronze layer for ConversionStatuses dict)
├── Wallet.ConversionTransactions (Amounts, Addresses, Fees, Timestamps per leg)
├── Wallet.ConversionStatuses (ConversionStatus integer)
├── Dictionary.ConversionStatuses (1=Pending, 2=Failed, 3=Completed)
├── EXW_Wallet.CryptoTypes (FromCrypto, ToCrypto names)
├── EXW_Wallet.CustomerWalletsView (SendingGCID, RecievingGCID)
├── EXW_Wallet.SentTransactions (SentTXIDs, SentAmounts, EtoroFees, BlockchainFees)
└── EXW_Wallet.ReceivedTransactions (ReceivedTXIDs, ReceivedAmounts, BlockchainFees)
     |
     |-- [Historical one-time ad-hoc JOIN load — 2024-04-09] --|
     v
EXW_dbo.EXW_FactConversions (50,298 rows, HASH(SendingGCID), HEAP)
     |
     |-- [JOIN: ToEtoroSentTXID = EXW_FactTransactions.TranID, IsConversion=1] --|
     v
BI_DB_dbo.SP_US_Daily_Crypto → BI_DB_dbo.BI_DB_US_Daily_Conversions
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| SendingGCID / RecievingGCID | EXW_dbo.EXW_DimUser | User dimension for wallet owners |
| FromCryptoID / ToCryptoID | EXW_Wallet.CryptoTypes | Crypto asset reference |
| ConversionID | WalletDB.Wallet.Conversions | Production source row |
| ToEtoroSentTXID | EXW_dbo.EXW_FactTransactions.TranID | Links to transaction log |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Condition | Purpose |
|--------------|---------------|---------|
| BI_DB_dbo.SP_US_Daily_Crypto | `ToEtoroSentTXID = EXW_FactTransactions.TranID AND IsConversion=1` | US daily crypto conversion reporting |

---

## 7. Sample Queries

### 7.1 Most popular crypto swap pairs
```sql
SELECT 
    FromCrypto, ToCrypto,
    COUNT(*) AS swap_count,
    SUM(CAST(RequestedFromAmount AS decimal(38,8))) AS total_from_amount
FROM [EXW_dbo].[EXW_FactConversions]
WHERE ConversionStatus = '3'  -- Completed only
GROUP BY FromCrypto, ToCrypto
ORDER BY swap_count DESC
```

### 7.2 User's swap history with status
```sql
SELECT 
    ConversionID, RequestTime, 
    FromCrypto, RequestedFromAmount, FromAmount,
    ToCrypto, RequestedToAmount, ToAmount,
    CASE ConversionStatus WHEN '1' THEN 'Pending' WHEN '2' THEN 'Failed' WHEN '3' THEN 'Completed' ELSE ConversionStatus END AS Status
FROM [EXW_dbo].[EXW_FactConversions]
WHERE SendingGCID = @GCID
ORDER BY RequestTime DESC
```

### 7.3 Daily swap volume by crypto
```sql
SELECT 
    CAST(RequestTime AS date) AS swap_date,
    FromCrypto,
    COUNT(*) AS conversion_count,
    SUM(CAST(FromAmount AS decimal(38,8))) AS volume_native
FROM [EXW_dbo].[EXW_FactConversions]
WHERE ConversionStatus = '3'
  AND RequestTime >= '2023-01-01'
GROUP BY CAST(RequestTime AS date), FromCrypto
ORDER BY swap_date DESC, conversion_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-20 | Quality: 8.4/10 (P16 adversarial: 8.35) | Phases: 14/14*
*Tiers: 14 T1, 31 T2, 0 T3, 1 T4, 0 T5 | Elements: 46/46, Logic: 8/10, Lineage: 9/10*
*Object: EXW_dbo.EXW_FactConversions | Type: Table | Production Source: WalletDB.Wallet.Conversions*
