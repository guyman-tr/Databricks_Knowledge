Select cc.RealCID as CID, cc.UserName, cc.GuruStatusID AS [PI Level], gc.ncopiers As Copiers, gc.AUM/*, risk.RiskScore*/, sa.ActionDate, sat.ActionName As ActivityType, sa.MessageText
From BI_DB_dbo.BI_DB_Social_Activity sa WITH (NOLOCK)
join DWH_dbo.Dim_Customer cc WITH (NOLOCK)
on sa.RealCID = cc.RealCID
and cc.GuruStatusID >= 2
Join BI_DB_dbo.BI_DB_Social_Activity_Type sat WITH (NOLOCK)
on sa.ActionTypeID = sat.ActionID
Join (select g.ParentUserName
      ,g.ParentCID
	  ,sum(isnull(Cash,0))+sum(isnull(Investment,0))+sum(isnull(PnL,0))+sum(isnull([DetachedPosInvestment],0))+sum(isnull([Dit_PnL],0)) as AUM
      ,count(*) AS ncopiers
      from general.etoroGeneral_History_GuruCopiers g WITH (NOLOCK)
      Where Timestamp = CAST(DateAdd(Day,0,GetDate()) As Date)
      Group By g.ParentUserName, g.ParentCID
	  ) gc
on sa.RealCID = gc.ParentCID
Where ActionDate > DateAdd(Month,-3,GetDate())
and sa.ActionTypeID In (1,2)