SELECT * ,
SUBSTRING([Date received],CHARINDEX('/',[Date received])+1,(((LEN([Date received]))-CHARINDEX('/', REVERSE([Date received])))-CHARINDEX('/',[Date received]))) MonthReceived
FROM BI_DB_dbo.[BI_DB_Deposits_WiresFromGooglesheets] fg
WHERE 1=1
AND NOT(fg.[Full description for MEMO BO] IS NULL AND fg.[IBAN / Account number] IS NULL AND fg.[Deposit ID] IS NULL AND fg.[Amount received] LIKE '%N%')