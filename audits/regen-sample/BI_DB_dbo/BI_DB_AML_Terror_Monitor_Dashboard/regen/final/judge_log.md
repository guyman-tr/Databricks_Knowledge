## Human Summary

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 7 | 1 of 5 sampled columns misclassified: `AMLEntity` (and siblings) tagged Tier 1 but upstream wiki has no individual column entries for these fields — descriptions are inferred, not quoted |
| Upstream Fidelity (20%) | 6 | 13 of 16 T1 columns are MINOR (verbatim + added context); 3 are NO (`AMLEntity`, `AMLSubEntity`, `AMLSubEntity_2`) because upstream wiki simply does not document those columns individually |
| Completeness (20%) | 10 | All 8 sections present, 22/22 elements matching DDL, tier legend, ASCII pipeline, footer with tier counts, row count + date in §1, dictionary enums inline, review-needed clean |
| Business Meaning (15%) | 9 | Concrete: names row grain, all 4 population filters, ETL SP, refresh cadence, regulation distribution, and compliance usage context |
| Data Evidence (10%) | 8 | Real row count (270,341 as of 2024-12-28), live value distributions for RiskScoreName, ScreeningStatus, AMLEntity; phases 11/14 with data gates evidently run |
| Shape Fidelity (10%) | 9 | All 8 sections, tier legend, real SQL in §7, correct footer format; minor: §5 references a separate lineage file rather than inlining the column-level table |

**Weighted total: 0.25×7 + 0.20×6 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9 = 1.75 + 1.20 + 2.00 + 1.35 + 0.80 + 0.90 = 8.00 → PASS**

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)" | Same + "Renamed from Dim_Customer.RealCID." | MINOR | Added rename note; meaning preserved |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | Same + "Resolved from DWH_dbo.Dim_Regulation via Dim_Customer.RegulationID." | MINOR | Added join context |
| KYC_Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | Same + "Resolved from DWH_dbo.Dim_Country via Dim_Customer.CountryID (customer's KYC country of residence)." | MINOR | Added join context |
| CitizenshipCountry | Same upstream as KYC_Country | Same verbatim + "Resolved from DWH_dbo.Dim_Country via Dim_Customer.CitizenshipCountryID. NULL if CitizenshipCountryID is NULL." | MINOR | Added join context + NULL note |
| POBCountry | Same upstream as KYC_Country | Same verbatim + join + NULL note | MINOR | Added join context |
| CountryByIP_Residency | Same upstream as KYC_Country | Same verbatim + "Resolved from DWH_dbo.Dim_Country via Dim_Customer.CountryIDByIP (country detected from registration IP). NULL if CountryIDByIP is NULL." | MINOR | Added join context |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | Same + "Only Normal (ID=1) and Warning (ID=5) appear in this table due to the SP population filter." | MINOR | Added population filter note; core description verbatim |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | Same + "Resolved from DWH_dbo.Dim_PlayerLevel via Dim_Customer.PlayerLevelID." | MINOR | Added join context |
| HasWallet | "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0." | Same + "Passthrough from DWH_dbo.Dim_Customer." | MINOR | Added passthrough note |
| RegisteredReal | "Account registration date (renamed from Registered). Default=getdate()." | Same + "Passthrough from DWH_dbo.Dim_Customer." | MINOR | Added passthrough note |
| FirstDepositDate | "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer)" | Same + passthrough note; labeled hybrid Tier 1/Tier 2 | MINOR | Upstream is already Tier 2; hybrid labeling is honest but unconventional |
| FirstDepositAmount | "Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer)" | Same + passthrough note; hybrid tier | MINOR | Same as FirstDepositDate |
| ScreeningStatus | "Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. (Tier 3 - live data)" | Same + join context + live value distribution | MINOR | Added live values enhance rather than paraphrase |
| AMLEntity | **N/A — BI_DB_AML_SubEntity_Categorization wiki documents 9 elements; `AMLEntity` is not among them** | "Primary AML legal entity assignment for this customer, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLEntity… only 'eToro_Gibraltar' is observed (28,615 rows…)" | **NO** | No verbatim source exists; entire description is inferred from SP code + live data observation |
| AMLSubEntity | Same — not in upstream wiki | "Secondary AML legal entity assignment… 'eToro_Money_UK' (6,566 rows…), 'eToro_Germany' (6,191 rows…)" | **NO** | No verbatim source; inferred from live data |
| AMLSubEntity_2 | Same — not in upstream wiki | "Tertiary AML legal entity assignment… 'eToro_Money_Malta' (509 rows…)" | **NO** | No verbatim source; inferred from live data |

---

### Top 5 Issues

1. **[HIGH] AMLEntity / AMLSubEntity / AMLSubEntity_2 — Tier 1 with no verbatim source**
   - These three columns are tagged `(Tier 1 — BI_DB_AML_SubEntity_Categorization)` but the upstream wiki for that table documents only 9 elements (`CID, GCID, CountryID, Country, RegulationID, Regulation, UpdateDate, VerificationLevelID, AML_Sub_Entity`) — none of which is `AMLEntity`, `AMLSubEntity`, or `AMLSubEntity_2`. The descriptions are generated from SP context and live data observation, not quoted verbatim. These should be `(Tier 2 — SP_AML_Terror_Monitor_Dashboard)` with a review-needed note to update the upstream wiki.

2. **[MEDIUM] AMLEntity / AMLSubEntity / AMLSubEntity_2 upstream wiki is structurally incomplete**
   - The BI_DB_AML_SubEntity_Categorization wiki only documents `AML_Sub_Entity` (a STRING_AGG concatenated column). The SP actually reads three separate decomposed columns. The upstream wiki needs to be updated to document these three columns before their downstream descriptions can be elevated to Tier 1.

3. **[MEDIUM] UpdateDate staleness not surfaced in §1 Business Meaning**
   - The review-needed sidecar correctly flags that all 270,341 rows show `UpdateDate = '2024-12-28'` — approximately 16 months before generation date (2026-04-28). This strongly suggests the SP is no longer running on schedule or the table is deprecated. Section 1 presents the table as actively refreshed ("daily TRUNCATE+INSERT") without any caveat. A freshness warning should appear in §1.

4. **[LOW] ScreeningStatus tier citation skips the relay**
   - Tagged `(Tier 1 — ScreeningService.Dictionary.ScreeningStatus)` but the direct upstream is `DWH_dbo.Dim_ScreeningStatus`, which itself documents that column as Tier 3 (no upstream wiki located). The citation correctly names the root origin, but the fact that the relay dimension has no confirmed wiki for this column should be noted. This is a minor documentation chain issue.

5. **[LOW] FirstDepositDate / FirstDepositAmount hybrid tier labeling**
   - These are labeled `(Tier 1 — Dim_Customer, Tier 2 in source: SP_Dim_Customer)`. While honest, mixing two tier labels in a single tier citation breaks the tier legend's one-tier-per-column contract. Should be either `(Tier 1 — Dim_Customer)` (since Dim_Customer is the direct upstream with a wiki) or documented in a footnote.

---

### Regeneration Feedback

1. **Re-tag AMLEntity, AMLSubEntity, AMLSubEntity_2 from Tier 1 to Tier 2** — `(Tier 2 — SP_AML_Terror_Monitor_Dashboard)` — since the upstream wiki for `BI_DB_AML_SubEntity_Categorization` does not individually document these columns. Add to review-needed: "Update BI_DB_AML_SubEntity_Categorization wiki to document AMLEntity, AMLSubEntity, AMLSubEntity_2 as individual elements; then upgrade to Tier 1."
2. **Add data staleness warning to §1** — Note that as of sampling date, all rows show `UpdateDate = '2024-12-28'` (~16 months stale). Flag as potentially dormant and direct users to verify SP scheduling before relying on the table for current compliance data.
3. **Normalize FirstDepositDate / FirstDepositAmount tier citations** — Use single-tier format: `(Tier 1 — Dim_Customer)` and remove the inline "Tier 2 in source" parenthetical, which belongs in the lineage file not the Element description.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AML_Terror_Monitor_Dashboard",
  "weighted_score": 8.0,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 6,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic)",
      "match": "MINOR",
      "loss": "Added 'Renamed from Dim_Customer.RealCID' — factually correct context, meaning preserved"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Resolved from DWH_dbo.Dim_Regulation via Dim_Customer.RegulationID.",
      "match": "MINOR",
      "loss": "Added join routing context; core description verbatim"
    },
    {
      "column": "KYC_Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.CountryID (customer's KYC country of residence).",
      "match": "MINOR",
      "loss": "Added join routing; verbatim core preserved"
    },
    {
      "column": "CitizenshipCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.CitizenshipCountryID. NULL if CitizenshipCountryID is NULL.",
      "match": "MINOR",
      "loss": "Added join routing and NULL note"
    },
    {
      "column": "POBCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.POBCountryID (place of birth). NULL if POBCountryID is NULL.",
      "match": "MINOR",
      "loss": "Added join routing and NULL note"
    },
    {
      "column": "CountryByIP_Residency",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.CountryIDByIP (country detected from registration IP). NULL if CountryIDByIP is NULL.",
      "match": "MINOR",
      "loss": "Added join routing and NULL note"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Only Normal (ID=1) and Warning (ID=5) appear in this table due to the SP population filter.",
      "match": "MINOR",
      "loss": "Added population filter note; core verbatim"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Resolved from DWH_dbo.Dim_PlayerLevel via Dim_Customer.PlayerLevelID.",
      "match": "MINOR",
      "loss": "Added join routing; verbatim core preserved"
    },
    {
      "column": "HasWallet",
      "upstream_quote": "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0.",
      "wiki_quote": "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from DWH_dbo.Dim_Customer.",
      "match": "MINOR",
      "loss": "Added passthrough note"
    },
    {
      "column": "RegisteredReal",
      "upstream_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "wiki_quote": "Account registration date (renamed from Registered). Default=getdate(). Passthrough from DWH_dbo.Dim_Customer.",
      "match": "MINOR",
      "loss": "Added passthrough note"
    },
    {
      "column": "FirstDepositDate",
      "upstream_quote": "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer)",
      "wiki_quote": "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from DWH_dbo.Dim_Customer. (Tier 1 — Dim_Customer, Tier 2 in source: SP_Dim_Customer)",
      "match": "MINOR",
      "loss": "Core text verbatim; hybrid tier labeling is non-standard but honest"
    },
    {
      "column": "FirstDepositAmount",
      "upstream_quote": "Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer)",
      "wiki_quote": "Amount of first deposit (in USD). Updated from FTDAmountInUsd. Passthrough from DWH_dbo.Dim_Customer. (Tier 1 — Dim_Customer, Tier 2 in source: SP_Dim_Customer)",
      "match": "MINOR",
      "loss": "Core verbatim; hybrid tier labeling"
    },
    {
      "column": "ScreeningStatus",
      "upstream_quote": "Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management.",
      "wiki_quote": "Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. Resolved from DWH_dbo.Dim_ScreeningStatus via Dim_Customer.ScreeningStatusID (LEFT JOIN — NULL if no screening record). Live values: NoMatch (99.9%), PendingInvestigation (0.07%), PEP (0.01%).",
      "match": "MINOR",
      "loss": "Added join context and live values; core description verbatim"
    },
    {
      "column": "AMLEntity",
      "upstream_quote": "N/A — BI_DB_AML_SubEntity_Categorization wiki documents 9 elements (CID, GCID, CountryID, Country, RegulationID, Regulation, UpdateDate, VerificationLevelID, AML_Sub_Entity). AMLEntity is not among them.",
      "wiki_quote": "Primary AML legal entity assignment for this customer, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLEntity (LEFT JOIN on CID). In this population (high-risk country connection), only 'eToro_Gibraltar' is observed (28,615 rows = customers with crypto wallets outside Germany under CySEC/FCA/ASIC/ASIC&GAML/FSA Seychelles). NULL for customers not qualifying for any primary AML entity (89% of population). (Tier 1 — BI_DB_AML_SubEntity_Categorization)",
      "match": "NO",
      "loss": "No verbatim source exists in upstream wiki; entire description inferred from SP code and live data observation. Tier 1 claim is unsupported."
    },
    {
      "column": "AMLSubEntity",
      "upstream_quote": "N/A — column not documented in BI_DB_AML_SubEntity_Categorization wiki",
      "wiki_quote": "Secondary AML legal entity assignment, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLSubEntity (LEFT JOIN on CID). Observed values: 'eToro_Money_UK' (6,566 rows), 'eToro_Germany' (6,191 rows). NULL when no secondary entity qualifies. (Tier 1 — BI_DB_AML_SubEntity_Categorization)",
      "match": "NO",
      "loss": "No verbatim source exists in upstream wiki; description entirely inferred. Tier 1 claim unsupported."
    },
    {
      "column": "AMLSubEntity_2",
      "upstream_quote": "N/A — column not documented in BI_DB_AML_SubEntity_Categorization wiki",
      "wiki_quote": "Tertiary AML legal entity assignment, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLSubEntity_2 (LEFT JOIN on CID). Observed values: 'eToro_Money_Malta' (509 rows). NULL when no tertiary entity qualifies. (Tier 1 — BI_DB_AML_SubEntity_Categorization)",
      "match": "NO",
      "loss": "No verbatim source exists in upstream wiki; description entirely inferred. Tier 1 claim unsupported."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "AMLEntity / AMLSubEntity / AMLSubEntity_2",
      "problem": "All three tagged (Tier 1 — BI_DB_AML_SubEntity_Categorization) but the upstream wiki for that table documents only 9 elements, none of which is AMLEntity, AMLSubEntity, or AMLSubEntity_2. The descriptions are inferred from SP source code and live data observation — not quoted verbatim from any upstream wiki. These should be downgraded to (Tier 2 — SP_AML_Terror_Monitor_Dashboard) until the upstream wiki is updated."
    },
    {
      "severity": "high",
      "column_or_section": "Section 1 / UpdateDate",
      "problem": "Table appears dormant: all 270,341 rows have UpdateDate = '2024-12-28 04:47:13.517', approximately 16 months before the generation date (2026-04-28). Section 1 presents the table as an actively refreshed daily feed without any staleness caveat. A compliance dashboard depending on this table would be consuming 16-month-old data. This risk is documented in the review-needed sidecar but is absent from the main wiki body."
    },
    {
      "severity": "medium",
      "column_or_section": "BI_DB_AML_SubEntity_Categorization upstream wiki",
      "problem": "The upstream wiki for BI_DB_AML_SubEntity_Categorization is structurally incomplete — it only documents AML_Sub_Entity (the STRING_AGG column). The SP actually reads three separate decomposed columns (AMLEntity, AMLSubEntity, AMLSubEntity_2) that are not reflected in the upstream wiki's Elements table. Both wikis need to be updated in tandem."
    },
    {
      "severity": "low",
      "column_or_section": "FirstDepositDate / FirstDepositAmount",
      "problem": "Hybrid tier label '(Tier 1 — Dim_Customer, Tier 2 in source: SP_Dim_Customer)' breaks the one-tier-per-column contract of the tier legend. The upstream Dim_Customer wiki explicitly marks both columns as Tier 2. While the hybrid label is honest, it creates inconsistency. Standard practice should be (Tier 1 — Dim_Customer) since Dim_Customer has a wiki, with the Tier 2 origin noted in the lineage file."
    },
    {
      "severity": "low",
      "column_or_section": "ScreeningStatus",
      "problem": "Tier citation points to 'ScreeningService.Dictionary.ScreeningStatus' as root origin, skipping the relay (Dim_ScreeningStatus). Dim_ScreeningStatus wiki explicitly documents the Name column as Tier 3 (no upstream wiki found). While tracing to the original source is correct per rubric, the Dim_ScreeningStatus intermediary's Tier 3 status should be noted to warn users that the column value provenance is only inferred, not verified against a production dictionary wiki."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag AMLEntity, AMLSubEntity, AMLSubEntity_2 from Tier 1 to Tier 2 — '(Tier 2 — SP_AML_Terror_Monitor_Dashboard)' — since BI_DB_AML_SubEntity_Categorization wiki does not document these columns individually; add review-needed item requesting upstream wiki update. (2) Add data staleness warning to Section 1: note that all rows show UpdateDate = '2024-12-28' (~16 months stale as of generation date) and direct users to verify SP_AML_Terror_Monitor_Dashboard scheduling before using the table for current compliance reporting. (3) Normalize FirstDepositDate and FirstDepositAmount to single-tier format: '(Tier 1 — Dim_Customer)'; move the 'Tier 2 in source' note to the lineage file.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "AMLEntity: '28,615 rows' in element description",
      "AMLSubEntity: '6,566 rows', '6,191 rows' in element description",
      "AMLSubEntity_2: '509 rows' in element description",
      "ScreeningStatus: 'NoMatch (99.9%), PendingInvestigation (0.07%), PEP (0.01%)' in element description",
      "RiskScoreName: 'Medium (87.4%), High (12.3%), Low (0.2%), NULL (0.2%)' in element description"
    ],
    "skipped_phases": ["P10 (Jira/Confluence) — explicitly noted in footer and Section 8"]
  }
}
</JUDGE_VERDICT>
