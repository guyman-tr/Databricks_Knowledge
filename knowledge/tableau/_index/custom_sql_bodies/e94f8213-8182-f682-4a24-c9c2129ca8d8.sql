select * 
,  case when REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 1) = "" then Sender else
REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 1)end  AS Sender_HedgeClient_
,REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 2) AS Sender_by_
from risk.risk_output_rm_tables_operational_risk_update_hedge_history_v1
where
year(ClientSendTime)*1E4 + month(ClientSendTime)*1E2 + day(ClientSendTime)>=20231120
and RequestTypeID=1
order by  ClientSendTime desc