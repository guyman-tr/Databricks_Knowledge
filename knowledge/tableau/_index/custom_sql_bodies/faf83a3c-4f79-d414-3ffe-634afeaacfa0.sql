SELECT [External_Fivetran_regtect_euro_nat_gas].[_fivetran_synced] AS [_fivetran_synced],
  [External_Fivetran_regtect_euro_nat_gas].[_row] AS [_row],
CONVERT(DATE,[External_Fivetran_regtect_euro_nat_gas].[expiration_full_date],104) AS [expiration_full_date],
 [External_Fivetran_regtect_euro_nat_gas].[expiration_month] AS [expiration_month]
FROM [Dealing_staging].[External_Fivetran_regtect_euro_nat_gas] [External_Fivetran_regtect_euro_nat_gas]