select 
di.IsSettled,
di.InstrumentType,
Metric,
sum(case when DATEDIFF(week, c.Date, getdate()-1) > 0 THEN ([Amount]/8) ELSE 0 end) avg_8w
,max(c.Date)UpdateDate
from #dim_instrument di
left join  #calc c on di.InstrumentType=c.InstrumentType and di.IsSettled=c.IsSettled
group by 
di.InstrumentType,
di.IsSettled,
Metric