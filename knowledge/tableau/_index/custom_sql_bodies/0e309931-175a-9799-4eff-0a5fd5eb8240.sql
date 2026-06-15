select 
  dc.GCID
, dc.RealCID
, dc.FirstName
, dc.LastName
--, dc.IsCreditReportValidCB
, dc.LabelID
, efb.CountryID
, efb.Country
, efb.Regulation
, efb.PlayerLevelID 
, efb.Club AS  PlayerLevel
, dps.Name AS PlayerStatus
, dps.IsBlocked
, dat.Name as AccountType
, dc.AccountTypeID
, das.AccountStatusName 
, efb.CryptoName
, efb.Balance
, efb.BalanceUSD
, CASE WHEN efb.Balance>0 THEN 'N' ELSE 'Y' END IsZeroBalance
from EXW_dbo.EXW_FinanceReportsBalancesNew   efb  
Join DWH_dbo.Dim_Customer dc on dc.RealCID = efb.RealCID 
JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_AccountType dat ON dc.AccountTypeID = dat.AccountTypeID
JOIN DWH_dbo.Dim_AccountStatus das on dc.AccountStatusID = das.AccountStatusID
WHERE dc.AccountTypeID =7
and efb.BalanceDate = cast(getdate()-1 as DATE)