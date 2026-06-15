SELECT
    cbbil.InstrumentID
  , cbbil.IsBuy
  , cbbil.Regulation
  , cbbil.IsCreditReportValidCB
  , cbbil.IsValidCustomer
  , cbbil.Country
  , sum(cbbil.TotalFullCommission) TotalFullCommission
  , sum(cbbil.TotalCommission) TotalCommission
  , sum(cbbil.TotalZero			 ) TotalZero
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE
	cbbil.DateID BETWEEN CAST (FORMAT (CAST (<[Parameters].[Parameter 7]> AS DATE), 'yyyyMMdd') AS INT) AND CAST (FORMAT (CAST (<[Parameters].[Parameter 8]> AS DATE), 'yyyyMMdd') AS INT)
	AND cbbil.InstrumentID=624
GROUP BY 
	cbbil.InstrumentID
  , cbbil.IsBuy
  , cbbil.Regulation
  , cbbil.IsCreditReportValidCB
  , cbbil.Country
  , cbbil.IsValidCustomer