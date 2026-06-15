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
ncs.[LastCsat] as [LastCsat],
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
case when ncs.SubType in ('Cancel /change/refund my deposit',
'Cashier/Deposit options and limitations',
'Deposit - Other',
'Deposit fees',
'Deposit not reflecting in balance',
'Deposit Options and Limitations',
'Insufficient funds',
'Less funds shown',
'Transfer funds') then 'Deposits - Not Wire related' 
WHEN ncs.SubType  LIKE ('%t Deposit') then 'Deposits - Not Wire related'
when ncs.SubType in ('Australian Wires',
'Status of Wire Transfer',
'Wires Pool Account') then 'Deposits - Wire related' else 'Non Deposit Type'
end as [WiresRelatedVsOther],
CASE WHEN ncs.ClubTier IN ('Platinum Plus','Diamond') THEN 'Platinum+ & Diamond'
WHEN ncs.ClubTier IN ('Platinum') THEN 'Platinum' 
WHEN (ncs.ClubTier IN ('Bronze','Silver','Gold') OR ncs.ClubTier IS NULL) THEN 'Bronze & Silver & Gold' END AS [ClubLevel],


ROW_NUMBER () over (PARTITION by  ncs.CaseNumber ORDER BY ncs.[Date] DESC, ncs.TicketStatus desc) AS [RN],
CASE WHEN ncs.TicketStatus IN ('Closed','Solved') THEN 'Solved' ELSE 'Other Statuses' END AS [Open/Closed TicketStatus] 
,case when ncs.TicketStatus IN ('New','Open','created','On it') then 'Pending with eToro Team' else 'Pending with Client' end as [PendingGroup]
FROM [BI_DB].[dbo].[BI_DB_SF_Cases_New] ncs WITH (NOLOCK)
left JOIN [BI_DB].[dbo].[BI_DB_SF_Users] us WITH (NOLOCK)
ON ncs.CaseOwner = us.FullName
--where AND ncs.CreatedDate>= DATEADD(MONTH, -7, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))	

) A
WHERE 
RN=1 
AND  
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

AND A.SubRole IN ('Deposits')
)

or (A.TicketSubRole in ('OPS CS Deposits'))
)