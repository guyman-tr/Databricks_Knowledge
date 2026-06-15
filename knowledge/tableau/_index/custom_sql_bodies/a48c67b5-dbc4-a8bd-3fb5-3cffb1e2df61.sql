select base.*
,(YearMonth / 100) * 100 + 
                 CASE 
                     WHEN (YearMonth % 100) >= 1 AND (YearMonth % 100) <= 3 THEN 1
                     WHEN (YearMonth % 100) >= 4 AND (YearMonth % 100) <= 6 THEN 2
                     WHEN (YearMonth % 100) >= 7 AND (YearMonth % 100) <= 9 THEN 3
                     WHEN (YearMonth % 100) >= 10 AND (YearMonth % 100) <= 12 THEN 4
                 END as YearQuarter
,left(YearMonth,4) as Year
from
(


select distinct B.[CID],
B.[Club Level],
case when B.Regulation in (
'eToroUS',
'FinCEN',
'FinCEN+FINRA') then 'FinCEN'
when B.Regulation in (
'ASIC',
'ASIC & GAML') then 'ASIC' else B.Regulation end as [Regulation],
B.[Balance],
B.[CHB/Refund $ Amount],
B.[Country By Reg Form],
B.[Refund / CHB],
B.[CHB Reason],
B.[Method Of Payment],
B.[Month of CHB in BO],
B.[CHB/ Refund $ Ammount * (-1)],
B.[CHB Loss],
B.[CHB Loss by Risk USE],
B.[Final],
B.[RN],
B.[UpdateDate],
B.[PaymentStatus],
B.[YearMonth],
B.[Occurred],
datediff(year,dc.BirthDate, getdate()) as Age,
sp.Name as State




from [BI_DB_dbo].[BI_DB_ChargebackReport] B
JOIN [DWH_dbo].Dim_Customer dc on dc.RealCID=B.CID
left join [DWH_dbo].Dim_State_and_Province sp on sp.RegionByIP_ID=dc.RegionByIP_ID and dc.CountryID=sp.CountryID
)base