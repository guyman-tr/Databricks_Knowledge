select Date
      ,'All' as Type
      ,RealizedEquity 
      ,Equity
      ,STD
	  ,NULL As NetMoneyIn
from BI_DB_dbo.BI_DB_rsk_DailyRiskAgg
union 
select Date
      ,'Copy - All' as Type
      ,CopyAUM as RealizedEquity
      ,AUMIncUnPnL as Equity
      ,CopySTD as STD
	  ,[NetMoneyIn - CopyAll] As NetMoneyIn
from BI_DB_dbo.BI_DB_rsk_DailyRiskAgg
union 
select Date
      ,'Manual' as Type
      ,ManualEquity as RealizedEquity
      ,Equity-AUMIncUnPnL as Equity
      ,FXSTD as STD
	  ,NULL As NetMoneyIn
from BI_DB_dbo.BI_DB_rsk_DailyRiskAgg
union 
select Date
      ,'Copy - Copyfund' as Type
      ,Copyfund_AUM as RealizedEquity
      ,Copyfund_AUMIncUnPnL as Equity
      ,CopyfundSTD as STD
	  ,[NetMoneyIn - Copyfund] As NetMoneyIn
from BI_DB_dbo.BI_DB_rsk_DailyRiskAgg
union 
select Date
      ,'Copy - Traders' as Type
      ,Traders_AUM as RealizedEquity
      ,Traders_AUMIncUnPnL as Equity
      ,CopytraderSTD as STD
	  ,[NetMoneyIn - Traders] As NetMoneyIn
from BI_DB_dbo.BI_DB_rsk_DailyRiskAgg