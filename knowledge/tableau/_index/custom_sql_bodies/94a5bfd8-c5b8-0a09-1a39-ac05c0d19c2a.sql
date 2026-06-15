select 
p.OccurredDate,
i.InstrumentTypeID,
i.InstrumentType,
i.InstrumentID,
i.Name,
p.AskSpreaded,
p.BidSpreaded,
p.Ask,
p.Bid,
u.USD_cr_Long ConvertRatesIsBuy_1,
u.USD_cr_Short as ConvertRatesIsSell_0
From BI_DB..BI_DB_EOD_USD_cr u
join DWH..Dim_Instrument i on i.InstrumentID=u.InstrumentID
Join DWH..Fact_CurrencyPriceWithSplit p on p.InstrumentID=u.InstrumentID and p.OccurredDateID=u.DateID 
Where p.OccurredDate >= dateadd(day,-90,getdate())
and InstrumentTypeID in (5, 6)