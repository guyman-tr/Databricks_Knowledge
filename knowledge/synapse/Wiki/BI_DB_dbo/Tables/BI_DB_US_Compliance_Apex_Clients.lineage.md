# Column Lineage: BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients

## Source Objects

| Source Object | Type | Role | Join Condition |
|---------------|------|------|----------------|
| DWH_dbo.Dim_Customer (dc) | Dimension | Primary source — customer demographics, address, KYC level | Base table (WHERE IsValidCustomer=1 AND VerificationLevelID=3 AND (closed OR US Reg8)) |
| DWH_dbo.Fact_SnapshotCustomer (fsc) | Fact | Closure detection — first AccountStatusID=2 date | fsc.RealCID = dc.RealCID (via #accountclosedate) |
| DWH_dbo.Dim_Range (dr) | Dimension | Date range decoding for snapshot dates | dr.DateRangeID = fsc.DateRangeID |
| DWH_dbo.Dim_Regulation (creg) | Dimension | Current regulation name lookup | dc.RegulationID = creg.DWHRegulationID |
| DWH_dbo.Dim_Regulation (dreg) | Dimension | Designated regulation name lookup | dc.DesignatedRegulationID = dreg.DWHRegulationID |
| DWH_dbo.Dim_AccountStatus (das) | Dimension | Account status name lookup | dc.AccountStatusID = das.AccountStatusID |
| DWH_dbo.Dim_Country (dcn) | Dimension | Country of residence name lookup | dc.CountryID = dcn.CountryID |
| DWH_dbo.Dim_Country (dcc) | Dimension | Citizenship country name lookup | dc.CitizenshipCountryID = dcc.CountryID |
| DWH_dbo.Dim_State_and_Province (dst) | Dimension | State/province name lookup | dc.RegionID = dst.RegionByIP_ID AND dcn.CountryID = dst.CountryID |
| BI_DB_dbo.BI_DB_CIDFirstDates (bdcd) | BI_DB table | VL3 date + email | bdcd.CID = dc.RealCID |
| BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (q) | BI_DB table | KYC questionnaire answers (pivoted) | q.GCID = dc.GCID (via #KYC_Questions_Answers_Level) |
| BI_DB_dbo.External_USABroker_Apex_ApexData (ad) | External table | Apex brokerage account data | ad.GCID = dc.GCID (via #apexdata) |
| BI_DB_dbo.External_USABroker_Dictionary_ApexStatus (st) | External table | Apex status name lookup | ad.StatusID = st.StatusID |
| BI_DB_dbo.External_USABroker_Apex_UserData (ud) | External table | Apex approval data + CID mapping | ad.GCID = ud.GCID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| GCID | Dim_Customer | GCID | Passthrough |
| CID | Dim_Customer | RealCID | Rename |
| FullName | Dim_Customer | FirstName, LastName | CONCAT(FirstName, ' ', LastName) |
| Address_Country | Dim_Country (dcn) | Name | Dim-lookup passthrough via CountryID |
| Address_State | Dim_State_and_Province | Name | Dim-lookup passthrough via RegionID+CountryID |
| Address_City | Dim_Customer | City | Rename |
| Address_Street | Dim_Customer | Address | Rename |
| Address_BuildingNumber | Dim_Customer | BuildingNumber | Rename |
| Address_ZipCode | Dim_Customer | Zip | Rename |
| VerificationLevelID | Dim_Customer | VerificationLevelID | Passthrough |
| VerificationLevel3Date | BI_DB_CIDFirstDates | VerificationLevel3Date | Passthrough (CAST to DATE) |
| Regulation | Dim_Regulation (creg) | Name | Dim-lookup passthrough via RegulationID |
| DesignatedRegulation | Dim_Regulation (dreg) | Name | Dim-lookup passthrough via DesignatedRegulationID |
| DOB | Dim_Customer | BirthDate | Rename + CAST to DATE |
| Phone | Dim_Customer | Phone | Passthrough |
| Email | BI_DB_CIDFirstDates | Email | Passthrough |
| RegisteredReal | Dim_Customer | RegisteredReal | Passthrough (CAST to DATE) |
| CloseDate | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN(CAST(FromDateID AS DATE)) WHERE AccountStatusID=2 |
| AccountStatusName | Dim_AccountStatus | AccountStatusName | Dim-lookup passthrough via AccountStatusID |
| Q2_Experience | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=2, pivoted via MAX+GROUP BY |
| Q8_Trading_Primary_Purpose | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=8, pivoted via MAX+GROUP BY |
| Q9_Risk_Reward_Scenario | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=9, pivoted via MAX+GROUP BY |
| Q10_Annual_Income | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=10, pivoted via MAX+GROUP BY |
| Q11_Liquid_Assets | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=11, pivoted via MAX+GROUP BY |
| Q14_Planned_Invested_Amount | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=14, pivoted via MAX+GROUP BY |
| Q15_Sources_of_Income | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=15, pivoted via MAX+GROUP BY |
| Q18_Occupation | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=18, pivoted via MAX+GROUP BY |
| Q29_Time_Frame_Investing | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=29, pivoted via MAX+GROUP BY |
| Q30_Is_Shareholder | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | CASE WHEN QuestionId=30 AND AnswerId=93 THEN 1 ELSE 0 |
| Q30_Is_Employed_By_Broker | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | CASE WHEN QuestionId=30 AND AnswerId=94 THEN 1 ELSE 0 |
| Q30_Is_Public_Official | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | CASE WHEN QuestionId=30 AND AnswerId=95 THEN 1 ELSE 0 |
| Q30_Is_None_Apply_To_me | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | CASE WHEN QuestionId=30 AND AnswerId=96 THEN 1 ELSE 0 |
| Q36_US_Permanent_Resident | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=36, pivoted via MAX+GROUP BY |
| Q40_W9_Certification | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | CASE WHEN QuestionId=40, pivoted via MAX+GROUP BY |
| ApexID | External_USABroker_Apex_ApexData | ApexID | Passthrough |
| ApexStatus | External_USABroker_Dictionary_ApexStatus | Name | Dim-lookup passthrough via StatusID |
| ApproverName | External_USABroker_Apex_UserData | ApproverName | Passthrough |
| ApexApprovedDate | External_USABroker_Apex_UserData | ApprovedByDate | Rename |
| UpdateDate | — | — | ETL metadata: GETDATE() |
| Citizenship | Dim_Country (dcc) | Name | Dim-lookup passthrough via CitizenshipCountryID |
