WITH pop AS (
  SELECT
      a.GCID,
      a.CID,
      a.PlayerStatusID AS Current_ID,
      dps.Name AS Current_PlayerStatus,
      a.Previous_PlayerStatusID AS Previous_ID,
      pps.Name AS Previous_PlayerStatus,
      a.Change_Date,
      a.Is_FTD,
      a.Current_PlayerStatusReasonID,
      a.Current_PlayerStatusSubReasonID,
      ROW_NUMBER() OVER (
          PARTITION BY a.CID
          ORDER BY a.Change_Date DESC
      ) AS RowNum
  FROM (
      SELECT
          fsc.RealCID AS CID,
          fsc.GCID,
          fsc.PlayerStatusReasonID AS Current_PlayerStatusReasonID,
          fsc.PlayerStatusSubReasonID AS Current_PlayerStatusSubReasonID,
          CASE WHEN fsc.IsDepositor = 1 THEN 1 ELSE 0 END AS Is_FTD,
          fsc.PlayerStatusID,
          TO_TIMESTAMP(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date,
          LAG(fsc.PlayerStatusID, 1, 0) OVER (
              PARTITION BY fsc.RealCID
              ORDER BY dr.FromDateID ASC
          ) AS Previous_PlayerStatusID
      FROM dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON fsc.DateRangeID = dr.DateRangeID
      WHERE fsc.IsValidCustomer = 1
  ) a
  INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps
      ON a.PlayerStatusID = dps.PlayerStatusID
  INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pps
      ON a.Previous_PlayerStatusID = pps.PlayerStatusID
  WHERE a.PlayerStatusID <> a.Previous_PlayerStatusID
    AND a.PlayerStatusID NOT IN (0,1)
    AND a.Change_Date >= ADD_MONTHS(CURRENT_TIMESTAMP(), -6)
),

ranked_emails AS (
  SELECT
      ParentId AS CaseID,
      CID__c AS CID,
      CreatedDate AS Email_Date,
      TextBody,
      ROW_NUMBER() OVER (
          PARTITION BY ParentID
          ORDER BY CreatedDate ASC
      ) AS rn
  FROM crm.silver_crm_emailmessage
  WHERE YEAR(CreatedDate) = 2025
    AND Incoming = 'false'
),

first_email AS (
  SELECT
      CaseID,
      CID,
      Email_Date,
      TextBody
  FROM ranked_emails
  WHERE rn = 1
),

main AS (
  SELECT
      p.CID,
      p.GCID,
      p.Previous_PlayerStatus,
      CAST(p.Change_Date AS DATE) AS LimitedDate,
      p.Change_Date AS LimitedDateTime,
      MONTH(p.Change_Date) AS MonthLimited,
      p.Current_ID AS PlayerStatusIDLimitation,
      p.Current_PlayerStatus AS PlayerStatusLimitation,

      -- NEW: Correct event reason/subreason
      psr.Name AS PlayerStatusLimitationReason,
      pssr.PlayerStatusSubReasonName AS PlayerStatusLimitationSubReason,

      ps.Name AS Current_PlayerStatus,  -- current from customer table
      psr2.Name AS Current_PlayerStatusReason,
      pssr2.PlayerStatusSubReasonName AS Current_PlayerStatusSubReason,

      pl.Name AS PlayerLevel,
      r.Name AS Regulation,
      c.VerificationLevelID,
      pcs.PendingClosureStatusName AS PendingClosureStatus,
      fe.Email_Date,
      fe.TextBody,
      cou.Name AS Country
  FROM pop p
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
      ON c.RealCID = p.CID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps
      ON ps.PlayerStatusID = c.PlayerStatusID

  -- Correct limitation reason join
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
      ON psr.PlayerStatusReasonID = p.Current_PlayerStatusReasonID

  -- Correct limitation subreason join
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
      ON pssr.PlayerStatusSubReasonID = p.Current_PlayerStatusSubReasonID

  -- Current customer reason/subreason (unchanged)
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr2
      ON psr2.PlayerStatusReasonID = c.PlayerStatusReasonID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr2
      ON pssr2.PlayerStatusSubReasonID = c.PlayerStatusSubReasonID

  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country cou
      ON c.CountryID = cou.CountryID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
      ON c.PlayerLevelID = pl.PlayerLevelID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r
      ON r.ID = c.RegulationID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus pcs
      ON pcs.PendingClosureStatusID = c.PendingClosureStatusID

  LEFT JOIN main.bi_output.bi_output_customer_customer_support_case cs
      ON cs.CID = c.RealCID
     AND cs.CreatedDate BETWEEN date_add(CAST(p.Change_Date AS DATE), -1)
                            AND date_add(CAST(p.Change_Date AS DATE), 1)
     AND cs.Origin = 'Manually'

  LEFT JOIN first_email fe
      ON fe.CID = p.CID
     AND fe.CaseID = cs.CaseId
),

audit AS (
  SELECT
      BAAC.GCID,
      BAAC.ActionTime,
      BMAN.FirstName || ' ' || BMAN.LastName AS ManagerName,
      DAAT.AuditActionTypeName,
      BAAC.AuditActionParameters
  FROM main.general.bronze_db_logs_backoffice_auditaction BAAC
  LEFT JOIN main.general.bronze_etoro_dictionary_auditactiontype DAAT
      ON BAAC.AuditActionTypeID = DAAT.AuditActionTypeID
     AND DAAT.AuditActionTypeName = 'ChangePlayerStatus'
  LEFT JOIN main.billing.bronze_etoro_backoffice_manager BMAN
      ON BAAC.ManagerID = BMAN.ManagerID
)

SELECT DISTINCT
    m.*,
    a.ManagerName,
    a.ActionTime,
    a.AuditActionParameters
FROM main m
LEFT JOIN audit a
  ON m.GCID = a.GCID
 AND cast(a.ActionTime as date)=  
        cast(m.LimitedDateTime as date)
 AND CAST(regexp_extract(a.AuditActionParameters,
          '<PlayerStatus>(\\d+)</PlayerStatus>', 1) AS INT)
        = m.PlayerStatusIDLimitation
WHERE m.Email_Date IS NULL
  AND m.PlayerStatusLimitation <> 'Blocked'