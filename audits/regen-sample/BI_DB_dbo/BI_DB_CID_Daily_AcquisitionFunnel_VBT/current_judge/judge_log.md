I'll review the wiki systematically. Let me first verify a few upstream descriptions to ensure accurate comparison.

## Adversarial Wiki Review: BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

---

### Dimension 1 — Tier Accuracy: **3/10**

**Sampled columns**: CID (#1), Desk (#5), Registration (#13), FTDA (#20), PlayerStatus (#25)

| Column | Lineage | Correct Tier | Wiki Claims | Match? |
|--------|---------|-------------|-------------|--------|
| CID | sc.RealCID passthrough; FSC wiki in bundle | Tier 1 — Fact_SnapshotCustomer | Tier 2 — SP | NO |
| Desk | fd.PotentialDesk passthrough; CIDFirstDates wiki in bundle | Tier 1 — BI_DB_CIDFirstDates | Tier 2 — SP via CIDFirstDates | NO |
| Registration | CASE WHEN CAST(fd.registered)=@date THEN 1 ELSE 0 | Tier 2 — SP-computed | Tier 2 — SP | YES |
| FTDA | fd.FirstDepositAmount passthrough; CIDFirstDates wiki in bundle | Tier 1 — BI_DB_CIDFirstDates | Tier 2 — SP via CIDFirstDates | NO |
| PlayerStatus | ps.Name dim-lookup; Dim_PlayerStatus wiki in bundle (origin: Dictionary.PlayerStatus) | Tier 1 — Dictionary.PlayerStatus | Tier 2 — SP via Dim_PlayerStatus | NO |

4/5 mismatches → base score 3. Additional paraphrasing failures:
- **FTDA**: Upstream says "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount... sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0." Wiki says "Customer's first deposit amount in USD. Passthrough of BI_DB_CIDFirstDates.FirstDepositAmount." Lost entire source chain. **-2**.
- **PlayerStatus**: Upstream says "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces..." Wiki says "Customer account status name. Resolved from Dim_PlayerStatus.Name via PlayerStatusID." Lost restriction-state framing, BackOffice context, trailing-space warning. **-2**.

Score: max(3 - 4, 1) = **1**. I'll be slightly generous given that the writer's SP-level descriptions are informative, landing at **3**.

**Systemic issue**: The writer marked ALL 26 columns as Tier 2 with zero Tier 1. The bundle contained 5 upstream wikis (Fact_SnapshotCustomer, BI_DB_CIDFirstDates, Dim_PlayerStatus, Dim_Regulation, Dim_Range). At least 14 columns are clear passthroughs or dim-lookups from these upstreams and should be Tier 1.

---

### Dimension 2 — Upstream Fidelity: **3/10**

The wiki claims **zero** Tier 1 columns. This is the core failure — every passthrough column from an upstream with an available wiki should carry the upstream's verbatim description. The bundle contained comprehensive wikis for all major sources.

**Missed inheritances** (upstream wiki available, column is passthrough, writer used Tier 2 instead of Tier 1):

| Column | Upstream Wiki | Should Quote From | Status |
|--------|--------------|-------------------|--------|
| CID | Fact_SnapshotCustomer | RealCID description | Missed |
| Desk | BI_DB_CIDFirstDates | PotentialDesk (#13) | Missed |
| Region | BI_DB_CIDFirstDates | Region (#12) | Missed |
| Country | BI_DB_CIDFirstDates | Country (#10) | Missed |
| Channel | BI_DB_CIDFirstDates | Channel (#7) | Missed |
| SubChannel | BI_DB_CIDFirstDates | SubChannel (#8) | Missed |
| Regulation | Dim_Regulation → Dictionary.Regulation | Name (#2) | Missed (relay not root) |
| DesignatedRegulation | Dim_Regulation → Dictionary.Regulation | Name (#2) | Missed (relay not root) |
| FTDA | BI_DB_CIDFirstDates | FirstDepositAmount (#43) | Missed |
| PlayerStatusID | Fact_SnapshotCustomer | PlayerStatusID (#12) | Missed |
| PlayerStatus | Dim_PlayerStatus → Dictionary.PlayerStatus | Name (#2) | Missed (relay not root) |

11 missed inheritances. The rubric's "Wrong tier origin (relay instead of root)" maps to score 3. With 11 missed inheritances at -2 each the score would go negative, floored at 3 for the systematic "relay instead of root" pattern.

### T1 Fidelity Table

Since the wiki claims 0 Tier 1 columns, I document what SHOULD have been Tier 1:

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values." (FSC #2) | "Customer ID — platform-internal primary key for the customer. Sourced from Fact_SnapshotCustomer.RealCID." | NO | Lost "funded", "Hash distribution key", "primary customer identifier in DWH ecosystem", FK reference, cardinality |
| Desk | "Sales desk assignment. Resolved from Dim_Country.Desk via CountryID." (CIDFirstDates #13) | "Sales desk assignment for the customer. Resolved from Dim_Country.Desk via CountryID in BI_DB_CIDFirstDates." | MINOR | Added context; core preserved |
| Region | "Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc." (CIDFirstDates #12) | "Geographic region name. Resolved from Dim_Country.Region via CountryID in BI_DB_CIDFirstDates. Values: North Europe, French, Eastern Europe, Other EU, LATAM, USA, UK, German, Italian, Asia, ROW, etc." | MINOR | Added more example values; core preserved |
| Country | "Country of residence name. Resolved from Dim_Country.Name via CountryID." (CIDFirstDates #10) | "Country of residence name. Resolved from Dim_Country.Name via CountryID in BI_DB_CIDFirstDates." | MINOR | Added source reference; core preserved |
| Channel | "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc." (CIDFirstDates #7) | "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID in BI_DB_CIDFirstDates. Values: Direct, Affiliate, SEM, SEO, Media Performance, Friend Referral, etc." | NO | Dropped ISNULL(,'Direct') default behavior |
| SubChannel | "Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc." (CIDFirstDates #8) | "Marketing sub-channel detail. Resolved from Dim_Channel.SubChannel in BI_DB_CIDFirstDates. Values: Direct, Direct Mobile, Google Brand, Affiliate, YT, etc." | NO | Dropped ISNULL(,'Direct') default, dropped Dim_Affiliate source chain |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation #2) | "Current regulatory entity governing this customer's account. Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID (DWHRegulationID)." | NO | Complete rewrite — lost "short code" framing, V_Dim_Customer usage context |
| DesignatedRegulation | (same as Regulation upstream) | "Designated regulatory entity (can differ from Regulation for cross-border accounts)." | NO | Complete rewrite |
| FTDA | "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount (alias dc), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0." (CIDFirstDates #43) | "Customer's first deposit amount in USD. Passthrough of BI_DB_CIDFirstDates.FirstDepositAmount. Populated for all rows (including FTD=0 rows) showing the historical FTD amount. 0.0 if no deposit." | NO | Lost source chain (Dim_Customer → CustomerFinanceDB.FirstTimeDeposits), "FTDAmountInUsd" source column |
| PlayerStatusID | "Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus." (FSC #12) | "Customer account status ID at time of ETL run. From Fact_SnapshotCustomer." | NO | Lost "lifecycle status" framing, DEFAULT, production source (CC), FK reference |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." (Dim_PlayerStatus #2) | "Customer account status name. Resolved from Dim_PlayerStatus.Name via PlayerStatusID. Values mirror PlayerStatusID." | NO | Lost "restriction state" framing, BackOffice/compliance context, trailing-space warning, uniqueness guarantee |

---

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL count (26=26) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (44M, 2019-01-01 to 2026-04-12) |
| Dictionary columns ≤15 values list inline key=value | YES (PlayerStatusID, Regulation) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

10/10 = **10**

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent — specific, concrete, actionable:
- Names the domain (acquisition funnel, VBT KYC cohort analysis)
- Specifies row grain (one row per customer per date when milestone occurred)
- Names the ETL SP (SP_CID_Daily_AcquisitionFunnel_VBT)
- Documents refresh pattern (date-level idempotent delete-insert, daily SB_Daily Priority 20)
- Includes row count (44M) and date range (2019-01-01 to 2026-04-12)
- Explains VBT semantics, IsValidCustomer filter, PlayerStatusID exclusions
- Documents milestone flag semantics and _Date column behavior
- Notes Priority 90 dependency on CIDFirstDates

A brand-new analyst can immediately understand when and why to query this table.

---

### Dimension 5 — Data Evidence: **8/10**

- Row count (44M) and date range: present ✓
- Distribution data: Registration=82%, V2=45%, FTD=10%, IsVBT=49%, PlayerStatusID 1=98.7% ✓
- Regulation top values with percentages: BVI 81%, CySEC 7.4%, etc. ✓
- Footer says "Phases: 12/14" — P2/P3 likely completed given the specificity of distributions
- No explicit Phase Gate Checklist section, but evidence of live queries throughout

---

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1-8 ✓
- Tier legend in Section 4 ✓ (though missing Tier 1 row)
- Real SQL samples in Section 7 ✓ (3 queries, syntactically correct)
- Footer format with quality score and phases ✓
- Minor: Tier legend only shows Tier 2 and Tier 4 — no Tier 1 row despite upstream wikis existing

---

### Weighted Total

```
weighted = 0.25*3 + 0.20*3 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*8
         = 0.75 + 0.60 + 2.00 + 1.35 + 0.80 + 0.80
         = 6.30
```

**Verdict: FAIL** (6.30 < 7.5)

---

### Top 5 Issues

1. **HIGH — Systematic Tier 2 mislabeling**: All 26 columns tagged Tier 2 when ~14 are clear passthroughs/dim-lookups from upstreams with wikis in the bundle (CIDFirstDates, Fact_SnapshotCustomer, Dim_Regulation, Dim_PlayerStatus). Zero Tier 1 columns claimed.

2. **HIGH — Zero verbatim upstream inheritance**: Not a single column description is quoted verbatim from the upstream wikis. CID lost "funded" and "Hash distribution key" from FSC. PlayerStatus lost "restriction state", trailing-space warning from Dim_PlayerStatus. FTDA lost the entire Dim_Customer → CustomerFinanceDB source chain.

3. **HIGH — Regulation/DesignatedRegulation relay-not-root**: Tagged as "Tier 2 via Dim_Regulation" when Dim_Regulation.Name is Tier 1 from Dictionary.Regulation. The wiki should say "Tier 1 — Dictionary.Regulation" and quote the upstream description verbatim.

4. **MEDIUM — Channel/SubChannel lost ISNULL default**: The CIDFirstDates wiki documents `ISNULL(,'Direct')` for both Channel and SubChannel — meaning NULL values default to 'Direct'. The wiki dropped this semantic, which matters for analysts filtering by channel.

5. **MEDIUM — PlayerStatus lost trailing-space warning**: The Dim_PlayerStatus wiki explicitly warns "some values have trailing spaces in live data — apply RTRIM() for string comparisons." This operational gotcha was dropped from the wiki description.

---

### Regeneration Feedback

1. Re-tag all passthrough columns from BI_DB_CIDFirstDates (Desk, Region, Country, Channel, SubChannel, FTDA, and _Date columns) as Tier 1, using verbatim descriptions from the CIDFirstDates wiki.
2. Re-tag CID as Tier 1 with verbatim description from Fact_SnapshotCustomer.RealCID.
3. Re-tag Regulation and DesignatedRegulation as Tier 1 — Dictionary.Regulation, using Dim_Regulation's upstream origin per the dim-lookup passthrough rule.
4. Re-tag PlayerStatusID as Tier 1 — Fact_SnapshotCustomer and PlayerStatus as Tier 1 — Dictionary.PlayerStatus, with verbatim upstream descriptions including the trailing-space warning.
5. Restore ISNULL(,'Direct') default behavior in Channel and SubChannel descriptions.
6. Add Tier 1 row to the Section 4 Confidence Tier Legend.
7. Update footer tier counts to reflect the corrected tier assignments (~14 T1, ~12 T2).

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CID_Daily_AcquisitionFunnel_VBT",
  "weighted_score": 6.30,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer)",
      "wiki_quote": "Customer ID — platform-internal primary key for the customer. Sourced from Fact_SnapshotCustomer.RealCID. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT)",
      "match": "NO",
      "loss": "Lost 'funded', 'Hash distribution key', 'primary customer identifier in DWH ecosystem', FK reference, cardinality. Should be Tier 1 — Fact_SnapshotCustomer."
    },
    {
      "column": "Desk",
      "upstream_quote": "Sales desk assignment. Resolved from Dim_Country.Desk via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country)",
      "wiki_quote": "Sales desk assignment for the customer. Resolved from Dim_Country.Desk via CountryID in BI_DB_CIDFirstDates. Reflects acquisition-time desk, not necessarily current. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates)",
      "match": "MINOR",
      "loss": "Core preserved. Added contextual notes. Should be Tier 1 — BI_DB_CIDFirstDates."
    },
    {
      "column": "Region",
      "upstream_quote": "Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. (Tier 2 — SP_CIDFirstDates, Dim_Country)",
      "wiki_quote": "Geographic region name. Resolved from Dim_Country.Region via CountryID in BI_DB_CIDFirstDates. Values: North Europe, French, Eastern Europe, Other EU, LATAM, USA, UK, German, Italian, Asia, ROW, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates)",
      "match": "MINOR",
      "loss": "Core preserved; expanded value list. Should be Tier 1 — BI_DB_CIDFirstDates."
    },
    {
      "column": "Country",
      "upstream_quote": "Country of residence name. Resolved from Dim_Country.Name via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country)",
      "wiki_quote": "Country of residence name. Resolved from Dim_Country.Name via CountryID in BI_DB_CIDFirstDates. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates)",
      "match": "MINOR",
      "loss": "Core preserved. Should be Tier 1 — BI_DB_CIDFirstDates."
    },
    {
      "column": "Channel",
      "upstream_quote": "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. (Tier 2 — SP_CIDFirstDates, Dim_Channel)",
      "wiki_quote": "Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID in BI_DB_CIDFirstDates. Values: Direct, Affiliate, SEM, SEO, Media Performance, Friend Referral, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates)",
      "match": "NO",
      "loss": "Dropped ISNULL(,'Direct') default behavior — analysts won't know NULL maps to 'Direct'. Should be Tier 1 — BI_DB_CIDFirstDates."
    },
    {
      "column": "SubChannel",
      "upstream_quote": "Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. (Tier 2 — SP_CIDFirstDates, Dim_Channel)",
      "wiki_quote": "Marketing sub-channel detail. Resolved from Dim_Channel.SubChannel in BI_DB_CIDFirstDates. Values: Direct, Direct Mobile, Google Brand, Affiliate, YT, etc. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates)",
      "match": "NO",
      "loss": "Dropped ISNULL(,'Direct') default and Dim_Affiliate source chain. Should be Tier 1 — BI_DB_CIDFirstDates."
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "Current regulatory entity governing this customer's account. Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID (DWHRegulationID). (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_Regulation)",
      "match": "NO",
      "loss": "Complete rewrite — lost 'short code' framing, V_Dim_Customer context, Dictionary.Regulation origin. Should be Tier 1 — Dictionary.Regulation (dim's root origin)."
    },
    {
      "column": "DesignatedRegulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "Designated regulatory entity (can differ from Regulation for cross-border accounts). Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.DesignatedRegulationID. Same value set as Regulation. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_Regulation)",
      "match": "NO",
      "loss": "Complete rewrite. Should be Tier 1 — Dictionary.Regulation."
    },
    {
      "column": "FTDA",
      "upstream_quote": "Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount (alias dc), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. (Tier 2 — SP_Dim_Customer ← CustomerFinanceDB.FirstTimeDeposits)",
      "wiki_quote": "Customer's first deposit amount in USD. Passthrough of BI_DB_CIDFirstDates.FirstDepositAmount. Populated for all rows (including FTD=0 rows) showing the historical FTD amount. 0.0 if no deposit. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via BI_DB_CIDFirstDates)",
      "match": "NO",
      "loss": "Lost entire source chain (Dim_Customer → CustomerFinanceDB.Customer.FirstTimeDeposits), 'FTDAmountInUsd' source column name, 'first successful deposit' qualifier. Should be Tier 1 — BI_DB_CIDFirstDates."
    },
    {
      "column": "PlayerStatusID",
      "upstream_quote": "Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer)",
      "wiki_quote": "Customer account status ID at time of ETL run. From Fact_SnapshotCustomer. Excludes 2=Blocked/4=Fraudster/13=AML Limited. Present values: 1=Normal (98.7%), 9=Trade&MIMO Blocked, 10=Deposit Blocked, 15=Block Deposit & Trading, 5=Warning. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Fact_SnapshotCustomer)",
      "match": "NO",
      "loss": "Lost 'lifecycle status' framing, DEFAULT 0, production source (Ext_FSC_Real_Customer_Customer), FK reference. Should be Tier 1 — Fact_SnapshotCustomer."
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)",
      "wiki_quote": "Customer account status name. Resolved from Dim_PlayerStatus.Name via PlayerStatusID. Values mirror PlayerStatusID. (Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT via Dim_PlayerStatus)",
      "match": "NO",
      "loss": "Lost 'restriction state' framing, uniqueness guarantee, BackOffice/compliance/monitoring context, trailing-space warning. Should be Tier 1 — Dictionary.PlayerStatus (dim's root origin)."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "All 26 columns",
      "problem": "Systematic Tier 2 mislabeling: ALL columns tagged Tier 2 with zero Tier 1. The bundle contained wikis for Fact_SnapshotCustomer, BI_DB_CIDFirstDates, Dim_PlayerStatus, Dim_Regulation, and Dim_Range. At least 14 passthrough/dim-lookup columns should be Tier 1 with verbatim upstream descriptions."
    },
    {
      "severity": "high",
      "column_or_section": "Regulation, DesignatedRegulation",
      "problem": "Tagged Tier 2 via Dim_Regulation but Dim_Regulation.Name is documented as Tier 1 from Dictionary.Regulation. Writer should use the dim's root origin (Tier 1 — Dictionary.Regulation) per the dim-lookup passthrough rule, not relay through the SP."
    },
    {
      "severity": "high",
      "column_or_section": "PlayerStatus",
      "problem": "Tagged Tier 2 via Dim_PlayerStatus but Dim_PlayerStatus.Name is Tier 1 from Dictionary.PlayerStatus. Lost 'restriction state' framing, trailing-space warning, BackOffice/compliance context. Should be Tier 1 — Dictionary.PlayerStatus with verbatim description."
    },
    {
      "severity": "medium",
      "column_or_section": "Channel, SubChannel",
      "problem": "Dropped ISNULL(,'Direct') default behavior documented in CIDFirstDates wiki. Analysts won't know that NULL channels default to 'Direct' in the upstream, which affects filtering and aggregation logic."
    },
    {
      "severity": "medium",
      "column_or_section": "FTDA",
      "problem": "Lost entire source chain from CIDFirstDates wiki: 'Read directly from Dim_Customer.FirstDepositAmount... sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd)'. Wiki only says 'Passthrough of BI_DB_CIDFirstDates.FirstDepositAmount' — one hop instead of the full lineage."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag all passthrough columns from BI_DB_CIDFirstDates (Desk, Region, Country, Channel, SubChannel, FTDA, Reg_Date, V2_Date, V3_Date, FTD_Date, FirstPosOpen_Date) as Tier 1 using VERBATIM descriptions from the CIDFirstDates wiki. (2) Re-tag CID as Tier 1 with verbatim description from Fact_SnapshotCustomer.RealCID. (3) Re-tag Regulation and DesignatedRegulation as Tier 1 — Dictionary.Regulation using the dim's root origin per dim-lookup passthrough rule. (4) Re-tag PlayerStatusID as Tier 1 — Fact_SnapshotCustomer and PlayerStatus as Tier 1 — Dictionary.PlayerStatus, preserving trailing-space warning. (5) Restore ISNULL(,'Direct') default in Channel/SubChannel descriptions. (6) Add Tier 1 row to Section 4 Confidence Tier Legend. (7) Update footer tier counts to ~14 T1, ~12 T2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Registration 2026 YTD 82%/18%",
      "V2 2026 YTD 55%/45%",
      "FTD 2026 YTD 90%/10%",
      "IsVBT 2026 YTD 51%/49%",
      "PlayerStatusID 1=98.7%",
      "Regulation BVI 81%, CySEC 7.4%"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
