# EXW_dbo.EXW_FactConversions

> 50,298-row denormalized fact table recording every crypto-to-crypto conversion (swap) executed within the eToro wallet from October 2018 to June 2023. Combines base conversion data from WalletDB `Wallet.Conversions` with per-leg transaction details from `Wallet.ConversionTransactions`, tracking the source/destination wallets, amounts, fees, and blockchain transaction IDs for both the "From" and "To" sides of each swap. No writer SP — loaded via external pipeline. Last refreshed 2024-04-09; feature appears dormant since June 2023.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB — Wallet.Conversions + Wallet.ConversionTransactions (external pipeline load, no SSDT SP) |
| **Refresh** | Dormant — single bulk load on 2024-04-09, no ongoing refresh detected |
| **Synapse Distribution** | HASH(SendingGCID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table is a denormalized fact recording every crypto-to-crypto conversion (swap) performed by eToro wallet users. Each row represents a single conversion operation — e.g., swapping 0.1 ETH for 287 XLM. With 50,298 rows spanning October 2018 to June 2023, the table captures the full lifecycle of each swap: the initial request, the sent transactions on both the "From" (source crypto) and "To" (destination crypto) legs, and the received confirmations.

The table is a flattened join of two WalletDB production tables:
- **Wallet.Conversions** — the base conversion record (ID, wallets, amounts, crypto types, correlation ID, occurred timestamp).
- **Wallet.ConversionTransactions** — the per-leg details (fees, addresses, amounts) for both the From-leg and To-leg.

Additional enrichments include crypto name lookups from `EXW_Wallet.CryptoTypes` and customer GCID mapping. Notably, `SendingGCID` always equals `RecievingGCID` — all conversions are self-swaps within a single user's wallets.

The table has no writer stored procedure in the SSDT repo. All rows carry `UpdateDate = 2024-04-09 05:11:18`, indicating a single bulk load. The last conversion (`RequestTime`) is from 2023-06-14, suggesting the crypto-to-crypto conversion feature was deprecated or replaced.

**ConversionStatus** has 3 values: 3 (completed, 48,738 rows), 2 (failed/cancelled, 1,555 rows), 1 (pending, 5 rows). Top conversion pairs: ETH→BTC, XRP→BTC, BTC→ETH.

---

## 2. Business Logic

### 2.1 Two-Leg Conversion Structure

**What**: Each conversion has a "From" side (source crypto being sold) and a "To" side (destination crypto being purchased), with mirrored columns for each leg.

**Columns Involved**: FromWalletId/ToWalletId, FromCryptoID/ToCryptoID, FromAmount/ToAmount, FromAddress/ToAddress, all "SentFrom"/"SentTo" and "FromEtoro"/"ToEtoro" column pairs.

**Rules**:
- Each conversion involves two wallets belonging to the same user (SendingGCID = RecievingGCID)
- "From" columns track the crypto being sold; "To" columns track the crypto being purchased
- Amounts appear in native crypto units (e.g., 0.1 ETH, 287 XLM)

### 2.2 Conversion Lifecycle

**What**: Each conversion progresses through request → send → receive phases, tracked by separate timestamp and ID columns.

**Columns Involved**: RequestTime, FromEtoroDate/ToEtoroDate, ToEtoroSentTXID/FromEtoroSentTXID, ToEtoroReceivedTXID/FromEtoroReceivedTXID, ReceivedTime, ConversionStatus

**Rules**:
- ConversionStatus: 1=Pending, 2=Failed/Cancelled, 3=Completed
- Failed conversions (status=2) typically have NULL FromAmount, ToAmount, and ReceivedTime
- Completed conversions (status=3) have the full chain: request → sent → received with all amounts populated

### 2.3 Fee Structure

**What**: Each leg has eToro platform fees and blockchain network fees tracked separately.

**Columns Involved**: SentToEtoroWalletEtoroFees, SentToEtoroBlockchainFees, SentFromEtoroWalletEtoroFees, SentFromEtoroBlockchainFees, ToEtoroEstimatedBCFee, FromEtoroEstimatedBCFee, ToEtoroReceiveBlockchainFee, FromEtoroReceiveBlockchainFee

**Rules**:
- eToro fees are platform charges in native crypto units
- Blockchain fees are network transaction costs
- Estimated fees (ToEtoroEstimatedBCFee/FromEtoroEstimatedBCFee) are pre-send estimates; actual fees appear in the Sent/Received columns

### 2.4 Blockchain Crypto vs Wallet Crypto

**What**: A crypto asset may have a different "blockchain crypto" representation than its wallet-level crypto type.

**Columns Involved**: FromCryptoID/FromBlockchainCryptoId, ToCryptoID/ToBlockchainCryptoId, FromCrypto/FromBlockchainCryptoName, ToCrypto/ToBlockchainCryptoName

**Rules**:
- ERC-20 tokens (e.g., GBPX, GLDX) show FromBlockchainCryptoId = ETH (2) because they transact on the Ethereum blockchain
- Native cryptos (BTC, ETH, XLM) have matching CryptoId and BlockchainCryptoId

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `SendingGCID` — optimal for per-customer queries and JOINs to other EXW tables keyed on GCID.
- **Index**: HEAP — no clustered index. Full table scans for non-GCID filters.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Conversion volume for a user | `WHERE SendingGCID = @gcid` — distribution-aligned |
| Completed conversions only | `WHERE ConversionStatus = '3'` |
| Conversions by crypto pair | `GROUP BY FromCrypto, ToCrypto` |
| Date-range analysis | `WHERE RequestTime BETWEEN @start AND @end` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_FactTransactions | `efc.ToEtoroSentTXID = ft.TranID` | Link conversion to wallet transaction records (used in SP_US_Daily_Crypto) |
| EXW_dbo.EXW_DimUser | `efc.SendingGCID = edu.GCID` | Customer demographics |
| EXW_Wallet.CryptoTypes | `efc.FromCryptoID = ct.CryptoID` | Resolve crypto metadata |

### 3.4 Gotchas

- **ConversionStatus is varchar(500)**, not int — filter with string `'3'`, not integer `3`.
- **RecievingGCID** is misspelled ("Recieving" not "Receiving") — use the exact column name.
- **SendingGCID = RecievingGCID** always — do not assume these are different users.
- **NULL amounts**: ~313 rows have NULL FromAmount, ~1,510 have NULL ToAmount — these are failed/cancelled conversions (status 2).
- **Dormant table**: Last conversion is from 2023-06-14. Data is historical only.
- **ConversionID = ConversionID2** in all observed rows — appears to be a duplicate column.
- **RequestedFromAmount vs FromAmount**: RequestedFromAmount is the user's original request; FromAmount is the actual amount after micro-fees are deducted (typically differs by ~0.00005).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (Wallet.Conversions or Wallet.ConversionTransactions) |
| Tier 2 | Derived via lookup or transform during ETL load |
| Tier 3 | No upstream wiki; described from DDL, data patterns, and column naming |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ConversionID | bigint | YES | Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. (Tier 1 — Wallet.Conversions) |
| 2 | CorrelationID | uniqueidentifier | YES | Links to the parent request in Wallet.Requests.CorrelationId. (Tier 1 — Wallet.Conversions) |
| 3 | RequestTime | datetime | YES | Timestamp when the conversion was initiated. (Tier 1 — Wallet.Conversions) |
| 4 | FromWalletId | uniqueidentifier | YES | The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId. (Tier 1 — Wallet.Conversions) |
| 5 | FromAddress | nvarchar(512) | YES | Blockchain address of the source wallet for the From-leg of the conversion. Sourced from ConversionTransactions.ToAddress for the From-leg record. (Tier 2 — external pipeline) |
| 6 | SendingGCID | bigint | YES | Global customer ID of the user initiating the conversion. Always equals RecievingGCID (self-swap). Mapped from wallet ownership, not present in upstream Wallet.Conversions. (Tier 3 — no upstream wiki, wallet-to-customer mapping) |
| 7 | RequestedFromAmount | numeric(38,8) | YES | Amount of source crypto being sold. In native units of FromCryptoId. (Tier 1 — Wallet.Conversions) |
| 8 | FromCryptoID | int | YES | Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 — Wallet.Conversions) |
| 9 | FromCrypto | nvarchar(500) | YES | Name of the source cryptocurrency (e.g., ETH, BTC, XRP). Resolved from EXW_Wallet.CryptoTypes via FromCryptoID lookup. (Tier 2 — CryptoTypes lookup) |
| 10 | ConversionStatus | varchar(500) | YES | Conversion lifecycle status code: 1=Pending, 2=Failed/Cancelled, 3=Completed. Sourced from Wallet.ConversionStatuses (no upstream wiki available). (Tier 3 — no upstream wiki, derived from data) |
| 11 | ModificationTime | datetime | YES | Last modification timestamp of the conversion record. Tracks the most recent status or data change. (Tier 3 — no upstream wiki, name-derived) |
| 12 | FromAmount | numeric(38,8) | YES | Amount of source crypto being sold. In native units of FromCryptoId. Actual amount after micro-fee deduction (slightly less than RequestedFromAmount). NULL for failed conversions. (Tier 1 — Wallet.Conversions) |
| 13 | ToEtoroEstimatedBCFee | numeric(38,8) | YES | Estimated blockchain network fee for this leg. Pre-send estimate for the To-leg of the conversion. (Tier 1 — Wallet.ConversionTransactions) |
| 14 | ToEtoroDate | datetime | YES | Timestamp of the To-leg transaction record creation. (Tier 1 — Wallet.ConversionTransactions) |
| 15 | ConversionID2 | bigint | YES | Duplicate of ConversionID. Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Same value as ConversionID in all observed rows. (Tier 1 — Wallet.Conversions) |
| 16 | ToWalletId | uniqueidentifier | YES | The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId. (Tier 1 — Wallet.Conversions) |
| 17 | ToAddress | nvarchar(512) | YES | Destination blockchain address for this conversion leg. NULL when the transfer is internal. (Tier 1 — Wallet.ConversionTransactions) |
| 18 | RecievingGCID | bigint | YES | Global customer ID of the receiving side. Always equals SendingGCID (self-swap). Mapped from wallet ownership, not present in upstream tables. (Tier 3 — no upstream wiki, wallet-to-customer mapping) |
| 19 | RequestedToAmount | numeric(38,8) | YES | Amount of destination crypto being purchased. In native units of ToCryptoId. (Tier 1 — Wallet.Conversions) |
| 20 | ToCryptoID | int | YES | Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 — Wallet.Conversions) |
| 21 | ToCrypto | nvarchar(500) | YES | Name of the destination cryptocurrency (e.g., BTC, XLM, LTC). Resolved from EXW_Wallet.CryptoTypes via ToCryptoID lookup. (Tier 2 — CryptoTypes lookup) |
| 22 | ToAmount | numeric(38,8) | YES | Amount of destination crypto being purchased. In native units of ToCryptoId. NULL for failed conversions. (Tier 1 — Wallet.Conversions) |
| 23 | FromEtoroEstimatedBCFee | numeric(38,8) | YES | Estimated blockchain network fee for this leg. Pre-send estimate for the From-leg of the conversion. (Tier 1 — Wallet.ConversionTransactions) |
| 24 | FromEtoroDate | datetime | YES | Timestamp of the From-leg transaction record creation. (Tier 1 — Wallet.ConversionTransactions) |
| 25 | ToEtoroSentTXID | bigint | YES | To-leg sent transaction ID from the wallet's SentTransactions table. Used as FK to EXW_FactTransactions.TranID. (Tier 3 — no upstream wiki, from Wallet.SentTransactions) |
| 26 | ToEtoroSentBlockchainTXID | nvarchar(max) | YES | To-leg blockchain transaction hash for the sent transaction. On-chain identifier for the To-leg send. (Tier 3 — no upstream wiki, from Wallet.SentTransactions) |
| 27 | FromEtoroSentTXID | bigint | YES | From-leg sent transaction ID from the wallet's SentTransactions table. (Tier 3 — no upstream wiki, from Wallet.SentTransactions) |
| 28 | FromEtoroSentBlockchainTXID | nvarchar(max) | YES | From-leg blockchain transaction hash for the sent transaction. On-chain identifier for the From-leg send. (Tier 3 — no upstream wiki, from Wallet.SentTransactions) |
| 29 | SentToEtoroWalletAmount | numeric(38,8) | YES | Amount of crypto for the To-leg conversion in native units. The actual amount sent to the destination wallet. (Tier 1 — Wallet.ConversionTransactions) |
| 30 | SentToEtoroWalletEtoroFees | numeric(38,8) | YES | Calculated eToro fee amount in the crypto's native units. Platform fee for the To-leg. (Tier 1 — Wallet.ConversionTransactions) |
| 31 | SentToEtoroBlockchainFees | numeric(38,8) | YES | Estimated blockchain network fee for this leg. Network cost for the To-leg sent transaction. (Tier 1 — Wallet.ConversionTransactions) |
| 32 | SentFromEtoroWalletAmount | numeric(38,8) | YES | Amount of crypto for the From-leg conversion in native units. The actual amount sent from the source wallet. (Tier 1 — Wallet.ConversionTransactions) |
| 33 | SentFromEtoroWalletEtoroFees | numeric(38,8) | YES | Calculated eToro fee amount in the crypto's native units. Platform fee for the From-leg. (Tier 1 — Wallet.ConversionTransactions) |
| 34 | SentFromEtoroBlockchainFees | numeric(38,8) | YES | Estimated blockchain network fee for this leg. Network cost for the From-leg sent transaction. (Tier 1 — Wallet.ConversionTransactions) |
| 35 | ToEtoroReceivedTXID | bigint | YES | To-leg received transaction ID from the wallet's ReceivedTransactions table. Confirms receipt on the To side. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| 36 | ToEtoroReceivedAmount | numeric(38,8) | YES | Actual amount of crypto received on the To-leg after all fees. May differ from SentToEtoroWalletAmount due to blockchain fees. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| 37 | ToEtoroReceiveBlockchainFee | numeric(38,8) | YES | Blockchain fee deducted on receipt for the To-leg. Network cost on the receive side. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| 38 | FromEtoroReceivedTXID | bigint | YES | From-leg received transaction ID from the wallet's ReceivedTransactions table. Confirms receipt on the From side. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| 39 | FromEtoroReceivedAmount | numeric(38,8) | YES | Actual amount of crypto received on the From-leg after all fees. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| 40 | FromEtoroReceiveBlockchainFee | numeric(38,8) | YES | Blockchain fee deducted on receipt for the From-leg. Network cost on the receive side. (Tier 3 — no upstream wiki, from Wallet.ReceivedTransactions) |
| 41 | ReceivedTime | datetime | YES | Timestamp when the conversion was fully received/completed. NULL for failed or incomplete conversions (1,608 NULLs). (Tier 3 — no upstream wiki, name-derived) |
| 42 | UpdateDate | datetime | YES | ETL load timestamp. All rows show 2024-04-09 05:11:18, indicating a single bulk load. (Tier 3 — ETL metadata) |
| 43 | FromBlockchainCryptoId | int | YES | Blockchain-level crypto ID for the From-leg. For ERC-20 tokens, this maps to the underlying blockchain (e.g., ETH=2). Resolved via EXW_Wallet.CryptoTypes.BlockchainCryptoId. (Tier 2 — CryptoTypes lookup) |
| 44 | FromBlockchainCryptoName | nvarchar(500) | YES | Blockchain-level crypto name for the From-leg (e.g., ETH for ERC-20 tokens). Resolved via EXW_Wallet.CryptoTypes. (Tier 2 — CryptoTypes lookup) |
| 45 | ToBlockchainCryptoId | int | YES | Blockchain-level crypto ID for the To-leg. For ERC-20 tokens, this maps to the underlying blockchain. Resolved via EXW_Wallet.CryptoTypes.BlockchainCryptoId. (Tier 2 — CryptoTypes lookup) |
| 46 | ToBlockchainCryptoName | nvarchar(500) | YES | Blockchain-level crypto name for the To-leg (e.g., ETH for ERC-20 tokens). Resolved via EXW_Wallet.CryptoTypes. (Tier 2 — CryptoTypes lookup) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| ConversionID | Wallet.Conversions | Id | Rename |
| CorrelationID | Wallet.Conversions | CorrelationId | Passthrough |
| RequestTime | Wallet.Conversions | Occurred | Rename |
| FromWalletId | Wallet.Conversions | FromWalletId | Passthrough |
| FromAmount | Wallet.Conversions | FromAmount | Passthrough |
| RequestedFromAmount | Wallet.Conversions | FromAmount | Passthrough (original request) |
| FromCryptoID | Wallet.Conversions | FromCryptoId | Passthrough |
| ToWalletId | Wallet.Conversions | ToWalletId | Passthrough |
| ToAmount | Wallet.Conversions | ToAmount | Passthrough |
| RequestedToAmount | Wallet.Conversions | ToAmount | Passthrough (original request) |
| ToCryptoID | Wallet.Conversions | ToCryptoId | Passthrough |
| SentToEtoroWalletAmount | Wallet.ConversionTransactions | Amount | To-leg |
| SentFromEtoroWalletAmount | Wallet.ConversionTransactions | Amount | From-leg |
| ToAddress | Wallet.ConversionTransactions | ToAddress | To-leg |
| SentToEtoroWalletEtoroFees | Wallet.ConversionTransactions | EtoroFeeCalculated | To-leg |
| SentFromEtoroWalletEtoroFees | Wallet.ConversionTransactions | EtoroFeeCalculated | From-leg |
| ToEtoroEstimatedBCFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | To-leg |
| FromEtoroEstimatedBCFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | From-leg |
| FromCrypto | EXW_Wallet.CryptoTypes | Name | Lookup on FromCryptoID |
| ToCrypto | EXW_Wallet.CryptoTypes | Name | Lookup on ToCryptoID |
| SendingGCID | Wallet-to-customer mapping | — | External enrichment |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Conversions (50K rows, production)
WalletDB.Wallet.ConversionTransactions (per-leg details)
  |-- External pipeline (denormalized join + CryptoTypes lookup + GCID mapping) ---|
  v
EXW_dbo.EXW_FactConversions (50,298 rows, single bulk load 2024-04-09)
  |-- No downstream UC target (_Not_Migrated) ---|

Reader: BI_DB_dbo.SP_US_Daily_Crypto (joins on ToEtoroSentTXID)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| FromWalletId | Wallet.Wallets | Source wallet for the swap |
| ToWalletId | Wallet.Wallets | Destination wallet for the swap |
| FromCryptoID | EXW_Wallet.CryptoTypes | Crypto being sold |
| ToCryptoID | EXW_Wallet.CryptoTypes | Crypto being bought |
| SendingGCID / RecievingGCID | EXW_dbo.EXW_DimUser | Customer lookup (via GCID) |
| ConversionID | Wallet.ConversionStatuses | Conversion lifecycle tracking |
| ToEtoroSentTXID | EXW_dbo.EXW_FactTransactions | Wallet transaction record for To-leg send |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_US_Daily_Crypto | JOIN on ToEtoroSentTXID | US daily crypto reporting — links conversions to wallet transactions |

---

## 7. Sample Queries

### 7.1 Completed conversions by crypto pair
```sql
SELECT FromCrypto, ToCrypto, COUNT(*) AS SwapCount,
       SUM(CAST(FromAmount AS FLOAT)) AS TotalFromAmount
FROM EXW_dbo.EXW_FactConversions
WHERE ConversionStatus = '3'
GROUP BY FromCrypto, ToCrypto
ORDER BY SwapCount DESC
```

### 7.2 Conversion history for a specific user
```sql
SELECT ConversionID, RequestTime, FromCrypto, FromAmount,
       ToCrypto, ToAmount, ConversionStatus, ReceivedTime
FROM EXW_dbo.EXW_FactConversions
WHERE SendingGCID = 11035097
ORDER BY RequestTime DESC
```

### 7.3 Fee analysis for completed conversions
```sql
SELECT FromCrypto, ToCrypto,
       AVG(CAST(SentToEtoroWalletEtoroFees AS FLOAT)) AS AvgToEtoroFee,
       AVG(CAST(SentFromEtoroWalletEtoroFees AS FLOAT)) AS AvgFromEtoroFee,
       AVG(CAST(SentToEtoroBlockchainFees AS FLOAT)) AS AvgToBlockchainFee
FROM EXW_dbo.EXW_FactConversions
WHERE ConversionStatus = '3'
  AND SentToEtoroWalletEtoroFees IS NOT NULL
GROUP BY FromCrypto, ToCrypto
ORDER BY AvgToEtoroFee DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Atlassian sources found for this table. General crypto wallet documentation exists in Confluence CS space (Introduction - eToro crypto wallet, Sending crypto, etc.) but no table-specific references.

---

*Generated: 2026-04-27 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Tiers: 20 T1, 8 T2, 18 T3, 0 T4 | Elements: 46/46, Logic: 4/10, Relationships: 7/10, Sources: 7/10*
*Phases: 11/11*
*Object: EXW_dbo.EXW_FactConversions | Type: Table | Production Source: WalletDB — Wallet.Conversions + Wallet.ConversionTransactions*
