select RE.*, DP.HedgeServerID as CurrentHS
from BI_DB_Real_ETF RE
join DWH.dbo.Dim_Position DP
on RE.PositionID = DP.PositionID