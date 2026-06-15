SELECT
	c.DesignatedRegulation
	,c.Regulation
	,c.Country
	,c.ModificationDateEOMonth
	,sum(c.Amount) as Amount
	,count(distinct Case when c.Approved = 1 then c.WithdrawID end) as 'CO - Total WID Processed'
	,count(distinct c.WithdrawID) as CountDWID
	,count(distinct case when c.WD_ID_SLA = 'OverallSLA' then c.WithdrawID end) as 'WID Processed within SLA24'
	,sum(case when c.HoursBetween < 1 then 1 else 0 end) as '1H SLA'
	,count(*) as 'Number of Records'
FROM 
	#co c
GROUP BY 
	c.DesignatedRegulation
	,c.Regulation
	,c.Country
	,c.ModificationDateEOMonth