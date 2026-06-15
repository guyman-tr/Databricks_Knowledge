----TABLEAU CUSTOM QUERY
SELECT  a.Date
	  ,a.DateID
	  ,a.ticker
	  ,a.InstrumentID
	  ,a.InstrumentType
	  ,a.InstrumentTypeID
	  ,a.no_of_comments
	  ,a.sentiment
	  ,a.sentiment_score
	  ,a.rn
	  ,cast(a.TotalZero as bigint) as TotalZero
	  ,a.TotalNop
	  ,b.Date AS LastWeekDate
	  ,b.DateID AS LastWeekDateID
	  ,b.no_of_comments AS LastWeekComments
	  ,b.sentiment AS LastWeekSentiment
	  ,b.sentiment_score AS LastWeekSentimentScore
	  ,cast(b.TotalZero as bigint) AS LastWeekZero
	  ,b.TotalNop AS LastWeekNOP
	  ,c.Date AS FourWeekAgoDate
	  ,c.DateID AS FourWeekAgoDateID
	  ,c.no_of_comments AS FourWeekAgoComments
	  ,c.sentiment AS FourWeekAgoSentiment
	  ,c.sentiment_score AS FourWeekAgoSentimentScore
	  ,c.TotalZero AS FourWeekAgoZero
	  ,c.TotalNop AS FourWeekAgoNOP 
	  	  ,d.Date AS YesterdayDate
	  ,d.DateID AS YesterdayDateID
	  ,d.no_of_comments AS YesterdayComments
	  ,d.sentiment AS YesterdaySentiment
	  ,d.sentiment_score AS YesterdaySentimentScore
	  ,cast(d.TotalZero as bigint) AS YesterdayZero
	  ,d.TotalNop AS YesterdayNOP 
	  ,dma.ADVRatio AS DayADVRatio
	  ,dma2.ADVRatio AS DayBeforeADVRatio
	  ,dma3.ADVRatio AS SevenDayADVRatio
          ,(cast(a.no_of_comments as float) - cast(d.no_of_comments as float))/cast(IIF(d.no_of_comments=0,Null,d.no_of_comments) as float) as YesterdayToday
          ,(cast(a.no_of_comments as float) - cast(b.no_of_comments as float))/cast(IIF(b.no_of_comments=0,Null,b.no_of_comments) as float) as SevenDayToday
          ,(cast(a.TotalZero as float) - cast(d.TotalZero as float) )/cast(IIF(a.TotalZero=0,Null,a.TotalZero) as float) as YesterdayTodayZero
          ,(cast(a.TotalZero as float) - cast(b.TotalZero as float))/cast(IIF(a.TotalZero=0,Null,a.TotalZero) as float) as SevenDayTodayZero
		  ,(cast(dma2.ADVRatio as float) - cast(dma.ADVRatio as float))/cast(IIF(dma2.ADVRatio=0,Null,dma2.ADVRatio) as float) as YesterdayTodayADV
		  ,(cast(dma3.ADVRatio as float) - cast(dma.ADVRatio as float))/cast(IIF(dma3.ADVRatio=0,Null,dma3.ADVRatio) as float) as SevenDayTodayADV
	  from Dealing.dbo.Dealing_TradingBI_RedditReport a
LEFT JOIN  Dealing.dbo.Dealing_TradingBI_RedditReport b
ON a.Date = DATEADD(DAY,7,b.Date) AND a.InstrumentID = b.InstrumentID
LEFT JOIN  Dealing.dbo.Dealing_TradingBI_RedditReport c
ON a.Date = DATEADD(WEEK, 4, c.Date) AND a.InstrumentID = c.InstrumentID
LEFT JOIN  Dealing.dbo.Dealing_TradingBI_RedditReport d
ON a.Date = DATEADD(day, 1, d.Date) AND a.InstrumentID = d.InstrumentID
LEFT JOIN Dealing.dbo.Dealing_TradingBI_RedditReport dma
ON a.Date = dma.Date AND a.InstrumentID = dma.InstrumentID
LEFT JOIN Dealing.dbo.Dealing_TradingBI_RedditReport dma2
ON a.Date =  DATEADD(day, 1, dma2.Date) AND a.InstrumentID = dma2.InstrumentID 
LEFT JOIN Dealing.dbo.Dealing_TradingBI_RedditReport dma3
ON a.Date =  DATEADD(day, 7, dma3.Date) AND a.InstrumentID = dma3.InstrumentID