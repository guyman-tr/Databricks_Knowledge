select 
dr.ReportTime
,dr.CID
,dr.UserName
,dr.AUM
,dr.RealizedEquity
,dr.Tier
,dr.Country
,dr.Region
,dr.Manager
,dr.RiskScore
,dr.RiskScore_prev2
,dr.CopiedBlock
,dr.Copiers
,dr.BlockReason
,dr.UpdateDate
,dr.RiskJumpOver3
,dr.InactiveLoginner
,dr.InactiveFeedPoster
,dr.InactiveTrader
,dr.EliteClassificationChange
,dr.Lost10Percent
,dr.HoldsHighLevPosition
,dr.HighLevHoldingDetail
,dr.InvestedValueover30
,dr.Value_percenet
,dr.MostInvestedInstrument
,dr.FromClassification
,dr.CurrentClassification
,dr.LastLoggedIn
,dr.LastPosOpenDate
,dr.LastPublishedPostDate
,dr.DaysAsPI
,dr.Equity
,dr.ClosedAllPositions
,dr.BlockedOccurred
,dr.BuyPercent
,dr.SellPercent
,dr.LastAvgRiskScore
,dr.MaxRisckScore2Months
,dr.PlayerStatus

,max(case when dr.CopiedBlock=0 and bl.CID is not null then 1 
when dr.CopiedBlock=1 then dr.CopiedBlock else 0 END) as CopiedBlock_new
from BI_DB_dbo.BI_DB_DailyRiskAlert  dr 
left join 
(
Select CID,BlockReasonID,Occurred,OperationTypeID
 from [BI_DB_dbo].[External_etoro_Customer_BlockedCustomerOperations]
where OperationTypeID = 2  )as bl on bl.CID=dr.CID
--where dr.CID=13626563
group by 
dr.ReportTime
,dr.CID
,dr.UserName
,dr.AUM
,dr.RealizedEquity
,dr.Tier
,dr.Country
,dr.Region
,dr.Manager
,dr.RiskScore
,dr.RiskScore_prev2
,dr.CopiedBlock
,dr.Copiers
,dr.BlockReason
,dr.UpdateDate
,dr.RiskJumpOver3
,dr.InactiveLoginner
,dr.InactiveFeedPoster
,dr.InactiveTrader
,dr.EliteClassificationChange
,dr.Lost10Percent
,dr.HoldsHighLevPosition
,dr.HighLevHoldingDetail
,dr.InvestedValueover30
,dr.Value_percenet
,dr.MostInvestedInstrument
,dr.FromClassification
,dr.CurrentClassification
,dr.LastLoggedIn
,dr.LastPosOpenDate
,dr.LastPublishedPostDate
,dr.DaysAsPI
,dr.Equity
,dr.ClosedAllPositions
,dr.BlockedOccurred
,dr.BuyPercent
,dr.SellPercent
,dr.LastAvgRiskScore
,dr.MaxRisckScore2Months
,dr.PlayerStatus