SELECT A.*,  CASE WHEN DATEDIFF(DAY,CreatedDate,Date)<1 THEN 'In SLA' ELSE 'Out of SLA' END AS 'SLA',
DATEDIFF(DAY,CreatedDate,Date) AS DaysToResolve

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
ncs.CreatedByRole AS [CreatedByRole],
ncs.NumberOfTouches AS [NumberOfTouches],
ncs.RegulationAtOpen AS [RegulationAtOpen],
us.FullName AS [FullName],
us.Department AS [Department],
us.UserRole AS [UserRole],
us.GroupName AS [GroupName],
us.SubRole AS [SubRole],
ncs.[LastCsat] as [LastCsat],
us.Team AS [Team],
ncs.Role as [TicketRole],
ncs.SubRole as [TicketSubRole],
case when ncs.Source in ('Manually','Manual') then 'Opened By eToro' else 'Opened By client' end as [Opened By],
ROW_NUMBER () over (PARTITION by  ncs.CaseNumber ORDER BY ncs.[Date] DESC) AS [RN],
CASE WHEN ncs.TicketStatus IN ('Closed','Solved') THEN 'Solved' ELSE 'Other Statuses' END AS [Open/Closed TicketStatus] 

FROM [BI_DB].[dbo].[BI_DB_SF_Cases_New] ncs WITH (NOLOCK)
left JOIN [BI_DB].[dbo].[BI_DB_SF_Users] us WITH (NOLOCK)
ON ncs.CaseOwner = us.FullName
WHERE
ncs.CreatedDate>= DATEADD(MONTH, -7, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))	
AND

ncs.Type IN ('Risk and Compliance') 
AND Product IN ('eToro Money') AND

(ncs.ActionType IN ('Chargeback') AND 
SubType IN (
'Fraud',
'ATM Activity',
'Duplicate processing',
'Goods/services not received',
'Defective goods/services',
'Recurring transaction')
)
 or
 (ncs.ActionType IN ('Indemnity claims') AND ncs.SubType IN (
 'Scam',
 'Fraud reason',
 'Other'))

 OR 
 (ncs.ActionType IN ('Risk Check') 
 AND 
 (
 (ncs.SubType IN ('Transaction Confirmation') AND 
 ncs.SubType2 IN ('Payment/Transfers confirmation','Refunds/Credits source','POS transaction','ATM transaction','Negative balance'))
OR 
 (ncs.SubType IN ('Location confirmation') AND  ncs.SubType2 IN ('ATM location','POS location'))
OR (ncs.SubType IN ('Source of funds')  AND ncs.SubType2 IN ('Payment/Transfers source','Refunds/Credits source'))
 OR (ncs.SubType IN ('Trading account issue') AND ncs.SubType2 IN ('Risk check - Oher','Risk investigation','3rd Party','AML','Chargeback'))
)
)
) A
WHERE RN=1