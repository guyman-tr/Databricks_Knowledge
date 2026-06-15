SELECT c.*
FROM (
SELECT   mda.CID
      ,mda.GCID
	  ,mda.ClubID
	  ,mda.Club
	  ,mda.ClubCategory
	  ,mda.RegClubID
	  ,mda.RegClub
	  ,mda.CountryID
	  ,mda.Country
	  ,mda.RegCountryID
	  ,mda.RegCountry
	  ,mda.RegAccountSubProgramID
	  ,mda.RegAccountSubProgram
	  ,mda.HasAccountSubProgramChanged 
	  ,mda.AccountSubProgramID
	  ,mda.AccountSubProgram
	  ,mda.CountAccountSubProgramChanges
	  ,mda.RegAccountProgram
	  ,mda.AccountProgram
	  ,mda.CountAccountProgramChanges
	  ,mda.AccountPropertiesTime
	  ,mda.AccountPropertiesDate
	  ,mda.HasCard
	  ,mda.AccountID
	  ,mda.ProviderHolderID AS HolderID
	  ,mda.CardCreateDate
	  ,mda.CardStatus
	  ,CASE WHEN (mda.RegAccountSubProgramID =8 AND mda.RegAccountSubProgramID=mda.AccountSubProgramID) OR (mda.RegAccountSubProgramID =9 AND mda.RegAccountSubProgramID=mda.AccountSubProgramID) THEN 'eMoney FTD-Temp Program for FTD flow'
	        WHEN mda.RegAccountSubProgramID IN (8,9) THEN a.AccountSubProgram
	        ELSE mda.RegAccountSubProgram END AS [Source Program]
	  ,CASE 
	        WHEN mda.AccountSubProgramID=8 THEN 'eMoney FTD-Temp Program for FTD flow'
			WHEN mda.AccountSubProgramID=9 THEN 'eMoney FTD-Temp Program for FTD flow'
	  ELSE mda.AccountSubProgram
	  END AS [Destination Program]	
FROM eMoney_dbo.eMoney_Dim_Account mda
LEFT JOIN (
SELECT sub3.AccountID
      ,sub3.CID
	  ,sub3.AccountSubProgramID
	  ,sub3.AccountSubProgram
FROM (
SELECT  sub.AccountID
,sub2.CID
,sub.AccountProgramID
,sub.AccountProgram
,sub.AccountSubProgramID
,sub.AccountSubProgram
,sub.AccountPropertiesTime
,sub.AccountPropertiesDate
,sub.RNDesc
FROM(SELECT fap.AccountId AS 'AccountID'
,fap.AccountProgramId AS 'AccountProgramID'
,dapm.AccountProgram AS 'AccountProgram'
,fap.SubProgramId AS 'AccountSubProgramID'
,dsub.AccountSubProgram AS 'AccountSubProgram'
,fap.Created AS 'AccountPropertiesTime'
,CAST(fap.Created AS DATE) AS 'AccountPropertiesDate'
,ROW_NUMBER() OVER (PARTITION BY fap.AccountId ORDER BY fap.Created ASC) AS 'RNDesc'
FROM [eMoney_dbo].[FiatAccountsProperties] fap WITH(NOLOCK)
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountProgram] dapm WITH(NOLOCK) ON fap.AccountProgramId = dapm.AccountProgramID
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountSubProgram] dsub WITH(NOLOCK) ON fap.SubProgramId = dsub.AccountSubProgramID
) sub
INNER JOIN (
SELECT mda1.CID
      ,mda1.AccountID
      ,mda1.RegAccountSubProgramID
	  ,mda1.AccountSubProgramID
FROM eMoney_dbo.eMoney_Dim_Account mda1
WHERE mda1.RegAccountSubProgramID<>mda1.AccountSubProgramID AND mda1.IsValidETM=1 AND mda1.RegAccountSubProgramID IN (8,9)) sub2 ON sub2.AccountID=sub.AccountID)sub3
WHERE sub3.RNDesc=2) a ON mda.CID=a.CID
WHERE mda.IsValidETM=1 
AND mda.IsValidCustomer=1 ) c
WHERE c.[Source Program]<>c.[Destination Program]