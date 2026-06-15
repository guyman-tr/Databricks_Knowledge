SELECT
   cbbil.IsSettled
  , cbbil.InstrumentType
  , cbbil.Regulation
  , cbbil.IsCreditReportValidCB
  , cbbil.IsValidCustomer
  , cbbil.AccountType
  , cbbil.Country
  , cbbil.IsOutlier
  , cbbil.Transition
  , cbbil.IsGermanBaFIN
  , cbbil.IsEtoroTradingCID
  , cbbil.IsGlenEagleAccount
  , cbbil.CommissionVersion
,TanganyStatus
,IsDLTUser
  , sum(cbbil.UnrealizedPnLChange				) as UnrealizedPnLChange			
  , sum(cbbil.RealizedPnL						) as RealizedPnL					
  , sum(cbbil.TotalPnL							) as TotalPnL						
  , sum(cbbil.UnrealizedCommissionChange		) as UnrealizedCommissionChange	
  , sum(cbbil.RealizedCommission				) as RealizedCommission			
  , sum(cbbil.UnrealizedFullCommissionChange	) as UnrealizedFullCommissionChange
  , sum(cbbil.RealizedFullCommission			) as RealizedFullCommission		
  , sum(cbbil.CommissionOnOpen					) as CommissionOnOpen				
  , sum(cbbil.FullCommissionOnOpen				) as FullCommissionOnOpen			
  , sum(cbbil.CommissionCloseAdjustment			) as CommissionCloseAdjustment		
  , sum(cbbil.FullCommissionCloseAdjustment		) as FullCommissionCloseAdjustment	
  , sum(cbbil.TotalCommission					) as TotalCommission				
  , sum(cbbil.TotalFullCommission				) as TotalFullCommission			
  , sum(cbbil.TotalZero							) as TotalZero	
  , sum(cbbil.TicketFeeByPercentOnClose			) AS TicketFeeByPercentOnClose
  , convert(varchar(6),Date,112) AS YearMonth
  , CASE WHEN di.IsFuture = 1 THEN 1 else 0 END AS IsRealFutures
  , cbbil.IsSQF
  , cbbil.TicketFeeByPercentPositionType
  , cbbil.DateID
, IsC2P,SettlementTypeID
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil -- select top 10 * from BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level
	JOIN DWH_dbo.Dim_Instrument di
		ON cbbil.InstrumentID = di.InstrumentID
WHERE cbbil.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)  AND  CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
GROUP BY 
	cbbil.IsSettled
  , cbbil.InstrumentType
  , cbbil.Regulation
  , cbbil.IsCreditReportValidCB
  , cbbil.IsValidCustomer
  , cbbil.AccountType
  , cbbil.Country
  , cbbil.IsOutlier
  , cbbil.Transition
  , cbbil.IsGermanBaFIN
  , cbbil.IsEtoroTradingCID
  , cbbil.IsGlenEagleAccount
  , convert(varchar(6),Date,112)
  , CASE WHEN di.IsFuture = 1 THEN 1 else 0 END 
,TanganyStatus
,IsDLTUser
, cbbil.CommissionVersion
  , cbbil.IsSQF
  , cbbil.TicketFeeByPercentPositionType
    , cbbil.DateID
, IsC2P,SettlementTypeID