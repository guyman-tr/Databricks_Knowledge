-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.vg_customer_customer_first_dates
-- Captured: 2026-05-19T15:18:40Z
-- ==========================================================================

SELECT cfd.CID AS RealCID
     , cfd.GCID
     , dc.RegisteredReal AS RegistrationDate
     , dc.FirstDepositDate
     , dc.FirstDepositAmount
     , df.ID AS FTDPlatformID
     , CASE WHEN df.Name = 'Trading' THEN 'TradingPlatform'
            WHEN df.Name = 'IBAN' THEN 'eMoney'
            ELSE df.Name
       END AS FTDPlatformName
     , cfd.FirstPosOpenDate
     , cfd.LastDepositDate
     , cfd.LastDepositAmount
     , cfd.VerificationLevel1Date
     , cfd.VerificationLevel2Date
     , cfd.VerificationLevel3Date
     , cfd.FirstNewFundedDate AS FirstFundedDate
     , cfd.LastNewFundedDate
     , cfd.LastCashoutDate
     , ffa.FirstAction
     , ffa.FirstActionDate
     , ffa.FirstInstrument
     , ffa.FirstCross
     , ffa.FirstCrossDate
     , fc.CurrentClub AS FirstClub
     , fc.Date AS FirstClubDate
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfd
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  ON cfd.CID = dc.RealCID
LEFT JOIN main.bi_db.bronze_moneybusdb_dictionary_accounttypes df
  ON dc.FTDPlatformID = df.ID
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ffa
  ON cfd.CID = ffa.CID
LEFT JOIN (
  SELECT ccl.CID,
         ccl.Date,
         ccl.CurrentClub
  FROM main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ccl
  WHERE ccl.IsFTC = 1
) fc
  ON fc.CID = cfd.CID
