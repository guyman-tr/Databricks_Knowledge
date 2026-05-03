# EXW_Wallet.SentTransactionOutputs

> 2.2M-row Generic Pipeline landing table tracking individual outputs of blockchain send transactions from the eToro crypto wallet platform (WalletDB), spanning 2018-04-23 to 2026-04-27. Each row represents one destination address and amount within a sent transaction. Refreshed daily via Append strategy. No upstream wiki available; production source is WalletDB.Wallet.SentTransactionOutputs.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.SentTransactionOutputs (Generic Pipeline ID 710) |
| **Refresh** | Daily (1440 min), Append strategy, parquet |
| **Synapse Distribution** | HASH(SentTransactionId) |
| **Synapse Index** | HEAP + NCI on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_senttransactionoutputs` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze import |

---

## 1. Business Meaning

This table stores the individual outputs of blockchain send transactions from the eToro Wallet platform. A single send transaction (`SentTransactionId`) can have multiple outputs — each representing a distinct destination address (`ToAddress`) and crypto amount (`Amount`). This is consistent with UTXO-based blockchain models (e.g., Bitcoin) where a single transaction fans out to multiple recipients.

The table contains 2,212,095 rows spanning from April 2018 to April 2026. It is a direct Bronze landing from `WalletDB.Wallet.SentTransactionOutputs` via the Generic Pipeline (ID 710, Append, daily). There is no writer SP — data flows directly from the production WalletDB database through the data lake into Synapse.

Key downstream consumers:
- **EXW_Wallet.EXW_TransactionsView** — the unified wallet transactions view joins this table to `SentTransactions` to build the sent-side of the transaction ledger, filtering `IsEtoroFee = 0` to exclude fee outputs.
- **SP_EXW_FactRedeemTransactions** — reads `ToAddress`, `Amount`, `EtoroFees`, `SourceId`, `IsEtoroFee` to build the redeem fact table, matching outputs to redemption positions via `SourceId = PositionId`.
- **SP_EXW_C2F_E2E** — joins on `SentTransactionId` for crypto-to-fiat end-to-end tracking.

The `IsEtoroFee` flag distinguishes fee outputs (True, ~1K rows) from customer-facing outputs (False, ~2.2M rows). The `SourceIdType` column indicates the type of source entity: 1 (~1.13M rows), NULL (~1.08M), 2 (~1.4K), 0 (8).

---

## 2. Business Logic

### 2.1 Transaction Output Model (UTXO Pattern)

**What**: Each row is one output of a blockchain send transaction, following the UTXO (Unspent Transaction Output) model.
**Columns Involved**: Id, SentTransactionId, ToAddress, Amount
**Rules**:
- A single `SentTransactionId` can have multiple output rows (one per destination address)
- `Amount` is the crypto amount sent to `ToAddress` in that output (precision: 18 decimal places)
- `ToAddress` contains the raw blockchain address (may include query parameters like `?dt=0` for Ripple destination tags)

### 2.2 Fee Separation

**What**: Outputs are classified as customer-facing or eToro fee transfers.
**Columns Involved**: IsEtoroFee, EtoroFees, BlockchainFees
**Rules**:
- `IsEtoroFee = 0 (False)` — customer-facing output (~99.95% of rows)
- `IsEtoroFee = 1 (True)` — eToro fee output (~0.05% of rows)
- Downstream views (EXW_TransactionsView) filter `IsEtoroFee = 0` to exclude fee outputs
- `EtoroFees` is predominantly 0 at the output level; fee calculation happens at the transaction level in downstream SPs

### 2.3 Source Entity Linking

**What**: Links transaction outputs to source business entities (e.g., positions).
**Columns Involved**: SourceId, SourceIdType
**Rules**:
- `SourceIdType = 1` — source is a position ID (~51% of rows)
- `SourceIdType = NULL` — no source entity linked (~49% of rows)
- `SourceIdType = 2` — alternate source type (~0.06%)
- `SourceIdType = 0` — rare (8 rows)
- SP_EXW_FactRedeemTransactions joins `SourceId = PositionId` when `SourceIdType` implies a position

### 2.4 Address Normalization

**What**: Raw blockchain addresses are normalized for matching and deduplication.
**Columns Involved**: ToAddress, NormalizedToAddress
**Rules**:
- `ToAddress` is the raw address (may include protocol-specific suffixes like `?dt=0` for Ripple)
- `NormalizedToAddress` strips protocol-specific parameters for consistent address matching
- Used in EXW_TransactionsView's `other_transactions` CTE to exclude self-transfers by comparing against `WalletAddresses`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(SentTransactionId) — JOINs to `SentTransactions.Id` are co-located
- **Index**: HEAP (no clustered index) + NCI on `partition_date` for date-range filtering
- Use `partition_date` in WHERE clauses for efficient date-bounded queries

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| All outputs for a specific sent transaction | `WHERE SentTransactionId = @id` (distribution-aligned) |
| Daily output volume | `GROUP BY partition_date` (uses NCI) |
| Customer-facing outputs only | `WHERE IsEtoroFee = 0` |
| Outputs linked to a position | `WHERE SourceId = @positionId AND SourceIdType = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.SentTransactions | `SentTransactionId = SentTransactions.Id` | Get parent transaction details (CryptoId, WalletId, BlockchainFee, TransactionTypeId) |
| EXW_Wallet.Redemptions | `SentTransactions.CorrelationId = Redemptions.SendRequestCorrelationId AND SourceId = PositionId` | Link output to redemption position |
| EXW_Wallet.WalletAddresses | `NormalizedToAddress = WalletAddresses.NormalizedAddress` | Identify self-transfers |

### 3.4 Gotchas

- **ToAddress contains protocol parameters**: Ripple addresses include `?dt=0` (destination tag). Use `NormalizedToAddress` for address matching.
- **BlockchainFees is mostly NULL**: The blockchain fee is stored at the parent `SentTransactions` level, not per output. This column appears unused in reader SPs.
- **EtoroFees is predominantly 0**: eToro fees are calculated at higher levels (Redemptions, ConversionTransactions) and attributed in downstream SPs, not stored per output.
- **SourceId/SourceIdType NULLs**: ~49% of rows have no linked source entity. Not every send transaction originates from a tracked position.
- **No writer SP**: This is a Generic Pipeline landing table. Data is loaded directly from WalletDB, not via a Synapse stored procedure.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | ETL-computed or derived by pipeline logic |
| Tier 3 | Grounded in DDL + data evidence, no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | Id | bigint | YES | Primary key of the sent transaction output record. Unique identifier for each output row. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 2 | SentTransactionId | bigint | YES | FK to EXW_Wallet.SentTransactions.Id. Links this output to its parent send transaction. Distribution key. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 3 | ToAddress | varchar(4000) | YES | Raw blockchain destination address for this output. May contain protocol-specific suffixes (e.g., `?dt=0` for Ripple destination tags). (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 4 | Amount | numeric(36,18) | YES | Crypto amount sent to the destination address in this output. Precision of 18 decimal places for sub-unit accuracy. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 5 | EtoroFees | numeric(36,18) | YES | eToro platform fee amount for this output. Predominantly 0 at the output level; fees are typically calculated at the transaction or redemption level in downstream SPs. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 6 | BlockchainFees | numeric(36,18) | YES | Blockchain network fee attributed to this output. Mostly NULL in practice; the blockchain fee is stored at the parent SentTransactions level. SP_EXW_FactRedeemTransactions divides SentTransactions.BlockchainFee by output count instead. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 7 | SourceId | bigint | YES | Identifier of the source business entity linked to this output. When SourceIdType = 1, this is a position ID (joined as SourceId = PositionId in SP_EXW_FactRedeemTransactions). NULL when no source entity is linked (~49% of rows). (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 8 | SourceIdType | int | YES | Type classifier for SourceId. 1 = position ID (~51%), NULL = no linked entity (~49%), 2 = alternate source type (~0.06%), 0 = rare (8 rows). (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 9 | Occurred | datetime2(7) | YES | Timestamp when this transaction output was created/occurred. High precision (100ns). Used as the basis for ETL date partition columns (etr_y, etr_ym, etr_ymd). (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 10 | IsEtoroFee | bit | YES | Flag indicating whether this output represents an eToro fee transfer (1/True) or a customer-facing output (0/False). Downstream views filter on IsEtoroFee = 0 to exclude fee outputs. False: ~2.21M rows, True: ~1K rows. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 11 | NormalizedToAddress | varchar(max) | YES | Normalized version of ToAddress with protocol-specific parameters stripped (e.g., Ripple `?dt=0` suffix removed). Used for address matching and self-transfer detection in EXW_TransactionsView. (Tier 3 — WalletDB.Wallet.SentTransactionOutputs) |
| 12 | etr_y | varchar(max) | YES | ETL-added partition column: four-digit year extracted from Occurred (e.g., '2023'). Added by Generic Pipeline during ingestion. (Tier 2 — Generic Pipeline) |
| 13 | etr_ym | varchar(max) | YES | ETL-added partition column: year-month extracted from Occurred (e.g., '2023-03'). Added by Generic Pipeline during ingestion. (Tier 2 — Generic Pipeline) |
| 14 | etr_ymd | varchar(max) | YES | ETL-added partition column: year-month-day extracted from Occurred (e.g., '2023-03-16'). Added by Generic Pipeline during ingestion. (Tier 2 — Generic Pipeline) |
| 15 | SynapseUpdateDate | datetime | YES | Timestamp of the last Synapse ingestion/update for this row. Set by the Generic Pipeline during data loading. NULL in sampled data suggests this column may not be populated for all rows. (Tier 2 — Generic Pipeline) |
| 16 | partition_date | date | YES | Date-based partition key used for incremental loading and indexed for efficient date-range queries (NCI). Derived from Occurred date. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.SentTransactionOutputs | Id | Passthrough |
| SentTransactionId | WalletDB.Wallet.SentTransactionOutputs | SentTransactionId | Passthrough |
| ToAddress | WalletDB.Wallet.SentTransactionOutputs | ToAddress | Passthrough |
| Amount | WalletDB.Wallet.SentTransactionOutputs | Amount | Passthrough |
| EtoroFees | WalletDB.Wallet.SentTransactionOutputs | EtoroFees | Passthrough |
| BlockchainFees | WalletDB.Wallet.SentTransactionOutputs | BlockchainFees | Passthrough |
| SourceId | WalletDB.Wallet.SentTransactionOutputs | SourceId | Passthrough |
| SourceIdType | WalletDB.Wallet.SentTransactionOutputs | SourceIdType | Passthrough |
| Occurred | WalletDB.Wallet.SentTransactionOutputs | Occurred | Passthrough |
| IsEtoroFee | WalletDB.Wallet.SentTransactionOutputs | IsEtoroFee | Passthrough |
| NormalizedToAddress | WalletDB.Wallet.SentTransactionOutputs | NormalizedToAddress | Passthrough |
| etr_y | Generic Pipeline | — | Year from Occurred |
| etr_ym | Generic Pipeline | — | Year-month from Occurred |
| etr_ymd | Generic Pipeline | — | Year-month-day from Occurred |
| SynapseUpdateDate | Generic Pipeline | — | Ingestion timestamp |
| partition_date | Generic Pipeline | — | Date partition key |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.SentTransactionOutputs (production, WalletDB server)
  |-- Generic Pipeline (ID 710, Append, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/SentTransactionOutputs/ (Data Lake)
  |-- Generic Pipeline (Bronze import) ---|
  v
EXW_Wallet.SentTransactionOutputs (2,212,095 rows, Synapse)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_senttransactionoutputs (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| SentTransactionId | EXW_Wallet.SentTransactions | FK to parent send transaction (Id) |
| SourceId | (context-dependent) | When SourceIdType = 1, references a position ID |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Type | Usage |
|---|---|---|
| EXW_Wallet.EXW_TransactionsView | View | Joins on SentTransactionId to build unified transaction ledger |
| EXW_dbo.SP_EXW_FactRedeemTransactions | SP | Reads outputs to build redeem fact table; joins on SourceId = PositionId |
| EXW_dbo.SP_EXW_C2F_E2E | SP | Joins on SentTransactionId for crypto-to-fiat tracking |

---

## 7. Sample Queries

### 7.1 Count outputs per sent transaction

```sql
SELECT SentTransactionId,
       COUNT(*) AS output_count,
       SUM(Amount) AS total_amount
FROM EXW_Wallet.SentTransactionOutputs
WHERE partition_date >= '2026-01-01'
  AND IsEtoroFee = 0
GROUP BY SentTransactionId
HAVING COUNT(*) > 1
ORDER BY output_count DESC;
```

### 7.2 Daily output volume and amount

```sql
SELECT partition_date,
       COUNT(*) AS output_count,
       SUM(Amount) AS total_amount
FROM EXW_Wallet.SentTransactionOutputs
WHERE IsEtoroFee = 0
  AND partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date;
```

### 7.3 Identify fee vs. customer outputs

```sql
SELECT IsEtoroFee,
       COUNT(*) AS cnt,
       SUM(Amount) AS total_amount,
       AVG(Amount) AS avg_amount
FROM EXW_Wallet.SentTransactionOutputs
WHERE partition_date >= '2025-01-01'
GROUP BY IsEtoroFee;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 11 T3, 0 T4, 0 T5 | Elements: 16/16, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.SentTransactionOutputs | Type: Table | Production Source: WalletDB.Wallet.SentTransactionOutputs (Generic Pipeline)*
