select tt.DateID
      ,tt.Date
	  ,tt.TimeFrame
	  ,tt.rank
	  ,tt.InstrumentType
	  ,tt.InstrumentID
	  ,tt.Amount
	  ,tt.AssetType
	  ,tt.AmountType
	  ,tt.UpdateDate
          ,COALESCE(dc.UserName,di.InstrumentDisplayName) Instrument 
from dbo.BI_DB_Investors_Top10 tt
left join [DWH].[dbo].[Dim_Customer] dc
ON tt.InstrumentID = dc.RealCID
AND tt.InstrumentType IN ('Portfolio','PI')
LEFT JOIN [DWH].[dbo].[Dim_Instrument] di
ON tt.InstrumentID = di.InstrumentID
UNION
select CONVERT(CHAR(8),DATEADD(DAY,-1,tt.Date),112)DateID
      ,DATEADD(DAY,-1,tt.Date) Date
	  ,'StartOfYear'TimeFrame 
	  ,tt.rank
	  ,tt.InstrumentType
	  ,tt.InstrumentID
	  ,tt.Amount
	  ,tt.AssetType
	  ,tt.AmountType
	  ,tt.UpdateDate
          ,COALESCE(dc.UserName,di.InstrumentDisplayName) Instrument 
from dbo.BI_DB_Investors_Top10 tt
left join [DWH].[dbo].[Dim_Customer] dc
ON tt.InstrumentID = dc.RealCID
AND tt.InstrumentType IN ('Portfolio','PI')
LEFT JOIN [DWH].[dbo].[Dim_Instrument] di
ON tt.InstrumentID = di.InstrumentID
WHERE tt.Date = DATEFROMPARTS(YEAR(tt.Date),1,2)
AND tt.TimeFrame = 'Yesterday'
AND tt.AmountType = 'AUA_AUM'