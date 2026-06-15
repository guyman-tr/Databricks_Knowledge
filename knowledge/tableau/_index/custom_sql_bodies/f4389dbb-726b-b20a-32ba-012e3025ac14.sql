SELECT 
*
 FROM  BI_DB_dbo.BI_DB_RBSF_V2_TradingWorld
where Metric <> 'FullComission'

--/*
and RealCID in 
(
9668798
,12404260
,24848304
,33690551
,23069373
,32385399
,5917228
,8534315
,21167515
,5210374
)
--*/
/*
 GROUP BY RealCID
		 , DateID
	  , IsSettled
	  , Metric
--	  , InstrumentTypeID
	  , IsBuy
	  , IsCopy
	  , HodledThroughPeriod
	  , OpenedInPeriod
	  , ClosedInPeriod
	  , IsFirstTrade
 --       , InstrumentID
        , InstrumentType
        , IsSustainableEquity
        , StartDateInt
        , EndDateInt
        ,IsFinancialInstrument
	,IsNegativeMarket
	,KYCNeverTraded
*/