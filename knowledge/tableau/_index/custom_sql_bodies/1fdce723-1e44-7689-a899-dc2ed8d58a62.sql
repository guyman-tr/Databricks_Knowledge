select * 
,  case when REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 1) = "" then Sender else
REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 1)end  AS Sender_HedgeClient_
,REGEXP_EXTRACT(Sender, '(.*?)\\s*\\((.*?)\\)', 2) AS Sender_by_
from risk.risk_output_rm_tables_operational_risk_update_hedge_v1


-- in order to compare hours, use row_number on history