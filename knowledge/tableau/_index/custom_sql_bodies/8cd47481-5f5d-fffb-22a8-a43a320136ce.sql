SELECT
  --convert(varchar(6),Date,112) AS YearMonth, cbbil.DateID
  EOMONTH(Date) EoM
  , cbbil.Regulation
  , cbbil.US_State AS StateShortName
  , dsap.Name StateName
  , sum(cbbil.CommissionCloseAdjustment) as CommissionCloseAdjustment		
  , sum(cbbil.TicketFeeByPercentOnClose) AS TicketFeeByPercentOnClose
  --, SUM(cbbil.TicketFeeByPercentOnOpen) AS TicketFeeByPercentOnOpen
  , sum(cbbil.CommissionCloseAdjustment) 
    + sum(cbbil.TicketFeeByPercentOnClose) AS 'Closed commission adjustment'
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil 
	JOIN DWH_dbo.Dim_Instrument di ON cbbil.InstrumentID = di.InstrumentID
	LEFT JOIN DWH_dbo.Dim_State_and_Province dsap ON dsap.CountryID=219
		AND cbbil.US_State = dsap.ShortName
WHERE cbbil.DateID>=20190101 --between 20250701 AND 20250831
    and cbbil.Regulation in ('FinCEN', 'FinCEN+FINRA', 'eToroUS')
    AND cbbil.IsCreditReportValidCB=1
    AND cbbil.IsEtoroTradingCID=0
    AND cbbil.IsGlenEagleAccount=0
    AND (cbbil.IsDLTUser=0 OR cbbil.IsDLTUser is null)
    AND di.IsFuture=0
GROUP BY 
  EOMONTH(Date)
  , cbbil.Regulation
  , cbbil.US_State
  , dsap.Name