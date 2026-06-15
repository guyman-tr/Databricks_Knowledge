SELECT weekdate,
(([logins_succ_ratio_mob_]+[logins_succ_ratio_web_]+[platform_availability])/3) Trading_Platform
,(([verified_of_total_count]+[cashouts_within_sla_24]+[withdrawl_id_within_sla_24]+[wires_within_sla])/4) Operations
,(([redeems_monthly_within_sla]+[redeems_weekly_within_sla])/2) Crypto
  FROM [ThirdParty_Fivetran].[Fivetran].[regulation].[OutsourcedServicesMonitoring]