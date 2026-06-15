SELECT

	EOMONTH(KYC.Reg_Date) AS Reg_Month,
	KYC.VerificationLevelID,
	KYC.Gender,
        KYC.Region,
        KYC.EU,
        KYC.CountryName,
        KYC.Club,
	KYC.IsFTD,
        KYC.Age_On_Reg,
	KYC.IsFirstAction,
	KYC.FirstAction,
	IIF(KYC.FirstAction IN ('Copy Fund','Copy','Stocks/ETFs'),'Stocks/ETFs/Copy',KYC.FirstAction ) AS FirstActionAdj,
	KYC.FirstInstrument,
	KYC.Q10_AnswerText AS Annual_Income,
	KYC.Q11_AnswerText AS Liquid_Assets,
	KYC.Q18_AnswerText,
	CASE WHEN KYC.Q10_AnswerText IN ('Up to $10K') THEN 'Up to $10K' WHEN KYC.Q10_AnswerText IS NULL THEN 'NULL' ELSE 'More than 10K' end AS Annual_Income_Adj,
	CASE WHEN KYC.Q11_AnswerText IN ('Up to $10K') THEN 'Up to $10K' WHEN KYC.Q11_AnswerText IS NULL THEN 'NULL' ELSE 'More than 10K' end AS Liquid_Assets_Adj,
	CASE WHEN ((KYC.Q35_AnswerID =49 AND KYC.Q34_AnswerID =49 AND KYC.Q33_AnswerID=49 ) OR  KYC.Q2_AnswerID=49) THEN 'Never Traded' ELSE 'Traded' END AS Expirience,
	KYC.Q2_AnswerID AS Expirince_Old,
	KYC.Q23_Is_Assessment_Pass,
        KYC.Q23_AnswerText,
    KYC.Q3_Is_Professional_Knowledge,
	CASE WHEN (KYC.Q23_Is_Assessment_Pass=1 AND Q3_Is_Professional_Knowledge=1) THEN 'Professional+Pass'
		 WHEN (KYC.Q23_Is_Assessment_Pass=1 AND Q3_Is_Professional_Knowledge=0) THEN 'NOTProfessional+Pass'
		 WHEN (KYC.Q23_Is_Assessment_Pass=0 AND Q3_Is_Professional_Knowledge=1) THEN 'Professional+NOTPass'
		 ELSE 'NOTProfessional+NOTPass' END AS IsPassProfessional,
	KYC.Q33_AnswerText AS Expirience_Equities,
	KYC.Q34_AnswerText AS Expirience_Crypto,
	KYC.Q35_AnswerText AS Expirience_CFD,
	CASE WHEN KYC.Is_PI_Stocks=1 THEN 'Stocks'
		 WHEN KYC.Is_PI_Crypto=1 THEN 'Crypto'
		 WHEN KYC.Is_PI_FX=1 THEN 'FX' END AS PI_Answer,
	KYC.Total_PI_Answers,
	KYC.FirstDepositAmount,
	KYC.Equity30days,
	KYC.Revenue30days,
        KYC.Equity14days,
	KYC.Revenue14days,
        COUNT(RealCID) AS CIDcount

FROM BI_DB..BI_DB_KYC_Panel KYC
WHERE EOMONTH(KYC.Reg_Date)>=EOMONTH(DATEADD(MONTH,-24,GETDATE())) AND EOMONTH(KYC.Reg_Date)<>EOMONTH(GETDATE())
GROUP BY 


	EOMONTH(KYC.Reg_Date),
	KYC.VerificationLevelID,
	KYC.Gender,
	KYC.IsFTD,
	KYC.IsFirstAction,
	KYC.FirstAction,
	IIF(KYC.FirstAction IN ('Copy Fund','Copy','Stocks/ETFs'),'Stocks/ETFs/Copy',KYC.FirstAction ),
	KYC.FirstInstrument,
	KYC.Q10_AnswerText,
	KYC.Q11_AnswerText,
	KYC.Q18_AnswerText,
	CASE WHEN KYC.Q10_AnswerText IN ('Up to $10K') THEN 'Other' ELSE 'More than 10K' end,
	CASE WHEN KYC.Q11_AnswerText IN ('Up to $10K') THEN 'Other' ELSE 'More than 10K' end ,
	CASE WHEN ((KYC.Q35_AnswerID =49 AND KYC.Q34_AnswerID =49 AND KYC.Q33_AnswerID=49 ) OR  KYC.Q2_AnswerID=49) THEN 'Never Traded' ELSE 'Traded' END,
	KYC.Q2_AnswerID ,
	KYC.Q23_Is_Assessment_Pass,
        KYC.Q3_Is_Professional_Knowledge,
	CASE WHEN (KYC.Q23_Is_Assessment_Pass=1 AND Q3_Is_Professional_Knowledge=1) THEN 'Professional+Pass'
		 WHEN (KYC.Q23_Is_Assessment_Pass=1 AND Q3_Is_Professional_Knowledge=0) THEN 'NOTProfessional+Pass'
		 WHEN (KYC.Q23_Is_Assessment_Pass=0 AND Q3_Is_Professional_Knowledge=1) THEN 'Professional+NOTPass'
		 ELSE 'NOTProfessional+NOTPass' END,
	KYC.Q33_AnswerText,
	KYC.Q34_AnswerText,
	KYC.Q35_AnswerText,
	CASE WHEN KYC.Is_PI_Stocks=1 THEN 'Stocks'
		 WHEN KYC.Is_PI_Crypto=1 THEN 'Crypto'
		 WHEN KYC.Is_PI_FX=1 THEN 'FX' END,
	KYC.Total_PI_Answers,
	KYC.FirstDepositAmount,
	KYC.Equity30days,
	KYC.Revenue30days,
        KYC.Q23_AnswerText,
        KYC.Age_On_Reg,
        KYC.Club,
        KYC.Region,
        KYC.EU,
        KYC.CountryName,
        KYC.Equity14days,
        KYC.Revenue14days