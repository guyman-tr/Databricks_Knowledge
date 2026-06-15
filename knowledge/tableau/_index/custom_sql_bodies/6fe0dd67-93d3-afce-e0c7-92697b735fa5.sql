SELECT  CAST(instrument_id AS INT) AS InstrumentID,
        symbol AS Symbol,
        name AS Name,
        instrument_display_name AS InstrumentDisplayName,
        CAST(marex_feed AS DECIMAL(18,2)) AS Marex_Fees,
        marex_ccy AS Marex_Ccy,
        CAST(exchange_fees AS DECIMAL(18,2)) AS Exchange_Fees,
        exchange_ccy AS Exchange_Ccy,
        CAST(nfa_fees AS DECIMAL(18,2)) AS Nfa_Fees,
        nfa_ccy AS Nfa_Ccy
FROM [BI_DB_dbo].[External_Fivetran_google_sheets_real_future_fees]