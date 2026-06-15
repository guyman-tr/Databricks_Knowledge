SELECT
	EOMONTH(Date) AS Month
   ,[IsContacted]
   ,(CASE WHEN Manager IN ('Adam Vettese', 'Simon Peters', 'Pearse Carson', 'Mark Crouch')
   THEN 'PM' ELSE 'AM' END) AS AM_PM
   ,Manager
   ,SUM([TotalDepositAmount]) TotalDepositAmount


FROM [BI_DB_dbo].[BI_DB_NewBonusReport] WITH (NOLOCK)
WHERE Date >= DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, -6, GETDATE())), 0) --'20220101'
AND Manager IN ('Adam Vettese', 'Simon Peters', 'Pearse Carson', 'Stefan Mihailescu', 'Harry Blagden', 'Mark Crouch', 'Valentina Reingold', 'Calum McCoy'
, 'Charlie Kaur', 'Varun Sehgal', 'Thomas Williams', 'Luke Sefain', 'Samuel Crain', 'Virgilio Guidi', 'Sarah Glanville', 'Alfie Newsome', 'Callum Frame')
GROUP BY EOMONTH(Date)
		,IsContacted
		,Manager
		,(CASE WHEN Manager IN ('Adam Vettese', 'Simon Peters', 'Pearse Carson', 'Mark Crouch')
   THEN 'PM' ELSE 'AM' END)