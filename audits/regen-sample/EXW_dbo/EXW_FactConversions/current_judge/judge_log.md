I'll start by reviewing the wiki against the upstream bundle and DDL systematically.

## Per-Dimension Analysis

### Dimension 1 — Tier Accuracy (25%)

**5-column random sample**: ConversionID (#1), FromAddress (#5), ToEtoroEstimatedBCFee (#13), FromCrypto (#9), ToAmount (#22).

| Column | Lineage Source | Upstream Wiki? | Expected Tier | Wiki Claims | Correct? |
|--------|---------------|----------------|---------------|-------------|----------|
| ConversionID | Wallet.Conversions.Id | YES | Tier 1 | Tier 1 | YES |
| FromAddress | Wallet.ConversionTransactions.ToAddress | YES | Tier 1 | Tier 1 | YES |
| ToEtoroEstimatedBCFee | Wallet.ConversionTransactions.EstimatedBlockChainFee | YES | Tier 1 | **Tier 2** | **NO** |
| FromCrypto | EXW_Wallet.CryptoTypes.Name | NO (unresolved) | Tier 2 | Tier 2 | YES |
| ToAmount | Wallet.ConversionTransactions.Amount | YES | Tier 1 | Tier 1 | YES |

1 mismatch out of 5. The mismatch is damning because the writer correctly tagged the symmetric column `FromEtoroEstimatedBCFee` as Tier 1 but misclassified `ToEtoroEstimatedBCFee` as Tier 2 — both source from `ConversionTransactions.EstimatedBlockChainFee`. Same issue affects `ToEtoroDate` and `FromEtoroDate` (both from `ConversionTransactions.Occurred`, both marked Tier 2, should be Tier 1).

No paraphrasing failures on actual Tier 1 columns.

**Score: 7**

---

### Dimension 2 — Upstream Fidelity (20%)

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| ConversionID | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Passthrough from WalletDB." | MINOR | Added attribution, no loss |
| CorrelationID | "Links to the parent request in Wallet.Requests.CorrelationId." | "Links to the parent request in Wallet.Requests.CorrelationId. Used by the orchestration saga to deduplicate retries." | MINOR | Added extra sentence, no loss |
| RequestTime | "Timestamp when the conversion was initiated." (from Occurred) | "Timestamp when the conversion was initiated. Passthrough from Wallet.Conversions.Occurred." | MINOR | Added source reference, no loss |
| FromWalletId | "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId." | "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId." | YES | — |
| FromAddress | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | "Destination blockchain address for this conversion leg. NULL when the transfer is internal. FROM-leg outgoing address." | MINOR | Added leg clarification, no loss |
| RequestedFromAmount | "Amount of source crypto being sold. In native units of FromCryptoId." (from Conversions.FromAmount) | "Amount of source crypto being sold. In native units of FromCryptoId. This is the original requested amount before execution." | MINOR | Added clarification, no loss |
| FromCryptoID | "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID." | "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID." | YES | — |
| FromAmount | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for this conversion leg in native units. FROM-leg actual executed amount (may differ from RequestedFromAmount due to slippage/fees)." | MINOR | Added context, no loss |
| ToWalletId | "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId." | "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId." | YES | — |
| ToAddress | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | "Destination blockchain address for this conversion leg. NULL when the transfer is internal. TO-leg receiving address." | MINOR | Added leg clarification, no loss |
| RequestedToAmount | "Amount of destination crypto being purchased. In native units of ToCryptoId." (from Conversions.ToAmount) | "Amount of destination crypto being purchased. In native units of ToCryptoId. This is the original requested amount before execution." | MINOR | Added clarification, no loss |
| ToCryptoID | "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID." | "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID." | YES | — |
| ToAmount | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for this conversion leg in native units. TO-leg actual executed amount received in the destination wallet." | MINOR | Added context, no loss |
| FromEtoroEstimatedBCFee | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. FROM-leg estimated blockchain fee in native crypto units. NULL when blockchain fee was not available at load time." | MINOR | Added NULL semantics (beneficial), no loss |

**Fidelity of claimed Tier 1 columns**: All preserve upstream text verbatim with additions — no semantic loss. Base score: 9 (minor formatting additions throughout).

**Missed inheritances** (columns that should be Tier 1 but are tagged Tier 2, with ConversionTransactions wiki available in bundle):
1. `ToEtoroEstimatedBCFee` — passthrough from `ConversionTransactions.EstimatedBlockChainFee` (TO leg). Symmetric column `FromEtoroEstimatedBCFee` correctly tagged Tier 1.
2. `ToEtoroDate` — passthrough rename from `ConversionTransactions.Occurred` (TO leg).
3. `FromEtoroDate` — passthrough rename from `ConversionTransactions.Occurred` (FROM leg).

3 missed inheritances × -2 = -6. Score: 9 - 6 = **3**.

---

### Dimension 3 — Completeness (20%)

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL count (46/46) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES |
| Dictionary columns ≤15 values listed inline | YES (ConversionStatus: 1/2/3 in element #10) |
| .review-needed does NOT contain `## 4. Elements` | YES |

10/10 = **Score: 10**

---

### Dimension 4 — Business Meaning (15%)

Section 1 is outstanding. It names: row grain (single crypto-to-crypto swap), domain (eToro Wallet), row count (50,298), date range (Oct 2018 – June 2023), source systems (WalletDB.Wallet.Conversions + ConversionTransactions), refresh pattern (historical one-time load), GCID count (19,722), crypto distributions (ETH 34%, BTC 15%), status distribution (97% completed), and downstream consumer (SP_US_Daily_Crypto). A new analyst knows exactly when and why to query this table.

**Score: 10**

---

### Dimension 5 — Data Evidence (10%)

- Row count in Section 1: 50,298 ✓
- Date range: Oct 2018 – June 2023 ✓
- Enum values with counts: ConversionStatus 1/2/3 with exact row counts ✓
- NULL-rate claims: ToEtoroEstimatedBCFee 100% NULL, ToEtoroSentTXID 1% NULL ✓
- Phase Gate P2 + P3: both marked PASS in review-needed ✓

**Score: 9**

---

### Dimension 6 — Shape Fidelity (10%)

Numbered sections 1–8 present. Tier legend in Section 4. Real SQL with correct table references in Section 7. Footer has quality score (8.4/10), phase count (14/14), tier breakdown. Minor: Section 3 heading is "Query Advisory" rather than a more standard name, but content is well-structured.

**Score: 9**

---

### Weighted Total

```
weighted = 0.25×7 + 0.20×3 + 0.20×10 + 0.15×10 + 0.10×9 + 0.10×9
         = 1.75 + 0.60 + 2.00 + 1.50 + 0.90 + 0.90
         = 7.65
```

**Verdict: PASS** (7.65 ≥ 7.5)

---

## Top 5 Issues

1. **HIGH — ToEtoroEstimatedBCFee (#13)**: Tagged Tier 2 but is a passthrough from `ConversionTransactions.EstimatedBlockChainFee` (TO leg). Symmetric column `FromEtoroEstimatedBCFee` (#23) is correctly tagged Tier 1 from the same upstream source. Inconsistent.

2. **HIGH — ToEtoroDate (#14)**: Tagged Tier 2 but is a passthrough rename from `ConversionTransactions.Occurred` (TO leg). Upstream wiki exists in bundle. Should be Tier 1.

3. **HIGH — FromEtoroDate (#24)**: Tagged Tier 2 but is a passthrough rename from `ConversionTransactions.Occurred` (FROM leg). Same upstream source as ToEtoroDate. Should be Tier 1.

4. **MEDIUM — Missing ConversionTypeId coverage**: The upstream `Wallet.Conversions` wiki documents `ConversionTypeId` (1=FixedFrom, 2=FixedTo) which is a meaningful business column. This column is absent from the DWH table DDL (not loaded), but the wiki doesn't mention its absence or the business implication (all conversions lose the pricing-direction metadata). Section 2 could note this.

5. **LOW — CorrelationID description adds unverified claim**: The wiki adds "Used by the orchestration saga to deduplicate retries" which does not appear in the upstream wiki. The upstream only says "Links to the parent request in Wallet.Requests.CorrelationId." While likely accurate, this addition is unsourced.

---

## Regeneration Feedback

1. Re-tag `ToEtoroEstimatedBCFee` (#13) as `(Tier 1 — WalletDB.Wallet.ConversionTransactions)` using verbatim upstream text: "Estimated blockchain network fee for this leg." Then add the TO-leg qualification and NULL observation.
2. Re-tag `ToEtoroDate` (#14) as `(Tier 1 — WalletDB.Wallet.ConversionTransactions)` with upstream text for `Occurred`: "Timestamp of this transaction record creation."
3. Re-tag `FromEtoroDate` (#24) as `(Tier 1 — WalletDB.Wallet.ConversionTransactions)` with the same upstream text.
4. Update the footer tier breakdown from "14 T1, 31 T2" to "17 T1, 28 T2" to reflect the corrections.
5. Remove the unverified "orchestration saga" claim from CorrelationID or explicitly mark it as Tier 2 supplementary context.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_FactConversions",
  "weighted_score": 7.65,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "ConversionID",
      "upstream_quote": "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions.",
      "wiki_quote": "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Passthrough from WalletDB.",
      "match": "MINOR",
      "loss": "Added attribution suffix; no semantic loss"
    },
    {
      "column": "CorrelationID",
      "upstream_quote": "Links to the parent request in Wallet.Requests.CorrelationId.",
      "wiki_quote": "Links to the parent request in Wallet.Requests.CorrelationId. Used by the orchestration saga to deduplicate retries.",
      "match": "MINOR",
      "loss": "Added unverified orchestration saga claim; upstream text preserved"
    },
    {
      "column": "RequestTime",
      "upstream_quote": "Timestamp when the conversion was initiated.",
      "wiki_quote": "Timestamp when the conversion was initiated. Passthrough from Wallet.Conversions.Occurred.",
      "match": "MINOR",
      "loss": "Added source reference; no semantic loss"
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
      "wiki_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal. FROM-leg outgoing address.",
      "match": "MINOR",
      "loss": "Added leg clarification; no semantic loss"
    },
    {
      "column": "RequestedFromAmount",
      "upstream_quote": "Amount of source crypto being sold. In native units of FromCryptoId.",
      "wiki_quote": "Amount of source crypto being sold. In native units of FromCryptoId. This is the original requested amount before execution.",
      "match": "MINOR",
      "loss": "Added execution context; no semantic loss"
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
      "wiki_quote": "Amount of crypto for this conversion leg in native units. FROM-leg actual executed amount (may differ from RequestedFromAmount due to slippage/fees).",
      "match": "MINOR",
      "loss": "Added FROM-leg context; no semantic loss"
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
      "wiki_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal. TO-leg receiving address.",
      "match": "MINOR",
      "loss": "Added leg clarification; no semantic loss"
    },
    {
      "column": "RequestedToAmount",
      "upstream_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId.",
      "wiki_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId. This is the original requested amount before execution.",
      "match": "MINOR",
      "loss": "Added execution context; no semantic loss"
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
      "wiki_quote": "Amount of crypto for this conversion leg in native units. TO-leg actual executed amount received in the destination wallet.",
      "match": "MINOR",
      "loss": "Added TO-leg context; no semantic loss"
    },
    {
      "column": "FromEtoroEstimatedBCFee",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. FROM-leg estimated blockchain fee in native crypto units. NULL when blockchain fee was not available at load time.",
      "match": "MINOR",
      "loss": "Added FROM-leg context and NULL semantics; no semantic loss from upstream"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "ToEtoroEstimatedBCFee (#13)",
      "problem": "Tagged Tier 2 (WalletDB.Wallet.ConversionTransactions) but is a passthrough from ConversionTransactions.EstimatedBlockChainFee with upstream wiki available in bundle. Symmetric column FromEtoroEstimatedBCFee (#23) is correctly tagged Tier 1. Inconsistent tier assignment."
    },
    {
      "severity": "high",
      "column_or_section": "ToEtoroDate (#14)",
      "problem": "Tagged Tier 2 but is a passthrough rename from ConversionTransactions.Occurred (TO leg). Upstream wiki documents Occurred as 'Timestamp of this transaction record creation.' Should be Tier 1."
    },
    {
      "severity": "high",
      "column_or_section": "FromEtoroDate (#24)",
      "problem": "Tagged Tier 2 but is a passthrough rename from ConversionTransactions.Occurred (FROM leg). Same upstream source as ToEtoroDate. Should be Tier 1."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 2 / ConversionTypeId",
      "problem": "Upstream Wallet.Conversions documents ConversionTypeId (1=FixedFrom, 2=FixedTo) as a key business column. This column was not loaded into the DWH table, but the wiki does not mention its absence or the loss of pricing-direction metadata."
    },
    {
      "severity": "low",
      "column_or_section": "CorrelationID (#2)",
      "problem": "Wiki adds 'Used by the orchestration saga to deduplicate retries' which does not appear in the upstream Wallet.Conversions wiki. Unsourced claim appended to an otherwise faithful Tier 1 description."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag ToEtoroEstimatedBCFee (#13) as Tier 1 — WalletDB.Wallet.ConversionTransactions, using verbatim upstream text 'Estimated blockchain network fee for this leg.' then append TO-leg qualifier and NULL observation. (2) Re-tag ToEtoroDate (#14) as Tier 1 — WalletDB.Wallet.ConversionTransactions, using upstream text 'Timestamp of this transaction record creation.' (3) Re-tag FromEtoroDate (#24) as Tier 1 — WalletDB.Wallet.ConversionTransactions, same upstream text. (4) Update footer tier counts from '14 T1, 31 T2' to '17 T1, 28 T2'. (5) Remove or explicitly attribute the 'orchestration saga' claim in CorrelationID.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
