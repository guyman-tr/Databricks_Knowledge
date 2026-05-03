## Review: EXW_Wallet.CryptoTypes

This is a Generic Pipeline passthrough table from an external production database (WalletDB.Wallet.CryptoTypes) with **no upstream wiki available**. The writer correctly identified this and tagged all 31 production columns as Tier 3 and the 4 ETL columns as Tier 2. This is one of the cleaner wikis I've reviewed — the absence of upstream documentation limits the ceiling but the writer made the most of live data.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (CryptoID, BlockchainCryptoId, DisplayName, etr_y, Status). All tier assignments are correct. No upstream wiki exists, so all production columns are legitimately Tier 3. ETL columns correctly tagged Tier 2. No paraphrasing failures possible since there are zero Tier 1 columns.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No upstream wiki was available in the bundle. The writer correctly documented this in the review-needed sidecar and lineage file. Per rubric, this is a neutral 7.

**Dimension 3 — Completeness: 10/10**
All 10 checks pass:
- [x] All 8 sections present
- [x] Element count (35) matches DDL column count (35)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (174) and date range (2018-04-23 to 2026-02-16)
- [x] Dictionary columns list inline values (Status: 1/3, AssetTypeId: 1/2, CryptoActivityStatus: 2/3, CryptoCategoryName: 3 values)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToroX Wallet crypto reference), row grain (one row per crypto asset), ETL source and pattern (Generic Pipeline #625, Override daily), row count (174), date range, concrete examples (BTC, ETH, XRP). Names 15+ downstream SP consumers. An analyst would immediately understand when and how to use this table.

**Dimension 5 — Data Evidence: 8/10**
Strong data grounding throughout: row count (174), date range, specific value distributions (Status 1=13/3=161, AssetTypeId 1=12/2=162, CryptoActivityStatus 2=173/3=1), concrete examples (BTC=CryptoID 1, ETH=CryptoID 2), case inconsistency flagged (baseCrypto vs BaseCrypto). Footer says "Phases: 12/14" — 2 phases skipped but data claims are specific and internally consistent, suggesting genuine data access rather than fabrication.

**Dimension 6 — Shape Fidelity: 9/10**
Matches the golden reference shape closely: numbered sections, tier legend in Section 4, real SQL in Section 7, proper footer with quality score and phases-completed. Minor: Section 8 (Atlassian) is present but empty, which is correct for this object.

---

### T1 Fidelity Table

No Tier 1 columns exist — the upstream source (WalletDB.Wallet.CryptoTypes) has no documented wiki. This is correctly reflected in the lineage file and review-needed sidecar.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — no Tier 1 columns)* | — | — | — | — |

---

### Top 5 Issues

1. **(Low) Minor data inconsistency in Section 2.1**: AssetTypeId=1 counts 12 assets while Status=1 counts 13 rows. This appears to be accurate data (different columns, different distributions), but the proximity of the two statements without explicit clarification could confuse analysts.

2. **(Low) Footer phases 12/14**: Two phases were skipped but which ones are not explicitly identified in the wiki. The data evidence is strong enough that this doesn't suggest fabrication, but transparency about skipped phases would be better.

3. **(Info) No upstream wiki path forward**: The review-needed sidecar correctly flags this, but if WalletDB.Wallet.CryptoTypes ever gets documented, all 31 columns would need re-evaluation for Tier 1 upgrade — a significant re-work scope.

4. **(Info) CryptoCategoryName case inconsistency**: Correctly flagged in Gotchas (Section 3.4) and review-needed sidecar. Good catch by the writer.

5. **(Info) InstrumentId FK target**: Element #25 references "eToro's instrument system" and SP_Prices joining with "EXW_Currency.Instruments" — the relationship section could be more precise about the target table.

---

### Regeneration Feedback

No regeneration needed. If upstream wiki becomes available in the future:
1. Re-run the pipeline to upgrade Tier 3 columns to Tier 1 with verbatim descriptions.
2. Clarify which 2 of 14 phases were skipped in the footer.
3. Add explicit cross-reference between AssetTypeId and Status value distributions in Section 2.1 to avoid confusion.

---

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90
         = 8.95
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "CryptoTypes",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 2.1 (AssetTypeId vs Status)",
      "problem": "AssetTypeId=1 counts 12 assets while Status=1 counts 13 rows. While likely accurate (different columns), the proximity without clarification could confuse analysts."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer says 'Phases: 12/14' but does not identify which 2 phases were skipped."
    },
    {
      "severity": "info",
      "column_or_section": "All 31 production columns",
      "problem": "All production columns are Tier 3 due to missing upstream wiki for WalletDB.Wallet.CryptoTypes. Correct classification but limits documentation quality ceiling."
    },
    {
      "severity": "info",
      "column_or_section": "CryptoCategoryName",
      "problem": "Case inconsistency ('baseCrypto' vs 'BaseCrypto') correctly flagged in Gotchas and review-needed sidecar."
    },
    {
      "severity": "info",
      "column_or_section": "InstrumentId",
      "problem": "Element #25 references 'eToro's instrument system' and Section 6.1 says 'eToro Instrument system' — the FK target table (EXW_Currency.Instruments) mentioned in the description could be more precisely documented in Relationships."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Unknown — footer says 12/14 but does not identify which 2 were skipped"]
  }
}
</JUDGE_VERDICT>
