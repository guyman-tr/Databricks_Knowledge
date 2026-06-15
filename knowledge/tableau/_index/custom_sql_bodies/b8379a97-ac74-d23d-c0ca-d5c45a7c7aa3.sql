SELECT bdkp.RealCID,
		CASE WHEN bdkp.Q9_AnswerID IN (25,26,24,23) THEN 1 ELSE 0 END AS 'Is_RiskApetite_5/-3',
		CASE WHEN bdkp.Q10_AnswerID IN (79,35,34,80,36,81) THEN 1 ELSE 0 END AS 'Is_AnnualIncome_Upto10K',
		CASE WHEN bdkp.Q8_AnswerID IN (22) THEN 1 ELSE 0 END AS 'Is_TradingPurpose_SavingForHome'
FROM BI_DB_dbo.BI_DB_KYC_Panel bdkp