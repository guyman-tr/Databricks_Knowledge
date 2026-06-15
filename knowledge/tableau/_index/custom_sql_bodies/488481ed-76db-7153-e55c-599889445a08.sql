select final.*
from
(
select round(year(Date)*1E4 + month(Date)*1e2 + day(Date),0) as DateID,InstrumentType,VolumeOpen,VolumeClose
from
(
select Date, InstrumentType,sum(VolumeAtOpen)  as VolumeOpen, sum(VolumeAtClose) as VolumeClose
from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new
where Date between '2022-01-01' and '2023-01-20'
group by Date, InstrumentType
)base

union

(
select DateID, InstrumentType,sum(VolumeOpen) as VolumeOpen, sum(VolumeClose) VolumeClose
from risk.risk_output_rm_tables_history_daily_volume
group by DateID,InstrumentType
order by DateID
)
)final

order by DateID