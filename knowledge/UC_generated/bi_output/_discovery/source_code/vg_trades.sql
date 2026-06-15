-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_trades
-- Captured: 2026-05-19T15:01:07Z
-- ==========================================================================

SELECT
  fca.etr_ymd `Date`,
  fca.RealCID AS CID,
  dc.Name AS Country,
  dc.MarketingRegionManualName AS Region,
  InstrumentType,
  fca.InstrumentID,
  InstrumentDisplayName,
  di.IsFuture,
  dpl.Name as ClubTier,
  ps.Name PlayerStatus,
  dr.Name AS Regulation,
  DATE(dmc.RegisteredReal) AS RegistrationDate,
  DATE(dmc.FirstDepositDate) AS FTDDate,
  CASE WHEN fsc.MifidCategorizationID in (2,3) THEN 1 else 0 END IsProfessionalCustomer,
    CASE WHEN ActionTypeID IN (1, 4, 39, 40) THEN 'Manual'
    ELSE 'Copy'
  END AS ActionType,
  CASE
    WHEN IsSettled = 1 THEN 'Real'
    WHEN IsSettled = 0 THEn 'CFD'
  END AS `Real/CFD`,
  SUM(
    CASE
      WHEN ActionTypeID IN (1, 2, 3, 39) THEN 1
      ELSE 0
    END
  ) OpenTrades,
  SUM(
    CASE
      WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN 1
      ELSE 0
    END
  ) ClosedTrades,
  SUM(
    CASE
      WHEN ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40) THEN 1
      ELSE 0
    end
  ) TotalTrades,
  SUM(
    CASE
      WHEN ActionTypeID IN (1, 2, 3, 39) THEN -1 * fca.Amount
      ELSE 0
    END
  ) AS InvestedAmountOpen,
  SUM(
    CASE
      WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN fca.Amount
      ELSE 0
    END
  ) AS AmountClose,
  SUM(
    CASE
      WHEN ActionTypeID IN (1, 2, 3, 39) THEN -1 * fca.Amount
      WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN fca.Amount
      ELSE 0
    END
  ) AS TotalAmount
  ,fca.Leverage
--,SUM(CASE WHEN ActionTypeID IN (1,2,3,39) THEN CAST(dp.Volume AS BIGINT) WHEN ActionTypeID IN  (4,5,6,28,40) THEN   CAST(dp.VolumeOnClose AS BIGINT) ELSE 0 END) AS  Volume
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      on fsc.RealCID = fca.RealCID
      and fca.DateID between fsc.FromDateID and fsc.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dmc
      ON fca.RealCID = dmc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
      ON fsc.CountryID = dc.CountryID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
      ON di.InstrumentID = fca.InstrumentID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
      ON dpl.DWHPlayerLevelID = fsc.PlayerLevelID 
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps 
      ON ps.DWHPlayerStatusID = fsc.PlayerStatusID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
      ON dr.ID = fsc.RegulationID 
--LEFT JOIN DWH_dbo.Dim_Position dp WITH (NOLOCK)
--ON dp.PositionID=fca.PositionID
where  fsc.IsValidCustomer = 1
  AND ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)
GROUP BY
  fca.etr_ymd,
  fca.RealCID,
  dc.Name,
  dc.MarketingRegionManualName,
  InstrumentType,
  fca.InstrumentID,
  InstrumentDisplayName,
  dpl.Name,
  ps.Name ,
  dr.Name,
  DATE(dmc.RegisteredReal) ,
  DATE(dmc.FirstDepositDate) ,
  CASE WHEN fsc.MifidCategorizationID in (2,3) THEN 1 else 0 END,
  di.IsFuture,
  CASE
    WHEN ActionTypeID IN (1, 4, 39, 40) THEN 'Manual'
    ELSE 'Copy'
  END,
  CASE
    WHEN IsSettled = 1 THEN 'Real'
    WHEN IsSettled = 0 THEn 'CFD'
  END
  ,fca.Leverage
