WITH constants AS (
  SELECT CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT) AS date_id
),

/*====================================================
  STEP 1 – Aggregate validation errors
====================================================*/
errors AS (
  SELECT
      ue.GCID
    , STRING_AGG(CAST(ue.ApexValidationErrorID AS STRING), ', ') 
        AS ApexValidationErrorIDs
    , STRING_AGG(eu.Name, ', ') 
        AS ValidationErrors
  FROM main.finance.bronze_usabroker_apex_uservalidationerrors ue
  LEFT JOIN main.finance.bronze_usabroker_dictionary_apexvalidationerror eu
      ON eu.ApexValidationErrorID = ue.ApexValidationErrorID
  GROUP BY ue.GCID
),

apexerrors AS (
  SELECT
      ue.GCID
    , STRING_AGG(DISTINCT CAST(ue.ReasonConstant AS STRING), ', ') 
        AS ReasonConstant
    , STRING_AGG(DISTINCT ue.ReasonDescription, ', ') 
        AS ReasonDescription
  FROM bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ue
  GROUP BY ue.GCID
),



/*====================================================
  STEP 1 – Docs
====================================================*/
docs AS (
  SELECT
      dc.RealCID
    , MAX(CASE WHEN cdd.DocumentTypeID = 1 THEN 1 ELSE 0 END) AS POA_Defined
    , MAX(CASE WHEN cdd.DocumentTypeID = 2 THEN 1 ELSE 0 END) AS POI_Defined
    , MAX(CASE WHEN cdd.DocumentTypeID IN (15,18,23) THEN 1 ELSE 0 END) AS Selfie_Defined
    , MAX(CASE WHEN cdd.DocumentTypeID IN (22) THEN 1 ELSE 0 END) AS SSN_Card_Defined
    , MAX(CASE WHEN cdd.DocumentClassificationID IN (65) THEN 1 ELSE 0 END) AS US_Visa_Defined
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  LEFT JOIN main.billing.bronze_etoro_backoffice_customerdocument cd
      ON cd.CID = dc.RealCID
  LEFT JOIN main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype cdd
      ON cdd.DocumentID = cd.DocumentID
  WHERE 
      dc.DesignatedRegulationID IN (8,14)
    AND dc.VerificationLevelID = 3
    AND dc.IsValidCustomer = 1
  GROUP BY dc.RealCID
),

/*====================================================
  STEP 2 – Main Table
====================================================*/
final_output AS (
  SELECT
       dc.GCID
    , dc.RealCID
    , dc.RegulationID
    , dc.DesignatedRegulationID
    , COALESCE(ad.ApexID, 'No ApexAccount') AS ApexID
    , CASE WHEN ad.ApexID IS NULL THEN 'Not sent to Apex' ELSE 'Sent to Apex' END AS SentToApex
    , st.Name AS ApexStatus
    , err.ApexValidationErrorIDs
    , err.ValidationErrors
    , CAST(s.BeginTime AS DATE) AS ErrorDate
    , vl.Liabilities
    , CASE WHEN dc.IsDepositor = 1 THEN 'Yes' ELSE 'No' END AS IsDepositor
    , dps.Name AS PlayerStatus
    , dpcs.PendingClosureStatusName
    , COALESCE(d.POA_Defined, 0) AS POA_Defined
    , COALESCE(d.POI_Defined, 0) AS POI_Defined
    , COALESCE(d.Selfie_Defined, 0) AS Selfie_Defined
    , COALESCE(d.SSN_Card_Defined, 0) AS SSN_Card_Defined
    , COALESCE(d.US_Visa_Defined, 0) AS US_Visa_Defined
    , e.EvMatchStatusName 
    , ae.reasonconstant
    , ae.reasondescription
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps
      ON dc.PlayerStatusID = dps.PlayerStatusID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus dpcs
      ON dc.PendingClosureStatusID = dpcs.PendingClosureStatusID
  LEFT JOIN main.finance.bronze_usabroker_apex_apexdata ad
      ON ad.GCID = dc.GCID
  LEFT JOIN main.finance.bronze_usabroker_dictionary_apexstatus st
      ON ad.StatusID = st.StatusID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
      ON vl.CID = dc.RealCID
      AND vl.DateID = (SELECT date_id FROM constants)
  LEFT JOIN errors err
      ON err.GCID = dc.GCID
  LEFT JOIN main.finance.bronze_usabroker_apex_state s
      ON s.GCID = dc.GCID
  LEFT JOIN docs d
      ON d.RealCID = dc.RealCID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus e 
      ON e.EvMatchStatusID = dc.EvMatchStatus
  left join 
    apexerrors as ae
      ON ae.GCID = dc.GCID
  WHERE 
      dc.DesignatedRegulationID IN (8,14)
      AND dc.VerificationLevelID = 3
      AND dc.IsValidCustomer = 1
      AND (ad.StatusID <> 12 OR ad.StatusID IS NULL)
      AND dc.PlayerStatusID not in (2,4)
)

SELECT * FROM final_output
WHERE  
    DesignatedRegulationID in (8,14)
ORDER BY GCID