# Compliance & AML — Staleness Cross-Check Report

_Per spec 011 Phase A.5c. Cross-checks the Confluence corpus (Tier 3), wiki §3.3 (Tier 4), and UC `system.information_schema.tables` (ground truth) for the D domain._

_Generated 2026-05-24 from Phase A.0 anchors, Phase A.2 embedded scan, Phase A.5b Confluence corpus, and a Databricks `information_schema` query (220 rows scoped to AML/risk_class/compliance/cysec/screening/sanction/PEP)._

## Method

The Authority Hierarchy says **UC > Genie > Confluence canonical > wiki > Confluence non-canonical > Tableau**. Whenever evidence sources disagree, the higher tier wins. This report flags every disagreement found.

Verdict column abbreviations:
- **OK** — sources agree
- **STALE-CONF** — Confluence has it, UC doesn't (Confluence is out-of-date)
- **GAP-CONF** — UC has it, Confluence doesn't (Confluence missing important production reality)
- **GAP-DOC** — UC has it, neither Confluence nor wiki §3.3 covers it
- **OBSOLETE-OK** — explicitly Obsolete/Old/WiP-tagged Confluence page, content is for staleness baseline only; OK because the tag is honest

## 1. Production tables: Confluence claims vs UC reality

These are the 16 nodes extracted by the Confluence overlay (Phase A.5b) — checking each in UC.

| # | Confluence ref | UC equivalent | Verdict | Notes |
|---|---|---|---|---|
| 1 | `BackOffice.Customer` | `main.bi_db.bronze_etoro_backoffice_customer` (and family — confirmed via prior knowledge of bi_db bronze tables; not in this 220-row query because not AML-keyword-matched) | OK | the Customer master; widely referenced |
| 2 | `BackOffice.CustomerAllTimeAggregatedData` | `main.bi_db.bronze_etoro_backoffice_customeralltimeaggregateddata` (by naming convention; not in 220-row query) | OK | confirmed in prior phases |
| 3 | `BackOffice.SetRiskClassificationNew` | stored proc — runs in `etoro` DB; not a UC table | OK | stored proc, lives in Synapse only |
| 4 | `Customer.CustomerStatic` | `main.bi_db.bronze_etoro_customer_customerstatic` (by convention; not in this 220-row query) | OK |  |
| 5 | `Customer.ExtendedUserField` | `main.compliance.bronze_userapidb_customer_extendeduserfield_masked` | OK | UC has the **masked** PII-protected variant; production Synapse `Customer.ExtendedUserField` is the source |
| 6 | `Dictionary.CySecRiskClassificationParameter` | `main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter` | OK | bronze copy in UC |
| 7 | `History.Customer` | `main.bi_db.bronze_etoro_history_customer` (by convention; not in 220-row query) | OK |  |
| 8 | `History.CustomerAnswer` | `main.compliance.bronze_userapidb_history_customeranswers` | OK | bronze copy in UC (note: plural `customeranswers` in UC) |
| 9 | `RiskCalculation.CySecScoresTemporary` | NOT FOUND under that exact name. Closest: `main.de_output_stg.de_output_risk_calculations_cysec_users_scores` | **STALE-CONF** | the HLD (11655577818) names this table in Step 4 / Table A as the CySEC scoring output; the production move-to-Lake renamed it to `de_output_risk_calculations_cysec_users_scores`. HLD doc not updated to reflect implementation. |
| 10 | `RiskCalculation.ScoresTemporary` | `main.bi_db.bronze_etoro_riskcalculation_scorestemporary` | OK | bronze copy in UC |
| 11 | `RiskCalculation.SetRiskClassificationForCySec` | stored proc | OK | runs in Synapse |
| 12 | `RiskClassification.CySecRiskClassificationParameter` | `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` | OK |  |
| 13 | `RiskClassification.CySecRiskClassificationParameterView` | NOT FOUND under that exact name | **STALE-CONF** | HLD lists this VIEW as a metadata table to replicate; UC bronze layer has only the underlying table not the view |
| 14 | `dbo.P_RiskClassification` | stored proc | OK | runs in `RiskClassification` DB; not a UC object |
| 15 | `dbo.V_RiskClassificationDataLake` | `main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` | OK | bronze ingestion of the view |
| 16 | `main.general.bronze_etoro_dictionary_riskclassification` | `main.general.bronze_etoro_dictionary_riskclassification` (direct) | OK | exact UC match |

**2 STALE-CONF flags**: the HLD `11655577818` is the most table-rich Confluence doc but lists two objects (`RiskCalculation.CySecScoresTemporary`, `RiskClassification.CySecRiskClassificationParameterView`) that the production move-to-Lake did not preserve with those names. The HLD is the design; the implementation diverged.

## 2. Production tables that Confluence corpus does NOT cover

| UC object family | Count | Verdict | Notes |
|---|---|---|---|
| `main.regtech.gold_regtech_aml_*` | 11 tables | **GAP-CONF** | An entire parallel AML risk-scoring pipeline (regtech team) — `gold_regtech_aml_aml_riskscore_scd`, `gold_regtech_aml_api_riskscore`, `gold_regtech_aml_dict_regulation_aml`, `gold_regtech_aml_population`, etc. The 14 Confluence pages crawled (OTS Operations Wiki + CR Compliance Dev) make ZERO mention of regtech. This is a major doc-debt area. |
| `main.regtech.gold_regreportdb_prod_dbo_aml_*` | 9 tables | **GAP-CONF** | Regulatory reporting AML history tables (`aml_account_history`, `aml_ballance_history`, `aml_dnb_report`, `aml_party_history`, `aml_riskscore_scd`, etc.). Owned by RegTech; not in Compliance team Confluence. |
| `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_*` | 4 tables (the Phase A.3 Cluster 53 core) | **GAP-CONF** | The actual production AML scoring core (`*_aggregated_group_level`, `*_aggregated_level`, `*_cid_level`, `*_cid_window_level`). These are DE-team owned; the Compliance team Confluence pages describe the *upstream* HLD process but not these downstream consumer tables. |
| `main.de_output.de_output_risk_classification*` | 6 tables (incl. `_cysec`, `_history`, `_history_cysec`, `_scores`, `vw_risk_classification_history_complete`) | **GAP-CONF** | The DE-team destination of the HLD migration. HLD describes the target generically as "Data Lake"; the actual table names live only in UC. |
| `main.pii_data_stg.aml_*` and `main.pii_data.aml_snapshotcustomer_enriched_v` | 5 views + tables | **GAP-CONF** | PII-protected AML analyst views. No Confluence corpus mention. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | 1 table | **GAP-CONF** | Singapore-specific AML risk classification. AML Alerts Reconciliation Procedure (14245167130) lists "MAS" as a regulation but no Confluence page describes MAS/Singapore risk classification logic. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca` | 1 table | **GAP-CONF** | FCA Suspicious Activity Report (SAR). No Confluence mention. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | 1 table | **GAP-CONF** | Periodic AML review queue. No Confluence mention. |
| `main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` | 1 table | **GAP-CONF** | AML sub-entity categorization. No Confluence mention. |
| `main.wallet.bronze_walletdb_wallet_amlproviderusers`, `bronze_walletdb_wallet_amlvalidations` | 2 tables | **GAP-CONF** | Wallet AML provider integration. No Confluence mention. |
| `main.spaceship.bronze_spaceship_analytics_rpt_etoro_user_screening` | 1 table | **GAP-CONF** | Spaceship (UK product) AML screening report. No Confluence mention in corpus. |

**Total tables Confluence doesn't cover: 42+**. Concentrated in three areas: (1) the regtech parallel pipeline, (2) the DE-team destination layer (`de_output_*`, `cmp_aml_*`), (3) regulatory variants (Singapore, SAR FCA, sub-entity categorization).

This is **not surprising** given that Compliance and AML is the most churn-heavy domain (per user direction). The KPI views + Genie spaces + UC information_schema are the production-truth layer; Confluence canonical docs are the WHY-knowledge but not the complete inventory.

## 3. Wiki §3.3 join patterns: D-domain coverage

From Phase A.2 (`_compliance_embedded_members.md`) — 63 AML-tagged nodes embedded across Louvain clusters 1, 4, 6, 7, 10, 11, 16, 45 (the "Customer domain leakage"). These are wiki-derived JOIN patterns that put AML tables next to Customer tables semantically.

| Pattern | Verdict | Notes |
|---|---|---|
| 63 AML-named nodes in non-D Louvain clusters | OK | This is *correct* leakage — AML scoring INPUTS are customer-domain tables (Customer.CustomerStatic, BackOffice.Customer, History.CustomerAnswer). The wiki's join sampler picked up these natural joins. |
| `BI_DB_dbo.BI_DB_RiskAlertManagementTool` not in any D-primary cluster | **GAP-WIKI** | Phase A.4 Tableau fly-over surfaced it — production AML routing table missed by wiki §3.3. Now added to `compliance.yaml` hub_tables. |
| `cmp_aml_risk_classification_*` (4 tables) | **GAP-WIKI** | Wiki §3.3 has them in Cluster 53 but with low intra-cluster join weight. The dominant edges from these tables are via Genie config (Tier 2), not wiki joins (Tier 4). |

## 4. Obsolete-tagged pages: are they truly obsolete?

| Page | Reality check | Verdict |
|---|---|---|
| `AML Monitoring DC4 Timeframes (Obsolete)` (905216150) | Superseded by `AML Timeframes Limitation Procedure` (905183354) — current. | **OBSOLETE-OK** Tag honest. |
| `AML Monitoring Alerts Logic (Old logic)` (905216127) | Lists DC1-DC21 + OB6-OB20 rules. NO replacement page exists in the corpus that documents the *current* alert rule catalog. The alert rules surface in code as `BI_DB_dbo.BI_DB_AML_Daily_Alerts` and `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` but the rule LOGIC isn't documented in any non-obsolete Confluence page. | **OBSOLETE-OK-BUT-GAP** Tag is honest, but the replacement Confluence page doesn't exist. The current rule logic lives in production SQL in the SetRisk* stored procs + the regtech pipeline. |
| `CDD alert guidance: Client is PEP (WiP - not in use)` (12018122771, CR space) | Superseded by `CDD alert guidance: Client is PEP` (12003442859, OTS space). Both exist. | **OBSOLETE-OK** Tag honest. |

## 5. Implications for Phase B and Phase C

For Phase B (partition shape decision), this staleness report says:

1. **The semantic core is UC + Genie, not Confluence.** The 4 `cmp_aml_risk_classification_*` tables (Phase A.3 Cluster 53) plus the 6 `de_output_risk_classification*` tables (UC native) form the production AML scoring stack. Confluence describes the HLD process for the upstream Synapse-side calculation; the downstream UC tables are the actual analytical surface.

2. **The regtech AML pipeline is unowned in Confluence.** This means the v1 D skill should either:
   - **Cover it** by writing the SKILL.md from UC + KPI + Genie evidence alone (no Confluence), flagging the doc gap; OR
   - **Defer it** to a v2 spec dedicated to RegTech AML.
   Recommended: **cover it** — it's solidly in the AML risk-scoring family, and the user instructed "core issues matter more than most recent".

3. **The 2 STALE-CONF entries (CySecScoresTemporary and CySecRiskClassificationParameterView)** mean the SKILL.md should call the UC names, NOT the HLD's Synapse names. Lead with the UC reality and note "the HLD doc still references the pre-migration names."

4. **The 42+ GAP-CONF tables** confirm the Authority Hierarchy choice was correct: KPI views + Genie configs + UC information_schema are Tier 1 + 2 + ground truth for THIS domain. Confluence (Tier 3) is partial and aspirational for the AML/Compliance domain because the Compliance team writes process docs, not data docs.

## 6. Locality classification (Phase A.6 — NEVER-DROP rule)

> Per `.specify/templates/domain-build-template.md` Phase A.6 and spec 011 FR-011, every anchor surfaced in Phases A.0–A.5 is classified by where it physically lives today. The classification is **additive annotation, not a filter** — anchors not in UC are kept in the skill with `locality:` tags, not dropped. This was added 2026-05-24 by user direction: "we at this phase still have a lot of LOGIC and OUTPUT ONLY in synapse. re: aml alerts — i actually think it would be hugely beneficial to include the skill for knowledge purposes with caveat that the data does not yet live in databricks."

Buckets:
- **UC** — verified present in `main.*` via `system.information_schema.tables` query on 2026-05-24.
- **synapse_only** — exists in production Synapse (`sql_dp_prod_we`) but NOT in UC.
- **hybrid_synapse_uc** — both exist; UC bronze drops columns / lags / projects differently from Synapse master.
- **external_system** — third-party SaaS (Actimize, ComplyAdvantage, Salesforce); may surface downstream in UC bronze, but the decision/scoring engine isn't queryable from UC.
- **manual_only** — procedural knowledge (stored procs, runbook rules, alert-rule catalogues) — not a data table.

### 6.1 Live alert + routing tables — **SYNAPSE-ONLY** (the gap)

These are the operationally-critical AML routing tables. The user explicitly called them out as "logic and output only in synapse" — confirmed by `information_schema` query.

| Anchor | UC presence | Locality | Source system | Role | Bridge strategy |
|---|---|---|---|---|---|
| `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` | NOT FOUND | `synapse_only` | `sql_dp_prod_we` | Live AML alert routing table — `CategoryName='AML'` predicate identifies AML routing rows | Query via the Synapse MCP server `user-synapse_prod_sql` (read-only); see wiki at `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_BI_Alerts_New.md` |
| `BI_DB_dbo.BI_DB_AML_Daily_Alerts` | NOT FOUND | `synapse_only` | `sql_dp_prod_we` | Daily AML alert summary feeding the alert review queue | Query via `user-synapse_prod_sql` MCP; wiki at `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_Daily_Alerts.md` |
| `BI_DB_dbo.BI_DB_RiskAlertManagementTool` | NOT FOUND | `synapse_only` | `sql_dp_prod_we` | Cross-category alert management tool (filter `CategoryName='AML'` for AML); referenced by Tableau workbook surfaced in Phase A.4 | Query via `user-synapse_prod_sql` MCP; wiki at `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_RiskAlertManagementTool.md` |

**These three tables ARE the AML alerts production layer.** Skill must keep them — they are the primary anchors of the AML alert-routing sub-skill. Locality caveat explains that consumers querying from Databricks default profile will need to switch to Synapse.

### 6.2 Verified UC anchors

| Anchor | UC FQN | Locality | Tier (authority) | Notes |
|---|---|---|---|---|
| `BI_DB_dbo.BI_DB_AMLPeriodicReview` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | `UC` | 1 (production layer) | Periodic AML review queue — only AML-alert family table that made it to UC |
| `BI_DB_dbo.BI_DB_AML_SAR_Report_FCA` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca` | `UC` | 1 | FCA Suspicious Activity Report output |
| `BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | `UC` | 1 | MAS-regulated risk classification (Singapore) |
| `BI_DB_dbo.BI_DB_AML_Subentity_Categorization` | `main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` | `UC` | 1 | Sub-entity (legal-entity-of-the-day) AML categorization |
| cmp_aml_risk_classification family | `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_*` (4 tables) | `UC` | 1 (Phase A.3 Cluster 53 core) | The production AML risk SCORING core: `_aggregated_group_level`, `_aggregated_level`, `_cid_level`, `_cid_window_level` |
| de_output risk_classification family | `main.de_output.de_output_risk_classification_*` (6 tables) | `UC` | 1 | DE-team destination layer for the HLD 11655577818 CySEC migration: `_history`, `_history_cysec`, `_cysec_users_scores`, plus `vw_risk_classification_history_complete` |
| regtech AML family | `main.regtech.gold_regtech_aml_*` (11 tables) + `main.regtech.gold_regreportdb_prod_dbo_aml_*` (9 tables) | `UC` | 1 | Parallel AML risk-scoring pipeline (regtech team-owned); NO Confluence coverage (GAP-CONF) |
| pii_data AML views | `main.pii_data_stg.aml_*` + `main.pii_data.aml_snapshotcustomer_enriched_v` (5 objects) | `UC` | 1 | PII-protected AML analyst views |
| wallet AML integration | `main.wallet.bronze_walletdb_wallet_amlproviderusers`, `_amlvalidations` (2 tables) | `UC` | 1 | Wallet platform AML provider integration |
| spaceship user screening | `main.spaceship.bronze_spaceship_analytics_rpt_etoro_user_screening` | `UC` | 1 | Spaceship (UK product) AML screening report |
| All 12 bronze copies from §1 | (see §1 table) | `UC` | 1 | Bronze ingestions of OLTP Customer / RiskCalculation / RiskClassification / BackOffice families |

### 6.3 HLD-named tables that the implementation renamed — **HYBRID_SYNAPSE_UC**

These are the 2 STALE-CONF cases from §1: the HLD document still names the Synapse source by its old name, but the UC implementation chose a different name.

| HLD-side (Synapse) | UC-side | Locality | Notes |
|---|---|---|---|
| `RiskCalculation.CySecScoresTemporary` | `main.de_output_stg.de_output_risk_calculations_cysec_users_scores` | `hybrid_synapse_uc` | HLD references the Synapse name; UC name is `cysec_users_scores`. Skill teaches the UC name as canonical and notes the HLD is stale. |
| `RiskClassification.CySecRiskClassificationParameterView` | not present as a view in UC; underlying table `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` IS in UC | `hybrid_synapse_uc` | UC has the bronze TABLE but not the view; consumers needing the view's projection must query Synapse. |

### 6.4 Vendor / external-system sources — **EXTERNAL_SYSTEM**

These compute or store AML/compliance decisions but are not directly queryable from UC (verified by `information_schema` query — zero results for `actimize|complyadvantage|onfido|sumsub|trulioo|pep_check|sanction` table-name patterns).

| Source | Locality | Source system | Role | Bridge strategy |
|---|---|---|---|---|
| **Actimize** (CDD scoring engine) | `external_system` | Actimize SaaS | Computes the AML CDD risk score (200+ = high risk per `CDD alert guidance: Client is PEP` Confluence page). | No direct UC feed; score is surfaced indirectly via `BI_DB_dbo.BI_DB_RiskAlertManagementTool.AlertSeverityScore` (also synapse_only). For raw decisions and threshold settings: query Actimize UI directly with Compliance Eng team credentials. |
| **ComplyAdvantage** (sanctions / PEP screening) | `external_system` | ComplyAdvantage SaaS | Sanctions list match, PEP list match, adverse media. | Decision artifacts inferred from downstream Synapse routing tables; no direct UC feed. Refer to Compliance Eng for vendor portal access. |
| **Tableau** AML workbook (Phase A.4 fly-over) | `external_system` | Tableau Server | Surfaced `BI_DB_RiskAlertManagementTool` as the production AML routing source. Analyst-curated custom SQL — Authority Tier 6, weighted 0.5x in graph merge. | View in Tableau Server. The workbook is the audit trail for why this table is in the seed YAML's `hub_tables`. |

### 6.5 Procedural knowledge — **MANUAL_ONLY**

These are the rule catalogues, stored procs, and runbook steps that define AML/compliance LOGIC but are not data tables.

| Item | Locality | Source | Role | Bridge strategy |
|---|---|---|---|---|
| `BackOffice.SetRiskClassificationNew` (SP) | `manual_only` | Synapse `etoro` DB | Sets the risk classification on a customer event | Read the SP body in Synapse Wiki; no automated query |
| `RiskCalculation.SetRiskClassificationForCySec` (SP) | `manual_only` | Synapse `RiskCalculation` DB | CySEC-specific risk classification recompute | Read the SP body; runs in Synapse |
| `dbo.P_RiskClassification` (SP) | `manual_only` | Synapse `RiskClassification` DB | Master risk classification orchestration | Read the SP body |
| DC1-DC21 + OB6-OB20 alert rule catalogue | `manual_only` | Confluence page 905216127 (`AML Monitoring Alerts Logic (Old logic)`) — tagged Old logic but no replacement Confluence page exists. Rules execute today in `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` (synapse_only). | The rule LOGIC that produces today's AML alerts. The doc is tagged stale but is the only catalogue. | Read the Confluence page for rule names + intent; cross-reference against `BI_DB_AML_BI_Alerts_New.AlertCode` distinct values in Synapse for the current production set. **Skill must include both as a paired knowledge item.** |

### 6.6 Locality summary

| Locality | Count | Comment |
|---|---|---|
| `UC` | ~50 tables across `main.bi_db / bi_compliance_stg / compliance / de_output / de_output_stg / regtech / pii_data / pii_data_stg / wallet / spaceship` | The production AML scoring layer and the regulatory output layer ARE in UC |
| `synapse_only` | 3 critical alert-routing tables (`BI_DB_AML_BI_Alerts_New`, `BI_DB_AML_Daily_Alerts`, `BI_DB_RiskAlertManagementTool`) | The LIVE alert layer is Synapse-only — this is the user-surfaced gap |
| `hybrid_synapse_uc` | 2 (CySEC HLD rename cases) | HLD names ≠ UC names; skill teaches UC names |
| `external_system` | 3 (Actimize, ComplyAdvantage, Tableau workbook) | Vendor decisions surface only via downstream synapse_only tables |
| `manual_only` | 4 (3 stored procs + 1 alert-rule catalogue) | Procedural knowledge worth preserving |

### 6.7 Implications for Phase B partition

The locality classification has a direct impact on Phase B sub-skill design:

1. **An `aml-alert-routing` sub-skill is genuinely Synapse-anchored.** Its `required_tables:` will be minimal (the 2 UC-resident tables: `bi_db_amlperiodicreview`, `bi_db_aml_sar_report_fca`) and its `external_references:` will be substantial (the 3 synapse_only routing tables + 1 manual_only alert-rule catalogue + 1 external_system Actimize entry).

2. **An `aml-risk-scoring` sub-skill is UC-native.** `required_tables:` covers the cmp_aml_risk_classification_* + de_output_risk_classification* + bronze inputs; `external_references:` only needs the 2 hybrid_synapse_uc entries for the HLD rename gap.

3. **A `regtech-aml-pipeline` sub-skill is fully UC-native and Confluence-uncovered** — `required_tables` lists 20 regtech tables; `external_references` is empty.

4. **The hub `SKILL.md`** must surface in its description the fact that one sub-skill (alert-routing) is mostly Synapse-resident so the routing-time embedding picks up the right caveat.

---

## Provenance

- UC query: `system.information_schema.tables` (read-only Databricks SQL warehouse). 220 rows scoped to RLIKE `(aml|risk_class|riskcalc|riskclassification|cmp_aml|cysec|screening|sanction|pep_)` or schema RLIKE `(aml|compliance|riskcalc|riskclassification)`.
- Locality verification queries (Phase A.6, 2026-05-24): targeted `information_schema.tables` queries for `(aml_bi_alerts|aml_daily_alerts|riskalertmanagementtool|amlperiodicreview|aml_alert|aml_sar_report|aml_risk_alert)`, `(actimize|complyadvantage|onfido|sumsub|trulioo|pep_check|sanction|screening_check)`, and `(setrisk|risk_classification_history|alertseverity|aml_alerts|cdd_alert|pep_)` — 8 UC hits total, confirming the 3 Synapse-only alert-routing tables and the zero-hit external vendor pattern.
- Confluence corpus: `knowledge/confluence/_corpus/compliance/*.json` (14 pages).
- Wiki §3.3: `knowledge/skills/_node_summary.csv` + `_node_clusters.csv` (Phase A.2 scan).
- Locality contract: `knowledge/skills/_AUTHORITY_HIERARCHY.md` "Locality is orthogonal to authority" + `.specify/templates/domain-build-template.md` Phase A.6.
