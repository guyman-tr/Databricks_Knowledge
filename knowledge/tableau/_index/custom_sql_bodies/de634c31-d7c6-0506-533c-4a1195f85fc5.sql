SELECT DISTINCT tab2.EoM_date, tab2.Channel, 
	tab1.Impressions, tab1.Clicks, tab1.Views_10s, tab1.Cost, tab2.Click_on_CTA,
	tab2.Platform_Regs, tab2.Platform_FTD, tab2.Platform_V2,
	tab2.us_options_campaign_filter 
FROM (
	---- step 1: get platform regs, platform ftd: needs to consider conversion action name change in May 2023 -> data solution

	SELECT DISTINCT 			
			EOMONTH(main.date) EoM_date,
			CASE
			 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
			 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
			 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
			 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
			 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
			 ---UAC need to be handled separately given old conversion name generated unreliable results for UAC after may 2023
			END AS Channel, 
			SUM(CASE WHEN conversion_action_name='Click on CTA' THEN all_conversions-view_through_conversions ELSE 0 end) Click_on_CTA, 
			SUM(CASE WHEN conversion_action_name IN (
				--NEW conversion name since some time in may 2023: 
				'Registration Android-Firebase','Registration IOS-Firebase','Registration Web',
				--plus old conversion name used up till som time in may 2023: uncertain about the earliest these were put in use, but should hold accountable from at least january 2023:
				'Registration', 
				'eToro Cryptocurrency Trading (iOS) registration', 
				'eToro: Crypto. Stocks. Social. (iOS) registration', 
				'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
				'eToro: Investing made social (Android) registration',
				--adding options specific conversion names:
				'etoro_reg' 
				) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_Regs,
			SUM(CASE WHEN conversion_action_name IN (
				--NEW conversion name since some time in may 2023: 
				'V2 Android-Firebase','V2 IOS-Firebase','V2 Web',
				--plus old conversion name used up till som time in may 2023: uncertain about the earliest these were put in use, but should hold accountable from at least january 2023:
				'V2 Status', 		'V2_app_iOS',
				'eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2',
				'eToro: Stocks. Crypto. Social. (Android) Verification Level - 2',
				'eToro: Investing made social (Android) Verification Level - 2',
				'eToro: Investing made social (iOS) Verification Level - 2'
			 ) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_V2,
			SUM(CASE WHEN conversion_action_name IN (
				--NEW conversion name since some time in may 2023: 			
				'FTD Android-Firebase','FTD IOS-Firebase','FTD Web',
				--plus old conversion name used up till som time in may 2023: uncertain about the earliest these were put in use, but should hold accountable from at least january 2023:
				'FTD',
				'eToro: Investing made social (Android) FTD', 
				'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD', 
				'eToro Cryptocurrency Trading (iOS) FTD', 
				'eToro: Crypto. Stocks. Social. (iOS) FTD',
				--adding options specific conversion name:
				'etoro_ftd'
				) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_FTD,
			CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END AS us_options_campaign_filter --main.status,main.campaign_status
		FROM [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.perf_adgroup_performance_report main	
		JOIN [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.conv_adgroup_performance_report cv ON main.id = cv.id AND main.date = cv.date AND main.device = cv.device--campaign id is not unique
		AND main.date >='2023-01-01'
		WHERE 	case
			 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
			 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
			 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
			 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
			 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
			END  IS NOT NULL
		GROUP BY EOMONTH(main.date), 		CASE
			 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
			 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
			 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
			 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
			 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
			END, 		CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END 
		/*	ORDER BY EOMONTH(main.date), 		CASE
				 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
				 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
				 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
				 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
				 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
				END
		*/

		UNION ALL 
		 ---UAC from may 2023 and onwards: new conversion names

		SELECT DISTINCT 			
			EOMONTH(main.date) EoM_date,
			CASE WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
				END AS Channel, 
			SUM(CASE WHEN conversion_action_name='Click on CTA' THEN all_conversions-view_through_conversions ELSE 0 end) Click_on_CTA, 
			SUM(CASE WHEN conversion_action_name IN ('Registration Android-Firebase','Registration IOS-Firebase','Registration Web','etoro_reg'	--adding options specific conversion name:
				) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_Regs,
			SUM(CASE WHEN conversion_action_name IN ('V2 Android-Firebase','V2 IOS-Firebase','V2 Web') THEN all_conversions-view_through_conversions ELSE 0 end) Platform_V2,
			SUM(CASE WHEN conversion_action_name IN ('FTD Android-Firebase','FTD IOS-Firebase','FTD Web','etoro_ftd' --adding options specific conversion name:
				) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_FTD,
			CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END AS us_options_campaign_filter
		FROM [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.perf_adgroup_performance_report main	
		JOIN [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.conv_adgroup_performance_report cv ON main.id = cv.id AND main.date = cv.date AND main.device = cv.device--campaign id is not unique
		AND main.date >='2023-05-01'
		WHERE 	 
			CASE WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
			END  IS NOT NULL
		GROUP BY EOMONTH(main.date), CASE 
			WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
			END, CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END 

	 UNION ALL
	 ---UAC from jan to may 2023: old conversion names

		SELECT DISTINCT 			
			EOMONTH(main.date) EoM_date,
			CASE WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
				END AS Channel, 
			SUM(CASE WHEN conversion_action_name='Click on CTA' THEN all_conversions-view_through_conversions ELSE 0 end) Click_on_CTA, 
			SUM(CASE WHEN conversion_action_name IN ('Registration', 
				'eToro Cryptocurrency Trading (iOS) registration', 
				'eToro: Crypto. Stocks. Social. (iOS) registration', 
				'eToro - Invest in stocks, crypto & trade CFDs (Android) registration',
				'eToro: Investing made social (Android) registration',
				--adding options specific conversion names:
				'etoro_reg' 
				) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_Regs,
			SUM(CASE WHEN conversion_action_name IN ('V2 Status', 		'V2_app_iOS',
				'eToro: Crypto. Stocks. Social. (iOS) Verification Level - 2',
				'eToro: Stocks. Crypto. Social. (Android) Verification Level - 2',
				'eToro: Investing made social (Android) Verification Level - 2',
				'eToro: Investing made social (iOS) Verification Level - 2') THEN all_conversions-view_through_conversions ELSE 0 end) Platform_V2,
			SUM(CASE WHEN conversion_action_name IN (		'FTD',
				'eToro: Investing made social (Android) FTD', 
				'eToro - Invest in stocks, crypto & trade CFDs (Android) FTD', 
				'eToro Cryptocurrency Trading (iOS) FTD', 
				'eToro: Crypto. Stocks. Social. (iOS) FTD',
				--adding options specific conversion name:
				'etoro_ftd'
				) THEN all_conversions-view_through_conversions ELSE 0 end) Platform_FTD,
			CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END AS us_options_campaign_filter --main.status,main.campaign_status
		FROM [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.perf_adgroup_performance_report main	
		JOIN [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.conv_adgroup_performance_report cv ON main.id = cv.id AND main.date = cv.date AND main.device = cv.device--campaign id is not unique
		AND main.date BETWEEN '2023-01-01' AND '2023-04-30'
		WHERE 	 
			CASE WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
			END  IS NOT NULL
		GROUP BY EOMONTH(main.date),CASE 
			WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
			END, CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END 

	UNION ALL 

	SELECT  
 	 	 EOMONTH(ca.date) EoM_date,
		'Facebook' AS Channel,
		NULL AS Click_on_CTA,
		sum(CASE WHEN ca.action_type ='complete_registration'     THEN (ca.value) ELSE 0 END) AS Platform_Regs,
		0 AS Platform_V2,
		sum(CASE WHEN ca.action_type ='purchase'  THEN (ca.value) ELSE 0 END) AS Platform_FTD,
		 us_options_campaign_filter
	from [ThirdParty_Fivetran].[Fivetran].[facebook_cvr].[facebook_conversion_actions] ca 
	JOIN (
		SELECT DISTINCT pn.ad_id, pn.date,  CASE WHEN LOWER(ad_name) LIKE '%options%' THEN 'Y' ELSE 'N' END AS us_options_campaign_filter
		FROM 
			[ThirdParty_Fivetran].[Fivetran].[facebook].[facebook_preformance_new] pn 
		where (LOWER(pn.campaign_name) LIKE 'us_%' OR LOWER(pn.campaign_name) LIKE '%usa%' OR LOWER(ad_name) LIKE '%options%') AND pn.date >= '2023-01-01'
		--ORDER BY pn.date
	) us_ads ON us_ads.date=ca.date AND us_ads.ad_id=ca.ad_id
	group BY EOMONTH(ca.date),us_options_campaign_filter
	--ORDER BY  EOMONTH(ca.date) 
)tab2 

JOIN (	
	---- step 2: get imp, clicks, views, cost

		SELECT im_cl_co.EoM_date, im_cl_co.Channel, us_options_campaign_filter, ISNULL(impressions,0) Impressions, ISNULL(clicks,0) Clicks, ISNULL(Views_10s,0) Views_10s, ISNULL(cost,0) Cost 
		FROM (
			---get all google channels
			SELECT DISTINCT 			
				EOMONTH(main.date) EoM_date,
						case	 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
						 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
						 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND 
								LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
						 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
						 WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND 
								LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
						 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
					end as Channel,
				SUM(main.impressions) impressions,				
				SUM(main.clicks) clicks,				
				0 AS Views_10s,
				sum(main.cost_micros)/1000000 cost,
				CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END AS us_options_campaign_filter --main.status,main.campaign_status
			FROM [ThirdParty_Fivetran].[Fivetran].adwords_adgroup_perf_new_api.perf_adgroup_performance_report main	
			WHERE  main.date>='2023-01-01' AND 
				case	 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
						 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
						 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND 
								LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
						 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
						 WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND 
								LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
						 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
					end  IS NOT NULL
			GROUP BY EOMONTH(main.date), case	 WHEN  LOWER(main.campaign_name) LIKE 'us_brand_%' OR LOWER(main.campaign_name) LIKE 'us-opt_brand_%' THEN  'Google Brand' 
						 WHEN  LOWER(main.campaign_name) LIKE 'us_nb_%' OR LOWER(main.campaign_name) LIKE 'us-opt_nb_%' THEN  'Google Search' 
						 WHEN  (LOWER(main.campaign_name) LIKE 'us_yt_%' OR LOWER(main.campaign_name) LIKE 'us-opt_yt_%') AND 
								LOWER(main.campaign_name) NOT LIKE 'us_ytr_%' AND LOWER(main.campaign_name) NOT LIKE 'us-opt_ytr_%' THEN  'YouTube' 
						 WHEN  LOWER(main.campaign_name) LIKE 'us_ytr_%' OR LOWER(main.campaign_name) LIKE 'us-opt_ytr_%' THEN 'YTR'
						 WHEN  (LOWER(main.campaign_name) LIKE 'us_uac_%' OR LOWER(main.campaign_name) LIKE 'us-opt_uac_%')  AND 
								LOWER(main.campaign_name) NOT LIKE 'us_uac-r_%' and LOWER(main.campaign_name) NOT LIKE 'us-opt_uac-r%' THEN 'UAC'
						 WHEN  LOWER(main.campaign_name) LIKE  'us_uac-r_%' OR LOWER(main.campaign_name) LIKE  'us-opt_uac-r_%' THEN 'UAC-R' 
					end, CASE WHEN LOWER(main.campaign_name) LIKE 'us-opt_%' THEN 'Y' ELSE 'N' END 
			UNION ALL 
					---facebook
					SELECT DISTINCT EOMONTH(date) EoM_date, --ad_name, adset_name, campaign_name, campaign_id, ad_id, adset_id,
						'Facebook' AS Channel,
						sum(impressions) as Impressions,
						SUM(clicks) Clicks,
						0 AS Views_10s,
						SUM(spend) AS cost,
						CASE WHEN LOWER(ad_name) LIKE '%options%' THEN 'Y' ELSE 'N' END AS us_options_campaign_filter
					FROM [ThirdParty_Fivetran].[Fivetran].[facebook].[facebook_preformance_new] 
					WHERE date>='2023-01-01' AND 
					LOWER(campaign_name) LIKE 'us_%' OR LOWER(campaign_name) LIKE '%usa%' 
					OR LOWER(ad_name) LIKE '%options%' 
					GROUP BY EOMONTH(date)--, ad_name, adset_name, campaign_name, campaign_id, ad_id, adset_id
					,CASE WHEN LOWER(ad_name) LIKE '%options%' THEN 'Y' ELSE 'N' END 
		) im_cl_co
		--ORDER BY  im_cl_co.EoM_date, im_cl_co.Channel, us_options_campaign_filter
	)tab1 ON tab1.EoM_date=tab2.EoM_date AND tab1.Channel=tab2.Channel AND tab1.us_options_campaign_filter=tab2.us_options_campaign_filter
--ORDER BY tab1.EoM_date, tab1.Channel, tab1.us_options_campaign_filter