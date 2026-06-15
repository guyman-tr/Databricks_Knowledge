# Column Lineage: main.etoro_kpi.crm_csat_survey_per_case_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.crm_csat_survey_per_case_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\crm_csat_survey_per_case_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\crm_csat_survey_per_case_v.json` (rows: 4, mismatches: 4) |
| **Primary upstream** | `main.crm.silver_crm_csat_survey_entry__c` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.crm.silver_crm_csat_survey_entry__c` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.crm.silver_crm_csat_survey_entry__c   ←── primary upstream
        │
        ▼
main.etoro_kpi.crm_csat_survey_per_case_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Id` | `main.crm.silver_crm_csat_survey_entry__c` | `Id` | `passthrough` | — | Id |
| 2 | `cSAT_Date` | `main.crm.silver_crm_csat_survey_entry__c` | `cSAT_Date` | `passthrough` | — | cSAT_Date |
| 3 | `simplesurvey__Case__c` | `main.crm.silver_crm_csat_survey_entry__c` | `simplesurvey__Case__c` | `passthrough` | — | simplesurvey__Case__c |
| 4 | `simplesurvey__Survey_Score__c` | `main.crm.silver_crm_csat_survey_entry__c` | `simplesurvey__Survey_Score__c` | `passthrough` | — | simplesurvey__Survey_Score__c |

## Cross-check vs system.access.column_lineage

- Total target columns: **4**
- OK: **0**, WARN: **4**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Id` | `main.crm.silver_crm_csat_survey_entry__c.id` | `main.crm.silver_crm_csat_survey_entry__c.id`, `main.crm.silver_crm_medallia_xm__medallia_feedback__c.id` | WARN |
| `cSAT_Date` | `main.crm.silver_crm_csat_survey_entry__c.csat_date` | `main.crm.silver_crm_csat_survey_entry__c.createddate`, `main.crm.silver_crm_medallia_xm__medallia_feedback__c.createddate` | WARN |
| `simplesurvey__Case__c` | `main.crm.silver_crm_csat_survey_entry__c.simplesurvey__case__c` | `main.crm.silver_crm_csat_survey_entry__c.case__c`, `main.crm.silver_crm_medallia_xm__medallia_feedback__c.medallia_xm__original_case_number__c` | WARN |
| `simplesurvey__Survey_Score__c` | `main.crm.silver_crm_csat_survey_entry__c.simplesurvey__survey_score__c` | `main.crm.silver_crm_csat_survey_entry__c.agent_service_numvalue__c`, `main.crm.silver_crm_medallia_xm__medallia_feedback__c.csat_score__c` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **0**
