select 
distinct CID,
cd.DocumentID,
CAST(cd. DateAdded AS DATE) DateAdded,
country.Name as Country,
dr.Name as DesignatedRegulation,
suggested.Name as SuggestedDocumentType,
ddt.Name  AS DocumentType,
rej.RejectReasonName,
case when ven.Vendor is not null then 1 else 0 end as [SentToVendor]
--,
--cd.Comment as DocumentComment,
--dtdt.Comment as DocumentClassiificationComment,
--m1.FirstName +' '+ m1.LastName as AddedBy,
--m.FirstName +' '+ m.LastName as ClassifiedBy
from BI_DB_dbo.External_etoro_BackOffice_CustomerDocument cd
join DWH_dbo.Dim_Customer cc on cc.RealCID=cd.CID
join DWH_dbo.Dim_Country country on country.CountryID=cc.CountryID
join DWH_dbo.Dim_Regulation dr on dr.ID=cc.DesignatedRegulationID
Left JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dtdt On cd.DocumentID = dtdt.DocumentID
Left JOIN BI_DB_dbo.External_etoro_Dictionary_DocumentType ddt On dtdt.DocumentTypeID = ddt.DocumentTypeID
Left JOIN BI_DB_dbo.External_etoro_Dictionary_DocumentType suggested On suggested.DocumentTypeID = cd.SuggestedDocumentTypeID
left join [BI_DB_dbo].[External_etoro_BackOffice_DocumentVendors] ven on ven.DocumentID=cd.DocumentID
left join [BI_DB_dbo].[External_etoro_Dictionary_DocumentRejectReason] rej on rej.RejectReasonID=dtdt.RejectReasonID
--left join BI_DB_dbo.External_etoro_Dictionary_DocumentClassification class on class.DocumentClassificationID=dtdt.DocumentClassificationID
--left join  DWH_dbo.Dim_Manager m on m.ManagerID=dtdt.ManagerID	
--left join  DWH_dbo.Dim_Manager m1 on m1.ManagerID=cd.ManagerID	
where cd.DateAdded>= dateadd(month,DATEDIFF(MONTH,0,getdate())-3,0)