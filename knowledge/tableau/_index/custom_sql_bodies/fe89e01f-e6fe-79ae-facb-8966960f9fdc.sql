select cast(calendar_month_id as int) as StakingMonthID
		,year(calendar_month) StakingYear
		,datename(month,calendar_month) as StakingMonth
		,cast(instrument_id as int) as InstrumentID
		,currency as Currency
		,eligibility_monthly_rewards as  IncomeClients
                ,income_nostro as IncomeNostro
from [CopyFromLake].[Bronze_Fivetran_google_sheets_eligibility_monthly_rewards]
Where ((is_us<>1) or (is_us is null))