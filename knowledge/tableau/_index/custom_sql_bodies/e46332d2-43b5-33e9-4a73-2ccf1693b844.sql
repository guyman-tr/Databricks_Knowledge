Select 
cc.RealCID AS CID
, cr.[TransactionDate]
, evs.Name As EvStatus
, evp.Name As EvProvider
, evs1.Name as FinalResultEV
, ev1.EvMatchStatusName as FinalResultEVBO
--, cr.VerificationType
, dc.Name as Country
,dc.Region
, cc.VerificationLevelID
, case when cr.VerificationType=1 then 'Manual'
when cr.VerificationType=2 then 'System'
else 'Other'
end VerificationTypeName
, dr.Name as Regulation
,case when cc.HasWallet = 1 then 'Yes' else 'No' end as HasWallet

From [BI_DB_dbo].[External_UserApiDB_Ev_CustomerResult] cr

join DWH_dbo.Dim_Customer cc on cr.GCID = cc.GCID
Join [BI_DB_dbo].[External_UserApiDB_Dictionary_EvStatus] evs on cr.EvStatusId = evs.EvStatusId

Join [BI_DB_dbo].[External_UserApiDB_Dictionary_EvProvider] evp on cr.EvProviderId = evp.EvProviderId
Join [BI_DB_dbo].[External_UserApiDB_Dictionary_EvStatus] evs1 on cc.EvMatchStatus = evs1.EvStatusId
join  DWH_dbo.Dim_EvMatchStatus ev1 on cc.EvMatchStatus=ev1.EvMatchStatusID
join DWH_dbo.Dim_Country dc on cc.CountryID=dc.CountryID
join DWH_dbo.Dim_Regulation dr on dr.ID=cc.DesignatedRegulationID

WHERE [TransactionDate] BETWEEN '2022-01-01' AND '2023-09-20'

group by cc.RealCID
, cr.[TransactionDate]
, evs.Name
, evp.Name
, evs1.Name
,ev1.EvMatchStatusName
--, cr.VerificationType
, dc.Name
,dc.Region
, cc.VerificationLevelID
, cr.VerificationType
, dr.Name
,case when cc.HasWallet = 1 then 'Yes' else 'No' end