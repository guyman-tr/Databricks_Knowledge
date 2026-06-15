SELECT DISTINCT sfmc.*,
	
	case when onb.count_cid_v1_after_open=0 then null else onb.count_cid_v1_after_open end as count_cid_v1_after_open, 
	case when onb.count_cid_v2_after_open=0 then null else onb.count_cid_v2_after_open end as count_cid_v2_after_open, 
	case when onb.count_cid_v3_after_open=0 then null else onb.count_cid_v3_after_open end as count_cid_v3_after_open, 
	case when onb.count_cid_ftd_after_open=0 then null else onb.count_cid_ftd_after_open end as count_cid_ftd_after_open, 
	case when red.count_cid_redeposit_after_open =0 then null else red.count_cid_redeposit_after_open end as count_cid_redeposit_after_open,
	case when onb.count_cid_first_trade_after_open=0 then null else onb.count_cid_first_trade_after_open END count_cid_first_trade_after_open,
	
	onb.avg_min_to_V1_after_open, 
	onb.avg_min_to_V2_after_open, 
	onb.avg_min_to_V3_after_open, 
	onb.avg_min_to_ftd_after_open, 
	onb.avg_min_to_first_trade_after_open,
	onb.ftda_after_open,
	onb.avg_ftda_after_open,

	red.redeposit_ct_after_open,  
	red.total_redeposit_amount_after_open,
	red.avg_redeposit_amount_per_redeposit,
	red.avg_redeposit_amount_per_cid,
	red.avg_min_to_redeposit_level_deposit,
	red.avg_min_to_redeposit_level_cid
fROM  
	(SELECT left(base_sfmc.SendDateID,6) AS SendMonth, base_sfmc.EmailName, base_sfmc.CampaignName, base_sfmc.CampaignNumber, base_sfmc.CampaignGroup, base_sfmc.CampaignSubGroup, 
		COUNT(DISTINCT base_sfmc.GCID) gcid_count, SUM(base_sfmc.CountSend) CountSend, SUM(base_sfmc.Delivered) Delivered, SUM(base_sfmc.UniqueOpen) UniqueOpen, SUM(base_sfmc.UniqueClicks) UniqueClicks, SUM(base_sfmc.CountBounce) CountBounce
	FROM [BI_DB].[dbo].[BI_DB_SFMC_Report] base_sfmc
	JOIN DWH..Dim_Customer dc ON base_sfmc.GCID=dc.GCID AND dc.CountryID=218 AND base_sfmc.UniqueOpen=1 AND base_sfmc.CampaignNumber IN ('8540','8507','8199','8407','5219') 
	AND left(base_sfmc.SendDateID,6)>=202301
	 --AND base_sfmc.CampaignNumber='0012'--'7156'
	GROUP BY left(base_sfmc.SendDateID,6),  base_sfmc.EmailName, base_sfmc.CampaignName, base_sfmc.CampaignNumber, base_sfmc.CampaignGroup, base_sfmc.CampaignSubGroup
	) sfmc  
/****************************************************************************************KPIs on onboarding funnel, v1-v3, ftd, fa***************************************************************************************************************************************/
LEFT JOIN ( 
	SELECT DISTINCT SendMonth, base_onb.EmailName, base_onb.CampaignName, base_onb.CampaignNumber, base_onb.CampaignGroup, base_onb.CampaignSubGroup, 			
		COUNT(CASE WHEN (base_onb.DateTime_VL1 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL1) <=480) THEN base_onb.GCID else null end) as count_cid_v1_after_open, 
		COUNT(CASE WHEN (base_onb.DateTime_VL2 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL2) <=480) THEN base_onb.GCID else null end) as count_cid_v2_after_open, 
		COUNT(CASE WHEN (base_onb.DateTime_VL3 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL3) <=480) THEN base_onb.GCID else null end) as count_cid_v3_after_open, 
		COUNT(CASE WHEN (base_onb.DateTime_FTD > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) <=480) THEN base_onb.GCID else null end) as count_cid_ftd_after_open, 
		COUNT(CASE WHEN (base_onb.DateTime_FA > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FA) <=480)  THEN base_onb.GCID else null end) as count_cid_first_trade_after_open,
		sum(CASE WHEN (base_onb.DateTime_VL1 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL1) <=480) THEN DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL1) else null end) / 
           COUNT(CASE WHEN (base_onb.DateTime_VL1 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL1) <=480) THEN base_onb.GCID else null end)  
            as avg_min_to_V1_after_open, 
		sum(CASE WHEN (base_onb.DateTime_VL2 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL2) <=480) THEN DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL2) else null end) / 
           COUNT(CASE WHEN (base_onb.DateTime_VL2 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL2) <=480) THEN base_onb.GCID else null end)  
            as avg_min_to_V2_after_open, 
		sum(CASE WHEN (base_onb.DateTime_VL3 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL3) <=480) THEN DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL3) else null end) / 
           COUNT(CASE WHEN (base_onb.DateTime_VL3 > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_VL3) <=480) THEN base_onb.GCID else null end) 
            as avg_min_to_V3_after_open, 
		sum(CASE WHEN (base_onb.DateTime_FTD > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) <=480) THEN DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) else null end) / 
           COUNT(CASE WHEN (base_onb.DateTime_FTD > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) <=480) THEN base_onb.GCID else null end) 
            as avg_min_to_ftd_after_open, 
		sum(CASE WHEN (base_onb.DateTime_FA > onb_first_open_date_per_month AND  DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FA) <=480)  THEN DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FA)  else null end) / 
           COUNT(CASE WHEN (base_onb.DateTime_FA > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FA) <=480)  THEN base_onb.GCID else null end)
            as avg_min_to_first_trade_after_open,
		sum(CASE WHEN (base_onb.DateTime_FTD > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) <=480) THEN base_onb.FirstDepositAmount else null end) AS ftda_after_open,
		sum(CASE WHEN (base_onb.DateTime_FTD > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) <=480) THEN base_onb.FirstDepositAmount else null end)/
		   COUNT(CASE WHEN (base_onb.DateTime_FTD > onb_first_open_date_per_month AND DATEDIFF(MINUTE, onb_first_open_date_per_month, base_onb.DateTime_FTD) <=480) THEN base_onb.GCID else null end)
			AS avg_ftda_after_open
	FROM
	(	
		SELECT DISTINCT bdoofuk.GCID, left(SendDateID,6) SendMonth, sf_onb.EmailName, sf_onb.CampaignName, sf_onb.CampaignNumber, sf_onb.CampaignGroup, sf_onb.CampaignSubGroup, 
			DATEADD(HOUR,6,MIN(sf_onb.OpenDate)) AS onb_first_open_date_per_month, 
			bdoofuk.DateTime_VL1, bdoofuk.DateTime_VL2, bdoofuk.DateTime_VL3, 
			bdoofuk.DateTime_FTD, bdoofuk.FirstDepositAmount,
			bdoofuk.FirstActionDate AS DateTime_FA		
		FROM [BI_DB].[dbo].[BI_DB_SFMC_Report] sf_onb 
		JOIN BI_DB..BI_DB_Operations_Onboarding_Flow_UserKPIs bdoofuk ON sf_onb.GCID = bdoofuk.GCID AND left(sf_onb.SendDateID,6)>=202301 and sf_onb.UniqueOpen=1 
		AND bdoofuk.CountryID=218 AND sf_onb.CampaignNumber IN ('8540','8507','8199','8407','5219')
		AND sf_onb.UniqueOpen=1 
		--and sf_onb.CampaignNumber='0012'--'1463'
		GROUP BY bdoofuk.GCID, left(SendDateID,6), sf_onb.EmailName, sf_onb.CampaignName, sf_onb.CampaignNumber, sf_onb.CampaignGroup, sf_onb.CampaignSubGroup, 
		bdoofuk.DateTime_VL1, bdoofuk.DateTime_VL2, bdoofuk.DateTime_VL3, bdoofuk.DateTime_FTD, bdoofuk.FirstDepositAmount, 
		bdoofuk.FirstActionDate
		HAVING 
			(bdoofuk.DateTime_VL1>DATEADD(HOUR,6,MIN(sf_onb.OpenDate)) AND DATEDIFF(MINUTE, DATEADD(HOUR,6,MIN(sf_onb.OpenDate)), bdoofuk.DateTime_VL1) <=480) OR
			(bdoofuk.DateTime_VL2>DATEADD(HOUR,6,MIN(sf_onb.OpenDate)) AND DATEDIFF(MINUTE, DATEADD(HOUR,6,MIN(sf_onb.OpenDate)), bdoofuk.DateTime_VL2) <=480) OR
			(bdoofuk.DateTime_VL3>DATEADD(HOUR,6,MIN(sf_onb.OpenDate)) AND DATEDIFF(MINUTE, DATEADD(HOUR,6,MIN(sf_onb.OpenDate)), bdoofuk.DateTime_VL3) <=480) OR
			(bdoofuk.DateTime_FTD>DATEADD(HOUR,6,MIN(sf_onb.OpenDate)) AND DATEDIFF(MINUTE, DATEADD(HOUR,6,MIN(sf_onb.OpenDate)), bdoofuk.DateTime_FTD) <=480) OR
			(bdoofuk.FirstActionDate>DATEADD(HOUR,6,MIN(sf_onb.OpenDate)) AND DATEDIFF(MINUTE, DATEADD(HOUR,6,MIN(sf_onb.OpenDate)), bdoofuk.FirstActionDate) <=480) 
	)base_onb 
	GROUP BY SendMonth, base_onb.EmailName, base_onb.CampaignName, base_onb.CampaignNumber, base_onb.CampaignGroup, base_onb.CampaignSubGroup 	
	
)onb ON CONCAT(onb.SendMonth, onb.EmailName, onb.CampaignName, onb.CampaignNumber, onb.CampaignGroup, onb.CampaignSubGroup)=
		CONCAT(sfmc.SendMonth, sfmc.EmailName, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.CampaignGroup, sfmc.CampaignSubGroup)
/****************************************************************************************KPIs on redeposits***************************************************************************************************************************************/	
LEFT JOIN (
	---step 1: locate all qualifying redeposits and map all records to cid level per email campaign
	---step 2: aggregate redeposits to email campaign / CID level
	SELECT base_red.SendMonth, base_red.EmailName, base_red.CampaignName, base_red.CampaignNumber, base_red.CampaignGroup, base_red.CampaignSubGroup, 
		COUNT(DISTINCT base_red.GCID) AS count_cid_redeposit_after_open,
		SUM(redeposit_ct) AS redeposit_ct_after_open,  
		SUM(total_redeposit_amount) AS total_redeposit_amount_after_open,
		SUM(total_redeposit_amount)/SUM(redeposit_ct) AS avg_redeposit_amount_per_redeposit,
		SUM(total_redeposit_amount)/COUNT(DISTINCT base_red.GCID) AS avg_redeposit_amount_per_cid,
		SUM(min_to_first_redeposit)/SUM(redeposit_ct) AS avg_min_to_redeposit_level_deposit,
		SUM(min_to_first_redeposit)/COUNT(DISTINCT base_red.GCID) AS avg_min_to_redeposit_level_cid
	FROM 
		(SELECT sf_red.GCID, sf_red.RealCID, SendMonth, EmailName, CampaignName, CampaignNumber, CampaignGroup, CampaignSubGroup, red_first_open_date_per_month, 			
			COUNT(DISTINCT bdad.DepositID) redeposit_ct, MIN(bdad.[Deposit Time]) first_redeposit_dt, SUM(bdad.[Amount in $]) total_redeposit_amount, DATEDIFF(MINUTE, red_first_open_date_per_month, MIN(bdad.[Deposit Time])) min_to_first_redeposit		
		from
			(
			SELECT sf.GCID, dc.RealCID, left(SendDateID,6) SendMonth, EmailName, CampaignName, CampaignNumber, CampaignGroup, CampaignSubGroup, 
				DATEADD(HOUR,6,MIN(OpenDate)) AS red_first_open_date_per_month
			FROM [BI_DB].[dbo].[BI_DB_SFMC_Report] sf
			JOIN DWH..Dim_Customer dc ON sf.GCID=dc.GCID AND dc.CountryID=218 AND sf.UniqueOpen=1 AND sf.CampaignNumber IN ('8540','8507','8199','8407','5219')
			--dc.CountryID=219 AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) 
			WHERE UniqueOpen=1 AND left(SendDateID,6)>=202301 --and CampaignNumber='0012'
			GROUP BY sf.GCID, dc.RealCID, left(SendDateID,6) , EmailName, CampaignName, CampaignNumber, CampaignGroup, CampaignSubGroup, dc.FirstDepositDate 
			)sf_red 
		JOIN BI_DB..BI_DB_AllDeposits bdad ON bdad.CID=sf_red.RealCID AND bdad.PaymentStatus='Approved' 
		AND bdad.[Deposit Time] > red_first_open_date_per_month AND bdad.[Deposit Time] <=DATEADD(minute,480, red_first_open_date_per_month)
		AND (bdad.[Deposit Time] != bdad.FirstDepositDate OR bdad.ModificationDate!=bdad.FirstDepositDate)
		GROUP BY sf_red.GCID, sf_red.RealCID, SendMonth, EmailName, CampaignName, CampaignNumber, CampaignGroup, CampaignSubGroup, red_first_open_date_per_month
		)base_red
	GROUP BY base_red.SendMonth, base_red.EmailName, base_red.CampaignName, base_red.CampaignNumber, base_red.CampaignGroup, base_red.CampaignSubGroup
)red ON CONCAT(red.SendMonth, red.EmailName, red.CampaignName, red.CampaignNumber, red.CampaignGroup, red.CampaignSubGroup)=
		CONCAT(sfmc.SendMonth, sfmc.EmailName, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.CampaignGroup, sfmc.CampaignSubGroup)