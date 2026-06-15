SELECT  Date,
 Hour_Start ,
 Hour_End ,
 HedgeServerID ,
 InstrumentID ,
 InstrumentName ,
 BidLast ,
 AskLast ,
 Leverage , 
  ClientNOP ,
 OP_Long ,
 OP_Short ,
 ClientsVolumeBuy ,
 ClientsVolumeSell ,
 EtoroVolumeBuy ,
 EtoroVolumeSell ,
 EtoroNOP ,
 TotalZero ,
  FullCommission ,
  RollOverFee ,
 eToroPNL ,
 getdate() UpdateDate
 From dbo.Dealing_CommoditiesDailyReport_ClientvsEtoro