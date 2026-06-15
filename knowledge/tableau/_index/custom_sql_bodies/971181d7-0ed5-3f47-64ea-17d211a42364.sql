SELECT DISTINCT 
		bdkp.RealCID
		,bdkp.GCID
		,bdkp.Reg_Date
		,CASE WHEN bdkp.FTD_Month <= 200000 THEN NULL ELSE bdkp.FTD_Date END [FTD_Date]
		,CASE WHEN bdkp.FTD_Month > 200000 THEN DATEDIFF(DAY,bdkp.Reg_Date,bdkp.FTD_Date) ELSE NULL END [GapInDays_RegToFTD]
		,bdfa.FirstDepositAmount
		,bdkp.Gender
		,bdcd.Verified
		,bdcd.VerificationLevel1Date
		,bdcd.VerificationLevel2Date
		,bdcd.VerificationLevel3Date
		,bdkp.Q18_AnswerText [Occupation]
		,bdkp.Q3_Is_Professional_Knowledge [HaveTradingKnowledge]
		,bdkp.Q3_AnswerText [SourceOfTradingKnowledge]
		,bdkp.Q23_Is_Assessment_Pass [PassedKnowledgeAssessment]
		,bdkp.Experience_Level [TradingExperienceLevel]
		,bdkp.Q2_AnswerText [TradingExperienceTime]
		,bdkp.Q33_AnswerText [TradedBefore_Equities]
		,bdkp.Q47_AnswerText [TradedBefore_Equities_Amt]
		,bdkp.Q34_AnswerText [TradedBefore_Crypto]
		,bdkp.Q48_AnswerText [TradedBefore_Crypto_Amt]
		,bdkp.Q35_AnswerText [TradedBefore_LeveragedCFD]
		,bdkp.Q45_AnswerText [TradedBefore_LeveragedCFD_Amt]
		,bdkp.Q10_AnswerText [Annual_Income]
		,bdkp.Q15_AnswerText [MainIncome_Source]
		,bdkp.Q26_AnswerText [SourcesOfIncome]
		,bdkp.Q11_AnswerText [Liquid_Assets]
		,bdkp.Q9_AnswerText [Risk/Reward_ExpectationsTolerance]
		,bdkp.Q14_AnswerText [PlannedInvestment_Amt]
		,bdkp.Q5_AnswerText [TradingStrategy]
		,bdkp.Q8_AnswerText [PurposeOfTrading]
		,bdkp.Q29_AnswerText [TimeFrameForInvesting]
		,bdkp.Is_PI_Stocks [PlanToInvest_Stocks]
		,bdkp.Is_PI_Crypto [PlanToInvest_Crypto]
		,bdkp.Is_PI_FX [PlanToInvest_FX]
		,bdkp.Total_PI_Answers [PlanToInvest_TotalAssetTypes]
		,bdcd.NewMarketingRegion [MarketingRegion_Current]
		,bdcd.Region [Region_Current]
		,bdcd.Country [Country_Current]
		,bdcd.Club [Club_Current]
		,bdcd.Blocked [Blocked_Current]
		,DATEDIFF(YEAR, bdcd.BirthDate, GETDATE()) [Age_Current]
		,bdfa.FirstAction
		,bdfa.FirstActionDate
		,bdfa.FirstInstrument
		,bdfa.FirstAction_Detailed
		,bdfa.FirstActionTypeNew
		,bdfa.SecondAction
		,bdfa.SecondActionDate
		,bdfa.SecondInstrument
		,bdfa.SecondAction_Detailed
		,bdfa.ThirdAction
		,bdfa.ThirdActionDate
		,bdfa.ThirdAction_Detailed
		,bdfa.ThirdInstrument
		,bdfa.FourthAction
		,bdfa.FourthActionDate
		,bdfa.FourthAction_Detailed
		,bdfa.FifthAction
		,bdfa.FifthActionDate
		,bdfa.FifthAction_Detailed
		,bdfa.FirstLeverage
		,bdfa.SecondLeverage
		,bdfa.ThirdLeverage
		,bdfa.FourthLeverage
		,bdfa.FifthLeverage
		,bdfa.Deposit1day
		,bdfa.Deposit7days
		,bdfa.Deposit14days
		,bdfa.Deposit30days
		,bdfa.Deposit60days
		,bdfa.Deposit90days
		,bdfa.Deposit180days
		,bdfa.Deposit360days
		,bdfa.Equity1day
		,bdfa.Equity7days
		,bdfa.Equity14days
		,bdfa.Equity30days
		,bdfa.Equity60days
		,bdfa.Equity90days
		,bdfa.Equity180days
		,bdfa.Equity360days
		,bdfa.Revenue1day
		,bdfa.Revenue7days
		,bdfa.Revenue14days
		,bdfa.Revenue30days
		,bdfa.Revenue60days
		,bdfa.Revenue90days
		,bdfa.Revenue180days
		,bdfa.Revenue360days
		,bdfa.[Traded_Stocks/ETFs]
		,bdfa.TradedCrypto
		,bdfa.TradedCopy
		,bdfa.TradedCopyFund
		,bdfa.[Traded_FX/Commodities/Indices]
		,CASE WHEN bdcd.FirstDemoLoggedIn IS NOT NULL THEN 1 ELSE 0 END [Demo_HasLoginBefore]
		,bdcd.FirstDemoLoggedIn
		,CASE WHEN bdcd.FirstDemoPosOpenDate IS NOT NULL THEN 1 ELSE 0 END [Demo_OpenedPosBefore]
		,bdcd.FirstDemoPosOpenDate
		,GETDATE() [ScriptRunDate]
FROM BI_DB..BI_DB_KYC_Panel bdkp
LEFT JOIN BI_DB..BI_DB_CIDFirstDates bdcd ON bdkp.GCID = bdcd.GCID
LEFT JOIN BI_DB..BI_DB_First5Actions bdfa ON bdcd.CID = bdfa.CID