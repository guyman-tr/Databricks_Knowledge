## Adversarial Review: EXW_dbo.EXW_FactConversions

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (ConversionID, FromAddress, SentToEtoroBlockchainFees, FromBlockchainCryptoId, ReceivedTime). All tier assignments are correct. Passthroughs from documented upstreams are Tier 1, CryptoTypes lookups are Tier 2, columns from undocumented sources (SentTransactions, ReceivedTransactions, customer mapping) are Tier 3. No misclassifications found.

**Dimension 2 — Upstream Fidelity: 9/10**
All 24 Tier 1 columns reproduce the upstream description verbatim as the leading text, then append leg-specific context (e.g. "From-leg actual executed amount after micro-fee deduction"). No vendor names dropped, no NULL semantics removed, no FK targets lost. The extensions are additive, not substitutive. One trivial formatting pattern: many ConversionTransactions-sourced columns repeat the same generic upstream text ("Amount of crypto for this conversion leg in native units") before differentiating — faithful but slightly mechanical.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 46 elements match 46 DDL columns exactly. Every element row has 5 cells with proper tier tags. Property table has all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (50,298) and date range (Oct 2018 – Jun 2023). ConversionStatus lists 3 values inline. Review-needed sidecar has no `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (crypto-to-crypto swap), row grain (single conversion), row count, date range, ETL pattern (external pipeline, single bulk load), refresh status (dormant), status distribution with row counts, and top conversion pairs. An analyst landing here immediately knows what this table is and that it's historical-only.

**Dimension 5 — Data Evidence: 9/10**
Row count (50,298), date range, status distribution with exact row counts (3=48738, 2=1555, 1=5), NULL rates (~313 FromAmount NULLs, ~1,510 ToAmount NULLs, 1,608 ReceivedTime NULLs), UpdateDate uniformity, and top conversion pairs all present. Footer claims Phases: 11/11.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend, real SQL samples, footer with quality score and phases. One defect: **footer tier counts are wrong** — claims "22 T1, 8 T2, 16 T3" but actual count from the Elements table is 24 T1, 6 T2, 16 T3. Two Tier 2 columns were miscounted as Tier 1 or vice versa in the summary.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| ConversionID | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | YES | — |
| CorrelationID | "Links to the parent request in Wallet.Requests.CorrelationId." | "Links to the parent request in Wallet.Requests.CorrelationId." | YES | — |
| RequestTime | "Timestamp when the conversion was initiated." | "Timestamp when the conversion was initiated." | YES | — |
| FromWalletId | "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId." | "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId." | YES | — |
| FromAddress | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | "Destination blockchain address for this conversion leg. NULL when the transfer is internal. Mapped to the From-leg..." | MINOR | Additive context only |
| RequestedFromAmount | "Amount of source crypto being sold. In native units of FromCryptoId." | "Amount of source crypto being sold. In native units of FromCryptoId. This is the user's original requested sell amount..." | MINOR | Additive context only |
| FromCryptoID | "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID." | "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID." | YES | — |
| FromAmount | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for this conversion leg in native units. From-leg actual executed amount after micro-fee deduction. NULL for failed conversions." | MINOR | Additive context only |
| ToEtoroEstimatedBCFee | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Pre-send estimate for the To-leg of the conversion." | MINOR | Additive context only |
| ToEtoroDate | "Timestamp of this transaction record creation." | "Timestamp of this transaction record creation. To-leg of the conversion." | MINOR | Additive context only |
| ConversionID2 | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | "Duplicate of ConversionID. Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Same value as ConversionID in all observed rows." | MINOR | Additive context only |
| ToWalletId | "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId." | "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId." | YES | — |
| ToAddress | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | YES | — |
| RequestedToAmount | "Amount of destination crypto being purchased. In native units of ToCryptoId." | "Amount of destination crypto being purchased. In native units of ToCryptoId. This is the user's original requested buy amount..." | MINOR | Additive context only |
| ToCryptoID | "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID." | "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID." | YES | — |
| ToAmount | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for this conversion leg in native units. To-leg actual executed amount. NULL for failed conversions." | MINOR | Additive context only |
| FromEtoroEstimatedBCFee | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Pre-send estimate for the From-leg of the conversion." | MINOR | Additive context only |
| FromEtoroDate | "Timestamp of this transaction record creation." | "Timestamp of this transaction record creation. From-leg of the conversion." | MINOR | Additive context only |
| SentToEtoroWalletAmount | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for this conversion leg in native units. To-leg amount sent to the destination wallet." | MINOR | Additive context only |
| SentToEtoroWalletEtoroFees | "Calculated eToro fee amount in the crypto's native units." | "Calculated eToro fee amount in the crypto's native units. Platform fee for the To-leg." | MINOR | Additive context only |
| SentToEtoroBlockchainFees | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Network cost for the To-leg sent transaction." | MINOR | Additive context only |
| SentFromEtoroWalletAmount | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for this conversion leg in native units. From-leg amount sent from the source wallet." | MINOR | Additive context only |
| SentFromEtoroWalletEtoroFees | "Calculated eToro fee amount in the crypto's native units." | "Calculated eToro fee amount in the crypto's native units. Platform fee for the From-leg." | MINOR | Additive context only |
| SentFromEtoroBlockchainFees | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Network cost for the From-leg sent transaction." | MINOR | Additive context only |

---

### Top 5 Issues

1. **Footer tier counts are wrong** (shape_fidelity) — Footer claims "22 T1, 8 T2, 16 T3" but actual count from Elements table is 24 T1, 6 T2, 16 T3.

2. **SentToEtoroBlockchainFees lineage ambiguity** (tier_accuracy, low severity) — Column name suggests actual blockchain fee on the sent transaction, but lineage maps it to `EstimatedBlockChainFee` from ConversionTransactions. The Tier 1 description faithfully quotes the upstream ("Estimated blockchain network fee for this leg") which may confuse analysts expecting this to be the actual sent-transaction fee. The lineage mapping itself may be incorrect — worth verifying with data.

3. **No Section 3.1 performance guidance for HEAP scan cost** (business_meaning, low severity) — Section 3.1 mentions HEAP but doesn't quantify the impact. With only 50K rows this is trivial, but noting for completeness.

4. **Missing CryptoRateUsd from ConversionTransactions** (completeness, low severity) — The upstream ConversionTransactions has `CryptoRateUsd` (USD exchange rate at execution time) which was not carried into EXW_FactConversions. This is correctly not in the DDL so not a wiki error, but the review-needed sidecar could mention this as a potential enrichment opportunity.

5. **ConversionID2 purpose unclear** (business_meaning, low severity) — Described as "Duplicate of ConversionID" with same value in all rows, but the review-needed sidecar correctly flags this as an open question. The wiki handles it well by documenting the observation.

---

### Regeneration Feedback

1. Fix footer tier counts: change "22 T1, 8 T2" to "24 T1, 6 T2" (recount from Elements table).
2. No other regeneration required — this is a strong wiki.

---

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_FactConversions",
  "weighted_score": 9.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "ConversionID",
      "upstream_quote": "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions.",
      "wiki_quote": "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CorrelationID",
      "upstream_quote": "Links to the parent request in Wallet.Requests.CorrelationId.",
      "wiki_quote": "Links to the parent request in Wallet.Requests.CorrelationId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RequestTime",
      "upstream_quote": "Timestamp when the conversion was initiated.",
      "wiki_quote": "Timestamp when the conversion was initiated.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FromWalletId",
      "upstream_quote": "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId.",
      "wiki_quote": "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FromAddress",
      "upstream_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal.",
      "wiki_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal. Mapped to the From-leg of the conversion (sourced from ConversionTransactions.ToAddress of the From-leg record).",
      "match": "MINOR",
      "loss": "Additive leg-context only, upstream text preserved verbatim"
    },
    {
      "column": "RequestedFromAmount",
      "upstream_quote": "Amount of source crypto being sold. In native units of FromCryptoId.",
      "wiki_quote": "Amount of source crypto being sold. In native units of FromCryptoId. This is the user's original requested sell amount at conversion initiation; differs from FromAmount which reflects the actual executed amount after micro-fee deduction.",
      "match": "MINOR",
      "loss": "Additive disambiguation context only"
    },
    {
      "column": "FromCryptoID",
      "upstream_quote": "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID.",
      "wiki_quote": "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FromAmount",
      "upstream_quote": "Amount of crypto for this conversion leg in native units.",
      "wiki_quote": "Amount of crypto for this conversion leg in native units. From-leg actual executed amount after micro-fee deduction. NULL for failed conversions.",
      "match": "MINOR",
      "loss": "Additive leg-context and NULL semantics"
    },
    {
      "column": "ToEtoroEstimatedBCFee",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Pre-send estimate for the To-leg of the conversion.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "ToEtoroDate",
      "upstream_quote": "Timestamp of this transaction record creation.",
      "wiki_quote": "Timestamp of this transaction record creation. To-leg of the conversion.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "ConversionID2",
      "upstream_quote": "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions.",
      "wiki_quote": "Duplicate of ConversionID. Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Same value as ConversionID in all observed rows.",
      "match": "MINOR",
      "loss": "Additive duplicate-flag context only"
    },
    {
      "column": "ToWalletId",
      "upstream_quote": "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId.",
      "wiki_quote": "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ToAddress",
      "upstream_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal.",
      "wiki_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RequestedToAmount",
      "upstream_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId.",
      "wiki_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId. This is the user's original requested buy amount at conversion initiation; differs from ToAmount which reflects the actual executed amount.",
      "match": "MINOR",
      "loss": "Additive disambiguation context only"
    },
    {
      "column": "ToCryptoID",
      "upstream_quote": "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID.",
      "wiki_quote": "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ToAmount",
      "upstream_quote": "Amount of crypto for this conversion leg in native units.",
      "wiki_quote": "Amount of crypto for this conversion leg in native units. To-leg actual executed amount. NULL for failed conversions.",
      "match": "MINOR",
      "loss": "Additive leg-context and NULL semantics"
    },
    {
      "column": "FromEtoroEstimatedBCFee",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Pre-send estimate for the From-leg of the conversion.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "FromEtoroDate",
      "upstream_quote": "Timestamp of this transaction record creation.",
      "wiki_quote": "Timestamp of this transaction record creation. From-leg of the conversion.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "SentToEtoroWalletAmount",
      "upstream_quote": "Amount of crypto for this conversion leg in native units.",
      "wiki_quote": "Amount of crypto for this conversion leg in native units. To-leg amount sent to the destination wallet.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "SentToEtoroWalletEtoroFees",
      "upstream_quote": "Calculated eToro fee amount in the crypto's native units.",
      "wiki_quote": "Calculated eToro fee amount in the crypto's native units. Platform fee for the To-leg.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "SentToEtoroBlockchainFees",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Network cost for the To-leg sent transaction.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "SentFromEtoroWalletAmount",
      "upstream_quote": "Amount of crypto for this conversion leg in native units.",
      "wiki_quote": "Amount of crypto for this conversion leg in native units. From-leg amount sent from the source wallet.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "SentFromEtoroWalletEtoroFees",
      "upstream_quote": "Calculated eToro fee amount in the crypto's native units.",
      "wiki_quote": "Calculated eToro fee amount in the crypto's native units. Platform fee for the From-leg.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    },
    {
      "column": "SentFromEtoroBlockchainFees",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Network cost for the From-leg sent transaction.",
      "match": "MINOR",
      "loss": "Additive leg-context only"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer tier counts are wrong: claims '22 T1, 8 T2, 16 T3' but actual count from Elements table is 24 T1, 6 T2, 16 T3."
    },
    {
      "severity": "low",
      "column_or_section": "SentToEtoroBlockchainFees / SentFromEtoroBlockchainFees",
      "problem": "Column names suggest actual blockchain fees on sent transactions, but lineage maps to EstimatedBlockChainFee from ConversionTransactions. The Tier 1 description faithfully quotes 'Estimated blockchain network fee' which may confuse analysts expecting actual fees. Lineage mapping may warrant data verification."
    },
    {
      "severity": "low",
      "column_or_section": "ConversionID2",
      "problem": "Described as duplicate of ConversionID with same value in all rows. Purpose is unclear — review-needed sidecar correctly flags this but wiki could note whether this is a known ETL artifact or has functional meaning in edge cases."
    }
  ],
  "regeneration_feedback": "Fix footer tier counts: change '22 T1, 8 T2' to '24 T1, 6 T2'. No other regeneration required — this is a strong wiki with verbatim upstream inheritance, comprehensive business logic sections, and solid data evidence.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
