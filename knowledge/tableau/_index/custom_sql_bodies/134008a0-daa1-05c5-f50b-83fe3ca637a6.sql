SELECT  fca.Occurred
       ,dm.CID
        ,dm.ParentCID
	   ,CAST(-1*fca.Amount AS BIGINT) MoneyIn
        ,dc1.UserName
		,dm1.FirstName + ' ' + dm1.LastName AccountManager
,campaign_name
,p.start_date
,CASE WHEN efamtc.cid IS NOT NULL THEN -1*fca.Amount ELSE 0 END MoneyInAM
,CASE WHEN 
(Case When dm1.Team = 'Spanish' Then 'Spain' else dm1.Team end)
= p.region OR p.region = 'All' THEN 1 ELSE 0 END PIRegion
,MAX(CASE WHEN ao.CID IS NOT NULL THEN 1 ELSE 0 END) Contacted
,p.region
,dm1.Team
FROM DWH_dbo.Dim_Mirror dm
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dc.RealCID = dm.CID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
ON dc.RealCID=fca.RealCID
and dm.MirrorID = fca.MirrorID
INNER JOIN [DWH_dbo].[Dim_Customer] dc1 WITH (NOLOCK)
on dm.ParentCID = dc1.RealCID
 Join #PI p
 ON dm.ParentCID = p.CID
OUTER APPLY  
(
SELECT bduts.CID
FROM BI_DB_dbo.BI_DB_UsageTracking_SF bduts
WHERE bduts.ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c')
AND dm.CID = bduts.CID
AND fca.Occurred>=bduts.CreatedDate_SF
AND DATEDIFF(dd,bduts.CreatedDate_SF,fca.Occurred)<=30
--AND bdcdpc.AccountManagerID = bduts.CreatedByManagerID
GROUP BY bduts.CID
)ao
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_Club bdcdpc
ON dm.CID = bdcdpc.CID
AND fca.DateID = bdcdpc.DateID
JOIN BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User dm1
ON CAST(dm1.AccountManagerID AS BIGINT) = bdcdpc.AccountManagerID
LEFT JOIN BI_DB_dbo.External_Fivetran_account_manager_target_500_cids efamtc
ON dm.CID = efamtc.cid
WHERE fca.ActionTypeID IN (15,17)
AND cast(fca.Occurred as date)>=start_date
AND cast(fca.Occurred as date) <=end_date
AND dc.IsValidCustomer = 1
GROUP BY fca.Occurred
       ,dm.CID
        ,dm.ParentCID
	   ,-1*fca.Amount 
        ,dc1.UserName
        ,p.region
,campaign_name
,p.start_date
,dm1.FirstName + ' ' + dm1.LastName
,CASE WHEN efamtc.cid IS NOT NULL THEN -1*fca.Amount ELSE 0 END
,dm1.Team
,CASE WHEN 
(Case When dm1.Team = 'Spanish' Then 'Spain' else dm1.Team end)
= p.region OR p.region = 'All' THEN 1 ELSE 0 END