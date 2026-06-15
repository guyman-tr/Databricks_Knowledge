SELECT
	cc.RealCID
 --  ,-cs.PendingClosureStatusName AS PendingClosureStatus
   ,ps.Name AS PlayerStatus
   ,vl.Name AS VerificationLevel
   ,ds.DocumentStatusName AS DocumentStatus
   ,cd.DocumentID
   ,cd.DateAdded AS DocumentAdded
   ,cd.Comment
   ,dt.Comment AS ClassificationComment
   ,ddt.Name
   ,rr.RejectReasonName AS RejectReason
   ,m.FirstName + ' ' + m.LastName AS ClassifiedBy
   ,CAST(dt.Occurred AS DATE) ClassificationOccured
   ,dc.Name AS Country
FROM BI_DB_dbo.External_etoro_BackOffice_CustomerDocument cd

LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dt
	ON dt.DocumentID = cd.DocumentID
LEFT JOIN DWH_dbo.Dim_Customer cc
	ON cd.CID = cc.RealCID

	
LEFT JOIN DWH_dbo.Dim_VerificationLevel vl
	ON vl.ID = cc.VerificationLevelID
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps
	on ps.	PlayerStatusID=cc.PlayerStatusID
LEFT JOIN  DWH_dbo.Dim_DocumentStatus ds
	ON ds.DocumentStatusID = cc.DocumentStatusID
LEFT JOIN  BI_DB_dbo.External_etoro_Dictionary_DocumentType ddt
	ON ddt.DocumentTypeID = dt.DocumentTypeID
LEFT JOIN  [BI_DB_dbo].[External_etoro_Dictionary_DocumentRejectReason] rr
	ON rr.RejectReasonID = dt.RejectReasonID
LEFT JOIN [BI_DB_dbo].[External_etoro_BackOffice_Manager] m
	ON m.ManagerID = dt.ManagerID
JOIN  DWH_dbo.Dim_Country dc
	ON cc.CountryID = dc.CountryID
WHERE 
--DATEPART(ISO_WEEK, dt.Occurred) = 10
 YEAR(dt.Occurred) = 2024
and m.FirstName + ' ' + m.LastName IN ('Kamila Gavriilidou', 
'Liza Christopher', 
'Francesco Riccio',
'Natasa Loizidou',
'Constantinos Avgousti',
'Loukia Panayi',
'Jessica Valentin',
'Stefanos Georgiades',
'Athanasia Karlou', 
'Ieva Seduikyte',
'
Daniel Cohen
Customer Service Manager​
CS • Israel
Ellya Perl
Customer Service Manager Tier 1
CS • Israel

19
2
Noa Borenstein
Customer Service Trading Manager
CS • Israel

25
2
Shani Koren
Customer Service Manager​
CS • Israel

29
7
Charalampos Vasileiou
Customer Service Representative - Escalations Team
CS • Cyprus
Nicolas Kyriakou
Customer Service Team Leader
CS • Cyprus

10
Oren Kurtz
CS Team Leader
CS • Israel

6
Deborah Yojay',
'Eden Shalkoff','Galit Zaolianov','Lesli Jimenez','Sara Ben David','Sebastian Weiss')