Select Left (reporting_date,4) Year,'Avg Daily Incidents' [Type], count (1)*1.0/260 [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2022
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Avg Daily Incidents' [Type], count (1)*1.0/ 260 [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2023
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Avg Daily Incidents' [Type], count (1)*1.0/ 260 [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Avg Daily Incidents' [Type], count (1)*1.0/ (select datepart (dayofyear, cast(getdate ()as date)) - ( 105*(datepart(dayofyear,cast(getdate ()as date))*1.0/365))) [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
Group By Left (reporting_date,4) 

Union

Select Left (reporting_date,4) Year,'Avg Monthly Incidents' [Type], count (1)*1.0/12 [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2022
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Avg Monthly Incidents' [Type], count (1)*1.0/ 12 [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2023
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Avg Monthly Incidents' [Type], count (1)*1.0/ 12 [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Avg Monthly Incidents' [Type], count (1)*1.0/ (select datepart (Month, cast(getdate ()as date)))
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
Group By Left (reporting_date,4) 

Union

Select Left (reporting_date,4) Year,'Yearly Incidents' [Type], count (1) [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2022
Group By Left (reporting_date,4) 

Union
Select Left (reporting_date,4) Year,'Yearly Incidents' [Type], count (1) [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2023
Group By Left (reporting_date,4)


Union
Select Left (reporting_date,4) Year,'Yearly Incidents' [Type], count (1) [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
Group By Left (reporting_date,4)

Union
Select Left (reporting_date,4) Year,'Yearly Incidents' [Type], count (1) [Count]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
Group By Left (reporting_date,4)