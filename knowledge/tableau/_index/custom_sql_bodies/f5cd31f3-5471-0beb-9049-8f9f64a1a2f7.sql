SELECT * ,
SUBSTRING(fg.date_received,CHARINDEX('/',fg.date_received)+1,(((LEN(fg.date_received))-CHARINDEX('/', REVERSE(fg.date_received)))-CHARINDEX('/',fg.date_received))) MonthReceived
FROM [BI_DB_dbo].[External_Fivetran_google_sheets_wire_deposits_ops] fg
WHERE 1=1
AND NOT(fg.full_description_for_memo_bo IS NULL AND fg.iban_account_number IS NULL AND fg.deposit_id IS NULL AND fg.amount_received LIKE '%N%')