SELECT 
	KYC.* --,
	--CASE WHEN KYC.Q2_AnswerText<>KYC.M_Q2_AnswerText THEN 1 
	--WHEN KYC.Q3_AnswerText<>KYC.M_Q3_AnswerText THEN 1 
	--WHEN KYC.Q5_AnswerText<>KYC.M_Q5_AnswerText THEN 1 
	--WHEN KYC.Q8_AnswerText<>KYC.M_Q8_AnswerText THEN 1 
	--WHEN KYC.Q9_AnswerText<>KYC.M_Q9_AnswerText THEN 1 
	--WHEN KYC.Q10_AnswerText<>KYC.M_Q10_AnswerText THEN 1 
	--WHEN KYC.Q11_AnswerText<>KYC.M_Q11_AnswerText THEN 1 
	--WHEN KYC.Q14_AnswerText<>KYC.M_Q14_AnswerText THEN 1 
	--WHEN KYC.Q15_AnswerText<>KYC.M_Q15_AnswerText THEN 1 
	--WHEN KYC.Q18_AnswerText<>KYC.M_Q18_AnswerText THEN 1 
	--else 0 end as HasDifferentEP
, pcs.Change_Date as PendingClosureDate
,scr.Change_Date as ScreeningDate,
at1.Name as AccountTypeBO, 
dc.RegisteredReal as RegDate
	FROM #KYCPANEL KYC

left join #pendingclosuredate pcs on pcs.CID=KYC.CID
left join #screening scr on scr.CID=KYC.CID
JOIN DWH_dbo.Dim_Customer dc on dc.RealCID=KYC.CID
LEFT JOIN DWH_dbo.Dim_AccountType at1 on at1.AccountTypeID=dc.AccountTypeID