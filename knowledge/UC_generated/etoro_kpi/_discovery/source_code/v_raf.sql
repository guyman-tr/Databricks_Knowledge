-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.v_raf
-- Captured: 2026-05-19T15:17:56Z
-- ==========================================================================

SELECT
    R.ReferringCID,
    R.ReferredCID,
    C1.GCID AS ReferringGCID,
    C2.GCID AS ReferredGCID,
    R.ReferringCompensationAmount / 100.0                    AS ReferringCompensationAmount,
    R.ReferredCompensationAmount / 100.0                     AS ReferredCompensationAmount,
    R.RafStatusID,
    R.RafStatusName,
    R.CompensationDate,
    R.ProcessingDate,
    R.FraudReason,
    R.IsProcessed,
    C1.PlayerLevelID                                          AS ReferringOrigPlayerLevelID,
    R.CalcPlayerLevelID                                       AS ReferringCalcPlayerLevelID,
    P1.Name                                                   AS ReferringPlayerLevelName,
    C2.PlayerLevelID                                          AS ReferredOrigPlayerLevelID,
    P2.Name                                                   AS ReferredPlayerLevelName,
    C1.RegulationID                                           AS ReferringRegulationID,
    C2.RegulationID                                           AS ReferredRegulationID,
    DR1.Name                                                  AS ReferringRegulationName,
    DR2.Name                                                  AS ReferredRegulationName,
    CASE WHEN C1.GuruStatusID > 1 THEN 1 ELSE 0 END           AS ReferringIsPI,
    G1.Name                                                   AS ReferringGuruStatusName,
    C1.CountryID                                              AS ReferringCountryID,
    DC1.Name                                                  AS ReferringCountry,
    C2.CountryID                                              AS ReferredCountryID,
    DC2.Name                                                  AS ReferredCountry,
    CM1.RealizedEquity                                        AS ReferringRealizedEquity,
    CM2.RealizedEquity                                        AS ReferredRealizedEquity,
    L1.TotalPositionsAmount                                   AS ReferringTotalInvestedAmount,
    L2.TotalPositionsAmount                                   AS ReferredTotalInvestedAmount
FROM main.experience.bronze_rafcompensations_customer_raftrackingprocessed  R
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked         C1            ON R.ReferringCID = C1.RealCID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked         C2            ON R.ReferredCID = C2.RealCID
INNER JOIN main.general.bronze_etoro_dictionary_playerlevel                 P1            ON P1.PlayerLevelID = C1.PlayerLevelID
INNER JOIN main.general.bronze_etoro_dictionary_gurustatus                  G1            ON G1.GuruStatusID  = C1.GuruStatusID
INNER JOIN main.general.bronze_etoro_dictionary_country                     DC1           ON DC1.CountryID  = C1.CountryID
INNER JOIN main.general.bronze_etoro_dictionary_regulation                  DR1           ON DR1.ID          = C1.RegulationID
INNER JOIN main.general.bronze_etoro_dictionary_playerlevel                 P2            ON P2.PlayerLevelID = C2.PlayerLevelID
INNER JOIN main.general.bronze_etoro_dictionary_country                     DC2           ON DC2.CountryID  = C2.CountryID
INNER JOIN main.general.bronze_etoro_dictionary_regulation                  DR2           ON DR2.ID          = C2.RegulationID
LEFT JOIN  main.bi_db.bronze_etoro_customer_customermoney                   CM1           ON CM1.CID = R.ReferringCID
LEFT JOIN  main.bi_db.bronze_etoro_customer_customermoney                   CM2           ON CM2.CID = R.ReferredCID
LEFT JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities               L1            ON L1.CID = CAST(R.ReferringCID AS STRING)
                                                                                            AND L1.DateID  = CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT)
LEFT JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities               L2            ON L2.CID = CAST(R.ReferredCID AS STRING)
                                                                                          AND L2.DateID  = CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT)
