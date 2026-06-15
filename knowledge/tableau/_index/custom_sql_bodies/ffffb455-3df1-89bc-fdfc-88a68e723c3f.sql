select * 
from general.gold_lukka_all_trades 
where etr_ymd between 
date_add(<[Parameters].[Parameter 1]>,1)
and date_add(<[Parameters].[Parameter 2]>,1)