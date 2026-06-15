select
	distinct cc.RealCID AS CID,
	CAST(cc.BirthDate AS DATE) AS BirthDate,
	CAST(cc.RegisteredReal AS DATE) AS Registered,
	DATEDIFF(year,cc.BirthDate, getdate()) Age,  
	DATEDIFF(year,cc.BirthDate, cc.RegisteredReal) AgeAtReg,
	cc.VerificationLevelID,  
	CAST(cc.FirstDepositDate AS DATE) as FTDDate,
	dr.Name as Regulation,
	dc.Name as Country,
	ps.Name as PlayerStatus,
	cc.IsAddressProof,
	cc.IsIDProof,
	dems.EvMatchStatusName,
	max(CASE WHEN cdtdt.DocumentID IS NULL THEN 1 ELSE 0 END) AS IsSelfielivelinessProof

FROM DWH_dbo.Dim_Customer cc
left JOIN DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID = cc.PlayerStatusID
join DWH_dbo.Dim_Regulation dr on dr.ID=cc.RegulationID
join DWH_dbo.Dim_Country dc on dc.CountryID=cc.CountryID
LEFT JOIN DWH_dbo.Dim_EvMatchStatus dems ON dems.EvMatchStatusID=cc.EvMatchStatus
left join BI_DB_dbo.External_etoro_BackOffice_CustomerDocument cd on cd.CID=cc.RealCID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType cdtdt ON cdtdt.DocumentID=cd.DocumentID AND cdtdt.DocumentTypeID=18 --SelfieLivelines
where  
DATEDIFF(year,cc.BirthDate, cc.RegisteredReal)>=85
AND cc.IsValidCustomer=1
and cc.PlayerStatusID=1
and cc.VerificationLevelID=3
group by 
	cc.RealCID,
	CAST(cc.BirthDate AS DATE) ,
	CAST(cc.RegisteredReal AS DATE) ,
	DATEDIFF(year,cc.BirthDate, getdate()),  
	DATEDIFF(year,cc.BirthDate, cc.RegisteredReal) ,
	cc.VerificationLevelID,  
	CAST(cc.FirstDepositDate AS DATE) ,
	dr.Name ,
	dc.Name ,
	ps.Name ,
	cc.IsAddressProof,
	cc.IsIDProof,
	dems.EvMatchStatusName