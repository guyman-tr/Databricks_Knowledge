SELECT T.* 
FROM 
(SELECT        a.Date
             ,a.InstrumentID
             ,a.IsBuy
             ,a.IsSettled
             ,a.EOD_NOP
             ,a.Units
             ,a.Pre_MarketNOP
             ,a.PreOpenAsk
             ,a.PreOpenBid
             ,a.EOD_Ask
             ,a.EOD_Bid
             ,a.Percentage_Change
             ,a.UpdateDate
             ,a.InstrumentDisplayName
             ,ROW_NUMBER() OVER (PARTITION BY a.Date, a.InstrumentID,a.IsSettled ORDER BY a.UpdateDate DESC) AS RN
  
FROM main.bi_dealing.bi_output_dealing_pricespreus_open a
WHERE a.PreOpenAsk > 0.01 AND a.PreOpenBid > 0.01
AND ((a.PreOpenAsk-a.PreOpenBid)/a.PreOpenAsk)<0.05
)T
Where T.RN=1
ORDER BY T.Date DESC,T.Percentage_Change desc 
limit 20