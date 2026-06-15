WITH hedge1 AS (
    SELECT 
        hedge_trades.Id,
        hedge_trades.OrderId,
        CASE WHEN hedge_trades.ApiQuantity > 0 THEN hedge_trades.ApiQuantity ELSE hedge_trades.ExecutedQuantity END AS quantity,
        CASE WHEN hedge_trades.ApiPrice > 0 THEN hedge_trades.ApiPrice ELSE hedge_trades.ExecutedPrice END AS Price,
        hedge_trades.Side,
                CASE WHEN hedge_trades.FeeCurrency is null or hedge_trades.FeeCurrency = 'USDC'
             then hedge_trades.Fee ELSE  hedge_trades.Fee*(CASE WHEN hedge_trades.ApiPrice > 0 
                                                                THEN hedge_trades.ApiPrice 
                                                                ELSE hedge_trades.ExecutedPrice 
                                                                END) 
              END AS Fee,
        inst.Name AS instrument,
        CAST(e.Name AS STRING) AS exchange,
        COALESCE(hedge_trades.ExecutionTime, hedge_trades.CreationTime) AS execution_time,
        CAST(hedge_trades.PartyName AS STRING) AS SourceName
    FROM main.dealing.bronze_marketmaker_dbo_hedgetrades AS hedge_trades
    JOIN main.dealing.bronze_marketmaker_dbo_exchanges e ON hedge_trades.ExchangeId = e.Id
    JOIN main.dealing.bronze_marketmaker_dbo_instruments inst ON hedge_trades.InstrumentId = inst.Id
    WHERE (hedge_trades.OrderStatus = 3 OR hedge_trades.OrderStatus = 1)
      AND hedge_trades.Id > 9166920 
      AND COALESCE(hedge_trades.ExecutionTime, hedge_trades.CreationTime) BETWEEN <[Parameters].[Parameter 1]> AND date_add(<[Parameters].[StartDate (copy)_-8844225206589988864]>, 1)
	  AND HedgeOrderId IS NOT NULL
),

hedge2 AS (
    SELECT 
        hedge_trades.Id,
        hedge_trades.OrderId,
        CASE WHEN hedge_trades.ApiQuantity > 0 THEN hedge_trades.ApiQuantity ELSE hedge_trades.ExecutedQuantity END AS quantity,
        CASE WHEN hedge_trades.ApiPrice > 0 THEN hedge_trades.ApiPrice ELSE hedge_trades.ExecutedPrice END AS Price,
        hedge_trades.Side,
                CASE WHEN hedge_trades.FeeCurrency is null or hedge_trades.FeeCurrency = 'USDC'
             then hedge_trades.Fee ELSE  hedge_trades.Fee*(CASE WHEN hedge_trades.ApiPrice > 0 
                                                                THEN hedge_trades.ApiPrice 
                                                                ELSE hedge_trades.ExecutedPrice 
                                                                END) 
              END AS Fee,
        inst.Name AS instrument,
        CAST(e.Name AS STRING) AS exchange,
        hedge_trades.CreationTime AS execution_time,
        '' AS SourceName
    FROM main.dealing.bronze_marketmaker_dbo_exchanges e
    JOIN main.dealing.bronze_marketmaker_dbo_manualhedgetrades AS hedge_trades ON hedge_trades.ExchangeId = e.Id
    JOIN main.dealing.bronze_marketmaker_dbo_instruments inst ON hedge_trades.InstrumentId = inst.Id
    WHERE hedge_trades.OrderId IS NOT NULL
      AND hedge_trades.Id > 110
      AND hedge_trades.CreationTime BETWEEN <[Parameters].[Parameter 1]> AND date_add(<[Parameters].[StartDate (copy)_-8844225206589988864]>, 1)
),

hedge_trades AS (
    SELECT * FROM hedge1 UNION ALL SELECT * FROM hedge2
),

Check_Union AS (
    SELECT      
        CAST(journal.Pid AS STRING) AS Order_Id_Internal,
        CAST(journal.Pid AS STRING) AS trade_id,
        Occurred,
        UserName,
        CAST(TradeDate AS DATE) AS TradeDate,
        rr.Name AS Provider,
        CASE WHEN OrderType = 0 THEN 'Buy' ELSE 'Sell' END AS Direction, 
        Symbol,
        (CASE WHEN OrderType = 1 THEN -1 ELSE 1 END) * Units AS Units,  
        Rate,
        (CASE WHEN OrderType = 0 THEN -1 ELSE 1 END) * Units * Rate AS ValueUSD,    
        TRY_CAST(journal.Comments AS DOUBLE) AS FeeAmount
    FROM main.bi_db.bronze_etoro_cryptoliquidity_cryptotrade journal 
    LEFT OUTER JOIN main.bi_db.bronze_etoro_cryptoliquidity_cryptowallets rr ON rr.Pid = journal.WalletId
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument tm ON tm.InstrumentID = journal.InstrumentId
    WHERE TradeDate BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[StartDate (copy)_-8844225206589988864]>

    UNION ALL

    SELECT 
        CAST(OrderId AS STRING) AS Order_Id_Internal,
        CAST(Id AS STRING) AS trade_id,
        execution_time AS Occurred,
        'MM' AS UserName,
        CAST(execution_time AS DATE) AS TradeDate,
        exchange AS Provider,
        CASE WHEN Side = 0 THEN 'Buy' ELSE 'Sell' END AS Direction,
        instrument AS Symbol,
        CASE WHEN Side = 0 THEN quantity ELSE -quantity END AS Units,
        Price AS Rate,
        CASE WHEN Side = 0 THEN -quantity * Price ELSE quantity * Price END - (CASE WHEN Fee = -1 THEN 0 ELSE Fee END) AS ValueUSD,
        (CASE WHEN Fee = -1 THEN 0 ELSE Fee END) AS FeeAmount
    FROM hedge_trades
    WHERE execution_time BETWEEN <[Parameters].[Parameter 1]> AND date_add(<[Parameters].[StartDate (copy)_-8844225206589988864]>, 1)
),

HBC AS (
    SELECT 
        CAST(OrderId AS STRING) AS Order_Id_Internal,
        CAST(ROW_NUMBER() OVER (ORDER BY ExecutionTime) AS STRING) AS trade_id,
        ExecutionTime AS Occurred,
        'MM' AS UserName,
        CAST(ExecutionTime AS DATE) AS TradeDate,
        'GDAX_HBC_Real' AS Provider,
        CASE WHEN Side = 0 THEN 'Buy' ELSE 'Sell' END AS Direction,
        mi.Name AS Symbol,
        (case when Side = 0 then 1 else -1 end)*(case when ApiQuantity > 0 then ApiQuantity else ExecutedQuantity end) Units,
        ApiPrice AS Rate,
        (case when Side = 0 then -1 else 1 end)*(case when ApiQuantity > 0 then ApiQuantity * ApiPrice else ExecutedQuantity * ExecutedPrice end) -(CASE WHEN Fee = -1 THEN 0 ELSE Fee END) AS ValueUSD,
        (CASE WHEN Fee = -1 THEN 0 ELSE Fee END) AS FeeAmount
    FROM main.bi_db.bronze_marketmaker_dbo_v_hbchedgetrades HT
    JOIN main.dealing.bronze_marketmaker_dbo_instruments mi ON mi.Id = HT.InstrumentId
    WHERE ApiQuantity <> 0 
    AND ExecutionTime BETWEEN <[Parameters].[Parameter 1]> AND date_add(<[Parameters].[StartDate (copy)_-8844225206589988864]>, 1)
    AND HT.OrderStatus IN (1,3)
	AND ClientOrderId IS NOT NULL
),

Talos AS (
    SELECT distinct
        CAST(t.OrderID AS STRING) AS Order_Id_Internal,
        CAST(t.TradeID AS STRING) AS trade_id,
        COALESCE(t.Timestamp, t.TransactTime) AS Occurred,
        'TALOS' AS UserName,
        CAST(COALESCE(t.Timestamp, t.TransactTime) AS DATE) AS TradeDate,
        t.Market AS Provider,
        t.Side AS Direction,
        t.Symbol AS Symbol,
        CASE WHEN t.Side = 'Sell' THEN (-1)*t.Quantity ELSE t.Quantity END AS Units,
        t.Price AS Rate,
        CASE WHEN t.Side = 'Sell' THEN -t.Quantity * t.Price ELSE t.Quantity * t.Price END AS ValueUSD,
        (ABS(t.Price - t.FeeCurrency) * t.Quantity) AS FeeAmount
    FROM main.general.gold_talos_trades t
    WHERE
    COALESCE(t.Timestamp, t.TransactTime) BETWEEN <[Parameters].[Parameter 1]> AND date_add(<[Parameters].[StartDate (copy)_-8844225206589988864]>, 1)
    AND t.OrderID IS NOT NULL
),

Final_Base AS (
    SELECT Order_Id_Internal, trade_id, Direction AS type, Symbol, Units, ValueUSD, Rate, TradeDate, Provider, FeeAmount, UserName, 'MM' AS Source FROM Check_Union
    UNION ALL SELECT Order_Id_Internal, trade_id, Direction, Symbol, Units, ValueUSD, Rate, TradeDate, Provider, FeeAmount, UserName, 'MM_HBC' FROM HBC
    UNION ALL SELECT Order_Id_Internal, trade_id, Direction, Symbol, Units, ValueUSD, Rate, TradeDate, Provider, FeeAmount, UserName, 'Talos' FROM Talos
),

Final_Mapped AS (
    SELECT 
        f.Order_Id_Internal,
        f.trade_id,
        f.TradeDate,
        f.type,
        f.Symbol as base_asset_code,
        f.Units as base_asset_amount,
        f.ValueUSD as counter_asset_amount,
        CASE WHEN f.UserName IN ('MM', 'TALOS') THEN COALESCE(ABS(f.ValueUSD/NULLIF(f.Units, 0)), 0) ELSE COALESCE(f.Rate, 0) END as calculated_rate,
        COALESCE(f.FeeAmount, 0) as notes,
        COALESCE(t.counterparty, f.Provider) as counterparty,
        COALESCE(t.tag, '') AS tags,
		Source
    FROM Final_Base f
    LEFT JOIN (SELECT DISTINCT counterparty, tag FROM main.dealing.bronze_fivetran_google_sheets_mappingsforcryptoreconcilation_counterparty) t ON LOWER(t.counterparty) = LOWER(f.Provider)
)

SELECT 
    CASE 
        WHEN <[Parameters].[Parameter 2]> = 'All Time' THEN 'All Time' -- תצוגה אחידה לכל התקופה
        WHEN <[Parameters].[Parameter 2]> = 'Day' THEN CAST(TradeDate AS STRING)
        WHEN <[Parameters].[Parameter 2]> = 'Week' THEN CAST(DATE_TRUNC('WEEK', TradeDate) AS STRING)
        WHEN <[Parameters].[Parameter 2]> = 'Month' THEN CAST(DATE_TRUNC('MONTH', TradeDate) AS STRING)
        WHEN <[Parameters].[Parameter 2]> = 'Quarter' THEN CAST(DATE_TRUNC('QUARTER', TradeDate) AS STRING)
        WHEN <[Parameters].[Parameter 2]> = 'Year' THEN CAST(DATE_TRUNC('YEAR', TradeDate) AS STRING)
        ELSE CAST(TradeDate AS STRING)
    END AS time_period,
    Order_Id_Internal AS OrderID,
    trade_id AS TRADEID,
    TradeDate,
    base_asset_code,
    type,
    tags,
    counterparty,
    calculated_rate AS rate,
    (CASE WHEN type = 'Sell' THEN -1 ELSE 1 END * ABS(base_asset_amount)) AS signed_base_amount,
    (CASE WHEN type = 'Sell' THEN 1 ELSE -1 END * ABS(counter_asset_amount)) AS signed_counter_amount,
    notes AS fees,
	Source
FROM Final_Mapped