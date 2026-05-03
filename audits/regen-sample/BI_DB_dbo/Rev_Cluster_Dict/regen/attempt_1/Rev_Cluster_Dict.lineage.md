# Lineage: BI_DB_dbo.Rev_Cluster_Dict

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---------------|-------------|--------------|----------|
| 1 | BI_DB_dbo.BI_DB_KYC_Panel | Table | Semantic origin | SP_KYC_Score_CID_Level groups KYC panel answers into the same dimension categories stored in this dictionary |
| 2 | BI_DB_dbo.SP_KYC_Score_CID_Level | Stored Procedure | Consumer (reader) | LEFT JOINs to Rev_Cluster_Dict on 3 index columns to assign cluster number |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|---------------|---------------|-----------|------|
| Age_On_Reg_grouped_Index | (manual dictionary) | — | Manually maintained index for age-at-registration bracket | Tier 3 |
| max_33_35_Index | (manual dictionary) | — | Manually maintained index for trading experience bracket | Tier 3 |
| Q11_AnswerText_grouped_Index | (manual dictionary) | — | Manually maintained index for liquid assets bracket (Q11) | Tier 3 |
| Age_On_Reg_grouped | (manual dictionary) | — | Text label for age-at-registration bracket | Tier 3 |
| Q11_AnswerText_grouped | (manual dictionary) | — | Text label for liquid assets bracket (Q11) | Tier 3 |
| max_33_35 | (manual dictionary) | — | Text label for trading experience bracket (Q33/Q35/Q2) | Tier 3 |
| Combined_Answer_clustered | (manual dictionary) | — | Cluster assignment number for the 3-dimension combination | Tier 3 |
| UpdateDate | (manual dictionary) | — | Timestamp of last manual insert/update | Tier 3 |

## Notes

- This table has **no writer SP** — it is manually maintained (last updated 2023-11-14).
- It serves as a **static lookup dictionary** consumed by SP_KYC_Score_CID_Level.
- The three index columns correspond to grouped KYC questionnaire dimensions defined in SP_KYC_Score_CID_Level's CASE logic.
- No upstream production wiki exists (`_no_upstream_found.txt` present).
