# EXW_dbo.EXW_FactRedeemTransactions

> Fact table for crypto redemption transactions — 1.13M rows covering redemptions from 2018-10-09 to 2026-04-19. Each row represents one sent transaction output for a redemption, joining position-to-crypto conversion requests (Wallet.Redemptions) with the blockchain execution (SentTransactions, ReceivedTransactions) and fee details.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Redemptions (primary) + WalletDB.Wallet.SentTransactions + WalletDB.Wallet.SentTransactionOutputs + WalletDB.Wallet.ReceivedTransactions |
| **Refresh** | Daily — SP_EXW_FactRedeemTransactions @d DATE; DELETE by RedeemID + INSERT (today + re-run incomplete positions) |
| **Synapse Distribution** | HASH (RedeemID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only wallet redemption fact |

---

## 1. Business Meaning

EXW_FactRedeemTransactions is the definitive fact table for crypto redemptions in eToro Wallet. A redemption is the process where a customer converts a trading position (CFD or real) into actual cryptocurrency deposited into their wallet. Each row records one redemption's blockchain execution: the position redeemed, the crypto amount sent, fees charged, and the confirmation that the crypto arrived in the customer's wallet.

With 1.13 million rows spanning 2018-10-09 to 2026-04-19, the table covers 149,817 distinct users across 57 cryptocurrency types. XRP is the most redeemed asset (41%), followed by BTC (23%) and ETH (12.6%).

The ETL SP runs daily for `@d`, processing new redemptions where `BeginDate = @d`. A re-run mechanism catches positions where `FinalRedeemStatus = 'Completed'` but `ReceivedTransactionID` is NULL (received transaction not yet confirmed at time of initial insert). These are reprocessed until received confirmation is found.

99.9% of rows have `FinalRedeemStatus = 'Completed'`. Two columns (`eToroFeeAmount`, `ReceivedBlockchainFees`) and one derived column (`TotalSentAmountInBCTX`) are always NULL — these are deprecated columns retained for schema backward compatibility. Use `SentEtoroFees` for the actual eToro fee and `SentBlockchainFees` for the per-output blockchain fee.

---

## 2. Business Logic

### 2.1 Redemption Execution Flow

**What**: A redemption connects a trading position to a blockchain transfer from eToro's omnibus wallet to the customer's wallet.

**Columns Involved**: RedeemID, PositionID, RequestingGcid, SentTransactionID, BlockchainTransactionID, FinalRedeemStatus

**Flow**:
1. Customer requests redemption → Wallet.AddNewRedemptionRequest creates Wallet.Redemptions record
2. HandlePendingRedemptions picks up the request → Wallet.Requests + Wallet.RequestStatuses track status
3. Blockchain provider (BitGo) broadcasts the transaction → Wallet.SentTransactions created
4. Customer's wallet receives the crypto → Wallet.ReceivedTransactions created
5. SP joins all four sources to produce this row

### 2.2 FinalRedeemStatus Logic

**What**: Status is derived from the latest RequestStatus for the Redemption's SendRequestCorrelationId.

**Columns Involved**: FinalRedeemStatus

**Values**:
- `Completed`: RequestStatuses.RequestStatusId = 1 — blockchain transfer confirmed
- `Error`: RequestStatuses.RequestStatusId = 2 — transfer failed
- `Pending`: Any other status — transfer in progress or not yet sent

### 2.3 Fee Structure

**What**: Multiple fee columns exist; only some are populated.

**Columns Involved**: eToroFeeAmount, SentEtoroFees, SentBlockchainFees, EffectiveBlockchainFees

**Rules**:
- `eToroFeeAmount` — always NULL (SP explicitly sets to NULL; source value from Redemptions.eToroFeeAmount is discarded). Do not use.
- `SentEtoroFees` — actual eToro fee: `CAST(EtoroFees × FeeExchangeRate AS NUMERIC(38,8))` from External_WalletDB_Wallet_TransactionsView. Use this for fee analysis.
- `SentBlockchainFees` — per-output blockchain fee allocation: `SentTransactions.BlockchainFee / COUNT(outputs per tx)`. Divides network fee across transaction outputs.
- `EffectiveBlockchainFees` — passthrough from TransactionsView. May differ from SentBlockchainFees; represents the fee actually charged to the customer after any eToro subsidization.

### 2.4 ReceivedTransactionID Re-run Logic

**What**: The SP detects incomplete rows (Completed but no received confirmation) and reprocesses them to fill in ReceivedTransactionID and ReceivedAmount.

**Columns Involved**: ReceivedTransactionID, ReceivedAmount, FinalRedeemStatus

**Rules**:
- On each daily run, the SP identifies existing rows where `ReceivedTransactionID IS NULL AND FinalRedeemStatus = 'Completed'` and the blockchain tx is not in SentTransactionReplaces (BitGo replacements excluded)
- Those PositionIDs are re-fetched from source and reinserted with received tx data
- 725 rows currently have NULL ReceivedTransactionID — these are in-flight or awaiting blockchain confirmation

### 2.5 BitGo Transaction Replacement Exclusion

**What**: BitGo sometimes replaces a broadcast transaction with an updated one (RBF pattern). The original transaction's hash is tracked in SentTransactionReplaces.

**Columns Involved**: BlockchainTransactionID

**Rules**:
- Rows where `BlockchainTransactionID` matches `SentTransactionReplaces.OldBlockchainTransactionId` are excluded from the re-run re-fetch
- This prevents the re-run from fetching received transactions for replaced (superseded) tx hashes

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RedeemID) distribution with HEAP. Queries joining on RedeemID will benefit from colocation. No clustered index — full scans for range queries on SentTime or RequestingGcid. Always filter early.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All redemptions for a user | `WHERE RequestingGcid = @gcid ORDER BY SentTime DESC` |
| Completed redemptions in a period | `WHERE FinalRedeemStatus = 'Completed' AND SentTime BETWEEN @start AND @end` |
| Fee analysis by crypto | `SELECT CryptoId, SUM(SentEtoroFees) FROM ... GROUP BY CryptoId` |
| Unconfirmed redemptions | `WHERE FinalRedeemStatus = 'Completed' AND ReceivedTransactionID IS NULL` |
| XRP redemptions | `WHERE CryptoId = 4` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | RequestingGcid = GCID | User demographic enrichment |
| EXW_dbo.EXW_FactBalance | RequestingGcid = GCID, CryptoId = CryptoId | Balance at redemption time |

### 3.4 Gotchas

- **eToroFeeAmount is always NULL**: The SP explicitly sets `eToroFeeAmount = NULL`. Use `SentEtoroFees` for the actual eToro fee in native crypto units
- **TotalSentAmountInBCTX and ReceivedBlockchainFees are always NULL**: Deprecated columns retained for schema compatibility — never populated
- **ReceivingGCID = RequestingGcid in 99.9% of cases**: The SP sets `ReceivingGCID = rd.RequestingGcid` — the requesting customer is always the recipient in standard redemptions
- **IsEtoroFee = 0 for all rows**: The SP filters outputs by `SourceId = PositionId`, which selects only value-transfer outputs (not fee outputs). IsEtoroFee will always be 0 in this table
- **ReceivedTransactionID can be NULL**: 725 rows lack received confirmation — these are in-flight redemptions or awaiting late-arriving blockchain events
- **BlockchainTransactionID cast to nvarchar(4000)**: The DDL type is nvarchar(max) but the SP casts to nvarchar(4000) on insert
- **SentBlockchainFees is per-output, not per-transaction**: For multi-output Bitcoin transactions, SentBlockchainFees = BlockchainFee / COUNT(outputs). Sum per-transaction rather than per-output if computing total tx cost

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki (WalletDB.Wallet.Redemptions, SentTransactions, SentTransactionOutputs, or ReceivedTransactions) |
| Tier 2 | Derived from SP code analysis — ETL-computed, lookup-enriched, hardcoded, or sourced without upstream wiki |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best guess — no code or wiki evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RedeemID | bigint | NULL | Auto-incrementing surrogate primary key. Renamed from WalletDB.Wallet.Redemptions.Id. Distribution key for HASH(RedeemID). (Tier 1 — WalletDB.Wallet.Redemptions) |
| 2 | PositionID | bigint | NULL | Trading platform position being redeemed. Unique constraint - each position can only be redeemed once. NULL only for legacy records. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 3 | RequestingGcid | bigint | NULL | Global Customer ID of the customer requesting the redemption. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 4 | CryptoId | int | NULL | The cryptocurrency being redeemed. Implicit reference to Wallet.CryptoTypes.CryptoID. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 5 | RequestedAmount | numeric(38,8) | NULL | Gross amount of crypto requested for redemption. In native units of CryptoId. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 6 | eToroFeeAmount | numeric(38,8) | NULL | Always NULL in this table. SP explicitly sets `eToroFeeAmount = NULL` (overriding the source value from Redemptions). Do not use — see SentEtoroFees for the actual fee. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 7 | FinalRedeemStatus | varchar(30) | NULL | Redemption lifecycle outcome derived from latest RequestStatuses record. Values: Completed (RequestStatusId=1), Error (RequestStatusId=2), Pending (any other status). (Tier 2 — SP_EXW_FactRedeemTransactions via EXW_Wallet.RequestStatuses) |
| 8 | SentTransactionID | bigint | NULL | Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. Renamed from WalletDB.Wallet.SentTransactions.Id. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 9 | BlockchainTransactionID | nvarchar(max) | NULL | The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). Stored as nvarchar(4000) on insert despite nvarchar(max) DDL type. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 10 | SendingWalletID | uniqueidentifier | NULL | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer's wallet. For redemptions, this is the system's omnibus/redeem wallet. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 11 | SentTime | datetime | NULL | Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. Renamed from WalletDB.Wallet.SentTransactions.Occurred; CAST as datetime on insert. (Tier 1 — WalletDB.Wallet.SentTransactions) |
| 12 | SendingGCID | bigint | NULL | GCID of the wallet owner who holds the sending wallet. Lookup from EXW_Wallet.CustomerWalletsView.Gcid by SentTransactions.WalletId. For redemptions this is the omnibus wallet owner, not the redemption customer. (Tier 2 — SP_EXW_FactRedeemTransactions via EXW_Wallet.CustomerWalletsView) |
| 13 | SendingAddress | nvarchar(512) | NULL | Blockchain address of the sending wallet. Lookup from EXW_Wallet.CustomerWalletsView.Address by SentTransactions.WalletId. (Tier 2 — SP_EXW_FactRedeemTransactions via EXW_Wallet.CustomerWalletsView) |
| 14 | ReceiveAddress | nvarchar(512) | NULL | Destination blockchain address for this output. Renamed from WalletDB.Wallet.SentTransactionOutputs.ToAddress; filtered by SourceId = PositionId to select the redemption-specific output. (Tier 1 — WalletDB.Wallet.SentTransactionOutputs) |
| 15 | SentAmount | numeric(38,8) | NULL | Amount of crypto sent to this output address. Renamed from WalletDB.Wallet.SentTransactionOutputs.Amount; row with highest Amount per SentTransactionId selected via ROW_NUMBER. (Tier 1 — WalletDB.Wallet.SentTransactionOutputs) |
| 16 | SentEtoroFees | numeric(38,8) | NULL | eToro service fee for this redemption, converted to a common currency. Computed as CAST(SentTransactionOutputs.EtoroFees × TransactionsView.FeeExchangeRate AS NUMERIC(38,8)). Use this column instead of eToroFeeAmount, which is always NULL. (Tier 2 — SP_EXW_FactRedeemTransactions via External_WalletDB_Wallet_TransactionsView) |
| 17 | SentBlockchainFees | numeric(38,8) | NULL | Network fee allocated to this redemption output. Computed as SentTransactions.BlockchainFee / COUNT(outputs per SentTransactionId). For single-output txs equals the full tx fee; for multi-output UTXO txs, split proportionally. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 18 | IsEtoroFee | int | NULL | Whether this output represents an eToro fee payment rather than a value transfer. 1=fee output, 0/NULL=value output. Always 0 in this table — the SP filters by SourceId = PositionId, selecting only value-transfer outputs. (Tier 1 — WalletDB.Wallet.SentTransactionOutputs) |
| 19 | TotalSentAmountInBCTX | numeric(38,8) | NULL | Always NULL. Deprecated column retained for schema backward compatibility. SP comment: "this is no longer needed, but no point in starting to make changes to tables." Do not use. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 20 | ReceivedTransactionID | bigint | NULL | Auto-incrementing primary key of the matching ReceivedTransaction. FK target for Wallet.ReceivedTransactionStatuses. Renamed from WalletDB.Wallet.ReceivedTransactions.Id. NULL if the received transaction has not yet been detected (725 rows). (Tier 1 — WalletDB.Wallet.ReceivedTransactions) |
| 21 | ReceivedAmount | numeric(38,8) | NULL | Amount of crypto received in native units. NULL for zero-value transactions (e.g., token approvals). Sourced from WalletDB.Wallet.ReceivedTransactions.Amount, matched by BlockchainTransactionId + ReceiverAddress = ReceiveAddress. (Tier 1 — WalletDB.Wallet.ReceivedTransactions) |
| 22 | ReceivedBlockchainFees | numeric(38,8) | NULL | Always NULL. Deprecated column retained for schema backward compatibility. Do not use. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 23 | ReceivingGCID | bigint | NULL | Global Customer ID of the customer receiving the redeemed crypto. Set to Redemptions.RequestingGcid by the SP — the requesting customer is always the recipient in standard redemptions. (Tier 1 — WalletDB.Wallet.Redemptions) |
| 24 | TotalrxAmountInBCTX | numeric(38,8) | NULL | Total amount received in the blockchain transaction. Computed as MAX(ReceivedAmount) GROUP BY ReceivedTransactionID across all rows in the batch. Represents the total crypto received in that specific on-chain tx. NULL if ReceivedTransactionID is NULL. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 25 | CountReceivedTXInBCTX | int | NULL | Count of outputs in the received blockchain transaction. Computed as COUNT(ReceivedAmount) GROUP BY ReceivedTransactionID. Used with TotalrxAmountInBCTX to compute ReceivedInAllTXTable. NULL if ReceivedTransactionID is NULL. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 26 | ReceivedInAllTXTable | numeric(38,8) | NULL | Per-output average received amount. Computed as TotalrxAmountInBCTX / CountReceivedTXInBCTX. Represents ReceivedAmount normalized across all outputs of the blockchain tx. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 27 | UpdateDate | datetime | NULL | Timestamp of when this row was inserted into EXW_FactRedeemTransactions. Set to GETDATE() at insert time by the SP. (Tier 2 — SP_EXW_FactRedeemTransactions) |
| 28 | EffectiveBlockchainFees | numeric(38,8) | NULL | Actual blockchain fee charged to the customer after any eToro subsidization. Sourced from EXW_dbo.External_WalletDB_Wallet_TransactionsView.EffectiveBlockchainFee (ActionTypeId=1 filter). May differ from SentBlockchainFees. (Tier 2 — SP_EXW_FactRedeemTransactions via External_WalletDB_Wallet_TransactionsView) |
| 29 | BlockchainCryptoId | int | NULL | The underlying blockchain cryptocurrency ID for this redemption's crypto asset. Lookup from EXW_Wallet.CryptoTypes.BlockchainCryptoId by CryptoId. Distinguishes token cryptos (e.g., USDC) from their blockchain (e.g., ETH). NULL if CryptoTypes match not found. (Tier 2 — SP_EXW_FactRedeemTransactions via EXW_Wallet.CryptoTypes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RedeemID | WalletDB.Wallet.Redemptions | Id | Renamed |
| PositionID | WalletDB.Wallet.Redemptions | PositionId | Passthrough |
| RequestingGcid | WalletDB.Wallet.Redemptions | RequestingGcid | Passthrough |
| CryptoId | WalletDB.Wallet.Redemptions | CryptoId | Passthrough |
| RequestedAmount | WalletDB.Wallet.Redemptions | RequestedAmount | Passthrough |
| eToroFeeAmount | SP override | — | Hardcoded NULL |
| FinalRedeemStatus | WalletDB.Wallet.RequestStatuses | RequestStatusId | CASE: 1=Completed, 2=Error, else=Pending |
| SentTransactionID | WalletDB.Wallet.SentTransactions | Id | Renamed |
| BlockchainTransactionID | WalletDB.Wallet.SentTransactions | BlockchainTransactionId | Passthrough |
| SendingWalletID | WalletDB.Wallet.SentTransactions | WalletId | Passthrough |
| SentTime | WalletDB.Wallet.SentTransactions | Occurred | Renamed, CAST datetime |
| ReceiveAddress | WalletDB.Wallet.SentTransactionOutputs | ToAddress | Renamed |
| SentAmount | WalletDB.Wallet.SentTransactionOutputs | Amount | Passthrough |
| IsEtoroFee | WalletDB.Wallet.SentTransactionOutputs | IsEtoroFee | Passthrough |
| ReceivedTransactionID | WalletDB.Wallet.ReceivedTransactions | Id | Renamed |
| ReceivedAmount | WalletDB.Wallet.ReceivedTransactions | Amount | Passthrough |
| ReceivingGCID | WalletDB.Wallet.Redemptions | RequestingGcid | Passthrough (semantic alias) |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Redemptions
  (position-to-crypto redemption requests — GCID, CryptoId, RequestedAmount)
  |
  | via EXW_Wallet schema (CopyFromLake Bronze → Synapse External Tables)
  |
  + EXW_Wallet.Requests + EXW_Wallet.RequestStatuses → FinalRedeemStatus
  + EXW_Wallet.SentTransactions → blockchain tx execution details
  + EXW_Wallet.SentTransactionOutputs → per-output destination + amounts
  + EXW_Wallet.ReceivedTransactions → confirmation of customer wallet receipt
  + EXW_Wallet.CustomerWalletsView → SendingGCID, SendingAddress
  + EXW_dbo.External_WalletDB_Wallet_TransactionsView → SentEtoroFees, EffectiveBlockchainFees
  + EXW_Wallet.SentTransactionReplaces → BitGo replacement exclusion
  + EXW_Wallet.CryptoTypes → BlockchainCryptoId
    |
    | SP_EXW_FactRedeemTransactions @d DATE
    | DELETE by RedeemID in (today's + re-run positions) + INSERT
    v
EXW_dbo.EXW_FactRedeemTransactions (1.13M rows — Synapse)
    |
    +-- Finance redemption reporting (ad-hoc)
    +-- EXW_dbo.EXW_ReimbursementFollowUp (fee reconciliation)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RequestingGcid / ReceivingGCID | EXW_dbo.EXW_DimUser | User dimension for demographic enrichment |
| CryptoId | EXW_Wallet.CryptoTypes | Crypto asset name lookup |
| SentTransactionID | EXW_Wallet.SentTransactions | Source sent transaction detail |
| ReceivedTransactionID | EXW_Wallet.ReceivedTransactions | Source received transaction confirmation |
| RedeemID | EXW_Wallet.Redemptions | Source redemption lifecycle record |

### 6.2 Referenced By

| Source Object | Join Column | Description |
|--------------|-------------|-------------|
| EXW_dbo.EXW_ReimbursementFollowUp | RedeemID / RequestingGcid | Tracks reimbursement status for failed/problematic redemptions |

---

## 7. Sample Queries

### 7.1 All redemptions for a customer with fees and status

```sql
SELECT
    RedeemID,
    PositionID,
    CryptoId,
    RequestedAmount,
    SentEtoroFees,
    SentBlockchainFees,
    EffectiveBlockchainFees,
    FinalRedeemStatus,
    SentTime,
    BlockchainTransactionID
FROM EXW_dbo.EXW_FactRedeemTransactions
WHERE RequestingGcid = 12345678
ORDER BY SentTime DESC;
```

### 7.2 Completed redemptions without received confirmation (in-flight)

```sql
SELECT
    RedeemID,
    RequestingGcid,
    CryptoId,
    SentAmount,
    BlockchainTransactionID,
    SentTime
FROM EXW_dbo.EXW_FactRedeemTransactions
WHERE FinalRedeemStatus = 'Completed'
  AND ReceivedTransactionID IS NULL
ORDER BY SentTime;
```

### 7.3 Redemption volume and fees by crypto for a period

```sql
SELECT
    CryptoId,
    COUNT(*) AS RedemptionCount,
    SUM(RequestedAmount) AS TotalRequestedAmt,
    SUM(SentAmount) AS TotalSentAmt,
    SUM(SentEtoroFees) AS TotalEtoroFees,
    SUM(EffectiveBlockchainFees) AS TotalBlockchainFees
FROM EXW_dbo.EXW_FactRedeemTransactions
WHERE FinalRedeemStatus = 'Completed'
  AND SentTime >= '2026-01-01'
GROUP BY CryptoId
ORDER BY RedemptionCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found. SP header notes: created by Guy Manova (initial); modified by Inessa Kontorovich (2022-04-26 — join fixes to eliminate duplicates, temp table separation, added re-run logic for late received transactions; 2022-05-02 — replaced join by blockchain to join by crypto ID; 2024-12-08 — added condition to exclude self-receives from ReceivedTransactions matching).

---

*Generated: 2026-04-20 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 15 T1, 14 T2, 0 T3, 0 T4, 0 T5 | Elements: 29/29, Logic: 9/10, Sources: 8/10*
*Object: EXW_dbo.EXW_FactRedeemTransactions | Type: Table | Production Source: WalletDB.Wallet.Redemptions + WalletDB.Wallet.SentTransactions + SentTransactionOutputs + ReceivedTransactions*
