Select cc.RealCID as CID
,cc.UserName
,cc.FirstName+' '+cc.LastName as [Full Name]
,sa.ActionDate
,sat.ActionName As ActivityType
,sa.MessageText
,dc.Name AS Country
,dc.Region
,dc.Desk
,dpl.Name AS Club
,dr.Name AS Regulation
,CASE WHEN sau.ID IS NOT NULL THEN 1 
	  WHEN sau1.ID IS NOT NULL THEN 1 
	  ELSE 0 END AS IsRemoved
From BI_DB.dbo.BI_DB_Social_Activity sa WITH (NOLOCK)
join DWH..Dim_Customer cc WITH (NOLOCK)
on sa.RealCID = cc.RealCID
JOIN DWH..Dim_Country dc
ON cc.CountryID = dc.CountryID
JOIN DWH..Dim_PlayerLevel dpl
ON cc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH..Dim_Regulation dr
ON cc.RegulationID=dr.ID
Join BI_DB.dbo.BI_DB_Social_Activity_Type sat WITH (NOLOCK)
on sa.ActionTypeID = sat.ActionID
LEFT JOIN [BI_DB].[dbo].[BI_DB_Social_Activity_Updates] sau WITH (NOLOCK)
ON sa.CommentID = sau.ID
AND sau.TypeName='Comment'
AND sau.SetAsSpam=1
LEFT JOIN [BI_DB].[dbo].[BI_DB_Social_Activity_Updates] sau1 WITH (NOLOCK)
ON sa.PostID = sau1.ID
AND sau1.TypeName='Discussion'
AND sau1.SetAsSpam=1
Where ActionDate > DateAdd(Month,-3,GetDate()-1)
and sa.ActionTypeID In (1,2)
AND cc.IsValidCustomer=1