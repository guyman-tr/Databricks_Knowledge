# Column Lineage: main.etoro_kpi.crm_quality_assessment_per_case_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.crm_quality_assessment_per_case_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\crm_quality_assessment_per_case_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\crm_quality_assessment_per_case_v.json` (rows: 8, mismatches: 0) |
| **Primary upstream** | `main.crm.silver_crm_surveytaker__c` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.crm.silver_crm_surveytaker__c` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.crm.silver_crm_surveytaker__c   ←── primary upstream
        │
        ▼
main.etoro_kpi.crm_quality_assessment_per_case_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Case__c` | `main.crm.silver_crm_surveytaker__c` | `Case__c` | `passthrough` | — | Case__c |
| 2 | `Survey__c` | `main.crm.silver_crm_surveytaker__c` | `Survey__c` | `passthrough` | — | Survey__c |
| 3 | `Agent_Under_Assessment__c` | `main.crm.silver_crm_surveytaker__c` | `Agent_Under_Assessment__c` | `passthrough` | — | Agent_Under_Assessment__c |
| 4 | `Quality_Score__c` | `main.crm.silver_crm_surveytaker__c` | `Quality_Score__c` | `passthrough` | — | Quality_Score__c |
| 5 | `Compliance_a__c` | `main.crm.silver_crm_surveytaker__c` | `Compliance_a__c` | `passthrough` | — | Compliance_a__c |
| 6 | `Type_of_Communication__c` | `main.crm.silver_crm_surveytaker__c` | `Type_of_Communication__c` | `passthrough` | — | Type_of_Communication__c |
| 7 | `Team__c` | `main.crm.silver_crm_surveytaker__c` | `Team__c` | `passthrough` | — | Team__c |
| 8 | `CreatedDate` | `main.crm.silver_crm_surveytaker__c` | `CreatedDate` | `passthrough` | — | CreatedDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **8**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
