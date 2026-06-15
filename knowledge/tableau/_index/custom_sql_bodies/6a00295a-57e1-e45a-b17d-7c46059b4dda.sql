select 
Time_Period, ActiveDate, Country, 
 Club,
SUM(Opened_Manual_Or_Copy) 	Opened_Manual_Or_Copy,
SUM(Opened_Manual) 					Opened_Manual,
SUM(Opened_Copy_Trader) 		Opened_Copy_Trader,
SUM(Opened_Smart_Portfolio) Opened_Smart_Portfolio,
SUM(Opened_Stocks) 					Opened_Stocks,
SUM(Opened_Crypto) 					Opened_Crypto,
SUM(Active) 								Active,
SUM(Active_Manual) 					Active_Manual,
SUM(Active_Copy) 						Active_Copy,
SUM(EOM_Equity_Manual) 			EOM_Equity_Manual,
SUM(EOM_Equity_Copy) 				EOM_Equity_Copy,
SUM(EOM_Balance)                EOM_Balance
from (
select 
'Monthly' Time_Period,
f.CID,f.ActiveDate,f.Country,f.EOM_Club Club,
(SELECT MAX(i) Opened_Manual_Or_Copy FROM
(SELECT IsOpen_Copy AS i UNION 
SELECT IsOpen_CopyPortfolio UNION
SELECT ActiveOpen_Real_Stocks UNION
SELECT ActiveOpen_CFD_Stocks UNION
SELECT ActiveOpen_Real_Crypto UNION
SELECT ActiveOpen_CFD_Crypto UNION
SELECT f.[ActiveOpen_FX/Comm/Ind]) a )Opened_Manual_Or_Copy,
(SELECT MAX(i) Opened_Manual FROM 
(SELECT  ActiveOpen_Real_Stocks AS i UNION
SELECT ActiveOpen_CFD_Stocks UNION 
SELECT ActiveOpen_Real_Crypto UNION 
SELECT ActiveOpen_CFD_Crypto UNION
SELECT f.[ActiveOpen_FX/Comm/Ind] )a) Opened_Manual,
f.IsOpen_Copy Opened_Copy_Trader,
f.IsOpen_CopyPortfolio Opened_Smart_Portfolio,
CASE WHEN f.Active_Real_Stocks = 1 then 1 else f.Active_CFD_Stocks END Opened_Stocks,
CASE WHEN f.ActiveOpen_Real_Crypto = 1 then 1 else f.ActiveOpen_CFD_Crypto END  Opened_Crypto,
f.Active,
(SELECT MAX(i) Active_Manual FROM
(SELECT Active_Real_Stocks AS i UNION
SELECT Active_CFD_Stocks UNION	
SELECT Active_Real_Crypto UNION 
SELECT Active_CFD_Crypto UNION
SELECT [Active_FX/Comm/Ind] )a)  Active_Manual,
f.Active_Copy,
(SELECT MAX(i) EOM_Equity_Manual FROM
(SELECT EOM_Equity_Real_Crypto AS i UNION
SELECT EOM_Equity_Real_Stocks UNION 
SELECT EOM_Equity_CFD_Crypto UNION
SELECT EOM_Equity_CFD_Stocks UNION
SELECT f.[EOM_Equity_FX/Comm/Ind] )a) EOM_Equity_Manual,
f.EOM_Equity_Copy
,f.EOM_Balance
from [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] f
WHERE f.ActiveDate BETWEEN dateADD(MONTH,-13,GETDATE()) AND dateADD(MONTH,-1,GETDATE())  
UNION ALL
select 
'Weekly' Time_Period,
f.CID, f.FirstDayOfWeek, f.Country, f.EOW_Club Club, 
(SELECT MAX(i) Opened_Manual_Or_Copy FROM
(SELECT IsOpen_Copy AS i UNION 
SELECT IsOpen_CopyPortfolio UNION
SELECT ActiveOpen_Real_Stocks UNION
SELECT ActiveOpen_CFD_Stocks UNION
SELECT ActiveOpen_Real_Crypto UNION
SELECT ActiveOpen_CFD_Crypto UNION
SELECT f.[ActiveOpen_FX/Comm/Ind]) a )Opened_Manual_Or_Copy,   
(SELECT MAX(i) Opened_Manual FROM 
(SELECT  ActiveOpen_Real_Stocks AS i UNION
SELECT ActiveOpen_CFD_Stocks UNION 
SELECT ActiveOpen_Real_Crypto UNION 
SELECT ActiveOpen_CFD_Crypto UNION
SELECT f.[ActiveOpen_FX/Comm/Ind] )a) Opened_Manual,
f.IsOpen_Copy Opened_Copy_Trader,
f.IsOpen_CopyPortfolio Opened_Smart_Portfolio,
CASE WHEN f.Active_Real_Stocks = 1 then 1 else f.Active_CFD_Stocks END Opened_Stocks,
CASE WHEN f.ActiveOpen_Real_Crypto = 1 then 1 else f.ActiveOpen_CFD_Crypto END Opened_Crypto,
NULL,
NULL,       
NULL,
NULL,
NULL,
NULL
from [BI_DB_dbo].[BI_DB_CID_WeeklyPanel_FullData] f
where 
f.YearWeekNumber in 
(SELECT distinct concat(dd.CalendarYear, '-', dd.ISOWeekNumberOfYear)
from DWH_dbo.Dim_Date dd
where dd.FullDate BETWEEN DATEADD(week,-13, DATEADD(day,-1,DATEADD(wk,DATEDIFF(wk,7,CAST(YEAR(GETDATE()) AS NVARCHAR(100))) + (datepart(week, GETDATE())-1),7))) and
DATEADD(week,-1, DATEADD(day,-1,DATEADD(wk,DATEDIFF(wk,7,CAST(YEAR(GETDATE()) AS NVARCHAR(100))) + (datepart(week, GETDATE())-1),7)))
)
UNION ALL
select 
'Daily' Time_Period,
f.CID, f.ActiveDate, f.Country, f.EOD_Club Club, 
 (SELECT MAX(i) Opened_Manual_Or_Copy FROM
(SELECT IsOpen_Copy AS i UNION 
SELECT IsOpen_CopyPortfolio UNION
SELECT ActiveOpen_Real_Stocks UNION
SELECT ActiveOpen_CFD_Stocks UNION
SELECT ActiveOpen_Real_Crypto UNION
SELECT ActiveOpen_CFD_Crypto UNION
SELECT f.[ActiveOpen_FX/Comm/Ind]) a )Opened_Manual_Or_Copy, 
(SELECT MAX(i) Opened_Manual FROM 
(SELECT  ActiveOpen_Real_Stocks AS i UNION
SELECT ActiveOpen_CFD_Stocks UNION 
SELECT ActiveOpen_Real_Crypto UNION 
SELECT ActiveOpen_CFD_Crypto UNION
SELECT f.[ActiveOpen_FX/Comm/Ind] )a) Opened_Manual,
f.IsOpen_Copy																																		Opened_Copy_Trader,
f.IsOpen_CopyPortfolio																													Opened_Smart_Portfolio,
CASE WHEN f.Active_Real_Stocks = 1 then 1 else f.Active_CFD_Stocks end					Opened_Stocks,
CASE WHEN f.ActiveOpen_Real_Crypto = 1 then 1 else f.ActiveOpen_CFD_Crypto END  Opened_Crypto,
    
NULL,
NULL,       
NULL,
NULL,
NULL,
NULL
from [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData] f
where 
f.ActiveDate BETWEEN dateADD(DAY,-31,GETDATE()) and  dateADD(DAY,-1,GETDATE())  
) as final
group by Time_Period, ActiveDate, Country
, Club