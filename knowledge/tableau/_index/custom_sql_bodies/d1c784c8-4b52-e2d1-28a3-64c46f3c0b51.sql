select
distinct hbc.RealCID,
CAST(hbc.FirstDepositDate AS DATE) as FTDDate,
pl.Name as PlayerStatus,
pc.PendingClosureStatusName,
hbc.VerificationLevelID,
dr.Name as Regulation,
DATEDIFF(DAY,hbc.FirstDepositDate , GETDATE()) AS DaysFromFTD,
Liabilities + ActualNWA AS TotalEquity,
ss.Name as PEPCheckName

from DWH_dbo.Dim_Customer hbc
LEFT join  DWH_dbo.Dim_PendingClosureStatus pc on hbc.PendingClosureStatusID=pc.PendingClosureStatusID
LEFT join  DWH_dbo.Dim_PlayerStatus pl on hbc.PlayerStatusID=pl.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_Regulation dr on dr.ID=hbc.RegulationID
left join  DWH_dbo.V_Liabilities vl on hbc.RealCID = vl.CID AND DateID=Convert(varchar(12),DateAdd(Day,-1,GetDate()),112)
left join [BI_DB_dbo].[External_ScreeningService_Screening_UserScreening] us ON us.CID=hbc.RealCID
LEFT JOIN  [BI_DB_dbo].[External_ScreeningService_Dictionary_ScreeningStatus] ss ON ss.ID=us.ScreeningStatusID

where
hbc.IsValidCustomer=1 AND
hbc.IsDepositor=1 AND
hbc.VerificationLevelID <> 3
and (hbc.FirstDepositDate >= dateadd(day,-365,getdate()) AND hbc.FirstDepositDate <= dateadd(day,-13,getdate()))
and hbc.PendingClosureStatusID in (1) and hbc.PlayerStatusID in (
1,--Normal
5, --Warning                                          
11, --Social Index
13, --Pending Verification
14,--Blocked – Failed Verification
9 --Trade & MIMO Blocked
)
and hbc.RegulationID in (1,4,10,11) --CySEC, ASIC,ASIC+GAML,FSRA