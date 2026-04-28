# Compare — `EXW_dbo.EXW_FactTransactions`

**Bucket**: `good`

**Verdict**: **EQUIVALENT**  (score delta -0.3; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 9.6 | 9.3 | -0.3 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 45 | 45 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 21 | 24 | +3 |
| T2 count | 24 | 21 | -3 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 10 | 10 |
| completeness | 10 | 10 |
| data_evidence | 9 | 7 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 9 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `42` | 0.045 | 2 | 1 | Date portion of Occurred. CAST(Occurred AS DATE). Enables day-level grouping by actual occurrence date vs. TranDate (blockchain-assigned date). Column name has legacy typo 'DateOccured' (not 'DateOccu | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. DWH note: CAST of Occurred to DATE, dropping the time component. Intentional m |
| `2` | 0.081 | 2 | 1 | Platform-internal customer ID from DWH_dbo.Dim_Customer, joined on GCID. NULL for omnibus/system wallets (GCID=0) and customers not yet in Dim_Customer. Enables joins to DWH fact tables that key on Re | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer via GCID looku |
| `41` | 0.176 | 2 | 1 | Transaction date stored as datetime. Same value as TranDate (derived from TransDate) but as datetime type. Added for compatibility with datetime filtering in reporting tools. (Tier 2 — SP_EXW_Fact_Tra | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. DWH note: identical to TranDate source (TransDate from the view) but stored as dat |
| `37` | 0.258 | 2 | 2 | Name of the underlying blockchain asset. For ERC-20 tokens: 'ETH'. For native coins: equals CryptoName. From EXW_Wallet.CryptoTypes.Name where CryptoId=BlockchainCryptoId. (Tier 2 — SP_EXW_Fact_Transa | Name of the underlying blockchain cryptocurrency. Resolved via two-hop lookup: CryptoTypes[CryptoId].BlockchainCryptoId → CryptoTypes[BlockchainCryptoId].Name. (Tier 2 — SP_EXW_Fact_Transactions, EXW_ |
| `33` | 0.296 | 2 | 2 | Flag: 1 if this transaction is a crypto redemption (withdrawal to blockchain). Sent: TransactionTypeID IN (0=Redeem, 8=RedeemAsic). Received: ReceivedTransactionTypeID IN (2=Redeem, 7) OR matching blo | ETL-computed redemption flag. Sent: 1 when TransactionTypeID IN (0,8). Received: 1 when ReceivedTransactionTypeID IN (2,7) or blockchain match to a sent redeem. 0 otherwise. (Tier 2 — SP_EXW_Fact_Tran |
| `36` | 0.297 | 2 | 2 | Cryptocurrency ID of the underlying blockchain asset. For ERC-20 tokens (USDEX, EURX, GBPX): BlockchainCryptoId=2 (ETH). For native coins: equals CryptoId. From EXW_Wallet.CryptoTypes.BlockchainCrypto | Underlying blockchain cryptocurrency ID. Resolved from EXW_Wallet.CryptoTypes.BlockchainCryptoId by CryptoId lookup. Differs from CryptoId for tokens running on another chain (e.g., ERC-20 tokens have |
| `27` | 0.341 | 2 | 2 | AML provider decision for this transaction. Values: Amber (needs review), NA (not applicable), Green (clear), Red (flagged), Error (provider error). Joined from EXW_Wallet.AmlValidations (most-recent  | AML screening provider status from EXW_Wallet.AmlValidations. Most recent validation per transaction. Values: Green, Amber, Red, Error. NULL if not screened. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wa |
| `13` | 0.344 | 2 | 2 | eToro platform fee normalized by exchange rate: source EtoroFees × FeeExchangeRate. For most types FeeExchangeRate=1; for ConversionOut the fee is normalized to the destination crypto's value basis. D | eToro platform fees pre-multiplied by FeeExchangeRate in the SP. DWH note: computed as view.EtoroFees * view.FeeExchangeRate, unlike the source view where these are separate columns. (Tier 2 — SP_EXW_ |
| `45` | 0.355 | 2 | 2 | Human-readable type name for received transactions. From CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes.Name, joined on ReceivedTransactionTypeID. NULL for all sent transactions and ~76% of | Human-readable received transaction type name from CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes. NULL for sent transactions. Values include MoneyIn, Redeem. (Tier 2 — SP_EXW_Fact_Transact |
| `40` | 0.385 | 2 | 2 | Flag from EXW_Wallet.CryptoTypes indicating whether this crypto uses eToro's handling fee model. 0=standard provider-fee model (BTC, ETH, etc.). From EXW_Wallet.CryptoTypes.IsEtoroHandlingFee, joined  | Whether this cryptocurrency carries an eToro handling fee. Resolved from EXW_Wallet.CryptoTypes.IsEtoroHandlingFee by CryptoId lookup. Property of the crypto type, not the individual transaction. (Tie |

## Top issues — regen wiki (per judge)

- [medium] `Footer` — Footer claims '22 T1, 23 T2' but actual element count is 24 Tier 1 and 21 Tier 2. Off by 2 in each direction.
- [low] `Footer / Phase Gate` — No formal Phase Gate Checklist section. Footer says 'Phases: 12/14' without specifying which phases were completed or skipped. Cannot verify P2/P3 status.
- [low] `RealCID` — Tier 1 description adds 'Passthrough from Dim_Customer via GCID lookup.' beyond verbatim upstream text from Dim_Customer wiki. No semantic loss but technically non-verbatim.
- [low] `TranDateTime, DateOccured` — Both columns append 'DWH note:' clauses after verbatim upstream text. Informative additions but deviate from pure Tier 1 verbatim standard.
- [low] `TransactionTypeID` — Enum list omits type 4 (Funding), which is referenced by IsFunding flag (TransactionTypeID=4 for sent). This matches the upstream verbatim text which also omits it (type 4 falls into the 'other_transactions' catch-all CTE), but analysts may be confused by the inconsistency.
