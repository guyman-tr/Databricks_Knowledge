SELECT * FROM BI_DB_QSR_Balance_New bdqbn with (nolock)
WHERE bdqbn.Quarter
between <[Parameters].[Parameter 1]>
and <[Parameters].[Parameter 2]>