SELECT t.account_manager
		,t.region
                ,t.position
		,t.type_of_kpi
		,t.target
        ,cast(t.month as Date) Date
		,dd.CalendarYearQtr
FROM [BI_DB_dbo].[External_Fivetran_google_sheets_account_manager_targets_2024] t
JOIN DWH_dbo.Dim_Date dd
ON cast(t.month as Date) = dd.FullDate