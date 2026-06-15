WITH ranked AS (
  SELECT 
    y.InstrumentID,
    x.InstrumentDisplayName,
    x.InstrumentType,
    y.Bid,
    y.Ask,
    y.OccurredAtServer,
    y.etr_ymd,
    y.LiquidityAccountID,
    ROW_NUMBER() OVER (
      PARTITION BY y.InstrumentID, y.LiquidityAccountID 
      ORDER BY y.OccurredAtServer DESC
    ) AS rn
  FROM main.dealing.bronze_pricesfromprovider_marketcurrencyprice y
  LEFT JOIN main.data_rooms.vw_dim_instrument x ON x.InstrumentID = y.InstrumentID
  WHERE y.etr_ymd = <[Parameters].[Parameter 2]>
)
SELECT InstrumentID, InstrumentDisplayName, InstrumentType, Bid, Ask, OccurredAtServer, etr_ymd, LiquidityAccountID
FROM ranked
WHERE rn = 1
ORDER BY OccurredAtServer DESC