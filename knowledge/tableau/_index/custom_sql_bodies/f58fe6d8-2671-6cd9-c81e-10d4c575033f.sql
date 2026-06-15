select u.cid_upgrades,count(distinct(u.id)) > 0 as Contacted
from
(
  with q1 as
  (
  select 
        t1.TierChangeDate,
        t1.cid as cid_upgrades
    from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club t1
    left join `main`.`dwh`.`gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` t2
        on t1.CurrentTier = t2.playerlevelid
    left join `main`.`dwh`.`gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` t3
        on t1.lasttier = t3.PlayerLevelID
    where t3.Name = "Bronze" and to_timestamp(t1.Date, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')>=DATEADD(year, DATEDIFF(year, CAST('1970-01-01' AS TIMESTAMP), GETDATE()) - 1, CAST('1970-01-01' AS TIMESTAMP))
  )
,q2 as
  (
  select *
  from bi_output.bi_output_customer_customer_facing_agent_engagement ae
  where ae.ActionType in ('CompletedPhone','InboundEmail','ZoomCall','Whatsapp')
    )
select *
from q1
join q2
    on q1.cid_upgrades = q2.cid
where datediff(day,q2.etr_ymd,q1.TierChangeDate) between 0 and 30) u
group by u.cid_upgrades