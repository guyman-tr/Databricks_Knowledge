# Lineage: BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Evidence |
|---|---|---|---|---|---|---|
| 1 | V_CustomerAnswers | View | dbo | UserApiDB | Bronze lake export → COPY INTO | SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range loads Parquet from `/internal-sources/Bronze/UserApiDB/dbo/V_CustomerAnswers/` |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier | Confidence Reason |
|---|---|---|---|---|---|---|
| 1 | GCID | UserApiDB.dbo.V_CustomerAnswers | GCID | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; column name and sample data indicate Global Customer ID |
| 2 | OccurredAt | UserApiDB.dbo.V_CustomerAnswers | OccurredAt | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; sample shows datetime of KYC answer submission |
| 3 | FreeText | UserApiDB.dbo.V_CustomerAnswers | FreeText | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; free-text response field for open-ended KYC answers |
| 4 | QuestionId | UserApiDB.dbo.V_CustomerAnswers | QuestionId | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; numeric identifier for the KYC question |
| 5 | QuestionText | UserApiDB.dbo.V_CustomerAnswers | QuestionText | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; human-readable KYC question label |
| 6 | AnswerId | UserApiDB.dbo.V_CustomerAnswers | AnswerId | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; numeric identifier for the selected answer |
| 7 | AnswerText | UserApiDB.dbo.V_CustomerAnswers | AnswerText | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; human-readable answer label |
| 8 | MinThreshold | UserApiDB.dbo.V_CustomerAnswers | MinThreshold | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; lower bound of numeric range answers (e.g. income brackets) |
| 9 | MaxThreshold | UserApiDB.dbo.V_CustomerAnswers | MaxThreshold | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; upper bound of numeric range answers (e.g. income brackets) |
| 10 | MultipleSelection | UserApiDB.dbo.V_CustomerAnswers | MultipleSelection | Passthrough via Parquet COPY INTO | Tier 3 | No upstream wiki found; flag indicating whether the question allows multiple answers |
| 11 | etr_y | Bronze partition path | etr_y | Partition column from lake path `etr_y={year}` | Tier 3 | No upstream wiki found; ETL year partition key from Bronze export |
| 12 | etr_ym | Bronze partition path | etr_ym | Partition column from lake path `etr_ym={year-month}` | Tier 3 | No upstream wiki found; ETL year-month partition key from Bronze export |
| 13 | etr_ymd | Bronze partition path | etr_ymd | Partition column from lake path `etr_ymd={date}` | Tier 3 | No upstream wiki found; ETL date partition key from Bronze export |
