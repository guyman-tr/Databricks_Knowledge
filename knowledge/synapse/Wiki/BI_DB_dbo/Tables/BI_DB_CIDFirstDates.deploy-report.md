# Deployment Report: BI_DB_dbo.BI_DB_CIDFirstDates

> Generated: 2026-03-15 | Pipeline: dwh-semantic-doc (14-phase)

## 1. Object Summary


| Property               | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Synapse Object**     | `BI_DB_dbo.BI_DB_CIDFirstDates`                                        |
| **Object Type**        | Table                                                                  |
| **UC Primary Target**  | `pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`           |
| **Columns Documented** | 139                                                                    |
| **Quality Score**      | 8.5/10 (★★★★☆)                                                         |
| **Tier Breakdown**     | 0 T1, 100 T2, 6 T3, 18 T4 [UNVERIFIED], 0 T5                           |
| **Review Items**       | 18 Tier 4 columns + 6 clarification questions + 4 structural questions |


## 2. Output Files


| File                                           | Status  | Description                                                  |
| ---------------------------------------------- | ------- | ------------------------------------------------------------ |
| `BI_DB_CIDFirstDates.md`                       | WRITTEN | Wiki documentation (478 lines)                               |
| `BI_DB_CIDFirstDates.review-needed.md`         | WRITTEN | Review sidecar (28 items)                                    |
| `BI_DB_CIDFirstDates.alter.sql`                | WRITTEN | Main ALTER script (325 lines, 280 statements)                |
| `BI_DB_CIDFirstDates.downstream.alter.sql`     | WRITTEN | Deep propagation SQL log (590 lines, 504 statements)         |
| `BI_DB_CIDFirstDates.lineage-tree.json`        | WRITTEN | Full lineage tree (25 objects, 501 matches, 3 renames)       |
| `BI_DB_CIDFirstDates.propagation-scope.md`     | WRITTEN | Pre-execution scope report                                   |
| `BI_DB_CIDFirstDates.propagation-progress.json`| WRITTEN | Execution progress log (347 succeeded, 157 failed)           |
| `BI_DB_CIDFirstDates.deploy-report.md`         | WRITTEN | This file                                                    |


## 3. Main ALTER Execution


| Component       | Succeeded | Total   | Status                                        |
| --------------- | --------- | ------- | --------------------------------------------- |
| Table comment   | 1         | 1       | OK                                            |
| Table tags      | 1         | 1       | OK (14 tags)                                  |
| Column comments | 139       | 139     | OK                                            |
| PII tags        | 139       | 139     | OK (4 direct: UserName, Email, BirthDate, IP) |
| **Total**       | **280**   | **280** |                                               |


## 4. Downstream Objects

### 4a. Direct Downstream (Phase 11)

6 downstream objects discovered, 6 updated successfully. 2 additional objects skipped (METRIC_VIEWs).


| #   | Object                                                                | Type  | Columns Matched | Statements | Status |
| --- | --------------------------------------------------------------------- | ----- | --------------- | ---------- | ------ |
| 1   | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | TABLE | 139/139         | 139/139    | OK     |
| 2   | `main.etoro_kpi.cidfirstdates_v`                                      | VIEW  | 104/105         | 104/104    | OK     |
| 3   | `main.data_rooms.vw_cidfirstdates`                                    | VIEW  | 130/135         | 130/130    | OK     |
| 4   | `main.data_rooms.vw_cidfirstdates_not_masked`                         | VIEW  | 130/134         | 130/130    | OK     |
| 5   | `main.bi_output_stg.fca_cidfirstdates_2025`                           | VIEW  | 6/15            | 7/7        | OK     |
| 6   | `main.bi_output_stg.fca_cidfirstdates_joined_2025`                    | VIEW  | 5/15            | 5/5        | OK     |


**Skipped objects**:

- `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` — METRIC_VIEW, no column comment support
- `main.bi_output_stg.fca_cidfirstdates_2025_metric_view` — METRIC_VIEW, no column comment support

### 4b. Deep Lineage Propagation

25 downstream objects discovered via 3 methods: UC column lineage, name-pattern search, and Synapse dependency graph. 504 ALTER/COMMENT statements executed in 1 batch.

| Metric | Count |
| --- | --- |
| Discovery methods | `lineage`, `name_pattern`, `synapse_dependency` |
| Total downstream objects | 25 |
| Column matches (identical) | 501 |
| Renames detected | 3 |
| Blacklisted columns excluded | 10 |
| Statements executed | 504 |
| Succeeded | 347 |
| Failed | 157 |

**Failure breakdown**:

| Reason | Count | Objects |
| --- | --- | --- |
| Dropped object | ~91 | `main.api_delta.vw_cidfirstdates_not_masked` (view no longer exists) |
| Permission denied | ~66 | `regtech.*`, `api_general.*`, `dwh.*cid_monthlypanel*`, `general.*marketingdailyrawdata`, `general.*pltv` |

**Objects successfully updated** (17):

| # | Object | Type | Discovery | Columns |
| --- | --- | --- | --- | --- |
| 1 | `main.data_rooms.vw_cidfirstdates_not_masked` | VIEW | lineage | matched |
| 2 | `main.pii_data.gold_..._cidfirstdates_metric_view` | TABLE | lineage | matched |
| 3 | `main.bi_db.gold_..._cidfirstdates_masked` | TABLE | name_pattern | matched |
| 4 | `main.bi_db.gold_..._newbonusreport` | TABLE | synapse_dep | matched |
| 5 | `main.bi_db.gold_..._cid_lifestagedefinition` | TABLE | synapse_dep | matched |
| 6 | `main.bi_db.gold_..._compliance_illegal_trades_alerts` | TABLE | synapse_dep | matched |
| 7 | `main.bi_db.gold_..._operations_onboarding_flow_userkpis` | TABLE | synapse_dep | matched |
| 8 | `main.bi_db.gold_..._kyc_knowledge_assessment` | TABLE | synapse_dep | matched |
| 9 | `main.bi_db.gold_..._first5actions` | TABLE | synapse_dep | matched |
| 10 | `main.bi_db.gold_..._kyc_panel` | TABLE | synapse_dep | matched |
| 11 | `main.bi_db.gold_..._depositusersfirsttouchpoints` | TABLE | synapse_dep | matched |
| 12 | `main.bi_db.gold_..._cid_dailypanel_fulldata` | TABLE | synapse_dep | matched |
| 13 | `main.bi_db.gold_..._ops_fraud_alert_analysis` | TABLE | synapse_dep | matched |
| 14 | `main.bi_db.gold_..._cross_selling_monthly` | TABLE | synapse_dep | matched |
| 15 | `main.bi_db.gold_..._amlperiodicreview` | TABLE | synapse_dep | matched |
| 16 | `main.bi_db.gold_..._ltv_bi_actual` | TABLE | synapse_dep | matched |
| 17 | `main.bi_db.gold_..._aml_singapore_risk_classification` | TABLE | synapse_dep | matched |

**Detailed results**: See `BI_DB_CIDFirstDates.propagation-progress.json` and `BI_DB_CIDFirstDates.propagation-scope.md`.

## 5. Failures

Main ALTER: No failures. All 280 statements executed successfully.
Direct downstream: No failures. All 515 statements executed successfully.
Deep propagation: 157 of 504 failed (1 dropped view + permission-denied schemas). See Section 4b.

## 6. Phases Completed


| Phase                          | Status | Notes                                                                |
| ------------------------------ | ------ | -------------------------------------------------------------------- |
| 1. Structure Analysis          | DONE   | 139 columns, HASH(CID), CLUSTERED INDEX                              |
| 2. Live Data Sampling          | DONE   | ~45.6M rows, dates 2007–2026                                         |
| 3. Distribution Analysis       | DONE   | Batched GROUP BY for flags, enums, FKs                               |
| 4. Lookup Resolution           | DONE   | RegulationID, EvMatchStatus, CountryID, KycModeID resolved           |
| 5. JOIN Analysis               | DONE   | Via SP_CIDFirstDates (60.9 KB) — all JOINs extracted                 |
| 6. Business Logic Discovery    | DONE   | 9 business concepts documented                                       |
| 7. View Dependency Scan        | DONE   | No Synapse downstream views found                                    |
| 8. Procedure Reference Scan    | DONE   | SP_CIDFirstDates identified as sole writer                           |
| 9. Procedure Logic Extraction  | DONE   | Full SP parsed — column assignments, transforms, deprecated sections |
| 9B. ETL Orchestration Analysis | DONE   | Daily run, incremental INSERT/UPDATE/DELETE pattern                  |
| 10. Atlassian Knowledge Scan   | DONE   | BI Dictionary + CRM To Dataplatform pages found                      |
| 11. Generate Documentation     | DONE   | 5 files written, 795 ALTER statements executed                       |
| 12. Cross-Object Enrichment    | DONE   | 6 business concepts added to _semantic_index.md                      |
| 13. Production Lineage Mapping | DONE   | 11 production sources mapped                                         |
| 14. Query Advisory Metadata    | DONE   | Integrated into wiki Sections 3.1–3.4                                |


