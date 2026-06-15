Select 
	c.*
	,d.TotalDeposits
	,case when f.CID is Null then 0 else 1 end as RAF_CO_LowBalance_Filter
from 
	#cids c
LEFT JOIN 
	#dep d on d.CID = c.CID
LEFT JOIN 
	#final f on f.CID = c.CID
WHERE 
	year(c.Occurred) > 2024