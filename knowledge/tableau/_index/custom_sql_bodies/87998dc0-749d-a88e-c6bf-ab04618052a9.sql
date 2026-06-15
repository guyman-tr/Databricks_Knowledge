SELECT Timestamp,
Case When g.ParentCID IN (4657433,5572727,5572968,5621786,5572972,4657429,5351524,5351549,5826887,5572971,5716252,5572963,5621803,5351526,5351544,5572719,5572725,5572728,5621797,5621814,5826882,6059010,5993821,6062790,5993849,6036568) then 'CopyFunds'
     When dc2.GuruStatusID IN (2,3,4,5) then 'PI'
	 else 'Non-PI' End As CopyType, sum(isnull(Cash,0))+sum(isnull(Investment,0))+sum(isnull(PnL,0))+sum(isnull([DetachedPosInvestment],0))+sum(isnull([Dit_PnL],0)) As AUM
FROM general.etoroGeneral_History_GuruCopiers g
join DWH_dbo.Dim_Customer dc
on g.CID = dc.RealCID
and dc.PlayerLevelID <> 4
join DWH_dbo.Dim_Customer dc2
on g.ParentCID = dc2.RealCID
WHERE Timestamp in (Cast(DATEadd(Month,-1,GetDate()) As Date),Cast(DATEadd(day,-8,GetDate()) As Date),Cast(DATEadd(day,-2,GetDate()) As Date),Cast(DATEadd(day,-1,GetDate()) As Date))
Group By Timestamp,
Case When g.ParentCID IN (4657433,5572727,5572968,5621786,5572972,4657429,5351524,5351549,5826887,5572971,5716252,5572963,5621803,5351526,5351544,5572719,5572725,5572728,5621797,5621814,5826882,6059010,5993821,6062790,5993849,6036568) then 'CopyFunds'
     When dc2.GuruStatusID IN (2,3,4,5) then 'PI'
	 else 'Non-PI' END