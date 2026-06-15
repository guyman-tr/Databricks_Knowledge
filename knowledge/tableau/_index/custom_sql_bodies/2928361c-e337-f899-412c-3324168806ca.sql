select 
	C.* 
from 

(

SELECT
    B.CID,
    MAX(CASE WHEN Category = 'Trading' THEN Status else ps.Name END) AS Status_Trading,
    MAX(CASE WHEN Category = 'eMoney' THEN Status ELSE CurrencyBalanceStatus END) AS Status_eMoney,
    MAX(CASE WHEN Category = 'Stocks' THEN Status ELSE o.Name END COLLATE Latin1_General_BIN) AS Status_Stocks,
    MAX(CASE WHEN Category = 'Wallet' THEN Status ELSE UserWalletAllowance END) AS Status_Wallet,
	dc.IsDepositor,
	dr.Name as Regulation
FROM 
(select 
A.CID, 
PlayerStatus AS [Status], 
'Trading'   as Category
FROM 
(
SELECT 
	dc.RealCID as CID,
	ps.Name as PlayerStatus
from DWH_dbo.Dim_Customer dc 
join DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
WHERE dc.PlayerStatusID<>1
) A

union

select 
	RealCID as CID, 
	ApexStatus AS [Status], 
	'Stocks' as Category
from [BI_DB_dbo].[BI_DB_US_Apex_Rejected_Accounts]
WHERE ApexStatus in ('SUSPENDED','REJECTED')

union

SELECT
	a.CID,
	a.CurrencyBalanceStatus AS [Status], 
	'eMoney' as Category
from eMoney_dbo.eMoney_Dim_Account a 
where CurrencyBalanceStatus in ('SpendOnly','ReceiveOnly','Suspended','Suspended','Blocked')


union

select 
euswa.RealCID as CID,
UserWalletAllowance AS [Status], 
'Wallet' as Category
from  [EXW_dbo].[EXW_UserSettingsWalletAllowance] euswa 
where UserWalletAllowance in ('ReadOnly','NotAllowed')     
) B
JOIN DWH_dbo.Dim_Customer dc on dc.RealCID=B.CID
join DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
left join DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
LEFT JOIN eMoney_dbo.eMoney_Dim_Account a ON a.CID=B.CID
LEFT JOIN [EXW_dbo].[EXW_UserSettingsWalletAllowance] euswa  ON euswa.RealCID=B.CID
LEFT JOIN [BI_DB_dbo].[External_USABroker_Apex_Options] op ON dc.GCID=op.GCID
LEFT join [BI_DB_dbo].[External_USABroker_Dictionary_OptionsStatus] o on op.OptionsStatusID=o.OptionsStatusID
GROUP BY B.CID ,
	dc.IsDepositor,
	dr.Name) C
WHERE 
C.Status_eMoney IS NOT NULL OR 
(C.Status_Stocks IS NOT NULL and C.Status_Stocks NOT IN ('None'))
OR C.Status_Wallet IS NOT NULL