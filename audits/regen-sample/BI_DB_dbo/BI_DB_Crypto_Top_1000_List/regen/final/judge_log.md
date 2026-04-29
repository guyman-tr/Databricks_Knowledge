## Human-Readable Summary

### Per-Dimension Scores

| Dimension | Score | One-line justification |
|-----------|-------|----------------------|
| Tier Accuracy (25%) | **8** | 0/5 random-sample mismatches; −2 for CID paraphrase (tagged `Customer.CustomerStatic` but description sourced from MonthlyPanel relay, dropping root-level context) |
| Upstream Fidelity (20%) | **7** | 1 NO (ACC_Revenue — upstream element truncated in bundle, description reconstructed); all other T1 columns YES or MINOR (verbatim + additive context) |
| Completeness (20%) | **10** | All 10 checklist items pass; 16-element count matches DDL; footer with tiers; all 8 sections present; value enumerations present for Club and Region |
| Business Meaning (15%) | **9** | Section 1 is specific and actionable: exact row grain (1,000 CIDs), ETL SP, TRUNCATE+INSERT, date windows, equity range. Minor: SP comment "$100 vs $1,000" ambiguity could be called out more forcefully in Section 1 rather than relegated to review-needed only |
| Data Evidence (10%) | **8** | P2+P3 not listed as skipped; row count exact (1,000); Club/Region distributions; equity range; 19 uncontacted CIDs; ACC_Revenue_Crypto range — all specific |
| Shape Fidelity (10%) | **10** | Perfect structure: numbered sections, tier legend, lineage tables, ASCII ETL diagram, SQL samples, footer with quality/phases/tier counts |

**Weighted score: 0.25×8 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×10 = 8.55 → PASS**

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| CID | `"Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID."` (BI_DB_CIDFirstDates #1, root: Customer.CustomerStatic) | `"Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID."` | MINOR | Tagged `Customer.CustomerStatic` but description is MonthlyPanel's relay description; drops "Assigned at registration", "Unique within etoro DB", "Used as the universal customer identifier across all tables" |
| GCID | `"Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction."` | `"Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction."` | YES | None |
| Region | `"Marketing region label (newer vintage than Region). Values: ROW, UK, CEE, Nordics, Latam, SEA, Australia, etc."` (MonthlyPanel.NewMarketingRegion #168) | `"Marketing region label (newer vintage than Region). Values observed: UK=293, German=182, Arabic=127, French=64, CEE=62, SEA=56, Spain=44, Italian=41, Nordics=36, Australia=33, USA=24, Latam=23, ROW=15. Renamed from NewMarketingRegion in BI_DB_CID_MonthlyPanel_FullData."` | MINOR | Core meaning preserved; added count distribution and rename note |
| AccountManager | `"Name of the assigned account manager at ETL run time."` (MonthlyPanel #110) | `"Name of the assigned account manager at ETL run time."` | YES | None |
| Club | `"Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID."` (CIDFirstDates #5) | `"Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. Observed: Diamond=401, Platinum Plus=313, Platinum=95, Bronze=88, Gold=73, Silver=30."` | YES | Added observed distribution; root meaning preserved |
| LastLoggedIn | `"Date of the customer's last login before end of this month."` (MonthlyPanel #22) | `"Date of the customer's last login before end of this month."` | YES | None |
| LastDepositDate | `"Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits."` (CIDFirstDates #49) | `"Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. CAST from datetime to DATE."` | YES | Added transform note; accurate |
| LastPosOpenDate | `"Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2)."` (CIDFirstDates #54) | `"Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). CAST from datetime to DATE."` | YES | Added transform note; accurate |
| Equity | `"Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance."` (MonthlyPanel.EOM_Equity #27) | `"Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. Renamed from EOM_Equity. Range observed: -$1,954 to $6,472,324 (mean ~$141K)."` | YES | Added rename note and live data range |
| ACC_Revenue | *Upstream element unavailable — MonthlyPanel wiki truncated before ACC_Revenue_Total element row in bundle* | `"Running lifetime accumulated revenue total (legacy formula: FullCommissions across all asset classes, excluding function fees). Renamed from ACC_Revenue_Total in BI_DB_CID_MonthlyPanel_FullData. Retained for historical comparability; use ACC_Revenue_Total_New in MonthlyPanel for current analysis."` | NO | Upstream element not in bundle; description reconstructed from Business Logic section 2.4 of MonthlyPanel wiki. Documented in review-needed item #3 |

---

### Top 5 Issues

1. **[medium] CID** — Tagged `(Tier 1 — Customer.CustomerStatic)` but description was sourced verbatim from `BI_DB_CID_MonthlyPanel_FullData.CID` (the relay), not from the Customer.CustomerStatic root. The root-level context — "Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." — was dropped and replaced with MonthlyPanel-local additions ("Identifies the depositor. HASH distribution key."). The tag and the description are inconsistent: if the tier origin is Customer.CustomerStatic, the description must carry Customer.CustomerStatic's text.

2. **[medium] ACC_Revenue** — The MonthlyPanel upstream wiki was truncated in the bundle before the ACC_Revenue_Total element definition. The writer reconstructed the description from MonthlyPanel's Business Logic section 2.4 and correctly flagged this in review-needed item #3. The reconstructed description is plausible but has not been verified against the full upstream element row. A reviewer must open `BI_DB_CID_MonthlyPanel_FullData.md` directly and compare the actual ACC_Revenue_Total element definition.

3. **[medium] SP comment "$100 vs $1,000" discrepancy (Section 8 / Section 1)** — The SP author comment states `"less than 100$ revenue since 20230801"` but the HAVING clause uses `< 1000`. The wiki correctly uses $1,000 throughout, which matches the code. However, review-needed item #5 asks a reviewer to "confirm whether the cohort threshold was $100 or $1,000", yet Section 1 states it as settled fact ("between $0 and $1,000"). If the threshold is genuinely uncertain, Section 1 should hedge; if it is confirmed, review-needed item #5 should be resolved and closed.

4. **[low] Equity relay origin** — `Equity` is tagged `(Tier 1 — BI_DB_CID_MonthlyPanel_FullData.EOM_Equity)`, which is a relay column. MonthlyPanel's EOM_Equity is itself `(Tier 2 — DWH_dbo.V_Liabilities)`. The root origin is `DWH_dbo.V_Liabilities`. This is unavoidable because the V_Liabilities wiki is not in the bundle, so MonthlyPanel is the deepest available anchor. The relay citation is acceptable but the reader does not know whether V_Liabilities data is end-of-month, real-time, or snapshot-based — information that MonthlyPanel's description provides but only partially (it says "from V_Liabilities" without further detail).

5. **[low] LastContacted uses `CreatedDate` (dedup-MIN), not `CreatedDate_SF`** — The SP aggregates `MAX(CAST(bduts.CreatedDate AS DATE))` where `CreatedDate` is the group-deduplication MIN timestamp (may differ from the Salesforce-native `CreatedDate_SF`). The wiki element description correctly states `MAX(CAST(CreatedDate AS DATE))`, which matches the SP. However, the distinction between `CreatedDate` and `CreatedDate_SF` is not called out for the analyst, who might assume this is the Salesforce-native event timestamp. The BI_DB_UsageTracking_SF wiki notes that the two columns can differ. A brief note in the Gotchas section would close this gap.

---

### Regeneration Feedback (numbered)

1. For **CID**: Either change the tier tag to `(Tier 1 — BI_DB_CID_MonthlyPanel_FullData)` (reflecting the actual relay used) or replace the description with the full root-level text from `Customer.CustomerStatic` via the Dim_Customer wiki: "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." The current tag/description mismatch is the core problem.
2. For **ACC_Revenue**: Open `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CID_MonthlyPanel_FullData.md` directly, locate the ACC_Revenue_Total element row, and replace the reconstructed description with a verbatim quote. Then close review-needed item #3.
3. For the **"$100 vs $1,000" discrepancy**: Resolve review-needed item #5 before the wiki is considered final. If the threshold is confirmed as $1,000 (as the code clearly shows), update Section 8 Atlassian note to record the discrepancy as a known SP comment typo and remove the ambiguity flag from review-needed.
4. For **LastContacted**: Add a single sentence to Section 3.4 Gotchas: "LastContacted uses `BI_DB_UsageTracking_SF.CreatedDate` (the group-deduplication MIN timestamp), not `CreatedDate_SF` (the Salesforce-native event timestamp); the two may differ for deduped event groups."

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Crypto_Top_1000_List",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 10
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -- Customer.CustomerStatic) [BI_DB_CIDFirstDates #1, root: Customer.CustomerStatic]",
      "wiki_quote": "Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID.",
      "match": "MINOR",
      "loss": "Tagged Customer.CustomerStatic but description sourced from MonthlyPanel relay; drops 'Assigned at registration', 'Unique within etoro DB', 'Used as the universal customer identifier across all tables'"
    },
    {
      "column": "GCID",
      "upstream_quote": "Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -- Customer.CustomerStatic)",
      "wiki_quote": "Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Region",
      "upstream_quote": "Marketing region label (newer vintage than Region). Values: ROW, UK, CEE, Nordics, Latam, SEA, Australia, etc. (Tier 2 — Fact_SnapshotCustomer / Dim_Customer) [MonthlyPanel.NewMarketingRegion #168]",
      "wiki_quote": "Marketing region label (newer vintage than Region). Values observed: UK=293, German=182, Arabic=127, French=64, CEE=62, SEA=56, Spain=44, Italian=41, Nordics=36, Australia=33, USA=24, Latam=23, ROW=15. Renamed from NewMarketingRegion in BI_DB_CID_MonthlyPanel_FullData.",
      "match": "MINOR",
      "loss": "Added count distribution and rename note; core meaning fully preserved"
    },
    {
      "column": "AccountManager",
      "upstream_quote": "Name of the assigned account manager at ETL run time. (Tier 1 — DWH_dbo.Dim_Customer wiki) [MonthlyPanel #110]",
      "wiki_quote": "Name of the assigned account manager at ETL run time.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -- Dictionary.PlayerLevel) [CIDFirstDates #5]",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. Observed: Diamond=401, Platinum Plus=313, Platinum=95, Bronze=88, Gold=73, Silver=30.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "LastLoggedIn",
      "upstream_quote": "Date of the customer's last login before end of this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) [MonthlyPanel #22]",
      "wiki_quote": "Date of the customer's last login before end of this month.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "LastDepositDate",
      "upstream_quote": "Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. (Tier 2 -- SP_CIDFirstDates) [CIDFirstDates #49]",
      "wiki_quote": "Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. CAST from datetime to DATE.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "LastPosOpenDate",
      "upstream_quote": "Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) [CIDFirstDates #54]",
      "wiki_quote": "Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). CAST from datetime to DATE.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Equity",
      "upstream_quote": "Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. (Tier 2 — DWH_dbo.V_Liabilities) [MonthlyPanel.EOM_Equity #27]",
      "wiki_quote": "Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. Renamed from EOM_Equity. Range observed: -$1,954 to $6,472,324 (mean ~$141K).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ACC_Revenue",
      "upstream_quote": "[UNAVAILABLE — MonthlyPanel wiki truncated before ACC_Revenue_Total element row in bundle]",
      "wiki_quote": "Running lifetime accumulated revenue total (legacy formula: FullCommissions across all asset classes, excluding function fees). Renamed from ACC_Revenue_Total in BI_DB_CID_MonthlyPanel_FullData. Retained for historical comparability; use ACC_Revenue_Total_New in MonthlyPanel for current analysis.",
      "match": "NO",
      "loss": "Upstream element unavailable due to bundle truncation; description reconstructed from Business Logic section 2.4. Cannot confirm verbatim accuracy. Documented in review-needed item #3."
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "CID",
      "problem": "Tier tag says (Tier 1 — Customer.CustomerStatic) but description was sourced from BI_DB_CID_MonthlyPanel_FullData.CID (the relay). The root-source context — 'Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.' — was dropped and replaced with MonthlyPanel-local additions. Tag and description are inconsistent."
    },
    {
      "severity": "medium",
      "column_or_section": "ACC_Revenue",
      "problem": "MonthlyPanel upstream wiki truncated before ACC_Revenue_Total element. Description reconstructed from Business Logic section 2.4. Cannot be verified as verbatim. Reviewer must open BI_DB_CID_MonthlyPanel_FullData.md directly to check the actual element definition and resolve review-needed item #3."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1 / Section 8",
      "problem": "SP author comment says 'less than 100$ revenue since 20230801' but HAVING clause uses < 1000 (i.e., $1,000). Wiki uses $1,000 throughout (matching code), which is correct. However review-needed item #5 still treats this as unresolved ambiguity while Section 1 presents it as fact. These need to be reconciled: either confirm $1,000 and close review-needed, or hedge Section 1 language."
    },
    {
      "severity": "low",
      "column_or_section": "Equity",
      "problem": "Tagged (Tier 1 — BI_DB_CID_MonthlyPanel_FullData.EOM_Equity) which is a relay column. MonthlyPanel.EOM_Equity is itself (Tier 2 — DWH_dbo.V_Liabilities). Root origin is V_Liabilities. Acceptable given V_Liabilities wiki is absent from bundle, but reader cannot determine whether equity is real-time, snapshot, or end-of-month from this citation alone."
    },
    {
      "severity": "low",
      "column_or_section": "LastContacted",
      "problem": "SP aggregates MAX(CAST(bduts.CreatedDate AS DATE)) where CreatedDate is the group-dedup MIN timestamp, not CreatedDate_SF (Salesforce-native event timestamp). The wiki correctly states CreatedDate, but the Gotchas section does not warn analysts that this value may differ from what they would expect from a direct Salesforce export."
    }
  ],
  "regeneration_feedback": "Wiki PASSes at 8.55. For the next iteration: (1) CID — either retag as (Tier 1 — BI_DB_CID_MonthlyPanel_FullData) or replace description with the full Customer.CustomerStatic root text: 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.' (2) ACC_Revenue — open BI_DB_CID_MonthlyPanel_FullData.md directly, find the ACC_Revenue_Total element row, quote verbatim, then close review-needed item #3. (3) Resolve the '$100 vs $1,000' discrepancy: if confirmed as $1,000 (code is clear), update Section 8 to note the SP comment typo and close review-needed item #5; do not leave Section 1 and review-needed contradicting each other. (4) Add a Gotcha: 'LastContacted uses BI_DB_UsageTracking_SF.CreatedDate (dedup-MIN timestamp), not CreatedDate_SF; the two may differ for deduped event groups.'",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Region value counts: UK=293, German=182, Arabic=127, French=64, CEE=62, SEA=56, Spain=44, Italian=41, Nordics=36, Australia=33, USA=24, Latam=23, ROW=15",
      "Club distribution: Diamond=401, Platinum Plus=313, Platinum=95, Bronze=88, Gold=73, Silver=30",
      "Equity range: -$1,954 to $6,472,324 (mean ~$141K)",
      "ACC_Revenue_Crypto range: $27,128–$1,787,784",
      "LastContacted NULL: 19 of 1,000 CIDs"
    ],
    "skipped_phases": ["P7 (Views N/A)", "P10 (Jira skipped — regen harness)"]
  }
}
</JUDGE_VERDICT>
