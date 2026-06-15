SELECT l.Date
	  ,l.InstrumentID
	  ,l.Exchange
	  ,l.Max_Latency
	  ,l.Avg_Latency
	  ,l.Med_Latency
	  ,l.UpdateDate
	  ,di.InstrumentDisplayName
FROM dbo.Dealing_Latency_ByInstrument l
LEFT JOIN DWH..Dim_Instrument di
ON l.InstrumentID = di.InstrumentID