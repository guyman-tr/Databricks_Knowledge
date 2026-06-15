SELECT mda.ProviderHolderID,
mda.AccountID,
mda.Regulation,
mda.IsTestAccount,
mda.IsValidETM,
mda.IsValidCustomer,
mda.GCID,
dc.RealCID,
mda.ProviderCardID,
mda.Country,
mda.AccountProgram AS 'AccountProgram',
mda.AccountSubProgram,
mda.AccountSubProgramID,
mda.AccountCreateDate,
mda.CardCreateDate,
mda.CardStatus,
mda.AccountStatus,
dm.FirstName+' ' +dm.LastName AS 'Account Manager'
,mda.CardID
FROM eMoney_dbo.eMoney_Dim_Account mda 
INNER JOIN DWH_dbo.Dim_Customer dc ON mda.CID=dc.RealCID
INNER JOIN DWH_dbo.Dim_Manager dm ON dc.AccountManagerID=dm.ManagerID
where mda.AccountCreateDate>=<[Parameters].[Parameter 1]>
and mda.AccountCreateDate<=<[Parameters].[Parameter 2]>