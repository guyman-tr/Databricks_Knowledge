---
name: domain-compliance-and-aml
description: "Live AML alert layer + periodic-review queue + alert-rule catalogue. The LIVE alert routing is Synapse-only (BI_DB_AML_BI_Alerts_New is the live alert table with CategoryName='AML' predicate; BI_DB_AML_Daily_Alerts is the daily summary; BI_DB_RiskAlertManagementTool 165c is the cross-category alert review tool carrying AlertSeverityScore from Actimize CDD) — none of these three live in Databricks UC as of 2026-05-24, query via the Synapse MCP server user-synapse_prod_sql. The UC bridge is bi_db_amlperiodicreview (70c) which carries denormalized rollups (TotalAlerts, AlertsSummary, BIAMLAlerts, RiskAlertSummary, LatestRiskAlertDateReview, LatestBIAlertDate, AlertCategory) — sufficient for 'how many alerts' / 'when last alert' / 'periodic review due' but NOT sufficient for per-AlertID detail. The DC1-DC21 + OB6-OB20 alert rule catalogue lives in Confluence page 905216127 ('AML Monitoring Alerts Logic (Old logic)') — tagged Old logic but no replacement exists; cross-reference rule names against SELECT DISTINCT AlertCode FROM BI_DB_AML_BI_Alerts_New for the current production catalogue. Actimize SaaS computes the CDD score (200+ = high risk per Confluence 'CDD alert guidance: Client is PEP'); the score surfaces ONLY via BI_DB_RiskAlertManagementTool.AlertSeverityScore (synapse_only). Default to this skill for any 'which alerts fired' / 'periodic review queue' / 'AlertCode meaning' question; default to aml-risk-scoring for 'who is high-risk' / 'PEP_No_POA' / classification questions. The pii_data.aml_snapshotcustomer_enriched_v 54c is the PII-enriched analyst entry point that joins the periodic review back to customer state."
triggers:
  - AML alert
  - AML alerts
  - alert routing
  - alert review
  - alert category
  - AlertCode
  - AlertID
  - AlertCategory
  - AlertSeverityScore
  - AlertsSummary
  - BI_DB_AML_BI_Alerts_New
  - BI_DB_AML_Daily_Alerts
  - BI_DB_RiskAlertManagementTool
  - RiskAlertManagementTool
  - BI_DB_AMLPeriodicReview
  - bi_db_amlperiodicreview
  - aml_snapshotcustomer_enriched_v
  - periodic review
  - Review_Due_Date
  - Review_Due_DateID
  - DC1
  - DC2
  - DC3
  - DC4
  - DC5
  - DC6
  - DC7
  - DC8
  - DC9
  - DC10
  - DC11
  - DC21
  - OB6
  - OB7
  - OB8
  - OB20
  - DC alert
  - OB alert
  - Actimize
  - CDD risk score
  - CDD alert
  - Client is PEP
  - PEP alert
  - alert rule
  - alert catalogue
  - BIAMLAlerts
  - RiskAlertSummary
  - LatestRiskAlertDateReview
  - LatestBIAlertDate
  - TotalAlerts
  - TotalCheckAlerts
  - CheckAlertSummary
  - MaterialChangePII
  - MaterialChangeLogins
  - MaterialChangeMIMO
  - RoutineMonitoringRedFlagsHRC
  - SourceOfIncomeAlert
  - OccupationAlert
  - DeclaredIncomeANDAssetsAlert
  - PlannedInvestmentAlert
  - synapse only
  - Synapse-only AML
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
  - main.pii_data.aml_snapshotcustomer_enriched_v
external_references:
  - name: "BI_DB_dbo.BI_DB_AML_BI_Alerts_New"
    locality: synapse_only
    source_system: sql_dp_prod_we
    role: "Live AML alert table — one row per AML alert per CID per occurrence. Filter CategoryName='AML' for the AML scope (table is cross-category). The AlertCode column carries the rule ID (DC1-DC21, OB6-OB20, plus newer codes). NOT in UC."
    bridge_strategy: "Query via user-synapse_prod_sql MCP (read-only) or user-synapse_sql (write). The bridge to UC analytics is via bi_db_amlperiodicreview.BIAMLAlerts (denormalized alert summary per CID). Wiki at knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_BI_Alerts_New.md."
  - name: "BI_DB_dbo.BI_DB_AML_Daily_Alerts"
    locality: synapse_only
    source_system: sql_dp_prod_we
    role: "Daily AML alert summary aggregating BI_DB_AML_BI_Alerts_New to per-CID per-day grain. NOT in UC."
    bridge_strategy: "Query via user-synapse_prod_sql MCP. The bridge to UC analytics is via bi_db_amlperiodicreview.LatestBIAlertDate."
  - name: "BI_DB_dbo.BI_DB_RiskAlertManagementTool"
    locality: synapse_only
    source_system: sql_dp_prod_we
    role: "Cross-category alert management tool (filter CategoryName='AML' for AML scope). Carries the Actimize CDD output via AlertSeverityScore column. The operational review surface for the compliance ops team."
    bridge_strategy: "Query via user-synapse_prod_sql MCP. The bridge to UC analytics is via bi_db_amlperiodicreview.RiskAlertSummary + LatestRiskAlertDateReview. Surfaced as an AML anchor via Phase A.4 Tableau workbook fly-over (the Tableau workbook was the only Lake-side artifact that referenced this table)."
  - name: "DC1-DC21 + OB6-OB20 alert rule catalogue"
    locality: manual_only
    source_system: Confluence page 905216127 ('AML Monitoring Alerts Logic (Old logic)')
    role: "The catalogue of rule codes (DC = data-completeness style rules, OB = ongoing-behavior style rules) that produce today's AML alerts. The page is tagged '(Old logic)' but there is no replacement Confluence page; the rule logic lives in production stored procs."
    bridge_strategy: "Read the Confluence page for rule names + intent. Cross-reference against SELECT DISTINCT AlertCode, COUNT(*) FROM BI_DB_AML_BI_Alerts_New GROUP BY AlertCode (Synapse) for the current production catalogue. If a DC or OB code from the Old-logic page is not in the production distinct set, it has been retired. If a code is in the production set but not on the Old-logic page, it has been added since the page was tagged stale."
  - name: "Actimize CDD scoring engine"
    locality: external_system
    source_system: Actimize SaaS
    role: "Computes the AML CDD risk score (per Confluence 'CDD alert guidance: Client is PEP' page 12003442859: score 200+ = high risk; 100-199 = medium; 0-99 = low). The score is the AlertSeverityScore on BI_DB_RiskAlertManagementTool."
    bridge_strategy: "No direct data feed in UC. The Actimize score is surfaced downstream as BI_DB_RiskAlertManagementTool.AlertSeverityScore (synapse_only). For raw decisions + threshold settings, contact Compliance Eng for vendor portal access. The Confluence page is the only documentation of the score interpretation; treat it as authoritative for the threshold values."
sample_questions:
  - "Which AML alerts fired today / yesterday for CID X?"
  - "How many AML alerts were raised in the last 30 days by AlertCode?"
  - "Periodic AML review queue for next 30 days (Review_Due_Date filter)"
  - "Which customers are overdue for periodic AML review (Review_Due_DateID < today)?"
  - "What does AlertCode = 'DC4' mean? — pull from Confluence Old-logic page + cross-check against Synapse distinct AlertCode list"
  - "Customers with high Actimize CDD severity score (AlertSeverityScore >= 200)"
  - "Material-change alerts (MaterialChangePII / MaterialChangeLogins / MaterialChangeMIMO) per CID in the last 90 days"
  - "Routine monitoring red flags — outdated data / EP / HRC summary per CID"
  - "AlertsSummary breakdown for a single CID across the periodic-review queue"
  - "Reconcile per-CID alert count: bi_db_amlperiodicreview.TotalAlerts (UC) vs COUNT(*) on BI_DB_AML_BI_Alerts_New (Synapse) — should match"
  - "Source-of-income / occupation / planned-investment alerts on the periodic-review queue"
domain_tags:
  - compliance
  - aml
  - alerts
  - periodic-review
  - actimize
  - cdd
  - synapse-only
  - hybrid
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-24"
---

# AML Alert Routing

The live AML alert layer + periodic-review queue + alert-rule catalogue. **This sub-skill is the user-surfaced gap of the D super-domain: the operationally-critical alert routing tables live only in Synapse and require querying via the Synapse MCP server.** UC carries only the periodic-review queue (`bi_db_amlperiodicreview`, 70c) and the PII analyst view (`aml_snapshotcustomer_enriched_v`, 54c) as the UC entry points; everything else is `external_references` with explicit bridge strategies.

## When to Use

Load when the question concerns **which alerts fired** or **the periodic-review queue**, including:

- "Which AML alerts fired today / yesterday for CID X?" → Synapse `BI_DB_AML_BI_Alerts_New`
- "How many AML alerts last 30 days by AlertCode?" → Synapse `BI_DB_AML_BI_Alerts_New` / `BI_DB_AML_Daily_Alerts`
- "Periodic AML review queue for next 30 days" → UC `bi_db_amlperiodicreview` (no Synapse needed)
- "Customers overdue for periodic AML review" → UC `bi_db_amlperiodicreview.Review_Due_DateID`
- "What does AlertCode = 'DC4' mean?" → Confluence Old-logic page + Synapse `SELECT DISTINCT AlertCode`
- "Actimize CDD score threshold per CID" → Synapse `BI_DB_RiskAlertManagementTool.AlertSeverityScore`
- "Material-change alerts in last 90 days" → UC `bi_db_amlperiodicreview.MaterialChangePII/Logins/MIMO`
- "Routine-monitoring red flags per CID" → UC `bi_db_amlperiodicreview.RoutineMonitoringRedFlags*`

Do **not** load for:

- **Who is currently high-risk** (the classification itself) → [`aml-risk-scoring.md`](aml-risk-scoring.md)
- **PEP / sanctions screening decision** (the upstream check) → `B compliance-customer-snapshot-and-club` (planned v1.5)
- **RegTech regulator-facing risk** → [`aml-regtech-pipeline.md`](aml-regtech-pipeline.md)
- **FCA SAR submission output** → future spec 013-regulatory-reporting
- **Tribe Treezor audit envelopes** → `domain-cross/tribe-emoney-audit`

## Scope

In scope: live AML alert layer (BI_DB_AML_BI_Alerts_New, BI_DB_AML_Daily_Alerts, BI_DB_RiskAlertManagementTool — all synapse_only, documented in external_references); the UC bridge bi_db_amlperiodicreview (70c — periodic-review queue with TotalAlerts, AlertsSummary, BIAMLAlerts, RiskAlertSummary, AlertCategory, LatestRiskAlertDateReview, LatestBIAlertDate, Review_Due_Date, Review_Due_DateID, plus material-change + routine-monitoring + EP + economic-profile alert columns); the PII analyst view pii_data.aml_snapshotcustomer_enriched_v (54c, joins back to customer state); the DC1-DC21 + OB6-OB20 alert rule catalogue (Confluence Old-logic page, manual_only); the Actimize CDD scoring engine (external_system, surfacing via AlertSeverityScore on RiskAlertManagementTool); the documented threshold (200+ = high) per Confluence 12003442859 'CDD alert guidance: Client is PEP'.
Out of scope: the AML risk classification computation itself (aml-risk-scoring.md — cmp_aml + de_output_risk_classification stack), the RegTech parallel pipeline (aml-regtech-pipeline.md — keyed on PartyKey), KYC sanctions/PEP identity-side screening (B compliance-customer-snapshot-and-club planned v1.5), FCA SAR submission (bi_db_aml_sar_report_fca belongs to future spec 013), Tribe Treezor audit envelopes (domain-cross/tribe-emoney-audit), operator audit trail (B customer-action-audit-trail).
Last verified: 2026-05-24

## Critical Warnings

1. **Tier 1 — The LIVE alert layer is SYNAPSE-ONLY. A Databricks query alone CANNOT return per-alert detail.** `BI_DB_AML_BI_Alerts_New` (the table whose rows ARE the alerts), `BI_DB_AML_Daily_Alerts` (daily summary), and `BI_DB_RiskAlertManagementTool` (165c — the cross-category alert review tool carrying the Actimize `AlertSeverityScore`) are all in `sql_dp_prod_we` and **verified NOT in `system.information_schema.tables`** (Phase A.6 query, 2026-05-24). Trying to `SELECT * FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_bi_alerts_new` will fail with "table not found". Bridge strategy: query via the Synapse MCP server `user-synapse_prod_sql` (read-only) or `user-synapse_sql` (write). For the UC-only path, the rich UC bridge is `bi_db_amlperiodicreview` (70c) which carries denormalized rollups — see Pattern 1.

2. **Tier 1 — `bi_db_amlperiodicreview` is the UC analytics bridge — carries denormalized alert summaries per CID.** The 70-column periodic-review table answers: `TotalAlerts` (per-CID alert count across all categories), `BIAMLAlerts` (BI-side AML alert count), `RiskAlertSummary` (semicolon-delimited rollup), `LatestRiskAlertDateReview` (last alert date from `BI_DB_RiskAlertManagementTool`), `LatestBIAlertDate` (last alert date from `BI_DB_AML_BI_Alerts_New`), `AlertCategory` (broad category), `AlertsSummary` (text rollup of recent alerts), `CheckAlertSummary` + `TotalCheckAlerts`. **For "how many alerts" / "when was the last alert" / "who has open alerts" questions, this UC table is sufficient.** For per-AlertID / per-AlertCode detail, you MUST query Synapse — see Pattern 2.

3. **Tier 1 — The DC1-DC21 + OB6-OB20 alert rule catalogue is documented ONLY on a Confluence page tagged "(Old logic)".** Page `905216127` (`AML Monitoring Alerts Logic (Old logic)`) lists the historical rule catalogue. The Confluence tag is honest — the page is not current — but **no replacement Confluence page exists**. The current rule LOGIC lives in the Synapse stored procs (`BackOffice.SetRiskClassificationNew` family, manual_only in `aml-risk-scoring.md`'s external_references). To resolve "what does AlertCode = X mean": (a) look up `X` on the Old-logic page for the historical intent; (b) run `SELECT DISTINCT AlertCode, COUNT(*) FROM BI_DB_AML_BI_Alerts_New WHERE CategoryName = 'AML' GROUP BY AlertCode ORDER BY 2 DESC;` on Synapse for the current production catalogue; (c) codes on the Old-logic page but NOT in the production set are retired; (d) codes in the production set but NOT on the Old-logic page were added since the page was tagged stale (read the alert's row to infer intent, or escalate to Compliance Eng).

4. **Tier 1 — Actimize CDD score (`AlertSeverityScore`) thresholds are 200+ = High, 100-199 = Medium, 0-99 = Low.** Per Confluence page `12003442859` (`CDD alert guidance: Client is PEP`, current — not the WiP variant `12018122771`). The score is computed by Actimize SaaS (external_system) and ONLY surfaces in `BI_DB_RiskAlertManagementTool.AlertSeverityScore` (synapse_only). The thresholds are NOT data-derivable from UC — they live in the Confluence guidance. If a query needs "is this customer in Actimize-CDD High", the predicate is `AlertSeverityScore >= 200` against Synapse.

5. **Tier 2 — `bi_db_amlperiodicreview` key is `RealCID + Review_Due_DateID`, not `CID + etr_ymd`.** The table uses the DWH convention `RealCID INT` (same value as `CID` in cmp_aml — `CID = RealCID` everywhere in DWH facts) and the date is `Review_Due_Date` (`DATETIME`) plus `Review_Due_DateID` (`INT YYYYMMDD`). For periodic-review-queue questions: filter on `Review_Due_DateID BETWEEN :start AND :end`. For "last refresh" use `UpdateDate`.

6. **Tier 2 — `bi_db_amlperiodicreview.AlertsSummary` is text — a semicolon-delimited rollup, NOT a join-able list.** The same applies to `RiskAlertSummary`, `BIAMLAlerts`, `CheckAlertSummary`, `APU_Gaps_Summary`, `AlertCategory`. For "what alerts does CID X have" with structured detail, parse the text columns OR (preferred) query Synapse `BI_DB_AML_BI_Alerts_New WHERE RealCID = :cid` for the row-level evidence.

7. **Tier 2 — Material-change + routine-monitoring + economic-profile alerts have their own columns on `bi_db_amlperiodicreview`.** Material-change family: `MaterialChangePII`, `MaterialChangeLogins`, `MaterialChangeMIMO` (boolean / counts). Routine-monitoring red flags: `RoutineMonitoringRedFlagsOutdatedData`, `RoutineMonitoringRedFlagsEP` (economic profile), `RoutineMonitoringRedFlagsHRC` (high-risk-customer). Economic-profile: `SourceOfIncomeAlert`, `OccupationAlert`, `DeclaredIncomeANDAssetsAlert`, `PlannedInvestmentAlert`, `EconomicProfileReviewPending`, `EVReviewPending`. These are pre-aggregated boolean / count columns — query directly without joining to Synapse.

8. **Tier 2 — `main.pii_data.aml_snapshotcustomer_enriched_v` (54c PROD) is the canonical D-side analyst entry point — NOT to be confused with the similarly-named `main.pii_data_stg.gold_de_aml_snapshot_customer_enriched_v` (59c STAGING) used by sub-skill B `compliance-customer-snapshot-and-club`.** Verified against `main.information_schema.columns` 2026-05-25: these are TWO DIFFERENT views with different lineage. `pii_data.aml_snapshotcustomer_enriched_v` (PROD, 54c) is the AML-enriched analyst view — it builds population from `v_fact_snapshotcustomer_fromdateid_masked` + `dim_customer` and LEFT JOINs `de_output_risk_classification_history` (risk score), `fact_customeraction` (last action / last login), `bronze_etoro_backoffice_customerdocument` (POI/POA/Selfie/Income date), `bi_output_customer_customer_support_case` filtered to `ActionType LIKE '%AML%'` (last AML case), and `bronze_etoro_history_backofficecustomer` (AMLComment) + `bronze_etoro_backoffice_customer` (RiskComment). Use it for "show me customer X's AML state across classification + alerts + periodic-review-due + documents + cases". `pii_data_stg.gold_de_aml_snapshot_customer_enriched_v` (STAGING, 59c) is a different lineage — it joins `gold_de_aml_base_snapshotcustomer` + `gold_de_aml_current_attrs` + a `RegulationMapping` CASE expression, and is the table registered to the **"Customer AML Compliance Data" Genie space**. **There is NO `main.pii_data_stg.aml_snapshotcustomer_enriched_v`** — that name does not exist in UC (verified 2026-05-25). For D-scoped questions always use the PROD view; for snapshot-side B questions the staging view is the Genie-registered one.

9. **Tier 3 — `BI_DB_RiskAlertManagementTool` covers ALL categories — filter `CategoryName='AML'` for AML.** The 165-column table is cross-category (KYC, fraud, market manipulation, etc.). For AML-only views always filter `WHERE CategoryName = 'AML'`. Other category names include `'KYC'`, `'Fraud'`, `'Market'`, `'CDD'`. The Phase A.4 Tableau fly-over confirmed this is the canonical AML alert routing surface despite the generic table name.

10. **Tier 3 — Reconciling UC `bi_db_amlperiodicreview.TotalAlerts` against Synapse `BI_DB_AML_BI_Alerts_New` rowcount should match within ETL refresh tolerance.** If they diverge by more than expected staleness, suspect a refresh lag on the periodic-review pipeline (which materializes the rollup). The UC table is materialized via the `BackOffice.SetRiskClassificationNew` family writeback path (Synapse) → bronze ingestion → gold materialization, and lags Synapse by the bronze + gold cadence.

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **AlertCode** | Rule identifier on `BI_DB_AML_BI_Alerts_New` (DC1-DC21, OB6-OB20, plus newer codes). DC ≈ data-completeness; OB ≈ ongoing-behavior. The catalogue is the Confluence Old-logic page + the current Synapse `DISTINCT AlertCode` set. | rule code, alert rule, DC code, OB code |
| **AlertCategory** | Broad category (`'AML'`, `'KYC'`, `'Fraud'`, etc.) carried on both `BI_DB_AML_BI_Alerts_New.CategoryName` and `bi_db_amlperiodicreview.AlertCategory`. ALWAYS filter to `'AML'` for AML scope. | category, alert category |
| **AlertSeverityScore** | The Actimize CDD score (0-1000+ scale) on `BI_DB_RiskAlertManagementTool` (synapse_only). Thresholds: 0-99 = Low, 100-199 = Medium, 200+ = High (per Confluence 12003442859). | CDD score, Actimize score, severity score |
| **Periodic review queue** | Set of CIDs due for an AML compliance review; rows on `bi_db_amlperiodicreview` keyed on `RealCID + Review_Due_DateID`. Drives the compliance-ops team's daily workload. | review queue, AML review, periodic review |
| **AlertsSummary** | Semicolon-delimited text rollup of recent alerts per CID on `bi_db_amlperiodicreview`. Not join-able; for structured detail go to Synapse `BI_DB_AML_BI_Alerts_New`. | alert summary, summary column |
| **BIAMLAlerts** | Per-CID rollup of alerts originating from the BI-side AML pipeline (`BI_DB_AML_BI_Alerts_New`). Carried on `bi_db_amlperiodicreview`. | BI AML alerts, BI alert count |
| **Material change** | Alert family for changes in customer state — `MaterialChangePII` (personal info changed), `MaterialChangeLogins` (login pattern shift), `MaterialChangeMIMO` (money-in-money-out shift). | material change, change alert |
| **Routine monitoring red flag** | Periodic-review red-flag family — `Outdated Data`, `EP` (economic profile), `HRC` (high-risk customer). | red flag, monitoring flag, RMF |
| **Economic profile (EP) alert** | KYC-derived alerts on declared economic info: `SourceOfIncomeAlert`, `OccupationAlert`, `DeclaredIncomeANDAssetsAlert`, `PlannedInvestmentAlert`. The `EconomicProfileReviewPending` flag indicates the EP needs reverification. | EP alert, economic profile alert, declared-income alert |
| **EV (Enhanced Verification)** | Identity uplift workflow. `EVStatus`, `LastEVDate`, `EVReviewPending` — drives EV-track on the review queue. | enhanced verification, EV review |
| **Old-logic catalogue** | The DC1-DC21 + OB6-OB20 catalogue documented on Confluence `905216127` (tagged Old-logic, no replacement). Cross-reference against `SELECT DISTINCT AlertCode FROM BI_DB_AML_BI_Alerts_New`. | rule catalogue, alert rules, DC/OB rules |

## Query Patterns

### Pattern 1 — Periodic review queue for next N days (UC, no Synapse needed)

```sql
SELECT
  RealCID,
  Review_Due_Date,
  RiskClassification,
  Regulation,
  Club,
  PlayerStatus,
  TotalAlerts,
  AlertsSummary,
  BIAMLAlerts,
  LatestRiskAlertDateReview,
  LatestBIAlertDate,
  MaterialChangePII,
  MaterialChangeLogins,
  MaterialChangeMIMO,
  RoutineMonitoringRedFlagsHRC
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
WHERE Review_Due_DateID BETWEEN 20260524 AND 20260623
ORDER BY Review_Due_DateID, TotalAlerts DESC;
```

Use when: "periodic AML review queue for next 30 days", "who is due for review", "what alerts are tied to upcoming reviews".

### Pattern 2 — Per-AlertID detail (SYNAPSE, via user-synapse_prod_sql MCP)

```sql
-- Synapse — query via user-synapse_prod_sql MCP, NOT Databricks
SELECT
  RealCID,
  AlertID,
  AlertCode,
  CategoryName,
  AlertDate,
  AlertStatus,
  AlertDescription
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New
WHERE CategoryName = 'AML'
  AND AlertDate >= DATEADD(DAY, -7, GETDATE())
  AND RealCID = :cid
ORDER BY AlertDate DESC;
```

Use when: "which AML alerts fired for customer X in last 7 days with codes + descriptions", "row-level alert detail". Must run via Synapse MCP.

### Pattern 3 — Top firing alert codes last 30 days (SYNAPSE)

```sql
-- Synapse — query via user-synapse_prod_sql MCP
SELECT
  AlertCode,
  COUNT(*) AS alert_count,
  COUNT(DISTINCT RealCID) AS distinct_cids,
  MIN(AlertDate) AS first_seen,
  MAX(AlertDate) AS last_seen
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New
WHERE CategoryName = 'AML'
  AND AlertDate >= DATEADD(DAY, -30, GETDATE())
GROUP BY AlertCode
ORDER BY alert_count DESC;
```

Use when: "current alert rule activity catalogue", "which rules are firing most often", "is DC4 still active". Must run via Synapse MCP.

### Pattern 4 — Actimize CDD severity threshold (SYNAPSE, BI_DB_RiskAlertManagementTool)

```sql
-- Synapse — query via user-synapse_prod_sql MCP
SELECT
  RealCID,
  AlertID,
  AlertSeverityScore,
  CASE
    WHEN AlertSeverityScore >= 200 THEN 'High'
    WHEN AlertSeverityScore >= 100 THEN 'Medium'
    ELSE 'Low'
  END AS severity_band,
  AlertDate,
  AlertStatus
FROM BI_DB_dbo.BI_DB_RiskAlertManagementTool
WHERE CategoryName = 'AML'
  AND AlertDate >= DATEADD(DAY, -30, GETDATE())
  AND AlertSeverityScore >= 200
ORDER BY AlertSeverityScore DESC;
```

Use when: "high-severity Actimize CDD customers", "thresholds per Confluence 12003442859". Must run via Synapse MCP.

### Pattern 5 — Cross-join UC scoring + UC alert summary (no Synapse)

```sql
SELECT
  s.CID,
  s.Dynamic_Risk_Classification,
  s.Is_PEP,
  s.Is_Sanctions_Match,
  s.High_Risk_AND_No_POI,
  s.PEP_No_POA,
  p.TotalAlerts,
  p.AlertsSummary,
  p.RiskAlertSummary,
  p.LatestBIAlertDate,
  p.Review_Due_Date,
  p.MaterialChangePII,
  p.MaterialChangeLogins
FROM main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level s
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview p
  ON s.CID = p.RealCID
WHERE s.etr_ymd = '2026-05-23'
  AND s.Is_High_Risk = 1;
```

Use when: "show me High_Risk customers with their current alert summary + review-due date", "rollup of risk-score evidence + alert state in one row". Pure UC — no Synapse needed.

### Pattern 6 — Material-change + routine-monitoring red flag count

```sql
SELECT
  Regulation,
  Club,
  COUNT(*) FILTER (WHERE MaterialChangePII = 1)              AS pii_change,
  COUNT(*) FILTER (WHERE MaterialChangeLogins = 1)           AS logins_change,
  COUNT(*) FILTER (WHERE MaterialChangeMIMO = 1)             AS mimo_change,
  COUNT(*) FILTER (WHERE RoutineMonitoringRedFlagsOutdatedData = 1) AS outdated_data,
  COUNT(*) FILTER (WHERE RoutineMonitoringRedFlagsEP = 1)    AS ep_flag,
  COUNT(*) FILTER (WHERE RoutineMonitoringRedFlagsHRC = 1)   AS hrc_flag
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
GROUP BY Regulation, Club
ORDER BY Regulation, Club;
```

Use when: "which customers have material-change or routine-monitoring red flags", "RMF breakdown by regulator + club".

## External Data Sources

> **Locality caveat.** Three of the four most operationally-critical objects in this skill live ONLY in Synapse. A default Databricks notebook query will NOT return them. Use the bridge strategies below.

| Object | Locality | Source system | Role | Bridge strategy |
|---|---|---|---|---|
| `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` | `synapse_only` | `sql_dp_prod_we` | Live AML alert table — one row per alert per CID per occurrence. Filter `CategoryName='AML'`. AlertCode column carries the rule ID. | Query via the Synapse MCP server `user-synapse_prod_sql` (read-only) or `user-synapse_sql` (write). The UC analytics bridge is `bi_db_amlperiodicreview.BIAMLAlerts` (denormalized per-CID rollup) + `LatestBIAlertDate`. |
| `BI_DB_dbo.BI_DB_AML_Daily_Alerts` | `synapse_only` | `sql_dp_prod_we` | Daily aggregate of `BI_DB_AML_BI_Alerts_New` to per-CID per-day grain. | Query via `user-synapse_prod_sql` MCP. The UC analytics bridge is `bi_db_amlperiodicreview.LatestBIAlertDate`. |
| `BI_DB_dbo.BI_DB_RiskAlertManagementTool` | `synapse_only` | `sql_dp_prod_we` | Cross-category alert management tool — the operational review surface. Filter `CategoryName='AML'` for AML scope. `AlertSeverityScore` carries the Actimize CDD output. | Query via `user-synapse_prod_sql` MCP. The UC analytics bridge is `bi_db_amlperiodicreview.RiskAlertSummary` + `LatestRiskAlertDateReview`. |
| DC1-DC21 + OB6-OB20 alert rule catalogue | `manual_only` | Confluence page 905216127 | The catalogue of rule codes that produce today's AML alerts. Tagged "(Old logic)" but no replacement Confluence page exists. | Read the Confluence page for rule names + intent. Cross-reference against Synapse `SELECT DISTINCT AlertCode FROM BI_DB_AML_BI_Alerts_New WHERE CategoryName='AML'` for the current production set. See Critical Warning 3. |
| Actimize CDD scoring engine | `external_system` | Actimize SaaS | Computes the AML CDD risk score per customer event. Thresholds (per Confluence 12003442859): 0-99 Low, 100-199 Medium, 200+ High. | No direct UC feed. The score surfaces ONLY via `BI_DB_RiskAlertManagementTool.AlertSeverityScore` (synapse_only). For raw decisions + threshold-setting metadata, request access from the Compliance Eng team. See Critical Warning 4. |

> **The Actimize CDD threshold values are NOT data-derivable from UC.** They are documented only on the Confluence guidance page `12003442859`. Treat the page as authoritative for threshold values; if Compliance Eng has updated thresholds, the page should reflect them — confirm before quoting numbers.

> **The DC/OB rule catalogue is doc-debt.** Compliance Eng has not produced a current-version Confluence page replacing the Old-logic catalogue. When in doubt about a specific AlertCode's meaning, the production source-of-truth is the SP body in `BackOffice.SetRiskClassificationNew` (Synapse) — read it via the wiki path at `knowledge/synapse/Wiki/...`.

## Sources Consulted

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | L | 1 | UC `information_schema.columns` (70 cols verified 2026-05-24) | The UC bridge |
| `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` | S | 1 | wiki at `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_BI_Alerts_New.md` | Live alert table; UC absence confirmed 2026-05-24 |
| `BI_DB_dbo.BI_DB_RiskAlertManagementTool` | S | 1 | wiki + Phase A.4 Tableau fly-over `_compliance_tableau_flyover.md` | Cross-category, filter `CategoryName='AML'` |
| Confluence page 905216127 (Old logic) | S | 5 | `knowledge/confluence/_corpus/compliance/905216127.json` | DC/OB rule catalogue, tagged stale, no replacement |
| Confluence page 12003442859 (CDD alert guidance) | S | 3 | `knowledge/confluence/_corpus/compliance/12003442859.json` | Actimize threshold documentation; canonical for thresholds |
| Phase A.6 locality | - | - | `knowledge/skills/_compliance_staleness.md` §6.1 | The three synapse_only confirmations |
