(Select Count (1) [Count],incident_type [Type],left ([reporting_date],4) [Year]
From 
[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where subject is not null
Group by left ([reporting_date],4), incident_type)
Union all
(Select Count (1) [Count],'Total' [Type],left ([reporting_date],4) [Year]
From 
[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where subject is not null
Group by left ([reporting_date],4))