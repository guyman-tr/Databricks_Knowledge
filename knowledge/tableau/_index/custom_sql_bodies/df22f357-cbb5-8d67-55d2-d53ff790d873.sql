SELECT  
cc.RealCID as CID,
cd.DocumentID,
	cc.VerificationLevelID, 
	ddt1.Name AS SuggestedDocumentType,
	dt.Comment as ClassificationComment,
	cd.Comment,
	ddt.Name as DocumentType, 
	m.FirstName +' '+ m.LastName as ClassifiedBy,
	dc.Name as Country,
	dr.Name as Regulation,
	cd.DateAdded as DocumentAdded
     FROM 
	 BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dt 
left join BI_DB_dbo.External_etoro_BackOffice_CustomerDocument cd   on dt.DocumentID=cd.DocumentID
left join DWH_dbo.Dim_Customer cc on cd.CID=cc.RealCID
left join BI_DB_dbo.External_etoro_Dictionary_DocumentType ddt on ddt.DocumentTypeID=dt.DocumentTypeID
left join BI_DB_dbo.External_etoro_Dictionary_DocumentType ddt1 on ddt1.DocumentTypeID=cd.SuggestedDocumentTypeID
left join DWH_dbo.Dim_Manager m on m.ManagerID=dt.ManagerID
join DWH_dbo.Dim_Country dc on cc.CountryID=dc.CountryID
left join DWH_dbo.Dim_Regulation dr on dr.ID=cc.RegulationID
where 
cd.SuggestedDocumentTypeID IN (19)	--3210 Letter