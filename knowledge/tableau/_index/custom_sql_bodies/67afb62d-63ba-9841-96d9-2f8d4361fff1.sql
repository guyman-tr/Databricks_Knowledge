SELECT bdkp.RealCID
	  ,bdkp.Q10_AnswerText AS 'Annual_Income'
	  ,bdkp.Q11_AnswerText AS 'Liquid_Assets'
	  ,bdkp.Q9_AnswerText AS 'Risk_Apetite'
	  ,bdkp.Q14_AnswerText AS 'Planned_Invested_Amount'
	  ,bdkp.Q8_AnswerText AS 'Trading_Primary_Purpose'
FROM BI_DB_dbo.BI_DB_KYC_Panel bdkp