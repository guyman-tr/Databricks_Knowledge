select r1.N, r1.first_day, r1.last_day, r1.CID, r1.Club, r1.PositionID, r1.Regulation, LEFT(r1.Instrument,3) as Asset, r1.OpenOccurred, r1.CloseOccurred, r1.CloseDateID, r1.RealOpenDate, r1.RealCloseDate,
    r1.Leverage, r1.EffectiveAmountInUnitsDecimal, r1.AmountInUnitsDecimal, r1.MinDaysEligible, r1.Rewards,
    r2.PosDays, r2.RealPosDays, r2.EligibleDyas,
    r3.UserRevShare, r3.EffectiveAvgPositionPerCustomer, r3.Effectiveyield, r3.EffectiveRewardsPerCustomer,
    (AskLast+BidLast)/2 as USDprice, w.IsWaiver,
    case when vl.Credit < 0 then 'Yes' else 'No' end as [Credit Issue], r1.staking_month
from EXE.dbo.staking_raw1 r1 
left join EXE.dbo.staking_raw2 r2 on r1.PositionID = r2.PositionID and r1.staking_monthID = r2.staking_monthID
left join EXE.dbo.staking_raw3 r3 on r3.CID = r1.CID and lower(r3.Asset) = lower(LEFT(r1.Instrument,3)) and r3.staking_monthID = r1.staking_monthID
left join EXE.dbo.v_PriceCandle pc on pc.DateTo = cast(r1.last_day as date) and lower(pc.coin) = lower(LEFT(r1.Instrument,3))
left join [EXE].[dbo].[staking_Waiver] w on w.CID = r1.CID and w.staking_monthID = r3.staking_monthID
left join DWH.dbo.V_Liabilities vl on vl.CID = r1.CID and vl.FullDate = cast(DATEADD(day, -1, r1.Create_Date) as date)
where r1.CID in (<[Parameters].[Parameter 1]>)