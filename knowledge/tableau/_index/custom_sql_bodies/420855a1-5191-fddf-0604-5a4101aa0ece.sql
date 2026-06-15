SELECT bdramt.*,
dm.FirstName + ' ' + dm.LastName AS Agent,
country.Name as Country,
r.Name as Regulation

FROM BI_DB.dbo.BI_DB_Risk_AlertManagementTool bdramt
LEFT JOIN DWH.dbo.Dim_Manager dm ON dm.ManagerID=bdramt.ModifiedBy
LEFT JOIN DWH.dbo.Dim_Customer c ON c.RealCID= bdramt.CID
LEFT JOIN DWH.dbo.Dim_Country country ON country.CountryID=c.CountryID
LEFT JOIN DWH.dbo.Dim_Regulation r on r.ID=c.RegulationID
WHERE bdramt.CreationDate>='20220101'