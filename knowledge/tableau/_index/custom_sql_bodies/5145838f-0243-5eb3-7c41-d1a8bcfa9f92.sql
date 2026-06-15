SELECT distinct  from_utc_timestamp(s.StatusStartDate, 'Europe/Nicosia') as StatusStartDate,  from_utc_timestamp(StatusEndDate, 'Europe/Nicosia') AS StatusEndDate,s.StatusDuration,st.DeveloperName,  timestampdiff(MINUTE, StatusStartDate, StatusEndDate) AS TotalMinutes,concat(a.FirstName," ",a.LastName) AS Agent,a.SubRole,a.Site,concat(a2.FirstName," ",a2.LastName) AS Manager FROM crm.silver_crm_userservicepresence s 
left join crm.silver_crm_servicepresencestatus st on s.ServicePresenceStatusId=st.id and st.DeveloperName not in ('Busy_Traning')
left join bi_output.bi_output_customer_customer_support_agent_user a on a.ID=s.UserId and year(a.ToDate)=9999
left join bi_output.bi_output_customer_customer_support_agent_user a2 on a2.ID=a.ManagerID and year(a2.ToDate)=9999
WHERE CAST(from_utc_timestamp(s.StatusStartDate, 'Europe/Nicosia') AS DATE) >='2025-05-01'

--and UserId='0050800000HJPxzAAH'
and s.StatusEndDate is not null
and a.SubRole in ('Tier 1 - eToro','Tier 2 - eToro','Tier 3 - eToro','Technical - eToro','Escalation - eToro')
order by StatusStartDate asc