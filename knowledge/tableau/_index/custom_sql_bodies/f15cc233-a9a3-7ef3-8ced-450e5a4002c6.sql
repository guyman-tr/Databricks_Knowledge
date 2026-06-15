SELECT A.*,  CASE WHEN DATEDIFF(DAY,CreatedDate,Date)<1 THEN 'In SLA' ELSE 'Out of SLA' END AS 'SLA',
DATEDIFF(DAY,CreatedDate,Date) AS DaysToResolve,
CASE WHEN (
[TicketSubRole] IN (
'KYC Asia',
'OPS CS Verification',
'Corporate & SMSF',
'Verification Team Management','OPS CS World Check'
) 
OR 
Team IN (
'Communications - Verification',
'Communications - WCH',
'Corporate & SMSF',
'KYC Verification',
'WCH') or SubRole in ('KYC')
) THEN 'KYC' 

WHEN 
(
[TicketRole] IN 
('OPS Teams') 
OR 
A.UserRole IN ('OPS')
)
AND (A.SubRole IN ('Cashouts') or

	(
[TicketSubRole] IN (
'Lost wire COs / Returned wire COs',
'CO Problems',
'Account Closures',
'Lost credit card COs',
'3rd party refunds',
'Finance',
'CO - Exclude MOP from COs',
'OPS CS Cashouts',
'Cashouts'
) 
	OR A.Team IN 
(
'Account Closures',
'SEA payments',
'CO Prepration',
'Payment execution',
'CGS CO'
)
OR 
(
[TicketSubRole] IN (
'Lost wire COs / Returned wire COs',
'CO Problems',
'Account Closures',
'Lost credit card COs',
'3rd party refunds',
'Finance',
'CO - Exclude MOP from COs',
'OPS CS Cashouts',
'Cashouts'
) 

AND A.Team IN 
(
'Communications - CY',
'Communications - RO'
)
))) THEN 'Cashouts' 
WHEN (
(A.UserRole IN ('OPS')
AND 
 A.Team IN 
	(
	'AU',
	'Communications - CY',
	'Communications - RO',
	'CY',
	'RO',
	'UK'
	)

AND A.SubRole IN ('Deposits')
)

or (A.TicketSubRole in ('OPS CS Deposits'))
) THEN 'Deposits'

WHEN 
(
(A.UserRole IN ('OPS')

AND 
 A.Team IN 
(
'AU',
'Communications - CY',
'Communications - RO',
'CY',
'RO',
'UK'
)

AND A.SubRole IN ('Risk')
) OR
A.TicketSubRole IN ('OPS CS Risk')
) THEN 'Risk'

ELSE 'Other' END AS [OPS Groups]

FROM (
SELECT 
ncs.CID AS [CID],
ncs.CaseNumber AS [CaseNumber],
ncs.CreatedDate AS [CreatedDate],
ncs.Date AS [Date],
ncs.Source AS [Source],
ncs.ClubTier AS [ClubTier],
ncs.TicketStatus AS [TicketStatus],
ncs.ActionType AS [ActionType],
ncs.Type AS [Type],
ncs.SubType AS [SubType],
ncs.SubType2 AS [SubType2],
ncs.Priority AS [Priority],
ncs.Product AS [Product],
ncs.SLAScore AS [SLAScore],
csat.cSATLast as [LastCsat],
ncs.CreatedByRole AS [CreatedByRole],
ncs.NumberOfTouches AS [NumberOfTouches],
ncs.RegulationAtOpen AS [RegulationAtOpen],
us.FullName AS [FullName],
us.Department AS [Department],
us.UserRole AS [UserRole],
us.GroupName AS [GroupName],
us.SubRole AS [SubRole],
us.Team AS [Team],
ncs.Role as [TicketRole],
ncs.SubRole as [TicketSubRole],
case when ncs.Source in ('Manually','Manual') then 'Opened By eToro' else 'Opened By client' end as [Opened by],
ROW_NUMBER () over (PARTITION by  ncs.CaseNumber ORDER BY ncs.[Date] DESC) AS [RN],
CASE WHEN ncs.TicketStatus IN ('Closed','Solved') THEN 'Solved' ELSE 'Other Statuses' END AS [Open/Closed TicketStatus] 

FROM [BI_DB].[dbo].[BI_DB_SF_Cases_New] ncs WITH (NOLOCK)
left JOIN [BI_DB].[dbo].[BI_DB_SF_Users] us WITH (NOLOCK)
ON ncs.CaseOwner = us.FullName
left join [BI_DB].[dbo].[BI_DB_SF_M_cSAT]  csat on csat.CaseNumber=ncs.CaseNumber
WHERE 
--us.SubRole IN ('Cashouts','KYC','Deposits','MIMO','Risk','Partners') AND 
ncs.CreatedDate>= DATEADD(MONTH, -22, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))	


) A
WHERE RN=1