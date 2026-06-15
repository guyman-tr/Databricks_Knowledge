SELECT 'Unique' SendMonth,  'SKIP' AS CampaignGroup, 'SKIP' AS CampaignSubGroup, 
		COUNT(DISTINCT base_sfmc.GCID) unique_gcid_contacted_per_month
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report base_sfmc
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON base_sfmc.GCID=dc.GCID AND dc.CountryID=219 
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) AND dc.IsValidCustomer=1
AND base_sfmc.SendDateID>=20231130
WHERE base_sfmc.GCID!=25039419
UNION ALL

----monthly unique contacted
SELECT LEFT(base_sfmc.SendDateID,6) AS SendMonth,  'SKIP' AS CampaignGroup, 'SKIP' AS CampaignSubGroup, 
		COUNT(DISTINCT base_sfmc.GCID) unique_gcid_contacted_per_month
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report base_sfmc
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON base_sfmc.GCID=dc.GCID AND dc.CountryID=219 
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8)  AND dc.IsValidCustomer=1
AND base_sfmc.SendDateID>=20231130
	--AND base_sfmc.CampaignNumber='0012'--'7156'
GROUP BY  LEFT(base_sfmc.SendDateID,6)
HAVING COUNT(DISTINCT base_sfmc.GCID)>1

UNION ALL

----monthly unique contacted by campaign group, subgroup

SELECT LEFT(base_sfmc.SendDateID,6) AS SendMonth, base_sfmc.CampaignGroup, base_sfmc.CampaignSubGroup, 
		COUNT(DISTINCT base_sfmc.GCID) unique_gcid_contacted_per_month
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report base_sfmc
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON base_sfmc.GCID=dc.GCID AND dc.CountryID=219 
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8)  AND dc.IsValidCustomer=1
AND base_sfmc.SendDateID>=20231130
GROUP BY LEFT(base_sfmc.SendDateID,6), base_sfmc.CampaignGroup, base_sfmc.CampaignSubGroup
HAVING COUNT(DISTINCT base_sfmc.GCID)>1