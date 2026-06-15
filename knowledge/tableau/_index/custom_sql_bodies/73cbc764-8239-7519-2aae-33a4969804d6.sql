select [CID],
[Club Level],
case when Regulation in (
'eToroUS',
'FinCEN',
'FinCEN+FINRA') then 'FinCEN'
when Regulation in (
'ASIC',
'ASIC & GAML') then 'ASIC' else Regulation end as [Regulation],
[Balance],
[CHB/Refund $ Amount],
[Country By Reg Form],
[Refund / CHB],
[CHB Reason],
[Method Of Payment],
[Month of CHB in BO],
[CHB/ Refund $ Ammount * (-1)],
[CHB Loss],
[CHB Loss by Risk USE],
[Final],
[RN],
[UpdateDate],
[PaymentStatus],
[YearMonth],
[Occurred]

from BI_DB.[dbo].[BI_DB_M_ChargebackReport]