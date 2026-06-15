select Distinct bdcdpfd.AccountManager
      ,cl.CID
      ,case when cast(bdcdpfd.ActiveDate as date)=cast(cl.`Date`as date) then cl.`Date`
      else bdcdpfd.FTDdate end as `Date`
      , cl.OldTier
      ,cl.OldClub
      ,cl.CurrentTier
      ,cl.CurrentClub
      ,cl.PLChangeType
      ,case when cast(bdcdpfd.ActiveDate as date)=cast(cl.`Date`as date) then cast (trunc(cl.etr_ymd, 'MM') AS DATE)
      else cast (trunc(bdcdpfd.FTDdate, 'MM') AS DATE) end as ChangeDate
      ,case when cast(bdcdpfd.ActiveDate as date)=cast(cl.`Date`as date) then case WHEN bduts.etr_ymd >= DATEADD(day, -30, cl.etr_ymd) and bduts.etr_ymd<=cl.etr_ymd then 1 else 0 end 
      else case WHEN bduts.etr_ymd >= DATEADD(day, -30, bdcdpfd.FTDdate) and bduts.etr_ymd<=bdcdpfd.FTDdate then 1 else 0 end 
      end as IsContacted
from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata bdcdpfd
 JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct  cl 
on cl.CID=bdcdpfd.CID 
and (cast(bdcdpfd.ActiveDate as date)=cast(cl.`Date`as date) or (cast (bdcdpfd.RegDate as date)=cast(cl.`Date`as date) and cast(bdcdpfd.ActiveDate as date)<>cast(cl.`Date`as date) and bdcdpfd.ActiveDate=bdcdpfd.FTDdate))
left JOIN bi_output.bi_output_customer_customer_facing_agent_engagement bduts
ON bdcdpfd.CID = bduts.CID
AND bduts.ActionType in ('CompletedPhone','InboundEmail','ZoomCall','Whatsapp')
AND bduts.etr_ymd>=DATEADD(day,-30,cl.etr_ymd)
AND bduts.etr_ymd<=cl.etr_ymd
where cl.etr_ymd>='2024-08-01'
and cl.PLChangeType in ('Upgrade', 'FirstClub')