SELECT bdrik.*,dc.Region,dc.Desk 
FROM BI_DB..BI_DB_RAF_Invitees_KPIs  bdrik
INNER JOIN DWH..Dim_Country dc
    ON dc.Name = bdrik.Country