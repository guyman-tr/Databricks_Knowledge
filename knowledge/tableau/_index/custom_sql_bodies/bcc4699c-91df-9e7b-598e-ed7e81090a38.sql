SELECT  
 p.InstrumentID
,CommissionVersion
, PositionID
,b.RealCID
--,ClosePositionActionName
,ClosePositionReasonID
,OpenOccurred
,CloseOccurred  CloseOccurredTime
,Cast( p.CloseOccurred AS DATE) CloseOccurred
,EOMONTH(CloseOccurred)EOM
,NetProfit
,CloseTotalFees
,FullCommissionOnClose
,VolumeOnClose
,CloseMarketSpread
, p.IsBuy
,CloseMarketSpread+CloseTotalFees CloseFeePlusCloseSpread
,b.RegulationID
,dr1.Name Regulation
FROM [DWH_dbo].[Dim_Position] p 
   JOIN [DWH_dbo].[Fact_SnapshotCustomer] b 
      ON p.CID=b.RealCID
   JOIN [DWH_dbo].[Dim_Range] dr 
      ON dr.DateRangeID =  b.DateRangeID
	  AND CloseDateID BETWEEN dr.FromDateID AND dr.ToDateID 
   JOIN [DWH_dbo].[Dim_Instrument] ii 
      ON ii.InstrumentID=p.InstrumentID
   JOIN DWH_dbo.Dim_Regulation dr1
	ON b.RegulationID=dr1.DWHRegulationID
WHERE b.CountryID=94 
 AND IsSettled=1 
 AND CloseDateID>='20251218' 
  
and CloseOccurred >=<[Parameters].[Parameter 1]>
 AND InstrumentTypeID=10 
 AND IsValidCustomer=1