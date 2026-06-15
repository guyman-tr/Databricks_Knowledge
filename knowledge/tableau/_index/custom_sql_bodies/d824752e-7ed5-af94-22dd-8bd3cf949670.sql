SELECT  dp.PositionID
       ,dp.CID
       ,CAST(dp.OpenOccurred AS DATE) AS OpenDate
       ,dp.OpenDateID
       ,CAST(dp.CloseOccurred AS DATE) As CloseDate
       ,dp.CloseDateID
       ,di.`Exchange`
       ,di.InstrumentType
       ,da.BankAccountIBAN
       ,CASE 
        WHEN op.TreeID IS NOT NULL AND da.CurrencyBalanceISODesc = 
        CASE 
            WHEN di.SellCurrency = 'GBX' THEN 'GBP' 
            ELSE di.SellCurrency 
        END THEN 'IBAN LC'  
        WHEN op.TreeID IS NOT NULL AND da.CurrencyBalanceISODesc <> 
        CASE 
            WHEN di.SellCurrency = 'GBX' THEN 'GBP' 
            ELSE di.SellCurrency 
        END THEN 'IBAN Non-LC'
        WHEN op.TreeID IS NULL AND da.CurrencyBalanceISODesc = di.SellCurrency THEN 'TP LC'
        WHEN op.TreeID IS NULL AND da.CurrencyBalanceISODesc <> di.SellCurrency THEN 'TP Non-LC'
        ELSE 'Error' 
        END AS OpenSourceDetailed
      ,CASE 
        WHEN cl.PositionID IS NOT NULL AND da.CurrencyBalanceISODesc = 
        CASE 
            WHEN cl.ProcessCurrency = 'GBX' THEN 'GBP' 
            ELSE cl.ProcessCurrency 
        END THEN 'IBAN LC'  
        WHEN cl.PositionID IS NOT NULL AND da.CurrencyBalanceISODesc <> 
        CASE 
            WHEN cl.ProcessCurrency = 'GBX' THEN 'GBP' 
            ELSE cl.ProcessCurrency 
        END THEN 'IBAN Non-LC'
        WHEN cl.PositionID IS NULL AND da.CurrencyBalanceISODesc = di.SellCurrency THEN 'TP LC'
        WHEN cl.PositionID IS NULL AND da.CurrencyBalanceISODesc <> di.SellCurrency THEN 'TP Non-LC'
        ELSE 'Error' 
        END AS CloseSourceDetailed
       ,CASE WHEN op.TreeID is not null THEN 'IBAN' ELSE 'TP' END as OpenSource
       ,CASE WHEN cl.PositionID is not null THEN 'IBAN' ELSE 'TP' END as CloseSource
       ,da.CurrencyBalanceISODesc AS ClientsCurrency
       ,op.SellCurrency AS LCOpenCurrency
       ,cl.ProcessCurrency AS LCCloseCurrency
       ,di.SellCurrency AS InstrumentCurrency
       ,dp.InitialAmountCents/100 AS InitialAmountUSD
       ,dp.Leverage 
       ,dp.IsAirDrop
       ,dp.MirrorID
       ,dp.Amount
       ,da.Country
       ,da.RegCountry
       ,CASE WHEN da.CountryID = 218 THEN 'UK' ELSE 'EU' END as UK_EU
       ,CASE WHEN dp.IsPartialCloseChild = 0 or dp.IsPartialCloseChild is NULL THEN 0 ELSE 1 End as IsPartialCloseChild
       --,CASE WHEN op.TreeID IS NULL and op.DepositDate is not null THEN 1 else 0 end as Is_Deposit_WO_Position
FROM dwh.dim_position dp
INNER JOIN (SELECT di.InstrumentID
      ,di.InstrumentType
      ,di.Exchange
      ,di.InstrumentTypeID
      ,CASE WHEN di.SellCurrency='GBX' THEN 'GBP' ELSE di.SellCurrency END AS SellCurrency
FROM dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
WHERE di.InstrumentTypeID IN (5,6) ) di 
on dp.InstrumentID=di.InstrumentID 
INNER JOIN bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account da on dp.CID=da.Cid and da.IsValidCustomer=1 and da.GCID_Unique_Count=1 
LEFT JOIN bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban op on dp.PositionID=op.TreeID
LEFT JOIN bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban cl on dp.PositionID=cl.PositionID
WHERE COALESCE(dp.MirrorID, 0) = 0
      AND COALESCE(dp.IsAirDrop, 0) = 0
      AND dp.Leverage=1
      AND (dp.CloseOccurred>=date_add(week,-10,getdate()) OR dp.OpenOccurred>=date_add(week,-10,getdate()))