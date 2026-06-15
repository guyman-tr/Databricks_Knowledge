Select Count (1) [Count],left ([reporting_date],7) [Month]
From 
[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where subject is not null
Group by left ([reporting_date],7)