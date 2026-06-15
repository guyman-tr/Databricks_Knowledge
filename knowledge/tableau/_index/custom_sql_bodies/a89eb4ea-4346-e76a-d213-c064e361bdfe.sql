select * from
(with population as
(select a.CID, dc.GCID, a.Date, c.ParentUserName, 
case when d.GuruStatusID between 1 and 6 then  'PI' when  a.MirrorID>0 and d.AccountTypeID=9 then 'SP' else null end PI_SP,
case when d.GuruStatusID between 1 and 6 and d.CountryID=219 then 'US PI' when d.GuruStatusID between 1 and 6 and d.CountryID !=219 then 'Non US PI' else null end PI_Country,
case when cb.CID is not null then 1 else 0 end IsCopyBlocked, 
co.Name Country, pl.Name EOD_Club,
case when a.MirrorID>0 and d.AccountTypeID=9 then "Smart Portfolio" 
    when a.MirrorID>0 and d.AccountTypeID !=9 then "Copy" else b.InstrumentType end InstrumentType,
count(a.PositionID) NumCopyPositions,
max(coalesce(gu.Cash, 0) + coalesce(gu.Investment, 0) + coalesce(gu.PnL, 0) + coalesce(gu.DetachedPosInvestment, 0) + coalesce(gu.Dit_PnL, 0)) AS CopyAUC,
max(InitialInvestment) InitialInvestment,
max(WithdrawalSummary) WithdrawalSummary,
max(DepositSummary) DepositSummary,
sum(a.PositionPnL) PositionPnL, sum(a.Amount) Amount, sum(DailyPnL) DailyPnL
from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl a
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument b
on a.InstrumentID=b.InstrumentID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror c 
on a.MirrorID=c.MirrorID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked d
on c.ParentCID=d.RealCID
left join main.general.bronze_etoro_customer_blockedcustomeroperations cb
on d.RealCID=cb.CID
and date(cb.Occurred) = cast(a.Date as date)
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on a.CID=dc.RealCID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co
on dc.CountryID=co.CountryID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
on dc.PlayerLevelID=pl.PlayerLevelID
left join main.general.bronze_etorogeneral_history_gurucopiers gu
on c.CID=gu.CID
and c.ParentCID=gu.ParentCID
and CAST(OpenOccurred AS date)=CAST(StartCopy AS date)
and cast(a.Date as date) = cast(gu.`Timestamp`as date)
where a.etr_ymd >= date_trunc('MONTH', (current_date() - interval '4' DAY))
--and a.CID=23474088
group by 1,2,3,4,5,6,7,8,9,10
order by a.Date),

agg_population as
(select distinct CID, GCID, Date, Country, EOD_Club, ParentUserName, PI_SP, PI_Country,IsCopyBlocked, 
max(InitialInvestment) InitialInvestment,
max(WithdrawalSummary) WithdrawalSummary,
max(DepositSummary) DepositSummary,
max(CopyAUC) CopyAUC,
max(((CopyAUC+WithdrawalSummary)-(InitialInvestment+DepositSummary))/(InitialInvestment+DepositSummary)) CopyGain,
max(case when InstrumentType='Copy' then Amount else 0 end)  AmountCopy,
max(case when InstrumentType='Smart Portfolio' then Amount else 0 end)  AmountSP,
max(case when InstrumentType='Stocks' then Amount else 0 end)  AmountStocks,
max(case when InstrumentType='Crypto Currencies' then Amount else 0 end)  AmountCrypto,
max(case when InstrumentType in ('Currencies', 'Commodities','ETF', 'Indices') then Amount else 0 end) AmountCFD
from population
group by 1,2,3,4,5,6,7,8,9
),

final_pop as
(select 
a.*, 
sum(a.AmountCopy+a.AmountSP) over (partition by CID, cast(Date as date))/
sum(a.AmountCopy+a.AmountSP+a.AmountStocks+a.AmountCrypto+a.AmountCFD) over (partition by CID, cast(Date as date)) 
Copy_Of_Total_Portfolio

from agg_population a)

select *,
case when Copy_Of_Total_Portfolio>0 and Copy_Of_Total_Portfolio<=0.04 then '0-4%'
     when Copy_Of_Total_Portfolio>0.04 and Copy_Of_Total_Portfolio<=0.09 then '5-9%'
     when Copy_Of_Total_Portfolio>0.09 and Copy_Of_Total_Portfolio<=0.14 then '10-14%'
     when Copy_Of_Total_Portfolio>0.14 and Copy_Of_Total_Portfolio<=0.19 then '15-19%'
     when Copy_Of_Total_Portfolio>0.19 and Copy_Of_Total_Portfolio<=0.24 then '20-24%'
     when Copy_Of_Total_Portfolio>0.24 and Copy_Of_Total_Portfolio<=0.29 then '25-29%'
     when Copy_Of_Total_Portfolio>0.29 and Copy_Of_Total_Portfolio<=0.34 then '30-34%'
     when Copy_Of_Total_Portfolio>0.34 and Copy_Of_Total_Portfolio<=0.39 then '35-39%'
     when Copy_Of_Total_Portfolio>0.39 and Copy_Of_Total_Portfolio<=0.44 then '40-44%'
     when Copy_Of_Total_Portfolio>0.44 and Copy_Of_Total_Portfolio<=0.49 then '45-49%'
     when Copy_Of_Total_Portfolio>0.49 and Copy_Of_Total_Portfolio<=0.54 then '50-54%'
     when Copy_Of_Total_Portfolio>0.54 and Copy_Of_Total_Portfolio<=0.59 then '55-59%'
     when Copy_Of_Total_Portfolio>0.59 and Copy_Of_Total_Portfolio<=0.64 then '60-64%'
     when Copy_Of_Total_Portfolio>0.64 and Copy_Of_Total_Portfolio<=0.69 then '65-69%'
     when Copy_Of_Total_Portfolio>0.69 and Copy_Of_Total_Portfolio<=0.74 then '70-74%'
     when Copy_Of_Total_Portfolio>0.74 and Copy_Of_Total_Portfolio<=0.79 then '75-79%'
     when Copy_Of_Total_Portfolio>0.79 and Copy_Of_Total_Portfolio<=0.84 then '80-84%'
     when Copy_Of_Total_Portfolio>0.84 and Copy_Of_Total_Portfolio<=0.89 then '85-89%'
     when Copy_Of_Total_Portfolio>0.89 and Copy_Of_Total_Portfolio<=0.94 then '90-94%'
     when Copy_Of_Total_Portfolio>0.94 and Copy_Of_Total_Portfolio<=0.99 then '95-99%'
     when Copy_Of_Total_Portfolio>0.99 then '100%' end as Copy_Of_Total_Portfolio_p,

case when CopyGain<=0.01 then 'Less Then 1'
     when CopyGain>0.01 and CopyGain<=0.05 then '1-5%'
     when CopyGain>0.05 and CopyGain<=0.1 then '5-10%'
     when CopyGain>0.1 and CopyGain<=0.2 then '10-20%'
     when CopyGain>0.2 then 'More Then 20%' end as percentage_pnl


from final_pop pop
where pop.ParentUserName is not null)