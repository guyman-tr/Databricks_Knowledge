WITH base_trades AS (
  SELECT
    CAST(tr.ProcessDate AS DATE)                                          AS ProcessDate,
    tr.OfficeCode,
    tr.RegisteredRepCode,
    tr.BuySellCode,
    CASE WHEN tr.MarketCode = '5' THEN tr.OptionSymbolRoot ELSE tr.Symbol END AS OptionSymbolRoot,
    tr.MarketCode,
    tr.AccountNumber,
    tr.OrderID,
    tr.ExecutionTime,
    tr.Quantity,
    tr.NetAmount
  FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr
  JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
    ON tr.AccountNumber = am.AccountNumber
  WHERE tr.ProcessDate >= ADD_MONTHS(CURRENT_DATE(), -3)
    AND tr.AccountNumber NOT IN (
      '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007',
      '4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104'
    )
  GROUP BY
    CAST(tr.ProcessDate AS DATE),
    tr.OfficeCode, tr.RegisteredRepCode, tr.BuySellCode,
    CASE WHEN tr.MarketCode = '5' THEN tr.OptionSymbolRoot ELSE tr.Symbol END,
    tr.MarketCode, tr.AccountNumber, tr.OrderID, tr.ExecutionTime,
    tr.Quantity, tr.NetAmount
)

SELECT
  -- Time grain
  CAST(DATEADD(DAY, 7 - DAYOFWEEK(ProcessDate), ProcessDate) AS DATE) AS EoW_Sat,

  -- Regulation mapping
  CASE
    WHEN OfficeCode IN ('4GS', '5GU') THEN
      CASE RegisteredRepCode
        WHEN 'GAT' THEN 'FinCEN+FINRA'
        WHEN 'UK1' THEN 'FCA'
        WHEN 'FO1' THEN 'FINRAONLY'
        WHEN 'NY1' THEN 'NYDFS+FINRA'
      END
    WHEN LEFT(OfficeCode, 2) = '3E' THEN
      CASE RegisteredRepCode
        WHEN 'EAT' THEN 'FinCEN+FINRA'
        WHEN 'FO1' THEN 'FINRAONLY'
        WHEN 'NY1' THEN 'NYDFS+FINRA'
      END
  END AS Regulation,

  OptionSymbolRoot,

  CASE WHEN MarketCode = '5' THEN 'Options' ELSE 'Equities' END AS InstrumentType,

  -- Options contracts (4GS/5GU only)
  SUM(CASE WHEN OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1','UK1','NY1') AND BuySellCode = 'B' AND MarketCode = '5'
           THEN ABS(Quantity) END)   AS sum_contracts_buy,
  SUM(CASE WHEN OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1','UK1','NY1') AND BuySellCode = 'S' AND MarketCode = '5'
           THEN ABS(Quantity) END)   AS sum_contracts_sell,
  SUM(CASE WHEN OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1','UK1','NY1') AND MarketCode = '5'
           THEN ABS(Quantity) END)   AS sum_contracts_b_s,

  -- Options volume (4GS/5GU only)
  SUM(CASE WHEN OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1','UK1','NY1') AND BuySellCode = 'B' AND MarketCode = '5'
           THEN ABS(NetAmount) END)  AS sum_op_volume_buy,
  SUM(CASE WHEN OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1','UK1','NY1') AND BuySellCode = 'S' AND MarketCode = '5'
           THEN ABS(NetAmount) END)  AS sum_op_volume_sell,
  SUM(CASE WHEN OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('GAT','FO1','UK1','NY1') AND MarketCode = '5'
           THEN ABS(NetAmount) END)  AS sum_op_volume_b_s,

  -- Equities volume (3E + FO1/NY1 in 4GS/5GU)
  SUM(CASE WHEN (LEFT(OfficeCode, 2) = '3E' AND RegisteredRepCode IN ('ETA') AND BuySellCode = 'B' AND MarketCode <> '5')
                OR (OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('FO1','NY1') AND BuySellCode = 'B' AND MarketCode <> '5')
           THEN ABS(NetAmount) END)  AS sum_3E_volume_buy,
  SUM(CASE WHEN (LEFT(OfficeCode, 2) = '3E' AND RegisteredRepCode IN ('ETA') AND BuySellCode = 'S' AND MarketCode <> '5')
                OR (OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('FO1','NY1') AND BuySellCode = 'S' AND MarketCode <> '5')
           THEN ABS(NetAmount) END)  AS sum_3E_volume_sell,
  SUM(CASE WHEN (LEFT(OfficeCode, 2) = '3E' AND RegisteredRepCode IN ('ETA') AND MarketCode <> '5')
                OR (OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('FO1','NY1') AND MarketCode <> '5')
           THEN ABS(NetAmount) END)  AS sum_3E_volume_b_s,

  -- Equities trade counts (3E + FO1/NY1 in 4GS/5GU)
  COUNT(DISTINCT CASE WHEN (LEFT(OfficeCode, 2) = '3E' AND RegisteredRepCode IN ('ETA') AND BuySellCode = 'B' AND MarketCode <> '5')
                           OR (OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('FO1','NY1') AND BuySellCode = 'B' AND MarketCode <> '5')
                      THEN OrderID END) AS count_3E_trades_buy,
  COUNT(DISTINCT CASE WHEN (LEFT(OfficeCode, 2) = '3E' AND RegisteredRepCode IN ('ETA') AND BuySellCode = 'S' AND MarketCode <> '5')
                           OR (OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('FO1','NY1') AND BuySellCode = 'S' AND MarketCode <> '5')
                      THEN OrderID END) AS count_3E_trades_sell,
  COUNT(DISTINCT CASE WHEN (LEFT(OfficeCode, 2) = '3E' AND RegisteredRepCode IN ('ETA') AND MarketCode <> '5')
                           OR (OfficeCode IN ('4GS','5GU') AND RegisteredRepCode IN ('FO1','NY1') AND MarketCode <> '5')
                      THEN OrderID END) AS count_3E_trades_b_s

FROM base_trades

GROUP BY
  CAST(DATEADD(DAY, 7 - DAYOFWEEK(ProcessDate), ProcessDate) AS DATE),
  CASE
    WHEN OfficeCode IN ('4GS', '5GU') THEN
      CASE RegisteredRepCode
        WHEN 'GAT' THEN 'FinCEN+FINRA'
        WHEN 'UK1' THEN 'FCA'
        WHEN 'FO1' THEN 'FINRAONLY'
        WHEN 'NY1' THEN 'NYDFS+FINRA'
      END
    WHEN LEFT(OfficeCode, 2) = '3E' THEN
      CASE RegisteredRepCode
        WHEN 'EAT' THEN 'FinCEN+FINRA'
        WHEN 'FO1' THEN 'FINRAONLY'
        WHEN 'NY1' THEN 'NYDFS+FINRA'
      END
  END,
  OptionSymbolRoot,
  CASE WHEN MarketCode = '5' THEN 'Options' ELSE 'Equities' END