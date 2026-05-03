# Lineage: BI_DB_dbo.BI_DB_KYC_Questions_Answers

## Source Objects

| # | Source Object | Source Type | Relationship | Notes |
|---|---|---|---|---|
| — | (none found) | — | — | Dormant table. No SP writes to or reads from this table. No upstream production source identified. |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | QuestionId | (unknown) | — | — | Tier 3 |
| 2 | QuestionText | (unknown) | — | — | Tier 3 |
| 3 | MultipleSelection | (unknown) | — | — | Tier 3 |
| 4 | AnswerId | (unknown) | — | — | Tier 3 |
| 5 | AnswerText | (unknown) | — | — | Tier 3 |
| 6 | UpdateDate | (unknown) | — | — | Tier 3 |

## Lineage Notes

- **No writer SP** references this table. The similarly named `BI_DB_KYC_Questions_Answers_Row_Data` is a separate table populated by `SP_KYC_Questions_Answers_Row_Data_46` from `UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel`.
- This table appears to be a dormant KYC question/answer lookup that was superseded by the Row_Data variant.
- The `_no_upstream_found.txt` marker confirms no resolvable upstream wiki.
