SELECT t.account_manager
		,t.region
		,t.type_of_kpi
		,t.target
                ,cast(t.month as Date) Date
FROM [BI_DB_dbo].[External_Fivetran_google_sheets_account_manager_targets_2024] t