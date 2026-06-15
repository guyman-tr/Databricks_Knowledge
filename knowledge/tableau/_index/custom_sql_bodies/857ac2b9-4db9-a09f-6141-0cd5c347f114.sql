SELECT EOD.Date,DATENAME(Month, EOD.[Date]) [Period], Sum(ABS(EOD.eToroUSDAmount/Conv.rate)) M_NOP, SCD.InstrumentTypeID
from [AZR-WE-DWH-02].[Dealing].[dbo].[Dealing_Duco_EODRecon] EOD

left  join (
			select  *
			,concat(datepart(yy,reporttime),datepart(mm,reporttime)) YearMm
			from
				(select  * ,row_number() over (partition by concat(datepart(yy,reporttime),datepart(mm,reporttime)) order by reporttime desc) RN
				FROM [RegReportDB_Prod].[dbo].[Reg_Py_eurofxref_daily]
				where to_currency='USD') aa
				where RN=1
			) Conv  on Conv.YearMm =concat(datepart(yy,EOD.Date),datepart(mm,EOD.Date))

JOIN [Reg_Instruments_SCD] SCD on EOD.InstrumentID = SCD.InstrumentID
--Where EOD.Date = EOMONTH(Date)
Where EOD.Date in ('2023-07-31','2023-08-31','2023-09-29','2023-10-31','2023-11-30',
'2023-12-29','2024-01-31','2024-02-29','2024-03-29','2024-04-30','2024-05-31','2024-06-28')
AND LiquidityAccountName not like '%Real%'
AND LiquidityAccountName not like '%REAL%'
AND SCD.InstrumentID in  (312,313,314)
AND EOD.Date between SCD.ValidFrom and SCD.ValidTo
--AND EOD.Date > '2022-06-30'
--AND EOD.Date <= '2023-06-30'
Group By EOD.Date ,SCD.InstrumentTypeID
UNION
select '9999-12-31' as [Date]
     , 'Average' [Period]
    ,avg(A.M_NOP) as AVG_M_NOP, InstrumentTypeID
    from
	(SELECT EOD.Date,DATENAME(Month, EOD.[Date]) [Period], Sum(ABS(EOD.eToroUSDAmount/Conv.rate)) M_NOP,SCD.InstrumentTypeID
from [AZR-WE-DWH-02].[Dealing].[dbo].[Dealing_Duco_EODRecon] EOD

left  join (
			select  *
			,concat(datepart(yy,reporttime),datepart(mm,reporttime)) YearMm
			from
				(select  * ,row_number() over (partition by concat(datepart(yy,reporttime),datepart(mm,reporttime)) order by reporttime desc) RN
				FROM [RegReportDB_Prod].[dbo].[Reg_Py_eurofxref_daily]
				where to_currency='USD') aa
				where RN=1
			) Conv  on Conv.YearMm =concat(datepart(yy,EOD.Date),datepart(mm,EOD.Date))

LEFT JOIN [Reg_Instruments_SCD] SCD on EOD.InstrumentID = SCD.InstrumentID
--Where EOD.Date = EOMONTH(Date)
Where EOD.Date in  ('2023-07-31','2023-08-31','2023-09-29','2023-10-31','2023-11-30',
'2023-12-29','2024-01-31','2024-02-29','2024-03-29','2024-04-30','2024-05-31','2024-06-28')
AND LiquidityAccountName not like '%Real%'
AND LiquidityAccountName not like '%REAL%'
AND SCD.InstrumentID in  (312,313,314)
AND EOD.Date between SCD.ValidFrom and SCD.ValidTo
--AND Date > '2022-06-30'
--AND Date <= '2023-06-30'
Group By EOD.Date, SCD.InstrumentTypeID) as A
Group By A.InstrumentTypeID