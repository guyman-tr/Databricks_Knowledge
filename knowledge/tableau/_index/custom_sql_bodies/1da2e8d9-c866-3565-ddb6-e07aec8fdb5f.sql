with users_in_test as (
select distinct mp.mp_event_name, mp.variationid, mp.experimentid,  mp.mp_user_id, min(mp.etr_ymd) test_date
from main.mixpanel.silver mp  
where mp.etr_ymd>='2023-06-19'
and lower(mp.mp_event_name) like ('%experiment_started%')
and experimentid in ('raf_pi_dashboard_touchpoint','raf_after_first_copy', 'raf_after_ftd', 'raf_after_first_trade', 'raf_club_dashboard_touchpoint', 'raf_home_page_header','raf_side_nav_cta')
group by 1,2,3,4) ,

invitee_reg (
select mp.mp_event_name, mp.mp_user_id, mp.etr_ymd,  cast(mp.invitee_id as int) invitee_id
from main.mixpanel.silver mp
where mp.etr_ymd>='2023-06-19'
and mp.mp_event_name in ('RAF Action Success BE')
),

invitee_actions as (
SELECT CID, etr_ymd , registered,
(case when FirstDepositDate IS NOT NULL then 1 else 0 END) FTD,
(case when FirstNewFundedDate IS NOT NULL then 1 else 0 END) Activation
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates),

final_pop as (
  select variationid, experimentid, ut.mp_user_id, 
case when invitee_id is not null then 1 else 0 end raf_reg, FTD , Activation 
from users_in_test ut
left join invitee_reg ir
on ut.mp_user_id=ir.mp_user_id
and etr_ymd>=test_date
left join invitee_actions ia
on ir.invitee_id = ia.CID)

select 
experimentid, 
variationid, 
count(mp_user_id) users_in_experiment, 
sum(raf_reg) raf_registrations, 
sum(coalesce (FTD,0)) raf_ftd, 
sum(coalesce (Activation,0)) raf_activation
from final_pop
group by 1,2