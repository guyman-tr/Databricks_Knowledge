SELECT 
 --   top 100000
            RealCID
--	  , InstrumentID
	  , IsCopy
	  , IsBuy
	  , IsSettled
--	  , InstrumentTypeID
	  , InstrumentType
	  , DateID
	  , sum(AmountUSD) AS AmountUSD
	  , sum(PositionPnLUSD) AS PositionPnLUSD
	  , sum(AmountEURO) AS AmountEURO
	  , sum(PositionPnLEURO) AS PositionPnLEURO
	  , count(PositionID) AS CountPos
        , IsSustainableEquity
        , sum(TotalEquityUSD) AS TotalEquityUSD
	, sum(TotalEquityEuro) AS TotalEquityEuro
        , IsFinancialInstrument
 FROM BI_DB_dbo.BI_DB_RBSF_V2_EquityWorld
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
 GROUP BY 
 RealCID
--	  , InstrumentID
	  , IsCopy
	  , IsBuy
	  , IsSettled
--	  , InstrumentTypeID
	  , InstrumentType
	  , DateID
        , IsSustainableEquity
        , IsFinancialInstrument