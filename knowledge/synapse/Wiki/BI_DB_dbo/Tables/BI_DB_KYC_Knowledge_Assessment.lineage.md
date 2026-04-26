# BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| GCID | BI_DB_KYC_Questions_Answers_Row_Data | GCID | Passthrough | Tier 2 |
| Q23_Assessment | BI_DB_KYC_Questions_Answers_Row_Data | QuestionText | MAX(CASE WHEN QuestionId=23) | Tier 2 |
| Q23_Is_Assessment_Pass | SP_KYC_Panel | Computed | Aggregate: 1 if ANY version passed, 0 if any attempted but all failed, -1 if none attempted | Tier 2 |
| Assessment_142_146_Ind | SP_KYC_Panel | Computed | 1 if customer took 142-146 version, -1 otherwise | Tier 2 |
| Is_Assessment_142_146_Pass | SP_KYC_Panel | Computed | 1 if total points > -3 for 142-146 version, -1 if not taken | Tier 2 |
| Total_Points_Assessment_142_146 | SP_KYC_Panel | Computed | SUM of P_AnswerId_142 through P_AnswerId_146 (range -10 to +10), -100 sentinel if not taken | Tier 2 |
| P_AnswerId_142 | SP_KYC_Panel | Computed | +2 if AnswerId=142 selected (correct), -2 if not. -100 sentinel if 142-146 version not taken | Tier 2 |
| P_AnswerId_143 | SP_KYC_Panel | Computed | -2 if AnswerId=143 selected (correct answer is NOT selecting it), +2 if not. -100 sentinel | Tier 2 |
| P_AnswerId_144 | SP_KYC_Panel | Computed | +2 if AnswerId=144 selected (correct), -2 if not. -100 sentinel | Tier 2 |
| P_AnswerId_145 | SP_KYC_Panel | Computed | -2 if AnswerId=145 selected (correct answer is NOT selecting it), +2 if not. -100 sentinel | Tier 2 |
| P_AnswerId_146 | SP_KYC_Panel | Computed | -2 if AnswerId=146 selected (correct answer is NOT selecting it), +2 if not. -100 sentinel | Tier 2 |
| OccurredAt_Assessment_142_146 | BI_DB_KYC_Questions_Answers_Row_Data | OccurredAt | MAX(OccurredAt) for 142-146 answers. 1900-01-01 sentinel if not taken | Tier 2 |
| Assessment_101_104_Ind | SP_KYC_Panel | Computed | 1 if customer took 101-104 version, -1 otherwise | Tier 2 |
| Is_Assessment_101_104_Pass | SP_KYC_Panel | Computed | 1 if AnswerId=102 selected for 101-104 version, -1 if not taken | Tier 2 |
| Q23_AnswerID_101_104 | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | MAX(AnswerId) for QuestionId=23 with AnswerId IN (101-104,127). -1 sentinel | Tier 2 |
| Q23_AnswerText_101_104 | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | MAX(AnswerText) for the 101-104 answer. 'N/A' sentinel | Tier 2 |
| OccurredAt_Assessment_101_104 | BI_DB_KYC_Questions_Answers_Row_Data | OccurredAt | MAX(OccurredAt) for 101-104 answers. 1900-01-01 sentinel | Tier 2 |
| Assessment_84_87_Ind | SP_KYC_Panel | Computed | 1 if customer took 84-87 version, -1 otherwise | Tier 2 |
| Is_Assessment_84_87_Pass | SP_KYC_Panel | Computed | 1 if AnswerId 84=1 AND 87=1 AND 85=0 AND 86=0, else 0. -1 sentinel | Tier 2 |
| OccurredAt_Assessment_84_87 | BI_DB_KYC_Questions_Answers_Row_Data | OccurredAt | MAX(OccurredAt) for 84-87 answers. 1900-01-01 sentinel | Tier 2 |
| Q23_AnswerText | SP_KYC_Panel | Computed | Final consolidated answer text. 'N/A' for most rows | Tier 2 |
| Q23_AnswerID | SP_KYC_Panel | Computed | Final consolidated answer ID. -1 sentinel for most rows | Tier 2 |
| UpdateDate | SP_KYC_Panel | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | Primary source — raw Q&A from UserApiDB | BI_DB_dbo |
