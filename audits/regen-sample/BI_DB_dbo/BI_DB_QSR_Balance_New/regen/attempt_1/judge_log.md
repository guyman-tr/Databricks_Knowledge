## Adversarial Judge Review: BI_DB_dbo.BI_DB_QSR_Balance_New

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 6 | All 5 sampled columns correctly assigned Tier 1 vs Tier 2, but 2 Tier 1 columns (PlayerStatus, MifidCategory) have clear paraphrasing failures with semantic content lost from upstream wikis. -2 per paraphrasing failure. |
| Upstream Fidelity (20%) | 3 | ALL 6 Tier 1 columns are paraphrased. Dim-lookup columns (Regulation, PlayerStatus, Country, MifidCategory) had clear prose upstream descriptions that were completely rewritten. V_Liabilities columns more forgivable (upstream is formula-style) but still not verbatim. |
| Completeness (20%) | 8 | All 8 sections present, 35 elements match 35 DDL columns, all rows have 5 cells, all descriptions have tier tags, pipeline diagram present. Footer tier count is wrong: claims "4 T1, 31 T2" but actual count is 6 T1, 29 T2. |
| Business Meaning (15%) | 9 | Excellent Section 1: names CySEC/QSR domain, row grain, ETL SP author, dual-currency design, sustainability ratio approach, known bug, and specific data stats. Highly actionable. |
| Data Evidence (10%) | 7 | Row count (~130M), date range (Q1 2020–Q4 2023), distribution stats (61%/39% zero balance), value enumerations present. Phase Gate not explicitly marked as P2/P3 completed but evidence is consistent. |
| Shape Fidelity (10%) | 9 | All structural elements present: numbered sections, tier legend, real SQL samples, ETL pipeline diagram, footer with quality score. Minor: tier legend only shows 2 tiers (missing T3-T5 row). |

**Weighted Score: 0.25×6 + 0.20×3 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×9 = 6.65 → FAIL**

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation.Name) | "Short code for the regulatory authority governing this customer at quarter-end. Dim-lookup passthrough from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 12 values: CySEC, FCA, BVI..." | NO | Dropped "Used in V_Dim_Customer and analytics dashboards", rewrote opening clause |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." (Dim_PlayerStatus.Name) | "Account restriction state label at quarter-end. Dim-lookup passthrough from Dim_PlayerStatus.Name via Fact_SnapshotCustomer.PlayerStatusID. 9 values observed: Normal, Blocked... Note: some values have trailing spaces." | NO | Dropped "Human-readable", "Unique per status", "Used in BackOffice UI, compliance reports, and monitoring dashboards" |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." (Dim_Country.Name) | "Full country name in English at quarter-end. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID." | NO | Dropped "Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." |
| ClientBalanceEnd | "ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END" (V_Liabilities.Liabilities, T2 computed) | "Total client liabilities at quarter-end — what eToro owes the customer (real money, excluding promotional credit). ISNULL(V_Liabilities.Liabilities, 0). EUR rows divided by ECB Rate." | MINOR | Upstream is a formula, not prose. Wiki provides business interpretation drawn from V_Liabilities §1 meaning. Acceptable but not verbatim. |
| ClientBalanceEndRealCrypto | "ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0)" (V_Liabilities.LiabilitiesCryptoReal, T2 computed) | "Liabilities from real (settled) crypto positions at quarter-end. ISNULL(V_Liabilities.LiabilitiesCryptoReal, 0). EUR rows divided by ECB Rate." | MINOR | Same pattern — upstream is formula, wiki adds semantic gloss. |
| MifidCategory | "Human-readable classification label. Used in compliance dashboards and regulatory reports." (Dim_MifidCategorization.Name) | "MiFID II client classification tier name at quarter-end. Dim-lookup passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. Values: None, Retail, Professional, Elective professional, Retail Pending, Pending." | NO | Completely rewritten. Dropped "Used in compliance dashboards and regulatory reports." |

---

### Top 5 Issues

1. **[HIGH] All 4 dim-lookup Tier 1 columns paraphrased** — Regulation, PlayerStatus, Country, MifidCategory all have clear upstream prose descriptions in their respective dim wikis. The writer rewrote every one instead of quoting verbatim. This is the single biggest failure mode in the wiki.

2. **[MEDIUM] Footer tier count is wrong** — Footer claims "4 T1, 31 T2" but the Elements table contains 6 Tier 1 columns (Regulation, PlayerStatus, Country, ClientBalanceEnd, ClientBalanceEndRealCrypto, MifidCategory) and 29 Tier 2. The writer miscounted.

3. **[LOW] ClientBalanceEnd and ClientBalanceEndRealCrypto Tier 1 from V_Liabilities is debatable** — V_Liabilities marks both Liabilities and LiabilitiesCryptoReal as T2 (computed columns). The SP applies ISNULL(..., 0) + EUR÷Rate division. These could reasonably be Tier 2 (SP_Q_QSR_New) since the SP applies non-trivial transforms (ISNULL + currency division).

4. **[LOW] Section 8 is empty** — "No Atlassian sources searched" is understandable for harness mode but means the SP header commentary is the only contextual source cited. The SP header contains rich context (author notes about sensitivity, design rationale) that the wiki did capture well in Section 1.

5. **[LOW] MifidCategory Tier 1 tag says "Dictionary.MifidCategorization" which is correct root origin** — But the upstream Dim_MifidCategorization wiki provides a rich description including the full ID-to-name mapping (0=None, 1=Retail, etc.) and business rules about leverage/protection. The wiki captured the value list but dropped the business context about leverage caps and investor protection.

---

### Regeneration Feedback

1. **Quote Tier 1 dim-lookup descriptions verbatim** from upstream wikis: Regulation → Dim_Regulation.Name description, PlayerStatus → Dim_PlayerStatus.Name description, Country → Dim_Country.Name description, MifidCategory → Dim_MifidCategorization.Name description. Append QSR-specific context (value counts, trailing spaces) AFTER the verbatim quote, not instead of it.
2. **Fix footer tier counts**: 6 T1 (Regulation, PlayerStatus, Country, ClientBalanceEnd, ClientBalanceEndRealCrypto, MifidCategory), 29 T2, 0 T3/T4/T5.
3. **Reconsider ClientBalanceEnd and ClientBalanceEndRealCrypto tiers**: Since V_Liabilities itself marks these as T2 computed columns and the SP applies ISNULL + EUR currency division, Tier 2 from SP_Q_QSR_New/V_Liabilities may be more accurate. If kept as Tier 1, quote the V_Liabilities business meaning from §1 verbatim.
4. **Add tier legend rows for T3–T5** even if unused, for shape conformance.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_QSR_Balance_New",
  "weighted_score": 6.65,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 6,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulatory authority governing this customer at quarter-end. Dim-lookup passthrough from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 12 values: CySEC, FCA, BVI, ASIC & GAML, FinCEN+FINRA, FinCEN, ASIC, FSA Seychelles, eToroUS, FSRA, NFA, None.",
      "match": "NO",
      "loss": "Dropped 'Used in V_Dim_Customer and analytics dashboards', rewrote opening clause from 'Short code for the regulation' to 'Short code for the regulatory authority governing this customer at quarter-end'"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Account restriction state label at quarter-end. Dim-lookup passthrough from Dim_PlayerStatus.Name via Fact_SnapshotCustomer.PlayerStatusID. 9 values observed: Normal, Blocked, Block Deposit & Trading, Pending Verification, Blocked Upon Request, Trade & MIMO Blocked, Deposit Blocked, Warning, Copy Block. Note: some values have trailing spaces.",
      "match": "NO",
      "loss": "Dropped 'Human-readable', 'Unique per status', 'Used in BackOffice UI, compliance reports, and monitoring dashboards'"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English at quarter-end. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID.",
      "match": "NO",
      "loss": "Dropped 'Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.'"
    },
    {
      "column": "ClientBalanceEnd",
      "upstream_quote": "ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END",
      "wiki_quote": "Total client liabilities at quarter-end — what eToro owes the customer (real money, excluding promotional credit). ISNULL(V_Liabilities.Liabilities, 0). EUR rows divided by ECB Rate.",
      "match": "MINOR",
      "loss": "Upstream is formula-style, not prose. Wiki provides business interpretation from V_Liabilities Section 1 but not verbatim."
    },
    {
      "column": "ClientBalanceEndRealCrypto",
      "upstream_quote": "ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0)",
      "wiki_quote": "Liabilities from real (settled) crypto positions at quarter-end. ISNULL(V_Liabilities.LiabilitiesCryptoReal, 0). EUR rows divided by ECB Rate.",
      "match": "MINOR",
      "loss": "Upstream is formula-style. Wiki adds semantic description not present in upstream column entry."
    },
    {
      "column": "MifidCategory",
      "upstream_quote": "Human-readable classification label. Used in compliance dashboards and regulatory reports.",
      "wiki_quote": "MiFID II client classification tier name at quarter-end. Dim-lookup passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. Values: None, Retail, Professional, Elective professional, Retail Pending, Pending.",
      "match": "NO",
      "loss": "Completely rewritten. Dropped 'Human-readable classification label. Used in compliance dashboards and regulatory reports.'"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Regulation, PlayerStatus, Country, MifidCategory",
      "problem": "All 4 dim-lookup Tier 1 columns have upstream prose descriptions in their respective dimension wikis (Dim_Regulation.Name, Dim_PlayerStatus.Name, Dim_Country.Name, Dim_MifidCategorization.Name) but the writer rewrote every description instead of quoting verbatim. Key content lost includes usage contexts ('Used in BackOffice UI'), uniqueness constraints ('Unique per status'), and application contexts ('Used in UI dropdowns, compliance documents')."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '4 T1, 31 T2' but Elements table contains 6 Tier 1 columns (Regulation, PlayerStatus, Country, ClientBalanceEnd, ClientBalanceEndRealCrypto, MifidCategory) and 29 Tier 2. Writer miscounted."
    },
    {
      "severity": "low",
      "column_or_section": "ClientBalanceEnd, ClientBalanceEndRealCrypto",
      "problem": "Tagged Tier 1 from V_Liabilities but V_Liabilities marks both Liabilities and LiabilitiesCryptoReal as T2 (computed columns). SP applies ISNULL + EUR currency division. Tier 2 from SP_Q_QSR_New may be more appropriate, or if Tier 1, the description should quote V_Liabilities Section 1 business meaning verbatim."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Tier legend only shows T1 and T2 rows. For shape conformance, T3-T5 rows should be listed even if count is 0."
    },
    {
      "severity": "low",
      "column_or_section": "MifidCategory",
      "problem": "Upstream Dim_MifidCategorization wiki provides rich business context about MiFID II leverage caps, investor protection, and margin requirements. Wiki captured value list but dropped all business context about what each tier means for the customer."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Quote Tier 1 dim-lookup descriptions VERBATIM from upstream wikis — Dim_Regulation.Name, Dim_PlayerStatus.Name, Dim_Country.Name, Dim_MifidCategorization.Name — then append QSR-specific context (value counts, trailing spaces) AFTER the verbatim quote. (2) Fix footer tier counts to 6 T1, 29 T2. (3) Reconsider ClientBalanceEnd/ClientBalanceEndRealCrypto tier: if kept as T1, quote V_Liabilities §1 business meaning verbatim; if re-tagged T2, update footer accordingly. (4) Add full tier legend (T1–T5) in Section 4 even for unused tiers.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["IsZeroBalance (Q4 2023: 61% NonZero, 39% Zero)"],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
