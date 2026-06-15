(select "Last Daily Volume is " as description,
Daily_Volume,". Average of this month is" as comment1
,avg_Daily_Volume_Month, case when Daily_Volume>=avg_Daily_Volume_Month then ".Ok" else ".Not ok" end as status
from
(

select base1.*,base2.avg_Daily_Volume_Month
from
(

select yearmonth, sum(Daily_Volume)Daily_Volume
from
(
select int(round(DateID/100,0)) as yearmonth,coalesce(VolumeOpen,0)+coalesce(VolumeCLose,0) as Daily_Volume
from  risk.risk_output_rm_tables_daily_volume
)base
group by yearmonth
)base1
left join
(
select  int(round(DateID/100,0)) as yearmonth, avg(Daily_Volume) as avg_Daily_Volume_Month
from
(
select DateID, sum(coalesce(VolumeOpen,0)+ (coalesce(VolumeClose,0))) as Daily_Volume
from risk.risk_output_rm_tables_history_daily_volume
group by DateID
)temp1
group by yearmonth
)base2
on base1.yearmonth=base2.yearmonth
)final
)