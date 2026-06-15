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
      CAST(cfd.VerificationLevel3Date AS DATE) AS VerificationLevel3Date,
      CAST(dc.FirstDepositDate AS DATE)        AS MSB_FTDDate,
      case when dc.RegulationID in (7,8,14) then 'majority regulation'
            when dc.RegulationID=12 then '3.0 regulation'
            when dc.RegulationID=6 then
                case when dc.designatedregulationid =12 then '3.0 regulation' 
                     when dc.DesignatedRegulationID in (7,8,14) then 'majority regulation'
                    end
        end as regulation_split,
      dc.IsValidCustomer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfd 
    ON dc.RealCID = cfd.CID 
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
    ON dc.RegulationID = dr.ID --and dr.RegulationID in (6,7,8,12)
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr2 
    ON dc.DesignatedRegulationID = dr2.ID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 
    ON dc.CountryID = dc1.CountryID 
    --AND dc1.MarketingRegionManualName = 'USA'  
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
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province dsap
    ON dc.CountryID = 219  
    AND dc.RegionID = dsap.RegionByIP_ID  
  where 
       ( case when dc.RegulationID in (7,8,14) then 'majority regulation'
            when dc.RegulationID=12 then '3.0 regulation'
            when dc.RegulationID=6 then
                case when dc.designatedregulationid =12 then '3.0 regulation' 
                     when dc.DesignatedRegulationID in (7,8,14) then 'majority regulation'
                    end
        end ) is not null
  /*(dc.RegulationID in (7,8,12)) 
    or (dc.RegulationID =6 and dc.DesignatedRegulationID in (7,8,12) )
*/
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
  GROUP BY 
      p.regulation_split,
      p.MarketingRegionManualName,
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
      p.MSB_FTDDate,
      p.IsValidCustomer,
      am.OpenDDate,
      am.AccountNumber
),

apex_4gs_fa AS (
  SELECT af.*, 
      MIN(CAST(dp.OpenOccurred AS DATE)) AS MSB_FirstTradeDate,
      MIN(tr.ProcessDate)             AS Options_FirstTradeDate,
      LEAST(MIN(CAST(dp.OpenOccurred AS DATE)), MIN(tr.ProcessDate)) AS Cross_FirstTradeDate
  FROM apex_4gs_ftd af
  LEFT JOIN dwh.dim_position dp 
    ON af.RealCID = dp.CID 
       AND COALESCE(dp.IsAirDrop, 0) != 1
  LEFT JOIN main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr 
    ON tr.AccountNumber = af.Apex_4gs_AccountNumber 
  GROUP BY 
      af.regulation_split,
      af.MarketingRegionManualName,
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
      af.MSB_FTDDate,
      af.IsValidCustomer,
      af.Apex_4gs_OpenDate,
      af.Apex_4gs_AccountNumber,
      Apex_FTDDate
),

base AS (
    SELECT f.*,
          am1.OpenDDate AS Apex_3e_OpenDate,
      case 
	  	  when f.StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                  when f.StateShortName is null then 'Null State'
	  		else 'Majority States' 
		  end as State_group
    FROM apex_4gs_fa f
    LEFT JOIN main.finance.bronze_usabroker_apex_apexdata ap 
        ON ap.GCID = f.GCID
    LEFT JOIN (
                SELECT AccountNumber, OpenDDate 
                FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster 
                GROUP BY AccountNumber, OpenDDate
              ) am1
        ON am1.AccountNumber = ap.ApexID
)

-- Now unpivot the 11 date fields using UNION ALL instead of LATERAL VIEW
SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'Reg' AS EventType,
  Reg AS EventDate
FROM base
WHERE Reg IS NOT NULL AND Reg >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'V1' AS EventType,
  VerificationLevel1Date AS EventDate
FROM base
WHERE VerificationLevel1Date IS NOT NULL AND VerificationLevel1Date >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'V2' AS EventType,
  VerificationLevel2Date AS EventDate
FROM base
WHERE VerificationLevel2Date IS NOT NULL AND VerificationLevel2Date >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'V3' AS EventType,
  VerificationLevel3Date AS EventDate
FROM base
WHERE VerificationLevel3Date IS NOT NULL AND VerificationLevel3Date >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'Equity Acct Open' AS EventType,
  Apex_3e_OpenDate AS EventDate
FROM base
WHERE Apex_3e_OpenDate IS NOT NULL AND Apex_3e_OpenDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'Options Acct Open' AS EventType,
  Apex_4gs_OpenDate AS EventDate
FROM base
WHERE Apex_4gs_OpenDate IS NOT NULL AND Apex_4gs_OpenDate >= '2024-10-01'
UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'Apex Acct Open' AS EventType,
  Apex_4gs_OpenDate AS EventDate
FROM base
WHERE Apex_4gs_OpenDate IS NOT NULL AND Apex_4gs_OpenDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'MSB FTD' AS EventType,
  MSB_FTDDate AS EventDate
FROM base
WHERE MSB_FTDDate IS NOT NULL AND MSB_FTDDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'First Trade, wo Options' AS EventType,
  MSB_FirstTradeDate AS EventDate
FROM base
WHERE MSB_FirstTradeDate IS NOT NULL AND MSB_FirstTradeDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'Apex FTD' AS EventType,
  Apex_FTDDate AS EventDate
FROM base
WHERE Apex_FTDDate IS NOT NULL AND Apex_FTDDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'First Trade, Options' AS EventType,
  Options_FirstTradeDate AS EventDate
FROM base
WHERE Options_FirstTradeDate IS NOT NULL AND Options_FirstTradeDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'First Trade Cross' AS EventType,
  Cross_FirstTradeDate AS EventDate
FROM base
WHERE Cross_FirstTradeDate IS NOT NULL AND Cross_FirstTradeDate >= '2024-10-01'

UNION ALL

SELECT
  regulation_split,
  MarketingRegionManualName,
  CountryID,
  Regulation,
  DesignatedRegulation,
  State_group,
  RealCID,
  IsValidCustomer,
  'First Trade, Apex' AS EventType,
  Options_FirstTradeDate AS EventDate
FROM base
WHERE Options_FirstTradeDate IS NOT NULL AND Options_FirstTradeDate >= '2024-10-01'