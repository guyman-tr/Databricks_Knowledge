# BI_DB_dbo.BI_DB_PLTV — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_PLTV` — TRUNCATE+INSERT (no date parameter)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_KYC_Score_CID_Level | BI_DB_dbo | Customer cluster assignment (Cluster != 'No Cluster') |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB_dbo | KYC questionnaire answers (Q11, Q33, Q35) |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | BI_DB_dbo | Revenue8Y_LTV_New, FirstDepositDate |
| DWH_dbo.Dim_Customer | DWH_dbo | BirthDate, RegisteredReal, CountryID |
| DWH_dbo.Dim_Country | DWH_dbo | CountryID, MarketingRegionManualName |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CountryID | DWH_dbo.Dim_Country | CountryID | passthrough (Part 1) / JOIN on MarketingRegionManualName (Part 2) |
| Min_Age | DWH_dbo.Dim_Customer | BirthDate, RegisteredReal | CASE: age at registration → bucket (18, 27, 35 or 999) |
| Max_Age | DWH_dbo.Dim_Customer | BirthDate, RegisteredReal | CASE: age at registration → bucket (26, 35, 999) |
| Q11_AnswerID | BI_DB_dbo.BI_DB_KYC_Panel | Q11_AnswerID | passthrough (Part 1) / 999 (Part 2) |
| MaxQ33/MaxQ35 | BI_DB_dbo.BI_DB_KYC_Panel | Q33_AnswerID, Q35_AnswerID | MAX(Q33, Q35) or 999 |
| LeadScore | — | — | Always NULL (column removed 2024-10-25) |
| PLTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | Part 1: SUM/COUNT (avg per group), Part 2: AVG by region |
| updateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
