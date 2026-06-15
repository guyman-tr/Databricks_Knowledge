/****************************************************  *KPIs on email success KPI ****************************************************/
SELECT sfmc_base.CampaignGroup, sfmc_base.CampaignSubGroup, sfmc_base.CampaignName, sfmc_base.CampaignNumber, sfmc_base.EmailName,
		sfmc_base.SendDateID, LEFT(sfmc_base.SendDateID,6) SendMonth,
		----------------------------- email success metrics-------------------------		
		sfmc_base.UniqueSent_GCID as gcid_count, sfmc_base.CountSend, sfmc_base.CountDelivered as Delivered, sfmc_base.UniqueOpen, sfmc_base.UniqueClicks, 
		sfmc_base.CountBounce, 
		----------------------------- onboarding related metrics-------------------------
		onb_base.Count_conversion_VL1  AS count_cid_v1_after_open, onb_base.Count_conversion_VL2 AS count_cid_v2_after_open, onb_base.Count_conversion_VL3 AS count_cid_v3_after_open, 
		onb_base.Count_conversion_FTD AS count_cid_ftd_after_open, onb_base.Sum_FTDA AS ftda_after_open, 
		onb_base.Sum_FTDA/onb_base.Count_conversion_FTD as avg_ftda_after_open,
		onb_base.Count_conversion_FA AS count_cid_first_trade_after_open, 
		-----------------------------selecting redeposits related metrics-------------------------
		redep_base.count_cid_who_redeposited, redep_base.count_redeposits AS redeposit_ct, 
		redep_base.sum_total_redeposits AS total_redeposit_amount,
		-----------------------------selecting new trades related metrics-------------------------
		dp_base.count_cid_who_opened_new_trades, dp_base.count_new_trade_count AS new_trade_ct, 
		dp_base.sum_new_trade_volume AS total_volume_new_trades
FROM 
(
	SELECT 
		sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
		sfmc.SendDateID, COUNT(DISTINCT sfmc.GCID) UniqueSent_GCID, SUM(sfmc.CountSend) CountSend, SUM(sfmc.Delivered) CountDelivered, SUM(sfmc.UniqueOpen) UniqueOpen,
		SUM(sfmc.UniqueClicks) UniqueClicks, SUM(sfmc.CountBounce) CountBounce
	from
	(
		select sf.CampaignGroup, sf.CampaignSubGroup, sf.CampaignName, sf.CampaignNumber, sf.EmailName,
			sf.SendDateID, sf.GCID, 
			sf.CountSend,
			case when sf.Delivered<=0 then 0 else 1 end as Delivered,
			case when sf.CountBounce>0 then 1 else 0 end as CountBounce,
			sf.UniqueOpen, sf.UniqueClicks 
		frOM main.bi_output.bi_output_marketing_sfmc_sfmc_report sf
		JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON sf.GCID = dc.GCID AND dc.CountryID=219 
			--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) and dc.IsValidCustomer=1
		WHERE sf.SendDateID >=20231101 ---21396
		GROUP BY sf.CampaignGroup, sf.CampaignSubGroup, sf.CampaignName, sf.CampaignNumber, sf.EmailName,
			sf.SendDateID, sf.GCID, 
			sf.CountSend,
			case when sf.Delivered<=0 then 0 else 1 end,
			case when sf.CountBounce>0 then 1 else 0 end,
			sf.UniqueOpen, sf.UniqueClicks 
	)sfmc
	group by sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName, sfmc.SendDateID
)sfmc_base
LEFT JOIN (
		/****************************************************  *KPIs on onboarding funnel, v1-v3, ftd, fa****************************************************/

           select ec.EmailName, ec.SendDateID,  --DATEDIFF(MINUTE,ec.OpenDate_MST,bdoofuk.DateTime_VL1) min_diff_open_to_v1,
            --ec.GCID, ec.OpenDate_MST, from_unixtime(unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a') + (6* 3600) )  OpenDate_GMT
            --count(distinct ec.GCID) ct_gcid_who_opened,
            count(distinct case when (CASE WHEN bdoofuk.DateTime_VL1 IS NULL THEN NULL
                            ELSE (unix_timestamp(bdoofuk.DateTime_VL1, 'yyyy-MM-dd HH:mm:ss.SSS') - unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                	END) between 240 and 480 then ec.GCID end) as Count_conversion_VL1,
            count(distinct case when (CASE WHEN bdoofuk.DateTime_VL2 IS NULL THEN NULL
                            ELSE (unix_timestamp(bdoofuk.DateTime_VL2, 'yyyy-MM-dd HH:mm:ss.SSS') - unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                		END) between 240 and 480 then ec.GCID end) as Count_conversion_VL2,
            count(distinct case when (CASE WHEN bdoofuk.DateTime_VL3 IS NULL THEN NULL
                            ELSE (unix_timestamp(bdoofuk.DateTime_VL3, 'yyyy-MM-dd HH:mm:ss.SSS') - unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                		END) between 240 and 480 then ec.GCID end) as Count_conversion_VL3,
            count(distinct case when (CASE WHEN bdoofuk.DateTime_FTD ='1900-01-01 00:00:00.000' THEN NULL
                            ELSE (unix_timestamp(bdoofuk.DateTime_FTD, 'yyyy-MM-dd HH:mm:ss.SSS') - unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                		END) between 240 and 480 then ec.GCID end) as Count_conversion_FTD,
            sum(distinct case when (CASE WHEN bdoofuk.DateTime_FTD ='1900-01-01 00:00:00.000' THEN NULL
                            ELSE (unix_timestamp(bdoofuk.DateTime_FTD, 'yyyy-MM-dd HH:mm:ss.SSS') - unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                		END) between 240 and 480 then bdoofuk.FirstDepositAmount end) as Sum_FTDA,            
            count(distinct case when (CASE WHEN bdoofuk.FirstActionDate IS NULL THEN NULL
                            ELSE from_unixtime(unix_timestamp(bdoofuk.FirstActionDate, 'yyyy-MM-dd HH:mm:ss.SSS') - unix_timestamp(ec.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                		END) between 240 and 480 then ec.GCID end) as Count_conversion_FA
            from 
            (	
                SELECT 
					sfmc.GCID, dc.RealCID, sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
					sfmc.SendDateID,
					sfmc.SentTime, -- HH:mm:ss.SSSSSSSSS
					sfmc.OpenDate AS OpenDate_MST  --h:m:s a
					/* CASE 
                  			WHEN SentTime IS NULL OR OpenDate IS NULL THEN NULL
                   			 ELSE (unix_timestamp(OpenDate, 'M/d/yyyy h:m:s a') - unix_timestamp(SentTime, 'yyyy-MM-dd HH:mm:ss.SSSSSSSSS')) /60 - 60*6
                		END as min_diff_from_sent_to_open
					*/
				frOM main.bi_output.bi_output_marketing_sfmc_sfmc_report sfmc
				JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON sfmc.GCID = dc.GCID AND dc.CountryID=219 
				--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) and dc.IsValidCustomer=1
				WHERE sfmc.OpenDate IS NOT NULL  
				GROUP BY sfmc.GCID, dc.RealCID, sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
					sfmc.SendDateID, sfmc.SentTime, sfmc.OpenDate
            )ec
            JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis bdoofuk
			    ON bdoofuk.GCID = ec.GCID
            group by ec.EmailName, ec.SendDateID
		
)onb_base ON sfmc_base.SendDateID=onb_base.SendDateID AND sfmc_base.EmailName=onb_base.EmailName

LEFT JOIN (
/**************************************************************KPIs on redeposits******************************************************************/
	SELECT spo.EmailName, spo.SendDateID, 
			--spo.GCID, DepositID, Amount_in_USD, spo.OpenDate_MST, Deposit_Time, 
			--(unix_timestamp(redep.Deposit_Time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(spo.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6 min_diff_from_open_to_redeposit
			COUNT(distinct spo.GCID) count_cid_who_redeposited, 
            COUNT(distinct redep.DepositID) count_redeposits, 
            SUM(redep.Amount_in_USD) sum_total_redeposits
		FROM (
				SELECT 
					sfmc.GCID, dc.RealCID, sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
					sfmc.SentTime, sfmc.SendDateID,
					sfmc.OpenDate AS OpenDate_MST
				frOM main.bi_output.bi_output_marketing_sfmc_sfmc_report sfmc
				JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON sfmc.GCID = dc.GCID AND dc.CountryID=219 
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) and dc.IsValidCustomer=1
				WHERE sfmc.OpenDate IS NOT NULL  
				GROUP BY sfmc.GCID, dc.RealCID, sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
					sfmc.SentTime,  sfmc.SendDateID, sfmc.OpenDate
		) spo
		join (
			SELECT bdad.CID, bdad.DepositID, bdad.Amount_in_USD, bdad.Deposit_Time  
			FROM bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits bdad 
			JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.RealCID=bdad.CID AND dc.CountryID=219 AND dc.IsDepositor=1
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) and dc.IsValidCustomer=1 
			WHERE bdad.PaymentStatus='Approved' 
			AND bdad.ModificationDateID>=20231129
			AND  (
                unix_timestamp(bdad.Deposit_Time, 'yyyy-MM-dd HH:mm:ss') <> unix_timestamp(bdad.FirstDepositDate, 'yyyy-MM-dd HH:mm:ss')
				OR unix_timestamp(bdad.ModificationDate, 'yyyy-MM-dd HH:mm:ss') <> unix_timestamp(bdad.FirstDepositDate, 'yyyy-MM-dd HH:mm:ss')
			)
			GROUP BY bdad.CID, bdad.DepositID, bdad.Amount_in_USD, bdad.Deposit_Time  
		)redep 
		ON redep.CID=spo.RealCID 
        where (unix_timestamp(redep.Deposit_Time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(spo.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                	 between 240 and 480  
		GROUP BY spo.EmailName, spo.SendDateID
		
)redep_base ON sfmc_base.SendDateID=redep_base.SendDateID AND sfmc_base.EmailName=redep_base.EmailName

LEFT JOIN (
/**************************************************************KPIs on NEW TRADES******************************************************************/
		SELECT spo.EmailName, spo.SendDateID,
			COUNT(DISTINCT dp_pre.CID) count_cid_who_opened_new_trades, COUNT(distinct dp_pre.PositionID) count_new_trade_count, SUM(dp_pre.Amount) sum_new_trade_volume
		FROM (
			SELECT 
				sfmc.GCID, dc.RealCID, sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
				sfmc.SentTime, sfmc.SendDateID,
				sfmc.OpenDate AS OpenDate_MST
			frOM main.bi_output.bi_output_marketing_sfmc_sfmc_report sfmc
			JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON sfmc.GCID = dc.GCID AND dc.CountryID=219 
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) and dc.IsValidCustomer=1
			WHERE sfmc.OpenDate IS NOT NULL  
			GROUP BY sfmc.GCID, dc.RealCID, sfmc.CampaignGroup, sfmc.CampaignSubGroup, sfmc.CampaignName, sfmc.CampaignNumber, sfmc.EmailName,
				sfmc.SentTime,  sfmc.SendDateID, sfmc.OpenDate
		) spo
		JOIN ( 
			SELECT dp.CID, PositionID, Amount, OpenOccurred
			FROM main.dwh.dim_position dp 
			JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
                ON dc.RealCID=dp.CID AND dc.CountryID=219 AND dc.IsDepositor=1
--AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) and dc.IsValidCustomer=1 
			AND dp.OpenDateID>=20231130
			WHERE RegulationIDOnOpen in (7,8)
              and coalesce(dp.IsAirDrop, 0) != 1              -- filter out air drops
              and coalesce(dp.IsPartialCloseChild, 0) != 1    -- filter out partial positions
			GROUP BY dp.CID, PositionID, Amount, OpenOccurred
		)dp_pre
		ON dp_pre.CID=spo.RealCID 
        where (unix_timestamp(dp_pre.OpenOccurred, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(spo.OpenDate_MST, 'M/d/yyyy h:m:s a'))/60 - 60*6
                	 between 240 and 480  
		GROUP BY spo.EmailName, spo.SendDateID
)dp_base ON sfmc_base.SendDateID=dp_base.SendDateID AND sfmc_base.EmailName=dp_base.EmailName

GROUP BY sfmc_base.CampaignGroup, sfmc_base.CampaignSubGroup, sfmc_base.CampaignName, sfmc_base.CampaignNumber, sfmc_base.EmailName, LEFT(sfmc_base.SendDateID,6),
		sfmc_base.SendDateID, sfmc_base.UniqueSent_GCID, sfmc_base.CountSend, sfmc_base.CountDelivered, sfmc_base.UniqueOpen, sfmc_base.UniqueClicks, sfmc_base.CountBounce, 
		onb_base.Count_conversion_VL1, onb_base.Count_conversion_VL2, onb_base.Count_conversion_VL3, onb_base.Count_conversion_FTD, onb_base.Sum_FTDA, onb_base.Sum_FTDA/onb_base.Count_conversion_FTD , onb_base.Count_conversion_FA, 
		redep_base.count_cid_who_redeposited, redep_base.count_redeposits, redep_base.sum_total_redeposits, dp_base.count_cid_who_opened_new_trades, dp_base.count_new_trade_count, dp_base.sum_new_trade_volume