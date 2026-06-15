select * 
,year(ClientSendTime)*1E2 + month(ClientSendTime) as YearMonth
,  case when REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 1) = "" then Sender else
REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 1)end  AS Sender_HedgeClient_
,REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 2) AS Sender_by_
, ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY ClientSendTime) AS rn
, case when value>=50E3 then 1
when  
UpdateDate in
(select UpdateDate from
(
select UpdateDate, count(*) amount
from risk.risk_output_rm_tables_operational_risk_update_hedge_history_v1
group by UpdateDate
having count(*) >=5
)cnt_5) then 1
else 0 end as ind_alert
from risk.risk_output_rm_tables_operational_risk_update_hedge_history_v1
where
year(ClientSendTime)*1E2 + month(ClientSendTime) >=202312
qualify rn=1
order by ClientSendTime