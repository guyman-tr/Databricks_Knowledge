SELECT [Date]
     
      ,[LP]
  ,count(distinct [InstrumentID]) eToro_Positions_EOD
  FROM [Dealing_dbo].[Dealing_Duco_EODRecon]
 where [Date] >= cast (Getdate () -10 as Date)
and LP <> ''
 and LP in ('FXCM','FD NDFs ToroHedge22 Deals','Global Prime','GS','GS COMMOD','IB CFD','IG','JPM','MarketMaker Direct CFDbook Real','Saxo CFD','Saxo FX&Commod','UBS','EDF')
and LiquidityAccountID is not null
group by [Date]
     
      ,[LP]