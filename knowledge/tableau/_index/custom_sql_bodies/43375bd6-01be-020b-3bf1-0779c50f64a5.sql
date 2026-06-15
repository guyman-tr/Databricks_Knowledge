SELECT * FROM BI_DB_QSR_Volume_New WITH (NOLOCK)
WHERE Quarter
between <[Parameters].[Parameter 1]>
and <[Parameters].[Parameter 2]>