WITH ranked AS (
  SELECT 
    Exchange,
    Instrument,
    SendingTime,
    Asks.Price[0] AS AskPrice,
    Bids.Price[0] AS BidPrice,
    ROW_NUMBER() OVER (
      PARTITION BY Exchange, Instrument
      ORDER BY SendingTime DESC
    ) AS rn
  FROM main.dealing.bronze_dealingstreaming_marketmaker_dealing_market_maker_raw_order_book_data
  WHERE etr_ymd = <[Parameters].[Parameter 2]>
)
SELECT Exchange, Instrument, SendingTime, AskPrice, BidPrice
FROM ranked
WHERE rn = 1