WITH user_level1 (
select
ExternalUserId
, etr_ymd
, max(PushOptIn)PushOptIn
  --, max(case when AppInstallStatus='installed' then 1 else 0 end)Installed
, max(OccurredOriginal) LastUpdate
, sum(case when DeviceType='IOS' then 1 else 0 end)IOS_cnt
, sum(case when DeviceType='ANDROID' then 1 else 0 end)ANDROID_cnt
from urban.gold_device_status_daily o
  --left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c1 on o.ExternalUserId=c1.ExternalID
  --left join
  --left join dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked c on c1.GCID=c.GCID --and o.etr_ymd between c.FromDateID and c.ToDateID
where PushOptIn is not null
--and date_diff(etr_ymd, OccurredOriginal)<=30
and AppInstallStatus = 'installed'
and DeviceType in ('IOS', 'ANDROID')
group by ExternalUserId, etr_ymd
)

, user_level2 as(
select 
ExternalUserId
, etr_ymd
, PushOptIn
, nvl(LAG(PushOptIn) OVER (PARTITION BY ExternalUserId ORDER BY etr_ymd),PushOptIn) PrevPushOptIn
, nvl(LAG(LastUpdate) OVER (PARTITION BY ExternalUserId ORDER BY etr_ymd),LastUpdate) PrevLastUpdate
, LastUpdate
, case when nvl(IOS_cnt,0)>0 and nvl(ANDROID_cnt,0)>0 then 'BOTH' 
      when nvl(IOS_cnt,0)>0 and nvl(ANDROID_cnt,0)=0 then 'IOS'
      when nvl(IOS_cnt,0)=0 and nvl(ANDROID_cnt,0)>0 then 'ANDROID' end DeviceType
from user_level1 u
)

, user_level_3 as(

  select ExternalUserId
  , max(etr_ymd)etr_ymd
  from user_level2
  group by ExternalUserId
  )

, additional_info AS (
    SELECT c.GCID
        , c.RealCID
        , c.ExternalId
        , c.VerificationLevelID
        , c.PlayerStatusID
        , c.RegulationID
        , c.IsDepositor
        , c.IsEmailVerified
        , c.IsValidCustomer
        , c.PhoneVerifiedID
        , d.Club
        , d.Channel
        , d.SubChannel
        , d.LabelName
        , d.Country
        , d.Region
        , d.PotentialDesk
        , d.FunnelName
        , d.CommunicationLanguage
        , d.Manager
        ,TIMESTAMPDIFF(MONTH, c.RegisteredReal, CURRENT_DATE()) AS duration_from_registration_m
        ,TIMESTAMPDIFF(DAY, nvl(d.LastLoggedIn, c.RegisteredReal), CURRENT_DATE()) AS time_since_last_logged_in_d
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
    join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked d on d.CID=c.RealCID
    --where c.ExternalId=57293821324925430001
)

, user_level4 as(
 select u2.ExternalUserId
 , u2.etr_ymd
 , PushOptIn
 , PrevPushOptIn
 , case when PushOptIn=1 and PrevPushOptIn=0 then 'OptedIn' 
      when PushOptIn=0 and PrevPushOptIn=1 then 'OptedOut' else 0 end Action
 , LastUpdate
 , PrevLastUpdate
 , datediff(LastUpdate, PrevLastUpdate)PrevStatDuration
 , datediff(u2.etr_ymd, LastUpdate)StatDuration
 , DeviceType
 , case when u3.etr_ymd is not null then 1 else 0 end LastStat

, i.VerificationLevelID
, i.PlayerStatusID
, i.RegulationID
, i.IsDepositor
, i.IsEmailVerified
, i.IsValidCustomer
, i.PhoneVerifiedID
, i.Club
, i.Channel
, i.SubChannel
, i.LabelName
, i.Country
, i.Region
, i.PotentialDesk
, i.FunnelName
, i.CommunicationLanguage
, i.Manager
, i.duration_from_registration_m
, i.time_since_last_logged_in_d
 from user_level2 u2
 left join user_level_3 u3 on u2.ExternalUserId=u3.ExternalUserId and u2.etr_ymd=u3.etr_ymd
 left join additional_info i on u2.ExternalUserId=i.ExternalId
)

, total_durations as (

        select ExternalUserId
        ,sum(case when PushOptIn=1 then StatDuration else 0 end) as TotalOptInDuration
        , sum(case when PushOptIn=0 then StatDuration else 0 end) as TotalOptOutDuration
        from user_level4 u
        group by ExternalUserId
)

--, agg as(
select 
etr_ymd
, PushOptIn
, deviceType
, LastStat as IsLastStat
, VerificationLevelID
, PlayerStatusID
, RegulationID
, IsDepositor
--, IsEmailVerified
, IsValidCustomer
--, PhoneVerifiedID
, Club
--, Channel
--, SubChannel
--, LabelName
, Country
, Region
--, PotentialDesk
--, FunnelName
, CommunicationLanguage
--, Manager
, Action

, min(prevStatDuration) as MinPrevStatDuration
, max(prevStatDuration) as MaxPrevStatDuration
, avg(prevStatDuration) as AvgPrevStatDuration
, mean(prevStatDuration) as MeanPrevStatDuration
, mode(prevStatDuration) as ModePrevStatDuration
, stddev(prevStatDuration) as StddevPrevStatDuration
, median(prevStatDuration) as MedianPrevStatDuration

, min(StatDuration) as MinStatDuration
, max(StatDuration) as MaxStatDuration
, avg(StatDuration) as AvgStatDuration 
, mean(StatDuration) as MeanStatDuration
, mode(StatDuration) as ModeStatDuration
, stddev(StatDuration) as StddevStatDuration
, median(StatDuration) as MedianStatDuration

, case when duration_from_registration_m <=1 then 'less than 1 month'
        when duration_from_registration_m <=3 then 'less than 3 months'
        when duration_from_registration_m <=6 then 'less than 6 months'
        when duration_from_registration_m <=12 then 'less than 1 year'
        when duration_from_registration_m <=24 then 'less than 2 years'
        when duration_from_registration_m <=36 then 'less than 3 years'
        else 'longer than 3 years' end as duration_from_registration_m_group

, case when time_since_last_logged_in_d <=1 then 'less than 1 day'
        when time_since_last_logged_in_d <=7 then 'less than 7 days'
        when time_since_last_logged_in_d <=14 then 'less than 14 days'
        when time_since_last_logged_in_d <=30 then 'less than 30 days'
        when time_since_last_logged_in_d <=60 then 'less than 60 days'
        when time_since_last_logged_in_d <=90 then 'less than 90 days'
        else 'longer than 90 days' end as time_since_last_logged_in_d_group   

, case when StatDuration <=1 then 'less than 1 day'
        when StatDuration <=7 then 'less than 7 days'
        when StatDuration <=14 then 'less than 14 days'
        when StatDuration <=30 then 'less than 30 days'
        when StatDuration <=60 then 'less than 60 days'
        when StatDuration <=90 then 'less than 90 days'
        else 'longer than 90 days' end as StatDuration_group

, case when prevStatDuration <=1 then 'less than 1 day'
        when prevStatDuration <=7 then 'less than 7 days'
        when prevStatDuration <=14 then 'less than 14 days'
        when prevStatDuration <=30 then 'less than 30 days'
        when prevStatDuration <=60 then 'less than 60 days'
        when prevStatDuration <=90 then 'less than 90 days'
        else 'longer than 90 days' end as prevStatDuration_group    
, case when TotalOptInDuration <=1 then 'less than 1 day'
        when TotalOptInDuration <=7 then 'less than 7 days'
        when TotalOptInDuration <=14 then 'less than 14 days'
        when TotalOptInDuration <=30 then 'less than a month'
        when TotalOptInDuration <=60 then 'less than 2 months'
        when TotalOptInDuration <=90 then 'less than 3 months'
        when TotalOptInDuration <=180 then 'less than 6 months'
        when TotalOptInDuration <=365 then 'less than a year'
        when TotalOptInDuration <=730 then 'less than 2 years'
        when TotalOptInDuration <=1095 then 'less than 3 years'
        else 'longer than 3 years' end as TotalOptInDuration_group
, case when TotalOptOutDuration <=1 then 'less than 1 day'
        when TotalOptOutDuration <=7 then 'less than 7 days'
        when TotalOptOutDuration <=14 then 'less than 14 days'
        when TotalOptOutDuration <=30 then 'less than a month'
        when TotalOptOutDuration <=60 then 'less than 2 months'
        when TotalOptOutDuration <=90 then 'less than 3 months'
        when TotalOptOutDuration <=180 then 'less than 6 months'
        when TotalOptOutDuration <=365 then 'less than a year'
        when TotalOptOutDuration <=730 then 'less than 2 years'
        when TotalOptOutDuration <=1095 then 'less than 3 years'
        else 'longer than 3 years' end as TotalOptOutDuration_group       

, count(*) UserCnt
 from user_level4
 left join total_durations t on user_level4.ExternalUserId=t.ExternalUserId

group by etr_ymd
, PushOptIn
, deviceType
, LastStat  
, VerificationLevelID
, PlayerStatusID
, RegulationID
, IsDepositor
--, IsEmailVerified
, IsValidCustomer
--, PhoneVerifiedID
, Club
--, Channel
--, SubChannel
--, LabelName
, Country
, Region
--, PotentialDesk
--, FunnelName
, CommunicationLanguage
--, Manager
, Action
, case when duration_from_registration_m <=1 then 'less than 1 month'
        when duration_from_registration_m <=3 then 'less than 3 months'
        when duration_from_registration_m <=6 then 'less than 6 months'
        when duration_from_registration_m <=12 then 'less than 1 year'
        when duration_from_registration_m <=24 then 'less than 2 years'
        when duration_from_registration_m <=36 then 'less than 3 years'
        else 'longer than 3 years' end  

, case when time_since_last_logged_in_d <=1 then 'less than 1 day'
        when time_since_last_logged_in_d <=7 then 'less than 7 days'
        when time_since_last_logged_in_d <=14 then 'less than 14 days'
        when time_since_last_logged_in_d <=30 then 'less than 30 days'
        when time_since_last_logged_in_d <=60 then 'less than 60 days'
        when time_since_last_logged_in_d <=90 then 'less than 90 days' 
        else 'longer than 90 days' end     

, case when StatDuration <=1 then 'less than 1 day'
        when StatDuration <=7 then 'less than 7 days'
        when StatDuration <=14 then 'less than 14 days'
        when StatDuration <=30 then 'less than 30 days'
        when StatDuration <=60 then 'less than 60 days'
        when StatDuration <=90 then 'less than 90 days'
        else 'longer than 90 days' end 

, case when prevStatDuration <=1 then 'less than 1 day'
        when prevStatDuration <=7 then 'less than 7 days'
        when prevStatDuration <=14 then 'less than 14 days'
        when prevStatDuration <=30 then 'less than 30 days'
        when prevStatDuration <=60 then 'less than 60 days'
        when prevStatDuration <=90 then 'less than 90 days'
        else 'longer than 90 days' end 
, case when TotalOptInDuration <=1 then 'less than 1 day'
        when TotalOptInDuration <=7 then 'less than 7 days'
        when TotalOptInDuration <=14 then 'less than 14 days'
        when TotalOptInDuration <=30 then 'less than a month'
        when TotalOptInDuration <=60 then 'less than 2 months'
        when TotalOptInDuration <=90 then 'less than 3 months'
        when TotalOptInDuration <=180 then 'less than 6 months'
        when TotalOptInDuration <=365 then 'less than a year'
        when TotalOptInDuration <=730 then 'less than 2 years'
        when TotalOptInDuration <=1095 then 'less than 3 years'
        else 'longer than 3 years' end  
, case when TotalOptOutDuration <=1 then 'less than 1 day'
        when TotalOptOutDuration <=7 then 'less than 7 days'
        when TotalOptOutDuration <=14 then 'less than 14 days'
        when TotalOptOutDuration <=30 then 'less than a month'
        when TotalOptOutDuration <=60 then 'less than 2 months'
        when TotalOptOutDuration <=90 then 'less than 3 months'
        when TotalOptOutDuration <=180 then 'less than 6 months'
        when TotalOptOutDuration <=365 then 'less than a year'
        when TotalOptOutDuration <=730 then 'less than 2 years'
        when TotalOptOutDuration <=1095 then 'less than 3 years'
        else 'longer than 3 years' end             

--)

--select count(*) from agg