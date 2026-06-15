/* Create custom query that will provides the follows:


1) Real CID based on Fivetran
2) Account Type ID
3) Country ID 
4) Master Account CID
5) Player Level ID
6) Player Status ID
7) Employee Account Validation Status

*/


SELECT   dc.RealCID
		,dc.AccountTypeID
		,dat.Name AS 'AccountTypeName'
		,dc.CountryID
		,dc1.Name AS 'CountryNAme'
		,dc.PlayerLevelID
		,dpl.Name as 'PlayerLevelName'
		,dc.PlayerStatusID 
		,dps.Name AS 'PlayerStatusName'
		,dc.RegulationID
		,dr.Name AS 'RegulationName'
		,z.MasterAccountCID
		,z.VerificationLevelID
                ,CASE WHEN dc.IsDepositor = 0 THEN 'NeverDeposit' ELSE 'Deposit' end AS 'DepositIndicator'
		,Case when dc.AccountTypeID in (7,13) and dc.CountryID in (250,219) and z.MasterAccountCID in (10717251) and dc.PlayerLevelID in (4) and dc.PlayerStatusID=10 then 'Valid' else 'Not_Valid' end AS 'EmployeeAccountValidationStatus'
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN 
(SELECT 
		 x.CID
		,x.MasterAccountCID
		,x.RegulationID
		,x.VerificationLevelID
		,x.Verified
		,x.RegulationChangeDate  
FROM [DWH_staging].[etoro_BackOffice_Customer] x) z /* All CIDs are uniques */
ON z.CID = dc.RealCID
LEFT JOIN DWH_dbo.Dim_Country dc1 
ON dc1.CountryID = dc.CountryID 
LEFT JOIN DWH_dbo.Dim_PlayerLevel dpl 
ON dpl.PlayerLevelID = dc.PlayerLevelID 
left JOIN DWH_dbo.Dim_PlayerStatus dps 
ON dps.PlayerStatusID = dc.PlayerStatusID 
LEFT JOIN DWH_dbo.Dim_Regulation dr 
ON dr.ID = dc.RegulationID 
LEFT JOIN DWH_dbo.Dim_AccountType dat 
ON dat.AccountTypeID = dc.AccountTypeID
WHERE z.MasterAccountCID is not NULL