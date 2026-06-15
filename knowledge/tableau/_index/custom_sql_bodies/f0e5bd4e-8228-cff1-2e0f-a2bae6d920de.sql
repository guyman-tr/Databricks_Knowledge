select
dc.RealCID,
dc.GCID,
aty.Name as AccountType,
pl.Name as ClubLevel,
dc.FunnelID,
dc.FunnelFromID,
CASE  WHEN FunnelFromID=65 THEN 'From SMSF Funnel'WHEN aty.Name IN ('SMSF') THEN aty.Name end as [SMSF/FromSMSFfunnel],
dc.RegisteredReal as RegDate,
dc.FirstDepositDate,
fd.FirstDepositAmount,
MAX(CA.FirstOccurred) as FirstActionDate,
dc.VerificationLevelID,
dc.AffiliateID ,
dm.FirstName + ' ' + dm.LastName as AccountManager,
dr.Name as Regulaiton,
dc.Zip,
dc.City,
datediff(year,dc.BirthDate,getdate()) as Age,
v.Liabilities + v.ActualNWA AS TotalEquity ,
DESK.CFDesk as Desk
from DWH_dbo.Dim_Customer dc
left join DWH_dbo.Dim_AccountType aty on aty.AccountTypeID=dc.AccountTypeID
left join DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
left join [BI_DB_dbo].[BI_DB_CIDFirstDates] fd on fd.CID=dc.RealCID
LEFT JOIN DWH_dbo.Dim_Manager dm on dm.ManagerID=dc.AccountManagerID
LEFT JOIN DWH_dbo.Fact_FirstCustomerAction CA ON CA.RealCID=dc.RealCID
left join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=dc.PlayerLevelID
left join  DWH_dbo.Dim_Desk DESK ON DESK.CountryID=dc.CountryID AND DESK.LanguageID=dc.LanguageID
left join DWH_dbo.V_Liabilities v on v.CID=dc.RealCID and v.DateID=CONVERT(VARCHAR(8), GETDATE()-1, 112)
where dc.AccountTypeID=14--SMSF
OR dc.FunnelFromID=65
group by 
dc.RealCID,
dc.GCID,
pl.Name,
aty.Name,
dc.FunnelID,
dc.RegisteredReal ,
dc.FirstDepositDate,
fd.FirstDepositAmount,
dc.VerificationLevelID,
dc.AffiliateID ,
dm.FirstName + ' ' + dm.LastName ,
dr.Name,
dc.Zip,
dc.City,
datediff(year,dc.BirthDate,getdate()) ,
DESK.CFDesk,
v.Liabilities + v.ActualNWA,
dc.FunnelFromID,
CASE WHEN aty.Name IN ('SMSF') THEN aty.Name WHEN FunnelFromID=65 THEN 'From SMSF Funnel' end