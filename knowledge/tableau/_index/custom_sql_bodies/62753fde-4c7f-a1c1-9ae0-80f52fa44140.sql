SELECT sp.*
	, vrsss.running_status AS running_status_name
FROM Reprocess_Synapce_SP sp
	LEFT JOIN v_Reprocess_Synapce_SP_status vrsss 
		ON vrsss.id = sp.id