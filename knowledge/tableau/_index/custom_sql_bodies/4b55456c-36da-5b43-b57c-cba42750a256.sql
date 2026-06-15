SELECT wk.[DateID]
,wk.[Date]
,wk.[TimeFrame]
,wk.[LanguageID]
,wk.[Template]
,wk.[InstrumentID]
,wk.[SendNotification]
,wk.[UniqueSendNotification]
,wk.[OpenNotification]
,wk.[UniqueOpenNotification]
,wk.[OpenPosition]
,wk.[UniqueOpenPosition]
,wk.[IsFirst]
,wk.[UniqueIsFirst]
,wk.[Commission]
,wk.[Investment]
,wk.[UpdateDate]
,dd.ISOYearAndWeekNumber
,CASE WHEN dd.DayNumberOfWeek_Sun_Start = 1 THEN DATEADD(day,-5,wk.[Date]) ELSE CAST(DATEADD(week, DATEDIFF(week, 0, wk.[Date]), 0) AS DATE) END StartOfWeek 
FROM BI_DB.dbo.BI_DB_Volatility_Notifications_Weekly wk WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
ON wk.DateID = dd.DateKey
where TimeFrame = 'Day'