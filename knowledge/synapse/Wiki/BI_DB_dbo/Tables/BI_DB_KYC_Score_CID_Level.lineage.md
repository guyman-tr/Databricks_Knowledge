# BI_DB_dbo.BI_DB_KYC_Score_CID_Level — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| RealCID | BI_DB_KYC_Panel | RealCID | Passthrough | Tier 2 |
| Q11_Answer_Grouped_IND | SP_KYC_Score_CID_Level | Computed | CASE on Q11_AnswerID: 34,28→1; 35,81,29,30,33,38→2; 36,79,80,31,32,37→3; else 99 | Tier 2 |
| Q11_Answer_Grouped | SP_KYC_Score_CID_Level | Computed | CASE on Q11_AnswerID: maps to 'Up to $10K', '$10K-$50K & $1M-$5M', '$50K-$1M', 'Not_Answered' | Tier 2 |
| Age_On_Reg_Grouped_IND | SP_KYC_Score_CID_Level | Computed | CASE on Age_On_Reg: <=26→1, 27-34→2, >=35→3, else 99 | Tier 2 |
| Age_On_Reg_Grouped | SP_KYC_Score_CID_Level | Computed | CASE on Age_On_Reg: maps to 'up to 26', 'between 27 and 34', 'Above 35', 'Not_Answered' | Tier 2 |
| Max(33,35)_IND | SP_KYC_Score_CID_Level | Computed | CASE on Q33/Q35/Q2 AnswerIDs: max experience level 1-4, 99 | Tier 2 |
| Max(33,35) | SP_KYC_Score_CID_Level | Computed | CASE on Q33/Q35/Q2: maps to experience text labels | Tier 2 |
| Revenue30days | BI_DB_KYC_Panel | Revenue30days | Passthrough | Tier 2 |
| Reg_Date | BI_DB_KYC_Panel | Reg_Date | Passthrough | Tier 2 |
| Cluster | Rev_Cluster_Dict | Combined_Answer_clustered | LEFT JOIN on 3-way key. 'No Cluster' if not matched | Tier 2 |
| UpdateDate | SP_KYC_Score_CID_Level | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| BI_DB_dbo.BI_DB_KYC_Panel | Primary source — KYC Q&A data, age, revenue | BI_DB_dbo |
| BI_DB_dbo.Rev_Cluster_Dict | Cluster assignment dictionary (3-way key lookup) | BI_DB_dbo |
