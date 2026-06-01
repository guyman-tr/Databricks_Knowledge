---
name: domain-compliance-and-aml
description: "The parallel RegTech AML pipeline — 20 UC-native tables owned by the RegTech team under main.regtech.gold_regtech_aml_* (10 tables) + main.regtech.gold_regreportdb_prod_dbo_aml_* (10 tables). The serving layer is regtech_aml_api_riskscore 7c (API-facing risk score keyed on All_CDD_Parties_PARTY_KEY + All_CDD_Parties_RECORD_DATE) and regtech_aml_aml_riskscore_scd 6c (SCD-2 snapshot of risk level per PartyKey with StartDate/EndDate validity windows). The customer dimension is regtech_aml_population 39c keyed on CID + GCID + PartyKey-via-gen_key (the bridge to the cmp_aml family from aml-risk-scoring.md). Address / relationship / activity dimensions: partyaddress 20c, partytopartyrelation 8c, periodicactivityexpected 9c. Reference dictionaries: dict_regulation_aml 10c (regulator names), gen_key 13c (the CID↔PartyKey translation), transaction_currency 2c. Operational: run_log 8c. The RegReportDB-side feeds the regulator submission system with 10 *_history tables (account_history 31c, ballance_history 11c [sic - regtech misspelling], dnb_report 32c + dnb_report_agg 13c, party_history 39c, party_toaccount_relation_history 13c, partyaddress_history 22c, periodic_activity_expected_history 11c, riskscore_scd 6c, service_history 13c). The 'aml_' name prefix is universal in this family. ZERO Confluence documentation exists for the entire family (42+ GAP-CONF flag from Phase A.5c) — THIS SKILL IS THE DOCUMENTATION. Identifier convention: PartyKey is RegReportDB's customer key, NOT eToro's CID; bridge via regtech_aml_population.CID OR regtech_aml_gen_key. Default to api_riskscore for 'current API-facing AML risk per customer' / aml_riskscore_scd for 'risk-level history per PartyKey' / population for 'customer-dimensional context'."
triggers:
  - regtech
  - regtech_aml
  - regtech.gold_regtech_aml
  - regreportdb
  - gold_regreportdb_prod_dbo_aml
  - aml_riskscore_scd
  - api_riskscore
  - regtech_aml_population
  - regtech_aml_partyaddress
  - regtech_aml_partytopartyrelation
  - regtech_aml_periodicactivityexpected
  - regtech_aml_dict_regulation_aml
  - regtech_aml_gen_key
  - regtech_aml_run_log
  - regtech_aml_transaction_currency
  - aml_account_history
  - aml_ballance_history
  - aml_dnb_report
  - aml_dnb_report_agg
  - aml_party_history
  - aml_party_toaccount_relation_history
  - aml_partyaddress_history
  - aml_periodic_activity_expected_history
  - aml_service_history
  - PartyKey
  - PARTY_KEY
  - RECORD_DATE
  - RISK_LEVEL
  - RiskLevel
  - StartDate
  - EndDate
  - Aml_Row_UpdateDate
  - RegulationID
  - PlayerLevelID
  - CitizenshipCountryID
  - regulator submission
  - regulator AML
  - RegTech AML
  - DNB report
  - Do No Business
required_tables:
  - main.regtech.gold_regtech_aml_api_riskscore
  - main.regtech.gold_regtech_aml_aml_riskscore_scd
  - main.regtech.gold_regtech_aml_population
  - main.regtech.gold_regtech_aml_partyaddress
  - main.regtech.gold_regtech_aml_partytopartyrelation
  - main.regtech.gold_regtech_aml_periodicactivityexpected
  - main.regtech.gold_regtech_aml_dict_regulation_aml
  - main.regtech.gold_regtech_aml_gen_key
  - main.regtech.gold_regtech_aml_run_log
  - main.regtech.gold_regtech_aml_transaction_currency
  - main.regtech.gold_regreportdb_prod_dbo_aml_account_history
  - main.regtech.gold_regreportdb_prod_dbo_aml_ballance_history
  - main.regtech.gold_regreportdb_prod_dbo_aml_dnb_report
  - main.regtech.gold_regreportdb_prod_dbo_aml_dnb_report_agg
  - main.regtech.gold_regreportdb_prod_dbo_aml_party_history
  - main.regtech.gold_regreportdb_prod_dbo_aml_party_toaccount_relation_history
  - main.regtech.gold_regreportdb_prod_dbo_aml_partyaddress_history
  - main.regtech.gold_regreportdb_prod_dbo_aml_periodic_activity_expected_history
  - main.regtech.gold_regreportdb_prod_dbo_aml_riskscore_scd
  - main.regtech.gold_regreportdb_prod_dbo_aml_service_history
sample_questions:
  - "Current API-facing AML risk level per customer (api_riskscore)"
  - "Time-series of risk level for PartyKey X (aml_riskscore_scd SCD-2 walk)"
  - "RegTech AML population on date D — how many active customers in scope?"
  - "Translate CID 12345 → PartyKey via gen_key"
  - "Per-regulator risk level distribution (join api_riskscore to dict_regulation_aml + regulation column on population)"
  - "DNB report — which customers are on the Do-No-Business list right now?"
  - "Party-to-party relationship graph for PartyKey X"
  - "Run log — when did the last RegTech AML pipeline run, was it successful?"
  - "Account-history snapshot for PartyKey X over Q this year"
  - "Reconcile cmp_aml Dynamic_Risk_Classification ('High') vs aml_riskscore_scd.RiskLevel for the same customer (via gen_key bridge)"
domain_tags:
  - compliance
  - aml
  - regtech
  - reg-reporting
  - party-key
  - scd-2
  - api-riskscore
  - dnb
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-24"
---

# AML RegTech Pipeline

The parallel RegTech AML pipeline. 20 UC-native tables, **zero Confluence documentation** (Phase A.5c flagged the entire family as `GAP-CONF` — the only documentation that exists is this skill). Uses RegReportDB identifier conventions (`PartyKey`) — a separate key family from the cmp_aml + DWH conventions (`CID` / `GCID` / `RealCID`).

## When to Use

Load when the question concerns the **RegTech AML pipeline**, including:

- "Current API-facing AML risk level per customer" → `regtech_aml_api_riskscore`
- "Time-series risk level for PartyKey X" → `regtech_aml_aml_riskscore_scd` (SCD-2 walk)
- "RegTech AML population on date D" → `regtech_aml_population`
- "Translate CID 12345 → PartyKey" → `regtech_aml_gen_key`
- "Per-regulator AML risk distribution" → `dict_regulation_aml` + `population`
- "Customers on the Do-No-Business (DNB) list" → `gold_regreportdb_prod_dbo_aml_dnb_report`
- "Account-history time-series for PartyKey X" → `aml_account_history`
- "RegTech run log — last successful run" → `regtech_aml_run_log`
- Any query referencing `PartyKey`, `PARTY_KEY`, `RECORD_DATE`, `RISK_LEVEL`, RegReportDB naming, or `aml_*_history` tables

Do **not** load for:

- **Customer-side AML risk classification** (the cmp_aml + de_output stack — keyed on `CID`/`GCID`) → [`aml-risk-scoring.md`](aml-risk-scoring.md)
- **Live alerts that fired** → [`aml-alert-routing.md`](aml-alert-routing.md)
- **Regulator submission OUTPUT** (the actual file delivered to FCA / MAS / CySEC) → future spec 013-regulatory-reporting. The RegTech tables here are the SOURCE; the submission output is a separate stage.

## Scope

In scope: the full 20-table RegTech AML family — 10 tables under `main.regtech.gold_regtech_aml_*` (api_riskscore 7c, aml_riskscore_scd 6c, population 39c, partyaddress 20c, partytopartyrelation 8c, periodicactivityexpected 9c, dict_regulation_aml 10c, gen_key 13c, run_log 8c, transaction_currency 2c) + 10 tables under `main.regtech.gold_regreportdb_prod_dbo_aml_*` (account_history 31c, ballance_history 11c [sic — RegReportDB misspelling], dnb_report 32c, dnb_report_agg 13c, party_history 39c, party_toaccount_relation_history 13c, partyaddress_history 22c, periodic_activity_expected_history 11c, riskscore_scd 6c, service_history 13c).
Out of scope: customer-side classification (aml-risk-scoring.md), live alerts (aml-alert-routing.md), regulator submission output (future spec 013), the cmp_aml + de_output stack (aml-risk-scoring.md), KYC sanctions/PEP screening (B compliance-customer-snapshot-and-club planned v1.5), Tribe Treezor envelopes (domain-cross/tribe-emoney-audit).
Last verified: 2026-05-24

## Critical Warnings

1. **Tier 1 — `PartyKey` is NOT `CID`. Use `regtech_aml_gen_key` (or `regtech_aml_population.CID`) as the bridge.** RegReportDB uses its own customer key family. The bridge table `regtech_aml_gen_key` (13c) maps eToro `CID` ↔ RegTech `PartyKey`. Cross-referencing into the cmp_aml family from `aml-risk-scoring.md` requires this translation. NEVER assume `PartyKey = CID`; verify via `gen_key` first.

2. **Tier 1 — `aml_riskscore_scd` is SCD-2: walk by date-range, NOT by latest-snapshot.** The 6-column table has `PartyKey`, `RiskLevel`, `StartDate`, `EndDate`, `CreateDate`, `Aml_Row_UpdateDate`. For "risk level on date D" use `WHERE :d BETWEEN StartDate AND COALESCE(EndDate, '9999-12-31')`. For "current" risk level use `WHERE EndDate IS NULL`. **Do NOT use `Aml_Row_UpdateDate` as the validity boundary** — that's the last system update timestamp, not the business validity.

3. **Tier 1 — `api_riskscore` uses ALL_CAPS namespaced columns from the API contract.** The 7-column table has `All_CDD_Parties_PARTY_KEY`, `All_CDD_Parties_RECORD_DATE`, `All_CDD_Parties_RISK_LEVEL`, plus `path` (source-file path) + `etr_y`/`etr_ym`/`etr_ymd` partitions. The `RISK_LEVEL` values are enum strings from the regulator API contract (NOT the same as cmp_aml's `'High'`/`'Medium'`/`'Low'`). When comparing to cmp_aml, MAP the enum first — the values are not always identical.

4. **Tier 2 — `etr_ymd` is the partition on `regtech_aml_*` tables (where present).** Same convention as cmp_aml + de_output: filter with `WHERE etr_ymd = '...'` for partition pruning. Note: the `gold_regreportdb_prod_dbo_aml_*_history` tables follow a different convention — they are SCD-style and use `StartDate` / `EndDate` (or table-specific dates) instead.

5. **Tier 2 — The 10 `aml_*_history` tables are SCD-style. The 10 `regtech_aml_*` tables are mostly current-state with daily partitions.** The mental split:
   - `regtech_aml_*` (no `_history` suffix): API/service-layer current state, partitioned by `etr_ymd`.
   - `gold_regreportdb_prod_dbo_aml_*_history`: SCD-2 history feeding the regulator submission. Use SCD walks (`StartDate`/`EndDate`).
   - Exception: `regtech_aml_aml_riskscore_scd` IS SCD-2 despite the `regtech_aml_*` prefix — the table name's `_scd` suffix is honest.

6. **Tier 2 — `regtech_aml_population.RiskClassificationID` is the RegTech-side risk classification ID, NOT the same enum as `cmp_aml.Dynamic_Risk_Classification`.** The 39-column population table has `RiskClassificationID`, `PlayerStatusID`, `RegulationID`, `CountryID`, `CitizenshipCountryID`, `POBCountryID` — all foreign keys into RegTech dictionaries (`dict_regulation_aml`, etc.). For cross-referencing into the cmp_aml family, join via `population.CID = cmp_aml_risk_classification_cid_level.CID` (after Bridge in Critical Warning 1), then compare both risk classifications side by side.

7. **Tier 2 — The `dnb_report` (32c) + `dnb_report_agg` (13c) pair carries the Do-No-Business list.** Customers flagged for business cessation — separate semantics from "high-risk" classification. Filter customers by joining `population.PartyKey` ↔ `dnb_report.PartyKey` (after the bridge).

8. **Tier 3 — RegTech is RegTech-team owned. The DataPlatform team does NOT control the column schema or refresh cadence.** If column meanings are unclear, escalate to the RegTech team rather than inferring from cmp_aml conventions. The schema differs from cmp_aml (`Dynamic_Risk_Classification` text-enum vs `RiskLevel` foreign-key + SCD-2; `CID` vs `PartyKey`; `etr_ymd` partitions vs SCD validity windows) — DO NOT assume the patterns transfer.

9. **Tier 3 — Run-log first. The `regtech_aml_run_log` (8c) records pipeline run status — query it before trusting the latest partition.** Columns include run ID, start/end timestamps, status. A failed last run means the latest `etr_ymd` partition may be incomplete. Pattern: `SELECT * FROM main.regtech.gold_regtech_aml_run_log ORDER BY <timestamp> DESC LIMIT 5;` before any analyst query.

10. **Tier 3 — `aml_ballance_history` is misspelled (should be `balance_history`).** Honor the misspelling exactly when referencing the table — it's the RegReportDB-side source name. Do NOT autocorrect to `balance`.

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **PartyKey** | RegReportDB's customer identifier (NOT eToro `CID`). Bridge: `regtech_aml_gen_key` or `regtech_aml_population.CID`. | PARTY_KEY, regulator party ID |
| **RiskLevel** | The RegTech risk classification value on `aml_riskscore_scd` + `api_riskscore.All_CDD_Parties_RISK_LEVEL`. Enum from the regulator API contract — NOT identical to cmp_aml's `'High'`/`'Medium'`/`'Low'`. | RISK_LEVEL, regtech risk level |
| **SCD-2 walk** | `aml_riskscore_scd` validity is `StartDate ≤ :d < EndDate` (or `EndDate IS NULL` for current). | SCD walk, time-validity walk |
| **api_riskscore** | API-facing serving table — current risk level per PartyKey + RECORD_DATE for downstream consumers. ALL_CAPS namespaced columns. | api risk score, API risk |
| **gen_key** | The CID ↔ PartyKey translation table. 13 cols, includes the eToro-side keys + the RegReportDB-side PartyKey. | key map, CID-PartyKey bridge |
| **DNB (Do-No-Business)** | Customers flagged for business cessation. Captured on `aml_dnb_report` + `aml_dnb_report_agg`. | Do-No-Business, DNB list |
| **dict_regulation_aml** | Dictionary mapping `RegulationID` (numeric) → `Name` / `AmlName` (text). | regulator dictionary |
| **Population table** | `regtech_aml_population` — customer-dimensional context (KYC fields, country, regulator, account type, player status) keyed on `CID + GCID`. | regtech population, customer dim |
| **`_history` tables** | RegReportDB-side SCD-2 history tables (account / balance / party / address / service / DNB / periodic-activity). Feed the regulator submission. | history table, SCD history |
| **Aml_Row_UpdateDate** | System-update timestamp on `aml_riskscore_scd`. NOT a business-validity boundary. | row update date |

## Query Patterns

### Pattern 1 — Current API-facing risk per customer (current snapshot)

```sql
SELECT
  All_CDD_Parties_PARTY_KEY  AS party_key,
  All_CDD_Parties_RECORD_DATE AS record_date,
  All_CDD_Parties_RISK_LEVEL  AS risk_level,
  path
FROM main.regtech.gold_regtech_aml_api_riskscore
WHERE etr_ymd = '2026-05-23';
```

Use when: "current API-facing AML risk per PartyKey", "what does the regulator submission see right now".

### Pattern 2 — Risk-level time-series for one PartyKey (SCD-2 walk)

```sql
SELECT
  PartyKey,
  RiskLevel,
  StartDate,
  EndDate,
  CreateDate,
  Aml_Row_UpdateDate
FROM main.regtech.gold_regtech_aml_aml_riskscore_scd
WHERE PartyKey = :party_key
ORDER BY StartDate;
```

Use when: "time-series of risk level for PartyKey X", "when did this customer change risk level". Filter on `EndDate IS NULL` for current state.

### Pattern 3 — Per-regulator risk distribution

```sql
SELECT
  d.Name AS regulator,
  p.RegulationID,
  s.RiskLevel,
  COUNT(*) AS customer_count
FROM main.regtech.gold_regtech_aml_population p
JOIN main.regtech.gold_regtech_aml_aml_riskscore_scd s
  ON s.PartyKey = (SELECT PartyKey FROM main.regtech.gold_regtech_aml_gen_key g WHERE g.CID = p.CID LIMIT 1)
  AND s.EndDate IS NULL
LEFT JOIN main.regtech.gold_regtech_aml_dict_regulation_aml d
  ON d.RecID = p.RegulationID
WHERE p.IsActive = 1
  AND p.etr_ymd = '2026-05-23'
GROUP BY d.Name, p.RegulationID, s.RiskLevel
ORDER BY regulator, customer_count DESC;
```

Use when: "AML risk distribution per regulator", "how many High-Risk customers per regulator on date D". Adjust the `gen_key` join shape to your environment's exact column names.

### Pattern 4 — DNB (Do-No-Business) list right now

```sql
SELECT
  d.PartyKey,
  d.*  -- 32 cols, use SELECT * for forensic queries; trim for production
FROM main.regtech.gold_regreportdb_prod_dbo_aml_dnb_report d
WHERE d.StartDate <= CURRENT_DATE
  AND (d.EndDate IS NULL OR d.EndDate > CURRENT_DATE);
```

Use when: "who is on the Do-No-Business list right now", "DNB compliance status per PartyKey".

### Pattern 5 — Run log last 5 runs (always check before trusting latest partition)

```sql
SELECT *
FROM main.regtech.gold_regtech_aml_run_log
ORDER BY CreateDate DESC
LIMIT 5;
```

Use when: any query begins. Check the last run's status — a failed last run means the latest `etr_ymd` partition is incomplete.

### Pattern 6 — Reconcile cmp_aml + RegTech for the same customer (cross-pipeline)

```sql
SELECT
  c.CID,
  c.GCID,
  c.Dynamic_Risk_Classification AS cmp_aml_classification,
  s.PartyKey,
  s.RiskLevel AS regtech_risk_level,
  s.StartDate AS regtech_start,
  s.EndDate   AS regtech_end
FROM main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level c
LEFT JOIN main.regtech.gold_regtech_aml_gen_key g
  ON g.CID = c.CID
LEFT JOIN main.regtech.gold_regtech_aml_aml_riskscore_scd s
  ON s.PartyKey = g.PartyKey
  AND s.EndDate IS NULL
WHERE c.etr_ymd = '2026-05-23'
  AND c.CID = :cid;
```

Use when: "compare cmp_aml classification to RegTech risk level for customer X", "reconcile the two pipelines". Expect occasional divergence — different schedules + different enum mappings.

## Sources Consulted

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| `main.regtech.gold_regtech_aml_api_riskscore` | L | 1 | UC `information_schema.columns` (7 cols verified 2026-05-24) | API serving layer |
| `main.regtech.gold_regtech_aml_aml_riskscore_scd` | L | 1 | UC `information_schema.columns` (6 cols verified) | SCD-2 risk-level history |
| `main.regtech.gold_regtech_aml_population` | L | 1 | UC `information_schema.columns` (39 cols verified) | Customer dimensional context |
| `main.regtech.gold_regreportdb_prod_dbo_aml_*` (10 tables) | L | 1 | UC `information_schema.columns` (per-table column counts verified) | RegReportDB-side history feeding regulator submission |
| Phase A.3 Genie subgraph | - | 2 | `knowledge/skills/_compliance_subgraph.md` | RegTech tables surfaced as GAP via the Genie-seeded subgraph (zero Confluence) |
| Phase A.5c staleness | - | - | `knowledge/skills/_compliance_staleness.md` §2 | 20-table `GAP-CONF` annotation; THIS SKILL IS THE DOCUMENTATION |
| Phase A.6 locality | - | - | `_compliance_staleness.md` §6.2 | All 20 tables confirmed UC-native |
