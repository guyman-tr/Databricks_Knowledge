/****** Script for SelectTopNRows command from SSMS  ******/
SELECT dd.[date]
      ,dd.[CallID]
      ,dd.[CreatedDate]
      ,dd.[SystemModstamp]
      ,dd.[CallDuration]
	  ,dd.[Call_Summary__c]
      ,dd.[Engagement_Topics__c]
      ,dd.[Instruments__c]
      ,dd.[Manager]
      ,dd.[Instrument]
      ,dd.[ZoomCall]
      ,dd.[CID]
      ,dd.[Desk]
      ,dd.[UpdateDate]
	  ,ISNULL(ISNULL(di.InstrumentDisplayName,dm.ParentUserName),di1.SymbolFull) InstrumentName
	  ,MIN(dp.OpenOccurred) InstrumentOpenOccurred
	  ,MIN(dp.CloseOccurred) InstrumentCloseOccurred
	  ,MIN(dm.OpenOccurred) MirrorOpenOccurred
	  ,MIN(dm.CloseOccurred) MirrorCloseOccurred
  FROM BI_DB_dbo.BI_DB_Instrument_Details_During_Call dd
  LEFT JOIN DWH_dbo.Dim_Instrument di
  ON Instrument = di.InstrumentDisplayName
  LEFT JOIN DWH_dbo.Dim_Mirror dm 
  ON dd.CID=dm.CID
  and dm.ParentUserName = Instrument
  AND ((dm.OpenOccurred>= dd.date AND dm.OpenOccurred<=DATEADD(dd,30,dd.date))
		or (dm.CloseOccurred>= dd.date AND dm.CloseOccurred<=DATEADD(dd,30,dd.date))) 
  LEFT JOIN DWH_dbo.Dim_Instrument di1
  ON Instrument = di1.SymbolFull
  LEFT JOIN DWH_dbo.Dim_Position dp
  ON dd.CID = dp.CID
  AND (di.InstrumentID = dp.InstrumentID
		OR di1.InstrumentID = dp.InstrumentID)
  AND ((dp.OpenOccurred>= dd.date AND dp.OpenOccurred<=DATEADD(dd,30,dd.date))
		or (dp.CloseOccurred>= dd.date AND dp.CloseOccurred<=DATEADD(dd,30,dd.date)))
  AND dp.MirrorID = 0
  WHERE dd.Instrument NOT IN ('NULL','Null')
  AND dd.date>='20230301'
  GROUP BY dd.[date]
      ,dd.[CallID]
      ,dd.[CreatedDate]
      ,dd.[SystemModstamp]
      ,dd.[CallDuration]
	  ,dd.[Call_Summary__c]
      ,dd.[Engagement_Topics__c]
      ,dd.[Instruments__c]
      ,dd.[Manager]
      ,dd.[Instrument]
      ,dd.[ZoomCall]
      ,dd.[CID]
      ,dd.[Desk]
      ,dd.[UpdateDate]
	  ,ISNULL(ISNULL(di.InstrumentDisplayName,dm.ParentUserName),di1.SymbolFull)