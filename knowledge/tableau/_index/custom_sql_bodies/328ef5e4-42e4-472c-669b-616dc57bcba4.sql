SELECT 
 --  top 10000
        RealCID
--	  , ActionTypeID
--	  , InstrumentID
--	  , Leverage
	  , count(PositionID) AS CountPositions
	  , DateID
	  , IsSettled
          ,IsFuture
--	  , IsPartialCloseChild
	  , Metric
	  , sum(AmountUSD) AmountUSD
--	  , InstrumentTypeID
	  , IsBuy
	  , IsCopy
	  , HodledThroughPeriod
	  , OpenedInPeriod
	  , ClosedInPeriod
	  , sum(AmountEURO) AmountEURO
	  , IsFirstTrade
        , InstrumentType
        , IsSustainableEquity
, YearQuarter
, StartDateInt
, EndDateInt
 FROM  BI_DB_dbo.BI_DB_QST_CIF_V2_TradingWorld
/*
where RealCID in 
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
*/
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
, YearQuarter
,IsFuture