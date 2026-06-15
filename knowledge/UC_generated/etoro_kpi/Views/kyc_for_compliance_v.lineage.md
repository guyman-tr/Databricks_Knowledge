# Column Lineage: main.etoro_kpi.kyc_for_compliance_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.kyc_for_compliance_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\kyc_for_compliance_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\kyc_for_compliance_v.json` (rows: 8, mismatches: 4) |
| **Primary upstream** | `main.general.bronze_etoro_customer_customer_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.compliance.bronze_userapidb_kyc_answers` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Answers.md` |
| `main.general.bronze_etoro_customer_customer_masked` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |
| `main.compliance.bronze_userapidb_history_customeranswers` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/History/Tables/History.CustomerAnswers.md` |
| `main.compliance.bronze_userapidb_kyc_questions` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.Questions.md` |

## Lineage Chain

```
main.general.bronze_etoro_customer_customer_masked   ←── primary upstream
  + main.compliance.bronze_userapidb_kyc_questions   (JOIN)
  + main.compliance.bronze_userapidb_kyc_answers   (JOIN)
  + main.compliance.bronze_userapidb_history_customeranswers   (JOIN)
        │
        ▼
main.etoro_kpi.kyc_for_compliance_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `—` | `GCID` | `join_enriched` | — | aa.GCID |
| 2 | `CID` | `main.general.bronze_etoro_customer_customer_masked` | `CID` | `passthrough` | — | c.CID |
| 3 | `OccurredAt` | `—` | `OccurredAt` | `join_enriched` | — | aa.OccurredAt |
| 4 | `QuestionId` | `—` | `QuestionId` | `join_enriched` | — | aa.QuestionId |
| 5 | `QuestionText` | `main.compliance.bronze_userapidb_kyc_questions` | `QuestionText` | `join_enriched` | — | q.QuestionText |
| 6 | `AnswerId` | `—` | `AnswerId` | `join_enriched` | — | aa.AnswerId |
| 7 | `AnswerText` | `main.compliance.bronze_userapidb_kyc_answers` | `AnswerText` | `join_enriched` | — | a.AnswerText |
| 8 | `Is_Current` | `—` | `Is_Current` | `join_enriched` | — | aa.Is_Current |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **4**, WARN: **0**, ERROR: **4**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `GCID` | — | `main.compliance.bronze_userapidb_history_customeranswers.gcid`, `main.compliance.bronze_userapidb_kyc_customeranswers.gcid` | ERROR |
| `OccurredAt` | — | `main.compliance.bronze_userapidb_history_customeranswers.occurredat_insource`, `main.compliance.bronze_userapidb_kyc_customeranswers.occurredat` | ERROR |
| `QuestionId` | — | `main.compliance.bronze_userapidb_history_customeranswers.questionid`, `main.compliance.bronze_userapidb_kyc_customeranswers.questionid` | ERROR |
| `AnswerId` | — | `main.compliance.bronze_userapidb_history_customeranswers.answerid`, `main.compliance.bronze_userapidb_kyc_customeranswers.answerid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **7**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN compliance.bronze_userapidb_kyc_questions AS q ON aa.QuestionId = q.QuestionId
- `LEFT JOIN` — LEFT JOIN compliance.bronze_userapidb_kyc_answers AS a ON aa.AnswerId = a.AnswerId
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_customer_customer_masked AS c ON (c.GCID = aa.GCID)
