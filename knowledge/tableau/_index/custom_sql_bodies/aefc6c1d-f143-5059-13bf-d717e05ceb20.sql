SELECT CID,YearWeekNumber,a.SSWeekNumberOfYear, CalendarYear, Seniority, FTDdate, Country, Channel, EOW_Club, Revenue_Total, 
SUM(Revenue_Total) OVER (PARTITION BY a.CID ORDER BY a.SSWeekNumberOfYear asc) ACC_Revenue_Total,
CASE WHEN Channel = 'Friend Referral' THEN 1 ELSE 0 END IsRAF,
CASE WHEN b.CountryID in (74,191,13,79,197,100,57,143,196,219,218,102,162,183,202,226,55,164,12) THEN 1 ELSE 0 END Is_RAF_Countries,
ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.SSWeekNumberOfYear asc) SeniorityWeek
from dbo.BI_DB_CID_WeeklyPanel_FullData a
JOIN DWH.dbo.Dim_Country b
ON a.Country=b.Name
WHERE CalendarYear=2023 AND a.FTDdate>='2023-01-01'
and SSWeekNumberOfYear <= DATEPART(WEEK, GETDATE() ) -1