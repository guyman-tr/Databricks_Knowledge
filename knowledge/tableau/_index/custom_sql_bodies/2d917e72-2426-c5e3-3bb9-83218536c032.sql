select 
count(DocumentID) as NoOfDocs,
DocumentType,
VerificationLevelID,
DesignatedRegulation,
YearExpiryDate,
MonthExpiryDate,
RiskClassification,
year_month,
PlayerStatus
from (
SELECT
cd.DocumentID,
ddt.Name  AS DocumentType,
cc.VerificationLevelID,
dr.Name as DesignatedRegulation,
year(max(dtdt.ExpiryDate) )as YearExpiryDate,
month(max(dtdt.ExpiryDate)) as MonthExpiryDate,
CONVERT(VARCHAR(6), max(dtdt.ExpiryDate), 112) AS year_month,
RC.RiskScoreName AS RiskClassification,
ps.Name as PlayerStatus
from BI_DB_dbo.External_etoro_BackOffice_CustomerDocument cd
join DWH_dbo.Dim_Customer cc on cc.RealCID=cd.CID
join DWH_dbo.Dim_Regulation dr on dr.ID=cc.DesignatedRegulationID
Left JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dtdt On cd.DocumentID = dtdt.DocumentID
Left JOIN BI_DB_dbo.External_etoro_Dictionary_DocumentType ddt On dtdt.DocumentTypeID = ddt.DocumentTypeID
LEFT JOIN [BI_DB_dbo].[External_RiskClassification_dbo_V_RiskClassificationDataLake] RC ON RC.CID=cd.CID
join DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=cc.PlayerStatusID
where dtdt.DocumentTypeID in (1,2)  and cc.PlayerStatusID not in (2,4) and cc.VerificationLevelID in (2,3)
group by
cd.DocumentID ,
ddt.Name ,
cc.VerificationLevelID,
dr.Name ,
RC.RiskScoreName ,
ps.Name) A
GROUP BY 
DocumentType,
VerificationLevelID,
DesignatedRegulation,
YearExpiryDate,
MonthExpiryDate,
RiskClassification,
year_month,
PlayerStatus