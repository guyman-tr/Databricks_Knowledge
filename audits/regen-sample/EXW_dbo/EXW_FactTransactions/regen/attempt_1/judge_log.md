I'll start by verifying a few things before scoring. Let me check for the Dim_Customer wiki (for RealCID's claimed Tier 1 origin) and verify the tier counts.
Good — the Dim_Customer wiki exists and documents RealCID as: *"Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)"*

Let me verify the actual Tier 1 count in the wiki vs the footer claim.
Confirmed: **24 Tier 1** and **21 Tier 2** columns in the elements table, but the footer claims "22 T1, 23 T2". Off by 2 in each direction. Now I have everything I need for the verdict.

---

## Adversarial Judge Review — EXW_dbo.EXW_FactTransactions

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: RealCID (#2), TranStatus (#9), FeeExchangeRate (#15), BlockchainCryptoId (#36), ReceivedTransactionTypeID (#44). All five tier assignments are correct:
- RealCID: Dim-lookup passthrough traced to dim's root origin (Customer.CustomerStatic) — correctly Tier 1.
- TranStatus: Passthrough from Wallet.TransactionsView with upstream wiki present — correctly Tier 1.
- FeeExchangeRate: Passthrough from Wallet.TransactionsView — correctly Tier 1.
- BlockchainCryptoId: Lookup from EXW_Wallet.CryptoTypes (no upstream wiki) — correctly Tier 2.
- ReceivedTransactionTypeID: Enrichment from EXW_Wallet.ReceivedTransactions (no upstream wiki) — correctly Tier 2.

Zero mismatches. No paraphrasing failures on sampled Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **9/10**

All 22 Wallet.TransactionsView-sourced Tier 1 columns carry verbatim upstream descriptions. RealCID correctly traces through Dim_Customer to its root origin (Customer.CustomerStatic) with the Dim_Customer wiki's description preserved verbatim. Three columns add DWH-context notes after the upstream text (no semantic loss):

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| GCID | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. | YES | — |
| RealCID | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. *(from Dim_Customer wiki)* | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer via GCID lookup. | MINOR | Added DWH routing context; no upstream text lost |
| CryptoId | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. | YES | — |
| WalletID | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. | YES | — |
| TranID | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. | YES | — |
| TranStatusID | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. | YES | — |
| TranStatus | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. | YES | — |
| TranDate | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. | YES | — |
| Amount | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. | YES | — |
| ProviderFees | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. | YES | — |
| FeeExchangeRate | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. | YES | — |
| BlockchainFees | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. | YES | — |
| EstimatedBlockchainFee | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. | YES | — |
| ActionTypeID | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. | YES | — |
| ActionTypeName | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). | YES | — |
| SenderAddress | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). | YES | — |
| ReciverAddress | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. | YES | — |
| BlockchainTransactionId | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. | YES | — |
| TransactionTypeID | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. | YES | — |
| TransactionType | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. | YES | — |
| Occurred | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. | YES | — |
| TranDateTime | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. DWH note: identical to TranDate source (TransDate from the view) but stored as datetime instead of date. | MINOR | Added DWH type note; no upstream text lost |
| DateOccured | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. DWH note: CAST of Occurred to DATE, dropping the time component. Intentional misspelling 'Occured'. | MINOR | Added DWH note; no upstream text lost |
| LastStatusUpdateOccurred | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). | YES | — |

21 exact matches, 3 MINOR (additive DWH context, zero semantic loss). No paraphrasing, no dropped vendor names, no lost NULL semantics. Excellent.

### Dimension 3 — Completeness: **10/10**

All 10 structural checks pass:
- [x] All 8 sections present
- [x] 45 elements = 45 DDL columns
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII with real object names
- [x] Footer has tier breakdown counts (present, though values are wrong — see issues)
- [x] Section 1 has row count (4.7M) and date range (April 2018–present)
- [x] Dictionary columns list values inline (ActionTypeID, TranStatus, TransactionTypeID, AMLProviderStatus)
- [x] `.review-needed.md` Section 4 is "Tier Distribution", not Elements

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. It names the domain (crypto wallet transactions), the row grain (single blockchain transaction — sent or received), the ETL SP, the refresh pattern (daily DELETE+INSERT by TranID+ActionTypeID), row count (4.7M), date range (April 2018–April 2026), cardinalities (128 cryptos, 285K customers), and even the 2026 YTD distribution breakdown. A brand-new analyst would know exactly when and how to query this table.

### Dimension 5 — Data Evidence: **7/10**

Row count, date range, crypto/customer cardinalities, status distribution (99.8% Verified), and sent-type breakdown (41% CustomerMoneyOut, 40% Redeem, 18% ConversionToFiat) all appear. However, there is no formal Phase Gate Checklist section with P2/P3 checkboxes. The footer says "Phases: 12/14" but doesn't specify which phases were skipped. Data claims are plausible and specific enough to suggest live queries were run.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases count. Minor deviations: no formal Phase Gate Checklist section, and footer quality metadata uses a compact single-line format rather than a structured checklist.

### Weighted Total

```
weighted = 0.25×10 + 0.20×9 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×8
         = 2.50 + 1.80 + 2.00 + 1.50 + 0.70 + 0.80
         = 9.30
```

### Top Issues

1. **Footer tier counts are wrong** — claims "22 T1, 23 T2" but actual count is 24 T1, 21 T2 (off by 2 in each direction).
2. **No formal Phase Gate Checklist** — footer says "Phases: 12/14" without specifying which phases were completed or skipped. Cannot verify P2/P3 status.
3. **RealCID description adds routing context** — "Passthrough from Dim_Customer via GCID lookup" is appended beyond the upstream verbatim text. Harmless but non-verbatim.
4. **TranDateTime/DateOccured add DWH notes** — both append "DWH note:" clauses after the verbatim upstream text. Informative but technically deviates from pure Tier 1 verbatim standard.
5. **TransactionTypeID omits type 4 (Funding)** — the enum list (0, 5, 6, 7, 8, 9) comes verbatim from upstream, but the IsFunding flag documents `TransactionTypeID=4` for sent. The upstream view's "other_transactions" CTE catches type 4, so this is an upstream documentation gap — not a wiki error per se, but worth noting for analyst awareness.

### Regeneration Feedback (minor fixes only)

1. Fix footer tier counts from "22 T1, 23 T2" to "24 T1, 21 T2".
2. Add a formal Phase Gate Checklist section or expand the footer to list which phases were completed/skipped.
3. *(Optional)* Note TransactionTypeID=4 (Funding) in the enum values for completeness, even though the upstream omits it.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_FactTransactions",
  "weighted_score": 9.30,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "GCID",
      "upstream_quote": "Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid.",
      "wiki_quote": "Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer via GCID lookup.",
      "match": "MINOR",
      "loss": "Added DWH routing context ('Passthrough from Dim_Customer via GCID lookup'); no upstream text lost"
    },
    {
      "column": "CryptoId",
      "upstream_quote": "The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId.",
      "wiki_quote": "The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "WalletID",
      "upstream_quote": "The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId.",
      "wiki_quote": "The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TranID",
      "upstream_quote": "Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish.",
      "wiki_quote": "Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TranStatusID",
      "upstream_quote": "Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus.",
      "wiki_quote": "Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TranStatus",
      "upstream_quote": "Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval.",
      "wiki_quote": "Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TranDate",
      "upstream_quote": "Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate.",
      "wiki_quote": "Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Amount",
      "upstream_quote": "Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for \"other\" types.",
      "wiki_quote": "Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for \"other\" types.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ProviderFees",
      "upstream_quote": "External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types.",
      "wiki_quote": "External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FeeExchangeRate",
      "upstream_quote": "Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives.",
      "wiki_quote": "Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "BlockchainFees",
      "upstream_quote": "Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives.",
      "wiki_quote": "Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "EstimatedBlockchainFee",
      "upstream_quote": "Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives.",
      "wiki_quote": "Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ActionTypeID",
      "upstream_quote": "Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block.",
      "wiki_quote": "Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ActionTypeName",
      "upstream_quote": "Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility).",
      "wiki_quote": "Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "SenderAddress",
      "upstream_quote": "Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender).",
      "wiki_quote": "Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ReciverAddress",
      "upstream_quote": "Receiver's blockchain address (legacy misspelling \"Reciver\"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress.",
      "wiki_quote": "Receiver's blockchain address (legacy misspelling \"Reciver\"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "BlockchainTransactionId",
      "upstream_quote": "On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions.",
      "wiki_quote": "On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TransactionTypeID",
      "upstream_quote": "Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes.",
      "wiki_quote": "Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TransactionType",
      "upstream_quote": "Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions.",
      "wiki_quote": "Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Occurred",
      "upstream_quote": "When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred.",
      "wiki_quote": "When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "TranDateTime",
      "upstream_quote": "Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate.",
      "wiki_quote": "Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. DWH note: identical to TranDate source (TransDate from the view) but stored as datetime instead of date.",
      "match": "MINOR",
      "loss": "Added DWH type note after verbatim upstream text; no semantic loss"
    },
    {
      "column": "DateOccured",
      "upstream_quote": "When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred.",
      "wiki_quote": "When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. DWH note: CAST of Occurred to DATE, dropping the time component. Intentional misspelling 'Occured'.",
      "match": "MINOR",
      "loss": "Added DWH note after verbatim upstream text; no semantic loss"
    },
    {
      "column": "LastStatusUpdateOccurred",
      "upstream_quote": "Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables \"time since last update\" monitoring and SLA tracking. New in this version (not in TransactionViewOld).",
      "wiki_quote": "Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables \"time since last update\" monitoring and SLA tracking. New in this version (not in TransactionViewOld).",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '22 T1, 23 T2' but actual element count is 24 Tier 1 and 21 Tier 2. Off by 2 in each direction."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No formal Phase Gate Checklist section. Footer says 'Phases: 12/14' without specifying which phases were completed or skipped. Cannot verify P2/P3 status."
    },
    {
      "severity": "low",
      "column_or_section": "RealCID",
      "problem": "Tier 1 description adds 'Passthrough from Dim_Customer via GCID lookup.' beyond verbatim upstream text from Dim_Customer wiki. No semantic loss but technically non-verbatim."
    },
    {
      "severity": "low",
      "column_or_section": "TranDateTime, DateOccured",
      "problem": "Both columns append 'DWH note:' clauses after verbatim upstream text. Informative additions but deviate from pure Tier 1 verbatim standard."
    },
    {
      "severity": "low",
      "column_or_section": "TransactionTypeID",
      "problem": "Enum list omits type 4 (Funding), which is referenced by IsFunding flag (TransactionTypeID=4 for sent). This matches the upstream verbatim text which also omits it (type 4 falls into the 'other_transactions' catch-all CTE), but analysts may be confused by the inconsistency."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Correct footer tier counts from '22 T1, 23 T2' to '24 T1, 21 T2'. (2) Add a formal Phase Gate Checklist section or expand footer to list which phases were completed/skipped. (3) Optional: note TransactionTypeID=4 (Funding) in the enum values for consistency with IsFunding flag documentation.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present as formal section; footer says 12/14 without detail"]
  }
}
</JUDGE_VERDICT>
