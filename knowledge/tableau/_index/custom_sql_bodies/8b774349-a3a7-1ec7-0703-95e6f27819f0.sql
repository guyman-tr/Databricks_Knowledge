-- events

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
      CAST(dc.FirstDepositDate AS DATE)        AS MSB_FTDDate
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
  WHERE 
		dc.IsValidCustomer=1 and (
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
      p.MSB_FTDDate,
      am.OpenDDate,
      am.AccountNumber
),

base AS (
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
      af.MSB_FTDDate,
      af.Apex_4gs_OpenDate,
      af.Apex_4gs_AccountNumber,
      Apex_FTDDate
)
-- Now unpivot the 11 date fields using UNION ALL instead of LATERAL VIEW
SELECT
  Regulation,
  DesignatedRegulation,
  EventDate AS Date,
  SUM(CASE WHEN EventType = 'Reg' THEN EventCount ELSE 0 END) AS Reg,
  SUM(CASE WHEN EventType = 'V1' THEN EventCount ELSE 0 END) AS V1,
  SUM(CASE WHEN EventType = 'V2' THEN EventCount ELSE 0 END) AS V2,
  SUM(CASE WHEN EventType = 'V3' THEN EventCount ELSE 0 END) AS V3,
  SUM(CASE WHEN EventType = 'Apex Acct Open' THEN EventCount ELSE 0 END) AS new_equities_accounts,
  SUM(CASE WHEN EventType = 'Apex FTD' THEN EventCount ELSE 0 END) AS first_funded_accounts,
  SUM(CASE WHEN EventType = 'First Trade, Apex' THEN EventCount ELSE 0 END) AS first_traded_accounts,
  State_group
from 
(
   SELECT
        Regulation,
        DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
        COUNT(DISTINCT GCID) AS EventCount,
        'Reg' AS EventType,
        Reg AS EventDate
    FROM base
    WHERE Reg IS NOT NULL AND Reg >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end, 
            Reg

    UNION ALL

    SELECT
    Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
    COUNT(DISTINCT GCID) AS EventCount,
    'V1' AS EventType,
    VerificationLevel1Date AS EventDate
    FROM base
    WHERE VerificationLevel1Date IS NOT NULL AND VerificationLevel1Date >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end,
            VerificationLevel1Date
    UNION ALL

    SELECT
    Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
    COUNT(DISTINCT GCID) AS EventCount,
    'V2' AS EventType,
    VerificationLevel2Date AS EventDate
    FROM base
    WHERE VerificationLevel2Date IS NOT NULL AND VerificationLevel2Date >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end,
            VerificationLevel2Date

    UNION ALL

    SELECT
    Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
    COUNT(DISTINCT GCID) AS EventCount,
    'V3' AS EventType,
    VerificationLevel3Date AS EventDate
    FROM base
    WHERE VerificationLevel3Date IS NOT NULL AND VerificationLevel3Date >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end, 
            VerificationLevel3Date

    UNION ALL

    SELECT
    Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
    COUNT(DISTINCT GCID) AS EventCount,
    'Apex Acct Open' AS EventType,
    Apex_4gs_OpenDate AS EventDate
    FROM base
    WHERE Apex_4gs_OpenDate IS NOT NULL AND Apex_4gs_OpenDate >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end, 
        Apex_4gs_OpenDate

    UNION ALL

    SELECT
    Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
    COUNT(DISTINCT GCID) AS EventCount,
    'Apex FTD' AS EventType,
    Apex_FTDDate AS EventDate
    FROM base
    WHERE Apex_FTDDate IS NOT NULL AND Apex_FTDDate >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end, 
            Apex_FTDDate

    UNION ALL

    SELECT
    Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end as State_group,
    COUNT(DISTINCT GCID) AS EventCount,
    'First Trade, Apex' AS EventType,
    Options_FirstTradeDate AS EventDate
    FROM base
    WHERE Options_FirstTradeDate IS NOT NULL AND Options_FirstTradeDate >= '2024-11-10'
    group by   Regulation,
    DesignatedRegulation,
            case 
            when StateShortName IN ('NY','NV','HI','PR','VI') then '3.0 States'
                    when StateShortName is null then 'Null State'
                else 'Majority States' 
            end, 
            Options_FirstTradeDate
)tab 
GROUP BY Regulation, DesignatedRegulation, EventDate, State_group