SELECT 
	p.*,

	AVG(rf.Revenue_ThatMth) [AvgRev],
    SUM(rf.Revenue_ThatMth) [TotalRev],

	AVG(rf.RE_ThatMth) [AvgRE],
    MAX(rf.RE_ThatMth) [MaxRE],
    MIN(rf.RE_ThatMth) [MinRE],
	STDEV(rf.RE_ThatMth) [RE_stddev],
	bdcmpfd.ActiveDate,
	CASE WHEN bdcmpfd.EOM_Club LIKE '%Bronze%' THEN 'Bronze' ELSE bdcmpfd.EOM_Club END [FTD_yearend_club]
FROM
	#RE_filtered rf
	LEFT JOIN #pop p ON rf.RealCID = p.RealCID
	LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd ON rf.RealCID = bdcmpfd.CID AND rf.FTD_year = YEAR(bdcmpfd.ActiveDate) AND MONTH(bdcmpfd.ActiveDate) = 12 -- get club level at EOY of clients'FTD

GROUP BY
	p.RealCID
   ,p.MarketingRegion
   ,p.Country
   ,p.Regulation
   ,p.Club_current
   ,p.Status
   ,p.VerificationLevelID
   ,p.Reg_date
   ,p.FTD_date
   ,p.FTD_year
   ,p.FirstDepositAmount
   ,p.Age
   ,p.Seniority
   ,p.Gender
   ,p.Q10_Annual_Income
   ,p.Q10_AnswerText
   ,p.Q11_Liquid_Assets
   ,p.Q11_AnswerText
   ,p.Q14_Planned_Invested_Amount
   ,p.Q14_AnswerText
   ,p.Q18_Occupation
   ,p.Q18_AnswerText
   ,p.Q3_Trading_Knowledge
   ,p.Q3_Is_Professional_Knowledge
   ,p.Q3_AnswerText
   ,p.Revenue7days
   ,p.Revenue30days
   ,p.Revenue60days
   ,p.Revenue90days
   ,p.Revenue180days
   ,p.Revenue360days
   ,p.Equity7days
   ,p.Equity30days
   ,p.Equity60days
   ,p.Equity90days
   ,p.Equity180days
   ,p.Equity360days
   ,bdcmpfd.ActiveDate
   ,CASE WHEN bdcmpfd.EOM_Club LIKE '%Bronze%' THEN 'Bronze' ELSE bdcmpfd.EOM_Club END