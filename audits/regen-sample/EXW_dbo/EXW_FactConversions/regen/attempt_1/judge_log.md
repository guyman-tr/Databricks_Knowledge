## Adversarial Review: EXW_dbo.EXW_FactConversions

### Dimension 1 — Tier Accuracy: **7/10**

Five random columns sampled:

| Column | Wiki Tier | Correct Tier | Match? |
|--------|-----------|-------------|--------|
| ConversionID | Tier 1 (Wallet.Conversions) | Tier 1 | YES |
| FromAddress | Tier 2 (external pipeline) | Debatable — sourced from ConversionTransactions.ToAddress (wiki exists) but involves leg-selection + semantic rename | BORDERLINE |
| SendingGCID | Tier 3 | Tier 3 | YES |
| SentToEtoroWalletEtoroFees | Tier 1 (ConversionTransactions) | Tier 1 | YES |
| ToEtoroDate | Tier 1 (ConversionTransactions) | Tier 1 | YES |

One borderline mismatch: **FromAddress** is sourced from `Wallet.ConversionTransactions.ToAddress` (which has a wiki), yet tagged Tier 2. The lineage file itself says the source is `ConversionTransactions.ToAddress` — an upstream with a wiki present in the bundle. While the leg-selection and column rename add context, the value itself is a direct passthrough. Tier 1 with a note about the From-leg rename would be more accurate.

No paraphrasing failures detected in the sampled Tier 1 columns beyond the fidelity issues covered in Dimension 2.

---

### Dimension 2 — Upstream Fidelity: **3/10**

Four Tier 1 columns show clear rewording of upstream text. All follow the same anti-pattern: replacing "this" with "the To-leg" or "the From-leg" to disambiguate, plus appending extra sentences.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| ConversionID | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | YES | — |
| CorrelationID | "Links to the parent request in Wallet.Requests.CorrelationId." | "Links to the parent request in Wallet.Requests.CorrelationId." | YES | — |
| RequestTime | "Timestamp when the conversion was initiated." | "Timestamp when the conversion was initiated." | YES | — |
| FromWalletId | "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId." | "The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId." | YES | — |
| RequestedFromAmount | "Amount of source crypto being sold. In native units of FromCryptoId." | "Amount of source crypto being sold. In native units of FromCryptoId." | YES | — |
| FromCryptoID | "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID." | "Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID." | YES | — |
| FromAmount | "Amount of source crypto being sold. In native units of FromCryptoId." | "Amount of source crypto being sold. In native units of FromCryptoId. Actual amount after micro-fee deduction (slightly less than RequestedFromAmount). NULL for failed conversions." | MINOR | Upstream preserved; added Synapse-specific context |
| ConversionID2 | "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions." | "Duplicate of ConversionID. Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Same value as ConversionID in all observed rows." | MINOR | Upstream preserved; added duplicate note |
| ToWalletId | "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId." | "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId." | YES | — |
| RequestedToAmount | "Amount of destination crypto being purchased. In native units of ToCryptoId." | "Amount of destination crypto being purchased. In native units of ToCryptoId." | YES | — |
| ToCryptoID | "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID." | "Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID." | YES | — |
| ToAmount | "Amount of destination crypto being purchased. In native units of ToCryptoId." | "Amount of destination crypto being purchased. In native units of ToCryptoId. NULL for failed conversions." | MINOR | Upstream preserved; added NULL note |
| ToEtoroEstimatedBCFee | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Pre-send estimate for the To-leg of the conversion." | MINOR | Upstream preserved; appended context |
| **ToEtoroDate** | "Timestamp of this transaction record creation." | "Timestamp of the To-leg transaction record creation." | **NO** | Changed "this" → "the To-leg" — rewording |
| ToAddress | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | "Destination blockchain address for this conversion leg. NULL when the transfer is internal." | YES | — |
| **SentToEtoroWalletAmount** | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for the To-leg conversion in native units. The actual amount sent to the destination wallet." | **NO** | "this conversion leg" → "the To-leg conversion" + added sentence |
| SentToEtoroWalletEtoroFees | "Calculated eToro fee amount in the crypto's native units." | "Calculated eToro fee amount in the crypto's native units. Platform fee for the To-leg." | MINOR | Upstream preserved; appended leg context |
| SentToEtoroBlockchainFees | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Network cost for the To-leg sent transaction." | MINOR | Upstream preserved; appended context |
| **SentFromEtoroWalletAmount** | "Amount of crypto for this conversion leg in native units." | "Amount of crypto for the From-leg conversion in native units. The actual amount sent from the source wallet." | **NO** | Same rewording as SentToEtoroWalletAmount |
| SentFromEtoroWalletEtoroFees | "Calculated eToro fee amount in the crypto's native units." | "Calculated eToro fee amount in the crypto's native units. Platform fee for the From-leg." | MINOR | Upstream preserved; appended context |
| SentFromEtoroBlockchainFees | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Network cost for the From-leg sent transaction." | MINOR | Upstream preserved; appended context |
| FromEtoroEstimatedBCFee | "Estimated blockchain network fee for this leg." | "Estimated blockchain network fee for this leg. Pre-send estimate for the From-leg of the conversion." | MINOR | Upstream preserved; appended context |
| **FromEtoroDate** | "Timestamp of this transaction record creation." | "Timestamp of the From-leg transaction record creation." | **NO** | Same rewording as ToEtoroDate |

**Summary**: 10 YES, 8 MINOR, 4 NO. The 4 NO columns all follow the same pattern — replacing upstream "this" with a leg qualifier. Per the rubric, rewording IS the failure mode → score 3.

---

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | ✓ |
| Element count matches DDL (46/46) | ✓ |
| Every element row has 5 cells | ✓ |
| Every description ends with (Tier N — source) | ✓ |
| Property table has Production Source, Refresh, Distribution, UC Target | ✓ |
| Section 5.2 has ETL pipeline ASCII diagram | ✓ |
| Footer has tier breakdown counts | ✓ |
| Section 1 has row count and date range | ✓ |
| Dictionary columns (≤15 values) list key=value pairs (ConversionStatus: 3 values listed in element #10) | ✓ |
| .review-needed.md does NOT contain `## 4. Elements` | ✓ |

10/10 = **10**.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent: names the domain (crypto-to-crypto conversion/swap), specifies the row grain (single conversion operation), cites row count (50,298), date range (Oct 2018 – Jun 2023), production sources (Wallet.Conversions + ConversionTransactions), ETL pattern (external pipeline, single bulk load), and dormancy status. ConversionStatus distribution and top conversion pairs are included. A new analyst would immediately understand when and why to query this table.

---

### Dimension 5 — Data Evidence: **7/10**

Row count (50,298), date range (Oct 2018 – Jun 2023), ConversionStatus distribution (3 values with counts), NULL rates (~313 FromAmount NULLs, ~1,510 ToAmount NULLs, 1,608 ReceivedTime NULLs), and UpdateDate uniformity (all 2024-04-09) are all present. The footer claims "Phases: 11/11" but there is no explicit Phase Gate Checklist section with `[x]` checkboxes visible in the wiki body. Data claims appear genuine and specific.

---

### Dimension 6 — Shape Fidelity: **8/10**

All 8 numbered sections present, tier legend in Section 4, real SQL in Section 7, footer has quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section, and the quality score in the footer (`Quality: 8.0/10`) uses a slightly non-standard breakdown format.

---

### Weighted Total

```
weighted = 0.25×7 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 1.75 + 0.60 + 2.00 + 1.35 + 0.70 + 0.80
         = 7.20
```

**Verdict: FAIL** (7.20 < 7.5)

---

### Top 5 Issues

1. **HIGH — ToEtoroDate, FromEtoroDate**: Upstream says "Timestamp of this transaction record creation." Wiki rewrites as "Timestamp of the To/From-leg transaction record creation." Verbatim quoting rule violated.

2. **HIGH — SentToEtoroWalletAmount, SentFromEtoroWalletAmount**: Upstream says "Amount of crypto for this conversion leg in native units." Wiki rewrites as "Amount of crypto for the To/From-leg conversion in native units" and appends an extra sentence. Same verbatim violation.

3. **MEDIUM — FromAddress (Element #5)**: Tagged Tier 2 (external pipeline) but the lineage file itself traces it to `Wallet.ConversionTransactions.ToAddress`, which has an upstream wiki in the bundle. Should be Tier 1 with a note about From-leg selection, or at minimum Tier 2 citing ConversionTransactions rather than "external pipeline."

4. **LOW — Missing ConversionTypeId context**: The upstream `Wallet.Conversions` wiki documents `ConversionTypeId` (FixedFrom vs FixedTo) which determines whether FromAmount or ToAmount was user-specified. This business logic is entirely absent from the EXW wiki, despite being critical for interpreting amount columns. Not reflected in any column because ConversionTypeId doesn't exist in the EXW table — but Section 2 should note this omission.

5. **LOW — RequestedFromAmount/FromAmount ambiguity**: Both are mapped to `Wallet.Conversions.FromAmount` in the lineage (rows 7 and 12). If both come from the same upstream column, they should have the same value — yet the wiki claims RequestedFromAmount is the "original request" and FromAmount is "actual after micro-fee deduction." This contradicts the lineage mapping and needs clarification.

---

### Regeneration Feedback

1. Fix the 4 paraphrased Tier 1 columns: `ToEtoroDate`, `FromEtoroDate`, `SentToEtoroWalletAmount`, `SentFromEtoroWalletAmount`. Quote the upstream text verbatim ("this conversion leg" / "this transaction record creation") and append leg-specific context AFTER the verbatim quote, separated by a period.
2. Re-evaluate `FromAddress` tier: if sourced from `ConversionTransactions.ToAddress` (which has a wiki), tag as Tier 1 with the upstream description verbatim, followed by a note about From-leg selection. If the leg-selection transform justifies Tier 2, cite `ConversionTransactions.ToAddress` as the source, not "external pipeline."
3. Clarify the `RequestedFromAmount` vs `FromAmount` lineage: if both map to `Wallet.Conversions.FromAmount`, explain which pipeline step produces the difference. If they come from different upstream columns, correct the lineage.
4. Add a note in Section 2 about the missing `ConversionTypeId` column — the upstream Conversions table has it (FixedFrom=1, FixedTo=2) but it was dropped during the ETL load.

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_FactConversions",
  "weighted_score": 7.2,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
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
      "column": "RequestedFromAmount",
      "upstream_quote": "Amount of source crypto being sold. In native units of FromCryptoId.",
      "wiki_quote": "Amount of source crypto being sold. In native units of FromCryptoId.",
      "match": "YES",
      "loss": null
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
      "upstream_quote": "Amount of source crypto being sold. In native units of FromCryptoId.",
      "wiki_quote": "Amount of source crypto being sold. In native units of FromCryptoId. Actual amount after micro-fee deduction (slightly less than RequestedFromAmount). NULL for failed conversions.",
      "match": "MINOR",
      "loss": "Upstream text preserved verbatim; Synapse-specific context appended"
    },
    {
      "column": "ConversionID2",
      "upstream_quote": "Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions.",
      "wiki_quote": "Duplicate of ConversionID. Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. Same value as ConversionID in all observed rows.",
      "match": "MINOR",
      "loss": "Upstream text preserved; prepended duplicate note and appended observation"
    },
    {
      "column": "ToWalletId",
      "upstream_quote": "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId.",
      "wiki_quote": "The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RequestedToAmount",
      "upstream_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId.",
      "wiki_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId.",
      "match": "YES",
      "loss": null
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
      "upstream_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId.",
      "wiki_quote": "Amount of destination crypto being purchased. In native units of ToCryptoId. NULL for failed conversions.",
      "match": "MINOR",
      "loss": "Upstream preserved; NULL note appended"
    },
    {
      "column": "ToEtoroEstimatedBCFee",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Pre-send estimate for the To-leg of the conversion.",
      "match": "MINOR",
      "loss": "Upstream preserved; leg-specific context appended"
    },
    {
      "column": "ToEtoroDate",
      "upstream_quote": "Timestamp of this transaction record creation.",
      "wiki_quote": "Timestamp of the To-leg transaction record creation.",
      "match": "NO",
      "loss": "Rewrote 'this' as 'the To-leg' — verbatim text altered"
    },
    {
      "column": "ToAddress",
      "upstream_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal.",
      "wiki_quote": "Destination blockchain address for this conversion leg. NULL when the transfer is internal.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "SentToEtoroWalletAmount",
      "upstream_quote": "Amount of crypto for this conversion leg in native units.",
      "wiki_quote": "Amount of crypto for the To-leg conversion in native units. The actual amount sent to the destination wallet.",
      "match": "NO",
      "loss": "Rewrote 'this conversion leg' as 'the To-leg conversion'; appended extra sentence"
    },
    {
      "column": "SentToEtoroWalletEtoroFees",
      "upstream_quote": "Calculated eToro fee amount in the crypto's native units.",
      "wiki_quote": "Calculated eToro fee amount in the crypto's native units. Platform fee for the To-leg.",
      "match": "MINOR",
      "loss": "Upstream preserved; leg context appended"
    },
    {
      "column": "SentToEtoroBlockchainFees",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Network cost for the To-leg sent transaction.",
      "match": "MINOR",
      "loss": "Upstream preserved; context appended"
    },
    {
      "column": "SentFromEtoroWalletAmount",
      "upstream_quote": "Amount of crypto for this conversion leg in native units.",
      "wiki_quote": "Amount of crypto for the From-leg conversion in native units. The actual amount sent from the source wallet.",
      "match": "NO",
      "loss": "Same rewording pattern as SentToEtoroWalletAmount"
    },
    {
      "column": "SentFromEtoroWalletEtoroFees",
      "upstream_quote": "Calculated eToro fee amount in the crypto's native units.",
      "wiki_quote": "Calculated eToro fee amount in the crypto's native units. Platform fee for the From-leg.",
      "match": "MINOR",
      "loss": "Upstream preserved; leg context appended"
    },
    {
      "column": "SentFromEtoroBlockchainFees",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Network cost for the From-leg sent transaction.",
      "match": "MINOR",
      "loss": "Upstream preserved; context appended"
    },
    {
      "column": "FromEtoroEstimatedBCFee",
      "upstream_quote": "Estimated blockchain network fee for this leg.",
      "wiki_quote": "Estimated blockchain network fee for this leg. Pre-send estimate for the From-leg of the conversion.",
      "match": "MINOR",
      "loss": "Upstream preserved; context appended"
    },
    {
      "column": "FromEtoroDate",
      "upstream_quote": "Timestamp of this transaction record creation.",
      "wiki_quote": "Timestamp of the From-leg transaction record creation.",
      "match": "NO",
      "loss": "Same rewording pattern as ToEtoroDate"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "ToEtoroDate, FromEtoroDate",
      "problem": "Upstream ConversionTransactions.Occurred says 'Timestamp of this transaction record creation.' Wiki rewrites as 'Timestamp of the To/From-leg transaction record creation.' — verbatim quoting rule violated."
    },
    {
      "severity": "high",
      "column_or_section": "SentToEtoroWalletAmount, SentFromEtoroWalletAmount",
      "problem": "Upstream ConversionTransactions.Amount says 'Amount of crypto for this conversion leg in native units.' Wiki rewrites as 'Amount of crypto for the To/From-leg conversion in native units' and appends an extra sentence — verbatim quoting rule violated."
    },
    {
      "severity": "medium",
      "column_or_section": "FromAddress (Element #5)",
      "problem": "Tagged Tier 2 (external pipeline) but lineage traces it to Wallet.ConversionTransactions.ToAddress which has an upstream wiki in the bundle. Should be Tier 1 with the upstream description verbatim, or Tier 2 citing ConversionTransactions rather than 'external pipeline'."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5.1 lineage — RequestedFromAmount/FromAmount",
      "problem": "Both RequestedFromAmount and FromAmount are mapped to Wallet.Conversions.FromAmount in the lineage table. If they come from the same upstream column, the wiki's claim that one is 'original request' and the other is 'actual after micro-fee deduction' contradicts the single-source mapping."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2 — missing ConversionTypeId context",
      "problem": "Upstream Wallet.Conversions has ConversionTypeId (1=FixedFrom, 2=FixedTo) which determines whether FromAmount or ToAmount was user-specified. This column was dropped during ETL but the business logic implications are not documented."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix 4 paraphrased Tier 1 columns (ToEtoroDate, FromEtoroDate, SentToEtoroWalletAmount, SentFromEtoroWalletAmount) — quote upstream verbatim ('this conversion leg' / 'this transaction record creation') and append leg-specific context AFTER the verbatim quote, separated by a period. (2) Re-evaluate FromAddress tier: source is ConversionTransactions.ToAddress (wiki exists in bundle); either tag Tier 1 with verbatim upstream quote or keep Tier 2 but cite ConversionTransactions.ToAddress, not 'external pipeline'. (3) Clarify RequestedFromAmount vs FromAmount lineage — both map to Wallet.Conversions.FromAmount; explain which pipeline step produces the difference or correct the source column mapping. (4) Add a note in Section 2 about the dropped ConversionTypeId column (FixedFrom=1 vs FixedTo=2) from upstream Wallet.Conversions.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
