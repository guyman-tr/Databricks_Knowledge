select Create_Date, Asset, first_day, last_day, staking_month, staking_monthID,
LEFT(CONVERT(varchar(10), dateadd(day,-1, cast(last_day as date)),112), 6) as last_dayID,
FORMAT(last_day, 'MMMM-yyyy') AS date,
       sum(UsersUnits+eToroUnits) as [Avarage Staked Pool],
       Yield as [Avr Monthly Staking Yield],
       StakingRewards as [Total Staked Rewards],
       ((pc.AskLast+pc.BidLast)/2) * StakingRewards as [Total Staked Rewards USD],
       (pc.AskLast+pc.BidLast)/2 as USDprice
FROM
    (
        select p.Create_Date, p.first_day, p.last_day, LEFT(p.Instrument,3) as Asset, p.Rewards as StakingRewards, 
                p.staking_month, p.staking_monthID,
                su.SplitUserUnits, 
                p.Rewards*su.SplitUserUnits as UserStakingRewards,
                p.Rewards*(1-su.SplitUserUnits) as eToroStakingRewards,
                (sum(p.EligibleDyas*p.EffectiveAmountInUnitsDecimal/p.N)) as UsersUnits, 
                ((sum(p.EligibleDyas*p.EffectiveAmountInUnitsDecimal/p.N))/su.SplitUserUnits)-(sum(p.EligibleDyas*p.EffectiveAmountInUnitsDecimal/p.N)) as eToroUnits,
                (su.SplitUserUnits*p.Rewards)/(sum(p.EligibleDyas*p.AmountInUnitsDecimal/p.N)) as Yield,
                cast(sum(EligibleDyas) as float)/count(distinct PositionID) as AvgDays,
                sum(p.EffectiveAmountInUnitsDecimal)/ count(distinct GCID) as AvgHoldingUser
        from EXE.dbo.staking_raw2 p
        left join EXE.[dbo].[staking_split_units] su on su.Instrument = p.Instrument and p.first_day = su.first_day
        group by Create_Date, LEFT(p.Instrument,3), p.Rewards, su.SplitUserUnits, p.first_day, p.last_day, p.staking_month, p.staking_monthID
    ) a
left join EXE.dbo.v_PriceCandle pc on lower(pc.coin) = lower(a.Asset) and pc.DateTo = a.last_day
group by Create_Date, Asset, first_day, last_day, Yield, StakingRewards, (pc.AskLast+pc.BidLast)/2, staking_month, staking_monthID