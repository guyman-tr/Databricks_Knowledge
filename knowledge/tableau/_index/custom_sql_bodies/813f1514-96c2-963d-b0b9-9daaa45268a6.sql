SELECT pnl.CID, pnl.PositionPnL PositionPnL$, pnl.PositionID FROM BI_DB_dbo.BI_DB_PositionPnL pnl
WHERE pnl.DateID = (SELECT MAX(pnl.DateID) FROM BI_DB_dbo.BI_DB_PositionPnL pnl)