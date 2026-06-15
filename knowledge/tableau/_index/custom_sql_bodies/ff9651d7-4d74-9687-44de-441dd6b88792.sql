-- cohort
WITH pop AS (
  SELECT   
      dc1.MarketingRegionManualName,
      dc.CountryID,
      dr.Name AS Regulation,
      dr2.Name AS DesignatedRegulation,
      COALESCE(dc2.AdjStateShortName, dsap.ShortName) AS StateShortName, 
      COALESCE(dc2.AdjStateName, dsap.Name)           AS StateName,
      dc.RealCID,
      dc.GCID,
      CAST(cfd.Registered AS DATE)             AS Reg, 
      CAST(cfd.VerificationLevel1Date AS DATE) AS VerificationLevel1Date, 
      CAST(cfd.VerificationLevel2Date AS DATE) AS VerificationLevel2Date, 
      CAST(cfd.VerificationLevel3Date AS DATE) AS VerificationLevel3Date
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfd 
    ON dc.RealCID = cfd.CID 
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 
    ON dc.CountryID = dc1.CountryID 
    AND dc1.MarketingRegionManualName = 'USA'  
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
    ON dc.RegulationID = dr.ID --and dr.RegulationID in (6,7,8,12)
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr2 
    ON dc.DesignatedRegulationID = dr2.ID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province dsap
    ON dc.CountryID = 219  
    AND dc.RegionID = dsap.RegionByIP_ID  
  LEFT JOIN (
        SELECT 
          dc.CountryID,
          CASE 
            WHEN dc.CountryID = 219 THEN NULL  
            WHEN dc.CountryID IN (86, 153, 4, 214, 166) THEN dc.Name
          END AS AdjStateName,
          CASE 
            WHEN dc.CountryID = 219 THEN NULL  
            WHEN dc.CountryID IN (86, 153, 4, 214, 166) THEN dc.Abbreviation
          END AS AdjStateShortName
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc 
        WHERE dc.MarketingRegionManualName = 'USA'  
          OR dc.CountryID IN (86, 153, 4, 214, 166)
    ) dc2
    ON dc.CountryID = dc2.CountryID 
	WHERE dc.IsValidCustomer=1 and (
	  	(dc.RegulationID = 6 AND dc.DesignatedRegulationID = 12) OR dc.RegulationID = 12
  )
),

apex_4gs_ftd AS (
  SELECT   
      p.*,
      am.OpenDDate         AS Apex_4gs_OpenDate,
      am.AccountNumber     AS Apex_4gs_AccountNumber,
      MIN(ca.ProcessDate)  AS Apex_FTDDate
  FROM pop p
  LEFT JOIN main.general.bronze_usabroker_apex_options op 
    ON op.GCID = p.GCID
  LEFT JOIN (
              SELECT AccountNumber, OpenDDate
              FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster 
              GROUP BY AccountNumber, OpenDDate
            ) am 
    ON op.OptionsApexID = am.AccountNumber
  LEFT JOIN main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca 
    ON ca.AccountNumber = am.AccountNumber 
       AND ca.PayTypeCode = 'C' 
       AND (EnteredBy IN ('ACH','WRD') OR TerminalID = 'OMJNL')
  --WHERE p.StateShortName NOT IN ('NY','NV','HI','PR','VI')
  GROUP BY p.MarketingRegionManualName,
      p.CountryID,
      p.Regulation,
      p.DesignatedRegulation,
      p.StateShortName, 
      p.StateName,
      p.RealCID, 
      p.GCID,
      p.Reg, 
      p.VerificationLevel1Date, 
      p.VerificationLevel2Date, 
      p.VerificationLevel3Date,
      am.OpenDDate,
      am.AccountNumber
),

apex_4gs_fa AS (
  SELECT af.*, 
      MIN(tr.ProcessDate)             AS Options_FirstTradeDate
  FROM apex_4gs_ftd af
  LEFT JOIN main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr 
    ON tr.AccountNumber = af.Apex_4gs_AccountNumber 
  GROUP BY af.MarketingRegionManualName,
      af.CountryID,
      af.Regulation,
      af.DesignatedRegulation,
      af.StateShortName, 
      af.StateName,
      af.RealCID, 
      af.GCID,
      af.Reg, 
      af.VerificationLevel1Date, 
      af.VerificationLevel2Date, 
      af.VerificationLevel3Date,
      af.Apex_4gs_OpenDate,
      af.Apex_4gs_AccountNumber,
      Apex_FTDDate
)
    SELECT 

      f.Regulation,
      f.DesignatedRegulation,
      f.Reg as Date,
      COUNT(DISTINCT case when f.Reg is not null then GCID END) Reg, 
      COUNT(DISTINCT case when f.VerificationLevel1Date is not null then GCID END) V1, 
      COUNT(DISTINCT case when f.VerificationLevel2Date is not null then GCID END) V2, 
      COUNT(DISTINCT case when f.VerificationLevel3Date is not null then GCID END) V3,     
      COUNT(DISTINCT case when f.Apex_4gs_OpenDate is not null then GCID END) new_equities_accounts,     
      COUNT(DISTINCT case when f.Apex_FTDDate is not null then GCID END) first_funded_accounts,     
      COUNT(DISTINCT case when f.options_FirstTradeDate is not null then GCID END) first_traded_accounts,     
      case 
	  	  when f.StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                  when f.StateShortName is null then 'Null State'
	  		else 'Majority States' 
		  end as State_group
    FROM apex_4gs_fa f
    where f.Reg>='2024-11-10'
    GROUP BY f.Regulation,
      f.DesignatedRegulation,
      f.Reg,
       case 
	  	  when f.StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                  when f.StateShortName is null then 'Null State'
	  		else 'Majority States' 
		  end