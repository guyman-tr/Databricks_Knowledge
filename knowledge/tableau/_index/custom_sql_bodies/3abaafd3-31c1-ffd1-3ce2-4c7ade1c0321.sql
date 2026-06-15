WITH cids AS (
    SELECT DISTINCT
          dc.RealCID
        , dc.GCID
        , op.OptionsApexID
        , am.AccountNumber
        , am.OfficeCode
        , CASE WHEN dc.CountryID NOT IN (219) THEN 'United States' ELSE c.Name END AS CountryName
        , CASE WHEN dc.CountryID NOT IN (219) THEN c.Name ELSE s.Name END AS StateName
        , r.Name AS DesignatedRegulation
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c ON c.CountryID = dc.CountryID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province s 
           ON s.CountryID = dc.CountryID AND s.RegionByIP_ID = dc.RegionID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r 
           ON r.ID = dc.DesignatedRegulationID
    LEFT JOIN main.general.bronze_usabroker_apex_options op  ON dc.GCID = op.GCID
    LEFT JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am 
           ON am.AccountNumber = op.OptionsApexID
    WHERE c.CountryID IN (219, 86, 153, 4, 214, 166)
      AND dc.IsValidCustomer = 1
      AND dc.PlayerStatusID NOT IN (2, 4)
      AND dc.PlayerLevelID not in (4)
      AND dc.PendingClosureStatusID not in (2,3)
      AND dc.RegisteredReal >= '2025-01-01'
),

-- --------------------------------------------------------
-- Remove duplicates: keep only distinct state transitions
-- --------------------------------------------------------
state_history AS (
    SELECT DISTINCT
          RealCID
        , StateShortName
        , FromDateID
        , ToDateID
        , StateName
    FROM main.bi_output_stg.bi_output_compliance_usa_map_cid_state_regulation_daily
),

-- --------------------------------------------------------
-- Order transitions and detect state changes only
-- --------------------------------------------------------
ordered AS (
    SELECT
          *,
          ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY ToDateID DESC) AS rn,
          LAG(StateShortName) OVER (PARTITION BY RealCID ORDER BY ToDateID DESC) AS NextState
    FROM state_history
),

-- Latest state row
latest AS (
    SELECT 
      RealCID, 
      StateShortName AS LatestState,
      FromDateID,
      StateName, 
      ToDateID
    FROM 
      ordered
    WHERE 
      rn = 1
),

-- Previous *different* state row
previous AS (
    SELECT 
      RealCID, 
      StateShortName AS PreviousState,
      StateName
    FROM 
      ordered
    WHERE 
      rn > 1 
      AND StateShortName <> NextState
    QUALIFY ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY ToDateID DESC) = 1
)

-- --------------------------------------------------------
-- Final Output
-- --------------------------------------------------------
SELECT
      c.RealCID
    , c.GCID
    , c.AccountNumber
    , c.OfficeCode
    , c.DesignatedRegulation
    , CASE 
          WHEN c.StateName IS NULL THEN 'NULL State'
          WHEN c.StateName = 'New York' THEN 'NYDFS or FINRA'
          WHEN c.StateName IN ('Puerto Rico','Nevada', 'Hawaii', 'US Virgin Islands') THEN 'FINRAONLY'
          ELSE 'FinCEN+FINRA'
      END AS RegulationBasedOnState
    , c.CountryName
    , c.StateName AS CurrentState
    , to_date(CAST(l.FromDateID AS STRING), 'yyyyMMdd') AS StateChanged
    , p.statename AS PreviousState
FROM cids c
LEFT JOIN latest l   ON c.RealCID = l.RealCID
LEFT JOIN previous p ON c.RealCID = p.RealCID
WHERE 
  c.statename is not null
--WHERE c.RealCID = 7978033;