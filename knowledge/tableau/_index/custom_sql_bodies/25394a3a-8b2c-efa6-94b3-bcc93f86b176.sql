SELECT 
a.CID
,a.GCID
,CAST(a.FirstDepositDate AS DATE) AS 'FirstDepositDate'
,b.TIN_CountryID
,b.TIN_CountryName
,b.TIN_Value
,b.NoTIN_ReasonID
,b.NoTIN_Reason
,b.IsTIN_Mandatory
,b.TIN_UpdateDateTime
,b.TIN_UpdateDate
,b.TIN_UpdateDateID
,b.RN_TIN_CID_Country
,b.FieldID
,b.TypeID
,b.TypeIDName
,b.UpdateDate
,dr.Name AS 'Regulation_Name'
FROM BI_DB.dbo.BI_DB_CIDFirstDates a
INNER JOIN DWH.dbo.Dim_Regulation dr ON a.RegulationID = dr.DWHRegulationID
LEFT JOIN BI_DB.dbo.BI_DB_Tax_Compliance_TIN b ON a.CID = b.CID
WHERE a.FirstDepositDate IS NOT NULL 
      AND a.FirstDepositDate >= DATEADD(DAY, -15, GETDATE()-1)