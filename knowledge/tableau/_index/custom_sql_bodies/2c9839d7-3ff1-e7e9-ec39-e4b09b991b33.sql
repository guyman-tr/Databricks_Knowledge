SELECT   [customer_managers].Desk AS [desk1],
            [customer_managers].Desk AS [Desk],
            [customer_managers].IsActive AS [is_active],
		customer_managers.FirstName AS [first_name],
		customer_managers.LastName AS [last_name],
		customer_managers.AccountManagerID AS [manager_id],
		customer_managers.Position AS [position],
		customer_managers.FirstName+' '+ customer_managers.LastName AS [full_name],
		NULL AS [sales_team_leader],
		NULL AS [previous_position],
		NULL AS [previous_position_2],
		NULL AS [office],
		NULL AS [customers],
		NULL AS [_row],
		NULL AS [_fivetran_deleted],
		NULL AS [_fivetran_synced],
		customer_managers.Position AS [manager_type]
FROM [BI_DB_dbo].[External_BI_OUTPUT_Customer_Customer_Support_Agent_User] [customer_managers]
WHERE customer_managers.ToDate='9999-12-31T00:00:00.000Z'