with be as (
select Date,
InstrumentID,
InstrumentType,
case when ActionType='Copy' then 'Copy' else 'Manual' end as Copy_Manual,
Regulation,
count(*) as NumberOfTransactions
from main.dealing.bi_output_dealing_bestexecution_report
group by Date,
InstrumentID,
InstrumentType,
case when ActionType='Copy' then 'Copy' else 'Manual' end,
Regulation
),

failures as (
SELECT bdtfr.Date, bdtfr.InstrumentID, di.InstrumentType, bdtfr.Copy_Manual, bdtfr.Regulation,
SUM(bdtfr.Orders_Positions) AS NumberOfFailures
FROM main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk bdtfr
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
on di.InstrumentID= bdtfr.InstrumentID
WHERE Date>='2024-10-01'
AND Type='Failures'
GROUP BY Date, bdtfr.Copy_Manual, bdtfr.Regulation, bdtfr.InstrumentID, di.InstrumentType
)


select coalesce(be.Date, ris.Date) as Date,
coalesce(be.InstrumentID, ris.InstrumentID) as InstrumentID,
coalesce(be.InstrumentType, ris.InstrumentType) as InstrumentType,
coalesce(be.Copy_Manual, ris.Copy_Manual) as Copy_Manual,
coalesce(be.Regulation, ris.Regulation) as Regulation,
SUM(NumberOfTransactions) as NumberOfTransactions,
SUM(NumberOfFailures) AS NumberOfFailures
from be be
full outer join failures ris
on be.Date=ris.Date 
and be.Regulation=ris.Regulation 
and be.Copy_Manual= ris.Copy_Manual
and be.InstrumentID = ris.InstrumentID
group by coalesce(be.Date, ris.Date),
coalesce(be.InstrumentID, ris.InstrumentID),
coalesce(be.InstrumentType, ris.InstrumentType),
coalesce(be.Copy_Manual, ris.Copy_Manual),
coalesce(be.Regulation, ris.Regulation)