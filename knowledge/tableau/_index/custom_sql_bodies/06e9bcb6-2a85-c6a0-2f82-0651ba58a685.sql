SELECT
  tc.ProfessionalApplicationDate,
  t.CID,
  dr.Name AS Regulation,
  dc.Name AS Country,
  CONCAT(COALESCE(dm.FirstName, ''), ' ', COALESCE(dm.LastName, '')) AS AccountManager,
  dpl.Name AS Club,
  mc.Name AS MifidCategorization,
  CASE
    WHEN dr.Name = 'FCA' AND 
         DATEDIFF(current_date(), tc.VerificationLevel3Date) > 266 AND
         y.UnrealizedEquity * cr.EURMidRate > 500000 AND 
         t.Sig_Pos > 40 AND 
         y.Relevant_Loss_percentage < 0.2 
      THEN 'FCA Eligible'
    WHEN dr.Name = 'CySEC' AND 
         DATEDIFF(current_date(), tc.VerificationLevel3Date) > 266 AND
         y.UnrealizedEquity * cr.EURMidRate > 500000 AND 
         t.Sig_Pos > 40 AND 
         y.Relevant_Loss_percentage < 0.2 
      THEN 'CySEC Eligible'
    WHEN dr.Name = 'FSRA' AND 
         DATEDIFF(current_date(), tc.VerificationLevel3Date) > 266 AND
         y.UnrealizedEquity > 1000000 AND 
         t.Sig_Pos > 40 AND 
         y.Relevant_Loss_percentage < 0.2 
      THEN 'FSRA Eligible'
    ELSE 'Not eligible'
  END AS Professional_eligible,
  CASE
    WHEN dr.Name IN ('FCA', 'CySEC', 'FSRA') THEN
      CONCAT(
        CASE WHEN DATEDIFF(current_date(), tc.VerificationLevel3Date) <= 266 THEN 'Not enough days since VerificationLevel3; ' ELSE '' END,
        CASE WHEN y.UnrealizedEquity * cr.EURMidRate <= 500000 AND dr.Name IN ('FCA', 'CySEC') THEN 'Equity; ' ELSE '' END,
        CASE WHEN y.UnrealizedEquity <= 1000000 AND dr.Name = 'FSRA' THEN 'Equity; ' ELSE '' END,
        CASE WHEN t.Sig_Pos <= 40 THEN 'Not enough qualifying trades; ' ELSE '' END,
        CASE WHEN y.Relevant_Loss_percentage >= 0.2 THEN 'Loss percentage too high; ' ELSE '' END
      )
    ELSE 'No professional program in this region'
  END AS Criteria_not_met,
  CASE 
    WHEN d.FirstDocAfterApplication >= tc.ProfessionalApplicationDate THEN 'Yes'
    ELSE 'No'
  END AS Sent_Documents_After_Application,
  t.Sig_Pos AS Number_of_qualifying_trades,
  y.UnrealizedEquity AS Equity,
  y.Relevant_Loss_percentage,
  k.KYC_Occupation AS Occupation,
  tc.VerificationLevel3Date
FROM --TradesGrouped 
(
  SELECT
    t.CID,
    SUM(
      CASE 
        WHEN InstrumentTypeID = 1 AND Volume >= 50000 THEN 1
        WHEN InstrumentTypeID IN (2,4) AND Volume >= 25000 THEN 1
        WHEN InstrumentTypeID = 10 AND Volume >= 2000 THEN 1
        WHEN InstrumentTypeID IN (5,6) AND Volume >= 10000 THEN 1
        ELSE 0
      END
    ) AS Sig_Pos
--Trade start
  FROM   
  (SELECT
    y.CID,
    COALESCE(dp.Volume,0) as Volume,
    di.InstrumentTypeID
  FROM main.dwh.dim_position dp
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di ON dp.InstrumentID = di.InstrumentID
  RIGHT JOIN --Yearly start
  (  SELECT
    e.CID,
    e.UnrealizedEquity,
    m.MaxUnrealizedEquityPastYear,
    CASE 
      WHEN m.MaxUnrealizedEquityPastYear = 0 THEN NULL 
      ELSE 1 - e.UnrealizedEquity / m.MaxUnrealizedEquityPastYear 
    END AS Relevant_Loss_percentage
    --Equity Inside Yearly Inside Trade inside tradegroup start
  FROM 
  (  SELECT
    vl.CID,
    vl.RealizedEquity + COALESCE(vl.PositionPnL,0) AS UnrealizedEquity
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
  JOIN 
  --SnapshotCusomerStart
   (  SELECT DISTINCT
    dc.CID,
    dc.RegulationID,
    dc1.CountryID,
    dc1.AccountManagerID,
    dc1.PlayerLevelID,
    dc1.MifidCategorizationID
  FROM main.general.bronze_etoro_backoffice_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1 
    ON dc.CID = dc1.RealCID
  JOIN 
  --TargetCIDs start
  (  SELECT 
    CID, 
    ProfessionalApplicationDate,
    VerificationLevel3Date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
  WHERE ProfessionalApplicationDate IS NOT NULL) tc -- targetCID End

   ON tc.CID = dc.CID
  WHERE dc1.IsValidCustomer = 1
    AND dc1.MifidCategorizationID = 5  -- Only Pending
    AND (dc.MifidCategorizationID NOT IN (2,3)
         AND NOT (dc.RegulationID = 9 AND dc.SeychellesCategorizationID = 2))) sc 
  --SnapshotCusomerEnd
  ON vl.CID = sc.CID
  WHERE vl.DateID = CAST(date_format(current_date() - 1, 'yyyyMMdd') AS INT)) e --Equity Inside Yearly Inside Trade inside tradegroup END
  JOIN 
  --MaxEquity Start
  (  SELECT
    vl.CID,
    MAX(COALESCE(vl.RealizedEquity, 0) + COALESCE(vl.PositionPnL, 0)) AS MaxUnrealizedEquityPastYear
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
  JOIN 
  --Equity Inside MaxEquity Start
  (  SELECT
    vl.CID,
    vl.RealizedEquity + COALESCE(vl.PositionPnL,0) AS UnrealizedEquity
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
  JOIN 
  --SnapshotCustomerStart
  (  SELECT DISTINCT
    dc.CID,
    dc.RegulationID,
    dc1.CountryID,
    dc1.AccountManagerID,
    dc1.PlayerLevelID,
    dc1.MifidCategorizationID
  FROM main.general.bronze_etoro_backoffice_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1 
    ON dc.CID = dc1.RealCID
  JOIN 
  --TargetCIDs start
  (  SELECT 
    CID, 
    ProfessionalApplicationDate,
    VerificationLevel3Date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
  WHERE ProfessionalApplicationDate IS NOT NULL) tc -- targetCID End

   ON tc.CID = dc.CID
  WHERE dc1.IsValidCustomer = 1
    AND dc1.MifidCategorizationID = 5  -- Only Pending
    AND (dc.MifidCategorizationID NOT IN (2,3)
         AND NOT (dc.RegulationID = 9 AND dc.SeychellesCategorizationID = 2))) sc 
  --SnapshotCustomer End
  ON vl.CID = sc.CID
  WHERE vl.DateID = CAST(date_format(current_date() - 1, 'yyyyMMdd') AS INT)) e --Equity inside MaxEquity END

  ON vl.CID = e.CID
  WHERE TIMESTAMPDIFF(DAY, vl.etr_ymd, DATE_SUB(CURRENT_DATE(), 1)) <= 365
  GROUP BY vl.CID) m 
  --max equity inside Yearly inside Trade inside Tradegroup END
  ON e.CID = m.CID) y --Yearly inside trade inside tradegroup END
  ON dp.CID = y.CID and dp.MirrorID = 0 and dp.IsSettled = 0 and dp.IsAirDrop IS NULL AND dp.OpenOccurred BETWEEN DATE_SUB(CURRENT_DATE() - 1, 270) AND CURRENT_DATE() - 1) as t
  --LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di ON dp.InstrumentID = di.InstrumentID
  --WHERE dp.MirrorID = 0 AND dp.IsSettled = 0 AND dp.IsAirDrop IS NULL
   -- AND dp.OpenOccurred BETWEEN DATE_SUB(CURRENT_DATE() - 1, 270) AND CURRENT_DATE() - 1) t -- end of trade inside tradegroup

  GROUP BY t.CID ) t --end of tradeGroups

JOIN 
--Yearly Start
(  SELECT
    e.CID,
    e.UnrealizedEquity,
    m.MaxUnrealizedEquityPastYear,
    CASE 
      WHEN m.MaxUnrealizedEquityPastYear = 0 THEN NULL 
      ELSE 1 - e.UnrealizedEquity / m.MaxUnrealizedEquityPastYear 
    END AS Relevant_Loss_percentage
  FROM 
  --Equity Start
  (  SELECT
    vl.CID,
    vl.RealizedEquity + COALESCE(vl.PositionPnL,0) AS UnrealizedEquity
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
  JOIN 
  --snapshotcusomerstart
    (  SELECT DISTINCT
    dc.CID,
    dc.RegulationID,
    dc1.CountryID,
    dc1.AccountManagerID,
    dc1.PlayerLevelID,
    dc1.MifidCategorizationID
  FROM main.general.bronze_etoro_backoffice_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1 
    ON dc.CID = dc1.RealCID
  JOIN 
  --TargetCIDs start
  (  SELECT 
    CID, 
    ProfessionalApplicationDate,
    VerificationLevel3Date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
  WHERE ProfessionalApplicationDate IS NOT NULL) tc -- targetCID End

   ON tc.CID = dc.CID
  WHERE dc1.IsValidCustomer = 1
    AND dc1.MifidCategorizationID = 5  -- Only Pending
    AND (dc.MifidCategorizationID NOT IN (2,3)
         AND NOT (dc.RegulationID = 9 AND dc.SeychellesCategorizationID = 2))) sc 
  --snapshotcusomer end
  ON vl.CID = sc.CID
  WHERE vl.DateID = CAST(date_format(current_date() - 1, 'yyyyMMdd') AS INT)) e --Equity End

  JOIN 
  --Max Equity Start
  (  SELECT
    vl.CID,
    MAX(COALESCE(vl.RealizedEquity, 0) + COALESCE(vl.PositionPnL, 0)) AS MaxUnrealizedEquityPastYear
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
  JOIN 
  --Equity Start
  (  SELECT
    vl.CID,
    vl.RealizedEquity + COALESCE(vl.PositionPnL,0) AS UnrealizedEquity
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
  JOIN 
  --snapshotcusomerstart
   (  SELECT DISTINCT
    dc.CID,
    dc.RegulationID,
    dc1.CountryID,
    dc1.AccountManagerID,
    dc1.PlayerLevelID,
    dc1.MifidCategorizationID
  FROM main.general.bronze_etoro_backoffice_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1 
    ON dc.CID = dc1.RealCID
  JOIN 
  --TargetCIDs start
  (  SELECT 
    CID, 
    ProfessionalApplicationDate,
    VerificationLevel3Date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
  WHERE ProfessionalApplicationDate IS NOT NULL) tc -- targetCID End

   ON tc.CID = dc.CID
  WHERE dc1.IsValidCustomer = 1
    AND dc1.MifidCategorizationID = 5  -- Only Pending
    AND (dc.MifidCategorizationID NOT IN (2,3)
         AND NOT (dc.RegulationID = 9 AND dc.SeychellesCategorizationID = 2))) sc 
  --snapshotcustomerend 
  ON vl.CID = sc.CID
  WHERE vl.DateID = CAST(date_format(current_date() - 1, 'yyyyMMdd') AS INT)) e -- Equity End
    ON vl.CID = e.CID
  WHERE TIMESTAMPDIFF(DAY, vl.etr_ymd, DATE_SUB(CURRENT_DATE(), 1)) <= 365
  GROUP BY vl.CID) m
  --Max Equity End
   ON e.CID = m.CID) y -- Yearly End
   ON t.CID = y.CID
JOIN 
--SnapshotCusomer Start
(  SELECT DISTINCT
    dc.CID,
    dc.RegulationID,
    dc1.CountryID,
    dc1.AccountManagerID,
    dc1.PlayerLevelID,
    dc1.MifidCategorizationID
  FROM main.general.bronze_etoro_backoffice_customer dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1 
    ON dc.CID = dc1.RealCID
  JOIN 
  --TargetCIDs start
  (  SELECT 
    CID, 
    ProfessionalApplicationDate,
    VerificationLevel3Date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
  WHERE ProfessionalApplicationDate IS NOT NULL) tc -- targetCID End

   ON tc.CID = dc.CID
  WHERE dc1.IsValidCustomer = 1
    AND dc1.MifidCategorizationID = 5  -- Only Pending
    AND (dc.MifidCategorizationID NOT IN (2,3)
         AND NOT (dc.RegulationID = 9 AND dc.SeychellesCategorizationID = 2))) sc 
         --SnapshotCustomer End
         ON t.CID = sc.CID
JOIN 
--TragetCID Start
( SELECT 
    CID, 
    ProfessionalApplicationDate,
    VerificationLevel3Date
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
  WHERE ProfessionalApplicationDate IS NOT NULL) tc 
  --TargetCID END
  ON t.CID = tc.CID
LEFT JOIN 
--Documents Start
( SELECT
    CID,
    MIN(DateAdded) AS FirstDocAfterApplication
  FROM main.billing.bronze_etoro_backoffice_customerdocument
  GROUP BY CID) d
  --Documents End
   ON t.CID = d.CID
LEFT JOIN 
--KYS start
(SELECT
    GCID AS CID,
    Q18_AnswerText AS KYC_Occupation
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel) k
  --KYC END
   ON k.CID = t.CID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc ON sc.CountryID = dc.CountryID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr ON sc.RegulationID = dr.ID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl ON sc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm ON dm.ManagerID = sc.AccountManagerID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization mc ON sc.MifidCategorizationID = mc.MifidCategorizationID
CROSS JOIN 
--Conversionratestart
  (SELECT 1 / ((p1.Bid + p1.Ask) / 2) AS EURMidRate
  FROM main.dealing.bronze_pricelog_history_currencyprice p1
  WHERE p1.InstrumentID = 1
    AND p1.etr_ymd = current_date() - 1
    AND p1.Occurred = (
      SELECT MAX(Occurred)
      FROM main.dealing.bronze_pricelog_history_currencyprice
      WHERE InstrumentID = 1
        AND etr_ymd = current_date() - 1
    )) cr
--conversionrateend
WHERE dr.ID IN (1,2)