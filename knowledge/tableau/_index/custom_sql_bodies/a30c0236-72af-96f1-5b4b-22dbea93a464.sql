SELECT 
        CAST(CreateDate AS DATE) AS UploadDate,  -- Strip time to group by date
        DATEPART(HOUR, CreateDate) AS UploadHour,  -- Extract hour from datetime
        DATENAME(WEEKDAY, CreateDate) AS Weekday,
COUNT(TaskID) AS UploadsPerHour  -- Count uploads per hour per day
,Priority ,
dc1.Name as Country,
dc1.Region

FROM BI_DB_dbo.External_Assignment_Assignment_V_Tasks v
left join DWH_dbo.Dim_Customer dc on dc.RealCID=v.CID
left join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
where CreateDate>=DATEADD(MONTH, -6, DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE()-1 AS DATE)), 0))	  
  GROUP BY 
CAST(CreateDate AS DATE), 
DATEPART(HOUR, CreateDate),
DATENAME(WEEKDAY, CreateDate),
Priority,
dc1.Name ,
dc1.Region