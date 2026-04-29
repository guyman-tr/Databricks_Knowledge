I'll review this wiki systematically against the upstream bundle, DDL, and SP code.

## Dimension-by-Dimension Evaluation

### Dimension 1 — Tier Accuracy (5 random columns)

| Column | Claimed Tier | Actual Tier | Correct? |
|--------|-------------|-------------|----------|
| **CID** (#1) | Tier 1 — Fact_SnapshotCustomer | SP: `sc.RealCID AS CID` — rename passthrough, upstream wiki exists | YES |
| **Desk** (#5) | Tier 1 — BI_DB_CIDFirstDates | SP: `fd.PotentialDesk Desk` — rename passthrough, upstream wiki exists | YES |
| **Regulation** (#10) | Tier 1 — Dictionary.Regulation | SP: `dr1.Name` — dim-lookup from Dim_Regulation, dim's origin is Dictionary.Regulation | YES |
| **FTD_Date** (#18) | Tier 1 — BI_DB_CIDFirstDates | SP: `CAST(fd.FirstDepositDate AS date)` — type-narrowing passthrough | YES |
| **IsVBT** (#23) | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT | SP: `CASE WHEN vbt.GCID IS NULL THEN 0 ELSE 1` — ETL-computed | YES |

0 mismatches. **Score: 10**

### Dimension 2 — Upstream Fidelity (T1 Fidelity Table)

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| **CID** | "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values." (FSC #2) | "Real (funded) customer ID. The primary customer identifier in the DWH ecosystem. Passthrough from Fact_SnapshotCustomer.RealCID (renamed)." | MINOR | Dropped "Hash distribution key", "FK to Dim_Customer", "46.4M distinct values" — all FSC-contextual, not semantic loss for this table |
| **Desk** | "Sales desk assignment. Resolved from Dim_Country.Desk via CountryID." (CIDFirstDates #13) | "Sales desk assignment. Resolved from Dim_Country.Desk via CountryID. Passthrough from BI_DB_CIDFirstDates.PotentialDesk (renamed)." | YES | — |
| **Region** | "Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc." (CIDFirstDates #12) | "Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. Passthrough from BI_DB_CIDFirstDates." | YES | — |
| **Country** | "Country of residence name. Resolved from Dim_Country.Name via CountryID." (CIDFirstDates #10) | "Country of residence name. Resolved from Dim_Country.Name via CountryID. Passthrough from BI_DB_CIDFirstDates." | YES | — |
| **Channel** | "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc." (CIDFirstDates #7) | "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. Passthrough from BI_DB_CIDFirstDates." | YES | — |
| **SubChannel** | "Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc." (CIDFirstDates #8) | "Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. Passthrough from BI_DB_CIDFirstDates." | YES | — |
| **Regulation** | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation #2) | "Short code for the regulation. Used in analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID." | MINOR | Dropped "Used in V_Dim_Customer" — contextual to Dim_Regulation |
| **DesignatedRegulation** | Same upstream as Regulation: "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the designated (secondary) regulation. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.DesignatedRegulationID." | MINOR | Dropped "Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name" — only retained the first sentence paraphrased |
| **Reg_Date** | "Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first." (CIDFirstDates #27) | "Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first. CAST to DATE from BI_DB_CIDFirstDates.registered." | YES | — |
| **V2_Date** | "First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found." (CIDFirstDates #114) | "First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel2Date." | YES | — |
| **V3_Date** | "First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set." (CIDFirstDates #115) | "First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel3Date." | YES | — |
| **FTD_Date** | "First successful deposit date. Read directly from Dim_Customer.FirstDepositDate (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FirstDepositDate) != 1900`." (CIDFirstDates #40) | "First successful deposit date. Read directly from Dim_Customer.FirstDepositDate, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FTD_Date) != 1900`. CAST to DATE from BI_DB_CIDFirstDates.FirstDepositDate." | MINOR | Dropped "(alias `dc`)", adapted column name in filter — no semantic loss |
| **FTDA** | "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0." (CIDFirstDates #43) | "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. Passthrough from BI_DB_CIDFirstDates.FirstDepositAmount (renamed)." | YES | — |
| **FirstPosOpen_Date** | "First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1." (CIDFirstDates #45) | "First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1. CAST to DATE from BI_DB_CIDFirstDates.FirstPosOpenDate." | YES | — |
| **PlayerStatusID** | "Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus." (FSC #12) | "Customer lifecycle status. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer. Note: statuses 2 (Blocked), 4 (Blocked Upon Request), 13 (Pending Verification) are excluded by the SP WHERE clause." | MINOR | Dropped "(e.g., Active, Blocked, Pending)" and "DEFAULT 0" — compensated by adding SP exclusion context |
| **PlayerStatus** | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." (Dim_PlayerStatus #2) | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Dim-lookup from Dim_PlayerStatus.Name." | YES | — |

**Summary**: 11 YES, 5 MINOR (all trivial context adaptations, zero semantic losses, zero vendor/system name drops, zero NULL-semantic removals).

**Score: 9** (all verbatim or trivially adapted, no paraphrasing with semantic loss)

### Dimension 3 — Completeness

- [x] All 8 sections present (1-8)
- [x] Element count matches DDL: 26 DDL columns = 26 wiki elements
- [x] Every element row has 5 cells
- [x] Every element description ends with (Tier N — source)
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (44.5M) and date range (2019-01-01 to present)
- [x] No dictionary columns with ≤15 values needing inline lists (binary flags are self-explanatory)
- [x] .review-needed.md does NOT contain `## 4. Elements`

**Score: 10**

### Dimension 4 — Business Meaning

Section 1 is excellent: names the domain (daily customer acquisition funnel), row grain (one row per CID per calendar day where at least one milestone flag=1), ETL SP, refresh pattern (daily DELETE+INSERT), VBT classification purpose, valid customer filter, and concrete stats (44.5M rows, 36.2M distinct CIDs, 2,666 dates, 2026 YTD funnel counts, IsVBT distribution). A new analyst would immediately know when and how to query this table.

**Score: 10**

### Dimension 5 — Data Evidence

- Row count + date range in Section 1: YES (44.5M, 36.2M CIDs, 2019-01-01 to present)
- Specific enum values: YES (2026 YTD: 1.5M reg, 698K V2, 320K V3, 155K FTD, 128K first pos; 42%/58% VBT split)
- NULL-rate claims: Sentinel documented (FTD_Date 1900-01-01) but no explicit NULL-rate percentages
- Phase Gate: Footer says "Phases: 11/14" but no explicit P2/P3 checkbox section. Data claims are highly specific, suggesting real queries.

**Score: 8**

### Dimension 6 — Shape Fidelity

- Numbered sections 1-8: YES
- Tier legend in Section 4: YES (though only shows Tier 1 and Tier 2, which is appropriate since no other tiers are used)
- Real SQL in Section 7: YES (3 queries)
- Footer with quality score + phases list: YES
- Minor: No standalone Phase Gate Checklist section

**Score: 8**

### Weighted Total

```
weighted = 0.25×10 + 0.20×9 + 0.20×10 + 0.15×10 + 0.10×8 + 0.10×8
         = 2.50 + 1.80 + 2.00 + 1.50 + 0.80 + 0.80
         = 9.40
```

**Verdict: PASS**

### Top 5 Issues

1. **Low — DesignatedRegulation description abbreviated**: Drops "Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name" from upstream Dim_Regulation.Name description. Not a semantic failure but less informative than it could be.

2. **Low — CID drops FSC-contextual attributes**: "Hash distribution key", "FK to Dim_Customer (if exists)" dropped. Defensible since CID is not the hash key in this table, but the FK reference would be useful.

3. **Low — No Phase Gate Checklist section**: The wiki has no explicit P2/P3 checkbox section. Data claims appear genuine based on specificity but there's no verifiable audit trail.

4. **Low — PlayerStatusID drops example values**: Upstream includes "(e.g., Active, Blocked, Pending)" which was dropped. Compensated by adding the SP exclusion note, but the examples help analysts unfamiliar with the ID values.

5. **Info — Regulation join uses DWHRegulationID**: SP joins `sc.RegulationID = dr1.DWHRegulationID`. The Dim_Regulation wiki notes DWHRegulationID always equals ID and recommends using ID. Wiki correctly documents this but doesn't flag the potential confusion.

### Regeneration Feedback

No regeneration needed — PASS. Minor polish if desired:
1. Add "Values match production Dictionary.Regulation.Name" to DesignatedRegulation description for completeness.
2. Consider adding a Phase Gate Checklist section to make data evidence verifiable.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CID_Daily_AcquisitionFunnel_VBT",
  "weighted_score": 9.40,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values.",
      "wiki_quote": "Real (funded) customer ID. The primary customer identifier in the DWH ecosystem. Passthrough from Fact_SnapshotCustomer.RealCID (renamed).",
      "match": "MINOR",
      "loss": "Dropped 'Hash distribution key', 'FK to Dim_Customer (if exists)', '46.4M distinct values' — all FSC-contextual, not semantic loss for this table"
    },
    {
      "column": "Desk",
      "upstream_quote": "Sales desk assignment. Resolved from Dim_Country.Desk via CountryID.",
      "wiki_quote": "Sales desk assignment. Resolved from Dim_Country.Desk via CountryID. Passthrough from BI_DB_CIDFirstDates.PotentialDesk (renamed).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Region",
      "upstream_quote": "Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc.",
      "wiki_quote": "Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. Passthrough from BI_DB_CIDFirstDates.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Country of residence name. Resolved from Dim_Country.Name via CountryID.",
      "wiki_quote": "Country of residence name. Resolved from Dim_Country.Name via CountryID. Passthrough from BI_DB_CIDFirstDates.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Channel",
      "upstream_quote": "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc.",
      "wiki_quote": "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. Passthrough from BI_DB_CIDFirstDates.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "SubChannel",
      "upstream_quote": "Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc.",
      "wiki_quote": "Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. Passthrough from BI_DB_CIDFirstDates.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID.",
      "match": "MINOR",
      "loss": "Dropped 'Used in V_Dim_Customer' — contextual to Dim_Regulation, not this table"
    },
    {
      "column": "DesignatedRegulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the designated (secondary) regulation. Dim-lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.DesignatedRegulationID.",
      "match": "MINOR",
      "loss": "Dropped 'Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name' — abbreviated, though context-adapted for secondary regulation role"
    },
    {
      "column": "Reg_Date",
      "upstream_quote": "Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first.",
      "wiki_quote": "Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first. CAST to DATE from BI_DB_CIDFirstDates.registered.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "V2_Date",
      "upstream_quote": "First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found.",
      "wiki_quote": "First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel2Date.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "V3_Date",
      "upstream_quote": "First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set.",
      "wiki_quote": "First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. CAST to DATE from BI_DB_CIDFirstDates.VerificationLevel3Date.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FTD_Date",
      "upstream_quote": "First successful deposit date. Read directly from Dim_Customer.FirstDepositDate (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FirstDepositDate) != 1900`.",
      "wiki_quote": "First successful deposit date. Read directly from Dim_Customer.FirstDepositDate, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FTD_Date) != 1900`. CAST to DATE from BI_DB_CIDFirstDates.FirstDepositDate.",
      "match": "MINOR",
      "loss": "Dropped '(alias `dc`)' and adapted column name in filter — no semantic loss"
    },
    {
      "column": "FTDA",
      "upstream_quote": "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0.",
      "wiki_quote": "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. Passthrough from BI_DB_CIDFirstDates.FirstDepositAmount (renamed).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FirstPosOpen_Date",
      "upstream_quote": "First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1.",
      "wiki_quote": "First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1. CAST to DATE from BI_DB_CIDFirstDates.FirstPosOpenDate.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PlayerStatusID",
      "upstream_quote": "Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus.",
      "wiki_quote": "Customer lifecycle status. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer. Note: statuses 2 (Blocked), 4 (Blocked Upon Request), 13 (Pending Verification) are excluded by the SP WHERE clause.",
      "match": "MINOR",
      "loss": "Dropped '(e.g., Active, Blocked, Pending)' and 'DEFAULT 0' — compensated by adding SP exclusion context"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Dim-lookup from Dim_PlayerStatus.Name.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "DesignatedRegulation",
      "problem": "Description abbreviated vs upstream Dim_Regulation.Name — drops 'Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name'. Less informative than Regulation column's description for the same upstream source."
    },
    {
      "severity": "low",
      "column_or_section": "CID",
      "problem": "Drops 'FK to Dim_Customer (if exists)' from upstream FSC.RealCID description. The FK reference would help analysts understand join paths."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Footer",
      "problem": "No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer says 'Phases: 11/14' but data evidence audit trail is not verifiable from the wiki alone."
    },
    {
      "severity": "low",
      "column_or_section": "PlayerStatusID",
      "problem": "Drops upstream example values '(e.g., Active, Blocked, Pending)' which help analysts unfamiliar with the numeric IDs."
    },
    {
      "severity": "info",
      "column_or_section": "Section 5.1",
      "problem": "Regulation join documented as 'sc.RegulationID = dr1.DWHRegulationID' — correct per SP code, but Dim_Regulation wiki notes DWHRegulationID is always equal to ID and recommends using ID. No functional impact."
    }
  ],
  "regeneration_feedback": "No regeneration needed — PASS at 9.40. Optional polish: (1) Add 'Values match production Dictionary.Regulation.Name' to DesignatedRegulation description. (2) Consider adding a Phase Gate Checklist section for audit transparency.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist section not present as standalone section"]
  }
}
</JUDGE_VERDICT>
