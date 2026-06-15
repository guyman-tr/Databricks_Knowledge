# Column Lineage: main.etoro_kpi.ftd_funnel_kyc

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ftd_funnel_kyc` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ftd_funnel_kyc.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ftd_funnel_kyc.json` (rows: 3, mismatches: 2) |
| **Primary upstream** | `main.compliance.bronze_userapidb_kyc_customeranswers` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.compliance.bronze_userapidb_kyc_customeranswers` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CustomerAnswers.md` |

## Lineage Chain

```
main.compliance.bronze_userapidb_kyc_customeranswers   ←── primary upstream
        │
        ▼
main.etoro_kpi.ftd_funnel_kyc   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `main.compliance.bronze_userapidb_kyc_customeranswers` | `GCID` | `passthrough` | — | GCID |
| 2 | `First_KYC_Answer` | `main.compliance.bronze_userapidb_kyc_customeranswers` | `—` | `aggregate` | — | MIN(OccurredAt) AS First_KYC_Answer |
| 3 | `Last_KYC_Answer` | `main.compliance.bronze_userapidb_kyc_customeranswers` | `—` | `aggregate` | — | MAX(OccurredAt) AS Last_KYC_Answer |

## Cross-check vs system.access.column_lineage

- Total target columns: **3**
- OK: **1**, WARN: **0**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `First_KYC_Answer` | — | `main.compliance.bronze_userapidb_kyc_customeranswers.occurredat` | ERROR |
| `Last_KYC_Answer` | — | `main.compliance.bronze_userapidb_kyc_customeranswers.occurredat` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
