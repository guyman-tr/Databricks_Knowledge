Select 'System Failure' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'System Failure'

Union
Select 'System Failure*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'System Failure'

Union
Select 'Human Error' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Human Error'
Union
Select 'Human Error*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'Human Error'
Union
Select 'Communication Problem' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Communication Problem'
Union
Select 'Communication Problem*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'Communication Problem'
Union
Select 'Lack of Training' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Lack of Training'
Union
Select 'Lack of Training*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'Lack of Training'
Union
Select 'Missing Procedure' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Missing Procedure'
Union
Select 'Missing Procedure*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'Missing Procedure'
Union
Select 'Resource Problems' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Resource Problems'
Union
Select 'Resource Problems*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Resource Problems'
Union
Select 'Equipment Problem' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Equipment Problem'
Union
Select 'Equipment Problem*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'Equipment Problem'
Union
Select 'Other' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2024) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2024
and incident_type = 'Other'
Union
Select 'Other*' [Type], count (1)*1.0/ (Select count (1)
                       FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
                       Where Left (reporting_date,4) = 2025) [Percentage]
FROM[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where Left (reporting_date,4) = 2025
and incident_type = 'Other'