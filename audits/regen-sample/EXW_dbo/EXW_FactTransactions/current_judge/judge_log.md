I'll review this wiki systematically against the rubric. Let me first verify the upstream wiki to do a precise Tier 1 fidelity comparison.

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy: 10/10

Sampled 5 columns:
1. **GCID** (#1): Passthrough from Wallet.TransactionsView (renamed gcid→GCID). Wiki says Tier 1. ✅
2. **CryptoName** (#4): JOIN to EXW_Wallet.CryptoTypes.Name on CryptoId. No upstream wiki for CryptoTypes in bundle. Wiki says Tier 2. ✅
3. **EtoroFees** (#13): Computed as source.EtoroFees × FeeExchangeRate. Wiki says Tier 2. ✅
4. **ActionTypeName** (#19): Passthrough from Wallet.TransactionsView. Wiki says Tier 1. ✅
5. **ReceivedTransactionTypeID** (#44): JOIN to EXW_Wallet.ReceivedTransactions. Wiki says Tier 2. ✅

0 mismatches, 0 paraphrasing failures on Tier 1 columns in sample. Score: **10**.

### Dimension 2 — Upstream Fidelity: 9/10

All 21 Tier 1 columns carry the upstream Wallet.TransactionsView description verbatim, with DWH notes appended after. Three columns have trivial quote-character differences (escaped `\"` in upstream → `'` in wiki: Amount, ReciverAddress, LastStatusUpdateOccurred). No semantic loss anywhere — vendor names, NULL semantics, FK targets, and specific values all preserved.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| GCID | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. | YES | — |
| CryptoId | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. | YES | — |
| WalletID | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. | YES | — |
| TranID | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. | YES | — |
| TranStatusID | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. | YES | — |
| TranStatus | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. | YES | — |
| TranDate | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. | YES | — |
| Amount | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for 'other' types. | MINOR | Double quotes → single quotes around "other" |
| ProviderFees | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. | YES | — |
| FeeExchangeRate | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. | YES | — |
| BlockchainFees | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. | YES | — |
| EstimatedBlockchainFee | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. | YES | — |
| ActionTypeID | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. | YES | — |
| ActionTypeName | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). | YES | — |
| SenderAddress | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). | YES | — |
| ReciverAddress | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. | Receiver's blockchain address (legacy misspelling 'Reciver'). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. | MINOR | Double quotes → single quotes around "Reciver" |
| BlockchainTransactionId | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. | YES | — |
| TransactionTypeID | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. | YES | — |
| TransactionType | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. | YES | — |
| Occurred | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. | YES | — |
| LastStatusUpdateOccurred | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables 'time since last update' monitoring and SLA tracking. New in this version (not in TransactionViewOld). | MINOR | Double quotes → single quotes around "time since last update" |

Score: **9** (all verbatim; 3 trivial quote-formatting diffs, zero semantic loss).

### Dimension 3 — Completeness: 10/10

- [x] All 8 sections present (1–8)
- [x] Element count matches DDL: 45 = 45
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real SP/table names
- [x] Footer has tier breakdown counts (21 T1, 24 T2)
- [x] Section 1 has row count (4,709,301) and date range (2018-04-23 to 2026-04-19)
- [x] Dictionary columns list inline values (TranStatusID: 7 values, TransactionTypeID: 13 values, AMLProviderStatus: 5 values, ReceivedTransactionTypeID: 4 values)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10. Score: **10**.

### Dimension 4 — Business Meaning: 10/10

Section 1 is excellent: names domain (crypto wallet transactions), row grain (one row per transaction × action type, TranID+ActionTypeID), ETL SP (SP_EXW_Fact_Transactions), refresh pattern (daily incremental DELETE+INSERT), row count (4,709,301), date range, direction split (Received 53% / Sent 47%), status distribution, flag percentages. An analyst could immediately understand when and how to query this table.

### Dimension 5 — Data Evidence: 9/10

- Row count and date range in Section 1: ✅
- Specific enum values with counts: ✅ (TransactionTypeID 13 types, TranStatus 7 values with percentages, AMLProviderStatus 5 values, ReceivedTransactionTypeID 4 values with counts)
- NULL-rate claims: ✅ (AML ~69% NULL, ReceivedTransactionTypeID ~76% of received rows NULL)
- Phase Gate P2+P3: ✅ (both marked PASS in review-needed)

Deducting 1 point for: UC Target discrepancy — wiki property table claims `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` but lineage file says `_Not_Migrated`. One of these is fabricated or stale.

### Dimension 6 — Shape Fidelity: 9/10

- Numbered sections 1–8: ✅
- Tier legend in Section 4: ✅
- Real SQL samples in Section 7: ✅ (3 practical queries)
- Footer with quality score + phases-completed: ✅
- Property table complete: ✅

Minor: footer self-assessment claims "Quality: 9.4/10 (P16 adversarial: 9.45)" which pre-empts the judge. Not a structural failure but slightly presumptuous.

### Weighted Total

```
weighted = 0.25×10 + 0.20×9 + 0.20×10 + 0.15×10 + 0.10×9 + 0.10×9
         = 2.50 + 1.80 + 2.00 + 1.50 + 0.90 + 0.90
         = 9.60
```

**Verdict: PASS**

### Top 5 Issues

1. **UC Target contradiction** (medium): Wiki property table says `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` but lineage file says `_Not_Migrated`. The writer appears to have constructed the UC target name from a naming convention rather than verified it.
2. **Quote formatting in 3 Tier 1 descriptions** (low): Amount, ReciverAddress, and LastStatusUpdateOccurred use single quotes where upstream uses escaped double quotes. Purely cosmetic — no semantic loss.
3. **Footer self-score is inflated** (low): Writer claims 9.4/10 and "P16 adversarial: 9.45" — this pre-judges the review and isn't meaningful until independently scored.
4. **Section 8 is thin** (low): "No Atlassian sources found" is stated but the review-needed confirms P10 was skipped (no Atlassian MCP configured). This is acknowledged but leaves a gap.
5. **IsEtoroFee description could be clearer** (low): Wiki says "Reserved column — always NULL. The classification logic for this flag was commented out" but doesn't mention what the intended logic was. The review-needed sidecar captures this as an open question, which is the right place for it.

### Regeneration Feedback

No regeneration needed (PASS), but for polish:
1. Reconcile UC Target: verify whether the UC target exists or update to `_Not_Migrated` per the lineage file.
2. Match upstream quote characters exactly (double quotes, not single) in Amount, ReciverAddress, LastStatusUpdateOccurred descriptions.
3. Remove or tone down the self-assessed quality score in the footer — let the judge assign the score.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_FactTransactions",
  "weighted_score": 9.60,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 9,
    "shape_fidelity": 9
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
      "wiki_quote": "Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for 'other' types.",
      "match": "MINOR",
      "loss": "Double quotes around 'other' changed to single quotes — no semantic loss"
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
      "wiki_quote": "Receiver's blockchain address (legacy misspelling 'Reciver'). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress.",
      "match": "MINOR",
      "loss": "Double quotes around 'Reciver' changed to single quotes — no semantic loss"
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
      "column": "LastStatusUpdateOccurred",
      "upstream_quote": "Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables \"time since last update\" monitoring and SLA tracking. New in this version (not in TransactionViewOld).",
      "wiki_quote": "Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables 'time since last update' monitoring and SLA tracking. New in this version (not in TransactionViewOld).",
      "match": "MINOR",
      "loss": "Double quotes around 'time since last update' changed to single quotes — no semantic loss"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Property table — UC Target",
      "problem": "Wiki claims UC Target is `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` but lineage file says `_Not_Migrated`. The writer appears to have constructed the UC name from a naming convention rather than verified it."
    },
    {
      "severity": "low",
      "column_or_section": "Amount (#12)",
      "problem": "Upstream uses escaped double quotes around 'other'; wiki uses single quotes. Trivial formatting difference, no semantic loss."
    },
    {
      "severity": "low",
      "column_or_section": "ReciverAddress (#26)",
      "problem": "Upstream uses escaped double quotes around 'Reciver'; wiki uses single quotes. Trivial formatting difference, no semantic loss."
    },
    {
      "severity": "low",
      "column_or_section": "LastStatusUpdateOccurred (#43)",
      "problem": "Upstream uses escaped double quotes around 'time since last update'; wiki uses single quotes. Trivial formatting difference, no semantic loss."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer self-assigns Quality: 9.4/10 and a P16 adversarial score of 9.45. This pre-judges the independent review and is not meaningful until externally scored."
    }
  ],
  "regeneration_feedback": "No regeneration needed (PASS). For polish: (1) Reconcile UC Target — verify whether `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` actually exists or update to `_Not_Migrated` per lineage. (2) Match upstream quote characters exactly (escaped double quotes, not single quotes) in Amount, ReciverAddress, and LastStatusUpdateOccurred descriptions. (3) Remove self-assessed quality/adversarial scores from footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P10 — Atlassian (no MCP configured)"]
  }
}
</JUDGE_VERDICT>
