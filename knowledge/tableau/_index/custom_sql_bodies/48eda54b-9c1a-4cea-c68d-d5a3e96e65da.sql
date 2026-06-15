SELECT *
FROM [dbo].[Dim_Customer] [Dim_Customer]
where DATEDIFF(DAY, RegisteredReal, GETUTCDATE()) between 0 and 2