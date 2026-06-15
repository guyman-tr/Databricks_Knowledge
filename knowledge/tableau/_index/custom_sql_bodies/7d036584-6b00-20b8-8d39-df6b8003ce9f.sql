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
    A.Alert like  ('%Edited%') OR
	    A.Alert like ('%Forged%') or 
    A.Alert like ('%Fraud%') or 
    A.Alert like ('%Not Authentic%') or
    A.Alert like ('%Faces Do Not Match%') or 
    A.Alert like ('%Edited%') or
    A.Alert like ('%Digital Tampering%') or 
    A.Alert like ('%Picture Face Integrity%') or
    A.Alert like ('%Fonts%') or 
    A.Alert like ('%Template%') or 
    A.Alert like ('%Forged ID%') or 
    A.Alert like ('%Edited ID%') or 
    A.Alert like ('%Inconsistent POA%') or 
    A.Alert like ('%Fraud In Vendor DB%') or 
    A.Alert like ('%Spoofing%') or 
    A.Alert like ('%Fake Webcam%') or 
    A.Alert like ('%Forged Document%') or 
    A.Alert like ('%Abnormal Document Features%')
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
	from BI_DB_dbo.BI_DB_Document_Vendors 
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
or 
reasonList LIKE ('%Not Authentic%')
OR reasonList LIKE ('%Digital Tampering%')
OR reasonList LIKE ('%Picture Face Integrity%')
OR reasonList LIKE ('%Fonts%')
OR reasonList LIKE ('%Template%')
OR reasonList LIKE ('%Forged ID%')
OR reasonList LIKE ('%Edited ID%')
OR reasonList LIKE ('%Inconsistent POA%')
OR reasonList LIKE ('%Fraud In Vendor DB%')
OR reasonList LIKE ('%Faces Do Not Match%')
OR reasonList LIKE ('%Spoofing%')
OR reasonList LIKE ('%Fake Webcam%')
OR reasonList LIKE ('%Forged Document%')
OR reasonList LIKE ('%Abnormal Document Features%')
)
and ClassificationDate >='2025-10-01'
UNION
select 
	RealCID AS CID,
	ErrortDate AS AlertDate,
	ValidationError AS Alert,
	'APEX' AS Vendor,
	'' AS Details
from BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts
where 
(
ValidationError like ('%ApplicantProfileContainsHighRiskFraudWarning%') or
ValidationError like ('%CannotAutoAcceptForDeceased%') 
)
and ErrortDate >='2025-10-01'
) A
left join DWH_dbo.Dim_Customer dc on dc.RealCID=A.CID
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
LEFT join DWH_dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID