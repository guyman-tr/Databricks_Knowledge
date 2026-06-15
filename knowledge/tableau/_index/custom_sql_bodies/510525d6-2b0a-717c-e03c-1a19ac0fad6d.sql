SELECT CASE WHEN a.AccountNumber IS NULL THEN e.ApexID ELSE a.AccountNumber END AS 'ApexAccount'
	  ,CASE WHEN a.eToroCID IS NULL THEN e.CID ELSE a.eToroCID END AS 'CID'
	  , CASE WHEN a.ProcessDate	IS NULL THEN   e.Date ELSE a.ProcessDate END AS 'ProcessDate'
	  ,a.TerminalID
	  ,a.Cusip
	  ,a.ApexDescription
	  ,a.eToroDescription AS  eToroDesc
	  ,a.eToroCorporateActionTypeID AS eToroCATypeID
	  ,a.CompensationReasonID	AS CompensationReasonID_eToro
	  ,a.OriginalQuantity
	  ,a.Amount
	  ,e.Payment
	  ,e.TotalCashChange
	  ,e.Description
	  ,e.UpdateDate
	  ,e.eToroCorporateActionTypeID
	  ,e.CA_Desc_ID
	  ,e.CA_Description
	  ,e.eToroDescription
FROM BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex a
FULL OUTER JOIN  BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro e ON 	
a.ProcessDate=e.Date 
AND a.Amount=e.Payment
AND e.ApexID=a.AccountNumber