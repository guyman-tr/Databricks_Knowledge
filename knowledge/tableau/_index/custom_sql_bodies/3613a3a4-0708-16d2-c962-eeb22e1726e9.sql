select 
A.CID,
A.AlertDate,
A.Alert,
A.Vendor,
A.Details,
case when A.Vendor in ('Onfido','Au10tix') THEN 'POI Document Check'
WHEN A.Vendor IN ('Sumsub') THEN 'POA Document Check'
WHEN A.Vendor IN ('APEX') THEN 'Trading Clearing' END AS [CurrentServices],
case when A.Alert like ('%Underage%') 
	then 1 else 0 end as [Underage],
case when A.Alert like ('%Elderly%') 
	then 1 else 0 end as [Elderly],
case when A.Alert like ('%Deceased%') 
	then 1 else 0 end as [Deceased],
case when 
	A.Alert like ('%Forged%') or 
	A.Alert like ('%Fraud%') or 
	A.Alert like ('%Not Authentic%')  OR
	A.Alert like  ('%Faces Do Not Match%') OR 
        A.Alert like  ('%Edited%')
	then 1 else 0 end as [Fraud],
dc.VerificationLevelID,
ps.Name as PlayerStatus,
dr.Name as DesignatedRegulation
FROM 
(
select 
	CID, 
	ClassificationDate as AlertDate, 
	reasonList as Alert, 
	Vendor, 
	DocumentTypeCategory AS 'Details'
	from BI_DB.dbo.BI_DB_Document_Vendors 
where 
(
reasonList like ('%Forged Document%') or 
reasonList like ('%Forged Selfie%') or
reasonList like ('%Fraud In Vendor DB%') or
reasonList like ('%Underage%') or
reasonList like ('%Not Authentic%')
 or
reasonList like ('%Elderly%')
 or
reasonList like ('%Faces Do Not Match%')
 or
reasonList like ('%Edited Document%')
)
and ClassificationDate BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
UNION
select 
	RealCID AS CID,
	ErrortDate AS AlertDate,
	ValidationError AS Alert,
	'APEX' AS Vendor,
	'' AS Details
from BI_DB.[dbo].[BI_DB_H_US_Apex_Rejected_Accounts] 
where 
(
ValidationError like ('%ApplicantProfileContainsHighRiskFraudWarning%') or
ValidationError like ('%CannotAutoAcceptForDeceased%') 
)
and ErrortDate BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
) A
left join DWH.dbo.Dim_Customer dc on dc.RealCID=A.CID
LEFT JOIN DWH.dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
LEFT join DWH.dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID