SELECT 
        c.AccountNumber, c.ProcessDate, c.OrderId, c.Quantity, c.BuySellCode, c.NetAmount, c.RegisteredRepCode
    FROM 
        [BI_DB_dbo].[External_Sodreconciliation_apex_EXT872_TradeActivity] c
    WHERE 
        c.OfficeCode in ('4GS','5GU') 
        AND c.MarketCode ='5'
        and BuySellCode in ( 'B', 'S')
AND RegisteredRepCode in ('GAT','FO1')
    GROUP BY 
        c.AccountNumber, c.ProcessDate, c.OrderId, c.Quantity, c.BuySellCode, c.NetAmount, c.RegisteredRepCode