SELECT a.RealCID
      ,a.GCID
      ,EOMONTH(dc.FirstDepositDate) 'EOM_FTD'   
      ,a.CountryName
      ,a.Age_On_Reg
	  , CASE WHEN a.Age_On_Reg<25 THEN 'Low - 25'
	         WHEN a.Age_On_Reg<31 THEN '26 - 30'
			 WHEN a.Age_On_Reg<36 THEN '31 - 35'
			 WHEN a.Age_On_Reg<41 THEN '36 - 40'
			 WHEN a.Age_On_Reg<51 THEN '41 - 50'
			 WHEN a.Age_On_Reg<61 THEN '51 - 60'
			 WHEN a.Age_On_Reg>=61 THEN  '61+'
			 ELSE 'No age' END AS 'AgeGroup'
      ,a.Gender
      ,a.Q3_Is_Professional_Knowledge 
      ,a.Q23_Is_Assessment_Pass
      ,a.Experience_Level
      ,CASE WHEN ISNULL(a.Q10_AnswerID, 0) IN (34, 35, 0) THEN 'Up_to_$50K'
            WHEN ISNULL(a.Q10_AnswerID, 0) IN (36, 79) THEN '$50K-$200K'
       ELSE 'Above_$200K' END AS 'Annual_Income'
      ,CASE WHEN ISNULL(a.Q11_AnswerID, 0) IN (34, 35, 0) THEN 'Up_to_$50K'
            WHEN ISNULL(a.Q11_AnswerID, 0) IN (36, 79) THEN '$50K-$200K'
       ELSE 'Above_$200K' END AS 'Liquid_Assets'
      ,a.Q9_AnswerText 'Q9_Risk_Reward_Senario'
      ,a.Q14_AnswerText 'Q14_Planned_Invested_Amount'
      ,a.Q5_AnswerText 'Q5_Trading_Strategy'
      ,a.Q8_AnswerText 'Q8_Trading_Primary_Purpose'
      ,CASE WHEN EOMONTH(dc.FirstDepositDate)>=EOMONTH(bdoofuk.DateTime_VL3) AND EOMONTH(dc.FirstDepositDate)=EOMONTH(a.FirstAction_Date)
	  THEN 'FundedFTDmonth' ELSE  'NotFundedFTDMonth' END AS 'Funded_Ind'
	  ,bdoofuk.MarketingRegion
FROM BI_DB_dbo.BI_DB_KYC_Panel a
INNER JOIN DWH_dbo.Dim_Customer dc ON a.RealCID = dc.RealCID AND dc.IsDepositor=1
INNER JOIN BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs bdoofuk ON bdoofuk.CID=a.RealCID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd ON bdcd.CID=a.RealCID


--WHERE a.Reg_Month >= 202101