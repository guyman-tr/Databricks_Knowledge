Select 
f.* 
,case when (f.[Total deposits amount upon trigger of the alert] > f.ASSISTIVE) and (f.[Amount before the deposit that triggered the alert] > f.ASSISTIVE) then 'No' else 'Yes' end as 'Should the alert be triggered?'
FROM 
	#final2 f