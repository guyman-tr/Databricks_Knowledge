SELECT * 
FROM BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation 
where DateRelevance between <[Parameters].[Parameter 1]> 
and <[Parameters].[Parameter 2]>