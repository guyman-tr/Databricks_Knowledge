SELECT 
EOD.Date,
DATENAME(Month, EOD.[Date]) [Period], 
SCD.InstrumentTypeID,
Sum(ABS(EOD.eToroUSDAmount/Conv.rate)) M_NOP
from [AZR-WE-DWH-02].[Dealing].[dbo].[Dealing_Duco_EODRecon] EOD

left join (
select *
,concat(datepart(yy,reporttime),datepart(mm,reporttime)) YearMm
from
(select * ,row_number() over (partition by concat(datepart(yy,reporttime),datepart(mm,reporttime)) order by reporttime desc) RN
FROM [RegReportDB_Prod].[dbo].[Reg_Py_eurofxref_daily]
where to_currency='USD') aa
where RN=1
) Conv on Conv.YearMm =concat(datepart(yy,EOD.Date),datepart(mm,EOD.Date))

JOIN [Reg_Instruments_SCD] SCD on EOD.InstrumentID = SCD.InstrumentID
Where EOD.Date in ('2022-07-29','2022-08-31','2022-09-30','2022-10-31','2022-11-30',
'2022-12-30','2023-01-31','2023-02-28','2023-03-31','2023-04-28','2023-05-31','2023-06-30')
AND LiquidityAccountName not like '%Real%'
AND LiquidityAccountName not like '%REAL%'
--AND SCD.InstrumentTypeID in (4,5,6)
AND EOD.Date between SCD.ValidFrom and SCD.ValidTo
Group By EOD.Date,SCD.InstrumentTypeID