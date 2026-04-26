# BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data — Column Lineage

**Generated**: 2026-04-23 | **Pipeline**: External ETL from UserApiDB (ADF/external pipeline — no Synapse SP writer found)

## ETL Chain

```
UserApiDB (KYC microservice — compliance answers database)
  |-- External_UserApiDB_KYC_Questions (question dimension, synced into Synapse)
  |-- External_UserApiDB_KYC_Answers (answer dimension, synced into Synapse)
  |-- External ETL pipeline (ADF or SQL Agent — no Synapse SP writer) ---|
  v
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (467M rows, GCID+OccurredAt+Q+A)
  |-- (no confirmed Synapse SP downstream consumers in sys.sql_modules)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | UserApiDB (via external ETL) | GCID | Passthrough — Group Customer ID, cross-product identity | Tier 1 — Customer.CustomerStatic |
| 2 | OccurredAt | UserApiDB KYC submission event | OccurredAt | Passthrough — event timestamp of answer submission | Tier 2 — naming + data evidence |
| 3 | QuestionId | External_UserApiDB_KYC_Questions | QuestionId | Passthrough — FK to question dimension | Tier 2 — External_UserApiDB_KYC_Questions structure |
| 4 | QuestionText | External_UserApiDB_KYC_Questions | QuestionText | Denormalized snapshot at write time (LanguageId=1) | Tier 2 — External_UserApiDB_KYC_Questions structure |
| 5 | AnswerId | External_UserApiDB_KYC_Answers | AnswerId | Passthrough — FK to answer dimension | Tier 2 — External_UserApiDB_KYC_Answers structure |
| 6 | AnswerText | External_UserApiDB_KYC_Answers | AnswerText | Denormalized snapshot at write time | Tier 2 — External_UserApiDB_KYC_Answers structure |
| 7 | UpdateDate | ETL pipeline | — | ETL write timestamp (row last updated) | Propagation |

## Notes

- **No Synapse SP writer found**: Searched sys.sql_modules for all references to `KYC_Questions_Answers_Row_Data` — no Synapse stored procedure writes to this table. ETL source is an external pipeline (ADF or SQL Agent job) reading from UserApiDB.
- **Multi-select rows**: Questions with `MultipleSelection = True` (e.g., QuestionId=3,4,26,27) produce multiple rows per GCID+OccurredAt, one per selected AnswerId. This is by design — avg 1.33 answers per GCID+QuestionId, max 13 observed.
- **Text denormalization**: QuestionText and AnswerText are copied at submission time. Changes to question/answer wording in the dimension tables do NOT retroactively update historical rows.
- **GCID semantics**: GCID is the Group/Global Customer ID (cross-product identity). Join to Dim_Customer.GCID to bridge to trading CID.
- **Re-answers**: A customer may re-answer questions at different OccurredAt timestamps. To get latest answers, filter on MAX(OccurredAt) per GCID+QuestionId.
