SELECT ProcessDate, 
    
	count(DISTINCT CASE WHEN PayTypeCode='C' THEN AccountNumber end) CountAccount_main_to_ops, 
    count(DISTINCT CASE WHEN PayTypeCode='D' THEN AccountNumber end) CountAccount_ops_to_main, 

	count(DISTINCT CASE WHEN PayTypeCode='C' THEN ACATSControlNumber end) CountAction_main_to_ops, 
    count(DISTINCT CASE WHEN PayTypeCode='D' THEN ACATSControlNumber end) CountAction_ops_to_main, 

	sum(CASE WHEN PayTypeCode='C' THEN abs(Amount) end) AbsAmount_main_to_ops, --, count(DISTINCT ACATSControlNumber) CountTransfers
	sum(CASE WHEN PayTypeCode='D' THEN abs(Amount) end) AbsAmount_ops_to_main
FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity]
WHERE OfficeCode in ('4GS','5GU')  
AND RegisteredRepCode IN ('GAT', 'FO1')
and (TerminalID = 'OMJNL')
AND AccountNumber not in ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100')
--AND PayTypeCode='C' -- for deposits
AND ProcessDate >= DATEADD(WEEK,-10, GETDATE())
GROUP BY ProcessDate--, PayTypeCode