SELECT 
    ca.CID,
    - ca.Amount as Amount,
    ca.DateOccurred,
    TRY_CAST(ca.InstrumentID AS INT) AS InstrumentID, -- Convert InstrumentID to integer if possible
    di.Name AS Instrument,
    ca.Description,
    dr1.Name AS Regulation,
    fsc.IsCreditReportValidCB,
    fsc.IsValidCustomer,
    'CAInCreditType14' as IssueType
FROM 
(
    SELECT
        fca.CID,
        fca.Payment AS Amount,
        TO_DATE(fca.Occurred) AS DateOccurred,
        CAST(DATE_FORMAT(fca.Occurred, 'yyyyMMdd') AS INT) AS DateID,
        fca.Description,
        REGEXP_EXTRACT(fca.Description, 'Instrument=(\\d+):', 1) AS InstrumentID -- Extract InstrumentID using regex
    FROM main.general.bronze_etoro_history_credit fca
    WHERE fca.etr_ymd BETWEEN '2018-01-01' and '2024-09-30'
      AND fca.CreditTypeID = 14
      AND LOWER(fca.Description) LIKE '%ca type%'
      AND LOWER(fca.Description) NOT LIKE '%dividen%'
) ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
    ON ca.CID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr 
    ON fsc.DateRangeID = dr.DateRangeID AND ca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_Regulation dr1 
    ON fsc.RegulationID = dr1.DWHRegulationID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_Instrument di 
    ON TRY_CAST(ca.InstrumentID AS INT) = di.InstrumentID

union all

SELECT 
    ca.CID,
    - ca.Amount as Amount,
    ca.DateOccurred,
    TRY_CAST(ca.InstrumentID AS INT) AS InstrumentID, -- Convert InstrumentID to integer if possible
    di.Name AS Instrument,
    ca.Description,
    dr1.Name AS Regulation,
    fsc.IsCreditReportValidCB,
    fsc.IsValidCustomer,
    'USRegWithOvernight' as IssueType
FROM 
(
   SELECT
        fca.CID,
        fca.Payment AS Amount,
        TO_DATE(fca.Occurred) AS DateOccurred,
        CAST(DATE_FORMAT(fca.Occurred, 'yyyyMMdd') AS INT) AS DateID,
        fca.Description,
        REGEXP_EXTRACT(fca.Description, 'Instrument=(\\d+):', 1) AS InstrumentID -- Extract InstrumentID using regex
    FROM main.general.bronze_etoro_history_credit fca
    WHERE fca.etr_ymd BETWEEN '2018-01-01' and '2024-09-30'
      AND fca.CreditTypeID = 14
    AND (LOWER(fca.Description)  LIKE '%over%' OR LOWER(fca.Description)  LIKE '%weekend%')
--   and CID = 24103479
) ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
    ON ca.CID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr 
    ON fsc.DateRangeID = dr.DateRangeID AND ca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_Regulation dr1 
    ON fsc.RegulationID = dr1.DWHRegulationID
left JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_Instrument di 
    ON TRY_CAST(ca.InstrumentID AS INT) = di.InstrumentID
where fsc.RegulationID in (6,7,8)