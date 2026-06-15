with tx as (
    SELECT distinct
                    'Buy' AS ActionType, 
                    dp.OpenDateID AS DateID, 
                    cast(dp.OpenOccurred AS DATE) Date, 
                    dp.CID, 
					di.Name AS Instrument, 
                    di.InstrumentID, 
                    dp.RegulationIDOnOpen,
					dp.PositionID, 
                    dp.InitialAmountCents/100 AS Amount
				FROM main.dwh.dim_position dp
				JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
                    ON dp.InstrumentID = di.InstrumentID 
                        AND di.InstrumentTypeID=10
				JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
					ON dp.CID=dc.RealCID
						AND dc.IsValidCustomer = 1
				WHERE 
                    dp.RegulationIDOnOpen IN (7,8,14) 
                    AND dp.OpenOccurred >= date_add(YEAR, -2, current_timestamp())
                    and coalesce(dp.IsAirDrop, 0) != 1              -- filter out air drops
		    and COALESCE(dp.IsPartialCloseChild, 0) != 1    -- filter out buys auto generated from partial closure
    
    UNION

    SELECT Distinct 
					'Sell' AS ActionType, 
                    dp.CloseDateID AS DateID, 
                    cast(dp.CloseOccurred AS DATE) Date,
					dp.CID , 
					di.Name AS Instrument, 
                    di.InstrumentID, 
                    dp.RegulationIDOnOpen,
					dp.PositionID, 
                    dp.Amount+dp.NetProfit as Amount
				FROM main.dwh.dim_position dp
				JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
                    ON dp.InstrumentID = di.InstrumentID 
                        AND di.InstrumentTypeID=10
				JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
					ON dp.CID=dc.RealCID
						AND dc.IsValidCustomer = 1
				WHERE 
                    dp.RegulationIDOnOpen IN (7,8,14) 
		    and dp.CloseOccurred >= date_add(YEAR, -2, current_timestamp()) 
                    and coalesce(dp.IsAirDrop, 0) != 1              -- filter out air drops
		    and COALESCE(dp.IsPartialCloseChild, 0) != 1    -- filter out buys auto generated from partial closure
)

SELECT RegulationIDOnOpen,
    `Date` as FullDate, DateID,
    --ActionType,
    Instrument,
    InstrumentID,
    count(distinct case when ActionType='Buy' then PositionID end) as NumberOfTrades_Buy,
    count(distinct case when ActionType='Sell' then PositionID end) as NumberOfTrades_Sell,
    sum(distinct case when ActionType='Buy' then Amount end) as VolumeOnOpen,
    sum(distinct case when ActionType='Sell' then Amount end) as VolumeOnClose
FROM tx 
--where InstrumentID=100000
group by `Date`, DateID,
    --ActionType,
    Instrument,
    InstrumentID,
RegulationIDOnOpen