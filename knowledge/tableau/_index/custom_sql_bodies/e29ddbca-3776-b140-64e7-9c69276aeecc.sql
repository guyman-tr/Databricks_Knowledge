SELECT p.RealCID
	  ,p.RegisteredReal
          ,p.FirstDepositDate
	  ,p.FTD_YYMM
	  ,p.Country
	  ,p.EU
	  ,p.RegulationID
          ,p.Regulation
	  ,k.Q34_Experience_Crypto
	  ,k.Q34_AnswerText
	  ,k.Q34_AnswerID
	  ,k.Q35_Experience_CFDs
	  ,k.Q35_AnswerText
	  ,k.Q35_AnswerID
	  ,k.Q3_Trading_Knowledge
	  ,k.Q3_AnswerText
	  ,k.Q23_Assessment
	  ,k.Q23_Is_Assessment_Pass
	  ,k.Q23_AnswerText
	  ,k.Q23_AnswerID
	  ,k.Q8_Trading_Primary_Purpose
	  ,k.Q8_AnswerText
	  ,k.Q8_AnswerID
	  ,k.Q9_Risk_Reward_Scenario
	  ,k.Q9_AnswerText
	  ,k.Q9_AnswerID
	  ,k.Q10_Annual_Income
	  ,k.Q10_AnswerText
	  ,k.Q10_AnswerID
	  ,k.Q11_Liquid_Assets
	  ,k.Q11_AnswerText
	  ,k.Q11_AnswerID
          ,case when p.Country='Spain' and RegisteredReal>='20250320' then 'Futures' else 'CFD' end Product_Type
FROM (
		SELECT  DISTINCT dc.RealCID
			,dc.RegisteredReal
                        ,dc.FirstDepositDate
			,YEAR(dc.FirstDepositDate)*100+MONTH(dc.FirstDepositDate) FTD_YYMM
			,dc1.Name Country
			,dc1.EU
			,dc.RegulationID
                        ,dr.Name Regulation
	FROM DWH_dbo.Dim_Customer dc
	LEFT JOIN DWH_dbo.Dim_Country dc1
		ON dc.CountryID=dc1.CountryID
	LEFT JOIN DWH_dbo.Dim_Position dp
		ON dc.RealCID=dp.CID
        LEFT JOIN DWH_dbo.Dim_Regulation dr
		ON dr.DWHRegulationID=dc.RegulationID
	WHERE dc.FirstDepositDate>='20240101'
		AND dc1.EU=1
		AND dc.IsValidCustomer=1
		AND dc.RegulationID=1    -- CySEC
		AND dp.IsSettled=0
		AND dp.MirrorID=0
		AND dp.CloseDateID=0
		) p
LEFT JOIN (
				SELECT  bdkp.RealCID
	    ,bdkp.Q34_Experience_Crypto
		,bdkp.Q34_AnswerText
		,bdkp.Q34_AnswerID
		
		,bdkp.Q35_Experience_CFDs
		,bdkp.Q35_AnswerText
		,bdkp.Q35_AnswerID

		,bdkp.Q3_Trading_Knowledge
		,bdkp.Q3_AnswerText

		,bdkp.Q23_Assessment
		,bdkp.Q23_Is_Assessment_Pass
		,bdkp.Q23_AnswerText
		,bdkp.Q23_AnswerID

		,bdkp.Q8_Trading_Primary_Purpose
		,bdkp.Q8_AnswerText
		,bdkp.Q8_AnswerID

		,bdkp.Q9_Risk_Reward_Scenario
		,bdkp.Q9_AnswerText
		,bdkp.Q9_AnswerID

		,bdkp.Q10_Annual_Income
		,bdkp.Q10_AnswerText
		,bdkp.Q10_AnswerID

		,bdkp.Q11_Liquid_Assets
		,bdkp.Q11_AnswerText
		,bdkp.Q11_AnswerID
FROM BI_DB_dbo.BI_DB_KYC_Panel bdkp
	 ) k
	ON p.RealCID = k.RealCID