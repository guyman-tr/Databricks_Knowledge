---
id: aml-risk-scoring
name: "AML Risk Scoring"
description: "Production AML risk classification + scoring pipeline. UC-native, anchored on the bi_compliance_stg cmp_aml_risk_classification_* family (4 grain tables — cid_level 84c per CID per snapshot, cid_window_level 77c per CID per rolling-window, aggregated_level 72c segment-rolled, aggregated_group_level 71c group-rolled) which produces Dynamic_Risk_Classification ('High'/'Medium'/'Low'/NULL) plus 50+ pre-computed alert-trigger boolean columns (Is_High_Risk, Is_PEP, Is_Sanctions_Match, High_Risk_AND_No_POI, PEP_No_POA, PEP_No_POI_AND_No_POA, eMoney_High_Risk_AND_No_POI, HighRiskCountryDeposits, BronzeMultipleAccountsFunding, ThirdPartyDeposit, NoLoginsNoEquityOpenPosition, AllFundedDormantClients, V2AnomalyFlag, IsRejected, NoPOAUploaded, NoPOIUploaded, Null_Risk_Score_8_Days_After_First_Deposit, etc.). Joined upstream to the bronze input ring (bronze_userapidb_history_customeranswers 10c, bronze_userapidb_customer_extendeduserfield_masked 8c, bronze_riskclassification_dbo_v_riskclassificationdatalake 100c, bronze_riskclassification_dictionary_cysecriskclassificationparameter 6c + riskclassification_cysecriskclassificationparameter 8c, bronze_etoro_riskcalculation_scorestemporary 10c, bronze_etoro_dictionary_riskclassification 3c) and downstream to the destination layer (de_output_risk_classification 97c + _cysec 97c + _history 96c + _history_cysec 96c + vw_risk_classification_history_complete 96c + de_output_risk_calculations_cysec_users_scores 8c — the UC analog of the HLD's RiskCalculation.CySecScoresTemporary post-rename). Regulator-specific variants: bi_db_aml_singapore_risk_classification 45c (MAS, Final_Score + Risk_Score per CID), bi_db_aml_subentity_categorization 9c (legal-entity-of-the-day). PII analyst entry point: pii_data.aml_snapshotcustomer_enriched_v 54c. Canonical join key: GCID + CID + etr_ymd. Snapshot partition is etr_ymd (YYYY-MM-DD string). Default to cmp_aml_risk_classification_cid_level for any 'AML risk per CID' question. Do NOT load for KYC sanctions/PEP identity-side screening (covered in B compliance-customer-snapshot-and-club planned v1.5)."
triggers:
  - cmp_aml
  - cmp_aml_risk_classification
  - cmp_aml_risk_classification_cid_level
  - cmp_aml_risk_classification_cid_window_level
  - cmp_aml_risk_classification_aggregated_level
  - cmp_aml_risk_classification_aggregated_group_level
  - de_output_risk_classification
  - de_output_risk_classification_history
  - de_output_risk_classification_cysec
  - vw_risk_classification_history_complete
  - cysec_users_scores
  - RiskCalculation.CySecScoresTemporary
  - Dynamic_Risk_Classification
  - Is_High_Risk
  - Is_Medium_Risk
  - Is_Low_Risk
  - Is_Null_Risk
  - Is_PEP
  - Is_Sanctions_Match
  - High_Risk_AND_No_POI
  - High_Risk_AND_No_POA
  - High_Risk_No_POI_AND_No_POA
  - PEP_No_POI
  - PEP_No_POA
  - PEP_No_POI_AND_No_POA
  - PEPNoPOIncome
  - HighRiskNoPOIncome
  - eMoney_ClientRisk
  - eMoney_High_Risk_AND_No_POI
  - eMoney_High_Risk_AND_No_POA
  - Is_eMoneyClientRisk_High
  - Is_Platinum_High_Risk
  - Is_Diamond_High_Risk
  - HighRiskCountryDeposits
  - HighRiskRegulationChange
  - ThirdPartyDeposit
  - MultipleAccounts
  - BronzeMultipleAccountsFunding
  - SilverAndAboveMultipleAccountsFunding
  - AllFundedDormantClients
  - NoLoginsUnder100Equity
  - NoLoginsOver100Equity
  - V2AnomalyFlag
  - InvalidBINDeposits
  - aml_singapore_risk_classification
  - Singapore MAS risk
  - Final_Score
  - Risk_Score
  - aml_subentity_categorization
  - aml_snapshotcustomer_enriched_v
  - Country_RiskGroupID
  - VerificationLevelID
  - ScreeningStatus
  - PlayerStatus
  - Regulation
  - MifidCategorization
  - POA_Expiry_Date
  - POI_Expiry_Date
  - SetRiskClassificationNew
  - SetRiskClassificationForCySec
  - P_RiskClassification
required_tables:
  - main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level
  - main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_window_level
  - main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_aggregated_level
  - main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_aggregated_group_level
  - main.de_output.de_output_risk_classification
  - main.de_output.de_output_risk_classification_cysec
  - main.de_output.de_output_risk_classification_history
  - main.de_output.de_output_risk_classification_history_cysec
  - main.de_output.vw_risk_classification_history_complete
  - main.de_output.de_output_risk_classification_scores
  - main.de_output_stg.de_output_risk_calculations_cysec_users_scores
  - main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter
  - main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter
  - main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake
  - main.bi_db.bronze_etoro_riskcalculation_scorestemporary
  - main.compliance.bronze_userapidb_history_customeranswers
  - main.compliance.bronze_userapidb_customer_extendeduserfield_masked
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification
  - main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization
  - main.pii_data.aml_snapshotcustomer_enriched_v
  - main.general.bronze_etoro_dictionary_riskclassification
external_references:
  - name: "BackOffice.SetRiskClassificationNew"
    locality: manual_only
    source_system: sql_dp_prod_we (etoro DB)
    role: "Master stored proc that sets the risk classification on a customer event. The IN-DATABASE logic that determines Dynamic_Risk_Classification."
    bridge_strategy: "Read the SP body in Synapse via the etoro DB; documented in knowledge/synapse/Wiki path. Not a queryable data table."
  - name: "RiskCalculation.SetRiskClassificationForCySec"
    locality: manual_only
    source_system: sql_dp_prod_we (RiskCalculation DB)
    role: "CySEC-specific risk classification recompute orchestrator. Reads the CySEC scoring parameters from RiskClassification.CySecRiskClassificationParameter and writes to RiskCalculation.CySecScoresTemporary (which is now main.de_output_stg.de_output_risk_calculations_cysec_users_scores in UC post-rename)."
    bridge_strategy: "Read the SP body in Synapse via the RiskCalculation DB; not a queryable data table."
  - name: "dbo.P_RiskClassification"
    locality: manual_only
    source_system: sql_dp_prod_we (RiskClassification DB)
    role: "Top-level orchestration SP — sequences SetRiskClassificationNew, SetRiskClassificationForCySec, dictionary refresh."
    bridge_strategy: "Read the SP body in Synapse via the RiskClassification DB; not a queryable data table."
  - name: "RiskClassification.CySecRiskClassificationParameterView"
    locality: hybrid_synapse_uc
    source_system: sql_dp_prod_we (RiskClassification DB)
    role: "Synapse-side projection view over the cysec parameter table. The HLD doc 11655577818 references this VIEW; UC has the underlying TABLE (main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter, 8c) but the view's specific projection was never re-materialized in UC."
    bridge_strategy: "For the table data, use the UC bronze. For the view's specific projection (additional column derivations), query Synapse via user-synapse_prod_sql MCP. Most analyst questions are answered by the bronze table alone."
sample_questions:
  - "How many High_Risk customers do we have today (cross-regulation)?"
  - "PEP customers without POA upload (PEP_No_POA = 1)"
  - "CySEC risk classification distribution for active customers on date D"
  - "Singapore MAS Risk_Score breakdown for active customers"
  - "Time-series of Dynamic_Risk_Classification changes for customer X"
  - "Customers who triggered HighRiskCountryDeposits in the last 30 days"
  - "Multi-account funding alerts — BronzeMultipleAccountsFunding vs SilverAndAboveMultipleAccountsFunding"
  - "Dormant funded clients still classified High_Risk (AllFundedDormantClients = 1 AND Is_High_Risk = 1)"
  - "PEP customers in eMoney sub-vertical (Is_PEP = 1 AND Is_eMoneyClientRisk_High = 1)"
  - "Customers in the Null_Risk_Score_8_Days_After_First_Deposit cohort (data-quality alert)"
  - "Country_RiskGroupID = 3 (highest risk) customer count over time"
domain_tags:
  - compliance
  - aml
  - risk-classification
  - risk-scoring
  - cmp-aml
  - de-output
  - cysec
  - singapore-mas
  - pep
  - sanctions
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-24"
---

# AML Risk Scoring

The UC-native production AML risk classification and scoring pipeline. Computes a customer's AML risk verdict (`Dynamic_Risk_Classification`) plus 50+ pre-computed alert-trigger booleans on a daily snapshot grain, with regulator-specific variants (CySEC, Singapore MAS).

## When to Use

Load when the question concerns AML risk **classification** or **scoring**, including:

- "How many customers are High vs Medium vs Low risk today?"
- "PEP customers without POI upload (`PEP_No_POI = 1`)"
- "Customers triggering `HighRiskCountryDeposits` / `BronzeMultipleAccountsFunding` / `V2AnomalyFlag`"
- "Time-series of `Dynamic_Risk_Classification` per CID"
- "CySEC-regulated customers' risk classification — current and historical"
- "Singapore MAS `Final_Score` and `Risk_Score` per CID"
- "What is the score formula? — pull the bronze dictionary + the dictionary parameter table"
- "Where does `Dynamic_Risk_Classification = High` come from in the column-level evidence?" (e.g. which of the 50+ boolean triggers fired)
- "Sub-entity categorization — which legal entity is the CID booked under today?"

Load also for questions about the HLD-named tables `RiskCalculation.CySecScoresTemporary` and `RiskClassification.CySecRiskClassificationParameterView` — this skill teaches the UC post-rename mapping (see Critical Warning 1).

Do **NOT** load for:

- **Live alerts that fired** (`BI_DB_AML_BI_Alerts_New` row-level) → [`aml-alert-routing.md`](aml-alert-routing.md)
- **Periodic-review queue** → [`aml-alert-routing.md`](aml-alert-routing.md) (the `bi_db_amlperiodicreview` table is the bridge between the two skills)
- **RegTech parallel pipeline keyed on PartyKey** → [`aml-regtech-pipeline.md`](aml-regtech-pipeline.md)
- **Identity-side KYC sanctions / PEP screening decision** → `B compliance-customer-snapshot-and-club` (planned v1.5)
- **FCA SAR submission** (`bi_db_aml_sar_report_fca`) → future spec 013-regulatory-reporting

## Scope

In scope: cmp_aml_risk_classification_* (4 grain tables — cid_level 84c, cid_window_level 77c, aggregated_level 72c, aggregated_group_level 71c); de_output risk_classification (de_output_risk_classification 97c, _cysec 97c, _history 96c, _history_cysec 96c, vw_risk_classification_history_complete 96c, de_output_risk_classification_scores 9c, de_output_risk_calculations_cysec_users_scores 8c — the UC post-rename of HLD's RiskCalculation.CySecScoresTemporary); bronze inputs (bronze_riskclassification_dbo_v_riskclassificationdatalake 100c, bronze_riskclassification_dictionary_cysecriskclassificationparameter 6c, bronze_riskclassification_riskclassification_cysecriskclassificationparameter 8c, bronze_etoro_riskcalculation_scorestemporary 10c, bronze_userapidb_history_customeranswers 10c, bronze_userapidb_customer_extendeduserfield_masked 8c, bronze_etoro_dictionary_riskclassification 3c); regulator-specific (bi_db_aml_singapore_risk_classification 45c MAS, bi_db_aml_subentity_categorization 9c legal-entity); PII analyst view (aml_snapshotcustomer_enriched_v 54c — production + staging variants); stored procs that drive the classification (BackOffice.SetRiskClassificationNew, RiskCalculation.SetRiskClassificationForCySec, dbo.P_RiskClassification — all manual_only in external_references).
Out of scope: live alert tables BI_DB_AML_BI_Alerts_New / BI_DB_AML_Daily_Alerts / BI_DB_RiskAlertManagementTool (aml-alert-routing.md), the periodic-review queue bi_db_amlperiodicreview (aml-alert-routing.md), RegTech tables regtech.gold_regtech_aml_* / gold_regreportdb_prod_dbo_aml_* (aml-regtech-pipeline.md), identity-side screening (B compliance-customer-snapshot-and-club), FCA SAR (future spec 013), Tribe audit envelopes (domain-cross/tribe-emoney-audit).
Last verified: 2026-05-24

## Critical Warnings

1. **Tier 1 — HLD rename mapping. Use UC names, NOT the Confluence HLD names.** The HLD doc `11655577818` (Confluence "CR Compliance Dev" space) describes a Synapse-side flow that names two artifacts that DO NOT exist in UC under those names. Use the mapping below:

    | HLD-side (Synapse, stale) | UC-side (canonical) |
    |---|---|
    | `RiskCalculation.CySecScoresTemporary` | `main.de_output_stg.de_output_risk_calculations_cysec_users_scores` (8c) |
    | `RiskClassification.CySecRiskClassificationParameterView` | (NO VIEW IN UC) — use the bronze table `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` (8c) and project the view's columns yourself if needed |

    When the agent sees the HLD's Synapse names, MAP them to the UC names above. The HLD has not been updated to reflect the post-migration UC reality.

2. **Tier 1 — `Dynamic_Risk_Classification` is the canonical analyst column, NOT `RiskClassificationID`.** On `cmp_aml_risk_classification_cid_level` (84c), `Dynamic_Risk_Classification` is the human-readable risk verdict (`High` / `Medium` / `Low` / NULL). The four derivative booleans `Is_High_Risk`, `Is_Medium_Risk`, `Is_Low_Risk`, `Is_Null_Risk` are mutually exclusive expansions. The legacy numeric `RiskClassificationID` exists on bronze (`bronze_etoro_dictionary_riskclassification.RiskClassificationID`) and on `regtech_aml_population.RiskClassificationID` (the RegTech side) — but for THIS skill's analyst queries, ALWAYS prefer `Dynamic_Risk_Classification`. Filtering on `RiskClassificationID = 3` is brittle; filtering on `Dynamic_Risk_Classification = 'High'` is the canonical form.

3. **Tier 1 — `etr_ymd` is the snapshot partition, NOT `ReportRunDate`.** All four cmp_aml grain tables and all six de_output_risk_classification* tables carry `etr_ymd` (string `'YYYY-MM-DD'`) as the partition column. **Always filter with `WHERE etr_ymd = '...'` or `BETWEEN '...' AND '...'`** for partition pruning. `ReportRunDate` is a `DATETIME` informational column. The same applies to `ReportMonthText` (display) and `etr_ym` / `etr_y` (coarser partitions).

4. **Tier 1 — Snapshot frequency varies by grain — read `snapshot_frequency` before time-series.** The `cid_level` table has a `snapshot_frequency` column distinguishing daily snapshots from window snapshots. Don't assume one row per CID per day; the `cid_window_level` (77c) has rolling-window snapshots at non-daily cadence. For time-series of classification changes, use `de_output.de_output_risk_classification_history` (96c) or `vw_risk_classification_history_complete` (96c) which carry the dedicated history grain.

5. **Tier 1 — `Is_PEP` and `Is_Sanctions_Match` are downstream FLAGS — the screening DECISION lives upstream.** The columns `Is_PEP`, `Is_Sanctions_Match`, `ScreeningStatus`, `eMoney_ClientRisk` on `cmp_aml_risk_classification_cid_level` are PRE-COMPUTED by the upstream screening provider (ComplyAdvantage for PEP/sanctions/adverse media; Actimize for CDD). For "is customer X currently on a sanctions list" use these flags. For "WHO ran the sanctions check and WHEN" — the identity-side decision lives in `B compliance-customer-snapshot-and-club` (planned v1.5) or directly in ComplyAdvantage UI. The alert-trigger booleans here (`PEP_No_POI`, `PEP_No_POA`, `PEP_No_POI_AND_No_POA`, `PEP_No_POI_No_POA_No_POIncome`) combine the screening flag with KYC document state.

6. **Tier 1 — The 50+ alert-trigger booleans on `cid_level` are the column-level evidence of WHICH alerts fire downstream.** Examples: `High_Risk_AND_No_POI` (1 = High + missing Proof-of-Identity → upstream SP inserts an alert into `BI_DB_AML_BI_Alerts_New`), `HighRiskCountryDeposits` (deposit from FATF high-risk country), `BronzeMultipleAccountsFunding` (Bronze-club customer funding from multiple accounts), `V2AnomalyFlag` (catch-all model anomaly), `Null_Risk_Score_8_Days_After_First_Deposit` (data-quality alert: classification should have been computed by D+8). When the consumer asks "why is customer X high-risk", inspect the row's TRUE booleans — they ARE the evidence chain.

7. **Tier 2 — Canonical join key is `GCID + CID + etr_ymd`.** The cmp_aml family has both `GCID` and `CID` — `CID` is per-account, `GCID` is the cross-platform customer identifier (multiple `CID`s can map to one `GCID` in linked-account scenarios). For per-account analysis use `CID`; for cross-platform aggregation use `GCID`. Join to `Dim_Customer` is `CID = RealCID` (DWH convention). RegTech (covered separately) uses `PartyKey` — DO NOT join cmp_aml to RegTech on `CID` without going through `regtech_aml_population.CID → regtech_aml_gen_key → PartyKey`.

8. **Tier 2 — `Regulation` column carries the regulator-of-the-day, used in joining to regulator-specific tables.** `Regulation` is a denormalized string (`'CYS'`, `'FCA'`, `'MAS'`, `'ASIC'`, `'AUS'`, etc.). For Singapore MAS-specific scoring, filter `WHERE Regulation = 'MAS'` and join to `bi_db_aml_singapore_risk_classification` (45c). For CySEC-specific historical scoring, use `de_output_risk_classification_history_cysec` (96c). For sub-entity categorization (legal-entity-of-the-day), join `cmp_aml_risk_classification_cid_level.CID = bi_db_aml_subentity_categorization.CID`.

9. **Tier 2 — Bronze inputs have NULLs and stale dictionary values; trust the cmp_aml computed columns over raw bronze answers.** `bronze_userapidb_history_customeranswers` (10c) is the immutable KYC answer history; `bronze_userapidb_customer_extendeduserfield_masked` (8c) carries the masked-PII extended fields. For analyst queries that need the answer itself ("what occupation did customer X declare on date D"), join via `CID + DateID`. For risk classification, the cmp_aml computed columns have ALREADY consumed these bronzes — don't recompute from raw answers, just read the verdict.

10. **Tier 3 — The SP family is the LOGIC, not data. To know HOW a classification is computed, read the SP body in Synapse.** `BackOffice.SetRiskClassificationNew`, `RiskCalculation.SetRiskClassificationForCySec`, `dbo.P_RiskClassification` — all three live in Synapse and are documented in their wiki paths. The cmp_aml table is the OUTPUT of these procs; the formula lives in the proc body. See `external_references` block for the bridge strategy.

11. **Tier 3 — Multiple de_output_stg copies exist for staging; use `de_output.*` (not `de_output_stg.*`) for analyst queries.** The `main.de_output_stg.*` schema carries the staging variants (sometimes partial columns — `_cysec` is 43c in stg vs 97c in prod). For canonical analytics ALWAYS query `main.de_output.*` not `main.de_output_stg.*` (unless explicitly debugging an ETL).

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **Dynamic_Risk_Classification** | The canonical analyst column for current AML risk verdict per CID per snapshot. Values: `'High'` / `'Medium'` / `'Low'` / NULL. Derived: `Is_High_Risk`, `Is_Medium_Risk`, `Is_Low_Risk`, `Is_Null_Risk`. | risk classification, risk class, AML risk |
| **eMoney_ClientRisk** | The eMoney-vertical parallel risk classification (independent column from `Dynamic_Risk_Classification`). Derived: `Is_eMoneyClientRisk_High/Medium/Low/Null`. Cross-club variants: `Is_Platinum_eMoneyClientRisk_High`, `Is_Platinum_Plus_eMoneyClientRisk_High`, `Is_Diamond_eMoneyClientRisk_High`. | eMoney risk, eMoney client risk |
| **Alert-trigger booleans** | 50+ pre-computed boolean columns on `cid_level` that encode WHICH alert pattern is firing. Examples: `High_Risk_AND_No_POI` (high-risk + missing POI), `PEP_No_POA` (PEP + missing POA), `eMoney_High_Risk_AND_No_POI`, `HighRiskCountryDeposits`, `BronzeMultipleAccountsFunding`, `ThirdPartyDeposit`, `V2AnomalyFlag`, `Null_Risk_Score_8_Days_After_First_Deposit`. | alert triggers, alert conditions, risk flags |
| **Is_PEP** | Pre-computed flag from upstream PEP screening (ComplyAdvantage). Does NOT mean "the customer just got matched"; means "the customer is currently PEP-flagged in screening". | PEP flag |
| **Is_Sanctions_Match** | Pre-computed flag from upstream sanctions screening (ComplyAdvantage). Cross-list match (UN, OFAC, EU, UK, etc.). | sanctions, sanctioned |
| **Country_RiskGroupID** | FATF-style country risk grouping (numeric tier — 1 lowest, higher = higher risk). Joins to `bronze_etoro_dictionary_riskclassification` for label. Used in `HighRiskCountryDeposits` derivation. | country risk, FATF group |
| **Regulation** | Denormalized regulator-of-the-day for the CID — values: `'CYS'` (CySEC), `'FCA'` (UK), `'MAS'` (Singapore), `'ASIC'` (Australia), `'AUS'` (variant), etc. Drives the regulator-specific score variant. | regulator, regulation |
| **VerificationLevelID** | KYC verification tier (1 unverified → 3 fully verified). Many alert booleans key off "verification not yet level 3". | verification level, KYC level |
| **ScreeningStatus** | Screening pipeline state. Drives `LastScreeningStatusChange`. | screening state |
| **MifidCategorization** | MIFID-II customer category (Retail / Professional / Eligible Counterparty). Affects risk-scoring weight. | MIFID category |
| **PlayerStatus** | Customer lifecycle state (Active / Closed / Pending Closure / etc.). | account status, lifecycle state |
| **POA / POI** | Proof-of-Address / Proof-of-Identity document state. Columns: `POA`, `POI` (current state), `POA_Expiry_Date`, `POI_Expiry_Date`. Drives many `*_No_POI` / `*_No_POA` alert triggers. | proof-of-address, proof-of-identity, POI/POA docs |
| **Sub-entity** | Legal-entity-of-the-day the CID is booked under (eToro UK Ltd, eToro Europe Ltd, eToro AUS Ltd, etc.). Lives in `bi_db_aml_subentity_categorization` (9c). | legal entity, sub-entity |
| **Singapore Final_Score / Risk_Score** | MAS-specific composite score. `Final_Score` = composite, `Risk_Score` = derived band. Per-feature columns: `*_Final_Score` (Occupation, Sources_of_funds, Nationality, Annual_Income, Liquid_Assets, etc.). | MAS score, Singapore AML score |
| **Snapshot grain** | `etr_ymd` (daily partition) + `ReportRunDate` (timestamp). Multi-grain tables: `cid_level` (per CID per day), `cid_window_level` (per CID per rolling window), `aggregated_level` (segment rollup), `aggregated_group_level` (group rollup). | snapshot, daily snapshot, etr_ymd partition |

## Query Patterns

### Pattern 1 — Current AML risk classification per CID

```sql
SELECT
  CID,
  GCID,
  Dynamic_Risk_Classification,
  Is_PEP,
  Is_Sanctions_Match,
  Regulation,
  Country_RiskGroupID,
  VerificationLevelID,
  ScreeningStatus,
  POI_Expiry_Date,
  POA_Expiry_Date
FROM main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level
WHERE etr_ymd = '2026-05-23'
  AND CID = :cid;
```

Use when: "what is customer X's AML risk classification?", "is customer X PEP / sanctioned right now?", "what's the verification level + risk for CID Y?".

### Pattern 2 — High-Risk customer distribution by regulator (current snapshot)

```sql
SELECT
  Regulation,
  COUNT(*) FILTER (WHERE Is_High_Risk = 1)   AS high_risk,
  COUNT(*) FILTER (WHERE Is_Medium_Risk = 1) AS medium_risk,
  COUNT(*) FILTER (WHERE Is_Low_Risk = 1)    AS low_risk,
  COUNT(*) FILTER (WHERE Is_Null_Risk = 1)   AS null_risk,
  COUNT(*) FILTER (WHERE Is_PEP = 1)         AS pep,
  COUNT(*) FILTER (WHERE Is_Sanctions_Match = 1) AS sanctions
FROM main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level
WHERE etr_ymd = '2026-05-23'
  AND PlayerStatus <> 'Closed'
GROUP BY Regulation
ORDER BY high_risk DESC;
```

Use when: "how many high-risk customers per regulator", "current risk breakdown by regulator".

### Pattern 3 — Alert-trigger evidence: which boolean fired for High_Risk CIDs

```sql
SELECT
  CID,
  Dynamic_Risk_Classification,
  Is_PEP,
  Is_Sanctions_Match,
  High_Risk_AND_No_POI,
  High_Risk_AND_No_POA,
  PEP_No_POI,
  PEP_No_POA,
  HighRiskCountryDeposits,
  BronzeMultipleAccountsFunding,
  V2AnomalyFlag,
  Null_Risk_Score_8_Days_After_First_Deposit
FROM main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level
WHERE etr_ymd = '2026-05-23'
  AND Is_High_Risk = 1
  AND (High_Risk_AND_No_POI = 1
       OR High_Risk_AND_No_POA = 1
       OR HighRiskCountryDeposits = 1
       OR BronzeMultipleAccountsFunding = 1
       OR V2AnomalyFlag = 1);
```

Use when: "why is customer X high-risk", "which alert pattern is firing for High_Risk customers", "what's the column-level evidence chain".

### Pattern 4 — Risk classification time-series for one CID

```sql
SELECT
  etr_ymd,
  ReportRunDate,
  Dynamic_Risk_Classification,
  Is_PEP,
  Is_Sanctions_Match,
  Regulation,
  VerificationLevelID,
  PlayerStatus
FROM main.de_output.vw_risk_classification_history_complete
WHERE CID = :cid
  AND etr_ymd BETWEEN '2025-11-01' AND '2026-05-23'
ORDER BY etr_ymd;
```

Use when: "time-series of risk classification for customer X", "when did customer Y get marked High_Risk", "history of classification changes".

### Pattern 5 — Singapore MAS-specific scoring

```sql
SELECT
  CID,
  Final_Score,
  Risk_Score,
  Occupation_Final_Score,
  Sources_of_funds_Final_Score,
  Nationality_Final_Score,
  Annual_Income_Final_Score,
  Liquid_Assets_Final_Score,
  Net_Deposits_Final_Score,
  Screening_Block_Final
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification
WHERE Report_Date = (SELECT MAX(Report_Date) FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification)
  AND CID = :cid;
```

Use when: "Singapore MAS Final_Score for customer X", "MAS regulator scoring breakdown".

### Pattern 6 — CySEC post-rename mapping

```sql
SELECT
  *
FROM main.de_output_stg.de_output_risk_calculations_cysec_users_scores
WHERE etr_ymd = '2026-05-23'
  AND CID = :cid;
```

Use when: the user (or a Confluence HLD) references `RiskCalculation.CySecScoresTemporary`. This is the UC post-rename. See Critical Warning 1.

## Sources Consulted

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level` | L | 1 | UC `information_schema.columns` (84 cols verified 2026-05-24) | Genie + KPI; production AML core |
| `main.de_output.de_output_risk_classification` | L | 1 | UC `information_schema.columns` (97 cols) | DE-team destination |
| `main.de_output.vw_risk_classification_history_complete` | L | 1 | UC `information_schema.columns` (96 cols) | History view |
| `main.de_output_stg.de_output_risk_calculations_cysec_users_scores` | L | 1 | UC `information_schema.columns` (8 cols) | UC analog of HLD's `RiskCalculation.CySecScoresTemporary` |
| Confluence HLD `11655577818` | S | 3 | `knowledge/confluence/_corpus/compliance/11655577818.json` | Source of the rename mapping; stale on object names |
| `BackOffice.SetRiskClassificationNew` (SP) | S | 1 | wiki `knowledge/synapse/Wiki/...` (manual_only external_reference) | The actual classification logic |
| Phase A.5c staleness | - | - | `knowledge/skills/_compliance_staleness.md` | 2 STALE-CONF + 42+ GAP-CONF context |
| Phase A.6 locality | - | - | `_compliance_staleness.md` §6 | Hybrid + manual_only justification |
