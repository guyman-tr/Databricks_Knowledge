# Compliance & AML — Phase B Partition Decision

> Per spec 011 FR-006 + FR-010, the file-shape (hub-with-sub-skills vs single-overlay vs atomic-pair vs B-embedded) is chosen here, driven by the semantic-model outputs of Phases A.0–A.6, **not** by uniform-format convention. This document is the audit trail for that choice.

_Generated 2026-05-24. Author: spec-011 build agent. Inputs: `_compliance_production_anchors.md`, `_brief_cluster_35.md`, `_compliance_embedded_members.md`, `_compliance_subgraph.md`, `_compliance_tableau_flyover.md`, `_compliance_confluence_corpus.md`, `_compliance_confluence_edges.csv`, `_compliance_staleness.md`._

## 1. User-stated scope

Per direct user instruction at the start of the D build: **"AML risk classification and scoring only."** Explicitly OUT of scope for v1:

- KYC screening (sanctions / PEP / adverse media as identity-side checks)
- Tax compliance (FATCA / CRS reporting)
- Regulatory reporting (SAR FCA, MAS regulatory output, CySEC outbound)
- Tribe audit envelope interpretation (Treezor SOC2 — owned by `domain-cross/tribe-emoney-audit`)

These are AML-adjacent and will be addressed in future specs (012+). The v1 D skill must explicitly defer them.

## 2. Candidate shapes and evaluation

Four candidates per FR-010, evaluated against the semantic-model outputs.

### (a) Full hub + N sub-skills (Payments style)

**Strength.** Mirrors the existing 5 deployed domains. Each sub-skill owns ≤1 slice of the lifecycle; intra-slice joins are dense, inter-slice sparse.

**Fit for D.** Strong if there are ≥ 2 distinct anchor families inside scope. Phase A.6 confirms three:
1. **AML risk scoring** — UC-native (`cmp_aml_risk_classification_*` + `de_output_risk_classification*` + `de_output_risk_calculations_cysec_users_scores`).
2. **AML alert routing** — Synapse-anchored (`BI_DB_AML_BI_Alerts_New`, `BI_DB_AML_Daily_Alerts`, `BI_DB_RiskAlertManagementTool` all `synapse_only`; `BI_DB_AMLPeriodicReview` is the only UC-resident routing table).
3. **RegTech AML pipeline** — UC-native, fully Confluence-uncovered (`regtech.gold_regtech_aml_*` + `regtech.gold_regreportdb_prod_dbo_aml_*`).

Three families satisfy the "≥ 2 anchor families" threshold and each family has internal join density per the Genie configs and the subgraph (Phase A.3).

### (b) Single overlay skill embedded in B's compliance-customer-snapshot-and-club

**Weakness.** The B-side `compliance-customer-snapshot-and-club` is KYC-tilted (customer state / club tier / FATCA). The Phase A.6 locality result shows the AML scoring core is in a DIFFERENT catalog family (`bi_compliance_stg`, `de_output`, `regtech`) than the B-side anchors. Embedding D inside a B sub-skill would either bloat that sub-skill or force cross-skill cherry-picking. **Rejected.**

### (c) Standalone D hub with 1-2 sub-skills

**Weakness.** Cramming AML scoring + alert routing + regtech into one or two files violates the deployed convention's "≤1 slice per sub-skill" guarantee. The three families don't share an anchor table:

- scoring writes to `de_output_risk_classification*`
- alert routing reads from `BI_DB_AML_BI_Alerts_New` (Synapse)
- regtech writes to its own `regtech.gold_*` family

Compressing them removes the routing benefit (the embedding can't pick the right sub-skill if there's only one). **Rejected** in favor of (a).

### (d) Atomic-pair (just two files — hub + one)

**Weakness.** Same as (c) but worse — we'd be forced to drop one of the three families. The user's "core issues matter more than most recent" + "include synapse-only knowledge with caveat" rules both forbid dropping any of them. **Rejected.**

## 3. Decision

**Shape (a): hub + 3 sub-skills.**

```
knowledge/skills/domain-compliance-and-aml/
  SKILL.md                          # hub — routes between the 3 sub-skills + defers OUT-of-scope to siblings
  aml-risk-scoring.md               # CySEC + global risk classification SCORING (UC-native)
  aml-alert-routing.md              # live alert layer (mostly synapse_only + external_system Actimize)
  aml-regtech-pipeline.md           # parallel RegTech AML pipeline (UC-native, Confluence-uncovered)
```

Naming follows the deployed convention (`domain-<super>/...`). Sub-skill slugs are kebab-case, match the file stem, and prefix-free (no `aml-` is fine because the parent directory carries the AML context for retrieval).

Wait — to disambiguate from other domain sub-skills in flat search, the `aml-` prefix IS useful. The deployed convention is mixed: payments uses `crypto-wallet` (no `payments-` prefix) but trading uses `lp-contracts-and-cogs`. Following the more discoverable pattern, all three sub-skills keep the `aml-` prefix.

## 4. Sub-skill scopes and anchor lists

### 4.1 `aml-risk-scoring.md` (UC-native — Tier 1 KPI + Genie + Confluence canonical)

**Purpose.** The CySEC + global risk classification scoring pipeline. From source customer-side inputs (`Customer.CustomerStatic`, `History.CustomerAnswer`, `BackOffice.Customer`) through the production scoring core (`cmp_aml_risk_classification_*`) to the destination layer (`de_output_risk_classification*` + `de_output_risk_calculations_cysec_users_scores`).

**`required_tables:` (UC FQNs only):**

| FQN | Tier | Source |
|---|---|---|
| `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level` | 1 | Phase A.3 Cluster 53 core; Genie + KPI |
| `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_window_level` | 1 | " |
| `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_aggregated_level` | 1 | " |
| `main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_aggregated_group_level` | 1 | " |
| `main.de_output.de_output_risk_classification_history` | 1 | DE-team destination |
| `main.de_output.de_output_risk_classification_history_cysec` | 1 | " |
| `main.de_output.vw_risk_classification_history_complete` | 1 | DE view over the history pair |
| `main.de_output_stg.de_output_risk_calculations_cysec_users_scores` | 1 | The UC analog of HLD's `RiskCalculation.CySecScoresTemporary` (rename) |
| `main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter` | 2 | Bronze CySEC parameter dictionary |
| `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` | 2 | Bronze CySEC parameter table |
| `main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` | 2 | Bronze of the production view |
| `main.bi_db.bronze_etoro_riskcalculation_scorestemporary` | 2 | Bronze of `RiskCalculation.ScoresTemporary` |
| `main.compliance.bronze_userapidb_history_customeranswers` | 2 | Bronze of `History.CustomerAnswer` (customer KYC answer history) |
| `main.compliance.bronze_userapidb_customer_extendeduserfield_masked` | 2 | Bronze of `Customer.ExtendedUserField` (PII-masked) |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | 1 | MAS Singapore-specific scoring |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` | 1 | Sub-entity legal-entity categorization |
| `main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` | 1 | (duplicate placement under compliance catalog) |
| `main.general.bronze_etoro_dictionary_riskclassification` | 2 | The cross-product risk classification dictionary |

**`external_references:` (non-UC):**

| name | locality | source_system | role |
|---|---|---|---|
| `BackOffice.SetRiskClassificationNew` (SP) | manual_only | sql_dp_prod_we (`etoro` DB) | Master stored proc setting risk classification on customer events |
| `RiskCalculation.SetRiskClassificationForCySec` (SP) | manual_only | sql_dp_prod_we (`RiskCalculation` DB) | CySEC-specific recompute orchestrator |
| `dbo.P_RiskClassification` (SP) | manual_only | sql_dp_prod_we (`RiskClassification` DB) | Top-level orchestration |
| `RiskClassification.CySecRiskClassificationParameterView` | hybrid_synapse_uc | sql_dp_prod_we | Synapse-side projection of the parameter table; UC has the table but not the view |

### 4.2 `aml-alert-routing.md` (Synapse-anchored — the gap the user surfaced)

**Purpose.** The live AML alert layer. Where alerts fire, how they're routed (`CategoryName='AML'`), how they're queued for review, and the rule catalogue that produces them. The user explicitly required this sub-skill be included with locality caveats because "data does not yet live in databricks and user needs to go to synapse/other source for it."

**`required_tables:` (UC FQNs only — the small UC-resident slice):**

| FQN | Tier | Source |
|---|---|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | 1 | UC-resident periodic-review queue (the bridge to UC analytics) |
| `main.pii_data.aml_snapshotcustomer_enriched_v` | 1 | PII-enriched AML snapshot view (analyst entry point) |
| `main.pii_data_stg.aml_snapshotcustomer_enriched_v` | 1 | Staging variant |

**`external_references:` (the bulk of the sub-skill):**

| name | locality | source_system | role | bridge_strategy |
|---|---|---|---|---|
| `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` | synapse_only | sql_dp_prod_we | Live AML alert routing; `CategoryName='AML'` predicate | Query via `user-synapse_prod_sql` MCP; wiki at `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_BI_Alerts_New.md` |
| `BI_DB_dbo.BI_DB_AML_Daily_Alerts` | synapse_only | sql_dp_prod_we | Daily AML alert summary feeding the review queue | Query via `user-synapse_prod_sql` |
| `BI_DB_dbo.BI_DB_RiskAlertManagementTool` | synapse_only | sql_dp_prod_we | Cross-category alert mgmt tool (filter `CategoryName='AML'`); surfaced via Phase A.4 Tableau workbook | Query via `user-synapse_prod_sql` |
| DC1-DC21 + OB6-OB20 rule catalogue | manual_only | Confluence page 905216127 (`(Old logic)` tagged but no replacement) | The catalogue of rule codes producing today's alerts | Read Confluence page; cross-reference against `BI_DB_AML_BI_Alerts_New.AlertCode` distinct values for current production set |
| Actimize CDD scoring engine | external_system | Actimize SaaS | Computes CDD risk score (200+ = high risk per Confluence page `CDD alert guidance: Client is PEP`) | No direct feed; surfaces downstream as `BI_DB_RiskAlertManagementTool.AlertSeverityScore` (also synapse_only). Compliance Eng owns vendor credentials |

**Critical Warnings tier 1 will lead with the locality caveat.**

### 4.3 `aml-regtech-pipeline.md` (UC-native, Confluence-uncovered)

**Purpose.** The parallel RegTech AML pipeline owned by the RegTech team. 20 tables that the Phase A.5c staleness report flagged as `GAP-CONF` — production reality with zero Confluence documentation. The KPI views + UC information_schema ARE the documentation.

**`required_tables:` (UC FQNs only — the full RegTech AML family):**

| FQN | Tier | Source |
|---|---|---|
| `main.regtech.gold_regtech_aml_aml_riskscore_scd` | 1 | RegTech AML risk score SCD-2 |
| `main.regtech.gold_regtech_aml_api_riskscore` | 1 | API-facing risk score |
| `main.regtech.gold_regtech_aml_dict_regulation_aml` | 1 | AML regulation dictionary |
| `main.regtech.gold_regtech_aml_population` | 1 | AML scoring population |
| `main.regtech.gold_regreportdb_prod_dbo_aml_account_history` | 1 | AML account history |
| `main.regtech.gold_regreportdb_prod_dbo_aml_ballance_history` | 1 | AML balance history (sic) |
| `main.regtech.gold_regreportdb_prod_dbo_aml_dnb_report` | 1 | AML Do-No-Business report |
| `main.regtech.gold_regreportdb_prod_dbo_aml_party_history` | 1 | AML party history |
| `main.regtech.gold_regreportdb_prod_dbo_aml_riskscore_scd` | 1 | Reg report risk score SCD |
| (remaining 11 regtech AML tables — full list authored in the sub-skill) | 1 | " |

**`external_references:`** Empty (this family is fully UC-native).

**Critical Warnings tier 1 will name the doc gap explicitly** so the consumer knows they're holding the only documentation.

## 5. Hub (`SKILL.md`) shape

The hub:
- Lists the 3 sub-skills with anchor previews + when-to-load
- Names the v1-OUT-of-scope adjacents (KYC screening / Tax / FCA SAR / Tribe) and routes them to siblings/future-specs
- Surfaces the **locality caveat** in the description so retrieval-time embedding picks it up: "AML risk classification + scoring across UC-native and Synapse-only sources..."
- Carries the cross-domain pointers (`B compliance-customer-snapshot-and-club` for KYC-adjacent customer state, `C.3 emoney-tribe-audit` for Treezor envelopes, `H domain-revenue-and-fees` for chargeback-tied alerts).

## 6. OUT-of-scope routing (must appear in every sub-skill's Out-of-scope line)

| Question shape | Routes to |
|---|---|
| KYC sanctions / PEP / adverse-media screening as identity check | `B domain-customer-and-identity/compliance-customer-snapshot-and-club` (planned v1.5) |
| FATCA / CRS / IRS tax reporting | future spec 012-tax-compliance |
| FCA SAR / MAS regulatory submission | future spec 013-regulatory-reporting (uses `aml_sar_report_fca` etc.) |
| Treezor / Tribe SOC2 audit envelopes | `domain-cross/tribe-emoney-audit` |
| Operator audit trail (BackOffice manual actions) | `B domain-customer-and-identity/customer-action-audit-trail` |
| Trading-side broker recon (IG / Saxo / Duco) | `A domain-trading/broker-and-lp-reconciliation` |
| Fee / revenue events tied to AML decisions (refund / chargeback chain) | `H domain-revenue-and-fees` + `domain-cross/refund-chargeback-chain` |

## 7. Phase B exit criteria

- [x] Partition shape chosen (hub + 3 sub-skills) with semantic-model evidence cited
- [x] Three sub-skills' `required_tables:` + `external_references:` enumerated against Phase A.6 locality classification
- [x] OUT-of-scope adjacents named with sibling/future-spec routing
- [x] Locality caveat surfaced in the proposed hub description

→ Phase C may now author the four files.

## 8. Provenance

- Phase A.0: `_compliance_production_anchors.md` (KPI + Genie seeds)
- Phase A.1: `_brief_cluster_35.md` (Louvain AML core)
- Phase A.2: `_compliance_embedded_members.md` (63 embedded scan)
- Phase A.3: `_compliance_subgraph.md` (Genie-seeded subgraph)
- Phase A.4: `_compliance_tableau_flyover.md` (Tableau surfaced `BI_DB_RiskAlertManagementTool`)
- Phase A.5a: `tools/skills/extract_confluence_edges.py` (the new generic extractor)
- Phase A.5b: `_compliance_confluence_corpus.md` + `_compliance_confluence_edges.csv` (14 pages, 64 edges, 16 nodes)
- Phase A.5c + A.6: `_compliance_staleness.md` (2 STALE-CONF + 42 GAP-CONF + 1 OBSOLETE-OK-BUT-GAP; locality classification with 5 buckets)
- User direction (2026-05-24): "AML risk classification and scoring only" + "include synapse-only knowledge with caveat" + "core issues matter more than most recent"
- Harness contract: `_AUTHORITY_HIERARCHY.md` + `.specify/templates/domain-build-template.md` + `.specify/templates/skill-template.md`
