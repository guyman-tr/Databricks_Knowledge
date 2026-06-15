SELECT DateID, CID, SUM(ISNULL(ClosingBalance,0 )) 'ClosingBalance', SUM(ISNULL(bdcbcln.OpeningBalance,0 ))'OpeningBalance' 
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln 
WHERE CID IN (
3400616
,10526243
,11464063
,10842855
,21547142
,34537826
,35473655) AND  
DateID BETWEEN 
<[Parameters].[Parameter 1]>
AND 
<[Parameters].[Parameter 2]>
GROUP BY CID, DateID