-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_payments_mimo_allplatformddr_genienew
-- Captured: 2026-06-19T14:35:00Z
-- ==========================================================================

SELECT
  bddfmap.MIMOAction,
  bddfmap.TransactionID,
  bddfmap.RealCID,
  dc.MarketingRegionManualName,
  dc.Name AS Country,
  dpl.Name AS Club,
  dr1.Name AS Regulation,
  bddfmap.Date AS Date_MIMO,
  bddfmap.MIMOPlatform,
  bddfmap.IsInternalTransfer,
  bddfmap.Currency,
  CASE
    WHEN bddfmap.IsInternalTransfer = 1 THEN 'internal transfer - etoromoney'
    WHEN
      bddfmap.MIMOPlatform = 'eMoney'
      AND bddfmap.IsInternalTransfer = 0
    THEN
      o.Fundingtype_Txtype_7
    ELSE dft.Name
  END AS FundingType,
  bddfmap.IsGlobalFTD,
  bddfmap.AmountUSD AS AmountUSD_MIMO
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms bddfmap
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      ON bddfmap.RealCID = fsc.RealCID
      AND fsc.IsValidCustomer = 1
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
      ON fsc.DateRangeID = dr.DateRangeID
      AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
      ON fsc.CountryID = dc.CountryID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
      ON fsc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
      ON dr1.DWHRegulationID = fsc.RegulationID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype dft
      ON bddfmap.FundingTypeID = dft.FundingTypeID
    LEFT JOIN (
      SELECT
        mdt.TransactionID,
        CASE
          WHEN p.CID IS NOT NULL THEN 'OpenBanking'
          ELSE 'WireTransfer'
        END AS Fundingtype_Txtype_7
      FROM
        main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction mdt
          LEFT JOIN main.bi_db.bronze_moneytransfer_billing_transfers p
            ON lower(p.ExReferenceID) = lower(mdt.ReferenceNumber)
            AND p.TransferStatusID = 10
    ) o
      ON o.TransactionID = bddfmap.TransactionID
WHERE
  bddfmap.MIMOAction = 'Deposit'
  AND bddfmap.IsTradeFromIBAN = 0
  AND bddfmap.IsRedeem = 0
UNION ALL
/* =========================
   Withdraw
   ========================= */
SELECT
  bddfmap.MIMOAction,
  bddfmap.TransactionID,
  bddfmap.RealCID,
  dc.MarketingRegionManualName,
  dc.Name AS Country,
  dpl.Name AS Club,
  dr1.Name AS Regulation,
  bddfmap.Date AS Date_MIMO,
  bddfmap.MIMOPlatform,
  bddfmap.IsInternalTransfer,
  bddfmap.Currency,
  CASE
    WHEN bddfmap.IsInternalTransfer = 1 THEN 'internal transfer - etoromoney'
    WHEN
      bddfmap.MIMOPlatform = 'eMoney'
      AND bddfmap.IsInternalTransfer = 0
    THEN
      'WireTransfer'
    ELSE dft.Name
  END AS FundingType,
  bddfmap.IsGlobalFTD,
  bddfmap.AmountUSD AS AmountUSD_MIMO
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms bddfmap
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      ON bddfmap.RealCID = fsc.RealCID
      AND fsc.IsValidCustomer = 1
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
      ON fsc.DateRangeID = dr.DateRangeID
      AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
      ON fsc.CountryID = dc.CountryID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
      ON fsc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
      ON dr1.DWHRegulationID = fsc.RegulationID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype dft
      ON bddfmap.FundingTypeID = dft.FundingTypeID
WHERE
  bddfmap.MIMOAction = 'Withdraw'
  AND bddfmap.IsTradeFromIBAN = 0
  AND bddfmap.IsRedeem = 0
