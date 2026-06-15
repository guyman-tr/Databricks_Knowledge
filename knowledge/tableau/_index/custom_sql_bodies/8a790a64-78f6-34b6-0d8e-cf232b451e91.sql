/************************************************************************************** FINAL ***************************************************************************************/


SELECT
  dc.RealCID AS CID,
  ans.*	,
  
  CASE WHEN a.CKA_Completion_Date IS NOT NULL THEN 1 ELSE 0 END AS Completed_CKA,
  a.CKA_Completion_Date,
  a.Final_CKA_PassORFail, -- manual result overrides original results
  a.Final_CKA_PassORFail_Date, -- manual result overrides original results

  CASE WHEN b.CAR_Completion_Date IS NOT NULL THEN 1 ELSE 0 END AS Completed_CAR,
  b.CAR_Completion_Date,
  b.Final_CAR_PassORFail, -- manual result overrides original results
  b.Final_CAR_PassORFail_Date, -- manual result overrides original results

	current_date() AS UpdateDate
FROM
	CKA_CAR_useranswers ans 
  JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON ans.GCID = dc.GCID
	LEFT JOIN CKA_final a ON ans.GCID = a.GCID
	LEFT JOIN CAR_final b ON ans.GCID = b.GCID