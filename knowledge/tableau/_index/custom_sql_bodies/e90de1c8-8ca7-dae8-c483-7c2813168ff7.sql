WITH status_changes AS (
        SELECT
            ExternalUserId,
            Occurred,
           -- ifnull(LEAD(Occurred) OVER (PARTITION BY ExternalUserId ORDER BY Occurred), now()) AS NextOccurred,
            CASE when UserOptInState= 'None' OR UserOptInState=0 then 0 else 1 end UserOptInState,
            ifnull(LEAD(CASE when UserOptInState= 'None' OR UserOptInState=0 then 0 else 1 end) OVER (PARTITION BY ExternalUserId ORDER BY Occurred),2) AS NextUserOptInState
        FROM product_analytics_stg.bi_output_product_analytics_optin_optin_history_bronze
        where 1=1 
       -- and ExternalUserId =63701936393972762039
        and IsNewStatus=1
        order by 2
)
--select * from status_changes

, grouped_status_changes(
SELECT 
ExternalUserId
, Occurred
, ifnull(LEAD(Occurred) OVER (PARTITION BY ExternalUserId ORDER BY Occurred), now()) AS NextOccurred
, UserOptInState
, NextUserOptInState
, row_number() OVER(PARTITION BY ExternalUserId ORDER BY Occurred) ChangeRank 
from status_changes
    where 1=1
    --and ExternalUserId =57293821324925430001
    and UserOptInState != NextUserOptInState
order by 2
)

--select * from grouped_status_changes


, opt_in_periods AS (
    SELECT
        ExternalUserId,
        Occurred AS OptInStart,
        NextOccurred AS OptInEnd,
        DATEDIFF(NextOccurred, Occurred) AS OptInDurationDays
        , case when NextUserOptInState = 2 THEN 1 ELSE 0 END AS IsCurrnet
        , row_number() OVER(PARTITION BY ExternalUserId ORDER BY Occurred) OptInRank
        , ChangeRank
    FROM grouped_status_changes
    where UserOptInState = 1
    
)

--select * from opt_in_periods


, first_optIn_duration (
    select ExternalUserId
    , OptInDurationDays FirstOptInDuration
    from opt_in_periods
    where OptInRank = 1
)

--select * from first_optIn_duration
, max_optIn_Rank(
select ExternalUserId
, max(OptInRank) maxRnk
from opt_in_periods
group by ExternalUserId

)
, last_optIn_duration (
    select oip.ExternalUserId
    , OptInDurationDays LastOptInDuration
    , case when IsCurrnet = 1 THEN 1 ELSE 0 END AS CurrentOptInStatus
    from opt_in_periods oip
    join max_optIn_Rank mor on oip.ExternalUserId = mor.ExternalUserId
    where oip.OptInRank = mor.maxRnk
    
)

, total_durations AS (
    SELECT
        ExternalUserId,
        SUM(OptInDurationDays) AS TotalOptInDurationDays
    FROM opt_in_periods
    GROUP BY ExternalUserId
)

-- select * from total_durations

, user_segments AS (
    SELECT 
        ExternalUserId,
        SUM(CASE WHEN UserOptInState = 1 THEN 1 ELSE 0 END) AS opt_in_count,
        SUM(CASE WHEN UserOptInState = 0 THEN 1 ELSE 0 END) AS opt_out_count
        --MAX(PushOptIn) AS current_opt_in_status
    FROM grouped_status_changes
    GROUP BY ExternalUserId
)

--select * from user_segments

, segmented_users AS (
    SELECT 
        us.ExternalUserId,
        us.opt_in_count,
        us.opt_out_count,
        --us.current_opt_in_status,
        CASE 
            WHEN us.opt_in_count > 0 AND us.opt_out_count = 0 THEN 'Always Opted-In'
            WHEN us.opt_in_count = 0 AND us.opt_out_count > 0 THEN 'Always Opted-Out'
            ELSE 'Intermittent Opt-Ins'
        END AS OptInStatus
    FROM user_segments us
)

--select * from segmented_users

, device_usage AS (
    SELECT 
        ExternalUserId
        , COUNT(DISTINCT UrbanDeviceId) AS device_count
        , case when COUNT(DISTINCT UrbanDeviceId) = 1 THEN 'Single Device User'
                when COUNT(DISTINCT UrbanDeviceId) > 1 THEN 'Multiple Device User' end DeviceUsage
    FROM product_analytics_stg.bi_output_product_analytics_optin_optin_history_bronze
    --where ExternalUserId =57293821324925430001
    GROUP BY ExternalUserId
)

--select * from device_usage



, additional_info AS (
    SELECT c.GCID
        , c.RealCID
        , c.ExternalId
        , c.VerificationLevelID
        , c.PlayerStatusID
        , c.RegisteredReal
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
        , d.Language
        , d.Region
        , d.PotentialDesk
        , d.FunnelName
        , d.registered
        , d.LastLoggedIn
        , d.CommunicationLanguage
        , d.Manager
        ,TIMESTAMPDIFF(MONTH, c.RegisteredReal, CURRENT_DATE()) AS duration_from_registration
        ,TIMESTAMPDIFF(DAY, d.LastLoggedIn, CURRENT_DATE()) AS time_since_last_logged_in
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
    join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked d on d.CID=c.RealCID
    --where c.ExternalId=57293821324925430001
)


, final_output AS (
select su.ExternalUserId
, su.opt_in_count
, su.opt_out_count
, su.OptInStatus
, td.TotalOptInDurationDays
, fod.FirstOptInDuration
, lod.LastOptInDuration
, ifnull(lod.CurrentOptInStatus, 0)CurrentOptInStatus
, du.DeviceUsage
, du.device_count
, ai.GCID
, ai.RealCID
, ai.VerificationLevelID
, ai.PlayerStatusID
, ai.RegisteredReal
, ai.RegulationID
, ai.IsDepositor
, ai.IsEmailVerified
, ai.IsValidCustomer
, ai.PhoneVerifiedID
, ai.Club
, ai.Channel
, ai.SubChannel
, ai.LabelName
, ai.Country
, ai.Language
, ai.Region
, ai.PotentialDesk
, ai.FunnelName
, ai.registered
, ai.LastLoggedIn
, ai.CommunicationLanguage
, ai.Manager
, ai.duration_from_registration
, ai.time_since_last_logged_in

from segmented_users su
left join total_durations td on su.ExternalUserId=td.ExternalUserId
left join First_OptIn_Duration fod on su.ExternalUserId=fod.ExternalUserId
left join last_optIn_duration lod on su.ExternalUserId=lod.ExternalUserId
left join device_usage du on su.ExternalUserId=du.ExternalUserId
 join additional_info ai on su.ExternalUserId=ai.ExternalId
--where su.ExternalUserId =63701936393972762039
)

,tt as (
select 

 case when ifnull(opt_in_count,0) <5 then opt_in_count
        when opt_in_count <10 then '5-9'
        when opt_in_count <15 then '10-14'
        when opt_in_count <=20 then '15-20'
        else '20+' end as opt_in_count_range

, case when ifnull(opt_out_count,0) <5 then opt_out_count
        when opt_out_count <10 then '5-9'
        when opt_out_count <15 then '10-14'
        when opt_out_count <=20 then '15-20'
        else '20+' end as opt_out_count_range
     
, case when ifnull(TotalOptInDurationDays,0) = 0 then '0'
        when TotalOptInDurationDays <= 7 then 'less than a week'
        when TotalOptInDurationDays <= 14 then '1-2 weeks' 
        when TotalOptInDurationDays <= 30 then 'less than a month'
        when TotalOptInDurationDays <= 60 then '1-2 months'
        when TotalOptInDurationDays <= 90 then 'less than 3 months'
        when TotalOptInDurationDays <= 180 then 'less than 6 months'
        when TotalOptInDurationDays <= 365 then 'less than 1 year'
        when TotalOptInDurationDays <= 730 then 'less than 2 years'
        when TotalOptInDurationDays <= 1095 then 'less than 3 years'
        when TotalOptInDurationDays > 1095 then 'more than 3 years' end as TotalOptInDurationDaysRange

,  case when ifnull(FirstOptInDuration,0) = 0 then '0'
        when FirstOptInDuration <= 7 then 'less than a week'
        when FirstOptInDuration <= 14 then '1-2 weeks' 
        when FirstOptInDuration <= 30 then 'less than a month'
        when FirstOptInDuration <= 60 then '1-2 months'
        when FirstOptInDuration <= 90 then 'less than 3 months'
        when FirstOptInDuration <= 180 then 'less than 6 months'
        when FirstOptInDuration <= 365 then 'less than 1 year'
        when FirstOptInDuration <= 730 then 'less than 2 years'
        when FirstOptInDuration <= 1095 then 'less than 3 years'
        when FirstOptInDuration > 1095 then 'more than 3 years' end as FirstOptInDurationDaysRange  

,  case when ifnull(LastOptInDuration,0) = 0 then '0'
        when LastOptInDuration <= 7 then 'less than a week'
        when LastOptInDuration <= 14 then '1-2 weeks' 
        when LastOptInDuration <= 30 then 'less than a month'
        when LastOptInDuration <= 60 then '1-2 months'
        when LastOptInDuration <= 90 then 'less than 3 months'
        when LastOptInDuration <= 180 then 'less than 6 months'
        when LastOptInDuration <= 365 then 'less than 1 year'
        when LastOptInDuration <= 730 then 'less than 2 years'
        when LastOptInDuration <= 1095 then 'less than 3 years'
        when LastOptInDuration > 1095 then 'more than 3 years' end as LastOptInDurationDaysRange   
, ifnull(CurrentOptInStatus, 0)CurrentOptInStatus
, DeviceUsage
, device_count
, VerificationLevelID
, PlayerStatusID -- შესაბამისი სახელწოდებები ???
, case when duration_from_registration = 0 then 'less than a month'
        when duration_from_registration =1 then '1 month'
        when duration_from_registration =2 then '2 months'
        when duration_from_registration =3 then '3 months'
        when duration_from_registration <=6 then 'less than 6 months'
        when duration_from_registration <=12 then 'less than 1 year'
        else 'more than 1 year' end as duration_from_registrationRange
--, RegulationID   
, IsDepositor 
--, IsEmailVerified 
--, PhoneVerifiedID
, Club
--, Channel   
--, SubChannel
--, LabelName
, Country
, Language
, Region
, CommunicationLanguage
, case when time_since_last_logged_in = 0 then '0'
        when time_since_last_logged_in <= 7 then 'less than a week'
        when time_since_last_logged_in <= 14 then '1-2 weeks' 
        when time_since_last_logged_in <= 30 then 'less than a month'
        when time_since_last_logged_in <= 60 then '1-2 months'
        when time_since_last_logged_in <= 90 then 'less than 3 months'
        when time_since_last_logged_in <= 180 then 'less than 6 months'
        when time_since_last_logged_in <= 365 then 'less than 1 year'
        when time_since_last_logged_in <= 730 then 'less than 2 years'
        when time_since_last_logged_in <= 1095 then 'less than 3 years'
        else 'more than 3 years' end as time_since_last_loggedin_Range
, count(ExternalUserId) User_count
from final_output

group by 
 case when ifnull(opt_in_count,0) <5 then opt_in_count
        when opt_in_count <10 then '5-9'
        when opt_in_count <15 then '10-14'
        when opt_in_count <=20 then '15-20'
        else '20+' end 

, case when ifnull(opt_out_count,0) <5 then opt_out_count
        when opt_out_count <10 then '5-9'
        when opt_out_count <15 then '10-14'
        when opt_out_count <=20 then '15-20'
        else '20+' end 
     
, case when ifnull(TotalOptInDurationDays,0) = 0 then '0'
        when TotalOptInDurationDays <= 7 then 'less than a week'
        when TotalOptInDurationDays <= 14 then '1-2 weeks' 
        when TotalOptInDurationDays <= 30 then 'less than a month'
        when TotalOptInDurationDays <= 60 then '1-2 months'
        when TotalOptInDurationDays <= 90 then 'less than 3 months'
        when TotalOptInDurationDays <= 180 then 'less than 6 months'
        when TotalOptInDurationDays <= 365 then 'less than 1 year'
        when TotalOptInDurationDays <= 730 then 'less than 2 years'
        when TotalOptInDurationDays <= 1095 then 'less than 3 years'
        when TotalOptInDurationDays > 1095 then 'more than 3 years' end 

,  case when ifnull(FirstOptInDuration,0) = 0 then '0'
        when FirstOptInDuration <= 7 then 'less than a week'
        when FirstOptInDuration <= 14 then '1-2 weeks' 
        when FirstOptInDuration <= 30 then 'less than a month'
        when FirstOptInDuration <= 60 then '1-2 months'
        when FirstOptInDuration <= 90 then 'less than 3 months'
        when FirstOptInDuration <= 180 then 'less than 6 months'
        when FirstOptInDuration <= 365 then 'less than 1 year'
        when FirstOptInDuration <= 730 then 'less than 2 years'
        when FirstOptInDuration <= 1095 then 'less than 3 years'
        when FirstOptInDuration > 1095 then 'more than 3 years' end    

,  case when ifnull(LastOptInDuration,0) = 0 then '0'
        when LastOptInDuration <= 7 then 'less than a week'
        when LastOptInDuration <= 14 then '1-2 weeks' 
        when LastOptInDuration <= 30 then 'less than a month'
        when LastOptInDuration <= 60 then '1-2 months'
        when LastOptInDuration <= 90 then 'less than 3 months'
        when LastOptInDuration <= 180 then 'less than 6 months'
        when LastOptInDuration <= 365 then 'less than 1 year'
        when LastOptInDuration <= 730 then 'less than 2 years'
        when LastOptInDuration <= 1095 then 'less than 3 years'
        when LastOptInDuration > 1095 then 'more than 3 years' end
, ifnull(CurrentOptInStatus, 0)
, DeviceUsage
, device_count
, VerificationLevelID
, PlayerStatusID -- შესაბამისი სახელწოდებები ???
, case when duration_from_registration = 0 then 'less than a month'
        when duration_from_registration =1 then '1 month'
        when duration_from_registration =2 then '2 months'
        when duration_from_registration =3 then '3 months'
        when duration_from_registration <=6 then 'less than 6 months'
        when duration_from_registration <=12 then 'less than 1 year'
        else 'more than 1 year' end  
--, RegulationID   
, IsDepositor 
--, IsEmailVerified 
--, PhoneVerifiedID
, Club
--, Channel   
--, SubChannel
--, LabelName
, Country
, Language
, Region
, CommunicationLanguage
, case when time_since_last_logged_in = 0 then '0'
        when time_since_last_logged_in <= 7 then 'less than a week'
        when time_since_last_logged_in <= 14 then '1-2 weeks' 
        when time_since_last_logged_in <= 30 then 'less than a month'
        when time_since_last_logged_in <= 60 then '1-2 months'
        when time_since_last_logged_in <= 90 then 'less than 3 months'
        when time_since_last_logged_in <= 180 then 'less than 6 months'
        when time_since_last_logged_in <= 365 then 'less than 1 year'
        when time_since_last_logged_in <= 730 then 'less than 2 years'
        when time_since_last_logged_in <= 1095 then 'less than 3 years'
        else 'more than 3 years' end 



)

select * from tt
--where opt_in_count_range != 0 and opt_out_count_range != 0












/*
SELECT
    ai.ExternalId,
    ai.GCID,
    ai.Country,
    ai.Language,
    ai.VerificationLevelID,
    ai.age,
    ai.duration_from_registration,
    ai.time_since_last_logged_in,
    td.TotalOptInDurationDays,
    su.opt_in_count,
    su.opt_out_count,
    su.current_opt_in_status AS CurrentOptInStatus,
    su.OptInStatus,
    dsu.DeviceUsage
FROM additional_info ai
JOIN total_durations td
    ON ai.ExternalId = td.ExternalUserId
JOIN segmented_users su
    ON ai.ExternalId = su.ExternalUserId
JOIN device_segmented_users dsu
    ON ai.ExternalId = dsu.ExternalUserId
    where ai.ExternalID=57293821324925430001
ORDER BY ai.ExternalId;
*/