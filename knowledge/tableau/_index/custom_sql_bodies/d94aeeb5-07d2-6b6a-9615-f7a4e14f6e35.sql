SELECT  DISTINCT sa.RealCID, fd.GCID, sa.Username, 
 sa.ActionID, sa.ActionDate, sa.ActionDateID, 
 sta.ActionName AS ActionType, sa.SubTypeName, sa.MessageText, 
CASE WHEN  CharIndex('$', sa.MessageText) IS NOT NULL THEN SUBSTRING(sa.MessageText, CharIndex('$', sa.MessageText), CharIndex(' ', sa.MessageText))
 ELSE NULL END AS tag,
 fd.Channel, fd.Blocked, fd.Club, fd.Country, fd.Gender, fd.PopularInvestor, fd.NumberOfUsersFollowed, fd.State,  --fd.FirstDepositDate  
--bdcdpfd.eom
 GETDATE() AS  [UpdateDate]
FROM DWH_dbo.Dim_Customer dc WITH (NOLOCK)  
JOIN BI_DB_dbo.BI_DB_Social_Activity sa WITH (NOLOCK) ON dc.RealCID = sa.RealCID  
JOIN BI_DB_dbo.BI_DB_Social_Activity_Type sta WITH (NOLOCK) ON sa.ActionTypeID = sta.ActionID  AND sa.ActionTypeID <> 5
JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd WITH (NOLOCK) ON sa.RealCID = fd.CID  
--LEFT Join BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpfd with(NOLOCK) on sa.RealCID = bdcdpfd.CID AND bdcdpfd.DateID=sa.ActionDateID
WHERE --dc.UserName='analyst'
sa.ActionDateID>=20210101 and fd.Region='USA'  -- Automatic Post